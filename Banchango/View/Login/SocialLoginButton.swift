//
//  LoginButtonStyle.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI

struct SocialLoginButton: ButtonStyle {
    
    let buttontype: String
    
    init(buttontype: String) {
        self.buttontype = buttontype
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14))
            .foregroundColor(buttontype == "Apple" ? Color.white :
                             buttontype == "Google" ? Color.black :
                             buttontype == "Kakao" ? Color.black.opacity(0.85) : Color.black) // 카카오 버튼 레이블 색상
            .frame(maxWidth: .infinity, maxHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(buttontype == "Apple" ? Color.black :
                          buttontype == "Google" ? Color.white :
                          buttontype == "Kakao" ? Color(hex: "#FEE500") : Color.clear) // 카카오 버튼 배경색
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(buttontype == "Apple" ? Color.black :
                            buttontype == "Google" ? Color.black :
                            buttontype == "Kakao" ? Color(hex: "#FEE500") : Color.clear, lineWidth: 0.8) // 카카오 버튼 테두리 색상
            )
            .padding(.horizontal, 15)
            .opacity(configuration.isPressed ? 0.5 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 5))
    }
}

// UIColor의 hex 값을 SwiftUI Color로 변환하기 위한 확장
extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

//#Preview {
//    LoginView(authViewModel: .init())
//}
//
//import SwiftUI
//import AuthenticationServices
//
//struct CustomAppleLoginButton: View {
//    @EnvironmentObject var authViewModel: AuthenticationViewModel // 뷰 모델을 사용하여 로그인 상태 관리
//    @State private var isPressed: Bool = false // 버튼 누름 상태 관리
//
//    var body: some View {
//        ZStack {
//            // MARK: - 실제 Apple Login 버튼 (동작)
//            SignInWithAppleButton(.continue) { request in
//                authViewModel.send(action: .appleLogin(request))
//                print("Apple Login Request Triggered")
//            } onCompletion: { result in
//                authViewModel.send(action: .appleLoginCompletion(result))
//                print("Apple Login Completed: \(result)")
//            }
//            .frame(height: 60)
//            .opacity(0.05) // 약간의 투명도로 설정하여 터치 이벤트 전달 가능
//
//            // MARK: - 커스텀 UI
//            HStack {
//                Image("Apple") // 애플 로고 (SF Symbol)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 50, height: 50) // 로고 크기
//                    .padding(.leading, 15) // 버튼 좌측 여백
//
//                Spacer()
//
//                Text("Apple로 계속하기")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.white)
//                Spacer() // 로고와 텍스트 사이를 유지
//
//                Spacer()
//            }
//            .frame(height: 60)
//            .background(Color.black) // 버튼 배경색
//            .cornerRadius(5) // 둥근 모서리 설정
//            .shadow(color: isPressed ? Color.black.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5) // 그림자 효과
//            //.scaleEffect(isPressed ? 0.95 : 1.0) // 버튼 크기 약간 축소
//            .gesture(
//                DragGesture(minimumDistance: 0) // 드래그 제스처를 사용하여 누름 상태 감지
//                    .onChanged { _ in
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            isPressed = true
//                        }
//                    }
//                    .onEnded { _ in
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            isPressed = false
//                        }
//                    }
//            )
//        }
//        .padding(.horizontal, 15)
//    }
//}
//
//#Preview {
//    CustomAppleLoginButton()
//}
