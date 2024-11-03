//
//  Constant.swift
//  LMessenger
//
//  Created by 김동현 on 11/1/24.
//

import Foundation

// Constant.DBKey.users.. 너무길다
typealias DBKey = Constant.DBKey

enum Constant { }

// namespace
extension Constant {
    struct DBKey {
        static let Users = "Users"
        static let ChatRooms = "ChatRooms"
        static let Chats = "Chats"
    }
}


