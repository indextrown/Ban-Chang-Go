//
//  NoticeView.swift
//  Banchango
//
//  Created by 김동현 on 11/7/24.
//

import SwiftUI

// MARK: - Model
struct Notice: Identifiable {
    var id = UUID()
    var title: String
    var content: String
    var date: Date
}

// MARK: - ViewModel
final class NoticeViewModel: ObservableObject {
    @Published var notices: [Notice]
    
    init() {
        self.notices = [
            
            .init(title: "반창고 첫 앱 출시",
                   content: "안녕하세요 반창고입니다",
                   date: DateFormatter.customDateFormatter.date(from: "2024.11.05")!),
            
            .init(title: "반창고 첫 앱 출시",
                   content: "안녕하세요 반창고입니다",
                   date: DateFormatter.customDateFormatter.date(from: "2024.11.05")!),
        
            .init(title: "반창고 첫 앱 출시",
                   content: "안녕하세요 반창고입니다",
                   date: DateFormatter.customDateFormatter.date(from: "2024.11.05")!),
            .init(title: "반창고 첫 앱 출시",
                   content: "안녕하세요 반창고입니다",
                   date: DateFormatter.customDateFormatter.date(from: "2024.11.05")!),
            
        ]
    }
}

// MARK: - View
struct NoticeView: View {
    @ObservedObject var noticeVM = NoticeViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(noticeVM.notices) { notice in
                VStack(alignment: .leading) {
                    
                    Text(notice.title)
                        .font(.system(size: 16, weight: .bold))
                    
                    Text(notice.date, formatter: DateFormatter.customDateFormatter)
                        .font(.system(size: 14))
                }
                .padding(.vertical, 10)
                .background(
                    NavigationLink(destination: NoticeDetailView(notice: notice)) {
                        EmptyView()
                    }
                    .opacity(0) // 화살표 아이콘을 숨기기 위해 투명도 설정
                )
            }
            .navigationTitle("공지사항")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss() // 커스텀 뒤로 가기 버튼
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("뒤로가기")
                        }
                        .foregroundColor(.black)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true) // 기본 뒤로 가기 숨김
        
       
    }
}

extension DateFormatter {
    static let customDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}

//#Preview {
//    NoticeView()
//}

                             

struct NoticeDetailView: View {
    var notice: Notice
    @Environment(\.dismiss) var dismiss

    
    var body: some View {
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss() // 커스텀 뒤로 가기 버튼
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("뒤로가기")
                    }
                    .foregroundColor(.black)
                }
            }
        }

        .navigationBarBackButtonHidden(true)
    }
}


#Preview {
    NoticeDetailView(
        notice: .init(title: "반창고 첫 앱 출시",
        content: "안녕하세요 반창고입니다",
        date: DateFormatter.customDateFormatter.date(from: "2024.11.05")!))
}
