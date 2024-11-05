//
//  OnboardingView.swift
//  Banchango
//
//  Created by 김동현 on 11/5/24.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isFirstLaunching: Bool

        var body: some View {
            TabView {
                Image("onboarding1")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Image("onboarding2")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            .tabViewStyle(PageTabViewStyle())
            .overlay(
                VStack {
                    Spacer()
                    Button(action: {
                        isFirstLaunching = false // 첫 실행 후 온보딩 종료
                    }) {
                        Text("시작하기")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 50)
                }
            )
        }
}

//#Preview {
//    OnboardingView(isFirstLaunching: )
//}
