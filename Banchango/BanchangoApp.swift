//
//  BanchangoApp.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI

@main
struct BanchangoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("_isFirstLaunching") var isFirstLaunching: Bool = true
    
    var body: some Scene {
        WindowGroup {
            let container = DIContainer(services: Services())
            AuthenticationView(
                authVM: .init(container: container)
    
            )
            .environmentObject(container)
        }
    }
}











// 일단주석
//            if isFirstLaunching {
//                //OnboardingContentView(onboardingViewModel: .init())
//                } else {
//                    AuthenticationView(authVM: AuthenticationViewModel(container: container))
//                        .environmentObject(container)
//                }

//            // AuthenticationView에 DIContainer 주입
//            AuthenticationView(authVM: AuthenticationViewModel(container: container))
//                .environmentObject(container) // DIContainer를 environmentObject로 주입
//
