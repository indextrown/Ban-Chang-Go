//
//  Rect.swift
//  Banchango
//
//  Created by 김동현 on 11/3/24.
//

import SwiftUI

// HomeView
struct RectViewH: View {
    var height: CGFloat = 100
    var color: Color = .gray1

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
            .cornerRadius(20)
    }
}
 
// Profileview
struct RectViewHC: View {
    var height: CGFloat = 100
    var color: Color = .gray1
    var radius: CGFloat = 20

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
            .cornerRadius(radius)
    }
}
 
// NicknameRequiredView
struct RectView: View {
    var width: CGFloat = 100
    var height: CGFloat = 100
    var color: Color = .blue
    var radius: CGFloat = 20
    var image: Image?
    var imageColor: Color = .blue
    var isUserImage: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(color)
                .frame(width: width, height: height)
                .cornerRadius(radius)
               
            // 이미지가 존재하면
            if let image = image {
                if isUserImage {
                    // 사용자가 업로드한 이미지일 경우
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: radius))
                } else {
                    image
                        .resizable()    // 크기 조절 가능
                        .scaledToFit()  // 프레임맞게 조절하되 원본 비율 유지
                        .frame(width: width-60, height: height-60)
                        .clipShape(RoundedRectangle(cornerRadius: radius)) // 이미지를 둥근 사각형 모양으로 자름
                        .foregroundColor(imageColor)
                }
            }
        }
        .clipped() // 콘텐츠가 부모 뷰의 경계를 벗어날 경우, 해당 경게 기준으로 잘라냄
    }
}
