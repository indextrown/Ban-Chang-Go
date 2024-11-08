//
//  NoticeService.swift
//  Banchango
//
//  Created by 김동현 on 11/8/24.
//

import Foundation
import FirebaseDatabase
import Combine


class NoticeService {
    private var db: DatabaseReference = Database.database().reference()
    
    func fetchNotices() -> AnyPublisher<[Notice], DBError> {
        Future<Any, DBError> { promise in
            self.db.child("notices").getData { error, snapshot in
                if let error = error {
                    promise(.failure(DBError.error(error)))
                } else if snapshot?.value is NSNull {
                    promise(.success([])) // 데이터가 없을 경우 빈 배열 반환
                } else {
                    promise(.success(snapshot?.value as? [String: Any] ?? [:]))
                }
            }
        }
        .flatMap { value in
            if let dic = value as? [String: [String: Any]] {
                return Just(dic)
                    .tryMap { try JSONSerialization.data(withJSONObject: $0) }
                    .decode(type: [String: Notice].self, decoder: JSONDecoder())
                    .map { $0.values.map { $0 } } // Notice 객체 배열로 변환
                    .mapError { DBError.error($0) }
                    .eraseToAnyPublisher()
            } else {
                return Fail(error: .invalidatedType).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
}
