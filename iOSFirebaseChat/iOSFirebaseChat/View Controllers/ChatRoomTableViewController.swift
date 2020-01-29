//
//  ChatRoomTableViewController.swift
//  iOSFirebaseChat
//
//  Created by Patrick Millet on 1/28/20.
//  Copyright © 2020 Patrick Millet. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatroomViewController: MessagesViewController {
    // MARK: - Properties
    
    var threadController: ThreadController!
    var thread: Thread?

    let newThreadTitle = "Create new thread!"

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        if let thread = thread {
            threadController.observeMessages(
                for: thread,
                completion: messagesDidUpdate(withResult:))
            self.title = thread.name
        } else {
            self.title = newThreadTitle
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        threadController.stopObserving()
    }

    // MARK: - Methods
    
    private func sendNewMessage(
        with text: String,
        completion: @escaping (String?) -> Void)
    {
        guard
            let sender = currentSender() as? Sender,
            !text.isEmpty
            else { return }

        threadController?.create(Message(sender: sender, text: text), in: thread!)
        { error in
            if let error = error {
                completion("Error creating message: \(error)")
            } else { completion(nil) }
        }
    }

    private func createNewThread(
        named text: String,
        completion: @escaping (String?) -> Void)
    {
        guard !text.isEmpty else { return }

        self.title = text

        thread = Thread(name: text)
        threadController?.create(Thread(name: text)) { error in
            if let error = error {
                self.thread = nil
                self.title = self.newThreadTitle
                completion("Error creating new chatroom: \(error)")
            } else {
                self.threadController.observeMessages(
                    for: self.thread!,
                    completion: self.messagesDidUpdate(withResult:))
                completion(nil)
            }
        }
    }

    private func messagesDidUpdate(withResult result: Result<[Message], Error>) {
        do {
            thread?.setMessages(try result.get())
            DispatchQueue.main.async {
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        } catch {
            NSLog("Error updating messages from server: \(error)")
        }
    }
}

// MARK: - MessagesDataSource

extension ChatroomViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return threadController.currentUser ?? Sender(id: UUID().uuidString, displayName: "Unknown User")
    }

    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageType {
        guard let thread = thread else {
            fatalError("No chatroom found for ChatroomViewController")
        }
        return thread.messages[indexPath.item]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return 1
    }

    func numberOfItems(
        inSection section: Int,
        in messagesCollectionView: MessagesCollectionView
    ) -> Int {
        return thread?.messages.count ?? 0
    }
}

// MARK: - MessagesLayoutDelegate

extension ChatroomViewController: MessagesLayoutDelegate {
    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGFloat {
        return 20
    }

    func messageBottomLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGFloat {
        return 20
    }
}

// MARK: - MessagesDisplayDelegate

extension ChatroomViewController: MessagesDisplayDelegate {
    func inputBar(
        _ inputBar: InputBarAccessoryView,
        didPressSendButtonWith text: String)
    {
        func creationDidComplete(withErrorMessage errorMessage: String?) {
            if let errorMessage = errorMessage {
                NSLog(errorMessage)
                DispatchQueue.main.async {
                    inputBar.inputTextView.text = text
                }
            }
            DispatchQueue.main.async {
                self.messagesCollectionView.reloadData()
            }
        }

        if thread == nil {
            createNewThread(
                named: text,
                completion: creationDidComplete(withErrorMessage:))
        } else {
            sendNewMessage(
                with: text,
                completion: creationDidComplete(withErrorMessage:))
        }

        inputBar.inputTextView.text = ""
    }

    func textColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .black
    }

    func backgroundColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        return isFromCurrentSender(message: message) ? .blue : .green
    }

    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView)
    {
        let avatar = Avatar(image: nil, initials: message.sender.displayName)
        avatarView.set(avatar: avatar)
    }
}

// MARK: - MessageInputBarDelegate

extension ChatroomViewController: MessageInputBarDelegate {}
