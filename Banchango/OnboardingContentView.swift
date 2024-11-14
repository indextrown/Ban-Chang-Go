//
//  OnboardingContentView.swift
//  Banchango
//
//  Created by 김동현 on 11/14/24.
//

import SwiftUI

// MARK: - Model
struct OnboardingContent: Hashable {
    var imageFileName: String
    var title: String
    var subTitle: String
}

// MARK: - ViewModel
class OnboardingViewModel: ObservableObject {
    @Published var onboardingcontents: [OnboardingContent]
    
    init(
        onboardingcontents: [OnboardingContent] = [
            .init(imageFileName: "onboarding1",
                  title: "나의 걸음 기록",
                  subTitle: "한눈에 보이는 나의 걸음"),
            
            .init(imageFileName: "onboarding2",
                  title: "주변 약국 찾기",
                  subTitle: "주변 약국 정보를 간편하게"),
            
            .init(imageFileName: "onboarding3",
                  title: "약국 상세 정보",
                  subTitle: "운영시간과 상세 정보를 한눈에"),
            
            .init(imageFileName: "onboarding4",
                  title: "약국 검색",
                  subTitle: "원하는 약국을 빠르게 찾기")
        ]
    ) {
        self.onboardingcontents = onboardingcontents
    }
}

// MARK: - 온보딩 컨텐츠 뷰
struct OnboardingContentView: View {
    @ObservedObject private var onboardingViewModel: OnboardingViewModel
    
    init(onboardingViewModel: OnboardingViewModel) {
        self.onboardingViewModel = onboardingViewModel
    }
    
    var body: some View {
        VStack {
            OnboardingCellListView(onboardingViewModel: onboardingViewModel)
            
            Spacer()
                .frame(height: 50)
            
            StartBtnView()
        }
//       .edgesIgnoringSafeArea(.top)
    }
}

// MARK: - 온보딩 셀 리스트 뷰
private struct OnboardingCellListView: View {
    @ObservedObject private var onboardingViewModel: OnboardingViewModel
    @State private var selectedIndex: Int
    
    fileprivate init(onboardingViewModel: OnboardingViewModel, selectedIndex: Int = 0) {
        self.onboardingViewModel = onboardingViewModel
        self.selectedIndex = selectedIndex
    }
    
    fileprivate var body: some View {
        VStack {
            TabView(selection: $selectedIndex) {
                ForEach(Array(onboardingViewModel.onboardingcontents.enumerated()), id: \.element) { index, onboardingContent in
                    OnboardingCellView(onboardingContent: onboardingContent)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 1.5)
            
        }
    }
}

// MARK: - 온보딩 셀 뷰
private struct OnboardingCellView: View {
    private var onboardingContent: OnboardingContent
    
    fileprivate init(onboardingContent: OnboardingContent) {
        self.onboardingContent = onboardingContent
    }
    
    fileprivate var body: some View {
        VStack {
            Image(onboardingContent.imageFileName)
                .resizable()
                .scaledToFit()
                .cornerRadius(10)
            
            HStack {
                Spacer()
                
                VStack {
                    Spacer()
                        .frame(height: 46)
                    
                    Text(onboardingContent.title)
                        .font(.system(size: 16, weight: .bold))
                    
                    Spacer()
                        .frame(height: 5)
                    
                    Text(onboardingContent.subTitle)
                        .font(.system(size: 16))
                }
                
                Spacer()
            }
            .background(.white)
            .cornerRadius(0)
        }
        .padding(.top, 20)
        .shadow(radius: 10)
        
        
    }
    
}

private struct StartBtnView: View {
//    @Binding var isFirstLaunching: Bool
    @AppStorage("_isFirstLaunching") private var isFirstLaunching: Bool = true
    fileprivate var body: some View {
        Button {
            isFirstLaunching = false // 온보딩 종료
        } label: {
            HStack {
                Text("시작하기")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
            }
            
        }
        .padding(.bottom, 20)
    }
}



/*
struct OnboardingView2: View {
    @Binding var isFirstLaunching: Bool
    @State private var currentTab = 0

        var body: some View {
            TabView(selection: $currentTab) {
                Image("onboarding11")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .tag(0)
                
                Image("onboarding12")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle())
            .overlay(
                VStack {
                    Spacer()
                    
                    if currentTab == 1 {
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
                }
            )
            .ignoresSafeArea()
        }
}
 */

#Preview {
    OnboardingContentView(onboardingViewModel: .init())
}
