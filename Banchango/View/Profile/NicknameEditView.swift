//
//  NicknameEditView.swift
//  Banchango
//
//  Created by 김동현 on 11/7/24.
//

import SwiftUI

// 별도의 닉네임 편집 뷰 생성
struct NicknameEditView: View {
    @Binding var isEditing: Bool
    @Binding var nickname: String
    @ObservedObject var profileVM: HomeViewModel
    @ObservedObject var authVM: AuthenticationViewModel
    
    // 닉네임 유효성 확인 프로퍼티(공백제거후 빈 문자열 아닌지 확인)
    private var isNicknameVaild: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("닉네임 수정")
                .font(.headline)
            
            TextField("새로운 닉네임을 입력하세요", text: $nickname)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("취소") {
                    isEditing = false
                }
                .padding()
                
                Spacer()
                
                Button("저장") {
                    profileVM.myUser?.nickname = nickname
                    authVM.send(action: .updateNickname(nickname))
                    isEditing = false
                    authVM.currentUser?.nickname = nickname
                }
                .disabled(!isNicknameVaild) // 닉네임 유효하지 않으면 버튼 비활성화
                .padding()
            }
            .padding()
        }
        .padding()
    }
}

//
//#Preview {
//    NicknameEditView()
//}
