//
//  HomeViewTest.swift
//  Banchango
//
//  Created by 김동현 on 11/4/24.
//

import SwiftUI

struct HomeTestView: View {
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        Text("반창고")
                            .font(.system(size: 50))
                            
                        Text("반창고")
                            .font(.system(size: 20))
                           
                        Text("반창고")
                            .font(.system(size: 50))
                         
                    }
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 70)
                    .background(.green)
                    
                    HStack {
                        Spacer()
                    }
                    .padding(.vertical, 300)
                    .background(.white)
                    .cornerRadius(20)
                }
            }
        }
        .background(VStack(spacing: .zero) { Color.green; Color.white })
        .ignoresSafeArea()
    }
}


struct HomeTestView_Preview: PreviewProvider {
    static var previews: some View {
        HomeTestView()
    }
}


/*
var body: some View {
    // 화면의 크기 정보를 가져올 수 있음
    GeometryReader { geometry in
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 초록색 상단 배경
                Color.green
                    .frame(height: 500)
                    .overlay(
                        VStack {
                            Text("환영합니다!") // 초록색 배경 중앙에 표시할 텍스트
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .bold()
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .frame(width: geometry.size.width, height: geometry.size.height - 400)
                            .shadow(radius: 5)
                            .offset(y: 400) // 초록색 배경을 살짝 덮는 위치에 흰색 박스 배치
                    )

                
                // 아래에 추가적인 콘텐츠 공간
                VStack {
                    ForEach(0..<10) { index in
                        Text("Content \(index + 1)")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                    }
                    Spacer()

                }
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height * 1.5)
                .background(Color.white)
                
                
            }
        }
        .background(Color.green) // 전체 배경을 초록으로 설정
        .ignoresSafeArea(edges: [.top, .bottom]) // 상하단 여백 무시
    }
}
 */
