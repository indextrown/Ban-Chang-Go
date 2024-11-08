//
//  NoticeDetailView.swift
//  Banchango
//
//  Created by 김동현 on 11/8/24.
//

import SwiftUI

struct NoticeDetailView: View {
    var notice: Notice

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(notice.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(notice.date, formatter: DateFormatter.customDateFormatter)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Divider()
                
                Spacer()
                    .frame(height: 10)
                
                Text(notice.content)
                    .font(.body)
                
                Spacer()
            }
            .padding()
            .navigationTitle("공지사항 상세")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NoticeDetailView(
        notice: .init(title: "반창고 첫 앱 출시",
        content: "안녕하세요 반창고입니다",
        date: DateFormatter.customDateFormatter.date(from: "2024.11.05")!))
}
