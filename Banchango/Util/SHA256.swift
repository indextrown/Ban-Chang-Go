//
//  SHA256.swift
//  LMessenger
//
//  Created by 김동현 on 10/31/24.
//

import Foundation
import CryptoKit

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
    
    return hashString
}




