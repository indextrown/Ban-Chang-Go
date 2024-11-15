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
    @State private var nicknameMessage: String? = nil
 
    
    
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
            

            // CustomTextView를 사용한 닉네임 입력 필드
            CustomTextView(text: $nickname)
                .frame(height: 25)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isNicknameValid ? Color.maincolor : Color.gray, lineWidth: 1)
                )
                .padding(.horizontal, 20)

            // 닉네임 중복 상태 표시
            if let message = nicknameMessage {
                Text(message)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button(action: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isEditing = false
                    }
                }) {
                    Text("취소")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 140)
                        .background(Color.gray.opacity(0.7)) // 버튼 색 연하게
                        .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    authVM.send(action: .isNicknameDuplicate(nickname) { isDuplicate in
                            if isDuplicate {
                                nicknameMessage = "닉네임이 중복되었습니다."
                            } else {
                                nicknameMessage = nil
                                profileVM.myUser?.nickname = nickname
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isEditing = false // 닉네임 업데이트 성공 시 시트 닫기
                                }
                            }
                        })
                    
                    
                }) {
                    Text("저장")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 140)
                        .background(isNicknameValid ? Color.maincolor.opacity(0.7) : Color.gray.opacity(0.5)) // 버튼 색 연하게
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


import UIKit

struct CustomTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        
        // 내부 여백 설정 (약간의 상단 여백 추가)
        textView.textContainerInset = UIEdgeInsets(
            top: 4, // 상단 여백을 약간 추가
            left: 0,
            bottom: 0,
            right: 0
        )
        
        // 내부 여백 제거
        textView.textContainer.lineFragmentPadding = 0 // 추가 여백 제거
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextView

        init(_ parent: CustomTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
