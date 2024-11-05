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
                        MapCamera(centerCoordinate: location.coordinate, distance: 5000, heading: 0, pitch: 0)
                    )
                    self.isFirstUpdate = false
                    print("최초한번은 그냥 호출")
                    //self.fetchNearbyPharmacies()
                    self.debouncefetchNearbyPharmacies(for: location.coordinate)
                }
            }

            // 현재 위치를 업데이트
            DispatchQueue.main.async {
                self.location = location
            }
        }
    }

    
    func fetchNearbyPharmacies() {
            guard let location = location else { return }
            
            Task {
                let result = await PharmacyService.shared.getNearbyPharmacies(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                switch result {
                case .success(let pharmacies):
                    DispatchQueue.main.async {
                        self.pharmacies = pharmacies
                    }
                case .failure(let error):
                    print("약국 데이터를 가져오는 데 실패했습니다: \(error)")
                }
            }
        }
    
    // 현재 위치로 카메라 이동 함수
    func moveToCurrentLocation() {
        if let location = location {
            DispatchQueue.main.async {
                self.position = .camera(
                    MapCamera(centerCoordinate: location.coordinate, distance: 5000, heading: 0, pitch: 0)
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

  
    // 비동기로 약국 정보를 가져오는 함수
    func debouncefetchNearbyPharmacies(for coordinate: CLLocationCoordinate2D) {
        DispatchQueue.global(qos: .userInitiated).async {
            Task { [weak self] in
                guard let self = self else { return }
                let result = await PharmacyService.shared.getNearbyPharmacies(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                switch result {
                case .success(let newPharmacies):
                    // 백그라운드 스레드에서 딕셔너리 처리
                    var pharmacyDictionary: [String: Pharmacy] = [:]
                    
                    // 기존 약국을 딕셔너리에 추가
                    for pharmacy in self.pharmacies {
                        let key = "\(pharmacy.name) \(pharmacy.address)"
                        pharmacyDictionary[key] = pharmacy
                    }
                    
                    // 새로운 약국을 딕셔너리에 추가
                    for newPharmacy in newPharmacies {
                        let key = "\(newPharmacy.name) \(newPharmacy.address)"
                        pharmacyDictionary[key] = newPharmacy // 중복된 경우 무시하고 추가
                    }
                    
                    // 딕셔너리를 배열로 변환한 후 UI 업데이트를 위해 메인 스레드로 전환
                    let updatedPharmacies = Array(pharmacyDictionary.values)
                    
                    DispatchQueue.main.async {
                        self.pharmacies = updatedPharmacies
                    }
                    
                    //                    // 디버깅 출력: 약국 목록을 이쁘게 출력
                    //                    let formattedPharmacies = updatedPharmacies.map { pharmacy in
                    //                        return """
                    //                        이름: \(pharmacy.name)
                    //                        주소: \(pharmacy.address)
                    //                        city: \(pharmacy.city)
                    //                        전화번호: \(pharmacy.phone)
                    //                        좌표: (\(pharmacy.latitude), \(pharmacy.longitude))
                    //                        운영시간: \(pharmacy.operatingHours)
                    //                        """
                    //                    }.joined(separator: "\n-----------------\n") // 각 약국 정보 사이에 구분선 추가
                    //                    
                    //                    print("Updated pharmacies:\n\(formattedPharmacies)")
                    
                    
                    
                     // 운영 시간이 비어있는 경우에만 세부 정보 요청
                     for pharmacy in updatedPharmacies where pharmacy.operatingHours.isEmpty {
                         print("Fetching details for pharmacy: \(pharmacy.name)")
                             Task {
                                 let city = pharmacy.city[0]
                                 let lastCity = pharmacy.city[1]
                                     if let detailedPharmacy = await PharmacyManager.shared.getPharmacyInfo_async(q0: city, q1: lastCity, pageNo: "1", numOfRows: "10", qn: pharmacy.name) {
                                         DispatchQueue.main.async {
                                            if let index = self.pharmacies.firstIndex(where: { $0.name == detailedPharmacy.name }) {
                                                self.pharmacies[index].operatingHours = detailedPharmacy.operatingHours
                                            }
                                         }
                                     } else {
                                         print("Failed to fetch details for pharmacy: \(pharmacy.name)")
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
                                .foregroundColor(.green)
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
//                viewModel.fetchNearbyPharmacies(for: centerCoordinate)
            }
            //.ignoresSafeArea()
            //
            // 모달 뷰 표시
            .sheet(item: $selectedPlace) { place in
                // 선택된 장소가 있을 경우 모달 뷰를 표시
                PharmacyDetailView(pharmacy: place)
                    .presentationDetents([.fraction(0.5)])  // 모달 뷰가 화면의 절반만 차지하도록 설정
            }
//            .sheet(isPresented: $showDetailView) {
//                if let selectedPlace = selectedPlace {
//                    PharmacyDetailView(pharmacy: selectedPlace)
//                        //.presentationDetents([.medium])
//                        .presentationDetents([.fraction(0.3)])  // 모달 뷰가 화면의 절반만 차지하도록 설정
//                }
//            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        viewModel.moveToCurrentLocation()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.mainorange)
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
        VStack(alignment: .leading, spacing: 16) {
            Text(pharmacy.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("주소: \(pharmacy.address)")
                .font(.body)

            Text("전화번호: \(pharmacy.phone)")
                .font(.body)

            Text("운영시간:")
                .font(.headline)
            Text("\(pharmacy.operatingHours)")
            Spacer()
        }
        .padding()
        .navigationTitle("약국 상세 정보")
        .navigationBarTitleDisplayMode(.inline)
    }
}
/*


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
                        MapCamera(centerCoordinate: location.coordinate, distance: 5000, heading: 0, pitch: 0)
                    )
                    self.isFirstUpdate = false
                    print("최초한번은 그냥 호출")
                    //self.fetchNearbyPharmacies()
                    self.debouncefetchNearbyPharmacies(for: location.coordinate)
                }
            }

            // 현재 위치를 업데이트
            DispatchQueue.main.async {
                self.location = location
            }

            // 디바운스를 사용하여 너무 자주 호출되는 것을 방지
//            self.debounceWorkItem?.cancel()
//            self.debounceWorkItem = DispatchWorkItem { [weak self] in
//                guard let self = self else { return }
//                DispatchQueue.main.async { // UI 업데이트가 메인 스레드에서 이루어지도록 보장
//                    self.region.center = location.coordinate
//                }
//            }
//
//            if let workItem = self.debounceWorkItem {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
//            }
        }
    }

    
    func fetchNearbyPharmacies() {
            guard let location = location else { return }
            
            Task {
                let result = await PharmacyService.shared.getNearbyPharmacies(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                switch result {
                case .success(let pharmacies):
                    DispatchQueue.main.async {
                        self.pharmacies = pharmacies
                    }
                case .failure(let error):
                    print("약국 데이터를 가져오는 데 실패했습니다: \(error)")
                }
            }
        }
    
    
    
    
    // 현재 위치로 카메라 이동 함수
    func moveToCurrentLocation() {
        if let location = location {
            DispatchQueue.main.async {
                self.position = .camera(
                    MapCamera(centerCoordinate: location.coordinate, distance: 5000, heading: 0, pitch: 0)
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

  
    // 비동기로 약국 정보를 가져오는 함수
    func debouncefetchNearbyPharmacies_save(for coordinate: CLLocationCoordinate2D) {
        debounceWorkItem?.cancel() // 기존 작업 취소 (Debounce)
        debounceWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Task { [weak self] in
                guard let self = self else { return }
                let result = await PharmacyService.shared.getNearbyPharmacies(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                switch result {
                    
                case .success(let newPharmacies):
                    DispatchQueue.main.async {
                        var existingPharmacies = Set(self.pharmacies) // 기존 약국을 Set으로 변환
                        for newPharmacy in newPharmacies {
                            existingPharmacies.insert(newPharmacy) // 중복된 경우 무시하고 추가
                        }
                        self.pharmacies = Array(existingPharmacies) // Set을 배열로 변환하여 pharmacies에 저장
                        
                        // 디버깅 출력: 약국 목록을 이쁘게 출력
                        let formattedPharmacies = existingPharmacies.map { pharmacy in
                            return """
                            이름: \(pharmacy.name)
                            주소: \(pharmacy.address)
                            city: \(pharmacy.city)
                            전화번호: \(pharmacy.phone)
                            좌표: (\(pharmacy.latitude), \(pharmacy.longitude))
                            운영시간: \(pharmacy.operatingHours)
                            """
                        }.joined(separator: "\n-----------------\n") // 각 약국 정보 사이에 구분선 추가

                        print("Updated pharmacies:\n\(formattedPharmacies)")
                        
                        
                        /*
                        for pharmacy in existingPharmacies {
                            print("Fetching details for pharmacy: \(pharmacy.name)") // 약국 이름 출력
                            Task {
                                let city = pharmacy.city[0] // 직접 입력할 시도
                                let lastCity = pharmacy.city[1] // 직접 입력할 시군구
                                let name = pharmacy.name // 약국 이름

                                if let detailedPharmacy = await PharmacyManager.shared.getPharmacyInfo_async(q0: city, q1: lastCity, pageNo: "1", numOfRows: "10", qn: name) {
                                    DispatchQueue.main.async {
                                        if let index = self.pharmacies.firstIndex(where: { $0.name == detailedPharmacy.name }) {
                                            self.pharmacies[index] = detailedPharmacy
                                            print("Updated pharmacy details: \(detailedPharmacy)") // 디버깅 출력
                                        }
                                    }
                                } else {
                                    print("Failed to fetch details for pharmacy: \(pharmacy.name)") // 디버깅 출력
                                }
                            }
                        }
                        */
                        
                        
                        
                        
                    }
                case .failure(let error):
                    print("약국 데이터를 가져오는 데 실패했습니다: \(error)")
                }
            }
        }
        
        if let workItem = debounceWorkItem {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    }
    func debouncefetchNearbyPharmacies_today(for coordinate: CLLocationCoordinate2D) {
//        debounceWorkItem?.cancel() // 기존 작업 취소 (Debounce)
//        debounceWorkItem = DispatchWorkItem { [weak self] in
//            guard let self = self else { return }
            Task { [weak self] in
                guard let self = self else { return }
                let result = await PharmacyService.shared.getNearbyPharmacies(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                switch result {
                case .success(let newPharmacies):
                    // 백그라운드 스레드에서 딕셔너리 처리
                    var pharmacyDictionary: [String: Pharmacy] = [:]
                    
                    // 기존 약국을 딕셔너리에 추가
                    for pharmacy in self.pharmacies {
                        let key = "\(pharmacy.name) \(pharmacy.address)"
                        pharmacyDictionary[key] = pharmacy
                    }
                    
                    // 새로운 약국을 딕셔너리에 추가
                    for newPharmacy in newPharmacies {
                        let key = "\(newPharmacy.name) \(newPharmacy.address)"
                        pharmacyDictionary[key] = newPharmacy // 중복된 경우 무시하고 추가
                    }
                    
                    // 딕셔너리를 배열로 변환한 후 UI 업데이트를 위해 메인 스레드로 전환
                    let updatedPharmacies = Array(pharmacyDictionary.values)
                    
                    DispatchQueue.main.async {
                        self.pharmacies = updatedPharmacies
                        
                        // 디버깅 출력: 약국 목록을 이쁘게 출력
                        let formattedPharmacies = updatedPharmacies.map { pharmacy in
                            return """
                            이름: \(pharmacy.name)
                            주소: \(pharmacy.address)
                            city: \(pharmacy.city)
                            전화번호: \(pharmacy.phone)
                            좌표: (\(pharmacy.latitude), \(pharmacy.longitude))
                            운영시간: \(pharmacy.operatingHours)
                            """
                        }.joined(separator: "\n-----------------\n") // 각 약국 정보 사이에 구분선 추가
                        
                        print("Updated pharmacies:\n\(formattedPharmacies)")
                    }
                    
                    // 운영 시간이 비어있는 경우에만 세부 정보 요청
                    for pharmacy in updatedPharmacies where pharmacy.operatingHours.isEmpty {
                        print("Fetching details for pharmacy: \(pharmacy.name)")
                        Task {
                            let city = pharmacy.city[0]
                            let lastCity = pharmacy.city[1]
                            if let detailedPharmacy = await PharmacyManager.shared.getPharmacyInfo_async(q0: city, q1: lastCity, pageNo: "1", numOfRows: "10", qn: pharmacy.name) {
                                DispatchQueue.main.async {
                                    if let index = self.pharmacies.firstIndex(where: { $0.name == detailedPharmacy.name }) {
                                        self.pharmacies[index].operatingHours = detailedPharmacy.operatingHours
                                    }
                                }
                            } else {
                                print("Failed to fetch details for pharmacy: \(pharmacy.name)")
                            }
                        }
                    }

                case .failure(let error):
                    print("약국 데이터를 가져오는 데 실패했습니다: \(error)")
                }
            }
        }

    func debouncefetchNearbyPharmacies_tt(for coordinate: CLLocationCoordinate2D) {
        debounceWorkItem?.cancel() // 기존 작업 취소 (Debounce)
        
        debounceWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            Task { [weak self] in
                guard let self = self else { return }
                
                // 비동기적으로 약국 데이터 가져오기
                let result = await PharmacyService.shared.getNearbyPharmacies(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                switch result {
                case .success(let newPharmacies):
                    // 딕셔너리 처리를 백그라운드 스레드에서 수행
                    DispatchQueue.global(qos: .userInitiated).async {
                        var pharmacyDictionary: [String: Pharmacy] = [:]
                        
                        // 기존 약국을 딕셔너리에 추가
                        for pharmacy in self.pharmacies {
                            let key = "\(pharmacy.name) \(pharmacy.address)"
                            pharmacyDictionary[key] = pharmacy
                        }
                        
                        // 새로운 약국을 딕셔너리에 추가 (중복된 경우 업데이트)
                        for newPharmacy in newPharmacies {
                            let key = "\(newPharmacy.name) \(newPharmacy.address)"
                            pharmacyDictionary[key] = newPharmacy
                        }
                        
                        // 딕셔너리를 배열로 변환
                        let updatedPharmacies = Array(pharmacyDictionary.values)
                        
                        // UI 업데이트를 위해 메인 스레드에서 처리
                        DispatchQueue.main.async {
                            self.pharmacies = updatedPharmacies
                            
                            // 디버깅 출력: 약국 목록을 이쁘게 출력
                            let formattedPharmacies = updatedPharmacies.map { pharmacy in
                                return """
                                이름: \(pharmacy.name)
                                주소: \(pharmacy.address)
                                city: \(pharmacy.city)
                                전화번호: \(pharmacy.phone)
                                좌표: (\(pharmacy.latitude), \(pharmacy.longitude))
                                운영시간: \(pharmacy.operatingHours)
                                """
                            }.joined(separator: "\n-----------------\n")
                            
                            print("Updated pharmacies:\n\(formattedPharmacies)")
                        }
                        
                        /*
                        // 운영 시간이 비어있는 경우에만 세부 정보 요청
                        for pharmacy in updatedPharmacies where pharmacy.operatingHours.isEmpty {
                            Task {
                                let city = pharmacy.city[0]
                                let lastCity = pharmacy.city[1]
                                if let detailedPharmacy = await PharmacyManager.shared.getPharmacyInfo_async(q0: city, q1: lastCity, pageNo: "1", numOfRows: "10", qn: pharmacy.name) {
                                    DispatchQueue.main.async {
                                        if let index = self.pharmacies.firstIndex(where: { $0.name == detailedPharmacy.name }) {
                                            self.pharmacies[index].operatingHours = detailedPharmacy.operatingHours
                                        }
                                    }
                                } else {
                                    print("Failed to fetch details for pharmacy: \(pharmacy.name)")
                                }
                            }
                        }
                         */
                    }
                    
                case .failure(let error):
                    print("약국 데이터를 가져오는 데 실패했습니다: \(error)")
                }
            }
        }
        
        if let workItem = debounceWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    }

    func debouncefetchNearbyPharmacies_now(for coordinate: CLLocationCoordinate2D) {
        
        debounceWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            Task { [weak self] in
                guard let self = self else { return }
                
                // 비동기적으로 약국 데이터 가져오기
                let result = await PharmacyService.shared.getNearbyPharmacies(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                switch result {
                case .success(let newPharmacies):
                    // 딕셔너리 처리를 백그라운드 스레드에서 수행
                    DispatchQueue.global(qos: .userInitiated).async {
                        var pharmacyDictionary: [String: Pharmacy] = [:]
                        
                        // 기존 약국을 딕셔너리에 추가
                        for pharmacy in self.pharmacies {
                            let key = "\(pharmacy.name) \(pharmacy.address)"
                            pharmacyDictionary[key] = pharmacy
                        }
                        
                        // 새로운 약국을 딕셔너리에 추가 (중복된 경우 업데이트)
                        for newPharmacy in newPharmacies {
                            let key = "\(newPharmacy.name) \(newPharmacy.address)"
                            pharmacyDictionary[key] = newPharmacy
                        }
                        
                        // 딕셔너리를 배열로 변환
                        let updatedPharmacies = Array(pharmacyDictionary.values)
                        
                        // UI 업데이트를 위해 메인 스레드에서 처리
                        DispatchQueue.main.async {
                            self.pharmacies = updatedPharmacies
                            
                            // 디버깅 출력: 약국 목록을 이쁘게 출력
                            let formattedPharmacies = updatedPharmacies.map { pharmacy in
                                return """
                                이름: \(pharmacy.name)
                                주소: \(pharmacy.address)
                                city: \(pharmacy.city)
                                전화번호: \(pharmacy.phone)
                                좌표: (\(pharmacy.latitude), \(pharmacy.longitude))
                                운영시간: \(pharmacy.operatingHours)
                                """
                            }.joined(separator: "\n-----------------\n")
                            
                            print("Updated pharmacies:\n\(formattedPharmacies)")
                        }
                        
                        
                        // 운영 시간이 비어있는 경우에만 세부 정보 요청
                        for pharmacy in updatedPharmacies where pharmacy.operatingHours.isEmpty {
                            Task {
                                let city = pharmacy.city[0]
                                let lastCity = pharmacy.city[1]
                                if let detailedPharmacy = await PharmacyManager.shared.getPharmacyInfo_async(q0: city, q1: lastCity, pageNo: "1", numOfRows: "10", qn: pharmacy.name) {
                                    DispatchQueue.main.async {
                                        if let index = self.pharmacies.firstIndex(where: { $0.name == detailedPharmacy.name }) {
                                            self.pharmacies[index].operatingHours = detailedPharmacy.operatingHours
                                        }
                                    }
                                } else {
                                    print("Failed to fetch details for pharmacy: \(pharmacy.name)")
                                }
                            }
                        }
                         
                    }
                    
                case .failure(let error):
                    print("약국 데이터를 가져오는 데 실패했습니다: \(error)")
                }
            }
        }
        
        if let workItem = debounceWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    }
    
    func debouncefetchNearbyPharmacies(for coordinate: CLLocationCoordinate2D) {
        DispatchQueue.global(qos: .userInitiated).async {
            Task { [weak self] in
                guard let self = self else { return }
                let result = await PharmacyService.shared.getNearbyPharmacies(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                switch result {
                case .success(let newPharmacies):
                    // 백그라운드 스레드에서 딕셔너리 처리
                    var pharmacyDictionary: [String: Pharmacy] = [:]
                    
                    // 기존 약국을 딕셔너리에 추가
                    for pharmacy in self.pharmacies {
                        let key = "\(pharmacy.name) \(pharmacy.address)"
                        pharmacyDictionary[key] = pharmacy
                    }
                    
                    // 새로운 약국을 딕셔너리에 추가
                    for newPharmacy in newPharmacies {
                        let key = "\(newPharmacy.name) \(newPharmacy.address)"
                        pharmacyDictionary[key] = newPharmacy // 중복된 경우 무시하고 추가
                    }
                    
                    // 딕셔너리를 배열로 변환한 후 UI 업데이트를 위해 메인 스레드로 전환
                    let updatedPharmacies = Array(pharmacyDictionary.values)
                    
                    DispatchQueue.main.async {
                        self.pharmacies = updatedPharmacies
                    }
                    
                    //                    // 디버깅 출력: 약국 목록을 이쁘게 출력
                    //                    let formattedPharmacies = updatedPharmacies.map { pharmacy in
                    //                        return """
                    //                        이름: \(pharmacy.name)
                    //                        주소: \(pharmacy.address)
                    //                        city: \(pharmacy.city)
                    //                        전화번호: \(pharmacy.phone)
                    //                        좌표: (\(pharmacy.latitude), \(pharmacy.longitude))
                    //                        운영시간: \(pharmacy.operatingHours)
                    //                        """
                    //                    }.joined(separator: "\n-----------------\n") // 각 약국 정보 사이에 구분선 추가
                    //
                    //                    print("Updated pharmacies:\n\(formattedPharmacies)")
                    
                    
                    
                     // 운영 시간이 비어있는 경우에만 세부 정보 요청
                     for pharmacy in updatedPharmacies where pharmacy.operatingHours.isEmpty {
                         print("Fetching details for pharmacy: \(pharmacy.name)")
                             Task {
                                 let city = pharmacy.city[0]
                                 let lastCity = pharmacy.city[1]
                                     if let detailedPharmacy = await PharmacyManager.shared.getPharmacyInfo_async(q0: city, q1: lastCity, pageNo: "1", numOfRows: "10", qn: pharmacy.name) {
                                         DispatchQueue.main.async {
                                            if let index = self.pharmacies.firstIndex(where: { $0.name == detailedPharmacy.name }) {
                                                self.pharmacies[index].operatingHours = detailedPharmacy.operatingHours
                                            }
                                         }
                                     } else {
                                         print("Failed to fetch details for pharmacy: \(pharmacy.name)")
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
                                .foregroundColor(.green)
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
//                viewModel.fetchNearbyPharmacies(for: centerCoordinate)
            }
            //.ignoresSafeArea()
            //
            // 모달 뷰 표시
            .sheet(item: $selectedPlace) { place in
                // 선택된 장소가 있을 경우 모달 뷰를 표시
                PharmacyDetailView(pharmacy: place)
                    .presentationDetents([.fraction(0.5)])  // 모달 뷰가 화면의 절반만 차지하도록 설정
            }
//            .sheet(isPresented: $showDetailView) {
//                if let selectedPlace = selectedPlace {
//                    PharmacyDetailView(pharmacy: selectedPlace)
//                        //.presentationDetents([.medium])
//                        .presentationDetents([.fraction(0.3)])  // 모달 뷰가 화면의 절반만 차지하도록 설정
//                }
//            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        viewModel.moveToCurrentLocation()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.mainorange)
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
        VStack(alignment: .leading, spacing: 16) {
            Text(pharmacy.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("주소: \(pharmacy.address)")
                .font(.body)

            Text("전화번호: \(pharmacy.phone)")
                .font(.body)

            Text("운영시간:")
                .font(.headline)
            Text("\(pharmacy.operatingHours)")
//            ForEach(pharmacy.operatingHours.sorted(by: { $0.key < $1.key }), id: \.key) { day, hours in
//                Text("\(day): \(hours)")
//            }

            Spacer()
        }
        .padding()
        .navigationTitle("약국 상세 정보")
        .navigationBarTitleDisplayMode(.inline)
    }
}




*/
