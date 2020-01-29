//
//  ThreadController.swift
//  iOSFirebaseChat
//
//  Created by Patrick Millet on 1/28/20.
//  Copyright © 2020 Patrick Millet. All rights reserved.
//

import Foundation
import MessageKit
import FirebaseDatabase

class ThreadController {
    
    private var databaseReference: DatabaseReference

    private let threadsKey = "threads"
    private let messagesKey = "messages"
    private let currentUserKey = "currentUser"

    private(set) var threads = [Thread]()
    private(set) var currentUser: Sender?

    private var observers = [String: UInt]()

    init() {
        databaseReference = Database.database().reference()
    }

    func attemptToLogIn(_ didSucced: (Bool) -> Void) {
        if let currentUserDictionary = UserDefaults.standard
            .value(forKey: currentUserKey) as? [String: String]
        {
            currentUser = Sender(dictionary: currentUserDictionary)
            didSucced(true)
        } else {
            didSucced(false)
        }
    }

    func login(with user: Sender) {
        currentUser = user
    }

    func create(_ thread: Thread, completion: @escaping (Error?) -> Void) {
        let room = databaseReference.child(threadsKey).child(thread.id)

        room.setValue(thread.dictionaryRepresentation) { error, _ in
            completion(error)
        }
    }

    func create(
        _ message: Message,
        in thread: Thread,
        completion: @escaping (Error?) -> Void)
    {
        let messageRef = databaseReference
            .child(messagesKey)
            .child(thread.id)
            .child(message.messageId)

        messageRef.setValue(message.dictionaryRepresentation) { error, _ in
            if let error = error {
                completion(error)
                return
            }
        }

        let updateDateAsInterval = message.sentDate.timeIntervalSinceReferenceDate
        let threadUpdatedRef = databaseReference
            .child(threadsKey)
            .child(thread.id)
            .child(Thread.DictionaryKey.lastUpdated.rawValue)
        threadUpdatedRef.setValue(updateDateAsInterval) { error, database in
            completion(error)
        }
    }

    func fetchThreads(completion: @escaping (Result<[Thread], Error>) -> Void) {
        let threads = databaseReference.child(threadsKey)
        threads.observeSingleEvent(of: .value, with: { snapshot in
            guard let threadsByID = snapshot.value as? [String: Any] else {
                completion(.failure(NetworkError.badData))
                return
            }
            var fetchedThreads = [Thread]()
            for (_, threadRep) in threadsByID {
                guard
                    let threadRep = threadRep as? [String: Any],
                    let thread = Thread(from: threadRep)
                    else { continue }
                fetchedThreads.append(thread)
            }
            fetchedThreads.sort { $0.lastUpdated > $1.lastUpdated }

            self.threads = fetchedThreads

            completion(.success(fetchedThreads))
        }) { error in
            completion(.failure(error))
        }
    }

    func observeMessages(
        for thread: Thread,
        completion: @escaping (Result<[Message], Error>) -> Void)
    {
        if observers[thread.id] != nil { return }

        let threadRef = databaseReference.child(messagesKey).child(thread.id)
        self.observers[thread.id] = threadRef.observe(.value, with: { snapshot in
            let messagesByID = snapshot.value as? [String: Any] ?? [:]

            var messages = [Message]()
            for (_, messageRep) in messagesByID {
                guard
                    let messageRep = messageRep as? [String: Any],
                    let message = Message(from: messageRep)
                    else { continue }
                messages.append(message)
            }

            completion(.success(messages))
        }) { error in
            completion(.failure(error))
        }
    }

    func stopObserving() {
        for (id, handle) in observers {
            databaseReference.child(messagesKey).child(id)
                .removeObserver(withHandle: handle)
            observers[id] = nil
        }
    }
}
