//
//  HomeViewModel.swift
//  Banchango
//
//  Created by 김동현 on 11/3/24.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    enum Action {
        case load
    }
    
    @Published var myUser: User?
    @Published var phase: Phase = .notRequested
    
    private var userId: String
    private var container: DIContainer
    private var subscriptions = Set<AnyCancellable>()
    
    init(container: DIContainer, userId: String) {
        self.container = container
        self.userId = userId
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
                    // TODO:
                    if case .failure = completion {
                        self?.phase = .fail
                    }
                } receiveValue: { [weak self] users in
                    self?.phase = .success
                }.store(in: &subscriptions)
            return
        }
    
    }
}
