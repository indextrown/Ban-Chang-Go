//
//  MapView.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI
import MapKit
import CoreLocation

// LocationManager: 사용자 위치를 관리하는 클래스
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    // 사용자 위치가 처음 업데이트될 때만 카메라 위치를 업데이트하기 위해 플래그 추가
    private var isFirstUpdate = true
    private var loadedPharmacies: Set<String> = []
    
    // 카메라 위치 관리
    @Published var position: MapCameraPosition = .automatic
    
    // 현재 위치 정보를 저장하는 @Published 속성
    @Published var location: CLLocation?

    // 지도의 영역을 관리하는 변수
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.16839757570803, longitude: 128.1347953060123), // 초기 위치 설정
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @Published var pharmacies: [Pharmacy] = [] // 약국 데이터를 저장할 배열

    // 디바운스를 위한 작업 항목
    private var debounceWorkItem: DispatchWorkItem?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let location = locations.first else { return }

            // 첫 위치 업데이트에만 카메라 위치를 설정
            if self.isFirstUpdate {
                DispatchQueue.main.async { // UI 업데이트가 메인 스레드에서 이루어지도록 보장
                    self.position = .camera(
                        MapCamera(centerCoordinate: location.coordinate, distance: 4000, heading: 0, pitch: 0)
                    )
                    
                    print("최초한번은 그냥 호출")
                    //self.fetchNearbyPharmacies()
                    self.debouncefetchNearbyPharmacies(for: location.coordinate)
                    self.isFirstUpdate = false
                }
            }

            // 현재 위치를 업데이트
            DispatchQueue.main.async {
                self.location = location
            }
        }
    }

    // 현재 위치로 카메라 이동 함수
    func moveToCurrentLocation() {
        if let location = location {
            DispatchQueue.main.async {
                self.position = .camera(
                    MapCamera(centerCoordinate: location.coordinate, distance: 4000, heading: 0, pitch: 0)
                )
            }
        }
    }

    func fetchPharmacyDetails(for pharmacy: Pharmacy) async -> Pharmacy? {
        // 도시와 이름을 올바르게 인코딩
        guard let city = pharmacy.city.first,
              let lastCity = pharmacy.city.last,
              let name = pharmacy.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Invalid city or name for pharmacy: \(pharmacy.name)")
            return nil
        }

        // 상세 정보를 가져오는 함수 호출
        let detailedPharmacy = await PharmacyManager.shared.getPharmacyInfo_async(q0: city, q1: lastCity, pageNo: "1", numOfRows: "10", qn: name)

        if let detailedPharmacy = detailedPharmacy {
            print("Successfully fetched detailed pharmacy info: \(detailedPharmacy)")
        } else {
            print("No details found for pharmacy: \(pharmacy.name)")
        }

        return detailedPharmacy
    }
    
    func debouncefetchNearbyPharmacies(for coordinate: CLLocationCoordinate2D) {
        DispatchQueue.global(qos: .userInitiated).async {
            Task { [weak self] in
                guard let self = self else { return }
                let result = await PharmacyService.shared.getNearbyPharmacies(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                switch result {
                case .success(let newPharmacies):
                    DispatchQueue.main.async {
                        for newPharmacy in newPharmacies {
                            // 기존 약국 찾기
                            if let existingIndex = self.pharmacies.firstIndex(where: { $0.name == newPharmacy.name && $0.address == newPharmacy.address }) {
                                // 기존 약국이 있는 경우 운영 상태를 덮어쓰지 않음
                                let existingPharmacy = self.pharmacies[existingIndex]
                                self.pharmacies[existingIndex].operatingHours = existingPharmacy.operatingHours.isEmpty ? newPharmacy.operatingHours : existingPharmacy.operatingHours
                                self.pharmacies[existingIndex].isOpen = existingPharmacy.isOpen
                            } else {
                                // 새로운 약국 데이터인 경우 추가
                                self.pharmacies.append(newPharmacy)
                            }
                        }
                    }

                    // 운영 시간이 비어 있고, 새로운 약국들에 대해서만 세부 정보 요청 및 업데이트
                    for pharmacy in self.pharmacies where pharmacy.operatingHours.isEmpty {
                        let pharmacyKey = "\(pharmacy.name) \(pharmacy.address)"
                        
                        if !self.loadedPharmacies.contains(pharmacyKey) {
                            //print("Attempting to fetch details for:", pharmacyKey)
                            
                            Task {
                                //print("Task started for:", pharmacyKey)
                                
                                /*
                                guard let city = pharmacy.city.first, let lastCity = pharmacy.city.last,
                                      let encodedName = pharmacy.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                                    //print("Guard condition failed for:", pharmacyKey)
                                    return
                                }
                                 */
                                guard let city = pharmacy.city.first, let lastCity = pharmacy.city.last else {
                                    return
                                }
                                
                                if let detailedPharmacy = await PharmacyManager.shared.getPharmacyInfo_async(q0: city, q1: lastCity, pageNo: "1", numOfRows: "10", qn: pharmacy.name) {
                                    DispatchQueue.main.async {
                                        if let index = self.pharmacies.firstIndex(where: { $0.name == detailedPharmacy.name }) {
                                            self.pharmacies[index].operatingHours = detailedPharmacy.operatingHours
                                            
                                            // 영업 상태 업데이트
                                            let today = getDay(from: Date())
                                            let hours = operatingHours(for: today, operatingHours: self.pharmacies[index].operatingHours)
                                            self.pharmacies[index].isOpen = isOpenNow(startTime: hours.start, endTime: hours.end)
                                        }
                                        
                                        // 세부 정보를 성공적으로 로드한 약국은 loadedPharmacies에 추가
                                        self.loadedPharmacies.insert(pharmacyKey)
                                        //print("Added to loadedPharmacies:", pharmacyKey)
                                    }
                                } else {
                                    print("Failed to fetch details for pharmacy:", pharmacyKey)
                                }
                            }
                        }
                    }
                     
                case .failure(let error):
                    print("약국 데이터를 가져오는 데 실패했습니다: \(error)")
                }
            }
        }
    }

}

// SwiftUI View에서 LocationManager 사용
struct MapView: View {
    @StateObject private var viewModel = LocationManager()
    @State private var selectedPlace: Pharmacy? // 선택된 약국 정보
    @State private var showDetailView = false // 모달 표시 여부

    var body: some View {
        ZStack {
            Map(position: $viewModel.position) {
                //UserAnnotation()
                
                // 내위치 커스텀마커
                if let location = viewModel.location {
                    // 사용자 위치에 커스텀 마커를 추가
                    Annotation("내 위치", coordinate: location.coordinate) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 17, height: 17)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(radius: 3)
                    }
                }
                
                ForEach(viewModel.pharmacies, id: \.name) {pharmacy in
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: pharmacy.latitude, longitude: pharmacy.longitude)) {
                        Button {
                            selectedPlace = pharmacy
                            
                            if selectedPlace != nil {
                                DispatchQueue.main.async {
                                    self.showDetailView.toggle()
                                }
                            }
                        
                            //showDetailView.toggle() ///
                        } label: {
                            Image(systemName: "pill.circle")
                                .resizable()
                                .foregroundColor(pharmacy.isOpen == true ? .red : .gray)
                                //.foregroundColor(.green)
                                .background(Circle().fill(Color.white))
                                .frame(width: 30, height: 30)
                                .shadow(radius: 4)
                        }
//                        .onAppear {
//                            print("디버깅: \(pharmacy)")
//                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onMapCameraChange { context in
                // 카메라 중심 좌표 변경 시 호출
                let centerCoordinate = context.camera.centerCoordinate
                viewModel.debouncefetchNearbyPharmacies(for: centerCoordinate)
            }
            //.ignoresSafeArea()
            // 모달 뷰 표시
            .sheet(item: $selectedPlace) { place in
                // 선택된 장소가 있을 경우 모달 뷰를 표시
                PharmacyDetailView(pharmacy: place)
                    .presentationDetents([.fraction(0.5)])  // 모달 뷰가 화면의 절반만 차지하도록 설정
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        viewModel.moveToCurrentLocation()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.maincolor)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 2) // 테두리 추가
                                )
                            
                            Image(systemName: "location.fill") // 아이콘
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .offset(x: -1, y: 1)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

#Preview {
    MapView()
}

struct PharmacyDetailView: View {
    var pharmacy: Pharmacy

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(pharmacy.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                
                if pharmacy.isOpen {
                    Text("영업중")
                        .foregroundColor(.red)
                } else {
                    Text("영업 종료")
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
                .frame(height: 10)
            
            let today = getDay(from: Date())
            let hours = operatingHours(for: today, operatingHours: pharmacy.operatingHours)
            
            // 약국 정보가 있을 때 표시
            Text("\(hours.start) ~ \(hours.end)")
                .font(.system(size: 15))

            Spacer()
                .frame(height: 10)

            Text("\(pharmacy.address)")
                    .font(.system(size: 15))
  
            Text("연락처: \(pharmacy.phone)")
                .font(.system(size: 15))

            Text("운영시간:")
                .font(.system(size: 15))
                .padding(.top, 30)
            
            VStack(alignment: .leading, spacing: 5) {
               Text("월요일: \(formattedOperatingHours(for: "월요일"))")
               Text("화요일: \(formattedOperatingHours(for: "화요일"))")
               Text("수요일: \(formattedOperatingHours(for: "수요일"))")
               Text("목요일: \(formattedOperatingHours(for: "목요일"))")
               Text("금요일: \(formattedOperatingHours(for: "금요일"))")
               Text("토요일: \(formattedOperatingHours(for: "토요일"))")
               Text("일요일: \(formattedOperatingHours(for: "일요일"))")
           }
            
//            Text("\(pharmacy.operatingHours)")
//            Spacer()
        }
        .padding()
        .navigationTitle("약국 상세 정보")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 특정 요일에 대한 운영 시간을 가져오는 함수
    private func formattedOperatingHours(for day: String) -> String {
        let hours = operatingHours(for: day, operatingHours: pharmacy.operatingHours)
        return "\(hours.start) - \(hours.end)"
    }
}

