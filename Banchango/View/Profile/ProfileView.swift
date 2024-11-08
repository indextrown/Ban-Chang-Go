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

    @State private var nickname: String = ""
    @State private var isEditing: Bool = false
    @State private var showDeleteConfiguration = false
    
    var body: some View {
        NavigationView {
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
                            }
                        
                        
                        
                        // 공지사항 및 버전 정보
                        /*
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
                         */
                        
                        RectViewHC(height: 100, color: .white, radius: 15)
                            .overlay {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: NoticeView()) {
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
                                        // 공지사항 동작
                                    } label: {
                                        HStack {
                                            Text("이용약관")
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
                                            Text("버전정보")
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
                                    showDeleteConfiguration = true
                                    // 계정 탈퇴 동작
                                    //authVM.send(action: .deleteAccount)
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
                //.navigationTitle("설정")
            }
            
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






/*
RectViewHC(height: 150, color: .white, radius: 15) // 높이를 200으로 늘려 버튼 4개 공간 확보
    .overlay {
        VStack(spacing: 0) {
            // 첫 번째 버튼
            Button {
                // 첫 번째 버튼 동작
            } label: {
                HStack {
                    Text("공지사항")
                        .foregroundColor(.black)
                        .padding(.vertical, 12.5)
                    Spacer()
                }
                .padding(.leading, 20)
            }
            
            // 첫 번째 버튼과 두 번째 버튼 사이 분리선
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(height: 1)
                .padding(.horizontal, 15)
            
            // 두 번째 버튼
            Button {
                // 두 번째 버튼 동작
            } label: {
                HStack {
                    Text("이용약관")
                        .foregroundColor(.black)
                        .padding(.vertical, 12.5)
                    Spacer()
                }
                .padding(.leading, 20)
            }
            
            // 두 번째 버튼과 세 번째 버튼 사이 분리선
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(height: 1)
                .padding(.horizontal, 15)
            
            // 세 번째 버튼
            Button {
                // 세 번째 버튼 동작
            } label: {
                HStack {
                    Text("문의하기")
                        .foregroundColor(.black)
                        .padding(.vertical, 12.5)
                    Spacer()
                }
                .padding(.leading, 20)
            }
        }
    }
*/
