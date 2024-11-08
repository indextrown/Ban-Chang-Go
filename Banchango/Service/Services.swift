//
//  Services.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import Foundation

protocol ServiceType {
    var authService: AuthenticationServiceType { get set }
    var userService: UserServiceType { get set }
//    var noticeService: NoticeServiceType { get set }
}

class Services: ServiceType {
    var authService: AuthenticationServiceType
    var userService: UserServiceType
//    var noticeService: NoticeServiceType
    
    init() {
        self.authService = AuthenticationService()
        self.userService = UserService(deRepository: UserDBRepository())
//        self.noticeService = NoticeService()
    }
}

class StubService: ServiceType {
    var authService: AuthenticationServiceType = StubAuthenticationService()
    var userService: UserServiceType = StubUserService()
//    var noticeService: NoticeServiceType = NoticeService()

}

