//
//  ContentView.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject var authVM: AuthenticationViewModel
    //@StateObject var profileVM: ProfileViewModel
    var body: some View {
        VStack {
            switch authVM.authenticationState {
            case .authenticated:
                MainTabView()
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
            //authVM.authTest(action: .unauthenticated)
        }
    }
}

//#Preview {
//    AuthenticationView(authVM: .init(container: .init(services: Services())))
//}
