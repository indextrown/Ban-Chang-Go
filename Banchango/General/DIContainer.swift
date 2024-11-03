//
//  DIContainer.swift
//  LMessenger
//
//  Created by 김동현 on 10/30/24.
//

import Foundation

// MARK: - DiContainer는 enviromentObject에 주입될 예정이기 때문에 클래스 타입과 ObservableObject로 선언
class DIContainer: ObservableObject {
    // TODO: - service 서비스 관리할 프로퍼티
    var services: ServiceType
    
    init(services: ServiceType) {
        self.services = services
    }
}
