////
////  NoticeService.swift
////  Banchango
////
////  Created by 김동현 on 11/8/24.
////
//
//import Foundation
//import Combine
//import FirebaseDatabaseInternal
//
//protocol NoticeServiceType {
//    func fetchNotices() -> AnyPublisher<[Notice], ServiceError>
//}
//
//class NoticeService: NoticeServiceType {
//    private var db: DatabaseReference = Database.database().reference()
//    
//    func fetchNotices() -> AnyPublisher<[Notice], ServiceError> {
//        Future<Any, ServiceError> { promise in
//            self.db.child("notices").getData { error, snapshot in
//                if let error = error {
//                    promise(.failure(.error(error)))
//                } else if snapshot?.value is NSNull {
//                    promise(.success([])) // 데이터가 없을 경우 빈 배열 반환
//                } else {
//                    promise(.success(snapshot?.value as? [String: Any] ?? [:]))
//                }
//            }
//        }
//        .flatMap { value in
//            if let dic = value as? [String: [String: Any]] {
//                return Just(dic)
//                    .tryMap { try JSONSerialization.data(withJSONObject: $0) }
//                    .decode(type: [String: Notice].self, decoder: JSONDecoder())
//                    .map { $0.values.map { $0 } } // Notice 객체 배열로 변환
//                    .mapError { ServiceError.error($0) }
//                    .eraseToAnyPublisher()
//            } else {
//                return Fail(error: .error(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid data format"]))).eraseToAnyPublisher()
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//}
