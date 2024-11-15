//
//  AuthenticationViewModel.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import Foundation
import Combine
import AuthenticationServices
import FirebaseAuth

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
        case deleteAccount
//        case isNicknameDuplicate(String)
        case isNicknameDuplicate(String, (Bool) -> Void)
    }
    
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var isLoading = false
    @Published var currentUser: User?
    @Published var isNicknameDuplicate: Bool = false // 닉네임 중복 상태 관리
        
    
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
                //                print("UID: \(userId)")
                //                print("이까진성공: \(self.authenticationState)")
            }
            
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
                .flatMap { user in
                    // 사용자가 존재하는지 확인 후, 없으면 addUser 호출
                    self.container.services.userService.getUser(userId: user.id)
                        .catch { error -> AnyPublisher<User, ServiceError> in
                            // 다른 오류가 발생한 경우 그대로 에러를 반환
                            return self.container.services.userService.addUser(user)
                        }
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
                    self?.send(action: .checkNickname(user.id))
                }.store(in: &subscriptions) // sink를 하면 subscriptions가 리턴된다 -> 뷰모델에서 관리
            //subscriptions은 뷰모델에서 관리할건데 뷰모델에서 구독이 여러개 있을 수 있어서 set으로 관리하자
            
            
        case let .appleLogin(request):
            let nonce = container.services.authService.handleSignInWithAppleRequest(request as! ASAuthorizationAppleIDRequest)
            currentNonce = nonce
            
        case let .appleLoginCompletion(result):
            if case let .success(authorization) = result {
                guard let nonce = currentNonce else { return }
                
                container.services.authService.handleSignInWithAppleCompletion(authorization, none: nonce)
                // TODO: - db추가
                    .flatMap { user in
                        // 사용자가 존재하는지 확인 후, 없으면 addUser 호출
                        self.container.services.userService.getUser(userId: user.id)
                            .catch { error -> AnyPublisher<User, ServiceError> in
                                // 다른 오류가 발생한 경우 그대로 에러를 반환
                                return self.container.services.userService.addUser(user)
                            }
                    }
                    .sink { [weak self] completion in
                        // TODO: - 실패시
                        if case .failure = completion {
                            self?.isLoading = false
                        }
                    } receiveValue: { [weak self] user in
                        self?.isLoading = false
                        self?.userId = user.id
                        self?.send(action: .checkNickname(user.id))
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
            
        case .checkNickname(let userId):
            //print("사용자 ID에 대한 닉네임 확인 중: \(userId)") // 한글 로그 추가
            container.services.userService.getUser(userId: userId)
                .sink { completion in
                    if case .failure = completion {
                        //print("사용자 정보를 가져오는 데 실패했습니다: \(completion)") // 한글 로그 추가
                        self.authenticationState = .nicknameRequired
                    }
                } receiveValue: { existingUser in
                    //print("받은 사용자 정보: \(existingUser)") // 한글 로그 추가
                    if existingUser.nickname?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
                        //print("닉네임이 비어있거나 nil입니다.") // 한글 로그 추가
                        self.authenticationState = .nicknameRequired
                    } else {
                        //print("설정된 닉네임: \(existingUser.nickname!)") // 한글 로그 추가
                        self.authenticationState = .authenticated
                    }
                }
                .store(in: &subscriptions)
            
        case .deleteAccount:
            guard let userId = self.userId else { return }
            
            // 1단계: Realtime Database에서 유저 데이터를 삭제
            container.services.userService.deleteUser(userId: userId)
                .tryMap { _ -> FirebaseAuth.User in
                    // 2단계: Firebase Auth 계정 삭제
                    guard let currentUser = Auth.auth().currentUser else {
                        throw ServiceError.userNotFound
                    }
                    return currentUser
                }
                .flatMap { currentUser -> AnyPublisher<Void, Error> in
                    return Future<Void, Error> { promise in
                        currentUser.delete { error in
                            if let error = error {
                                promise(.failure(error))
                            } else {
                                promise(.success(()))
                            }
                        }
                    }.eraseToAnyPublisher()
                }
                .sink { completion in
                    if case .failure(let error) = completion {
                        print("계정 삭제 실패: \(error)")
                    }
                } receiveValue: { [weak self] _ in
                    // 계정과 데이터가 성공적으로 삭제된 경우
                    DispatchQueue.main.async {
                        self?.authenticationState = .unauthenticated
                        self?.userId = nil
                    }
                }
                .store(in: &subscriptions)
            
        case .isNicknameDuplicate(let nickname, let completion):
            container.services.userService.checkNickname(nickname)
                .sink { result in
                    switch result {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            print("닉네임 중복 확인 오류: \(error.localizedDescription)")
                            completion(false) // 오류 발생 시 false 반환
                        }
                    case .finished:
                        break
                    }
                } receiveValue: { isDuplicate in
                    DispatchQueue.main.async {
                        if isDuplicate {
                            completion(true) // 중복된 경우 클로저에 true 전달
                        } else {
                            completion(false) // 중복되지 않은 경우 클로저에 false 전달
                            self.send(action: .updateNickname(nickname)) // 중복되지 않은 경우 닉네임 업데이트
                        }
                    }
                }
                .store(in: &subscriptions)



        }
    }
}


/*
case .isNicknameDuplicate(let nickname):
container.services.userService.checkNickname(nickname)
    .sink { completion in
        if case .failure(let error) = completion {
            print("닉네임 중복 확인 중 오류 발생: \(error.localizedDescription)")
        }
    } receiveValue: { isDuplicate in
        if isDuplicate {
            print("닉네임이 중복되었습니다.")
            self.isNicknameDuplicate = true // 닉네임 중복 상태 업데이트
        } else {
            guard let userId = self.userId else { return }
            self.container.services.userService.updateUserNickname(userId: userId, nickname: nickname)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("닉네임이 성공적으로 업데이트되었습니다.")
                        self.authenticationState = .authenticated
                        self.isNicknameDuplicate = false // 중복 상태 초기화
                    case .failure(let error):
                        print("닉네임 업데이트 실패: \(error.localizedDescription)")
                    }
                }, receiveValue: { _ in })
                .store(in: &self.subscriptions)
        }
    }
    .store(in: &subscriptions)
 */
