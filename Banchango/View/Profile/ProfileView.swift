//
//  ProfileView.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var motionManager: HeadphoneMotionManager
    @StateObject private var noticeVM = NoticeViewModel()

    @State private var nickname: String = ""
    @State private var isEditing: Bool = false
    @State private var showDeleteConfiguration = false
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return version
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.gray1
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
//                        Spacer()
//                            .frame(height: 10)
                        HStack {
                            Text("설정")
                                .font(.system(size: 35, weight: .bold))
                            Spacer()
                        }
                        .padding(.bottom, 10)
                        
                        
                        
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
                                    .onDisappear {
                                        DispatchQueue.main.async {
                                            // 키보드 닫기
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }
                                    }
                            }

                        RectViewHC(height: 100, color: .white, radius: 15)
                            .overlay {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: NoticeView(noticeVM: noticeVM)) {
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
                                        let urlSecondString = Bundle.main.infoDictionary?["KAKAO_OPENCHAT_URL"] as? String ?? ""
                                        
                                        // 버전 정보 동작
                                        if let url = URL(string: "https://\(urlSecondString)") {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        HStack {
                                            Text("문의하기")
                                                .foregroundColor(.black)
                                                .padding(.top, 12.5)
                                            Spacer()
                                        }
                                        .padding(.leading, 20)
                                    }
                                }
                            }

                        RectViewHC(height: 100, color: .white, radius: 15)
                            .overlay {
                                VStack(spacing: 0) {
                                    Button {
                                        
                                        let urlSecondString = Bundle.main.infoDictionary?["NOTION_URL"] as? String ?? ""
                                        
                                        if let url = URL(string: "https://\(urlSecondString)") {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        HStack {
                                            Text("개인정보처리방침")
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
                                    
                                    HStack {
                                        Text("버전정보")
                                            .foregroundColor(.black)
                                            .padding(.top, 12.5)
                                        Spacer()
                                        
                                        Text(appVersion)
                                            .padding(.top, 12.5)
                                    }
                                    .padding(.horizontal, 20)

                                }
                            }
                        
                        // 계정 탈퇴 버튼
                        RectViewHC(height: 50, color: .white, radius: 15)
                            .overlay {
                                Button {
                                    if motionManager.isMonitoring {
                                        motionManager.stopMonitoring()
                                    }
                                    showDeleteConfiguration = true
                                    
                                    // 계정 탈퇴 동작
                                    // authVM.send(action: .deleteAccount)
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
                            if motionManager.isMonitoring {
                                motionManager.stopMonitoring()
                            }
                            authVM.send(action: .logout)
                        } label: {
                            Text("로그아웃")
                                .foregroundColor(.red)
                        }
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .alert(isPresented: $showDeleteConfiguration) {
                        Alert(
                            title: Text("계정 삭제"),
                            message: Text("정말로 계정을 삭제하시겠습니가?"),
                            primaryButton: .destructive(Text("삭제")) {
                                authVM.send(action: .deleteAccount)
                            },
                            secondaryButton: .cancel()
                            
                        )
                    }
                }
            }
        }
        .onAppear {
            noticeVM.loadNotices() // ProfileView가 나타날 때 공지사항 로드
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock DIContainer 및 ViewModel 설정
        let container = DIContainer(services: Services())
        let authVM = AuthenticationViewModel(container: container)
        let homeVM = HomeViewModel(container: container, userId: "testUserId")

        // ProfileView를 Preview에 추가
        ProfileView()
            .environmentObject(authVM)
            .environmentObject(homeVM)
    }
}







