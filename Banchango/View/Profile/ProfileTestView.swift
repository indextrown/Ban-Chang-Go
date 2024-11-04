//
//  ProfileTestView.swift
//  Banchango
//
//  Created by 김동현 on 11/4/24.
//

import SwiftUI

struct ProfileTestView: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("설정")
                            .font(.system(size: 35, weight: .bold))
                        Spacer()
                    }
                    
                    RectViewHC(height: 50, color: .white, radius: 15)
                        .overlay {
                            HStack {
                                Text("닉네임")
                                Spacer()
                                Text("닉네임") // Static text for testing
                            }
                            .padding()
                        }
                    
                    RectViewHC(height: 100, color: .white, radius: 15)
                        .overlay {
                            VStack(spacing: 0) {
                                Button {
                                    // Placeholder action
                                } label: {
                                    HStack {
                                        Text("공지사항")
                                            .foregroundColor(.black)
                                            .padding(.bottom, 12.5)
                                        Spacer()
                                    }
                                    .padding(.leading, 20)
                                }
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.4))
                                    .frame(height: 1)
                                    .padding(.horizontal, 15)
                                
                                Button {
                                    // Placeholder action
                                } label: {
                                    HStack {
                                        Text("버전")
                                            .foregroundColor(.black)
                                            .padding(.top, 12.5)
                                        Spacer()
                                    }
                                    .padding(.leading, 20)
                                }
                            }
                        }
                    
                    RectViewHC(height: 50, color: .white, radius: 15)
                        .overlay {
                            HStack {
                                Button {
                                    
                                } label: {
                                    Text("계정탈퇴")
                                        .foregroundColor(.black)
                                }
                                Spacer()
                            }
                            .padding()
                        }
                    RectViewHC(height: 50, color: .white, radius: 15)
                        .overlay {
                          
                            Button {
                                
                            } label: {
                                HStack {
                                    Text("계정탈퇴")
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding()
                                
                            }
                               
                           
                        }
                    
                    Button {
                        // Placeholder action
                    } label: {
                        Text("로그아웃")
                            .foregroundColor(.red)
                    }
                    
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
            }
        }
    }
}

#Preview {
    ProfileTestView()
}
