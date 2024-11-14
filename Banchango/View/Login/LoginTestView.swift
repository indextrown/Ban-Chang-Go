//
//  LoginTestView.swift
//  Banchango
//
//  Created by 김동현 on 11/14/24.
//

import SwiftUI
import AuthenticationServices

struct LoginTestView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isPressed: Bool = false // 버튼 눌림 상태

    var body: some View {
        VStack {
            ZStack {
                // 실제 보이는 버튼 (시각적 효과)
                HStack {
                    Image(systemName: "applelogo") // Apple 대체 아이콘
                    Text("Apple 로그인")
                }
                .padding()
                .background(isPressed ? Color.gray.opacity(0.3) : Color.white) // 눌림 효과
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0) // 눌림 시 크기 축소
                .animation(.easeInOut(duration: 0.1), value: isPressed)

                // Apple Login 버튼 (터치 이벤트 처리)
                SignInWithAppleButton(.continue) { request in
                    // Apple 로그인 요청
                    withAnimation {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false // 애니메이션 복구
                    }
                    print("Apple Login Request Triggered")
                } onCompletion: { result in
                    // Apple 로그인 결과 처리
                    switch result {
                    case .success(let authorization):
                        print("Apple Login Success: \(authorization)")
                    case .failure(let error):
                        print("Apple Login Failed: \(error.localizedDescription)")
                    }
                }
                .signInWithAppleButtonStyle(.white) // 스타일 유지
                .frame(width: 200, height: 45) // 최소 크기 유지
                .opacity(0.02) // 거의 보이지 않게 설정
                .background(Color.clear) // 터치 가능하도록 배경 유지
                .allowsHitTesting(true) // 터치 이벤트 활성화
            }
            
        }
        .padding()
    }
}

// Preview
#Preview {
    LoginTestView()
}
