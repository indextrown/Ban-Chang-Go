//
//  LoginView.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isAppleButtonPressed: Bool = false // 애플 버튼 누름 상태 관리
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Spacer()
                Spacer()
                
                /*
                // MARK: - 애플버튼
                SignInWithAppleButton { request in
                    // TODO:
                    authViewModel.send(action: .appleLogin(request))
                    
                    // 인증이 완료됬을때 불려지는 클로저 - 성공시 파이어베이스 인증 진행
                } onCompletion: { request in
                    // TODO:
                   authViewModel.send(action: .appleLoginCompletion(request))
                }
                .frame(height: 60)
                .padding(.horizontal, 15)
                .cornerRadius(5)
                 */
                
                // MARK: - 애플 로그인 버튼

                ZStack {
                    // 실제 Apple Login 버튼
                    SignInWithAppleButton(.continue) { request in
                        authViewModel.send(action: .appleLogin(request))
                        print("Apple Login Request Triggered")
                    } onCompletion: { result in
                        authViewModel.send(action: .appleLoginCompletion(result))
                        print("Apple Login Completed: \(result)")
                    }
                    .frame(height: 60)
                    .opacity(0.05) // 약간의 투명도로 설정
                    .allowsHitTesting(true) // 터치 이벤트 활성화

                    // 커스텀 UI
                    HStack {
                        Image("Apple")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .padding(.leading, 15)
                            .padding(.top, 5)

                        Spacer()

                        Text("Apple로 계속하기")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()
                        Spacer()
                    }
                    .frame(height: 60)
                    .background(Color.black)
                    .cornerRadius(5)
                    .shadow(color: isAppleButtonPressed ? Color.black.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5) // 그림자 효과
                    .allowsHitTesting(false) // 터치 이벤트를 SignInWithAppleButton으로 전달
                    .gesture(
                        DragGesture(minimumDistance: 0) // 버튼 눌림 상태 감지
                            .onChanged { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isAppleButtonPressed = true
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isAppleButtonPressed = false
                                }
                            }
                    )
                }
                                .padding(.horizontal, 15)

                
                
                // MARK: - 구글버튼
                Button {
                    // TODO:
                    authViewModel.send(action: .googleLogin)
                    //authViewModel.authenticationState = .authenticated
                } label: {
                    ZStack {
                        // 텍스트를 버튼 중앙에 배치
                        Text("Google 계속하기")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .center) // 텍스트 중앙 정렬
                        
                        // 로고를 버튼의 왼쪽에 배치
                        HStack {
                            Image("Google") // 구글 로고
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24) // 로고 크기
                                .padding(.leading, 30) // 버튼 좌측 여백
                            Spacer() // 로고와 텍스트 사이를 유지
                        }
                    }
                }.buttonStyle(SocialLoginButton(buttontype: "Google"))
            }
            .padding(.bottom, 100)
            .padding(.horizontal, 13)
            .background(
                Image("Login") // "img_login"을 배경으로 설정
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all) // 배경이 화면 전체를 채우도록 설정
            )
        }
    }
}

#Preview {
    LoginView(authViewModel: .init())
}
