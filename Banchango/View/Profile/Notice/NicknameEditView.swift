//
//  NicknameEditView.swift
//  Banchango
//
//  Created by 김동현 on 11/3/24.
//

import SwiftUI

// 별도의 닉네임 편집 뷰 생성
struct NicknameEditView: View {
    @Binding var isEditing: Bool
    @Binding var nickname: String
    @ObservedObject var profileVM: HomeViewModel
    @ObservedObject var authVM: AuthenticationViewModel
    
    // 닉네임 유효성 확인 프로퍼티(공백제거후 빈 문자열 아닌지 확인)
    private var isNicknameValid: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
 
            
            Text("닉네임 수정")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.bottom, 10)
            
            TextField("새로운 닉네임을 입력하세요", text: $nickname)
                .padding(.vertical, 10) // 세로 간격만 설정
                .padding(.horizontal, 16) // 좌우 패딩 설정
                .cornerRadius(10) // 배경과 모서리 반경
                .overlay(
                    RoundedRectangle(cornerRadius: 10) // 텍스트필드와 일치하도록 설정
                        .stroke(isNicknameValid ? Color.blue : Color.gray, lineWidth: 1)
                )
                .padding(.horizontal, 20) // 전체 뷰와 텍스트필드의 간격


            HStack {
                Button(action: {
                    isEditing = false
                }) {
                    Text("취소")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 140)
                        .background(Color.red.opacity(0.7)) // 버튼 색 연하게
                        .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    profileVM.myUser?.nickname = nickname
                    authVM.send(action: .updateNickname(nickname))
                    isEditing = false
                    authVM.currentUser?.nickname = nickname
                }) {
                    Text("저장")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 140)
                        .background(isNicknameValid ? Color.blue.opacity(0.7) : Color.gray.opacity(0.5)) // 버튼 색 연하게
                        .cornerRadius(10)
                }
                .disabled(!isNicknameValid)
                
            }
            .padding(.horizontal, 20)
            
            Spacer()
            Spacer()
        }
        .padding()
        .ignoresSafeArea(edges: .all)
    }
}


