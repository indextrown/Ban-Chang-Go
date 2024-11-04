//
//  AuthenticationViewModel.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import Foundation
import Combine
import AuthenticationServices

enum AuthenticationState {
    case unauthenticated
    case authenticated
    case nicknameRequired
}

class AuthenticationViewModel: ObservableObject {
    
    enum Action {
        case googleLogin
        case appleLogin(ASAuthorizationRequest)
        case appleLoginCompletion(Result<ASAuthorization, Error>)
        case checkAuthenticationState
        case logout
        case updateNickname(String)
    }
    
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var isLoading = false
    @Published var currentUser: User?
    
    var userId: String?
    
    private var currentNonce: String?
    private var container: DIContainer
    private var subscriptions = Set<AnyCancellable>()
    
    init(container: DIContainer) {
        self.container = container
        // container.services.authService
    }
    
    func send(action: Action) {
        switch action {
        case .checkAuthenticationState:
                if let userId = container.services.authService.checkAuthenticationState() {
                    self.userId = userId
                    self.authenticationState = .authenticated // 사용자 ID가 있으면 인증 상태 변경
                    // 필요 시 사용자 정보를 가져오는 작업을 추가할 수 있습니다.
                    // 사용자 정보를 가져오는 작업
                                container.services.userService.getUser(userId: userId)
                                    .sink { completion in
                                        if case .failure = completion {
                                            // 사용자 정보 가져오기 실패 시 처리
                                            self.authenticationState = .unauthenticated
                                        }
                                    } receiveValue: { existingUser in
                                        // 사용자 정보를 성공적으로 가져온 경우
                                        self.currentUser = existingUser
                                        // 닉네임 유무 확인
                                        if existingUser.nickname?.isEmpty ?? true {
                                            self.authenticationState = .nicknameRequired // 닉네임 설정 필요 상태로 변경
                                        }
                                    }
                                    .store(in: &subscriptions) // 구독 저장
                } else {
                    self.authenticationState = .unauthenticated // 로그인 상태가 아닐 경우
                }
//        case .checkAuthenticationState:
//            if let userId = container.services.authService.checkAuthenticationState() {
//                self.userId = userId
//                self.authenticationState = .authenticated
//            }
            
        case .logout:
            container.services.authService.logout()
                .sink { completion in
                      
                } receiveValue: { [weak self] _ in
                    self?.authenticationState = .unauthenticated
                    self?.userId = nil
                }.store(in: &subscriptions)
        case .googleLogin:
            isLoading = true
            container.services.authService.signInWithGoogle()
                .flatMap { [weak self] user in
//                    self?.currentUser = user
                    
                    // 사용자 정보를 가져온 후
                    return self?.container.services.userService.getUser(userId: user.id) ?? Empty().eraseToAnyPublisher()
                }
                .sink { [weak self] completion in
                    if case .failure = completion {
                        self?.isLoading = false
                    }
                } receiveValue: { [weak self] existingUser in
                    self?.isLoading = false
                    self?.currentUser = existingUser
                    self?.userId = existingUser.id
                    //print("Logged in User: \(existingUser)") // 추가: 로그인한 사용자 정보 출력
                    
                    // 닉네임 유무 확인
                    if existingUser.nickname?.isEmpty ?? true {
                        self?.authenticationState = .nicknameRequired // 닉네임 설정 필요 상태로 변경
                    } else {
                        self?.authenticationState = .authenticated // 닉네임이 있으면 인증 상태 변경
                    }
                }.store(in: &subscriptions)
                                                
        case let .appleLogin(request):
            let nonce = container.services.authService.handleSignInWithAppleRequest(request as! ASAuthorizationAppleIDRequest)
            currentNonce = nonce
        
        case let .appleLoginCompletion(result):
            if case let .success(authorization) = result {
                guard let nonce = currentNonce else { return }
                
                container.services.authService.handleSignInWithAppleCompletion(authorization, none: nonce)
                    .flatMap { user in
                        self.currentUser = user
                        // 사용자 정보를 가져온 후
                        return self.container.services.userService.getUser(userId: user.id)
                    }
                    .sink { [weak self] completion in
                        if case .failure = completion {
                            self?.isLoading = false
                        }
                    } receiveValue: { [weak self] existingUser in
                        self?.isLoading = false
                        self?.userId = existingUser.id
                        self?.currentUser = existingUser
                        
                        // MARK: - 닉네임 유무 확인
                        if existingUser.nickname?.isEmpty ?? true {
                            self?.authenticationState = .nicknameRequired
                        } else {
                            self?.authenticationState = .authenticated // 닉네임이 있으면 인증 상태 변경
                        }
                    }.store(in: &subscriptions)
            } else if case let .failure(error) = result {
                isLoading = false
                print(error.localizedDescription)
            }
            
        case .updateNickname(let nickname):
            guard let userId = userId else { return } // 사용자 ID가 없으면 리턴
            
            // container.services.userService를 통해 닉네임 업데이트 호출
            container.services.userService.updateUserNickname(userId: userId, nickname: nickname)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.authenticationState = .authenticated // 닉네임 설정 후 인증 상태 변경
                    case .failure(let error):
                        print("닉네임 업데이트 실패: \(error)") // 오류 처리
                    }
                }, receiveValue: { _ in })
                .store(in: &subscriptions)

        }
    }
}

