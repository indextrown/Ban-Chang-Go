//
//  NicknameSettingView.swift
//  Banchango
//
//  Created by 김동현 on 11/3/24.
//

import SwiftUI

struct NicknameSettingView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @State private var nickname: String = ""
    @State private var nicknameMessage: String? = nil
    
    @State private var birthdate: Date = Date()
    @State private var isDatePickerActive: Bool = false
    
    @State private var selectedGender: Gender = Gender.male
    
    // 닉네임이 유효한지 검사하는 프로퍼티
    private var isNicknameValid: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("정보를 입력해 주세요")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading, 10)
                    Spacer()
                }
                
                
                Spacer()
                    .frame(height: 30)
                
                HStack {
                    Text("닉네임")
                        .padding(.leading, 10)
                    Spacer()
                }
                
                TextField("닉네임 입력", text: $nickname)
                    .customTextFieldStyle()
                    .onDisappear {
                        DispatchQueue.main.async {
                            // 키보드 닫기
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                
                Spacer()
                    .frame(height: 10)
                
                if let message = nicknameMessage {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                    .frame(height: 20)
                
                HStack {
                    Text("생년월일")
                        .padding(.leading, 10)
                    Spacer()
                }
                
                Button {
                    isDatePickerActive = true
                } label: {
                    HStack {
                        Text(formattedDate(birthdate))
                        Spacer()
                    }
                }.buttonStyle(AppButtonStyle())
                
                Spacer()
                    .frame(height: 20)
                
                HStack {
                    Text("성별")
                        .padding(.leading, 10)
                    Spacer()
                }
                
                HStack {
                    GenderButton(title: "남성", gender: .male, selectedGender: $selectedGender)
                        .buttonStyle(SelectionButtonStyle(isSelected: selectedGender == .male))
                    
                    GenderButton(title: "여성", gender: .female, selectedGender: $selectedGender)
                        .buttonStyle(SelectionButtonStyle(isSelected: selectedGender == .female))
                    
                    GenderButton(title: "선택안함", gender: .unspecified, selectedGender: $selectedGender)
                        .buttonStyle(SelectionButtonStyle(isSelected: selectedGender == .unspecified))
                }
                
                Spacer()
                    .frame(height: 360)
                
                Button {
                    if isNicknameValid {
                        authVM.send(action: .isNicknameDuplicate(nickname) { isDuplicate in
                            if isDuplicate {
                                nicknameMessage = "닉네임이 중복되었습니다."
                            } else {
                                nicknameMessage = nil
                                //                            authVM.send(action: .updateNickname(nickname))
                                // .updateUser(let nickname, let birthdate, let gender)
                                let birthdayString = formattedDate(birthdate)
                                let genderString = selectedGender.rawValue
                                authVM.send(action: .updateUser(nickname, birthdayString, genderString))
                            }
                        })
                    } else {
                        nicknameMessage = "닉네임을 입력하세요"
                    }
                    
                } label: {
                    Text("완료")
                }
                .buttonStyle(CompleteButtonStyle())
            }
            .padding()
            .sheet(isPresented: $isDatePickerActive) {
                BirthdatePickerView(birthdate: $birthdate)
                    .presentationDetents([.fraction(0.5)])
            }
        }
        .gesture(DragGesture().onChanged { _ in })
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // "Nov 11, 2024" 형태
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}



// Custom TextField Style
struct CustomTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding() // 내부 여백 추가
            .frame(maxWidth: .infinity) // 너비를 최대화하여 확장
            .background(Color.white) // 버튼과 동일한 흰색 배경
            .overlay(
                RoundedRectangle(cornerRadius: 10) // 둥근 테두리
                    .stroke(Color.black, lineWidth: 2) // 검은색 테두리
            )
            .clipShape(RoundedRectangle(cornerRadius: 10)) // 모양을 버튼과 동일하게 설정
    }
}

extension View {
    // TextField 스타일을 쉽게 적용할 수 있도록 View 확장
    func customTextFieldStyle() -> some View {
        self.modifier(CustomTextFieldStyle())
    }
}


// MARK: - 생년월일 선택 화면
struct BirthdatePickerView: View {
    @Binding var birthdate: Date
    @Environment(\.dismiss) private var dismiss // Sheet 닫기

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("생년월일 선택", selection: $birthdate, 
                           in: ...Date(), // 현재 날짜까지 선택 가능
                           displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .padding()
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    // .environment(\.locale, Locale(identifier: String(Locale.preferredLanguages[0])))

                Button("완료") {
                    dismiss() // Sheet 닫기
                }
                .buttonStyle(AppButtonStyle()) // 기존 버튼 스타일 사용
                .padding()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    
                    Text("생년월일 선택")
                        .font(.headline)
                        .padding(.horizontal, 20)
                }
            }

        }
    }
}

// 생년월일관련
struct AppButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.white : Color.black)    // 텍스트 색상
            .padding()                  // 내부 여백
            .frame(maxWidth: .infinity) // 버튼 넓이 설정
            .background(
                configuration.isPressed ? Color.black : Color.white // 누를 때 색상 변경
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 2) // 테두리
            )
            .clipShape(RoundedRectangle(cornerRadius: 10)) // 둥근 모양
            //.padding() // 외부 여백
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed) // 애니메이션 추가
    }
}

// 성별 타입
enum Gender: String, Codable {
    case male = "남자"
    case female = "여자"
    case unspecified = "선택안함"
}

// 성별 버튼
struct GenderButton: View {
    let title: String
    let gender: Gender
    @Binding var selectedGender: Gender
    
    var body: some View {
        Button {
            selectedGender = gender
        } label: {
            Text(title)
        }
    }
}

// 선택 버튼
struct SelectionButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isSelected ? Color.white : Color.black)    // 텍스트
            .padding()  // 내부 여백
            .frame(maxWidth: .infinity) // 버튼 넓이
            .background(isSelected ? Color.maincolor : Color.white)         // 배경 색성
        
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10)) // 둥근 모양
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // 누를 때 크기 애니메이션
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed) // 애니메이션 추가
    }
}

// 완료 버튼
struct CompleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.maincolor : Color.white)    // 텍스트 색상
            .padding()                  // 내부 여백
            .frame(maxWidth: .infinity) // 버튼 넓이 설정
            .background(
                configuration.isPressed ? Color.white : Color.maincolor // 누를 때 색상 변경
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 2) // 테두리
            )
            .clipShape(RoundedRectangle(cornerRadius: 10)) // 둥근 모양
//            .padding() // 외부 여백
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed) // 애니메이션 추가
    }
}


