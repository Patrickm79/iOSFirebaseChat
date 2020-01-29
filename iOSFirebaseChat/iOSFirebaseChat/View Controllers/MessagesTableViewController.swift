//
//  MessagesTableViewController.swift
//  iOSFirebaseChat
//
//  Created by Patrick Millet on 1/28/20.
//  Copyright © 2020 Patrick Millet. All rights reserved.
//

import UIKit

import MessageKit

class MessagesTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var chatController = ThreadController()

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        chatController.attemptToLogIn { didSucceed in
            if !didSucceed {
                DispatchQueue.main.async { self.showNewUserAlert() }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        chatController.fetchThreads { result in
            do {
                let _ = try result.get()
                DispatchQueue.main.async { self.tableView.reloadData() }
            } catch {
                NSLog("Error fetching chatrooms: \(error)")
            }
        }
    }

    // MARK: - Table view data source
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return chatController.threads.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ThreadCell",
            for: indexPath)

        cell.textLabel?.text = chatController.threads[indexPath.row].name

        return cell
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowThreadDetailSegue" {
            guard
                let roomVC = segue.destination as? ChatroomViewController,
                let index = tableView.indexPathForSelectedRow?.row
                else { return }
            roomVC.threadController = chatController
            roomVC.thread = chatController.threads[index]
        }
        if segue.identifier == "NewThreadSegue" {
            guard
                let roomVC = segue.destination as? ChatroomViewController
                else { return }
            roomVC.threadController = chatController
        }
    }

    // MARK: - Helper Methods
    private func showNewUserAlert() {
        let alert = UIAlertController(
            title: "Set a username",
            message: nil,
            preferredStyle: .alert)

        var usernameTextField: UITextField!

        alert.addTextField { (textField) in
            textField.placeholder = "Username:"
            usernameTextField = textField
        }

        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            let displayName = usernameTextField.text ?? "No name"
            let id = UUID().uuidString

            let sender = Sender(senderId: id, displayName: displayName)

            UserDefaults.standard.set(sender.dictionaryRepresentation, forKey: "currentUser")

            self.chatController.login(with: sender)
        }

        alert.addAction(submitAction)
        present(alert, animated: true, completion: nil)
    }
}
