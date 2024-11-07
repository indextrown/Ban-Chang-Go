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

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Spacer()
                Spacer()
                
                // MARK: - 애플버튼
                SignInWithAppleButton { request in
                    // TODO:
                    authViewModel.send(action: .appleLogin(request))
                    
                    // 인증이 완료됬을때 불려지는 클로저 - 성공시 파이어베이스 인증 진행
                } onCompletion: { request in
                    // TODO:
                   authViewModel.send(action: .appleLoginCompletion(request))
                }
                .frame(height: 50)
                .padding(.horizontal, 15)
                .cornerRadius(5)
                
                
                
                // MARK: - 구글버튼
                Button {
                    // TODO:
                    authViewModel.send(action: .googleLogin)
                    //authViewModel.authenticationState = .authenticated
                } label: {
                    HStack {
                        Image("Google")
                            .resizable() // 아마자 크기 조절 가능하도록 설정
                            .aspectRatio(contentMode: .fit) // 비율 유지하며 크기 조정
                            .frame(width: 24, height: 24) // 크기 설정
                        Text("Google 로그인")
                        
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
