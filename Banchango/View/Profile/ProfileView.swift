//
//  ProfileView.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI

import Combine

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
        print("Initialized ProfileViewModel with User: \(String(describing: myUser))") // 추가: 초기화된 사용자 정보 출력
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

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject var profileVM: ProfileViewModel
    
    @State private var nickname: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        ZStack {
            Color.gray1 // 전체 화면 배경색 설정
               .edgesIgnoringSafeArea(.all) // 화면의 모든 영역을 채우도록 설정
            ScrollView {
                VStack(spacing: 20) {
                    // 실제 View 내용
                    RectViewHC(height: 50, color: .white, radius: 15)
                        .overlay {
                            HStack {
                                Text("닉네임")
                                Spacer()
                                Text(profileVM.myUser?.nickname ?? "닉네임")
                            }
                            .padding()
                        }
                    RectViewHC(height: 50, color: .white, radius: 15)
                    RectViewHC(height: 50, color: .white, radius: 15)
                    
                    Button {
                        authVM.send(action: .logout)
                    } label: {
                        Text("로그아웃")
                            .foregroundColor(.red)
                    }
                    
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
            }
       }
    }
    
    /*
    @ViewBuilder
    var contentView: some View {
        switch profileVM.phase {
        case .notRequested:
            PlaceHolderView()
                .onAppear {
                    profileVM.send(action: .load)
                }
        case .loading:
            ProgressView()
                .background(Color.gray1)
        case .success:
            ZStack {
                Color.gray1 // 전체 화면 배경색 설정
                   .edgesIgnoringSafeArea(.all) // 화면의 모든 영역을 채우도록 설정
                ScrollView {
                    VStack(spacing: 20) {
                        // 실제 View 내용
                        RectViewHC(height: 50, color: .white, radius: 15)
                            .overlay {
                                HStack {
                                    Text("닉네임")
                                    Spacer()
                                    Text(profileVM.myUser?.nickname ?? "닉네임")
                                }
                                .padding()
                            }
                        RectViewHC(height: 50, color: .white, radius: 15)
                        RectViewHC(height: 50, color: .white, radius: 15)
                        
                        Button {
                            authVM.send(action: .logout)
                        } label: {
                            Text("로그아웃")
                                .foregroundColor(.red)
                        }
                        
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 30)
                }
           }
            //LoadedView()
                //.environmentObject(profileVM)
               
        case .fail:
            ErrorView()
        }
    }
     */
}


//#Preview {
//    ProfileView( homeVM: .init(container: .init(services: StubService()), userId: "user1_id"))
//}

/*
VStack(spacing: 20) {
    HStack {
        RectViewH(height: 300, color: .white)
//                Text("닉네임")
//                    .font(.headline)
//                    .foregroundColor(.black)
//
//                Spacer()
//
//                if isEditing {
//                    TextField("닉네임", text: $nickname)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .padding()
//                } else {
//                    Text(nickname.isEmpty ? "닉네임이 없습니다" : nickname)
//                        .font(.title2)
//                        .foregroundColor(.mainorange)
//                }
    }

//
//            Button {
//                authVM.send(action: .logout)
//            } label: {
//                Text("로그아웃")
//                    .foregroundColor(.red)
//            }
}
*/
