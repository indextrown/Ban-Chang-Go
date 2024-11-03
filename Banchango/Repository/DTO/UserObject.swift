//
//  UserObject.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import Foundation

struct UserObject: Codable {
    var id: String
    var name: String
    var phoneNumber: String?
    var profileURL: String?
    var description: String?
    var nickname: String?
}


extension UserObject {
    func toModel() -> User {
        .init(id: id,
              name: name,
              phoneNumber: phoneNumber,
              profileURL: profileURL,
              description: description,
              nickname: nickname
        )
    }
}

