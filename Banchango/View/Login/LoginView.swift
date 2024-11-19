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
    @State private var isPressed: Bool = false // 버튼 눌림 상태
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Spacer()
                
                // MARK: - 애플 버튼
                
                ZStack {
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "applelogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .padding(.leading, 37)
                            Spacer()
                            Text("Apple로 계속하기")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.trailing, 50)
                            Spacer()
                        }
                    }
                    .buttonStyle(SocialLoginButton(buttontype: "Apple"))
                    
                    
                    // Apple Login 버튼 (터치 이벤트 처리)
                    SignInWithAppleButton(.continue) { request in
                        // Apple 로그인 요청
                        withAnimation {
                            isPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isPressed = false // 애니메이션 복구
                        }
                        //print("Apple Login Request Triggered")
                        authViewModel.send(action: .appleLogin(request))
                        
                    } onCompletion: { result in
                        authViewModel.send(action: .appleLoginCompletion(result))
                    }
                    .frame(width: 200, height: 45) // 최소 크기 유지
                    .opacity(0.02) // 거의 보이지 않게 설정
                    .background(Color.clear) // 터치 가능하도록 배경 유지
                    .allowsHitTesting(true) // 터치 이벤트 활성화
                    
                }

                // MARK: - 구글 버튼
                Button {
                    authViewModel.send(action: .googleLogin)
                } label: {
                    HStack {
                        Image("Google")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .padding(.leading, 35)
                        Spacer()
                        Text("Google로 계속하기")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.trailing, 50)
                        Spacer()
                    }
                }
                .buttonStyle(SocialLoginButton(buttontype: "Google"))
            }
            .padding(.bottom, 100)
            .padding(.horizontal, 13)
            .background(
                Group {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        // iPad 배경
                        GeometryReader { geometry in
                            Image("Login")
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .edgesIgnoringSafeArea(.all)
                        }
                    } else {
                        // iPhone 배경
                        Image("Login")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .edgesIgnoringSafeArea(.all)
                    }
                }
            )
        }
    }
}

#Preview {
    LoginView(authViewModel: .init())
}


