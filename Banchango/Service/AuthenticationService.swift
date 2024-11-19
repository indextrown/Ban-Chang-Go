//
//  AuthenticationService.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices

enum AuthenticationError: Error {
    case clientIDError
    case tokenError
    case invalidated
}

protocol AuthenticationServiceType {
    // 퍼블리셔
    
    //구글 로그인
    func signInWithGoogle() -> AnyPublisher<User, ServiceError>
    
    // 애플 로그인
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) -> String
    func handleSignInWithAppleCompletion(_ authorization: ASAuthorization, none: String) -> AnyPublisher<User, ServiceError>
    
    // 로그인 확인
    func checkAuthenticationState() -> String?
    
    // 로그아웃
    func logout() -> AnyPublisher<Void, ServiceError>
    
    // 탈퇴
    func deleteUser() -> AnyPublisher<Void, ServiceError>
}

class AuthenticationService: AuthenticationServiceType {
    
    
    
    // 컴플리션 핸들러이다. -> 퍼블리셔를 위에서 만들자
    // Combine 방식의 인터페이스로 외부에 제공하는 역할을 하고, Combine을 사용하는 ViewModel이나 서비스에서 쉽게 구독할 수 있습니다.
    func signInWithGoogle() -> AnyPublisher<User, ServiceError> {
        //Empty().eraseToAnyPublisher()
        Future { [weak self] promise in
            self?.signInWithGoogle{ result in
                switch result {
                case let .success(user):
                    promise(.success(user))
                case let .failure(error):
                    promise(.failure(.error(error)))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) -> String {
        request.requestedScopes = [.fullName, .email]
        
        // nonce 세팅할건데 nonce는 랜덤스트림을 만들오소 sha암호화를 이용해 만들 것이다
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        return nonce
    }
    
    // 애플로그인도 combine지원하지 않아서 completion handler만들어서 future로 publisher를 만들자
    func handleSignInWithAppleCompletion(_ authorization: ASAuthorization, none: String) -> AnyPublisher<User, ServiceError> {
        Future { [weak self] promise in
            self?.handleSignInWithAppleCompletion(authorization, nonce: none) { result in
                switch result {
                case let .success(user):
                    promise(.success(user))
                case let .failure(error):
                    promise(.failure(.error(error)))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 로그인 확인
    func checkAuthenticationState() -> String? {
        if let user = Auth.auth().currentUser {
            return user.uid
        } else {
            return nil
        }
    }
    
    func logout() -> AnyPublisher<Void, ServiceError> {
        Future { promise in
            do {
                try Auth.auth().signOut()
                promise(.success(()))
            } catch {
                promise(.failure(.error(error)))
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteUser() -> AnyPublisher<Void, ServiceError> {
        Future { promise in
            guard let user = Auth.auth().currentUser else {
                promise(.failure(.userNotFound))
                return
            }
            user.delete { error in
                if let error = error {
                    promise(.failure(.error(error)))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
}

// MARK: - 구글로그인은 Combine제공하지 않는다 응답으로 completion핸들러 구현하고 completion핸들러 가지고 future로 publisher만드는 작업 진행
// MARK: - 애플로그인도 combine지원하지 않아서 completion handler만들어서 future로 publisher를 만들자
extension AuthenticationService {
    // Google Sign-In의 실제 비동기 작업을 수행하는 함수입니다. 이 메서드의 결과를 signInWidhGoogle()에서 Combine의 Future로 변환하여 사용할 수 있습니다.
    private func signInWithGoogle(completion: @escaping (Result<User, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(AuthenticationError.clientIDError)) // 실패
            return
        }
        
        // 클라이언트ID로 configuration setting
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // 실제 로그인 프로세스(구글로그인 창이 뜰 뷰를 가져옴-> 윈도우에서 rootview를 추출하여 보냐주자)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        // 로그인 진행(완료시 컨프리션 호출됨)
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                // 유저정보, 토큰정보가 없다면
                completion(.failure(AuthenticationError.tokenError))
                return
            }
            
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // TODO: -
            self?.authenticateUserWithFirebase(credential: credential, platform: "Google", completion: completion)
        }
    }
    
    
    private func handleSignInWithAppleCompletion(_ authorization: ASAuthorization,
                                                 nonce: String,
                                                 completion: @escaping (Result<User, Error>) -> Void) {
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken else {
                print("애플 로그인 실패: 유효하지 않은 자격 증명")
            completion(.failure(AuthenticationError.tokenError))
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("애플 로그인 실패: ID 토큰 변환 실패") // 에러 출력 추가
            completion(.failure(AuthenticationError.tokenError))
            return
        }
        
        let credential = OAuthProvider.credential(providerID: AuthProviderID.apple,
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
                                          
        
        authenticateUserWithFirebase(credential: credential, platform: "Apple") { result in
            switch result {
            case var .success(user):
                user.name = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                    .compactMap{ $0 }
                    .joined(separator: " ")
                completion(.success(user))
            case let .failure(error):
             print("Firebase 인증 실패: \(error.localizedDescription)") // 에러 출력 추가
                completion(.failure(error))
            }
        }
    }
    
    
    // MARK: - 파이어베이스 인증 진행 함수
    private func authenticateUserWithFirebase(
        credential: AuthCredential,
        platform: String? = nil,
        birthdate: String? = nil, // 생일 매개변수 추가
        gender: String? = nil, // 성별 매개변수 추가
        completion: @escaping (Result<User, Error>) -> Void ) {
        Auth.auth().signIn(with: credential) { result, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let result else {
                completion(.failure(AuthenticationError.invalidated))
                return
            }
            
            // 현재 시간을 문자열로 변환
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 원하는 형식
            let currentDate = formatter.string(from: Date())
    
            
            let firebaseUser = result.user
            let user: User = .init(id: firebaseUser.uid,
                                   name: firebaseUser.displayName ?? "",
                                   phoneNumber: firebaseUser.phoneNumber,
                                   profileURL: firebaseUser.photoURL?.absoluteString,
                                   signupDate: currentDate,
                                   platform: platform,
                                   birthdate: birthdate, // 생일 포함
                                   gender: gender) // 성별 포함
                                
            completion(.success(user))
        }
    }
}

class StubAuthenticationService: AuthenticationServiceType {

    
    func signInWithGoogle() -> AnyPublisher<User, ServiceError> {
        Empty().eraseToAnyPublisher()
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) -> String {
        return ""
    }
    
    func handleSignInWithAppleCompletion(_ authorization: ASAuthorization, none: String) -> AnyPublisher<User, ServiceError> {
        Empty().eraseToAnyPublisher()
    }
    
    func checkAuthenticationState() -> String? {
        return nil
    }
    
    func logout() -> AnyPublisher<Void, ServiceError> {
        Empty().eraseToAnyPublisher()
    }
    
    func deleteUser() -> AnyPublisher<Void, ServiceError> {
        Empty().eraseToAnyPublisher()
    }
}


