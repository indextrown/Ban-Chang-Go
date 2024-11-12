//
//  Color+Extension.swift
//  Banchango
//
//  Created by 김동현 on 11/9/24.
//

import SwiftUI

extension Color {
    /// RGB 값을 기반으로 Color 생성
    /// - Parameters:
    ///   - red: Red 값 (0~255)
    ///   - green: Green 값 (0~255)
    ///   - blue: Blue 값 (0~255)
    ///   - opacity: 불투명도 (0.0~1.0)
    static func rgb(_ red: Double, _ green: Double, _ blue: Double, opacity: Double = 1.0) -> Color {
        return Color(
            red: red / 255.0,
            green: green / 255.0,
            blue: blue / 255.0,
            opacity: opacity
        )
    }
}
