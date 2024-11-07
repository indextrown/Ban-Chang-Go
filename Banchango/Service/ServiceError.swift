//
//  ServiceError.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import Foundation

enum ServiceError: Error {
    case error(Error)
    case userNotFound

}

extension ServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .error(let dbError):
            return dbError.localizedDescription
        case .userNotFound:
            return "사용자를 찾을 수 없습니다."
        }
    }
}
