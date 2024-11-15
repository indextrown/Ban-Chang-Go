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
            if isFirstLaunching {
                OnboardingContentView(onboardingViewModel: .init())
            } else {
                AuthenticationView(
                    authVM: .init(container: container)
                )
                .environmentObject(container)
            }
        }
    }
}





