//
//  DBError.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import Foundation

enum DBError: Error {
    case error(Error)
    case emptyValue
    case invalidatedType
}

extension DBError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .error(let error):
            return "오류가 발생했습니다: \(error.localizedDescription)"
        case .emptyValue:
            return "데이터베이스에 해당 사용자 정보가 없습니다."
        case .invalidatedType:
            return "유효하지 않은 데이터 타입입니다."
        }
    }
}
