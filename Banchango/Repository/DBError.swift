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
