//
//  NicknameSettingView.swift
//  Banchango
//
//  Created by 김동현 on 11/3/24.
//

import SwiftUI

struct NicknameSettingView: View {
    @State private var nickname: String = ""
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
            
            TextField("닉네임을 입력하세요", text: $nickname)
                .padding(.vertical, 10) // 세로 간격만 설정
                .padding(.horizontal, 16) // 좌우 패딩 설정
                .cornerRadius(10) // 배경과 모서리 반경
                .overlay(
                    RoundedRectangle(cornerRadius: 10) // 텍스트필드와 일치하도록 설정
                        .stroke(isNicknameValid ? Color.blue : Color.gray, lineWidth: 1)
                )
                .frame(maxWidth: 300) // 텍스트필드 폭을 줄임
                .padding(.horizontal, 20) // 전체 뷰와 텍스트필드의 간격

            
            Button(action: {
                authVM.send(action: .updateNickname(nickname))
            }) {
                Text("저장")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 300)
                    .background(isNicknameValid ? Color.mainorange : Color.gray)
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
