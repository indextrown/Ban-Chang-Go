//
//  UserService.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import Foundation
import Combine

protocol UserServiceType {
    // MARK: - 여기는 서비스 layer이기 때문에 DTO가 아닌 User모델을 받도록 하자
    func addUser(_ user: User) -> AnyPublisher<User, ServiceError>
    func getUser(userId: String) -> AnyPublisher<User, ServiceError>
    func loadUsers(id: String) -> AnyPublisher<[User], ServiceError>
    func updateUserNickname(userId: String, nickname: String) -> AnyPublisher<Void, ServiceError> // 추가
    func deleteUser(userId: String) -> AnyPublisher<Void, ServiceError>
}

class UserService: UserServiceType {
    private var subscriptions = Set<AnyCancellable>() // subscriptions 추가
    
    private var dbRepository: UserDBRepositoryType
    
    init(deRepository: UserDBRepositoryType) {
        self.dbRepository = deRepository
    }
    
    func addUser(_ user: User) -> AnyPublisher<User, ServiceError> {
        dbRepository.addUser(user.toObject())
            .map { user }
            .mapError { .error($0) }
            .eraseToAnyPublisher()
    }
    
    func getUser(userId: String) -> AnyPublisher<User, ServiceError> {
        dbRepository.getUser(userId: userId)
            .map { $0.toModel() }
            .mapError { dbError in
                if case .emptyValue = dbError {
                    return .userNotFound
                } else {
                    return .error(dbError)
                }
            }
            .eraseToAnyPublisher()
    }

    
    func loadUsers(id: String) -> AnyPublisher<[User], ServiceError> {
        dbRepository.loadUsers()
            .map { $0
                .map { $0.toModel() }
                .filter { $0.id != id }
            }
            .mapError { .error($0) }
            .eraseToAnyPublisher()
    }
    
    func updateUserNickname(userId: String, nickname: String) -> AnyPublisher<Void, ServiceError> {
        let updatedUserObject = UserObject(id: userId, name: "", nickname: nickname) // 필요한 다른 속성도 추가
            return dbRepository.updateUser(updatedUserObject)
                .mapError { .error($0) }
                .eraseToAnyPublisher()
        }
    
    func deleteUser(userId: String) -> AnyPublisher<Void, ServiceError> {
        Future { promise in
            // 데이터베이스에서 사용자 삭제 로직
            self.dbRepository.deleteUser(userId: userId) // dbRepository를 사용하여 삭제
                .sink { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(.error(error)))
                    }
                } receiveValue: {
                    promise(.success(()))
                }
                .store(in: &self.subscriptions) // subscriptions에 저장
        }
        .eraseToAnyPublisher()
    }
}

class StubUserService: UserServiceType {
    func updateUserNickname(userId: String, nickname: String) -> AnyPublisher<Void, ServiceError> {
        Empty().eraseToAnyPublisher()
    }
    
    func addUser(_ user: User) -> AnyPublisher<User, ServiceError> {
        Empty().eraseToAnyPublisher()
    }
    
    func getUser(userId: String) -> AnyPublisher<User, ServiceError> {
        Just(.stub1).setFailureType(to: ServiceError.self).eraseToAnyPublisher()
    }
    
    func loadUsers(id: String) -> AnyPublisher<[User], ServiceError> {
        Just([.stub1, .stub2]).setFailureType(to: ServiceError.self).eraseToAnyPublisher()
    }
    func deleteUser(userId: String) -> AnyPublisher<Void, ServiceError> {
        Empty().eraseToAnyPublisher()
    }
}

// 실제 구현체와 의존성이 없으므로 실제 유저DB 리퍼지토리가 아닌 다른 구현체에도 주입을 할 수가 있고
// 느슨한 결합을 하기 위해 사용..
