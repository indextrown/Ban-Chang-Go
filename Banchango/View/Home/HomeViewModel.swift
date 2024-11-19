//
//  HomeViewModel.swift
//  Banchango
//
//  Created by 김동현 on 11/3/24.
//

import Foundation
import Combine
import FirebaseDatabase

class HomeViewModel: ObservableObject {
    enum Action {
        case load
    }
    
    @Published var myUser: User?
    @Published var phase: Phase = .notRequested
    @Published var notices: [Notice] = []
    
    private var userId: String
    private var container: DIContainer
    private var subscriptions = Set<AnyCancellable>()
    private var db: DatabaseReference
    
    init(container: DIContainer, userId: String) {
        self.container = container
        self.userId = userId
        self.db = Database.database().reference() // Firebase Database 초기화
    }
    
    func send(action: Action) {
        switch action {
        case .load:
            phase = .loading
            
            // TODO: -
            container.services.userService.getUser(userId: userId)
                .handleEvents(receiveOutput: { [weak self] user in
                    self?.myUser = user
                })
                .flatMap { user in
                    self.container.services.userService.loadUsers(id: user.id)
                }
                .sink { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        print("실패: \(error.localizedDescription)") // 에러 메시지 출력
                        self?.phase = .fail
                    case .finished:
                        break
                    }
//                .sink { [weak self] completion in
//                    // TODO:
//                    if case .failure = completion {
//                        print("실패")
//                        self?.phase = .fail
//                    }
                } receiveValue: { [weak self] users in
                    self?.phase = .success
                }.store(in: &subscriptions)
            return
        }
    }
}
