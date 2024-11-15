//
//  ContentView.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject var authVM: AuthenticationViewModel
    @EnvironmentObject var container: DIContainer
    
    var body: some View {
        VStack {
            switch authVM.authenticationState {
            case .authenticated:
                
                // 인증된 상태에서만 HomeViewModel필요하기 때문에 여기서 생성
                MainTabView(homeVM: HomeViewModel(container: container, userId: authVM.userId ?? ""))
                        .environmentObject(authVM)
                    
            case .unauthenticated:
                LoginView()
                    .environmentObject(authVM) // 지울예정
                
            case .nicknameRequired:
                NicknameSettingView()
                    .environmentObject(authVM)
            }
        }
        .onAppear {
            authVM.send(action: .checkAuthenticationState)
        }
        
        .onChange(of: authVM.authenticationState) { oldState, newState in
            
            // 인증된 상태로 변경될 때 닉네임 체크
            if newState == .authenticated, let userId = authVM.userId {
                authVM.send(action: .checkNickname(userId)) // 닉네임 체크
            }
        }
    }
}











#Preview {
    AuthenticationView(authVM: .init(container: .init(services: Services())))
}

