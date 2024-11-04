//
//  HomeViewTest.swift
//  Banchango
//
//  Created by 김동현 on 11/4/24.
//

import SwiftUI
import Charts
import CoreMotion

struct HomeTestView: View {
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
            LoadedView2()
                .environmentObject(viewModel)
               
        case .fail:
            ErrorView()
        }
    }
}

struct LoadedView2: View {
    @StateObject private var viewModel = PedometerViewModel()
    
    var body: some View {
        VStack {
            //Text("테스트")
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

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
                                        //Text("5,950")
                                        Text("\(viewModel.stepCount)")
                                            .font(.system(size: 30))
                                            .fontWeight(.bold)
                                            .foregroundColor(.mainorange)
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
                            .padding(.horizontal, 20) // HStack 전체에 좌우 여백 설정
                        }
                        .padding(.top, 30)
                    


                    RectViewH(height: 300, color: .white)
                        .overlay {
                            
                            Text("이번주 평균 걸음 수는?")
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // 좌측 상단 정렬
                            
                            GradientAreaChartExampleView(stepData: GradientAreaChartExampleView2().stepData)
                                .padding(.leading, 20) // 차트를 오른쪽으로 이동
                                .padding(.trailing, -20) // 필요 시 오른쪽 여백 제거
                                .padding(.bottom, 20)
                        }
                    
                    RectViewH(height: 600, color: .white)
                        .overlay {
                            Text("나의 건강 그래프")
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // 좌측 상단 정렬
                        
                        }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(Color.gray1) // 배경색 설정
        .background(.maincolor) // 배경색 설정//.edgesIgnoringSafeArea(.all) // 안전 영역을 무시하고 전체 화면에 배경색 적용
        .onAppear {
            viewModel.startPedometerUpdates()
        }
    }
}


struct GradientAreaChartExampleView2: View {
    // 일주일 간의 데이터 예시
    let stepData = [
        StepData(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, steps: 4681),
        StepData(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, steps: 1901),
        StepData(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, steps: 6188),
        StepData(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, steps: 3854),
        StepData(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, steps: 7811),
        StepData(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, steps: 2146),
        StepData(date: Date(), steps: 768)
    ]
    
    let linearGradient = LinearGradient(
        gradient: Gradient(
            colors: [
                Color.maincolor.opacity(0.4),
                Color.maincolor.opacity(0)
            ]
        ),
        startPoint: .top,
        endPoint: .bottom)
    
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
            }
        }
        
        .chartXAxis {
            AxisMarks(values: stepData.map { $0.date }) { value in
                //AxisGridLine()
                //AxisTick()
                if let date = value.as(Date.self) {
                    AxisValueLabel(getKoreanWeekday(from: date), centered: true)
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...12000) // 걸음 수 최대 범위 설정
        //.aspectRatio(1, contentMode: .fit)
        //.frame(width: 350, height: 250) // 원하는 높이 설정
    }
    
    // 한글 요일 표시를 위한 함수
    func getKoreanWeekday(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "E" // 요일을 한글로 출력하기 위한 포맷 (월, 화, 수...)
        return dateFormatter.string(from: date)
    }
    
}



#Preview {
    HomeTestView(viewModel: .init(container: .init(services: StubService()), userId: "user1_id"))
}
