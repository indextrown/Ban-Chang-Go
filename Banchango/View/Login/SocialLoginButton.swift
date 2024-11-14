////
////  LoginButtonStyle.swift
////  Banchango
////
////  Created by 김동현 on 11/2/24.
////
//
//import SwiftUI
//
//struct SocialLoginButton: ButtonStyle {
//    
//    let buttontype: String
//    
//    init(buttontype: String) {
//        self.buttontype = buttontype
//    }
//    
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .font(.system(size: 14))
//            .foregroundColor(
//                             buttontype == "Google" ? Color.black :
//                             buttontype == "Kakao" ? Color.black.opacity(0.85) : Color.black) // 카카오 버튼 레이블 색상
//            .frame(maxWidth: .infinity, maxHeight: 60)
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(
//                          buttontype == "Google" ? Color.white :
//                          buttontype == "Kakao" ? Color(hex: "#FEE500") : Color.clear) // 카카오 버튼 배경색
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(
//                            buttontype == "Google" ? Color.black :
//                            buttontype == "Kakao" ? Color(hex: "#FEE500") : Color.clear, lineWidth: 0.8) // 카카오 버튼 테두리 색상
//            )
//            .padding(.horizontal, 15)
//            .opacity(configuration.isPressed ? 0.5 : 1)
//            .contentShape(RoundedRectangle(cornerRadius: 5))
//    }
//}
//
//// UIColor의 hex 값을 SwiftUI Color로 변환하기 위한 확장
//extension Color {
//    init(hex: String) {
//        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        if hexSanitized.hasPrefix("#") {
//            hexSanitized.removeFirst()
//        }
//        
//        var rgb: UInt64 = 0
//        Scanner(string: hexSanitized).scanHexInt64(&rgb)
//        
//        let red = Double((rgb >> 16) & 0xFF) / 255.0
//        let green = Double((rgb >> 8) & 0xFF) / 255.0
//        let blue = Double(rgb & 0xFF) / 255.0
//        self.init(red: red, green: green, blue: blue)
//    }
//}
//

import SwiftUI

struct SocialLoginButton: ButtonStyle {
    let buttontype: String

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(
                buttontype == "Google" ? Color.black :
                buttontype == "Kakao" ? Color.black.opacity(0.85) :
                Color.white // 애플 버튼 레이블 색상
            )
            .frame(maxWidth: .infinity, maxHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        buttontype == "Google" ? Color.white :
                            buttontype == "Kakao" ? Color("#FEE500") :
                        Color.black // 애플 버튼 배경색
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        buttontype == "Google" ? Color.black :
                            buttontype == "Kakao" ? Color("#FEE500") :
                        Color.clear, lineWidth: 0.8 // 테두리 색상
                    )
            )
            .opacity(configuration.isPressed ? 0.5 : 1)
            .padding(.horizontal, 15)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}
