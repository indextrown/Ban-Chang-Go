//
//  Rect.swift
//  Banchango
//
//  Created by 김동현 on 11/3/24.
//

import SwiftUI

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
