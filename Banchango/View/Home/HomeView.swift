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
    // 테스트 호출 함수
    var body: some View {
        VStack {
            contentView
        }
//        .background(Color.gray1)
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
    @EnvironmentObject private var homeVewModel: HomeViewModel
    @State private var goalSteps: Int = 2000 // 기본 목표 걸음 수
    
    var body: some View {

        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("반창고")
                                .font(.system(size: 35, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 0)
                                .padding(.bottom, 10)
                            
                            HStack {
                                Text("\(homeVewModel.myUser?.nickname ?? "닉네임")")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.lightGreen)
                                    
                                
                                Text("\("님")")
                                    .font(.system(size: 25))
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("\(viewModel.stepCount)걸음")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.lightGreen)
                                
                                Text("걸어")
                                    .font(.system(size: 25))
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("\(viewModel.caloriesBurned)Kcal")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.lightGreen)
                                
                                Text("소모했어요!")
                                    .font(.system(size: 25))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                                .frame(height: 10)
                           
                            HStack {
                                Spacer()
                                Text("남은 걸음: \(goalSteps - viewModel.stepCount)")
                                    .font(.body)
                                    .font(.system(size: 15))
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(.white)
                                    .cornerRadius(30)
                            }
                            .padding(.trailing, 20)
                            
                        }
                        .padding(.leading, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 70)
                        .background(.green)

                        VStack {
                            HStack {
                                Spacer()
                                Image("Character")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit) // 비율에 맞춰 이미지 크기 조정
                                    .frame(width: 150, height: 150) // 원하는 크기로 조정
                                    .padding(.trailing, 15)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.bottom, -30)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("오늘의 목표 걸음은?")
                                .font(.system(size: 20, weight: .bold))
                            
                            RectViewH(height: 130, color: .white)
                                .overlay {
                                    VStack {
                                        Text("목표 걸음")
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
                                                    .foregroundColor(.bkText)
                                                //.background(Color.gray.opacity(0.2))
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
                                                    .foregroundColor(.bkText)
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                    .padding()
                                }
                            
                            Text("이번주 걸음 그래프")
                                .font(.system(size: 20, weight: .bold))
                                .padding(.top, 30)
                            
                            RectViewH(height: 270, color: .white)
                                .overlay {

                                    GradientAreaChartExampleView(stepData: viewModel.weeklyStepData)
                                        .padding(.top, 50)
                                        .padding(.leading, 20) // 차트를 오른쪽으로 이동
                                        .padding(.trailing, -20) // 필요 시 오른쪽 여백 제거
                                        .padding(.bottom, 20)
                                }

                            
                        }
                        .padding()
                        .padding(.top, -120)
                    }
                    .padding(.vertical, 130)
                    .background(.gray1)
                    .cornerRadius(20)
                    
                }
            }
        }
        .onAppear {
            viewModel.startPedometerUpdates()
            viewModel.fetchLast7DaysStepData()
        }
        .background(VStack(spacing: .zero) { Color.green; Color.gray1 })
        .ignoresSafeArea()
    }
         
    
    // 현재 날짜를 문자열로 반환하는 함수
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일" // 원하는 포맷으로 설정
        return dateFormatter.string(from: Date())
    }
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
    }
}


// MARK: - Model
struct StepData: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
}

struct GradientAreaChartExampleView: View {
    
    // 최근 7일간의 걸음 수 데이터를 외부에서 전달받는 속성
    let stepData: [StepData]
    
    // 그래디언트 스타일 정의
    let linearGradient = LinearGradient(
        gradient: Gradient(
            colors: [
                Color.maincolor.opacity(0.4),
                Color.maincolor.opacity(0)
            ]
        ),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        Chart {
            ForEach(stepData) { data in
                LineMark(x: .value("Date", data.date),
                         y: .value("Steps", data.steps))
                    .foregroundStyle(.mainorange)
                    .interpolationMethod(.cardinal)
                
                AreaMark(x: .value("Date", data.date),
                         y: .value("Steps", data.steps))
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(linearGradient)
                
                PointMark(x: .value("Date", data.date),
                          y: .value("Steps", data.steps))
                    .foregroundStyle(.mainred)
                    .symbolSize(40)
                    .annotation(position: .top) {
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
        .chartXAxis {
            // x축에 표시할 날짜 배열 생성
            let weekdays = Array(stride(from: Calendar.current.date(byAdding: .day, value: -1, to: stepData.first?.date ?? Date())!,
                                        to: Calendar.current.date(byAdding: .day, value: 2, to: stepData.last?.date ?? Date())!,
                                        by: 60 * 60 * 24))
            
            AxisMarks(values: weekdays) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(getKoreanWeekday(from: date), centered: true)
                        .offset(x: -20)
                }
            }
        }
        .chartYAxis(.hidden) // y축 눈금 제거
        .chartYScale(domain: 0...10000)
        .chartXScale(domain: (stepData.first?.date ?? Date())...(Calendar.current.date(byAdding: .day, value: 1, to: stepData.last?.date ?? Date())!))
        .padding(.leading, 20)
        .padding(.trailing, 20)
        .frame(height: 200)
    }
    
    func getKoreanWeekday(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: date)
    }
}


#Preview {
    HomeView(viewModel: .init(container: .init(services: StubService()), userId: "user1_id"))
}


/*
// MARK: - legacy

import SwiftUI
import CoreMotion
import Charts

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    // 테스트 호출 함수
    
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
                                    Text("오늘의 걸음 👟")
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
                                Text("목표 걸음")
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
                                            .foregroundColor(.bkText)
                                            //.background(Color.gray.opacity(0.2))
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
                                            .foregroundColor(.bkText)
//                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding()
                        }
                    
                    
                    RectViewH(height: 270, color: .white)
                        .overlay {
                            Text("이번주 걸음 그래프")
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding()
                                .padding(.leading, 10)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // 좌측 상단 정렬
                                
                            
                            GradientAreaChartExampleView(stepData: viewModel.weeklyStepData)
                                .padding(.top, 50)
                                .padding(.leading, 20) // 차트를 오른쪽으로 이동
                                .padding(.trailing, -20) // 필요 시 오른쪽 여백 제거
                                .padding(.bottom, 20)
                        }

                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
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
    }
}


// MARK: - Model
struct StepData: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
}

struct GradientAreaChartExampleView: View {
    
    // 최근 7일간의 걸음 수 데이터를 외부에서 전달받는 속성
    let stepData: [StepData]
    
    // 그래디언트 스타일 정의
    let linearGradient = LinearGradient(
        gradient: Gradient(
            colors: [
                Color.maincolor.opacity(0.4),
                Color.maincolor.opacity(0)
            ]
        ),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        Chart {
            ForEach(stepData) { data in
                LineMark(x: .value("Date", data.date),
                         y: .value("Steps", data.steps))
                    .foregroundStyle(.mainorange)
                    .interpolationMethod(.cardinal)
                
                AreaMark(x: .value("Date", data.date),
                         y: .value("Steps", data.steps))
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(linearGradient)
                
                PointMark(x: .value("Date", data.date),
                          y: .value("Steps", data.steps))
                    .foregroundStyle(.mainred)
                    .symbolSize(40)
                    .annotation(position: .top) {
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
        .chartXAxis {
            // x축에 표시할 날짜 배열 생성
            let weekdays = Array(stride(from: Calendar.current.date(byAdding: .day, value: -1, to: stepData.first?.date ?? Date())!,
                                        to: Calendar.current.date(byAdding: .day, value: 2, to: stepData.last?.date ?? Date())!,
                                        by: 60 * 60 * 24))
            
            AxisMarks(values: weekdays) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(getKoreanWeekday(from: date), centered: true)
                        .offset(x: -20)
                }
            }
        }
        .chartYAxis(.hidden) // y축 눈금 제거
        .chartYScale(domain: 0...10000)
        .chartXScale(domain: (stepData.first?.date ?? Date())...(Calendar.current.date(byAdding: .day, value: 1, to: stepData.last?.date ?? Date())!))
        .padding(.leading, 20)
        .padding(.trailing, 20)
        .frame(height: 200)
    }
    
    func getKoreanWeekday(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: date)
    }
}


/*
struct GradientAreaChartExampleView_Previews: PreviewProvider {
    static var previews: some View {
        let calendar = Calendar.current
        let today = calendar.date(byAdding: .day, value: -7, to: Date())!
        //calendar.startOfDay(for: Date()) // 오늘 날짜
        
        // 지난 6일치 데이터와 오늘 날짜를 포함한 데이터를 생성
        let testStepData: [StepData] = (0...6).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            return StepData(date: date, steps: Int.random(in: 1000...8000))
        }.reversed() // 날짜가 오름차순이 되도록 뒤집기
        
        // GradientAreaChartExampleView의 Preview에 생성한 테스트 데이터 전달
        GradientAreaChartExampleView(stepData: testStepData)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
*/



#Preview {
    HomeView(viewModel: .init(container: .init(services: StubService()), userId: "user1_id"))
}
*/
