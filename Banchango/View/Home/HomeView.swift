//
//  HomeView.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI
import CoreMotion
import Charts

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    var body: some View {
        VStack {
            contentView
        }
        .background(Color.gray1)
    }
    
    @ViewBuilder
    var contentView: some View {
        switch viewModel.phase {
        case .notRequested:
            PlaceHolderView()
                .onAppear {
                    viewModel.send(action: .load)
                }
        case .loading:
            ProgressView()
                .background(.white)
        case .success:
            LoadedView()
                .environmentObject(viewModel)
               
        case .fail:
            ErrorView()
        }
    }
}


struct LoadedView: View {
    @StateObject private var viewModel = PedometerViewModel()
    @State private var goalSteps: Int = 2000 // 기본 목표 걸음 수
    var body: some View {
        VStack(spacing: 20) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - 오늘 날짜 표시
                    Text(getCurrentDateString())
                        .font(.system(size: 17))
                        .foregroundColor(.black)
                    
                    RectViewH(height: 130, color: .white)
                        .overlay {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("오늘의 걸음수 👟")
                                        .font(.system(size: 20))
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                        .frame(height: 20)
                                    
                                    HStack {
                                        Text("\(viewModel.stepCount)")
                                            .font(.system(size: 30))
                                            .fontWeight(.bold)
                                            .foregroundColor(.mainorange)
                                        
                                        if viewModel.stepCount >= goalSteps {
                                            Text("😄") // 웃는 이모티콘
                                        } else {
                                            Text("😄") // 속상한 이모티콘
                                                .colorMultiply(Color.gray.opacity(0.2))
                                        }
                                    }
                                }
                                .padding(.leading, 10)
                                .frame(maxWidth: .infinity, alignment: .leading) // 왼쪽 정렬

                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 1, height: 80) // 구분선 두께와 높이 설정
                                    .padding(.horizontal, 10) // 구분선 양쪽 여백 설정

                                VStack(alignment: .leading) {
                                    Text("칼로리🔥")
                                        .font(.system(size: 20))
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                      
                                    Spacer()
                                        .frame(height: 20)
                                    
                                    HStack {
                                        Text("\(viewModel.caloriesBurned)")
                                            .font(.system(size: 30))
                                            .fontWeight(.bold)
                                            .foregroundColor(.mainorange)
                                        
                                        Text("kcal")
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding(.leading, 10)
                                .frame(maxWidth: .infinity, alignment: .leading) // 왼쪽 정렬
                            }
                            .padding(.horizontal, 20)
                        }
                    
                    // 목표 걸음 수 설정
                    RectViewH(height: 130, color: .white)
                        .overlay {
                            VStack {
                                Text("목표 걸음 수")
                                    .font(.system(size: 20))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Button(action: {
                                        if goalSteps > 0 {
                                            goalSteps -= 100 // 목표 걸음 수 감소
                                        }
                                    }) {
                                        Text("-")
                                            .font(.system(size: 30))
                                            .frame(width: 50, height: 50)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                    
                                    Text("\(goalSteps)")
                                        .font(.system(size: 30))
                                        .fontWeight(.bold)
                                        .foregroundColor(.mainorange)
                                    
                                    Button(action: {
                                        goalSteps += 100 // 목표 걸음 수 증가
                                    }) {
                                        Text("+")
                                            .font(.system(size: 30))
                                            .frame(width: 50, height: 50)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding()
                        }
                    
                    RectViewH(height: 300, color: .white)
                        .overlay {
                            
                            Text("이번주 걸음 수는?")
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // 좌측 상단 정렬
                            
                            
                            GradientAreaChartExampleView(stepData: viewModel.weeklyStepData) // 최근 7일 데이터 전달
                                .padding(10)
                        }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        //.background(.gray1)
        .onAppear {
            viewModel.startPedometerUpdates()
            viewModel.fetchLast7DaysStepData()
        }
    }
    
    // 현재 날짜를 문자열로 반환하는 함수
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일" // 원하는 포맷으로 설정
        return dateFormatter.string(from: Date())
    }
}

#Preview {
    HomeView(viewModel: .init(container: .init(services: StubService()), userId: "user1_id"))
}


// MARK: - ViewModel (Pedometer Data)
final class PedometerViewModel: ObservableObject {
    private var pedometer = CMPedometer()
    @Published var stepCount: Int = 0 {
        didSet { calculateCalories() }
    }
    @Published var caloriesBurned: Int = 0
    @Published var weeklyStepData: [StepData] = []
    
    init() {
        // 앱이 시작될 때 CMPedometer에서 걸음 수 가져오기
        startPedometerUpdates()
    }
    func startPedometerUpdates__() {
            let startOfToday = Calendar.current.startOfDay(for: Date())
            if CMPedometer.isStepCountingAvailable() {
                pedometer.queryPedometerData(from: startOfToday, to: Date()) { data, error in
                    if let data = data, error == nil {
                        DispatchQueue.main.async {
                            self.stepCount = data.numberOfSteps.intValue
                        }
                    }
                }
                pedometer.startUpdates(from: startOfToday) { data, error in
                    if let data = data, error == nil {
                        DispatchQueue.main.async {
                            self.stepCount = data.numberOfSteps.intValue
                        }
                    }
                }
            }
        }
    func startPedometerUpdates() {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        if CMPedometer.isStepCountingAvailable() {
            pedometer.queryPedometerData(from: startOfToday, to: Date()) { data, error in
                if let data = data, error == nil {
                    DispatchQueue.main.async {
                        self.stepCount = data.numberOfSteps.intValue
                        
                        // 오늘 데이터 업데이트
                        let todayStepData = StepData(date: startOfToday, steps: self.stepCount)
                        
                        if let index = self.weeklyStepData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfToday) }) {
                            self.weeklyStepData[index] = todayStepData
                        } else {
                            self.weeklyStepData.append(todayStepData)
                        }
                        
                        // 날짜 순으로 정렬
                        self.weeklyStepData.sort(by: { $0.date < $1.date })
                    }
                }
            }
            
            // 실시간 업데이트를 위한 startUpdates 설정
            pedometer.startUpdates(from: startOfToday) { data, error in
                if let data = data, error == nil {
                    DispatchQueue.main.async {
                        self.stepCount = data.numberOfSteps.intValue
                        
                        // 오늘 데이터 업데이트
                        let todayStepData = StepData(date: startOfToday, steps: self.stepCount)
                        
                        if let index = self.weeklyStepData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfToday) }) {
                            self.weeklyStepData[index] = todayStepData
                        } else {
                            self.weeklyStepData.append(todayStepData)
                        }
                        
                        // 날짜 순으로 정렬
                        self.weeklyStepData.sort(by: { $0.date < $1.date })
                    }
                }
            }
        }
    }

    
//    func startPedometerUpdates() {
//        let startOfToday = Calendar.current.startOfDay(for: Date())
//        if CMPedometer.isStepCountingAvailable() {
//            pedometer.queryPedometerData(from: startOfToday, to: Date()) { data, error in
//                if let data = data, error == nil {
//                    DispatchQueue.main.async {
//                        self.stepCount = data.numberOfSteps.intValue
//                    }
//                }
//            }
//            pedometer.startUpdates(from: startOfToday) { data, error in
//                if let data = data, error == nil {
//                    DispatchQueue.main.async {
//                        self.stepCount = data.numberOfSteps.intValue
//                    }
//                }
//            }
//        }
//    }
    
    private func calculateCalories() {
        let caloriesPerStep = 0.04
        self.caloriesBurned = Int(Double(stepCount) * caloriesPerStep)
    }
    
    func fetchLast7DaysStepData_save() {
        let calendar = Calendar.current
        weeklyStepData = [] // 초기화
        
        for dayOffset in 0..<7 {
            let startDate = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: Date()))!
            let endDate = calendar.date(byAdding: .day, value: -dayOffset + 1, to: calendar.startOfDay(for: Date()))!
            
            pedometer.queryPedometerData(from: startDate, to: endDate) { data, error in
                if let data = data, error == nil {
                    DispatchQueue.main.async {
                        let stepData = StepData(date: data.startDate, steps: data.numberOfSteps.intValue)
                        self.weeklyStepData.insert(stepData, at: 0) // 날짜 순서대로 추가
                    }
                }
            }
        }
    }
    func fetchLast7DaysStepData___() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date()) // 오늘의 시작 시간 (한국 시간 기준)
        weeklyStepData = [] // 초기화
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul") // 한국 시간대 설정
        
        // 어제까지의 6일간의 데이터를 수집
        for dayOffset in 1...6 {
            let startDate = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday)!
            let endDate = calendar.date(byAdding: .day, value: -dayOffset + 1, to: startOfToday)!

            pedometer.queryPedometerData(from: startDate, to: endDate) { data, error in
                DispatchQueue.main.async {
                    if let data = data, error == nil {
                        let stepData = StepData(date: startDate, steps: data.numberOfSteps.intValue)
                        self.weeklyStepData.insert(stepData, at: 0) // 날짜 순서대로 추가
                    } else {
                        // 데이터가 없는 경우 기본값 추가 (걸음 수 0)
                        let stepData = StepData(date: startDate, steps: 0)
                        self.weeklyStepData.insert(stepData, at: 0) // 날짜 순서대로 추가
                    }

                    // 디버깅을 위한 stepData 출력 (한국 시간대 적용)
                    //print("현재 stepData (어제까지): \(self.weeklyStepData.map { "\(dateFormatter.string(from: $0.date)): \($0.steps) 걸음" })")
                }
            }
        }
        
        // 오늘의 데이터를 실시간으로 업데이트
        pedometer.startUpdates(from: startOfToday) { data, error in
            DispatchQueue.main.async {
                if let data = data, error == nil {
                    let todaySteps = data.numberOfSteps.intValue
                    let todayStepData = StepData(date: startOfToday, steps: todaySteps)
                    
                    // 기존의 오늘 데이터가 있으면 업데이트하고, 없으면 추가
                    if let index = self.weeklyStepData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfToday) }) {
                        self.weeklyStepData[index] = todayStepData
                    } else {
                        self.weeklyStepData.append(todayStepData)
                    }

                    // 디버깅을 위한 최종 stepData 출력 (한국 시간대 적용)
                    //print("현재 stepData (오늘 포함): \(self.weeklyStepData.map { "\(dateFormatter.string(from: $0.date)): \($0.steps) 걸음" })")
                    
                    // 날짜 순으로 정렬
                    self.weeklyStepData.sort(by: { $0.date < $1.date })
                }
            }
        }
    }

    func fetchLast7DaysStepData() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date()) // 오늘의 시작 시간
        weeklyStepData = [] // 초기화
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul") // 한국 시간대 설정
        
        // 어제까지의 6일간의 데이터를 수집 (오늘 제외)
        for dayOffset in 1...6 {
            let startDate = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday)!
            let endDate = calendar.date(byAdding: .day, value: -dayOffset + 1, to: startOfToday)!

            pedometer.queryPedometerData(from: startDate, to: endDate) { data, error in
                DispatchQueue.main.async {
                    if let data = data, error == nil {
                        let stepData = StepData(date: startDate, steps: data.numberOfSteps.intValue)
                        self.weeklyStepData.insert(stepData, at: 0) // 날짜 순서대로 추가
                    } else {
                        // 데이터가 없는 경우 기본값 추가 (걸음 수 0)
                        let stepData = StepData(date: startDate, steps: 0)
                        self.weeklyStepData.insert(stepData, at: 0) // 날짜 순서대로 추가
                    }
                }
            }
        }
        
        // 실시간으로 오늘의 걸음 수는 startPedometerUpdates에서 처리
    }



    



}




// MARK: - Model
struct StepData: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
}

// MARK: - View

struct GradientAreaChartExampleView: View {
    
    // 최근 7일간의 걸음 수 데이터를 외부에서 전달받는 속성
//    @Binding var stepData: [StepData]
    let stepData: [StepData]
    
    
    // 그래디언트 스타일 정의
    let linearGradient = LinearGradient(
        gradient: Gradient(
            colors: [
                Color.maincolor.opacity(0.4), // 상단의 불투명한 색상
                Color.maincolor.opacity(0)    // 하단의 투명한 색상
            ]
        ),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        Chart {
            // MARK: - line
            ForEach(stepData) { data in
                LineMark(x: .value("Date", data.date),
                         y: .value("Steps", data.steps))
                .foregroundStyle(.mainorange)
            }
            .interpolationMethod(.cardinal)
            
            // MARK: - gradient
            ForEach(stepData) { data in
                AreaMark(x: .value("Date", data.date),
                         y: .value("Steps", data.steps))
              
            }
            .interpolationMethod(.cardinal)
            .foregroundStyle(linearGradient)
            
            // MARK: - dot
            ForEach(stepData) { data in
                PointMark(x: .value("Date", data.date),
                          y: .value("Steps", data.steps)) // 점 표시
                    .foregroundStyle(.mainred) // 점의 색상 설정
                    .symbolSize(40) // 점 크기 설정
                
                    .annotation(position: .top) { // 점의 우측 대각선 상단에 표시
                        Text("\(data.steps)")
                            .font(.caption)
                            .foregroundColor(.black)
                            .padding(3)
                            .background(Color.white)
                            .cornerRadius(5)
                            .shadow(radius: 1)
                    }
            }
        }

        .offset(x: 20) // 오른쪽으로 20포인트 이동
        .chartXAxis {
                AxisMarks(values: stride(from: -1, to: 7, by: 1).map { dayOffset in
                    Calendar.current.date(byAdding: .day, value: -6 + dayOffset, to: Date())! // 오늘 날짜를 포함하여 7일 생성
                }.reversed()) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel(getKoreanWeekday(from: date), centered: true)
                            .offset(x: -20)
                    }
                }
            }
        
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...12000) // 걸음 수 최대 범위 설정
//        .aspectRatio(1, contentMode: .fit)
//        .frame(width: 400, height: 300)
        //.frame(width: 350, height: 250) // 원하는 높이 설정
    }
        
    


    // MARK: - Helper Function (한글 요일 표시)
    func getKoreanWeekday_save(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR") // 한국어 로케일 설정
        dateFormatter.dateFormat = "E" // 요일만 출력하기 위한 포맷 (월, 화, 수...)
        return dateFormatter.string(from: date) // 변환된 요일 문자열 반환
    }
    
    // MARK: - Helper Function (한글 요일 표시)
        func getKoreanWeekday(from date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR") // 한국어 로케일 설정
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul") // 한국 시간대 설정
            dateFormatter.dateFormat = "E" // 요일만 출력하기 위한 포맷 (월, 화, 수...)
            return dateFormatter.string(from: date) // 변환된 요일 문자열 반환
        }
}






























//        .chartXAxis {
//            AxisMarks(values: stepData.map { $0.date }) { value in
//                if let date = value.as(Date.self) {
//                    AxisValueLabel(getKoreanWeekday(from: date), centered: true)
//                }
//            }
//        }


//        .chartXAxis {
//            AxisMarks(values: stride(from: 0, to: 7, by: 1).map { dayOffset in
//                Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
//            }.reversed()) { value in
//                if let date = value.as(Date.self) {
//                    AxisValueLabel(getKoreanWeekday(from: date), centered: true)
//                }
//            }
//        }


//        .chartXAxis {
//            AxisMarks(values: stepData.map { $0.date }) { value in
//                //AxisGridLine()
//                //AxisTick()
//                if let date = value.as(Date.self) {
//                    AxisValueLabel(getKoreanWeekday(from: date), centered: true)
//                }
//            }
//        }
