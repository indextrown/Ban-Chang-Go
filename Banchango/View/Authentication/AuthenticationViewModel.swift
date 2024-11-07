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
        case checkNickname(String)
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
                
                print("UID: \(userId)")
                print("이까진성공: \(self.authenticationState)")
            }
            else {
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
            // MARK: - 구글 로그인 완료가 되면
            container.services.authService.signInWithGoogle()
            // TODO: - db추가
                .flatMap { user in
                    self.container.services.userService.addUser(user)
                }
            // MARK: - 실패시
                .sink { [weak self] completion in
                    // TODO: - 실패시
                    if case .failure = completion {
                        self?.isLoading = false
                    }
                    // MARK: - 성공시
                } receiveValue: { [weak self] user in
                    self?.isLoading = false
                    self?.userId = user.id // 유저정보가 오면 뷰모델에서 아이디 보유하도록
                    self?.authenticationState = .authenticated
                }.store(in: &subscriptions) // sink를 하면 subscriptions가 리턴된다 -> 뷰모델에서 관리
            //subscriptions은 뷰모델에서 관리할건데 뷰모델에서 구독이 여러개 있을 수 있어서 set으로 관리하자
            /*
             case .googleLogin:
             isLoading = true
             container.services.authService.signInWithGoogle()
             .flatMap { [weak self] user in
             //                    self?.currentUser = user
             
             print("유저: \(user)")
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
             
             //                    // 닉네임 유무 확인
             //                    if existingUser.nickname?.isEmpty ?? true {
             //                        self?.authenticationState = .nicknameRequired // 닉네임 설정 필요 상태로 변경
             //                    } else {
             //                        self?.authenticationState = .authenticated // 닉네임이 있으면 인증 상태 변경
             //                    }
             } .store(in: &subscriptions)
             */
            
            
        case let .appleLogin(request):
            let nonce = container.services.authService.handleSignInWithAppleRequest(request as! ASAuthorizationAppleIDRequest)
            currentNonce = nonce
            
        case let .appleLoginCompletion(result):
            if case let .success(authorization) = result {
                guard let nonce = currentNonce else { return }
                
                container.services.authService.handleSignInWithAppleCompletion(authorization, none: nonce)
                    // TODO: - db추가
                    .flatMap { user in
                        self.container.services.userService.addUser(user)
                    }
                    .sink { [weak self] completion in
                        // TODO: - 실패시
                        if case .failure = completion {
                            self?.isLoading = false
                        }
                    } receiveValue: { [weak self] user in
                        self?.isLoading = false
                        self?.userId = user.id
                        self?.authenticationState = .authenticated
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
            
        case .checkNickname(let userId): // 추가된 부분
            container.services.userService.getUser(userId: userId)
                .sink { completion in
                    if case .failure = completion {
                        print("닉네임 체크 실패")
                    }
                } receiveValue: { existingUser in
                    if existingUser.nickname?.isEmpty ?? true {
                        self.authenticationState = .nicknameRequired // 닉네임 설정 필요 상태로 변경
                    }
                }
                .store(in: &subscriptions) // 구독 저장
        }
    }
}

