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
        ZStack {
            Color.gray1
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 20)
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
                .padding(.top, 30)
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




// 별도의 닉네임 편집 뷰 생성
struct NicknameEditView: View {
    @Binding var isEditing: Bool
    @Binding var nickname: String
    @ObservedObject var profileVM: HomeViewModel
    @ObservedObject var authVM: AuthenticationViewModel
    
    // 닉네임 유효성 확인 프로퍼티(공백제거후 빈 문자열 아닌지 확인)
    private var isNicknameVaild: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
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
                .disabled(!isNicknameVaild) // 닉네임 유효하지 않으면 버튼 비활성화
                .padding()
            }
            .padding()
        }
        .padding()
    }
}


// 기존 버튼 스타일과 일치시키는 스타일 정의
struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(Color.blue) // 기존 배경색
            .cornerRadius(10)
            .padding()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
