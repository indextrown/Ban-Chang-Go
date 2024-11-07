//
//  ProfileView.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI
import Combine

/*
class ProfileViewModel: ObservableObject {
    enum Action {
        case load
    }
    
    @Published var myUser: User?
    @Published var phase: Phase = .notRequested
    
    private var userId: String
    private var container: DIContainer
    private var subscriptions = Set<AnyCancellable>()
    
    init(container: DIContainer, userId: String, currentUser: User?) {
        self.container = container
        self.userId = userId
        self.myUser = currentUser
        //print("Initialized ProfileViewModel with User: \(String(describing: myUser))") // 추가: 초기화된 사용자 정보 출력
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
*/
//
//struct ProfileView: View {
//    @EnvironmentObject var authVM: AuthenticationViewModel
//    @EnvironmentObject var profileVM: HomeViewModel
//    //@StateObject var profileVM: ProfileViewModel
//    
//    @State private var nickname: String = ""
//    @State private var isEditing: Bool = false
//    
//    var body: some View {
//        
//        ZStack {
//            Color.gray1 // 전체 화면 배경색 설정
//                .edgesIgnoringSafeArea(.all) // 화면의 모든 영역을 채우도록 설정
//            ScrollView {
//                VStack(spacing: 20) {
//                    HStack {
//                        Text("설정")
//                            .font(.system(size: 35, weight: .bold))
//                        Spacer()
//                    }
//                    RectViewHC(height: 50, color: .white, radius: 15)
//                                .overlay {
//                                    Button(action: {
//                                        isEditing.toggle()
//                                    }) {
//                                        HStack {
//                                            Text(profileVM.myUser?.nickname ?? "닉네임")
//                                                .foregroundColor(.bkText)
//                                            Spacer()
//                                        }
//                                        .padding()
//                                    }
//                                }
//                                .sheet(isPresented: $isEditing) {
//                                    NicknameEditView(isEditing: $isEditing, nickname: $nickname, profileVM: profileVM, authVM: authVM)
//                                }
//                    
//                    RectViewHC(height: 100, color: .white, radius: 15)
//                        .overlay {
//                            VStack(spacing: 0) { // spacing을 0으로 설정하고 개별 padding으로 조절
//                                Button {
//                                    // 첫 번째 버튼 동작
//                                } label: {
//                                    HStack {
//                                        Text("공지사항")
//                                            .foregroundColor(.black)
//                                            .padding(.bottom, 12.5) // 구분선 위쪽 여백 설정
//                                        Spacer()
//                                    }
//                                    .padding(.leading, 20)
//                                }
//                                
//                                Rectangle()
//                                    .fill(Color.gray.opacity(0.4))
//                                    .frame(height: 1)
//                                    .padding(.horizontal, 15)
//                                
//                                Button {
//                                    // 두 번째 버튼 동작
//                                } label: {
//                                    HStack {
//                                        Text("버전")
//                                            .foregroundColor(.black)
//                                            .padding(.top, 12.5) // 구분선 아래쪽 여백 설정
//                                        Spacer()
//                                    }
//                                    .padding(.leading, 20)
//                                }
//                            }
//                        }
//                    
//                    RectViewHC(height: 50, color: .white, radius: 15)
//                        .overlay {
//                            Button {
//                                
//                            } label: {
//                                HStack {
//                                    Text("계정탈퇴")
//                                        .foregroundColor(.black)
//                                    Spacer()
//                                }
//                                .padding()
//                            }
//                        }
//                    
//                    Button {
//                        authVM.send(action: .logout)
//                    } label: {
//                        Text("로그아웃")
//                            .foregroundColor(.red)
//                    }
//                    
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 30)
//            }
//        }
//    }
//}
//
//// 별도의 닉네임 편집 뷰 생성
//struct NicknameEditView: View {
//    @Binding var isEditing: Bool
//    @Binding var nickname: String
//    @ObservedObject var profileVM: ProfileViewModel
//    @ObservedObject var authVM: AuthenticationViewModel
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("닉네임 수정")
//                .font(.headline)
//            
//            TextField("새로운 닉네임을 입력하세요", text: $nickname)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//            
//            HStack {
//                Button("취소") {
//                    isEditing = false
//                }
//                .padding()
//                
//                Spacer()
//                
//                Button("저장") {
//                    profileVM.myUser?.nickname = nickname
//                    authVM.send(action: .updateNickname(nickname))
//                    isEditing = false
//                    
//                    authVM.currentUser?.nickname = nickname
//                }
//                .padding()
//            }
//            .padding()
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    let container = DIContainer(services: StubService()) // DIContainer 초기화
//    let user = User(id: "user1_id", name: "jemas", nickname: "Preview User") // User 객체 생성
//    
//    return ProfileView(
//        profileVM: ProfileViewModel(container: container, userId: "user1_id", currentUser: user)
//    )
//    .environmentObject(AuthenticationViewModel(container: container)) // authVM 주입
//}
//
//
//
//
//    /*
//    @ViewBuilder
//    var contentView: some View {
//        switch profileVM.phase {
//        case .notRequested:
//            PlaceHolderView()
//                .onAppear {
//                    profileVM.send(action: .load)
//                }
//        case .loading:
//            ProgressView()
//                .background(Color.gray1)
//        case .success:
//            ZStack {
//                Color.gray1 // 전체 화면 배경색 설정
//                   .edgesIgnoringSafeArea(.all) // 화면의 모든 영역을 채우도록 설정
//                ScrollView {
//                    VStack(spacing: 20) {
//                        // 실제 View 내용
//                        RectViewHC(height: 50, color: .white, radius: 15)
//                            .overlay {
//                                HStack {
//                                    Text("닉네임")
//                                    Spacer()
//                                    Text(profileVM.myUser?.nickname ?? "닉네임")
//                                }
//                                .padding()
//                            }
//                        RectViewHC(height: 50, color: .white, radius: 15)
//                        RectViewHC(height: 50, color: .white, radius: 15)
//                        
//                        Button {
//                            authVM.send(action: .logout)
//                        } label: {
//                            Text("로그아웃")
//                                .foregroundColor(.red)
//                        }
//                        
//                    }
//                    .padding(.horizontal, 30)
//                    .padding(.top, 30)
//                }
//           }
//            //LoadedView()
//                //.environmentObject(profileVM)
//               
//        case .fail:
//            ErrorView()
//        }
//    }
//     */
//
//
//
////#Preview {
////    ProfileView( homeVM: .init(container: .init(services: StubService()), userId: "user1_id"), profileVM: <#ProfileViewModel#>)
////}
//
///*
//VStack(spacing: 20) {
//    HStack {
//        RectViewH(height: 300, color: .white)
////                Text("닉네임")
////                    .font(.headline)
////                    .foregroundColor(.black)
////
////                Spacer()
////
////                if isEditing {
////                    TextField("닉네임", text: $nickname)
////                        .textFieldStyle(RoundedBorderTextFieldStyle())
////                        .padding()
////                } else {
////                    Text(nickname.isEmpty ? "닉네임이 없습니다" : nickname)
////                        .font(.title2)
////                        .foregroundColor(.mainorange)
////                }
//    }
//
////
////            Button {
////                authVM.send(action: .logout)
////            } label: {
////                Text("로그아웃")
////                    .foregroundColor(.red)
////            }
//}
//*/



import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var homeVM: HomeViewModel

    @State private var nickname: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        ZStack {
            Color.gray1
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("설정")
                            .font(.system(size: 35, weight: .bold))
                        Spacer()
                    }
                    
                    // 닉네임 수정 버튼
                    RectViewHC(height: 50, color: .white, radius: 15)
                        .overlay {
                            Button(action: {
                                isEditing.toggle()
                            }) {
                                HStack {
                                    Text(homeVM.myUser?.nickname ?? "닉네임")
                                        .foregroundColor(.bkText)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                        .sheet(isPresented: $isEditing) {
                            NicknameEditView(isEditing: $isEditing, nickname: $nickname, profileVM: homeVM, authVM: authVM)
                        }
                    
                    // 공지사항 및 버전 정보
                    RectViewHC(height: 100, color: .white, radius: 15)
                        .overlay {
                            VStack(spacing: 0) {
                                Button {
                                    // 공지사항 동작
                                } label: {
                                    HStack {
                                        Text("공지사항")
                                            .foregroundColor(.black)
                                            .padding(.bottom, 12.5)
                                        Spacer()
                                    }
                                    .padding(.leading, 20)
                                }
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.4))
                                    .frame(height: 1)
                                    .padding(.horizontal, 15)
                                
                                Button {
                                    // 버전 정보 동작
                                } label: {
                                    HStack {
                                        Text("버전")
                                            .foregroundColor(.black)
                                            .padding(.top, 12.5)
                                        Spacer()
                                    }
                                    .padding(.leading, 20)
                                }
                            }
                        }
                    
                    // 계정 탈퇴 버튼
                    RectViewHC(height: 50, color: .white, radius: 15)
                        .overlay {
                            Button {
                                // 계정 탈퇴 동작
                            } label: {
                                HStack {
                                    Text("계정탈퇴")
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                    
                    // 로그아웃 버튼
                    Button {
                        authVM.send(action: .logout)
                    } label: {
                        Text("로그아웃")
                            .foregroundColor(.red)
                    }
                    
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
            }
        }
    }
}

// 별도의 닉네임 편집 뷰 생성
struct NicknameEditView: View {
    @Binding var isEditing: Bool
    @Binding var nickname: String
    @ObservedObject var profileVM: HomeViewModel
    @ObservedObject var authVM: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("닉네임 수정")
                .font(.headline)
            
            TextField("새로운 닉네임을 입력하세요", text: $nickname)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("취소") {
                    isEditing = false
                }
                .padding()
                
                Spacer()
                
                Button("저장") {
                    profileVM.myUser?.nickname = nickname
                    authVM.send(action: .updateNickname(nickname))
                    isEditing = false
                    authVM.currentUser?.nickname = nickname
                }
                .padding()
            }
            .padding()
        }
        .padding()
    }
}
