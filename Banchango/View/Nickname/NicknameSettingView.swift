//
//  NicknameSettingView.swift
//  Banchango
//
//  Created by 김동현 on 11/3/24.
//

import SwiftUI

struct NicknameSettingView: View {
    @State private var nickname: String = ""
    @State private var nicknameMessage: String? = nil
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    // 닉네임이 유효한지 검사하는 프로퍼티
    private var isNicknameValid: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("닉네임을 설정해주세요")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.bottom, 10)
            
            // CustomTextView를 사용하여 텍스트 필드 대체
            CustomTextView(text: $nickname)
                .frame(height: 25)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isNicknameValid ? Color.maincolor : Color.gray, lineWidth: 1)
                )
                .frame(maxWidth: 300) // 텍스트필드 폭을 줄임
                .padding(.horizontal, 20) // 전체 뷰와 텍스트필드의 간격

            // 닉네임 중복 상태 표시
            if let message = nicknameMessage {
                Text(message)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                authVM.send(action: .isNicknameDuplicate(nickname) { isDuplicate in
                    if isDuplicate {
                        nicknameMessage = "닉네임이 중복되었습니다."
                    } else {
                        nicknameMessage = nil
                        authVM.send(action: .updateNickname(nickname))
                    }
                })
            }) {
                Text("저장")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 300)
                    .background(isNicknameValid ? Color.maincolor : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!isNicknameValid)
            
            Spacer()
        }
        .padding()
        .ignoresSafeArea(edges: .all)
    }
}

#Preview {
    NicknameSettingView()
}
