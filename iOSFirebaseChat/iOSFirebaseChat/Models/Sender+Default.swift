//
//  Sender+Default.swift
//  iOSFirebaseChat
//
//  Created by Patrick Millet on 1/28/20.
//  Copyright © 2020 Patrick Millet. All rights reserved.
//

import Foundation
import MessageKit

extension Sender {
    var dictionaryRepresentation: [String: String] {
        return ["id": senderId, "displayName": displayName]
    }

    init?(dictionary: [String: String]) {
        guard
            let id = dictionary["id"],
            let displayName = dictionary["displayName"]
            else { return nil }

        self.init(senderId: id, displayName: displayName)
    }
}
