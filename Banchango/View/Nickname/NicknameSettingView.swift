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
    
    var body: some View {
        VStack {
            Text("닉네임을 설정해주세요")
            TextField("닉네임", text: $nickname)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button {
                authVM.send(action: .updateNickname(nickname))
            } label: {
                Text("저장")
            }
        }
    }
}

#Preview {
    NicknameSettingView()
}