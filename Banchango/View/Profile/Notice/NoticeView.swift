//
//  NoticeView.swift
//  Banchango
//
//  Created by 김동현 on 11/7/24.
//

import SwiftUI
import Combine
import FirebaseDatabase


// MARK: - Model
struct Notice: Identifiable, Decodable {
    var id = UUID()
    var title: String
    var content: String
    var date: Date
    enum CodingKeys: String, CodingKey {
        case title, content, date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // JSON에 id가 없을 경우 기본값으로 UUID 생성
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        
        // 날짜 변환
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: dateString) {
            self.date = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Invalid date format.")
        }
    }
    
    init(id: UUID = UUID(), title: String, content: String, date: Date) {
            self.id = id
            self.title = title
            self.content = content
            self.date = date
        }
}

// MARK: - ViewModel
final class NoticeViewModel: ObservableObject {
    @Published var notices: [Notice] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var db: DatabaseReference = Database.database().reference() // Firebase DB 참조 추가
    
    func loadNotices() {
        db.child("notices").getData { [weak self] error, snapshot in
            if let error = error {
                print("공지사항을 가져오는 중 오류 발생: \(error)")
                return
            }
            
            guard let data = snapshot?.value as? [String: [String: Any]] else {
                print("공지사항 데이터 형식 오류")
                return
            }
            
            do {
                var notices = [Notice]()
                
                for (_, value) in data {
                    let jsonData = try JSONSerialization.data(withJSONObject: value)
                    let notice = try JSONDecoder().decode(Notice.self, from: jsonData)
                    notices.append(notice)
                }
                
                // 날짜순 정렬
                notices.sort { $0.date > $1.date }
                
                DispatchQueue.main.async {
                    self?.notices = notices
                }
            } catch {
                print("공지사항 디코딩 오류: \(error)")
            }
        }
    }
    
    /*
    init() {
        self.notices = [
            
            .init(title: "반창고 첫 앱 출시",
                   content: "안녕하세요 반창고입니다",
                   date: DateFormatter.customDateFormatter.date(from: "2024.11.07")!)
            
        ]
    }
     */
}


// MARK: - View @Environment(\.dismiss) var dismiss
struct NoticeView: View {
    @ObservedObject var noticeVM: NoticeViewModel

    var body: some View {

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
                .opacity(0)
            )
        }
//        .onAppear {
//            noticeVM.loadNotices()
//        }
        .navigationTitle("공지사항")
        .navigationBarTitleDisplayMode(.inline)
    }
        
}

// MARK: - Extension
extension DateFormatter {
    static let customDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}

#Preview {
    NoticeView(noticeVM: .init())
}

