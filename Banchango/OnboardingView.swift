//
//  OnboardingView.swift
//  Banchango
//
//  Created by 김동현 on 11/5/24.
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
            .init(imageFileName: "onboarding1", title: "제목1", subTitle: "내용1"),
            .init(imageFileName: "onboarding2", title: "제목2", subTitle: "내용2")
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
            
            StartBtnView()
        }
        .edgesIgnoringSafeArea(.top)
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
        .shadow(radius: 10)
    }
}

private struct StartBtnView: View {
    //@Binding var isFirstLaunching: Bool
    fileprivate var body: some View {
        Button {

        } label: {
            Text("시작하기")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(.green)
            
//            Image("startHome")
//              .renderingMode(.template)
//              .foregroundColor(.customGreen)
        }
        .padding(.bottom, 50)
    }
}




struct OnboardingView2: View {
    @Binding var isFirstLaunching: Bool
    @State private var currentTab = 0

        var body: some View {
            TabView(selection: $currentTab) {
                Image("onboarding_1")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .tag(0)
                
                Image("onboarding_2")
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

#Preview {
    OnboardingContentView(onboardingViewModel: .init())
}


//
//struct OnboardingView_Previews: PreviewProvider {
//    static var previews: some View {
//        // 프리뷰용 State 변수를 만들어 Binding으로 전달
//        StatefulPreviewWrapper(true) { isFirstLaunching in
//            OnboardingView(isFirstLaunching: isFirstLaunching)
//        }
//    }
//}
//
//// State 변수를 간단히 Wrapping하는 구조체 생성
//struct StatefulPreviewWrapper<Value: Equatable, Content: View>: View {
//    @State private var value: Value
//    private let content: (Binding<Value>) -> Content
//
//    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
//        self._value = State(initialValue: value)
//        self.content = content
//    }
//
//    var body: some View {
//        content($value)
//    }
//}
//
