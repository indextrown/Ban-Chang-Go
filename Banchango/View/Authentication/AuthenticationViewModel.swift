////
////  AuthenricationViewModel.swift
////  Banchango
////
////  Created by 김동현 on 9/8/24.
////
//
//
//import SwiftUI
//import Combine
//import Firebase
//import KakaoSDKAuth
//import KakaoSDKUser
//
//class AuthenticationViewModel: ObservableObject {
//    @Published var isNicknameRequired = false
//    @Published var user: User?                  // 사용자 정보 저장
//    @Published var isLoggedIn = false           // 로그인 상태 변화 감지
//    @Published var hasProfile: Bool = false
//    @Published var isLoading = false            // 로딩 상태 초기값 false로 설정
//    
//    
//    @AppStorage("userId") var userId: String? {
//        didSet {
//            // userId가 변경될 때 isLoggedIn 값을 업데이트
//            // 값이 존재하면 true
//            isLoggedIn = (userId != nil)
//        }
//    }
//    
//    // 로그인 유형을 저장할 @AppStorage 속성 추가
//    @AppStorage("loginType") var loginType: String?
//    
//    init() {
//        // 앱이 시작될 때 로그인 상태 확인
//        checkLoginStatus()
//    }
//    
//    func checkLoginStatus() {
//        // 로딩 시작
//        isLoading = true
//        
//        // 사용자 ID가 존재하면 Firestore에서 유저 정보를 확인
//        if let userId = userId {
//            checkIfUIDExistsInFirestore(uid: userId)
//        } else {
//            // 사용자 ID가 없으면 로그인 화면 표시
//            isLoggedIn = false
//            isNicknameRequired = false
//            isLoading = false
//        }
//    }
//    
//    func checkIfUIDExistsInFirestore(uid: String) {
//        let db = Firestore.firestore()
//        let docRef = db.collection("users").document(uid)
//        
//        docRef.getDocument { document, error in
//            if let document = document, document.exists {
//                // UID가 Firebase에 존재하는 경우 User 객체 생성
//                let data = document.data()
//                let nickname = data?["nickname"] as? String ?? ""
//                self.user = User(id: uid, nickname: nickname)
//                self.userId = uid
//                self.isLoggedIn = true
//            } else {
//                // UID가 존재하지 않는 경우: 닉네임 입력 화면 표시
//                self.isNicknameRequired = true
//                self.isLoggedIn = false
//            }
//            // 로딩 종료
//            self.isLoading = false
//        }
//    }
//    
//    func saveUIDAndNicknameToFirestore(uid: String, nickname: String) {
//        let db = Firestore.firestore()
//        let user = User(id: uid, nickname: nickname)
//        
//        db.collection("users").document(uid).setData([
//            "uid": user.id,
//            "nickname": user.nickname
//        ]) { error in
//            if let error = error {
//                print("유저 데이터 저장 실패: \(error.localizedDescription)")
//            } else {
//                print("유저 데이터 저장 성공!")
//                self.user = user    // 사용자 정보 업데이트
//                self.userId = uid   // 로그인 상태를 유지하기 위해 userId 저장
//                self.isNicknameRequired = false
//            }
//        }
//    }
//    
//    // MARK: - 카카오로그인
//    func kakaoLogin() {
//        // 카카오톡으로 로그인 시도
//        if UserApi.isKakaoTalkLoginAvailable() {
//            UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
//                if let error = error {
//                    print("카카오톡 로그인 실패: \(error.localizedDescription)")
//                    return
//                }
//                self?.loginType = "Kakao"
//                self?.fetchUserInfo()
//            }
//        } else {
//            // 카카오 계정으로 로그인 시도
//            UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
//                if let error = error {
//                    print("카카오 계정 로그인 실패: \(error.localizedDescription)")
//                    return
//                }
//                self?.loginType = "Kakao"
//                self?.fetchUserInfo()
//            }
//        }
//    }
//
//    private func fetchUserInfo() {
//        UserApi.shared.me { [weak self] (user, error) in
//            if let error = error {
//                print("사용자 정보 요청 실패: \(error.localizedDescription)")
//                return
//            }
//            guard let user = user else {
//                print("사용자 정보가 없습니다.")
//                return
//            }
//            // 사용자 정보 추출
//            guard let id = user.id else {
//                print("사용자 ID가 없습니다.")
//                return
//            }
//            
//            let uid = "\(id)"
//            print("디버깅: \(uid)")
//            
//
//            
//            let nickname = user.kakaoAccount?.profile?.nickname ?? "Unknown"
//            
//            // User 객체 생성
//            self?.user = User(id: uid, nickname: nickname)
//            
//            // uid를 받으면 @AppStorage("userId") var userId: String?에 저정해야해
//            self?.userId = uid
//            
//            // Firestore에 UID 존재 여부 확인
//            self?.checkIfUIDExistsInFirestore(uid: uid)
//        }
//    }
//    
//    func fetchArrayFromFirestore(forKey key: String, completion: @escaping ([String]?) -> Void) {
//        let db = Firestore.firestore()
//        let docRef = db.collection("yourCollectionName").document("yourDocumentId") // 적절한 컬렉션과 문서 ID로 변경하세요
//        
//        docRef.getDocument { document, error in
//            if let error = error {
//                print("문서 가져오기 실패: \(error.localizedDescription)")
//                completion(nil)
//                return
//            }
//            
//            guard let document = document, document.exists,
//                  let data = document.data(),
//                  let array = data[key] as? [String] else {
//                print("문서가 없거나 배열이 없음.")
//                completion(nil)
//                return
//            }
//            
//            completion(array)
//        }
//    }
//    
//    func logout() {
//        if loginType == "Kakao" {
//            UserApi.shared.logout { [weak self] (error) in
//                if let error = error {
//                    print("카카오 로그아웃 실패: \(error.localizedDescription)")
//                } else {
//                    print("카카오 로그아웃 성공")
//                    self?.clearUserData() // 사용자 관련 데이터 초기화
//                }
//            }
//        } else {
//            clearUserData()
//            /*
//            // firebase 인증 로그아웃 처리(필요시)
//            do {
//                try Auth.auth().signOut()
//            } catch let signOutError as NSError {
//                //print("Error signing out: %@", signOutError)
//            }
//             */
//        }
//    }
//    
//    
//    // 사용자 관련 데이터 초기화
//    private func clearUserData() {
//        // 사용자 관련 데이터 초기화
//        self.user = nil
//        self.userId = nil
//        self.isLoggedIn = false
//        self.isNicknameRequired = false
//        self.loginType = nil
//        // Firebase 인증 로그아웃이 필요한 경우 처리
//        /*
//        do {
//            try Auth.auth().signOut()
//        } catch let signOutError as NSError {
//            print("Error signing out: %@", signOutError)
//        }
//        */
//        print("로그아웃 완료")
//        
//    }
//    
//    
//    // 로그아웃 시 실행되는 메서드
//    // 로그웃이 끝나고 draw값을 변경하기 위해 사용
//    func onLogout(completion: @escaping () -> Void) {
//        if !isLoggedIn {
//            completion()
//        }
//    }
//    
//
//    func checkIfNicknameExists(uid: String, completion: @escaping (Bool) -> Void) {
//        let db = Firestore.firestore()
//        let docRef = db.collection("users").document(uid)
//        
//        docRef.getDocument { document, error in
//            if let error = error {
//                print("닉네임 확인 중 오류 발생: \(error.localizedDescription)")
//                completion(false) // 오류 발생 시 false 반환
//                return
//            }
//            
//            guard let document = document, document.exists,
//                  let data = document.data(),
//                  let nickname = data["nickname"] as? String, !nickname.isEmpty else {
//                print("닉네임이 존재하지 않음.")
//                completion(false) // 닉네임이 없으면 false 반환
//                return
//            }
//            
//            print("닉네임이 존재합니다: \(nickname)")
//            completion(true) // 닉네임이 존재하면 true 반환
//        }
//    }
//
//}


//
//
//import SwiftUI
//import Combine
//import Firebase
//import KakaoSDKAuth
//import KakaoSDKUser
//
//class AuthenticationViewModel: ObservableObject {
//    @Published var isNicknameRequired = false
//    @Published var user: User?                  // 사용자 정보 저장
//    @Published var isLoggedIn = false           // 로그인 상태 변화 감지
//    @Published var hasProfile: Bool = false
//    @Published var isLoading = false            // 로딩 상태 초기값 false로 설정
//    
//    @AppStorage("userId") var userId: String? {
//        didSet {
//            // userId가 변경될 때 isLoggedIn 값을 업데이트
//            // 값이 존재하면 true
//            isLoggedIn = (userId != nil)
//        }
//    }
//    
//    // 로그인 유형을 저장할 @AppStorage 속성 추가
//    @AppStorage("loginType") var loginType: String?
//    
//    init() {
//        // 앱이 시작될 때 로그인 상태 확인
//        checkLoginStatus()
//    }
//    
//    func checkLoginStatus() {
//       isLoading = true // 로그인 상태 확인 시작 시 로딩 상태로 설정
//
//       if let userId = userId {
//           checkIfUIDExistsInFirestore(uid: userId) { exists in
//               if exists {
//                   self.checkIfNicknameExists(uid: userId) { nicknameExists in
//                       if nicknameExists {
//                           self.isNicknameRequired = false
//                           self.isLoggedIn = true
//                       } else {
//                           self.isNicknameRequired = true
//                       }
//                       self.isLoading = false // 상태 확인 후 로딩 종료
//                   }
//               } else {
//                   self.isLoggedIn = false
//                   self.isNicknameRequired = true
//                   self.isLoading = false
//               }
//           }
//       } else {
//           self.isLoggedIn = false
//           self.isNicknameRequired = false
//           self.isLoading = false
//       }
//   }
//       
//    func checkIfUIDExistsInFirestore(uid: String, completion: @escaping (Bool) -> Void) {
//        let db = Firestore.firestore()
//        let docRef = db.collection("users").document(uid)
//        
//        docRef.getDocument { document, error in
//            if let error = error {
//                print("UID 확인 중 오류 발생: \(error.localizedDescription)")
//                completion(false)
//                return
//            }
//            
//            if let document = document, document.exists {
//                print("UID가 존재합니다.")
//                completion(true)
//            } else {
//                print("UID가 존재하지 않습니다.")
//                completion(false)
//            }
//        }
//    }
//    
//    func checkIfNicknameExists(uid: String, completion: @escaping (Bool) -> Void) {
//        let db = Firestore.firestore()
//        let docRef = db.collection("users").document(uid)
//        
//        docRef.getDocument { document, error in
//            if let error = error {
//                print("닉네임 확인 중 오류 발생: \(error.localizedDescription)")
//                completion(false)
//                return
//            }
//            
//            guard let document = document, document.exists,
//                  let data = document.data(),
//                  let nickname = data["nickname"] as? String, !nickname.isEmpty else {
//                print("닉네임이 존재하지 않음.")
//                completion(false)
//                return
//            }
//            
//            print("닉네임이 존재합니다: \(nickname)")
//            completion(true)
//        }
//    }
//    
//    func saveUIDAndNicknameToFirestore(uid: String, nickname: String) {
//        let db = Firestore.firestore()
//        let user = User(id: uid, nickname: nickname)
//        
//        db.collection("users").document(uid).setData([
//            "uid": user.id,
//            "nickname": user.nickname
//        ]) { error in
//            if let error = error {
//                print("유저 데이터 저장 실패: \(error.localizedDescription)")
//            } else {
//                print("유저 데이터 저장 성공!")
//                self.user = user    // 사용자 정보 업데이트
//                self.userId = uid   // 로그인 상태를 유지하기 위해 userId 저장
//                self.isNicknameRequired = false
//            }
//        }
//    }
//    
//    // MARK: - 카카오로그인
//    func kakaoLogin() {
//        // 카카오톡으로 로그인 시도
//        if UserApi.isKakaoTalkLoginAvailable() {
//            UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
//                if let error = error {
//                    print("카카오톡 로그인 실패: \(error.localizedDescription)")
//                    return
//                }
//                self?.loginType = "Kakao"
//                self?.fetchUserInfo()
//            }
//        } else {
//            // 카카오 계정으로 로그인 시도
//            UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
//                if let error = error {
//                    print("카카오 계정 로그인 실패: \(error.localizedDescription)")
//                    return
//                }
//                self?.loginType = "Kakao"
//                self?.fetchUserInfo()
//            }
//        }
//    }
//
//    private func fetchUserInfo() {
//        UserApi.shared.me { [weak self] (user, error) in
//            if let error = error {
//                print("사용자 정보 요청 실패: \(error.localizedDescription)")
//                return
//            }
//            guard let user = user else {
//                print("사용자 정보가 없습니다.")
//                return
//            }
//            // 사용자 정보 추출
//            guard let id = user.id else {
//                print("사용자 ID가 없습니다.")
//                return
//            }
//            
//            let uid = "\(id)"
//            print("디버깅: \(uid)")
//            
//            let nickname = user.kakaoAccount?.profile?.nickname ?? "Unknown"
//            
//            // User 객체 생성
//            self?.user = User(id: uid, nickname: nickname)
//            self?.userId = uid // UID를 @AppStorage에 저장
//            
//            // Firestore에서 UID 확인 및 닉네임 확인
//            self?.checkIfUIDExistsInFirestore(uid: uid) { uidExists in
//                if uidExists {
//                    self?.checkIfNicknameExists(uid: uid) { nicknameExists in
//                        if nicknameExists {
//                            print("로그인 성공")
//                            self?.isNicknameRequired = false
//                            self?.isLoggedIn = true
//                        } else {
//                            print("닉네임 입력 필요")
//                            self?.isNicknameRequired = true
//                            self?.isLoggedIn = false
//                        }
//                    }
//                } else {
//                    print("UID가 존재하지 않음. 닉네임 입력 필요")
//                    self?.isNicknameRequired = true
//                    self?.isLoggedIn = false
//                }
//            }
//        }
//    }
//    
//    func logout() {
//        if loginType == "Kakao" {
//            UserApi.shared.logout { [weak self] (error) in
//                if let error = error {
//                    print("카카오 로그아웃 실패: \(error.localizedDescription)")
//                } else {
//                    print("카카오 로그아웃 성공")
//                    self?.clearUserData()
//                }
//            }
//        } else {
//            clearUserData()
//        }
//    }
//    
//    private func clearUserData() {
//        self.user = nil
//        self.userId = nil
//        self.isLoggedIn = false
//        self.isNicknameRequired = false
//        self.loginType = nil
//    }
//    
//    func onLogout(completion: @escaping () -> Void) {
//        if !isLoggedIn {
//            completion()
//        }
//    }
//}
//
//
import SwiftUI
import Combine
import Firebase
import KakaoSDKAuth
import KakaoSDKUser

class AuthenticationViewModel: ObservableObject {
    @Published var isNicknameRequired = false
    @Published var user: User?                  // 사용자 정보 저장
    @Published var isLoggedIn = false           // 로그인 상태 변화 감지
    @Published var hasProfile: Bool = false
    @Published var isLoading = false            // 로딩 상태 초기값 false로 설정
    
    @AppStorage("userId") var userId: String? {
        didSet {
            DispatchQueue.main.async {
                // userId가 변경될 때 isLoggedIn 값을 업데이트
                self.isLoggedIn = (self.userId != nil)
            }
        }
    }
    
    @AppStorage("loginType") var loginType: String?
    
    init() {
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        isLoading = true
        if let userId = userId {
            checkIfUIDExistsInFirestore(uid: userId) { exists in
                DispatchQueue.main.async {
                    if exists {
                        self.checkIfNicknameExists(uid: userId) { nicknameExists in
                            DispatchQueue.main.async {
                                if nicknameExists {
                                    self.isNicknameRequired = false
                                    self.isLoggedIn = true
                                } else {
                                    self.isNicknameRequired = true
                                }
                                self.isLoading = false
                            }
                        }
                    } else {
                        self.isLoggedIn = false
                        self.isNicknameRequired = true
                        self.isLoading = false
                    }
                }
            }
        } else {
            self.isLoggedIn = false
            self.isNicknameRequired = false
            self.isLoading = false
        }
    }
    
    func checkIfUIDExistsInFirestore(uid: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async { // 백그라운드 스레드에서 Firestore 요청 실행
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(uid)

            docRef.getDocument { document, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("UID 확인 중 오류 발생: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    if let document = document, document.exists {
                        print("UID가 존재합니다.")
                        completion(true)
                    } else {
                        print("UID가 존재하지 않습니다.")
                        completion(false)
                    }
                }
            }
        }
    }

    func checkIfUIDExistsInFirestore2(uid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { document, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("UID 확인 중 오류 발생: \(error.localizedDescription)")
                    completion(false)
                }
                return
            }
            
            if let document = document, document.exists {
                DispatchQueue.main.async {
                    print("UID가 존재합니다.")
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    print("UID가 존재하지 않습니다.")
                    completion(false)
                }
            }
        }
    }
    
    func checkIfNicknameExists(uid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { document, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("닉네임 확인 중 오류 발생: \(error.localizedDescription)")
                    completion(false)
                }
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let nickname = data["nickname"] as? String, !nickname.isEmpty else {
                DispatchQueue.main.async {
                    print("닉네임이 존재하지 않음.")
                    completion(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                print("닉네임이 존재합니다: \(nickname)")
                completion(true)
            }
        }
    }
    
    func saveUIDAndNicknameToFirestore(uid: String, nickname: String) {
        let db = Firestore.firestore()
        let user = User(id: uid, nickname: nickname)
        
        db.collection("users").document(uid).setData([
            "uid": user.id,
            "nickname": user.nickname
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("유저 데이터 저장 실패: \(error.localizedDescription)")
                } else {
                    print("유저 데이터 저장 성공!")
                    self.user = user    // 사용자 정보 업데이트
                    self.userId = uid   // 로그인 상태를 유지하기 위해 userId 저장
                    self.isNicknameRequired = false
                }
            }
        }
    }
    
    // MARK: - 카카오로그인
    func kakaoLogin() {
        // 카카오톡으로 로그인 시도
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
                if let error = error {
                    print("카카오톡 로그인 실패: \(error.localizedDescription)")
                    return
                }
                self?.loginType = "Kakao"
                self?.fetchUserInfo()
            }
        } else {
            // 카카오 계정으로 로그인 시도
            UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
                if let error = error {
                    print("카카오 계정 로그인 실패: \(error.localizedDescription)")
                    return
                }
                self?.loginType = "Kakao"
                self?.fetchUserInfo()
            }
        }
    }

    private func fetchUserInfo() {
        UserApi.shared.me { [weak self] (user, error) in
            if let error = error {
                print("사용자 정보 요청 실패: \(error.localizedDescription)")
                return
            }
            guard let user = user else {
                print("사용자 정보가 없습니다.")
                return
            }
            // 사용자 정보 추출
            guard let id = user.id else {
                print("사용자 ID가 없습니다.")
                return
            }
            
            let uid = "\(id)"
            let nickname = user.kakaoAccount?.profile?.nickname ?? "Unknown"
            
            DispatchQueue.main.async {
                self?.user = User(id: uid, nickname: nickname)
                self?.userId = uid // UID를 @AppStorage에 저장
                self?.checkIfUIDExistsInFirestore(uid: uid) { _ in }
            }
        }
    }
    
    func logout() {
        if loginType == "Kakao" {
            UserApi.shared.logout { [weak self] (error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("카카오 로그아웃 실패: \(error.localizedDescription)")
                    } else {
                        print("카카오 로그아웃 성공")
                        self?.clearUserData()
                    }
                }
            }
        } else {
            clearUserData()
        }
    }
    
    private func clearUserData() {
        DispatchQueue.main.async {
            self.user = nil
            self.userId = nil
            self.isLoggedIn = false
            self.isNicknameRequired = false
            self.loginType = nil
        }
    }
}
