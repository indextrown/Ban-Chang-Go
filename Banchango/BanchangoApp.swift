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
//            AuthenticationView(
//                authVM: .init(container: container)
//            )
//            .environmentObject(container)
            
            
            if isFirstLaunching {
                OnboardingContentView(onboardingViewModel: .init())
//                    .onDisappear {
//                        isFirstLaunching = false // 온보딩이 사라질 때 첫 실행 여부를 false로 설정
//                    }
            } else {
                AuthenticationView(
                    authVM: .init(container: container)
                )
                .environmentObject(container)
            }
        }
    }
}





