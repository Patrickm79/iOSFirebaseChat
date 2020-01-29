//
//  NetworkErrorEnum.swift
//  iOSFirebaseChat
//
//  Created by Patrick Millet on 1/28/20.
//  Copyright © 2020 Patrick Millet. All rights reserved.
//

import Foundation

enum NetworkError: Error {
    case noDecode
    case noEncode
    case badData
    case timeout
    case other(Error?)
}
