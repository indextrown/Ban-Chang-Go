//
//  User.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import Foundation

struct User {
    var id: String
    var name: String
    var phoneNumber: String?
    var profileURL: String?
    var description: String?
    var nickname: String?
    var signupDate: String?
    var platform: String?
}
extension User {
    // 유저의 타입을 object화
    func toObject() -> UserObject {
        .init(id: id,
              name: name,
              phoneNumber: phoneNumber,
              profileURL: profileURL,
              description: description,
              nickname: nickname,
              signupDate: signupDate,
              platform: platform
        )
    }
}

extension User {
    static var stub1: User {
        .init(id: "user1_id", name: "김동현")
    }
    
    static var stub2: User {
        .init(id: "user2_id", name: "Index")
    }
}

