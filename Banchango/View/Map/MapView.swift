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
    
    // 약국 데이터를 저장할 배열
    @Published var pharmacies: [Pharmacy] = []
    
    // 검색 결과 저장
    @Published var searchResults: [Pharmacy] = []
    
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
    
    // 특정 위치로 카메라 이동 함수
    func moveToLocation(latitude: Double, longitude: Double) {
        DispatchQueue.main.async {
            let newCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            //print("Moving to Location: Latitude \(latitude), Longitude \(longitude)")
            
            self.position = .camera(
                MapCamera(centerCoordinate: newCoordinate, distance: 1000, heading: 0, pitch: 0)
            )
        }
    }

    
    func searchPharmacies(by name: String) {
        guard let location = self.location else {
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }

        location.coordinate.toCityName { [weak self] cityArray in
            guard let self = self else { return }
            guard let cityArray = cityArray else {
                DispatchQueue.main.async {
                    self.searchResults = []
                }
                return
            }

            // 배열을 각각 분리하여 q0, q1에 할당
            let normalizedCityfirst = self.normalizeCityName(cityArray[0])
            let q0 = normalizedCityfirst // 시
            let q1 = cityArray[1]  // 군
            //print("cityArray: \(cityArray), q0: \(q0), q1: \(q1)")
            
            Task {
                // `getPharmacyInfo_async` 호출
                if let searchResult = await PharmacyManager.shared.getPharmaciesInfo_async(
                    q0: q0,
                    q1: q1,
                    pageNo: "1",
                    numOfRows: "5",
                    qn: name
                ) {
                    //print("\(q0) \(q1) \(name)")
                    //print(searchResult)
                    DispatchQueue.main.async {
                        // 검색 결과를 업데이트
                        self.searchResults = searchResult
                    }
                } else {
                    DispatchQueue.main.async {
                        // 결과가 없으면 비우기
                        self.searchResults = []
                    }
                }
            }
        }
    }
     
    
    func searchPharmacy__(by name: String) {
        guard let location = self.location else {
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }

        location.coordinate.toCityName { [weak self] cityArray in
            guard let self = self else { return }
            guard let cityArray = cityArray, cityArray.count == 2 else {
                DispatchQueue.main.async {
                    self.searchResults = []
                }
                return
            }

            // 배열을 각각 분리하여 q0, q1에 할당
            let normalizedCityfirst = self.normalizeCityName(cityArray[0])
            let q0 = normalizedCityfirst // 시
            let q1 = cityArray[1]  // 군
            //print("cityArray: \(cityArray), q0: \(q0), q1: \(q1)")
            Task {
                if let searchResult = await PharmacyManager.shared.getPharmacyInfo_async(
                    q0: q0,
                    q1: q1,
                    pageNo: "1",
                    numOfRows: "10",
                    qn: name
                ) {
                    DispatchQueue.main.async {
                        //print("Search succeeded: \(searchResult)")
                        self.searchResults = [searchResult]
                    }
                } else {
                    DispatchQueue.main.async {
                        self.searchResults = []
                    }
                }
            }
        }
    }

    
    func moveToPharmacy(_ pharmacy: Pharmacy) {
       moveToLocation(latitude: pharmacy.latitude, longitude: pharmacy.longitude)
    }


    func fetchPharmacyDetails(for pharmacy: Pharmacy) async -> Pharmacy? {
        // 도시와 이름을 올바르게 인코딩
        guard let city = pharmacy.city.first,
              let lastCity = pharmacy.city.last,
              let name = pharmacy.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
#if DEBUG
            print("Invalid city or name for pharmacy: \(pharmacy.name)")
#endif
            return nil
        }
        
        // 약국 정보 가져오기
        let detailedPharmacy = await PharmacyManager.shared.getPharmacyInfo_async(q0: city, q1: lastCity, pageNo: "1", numOfRows: "10", qn: name)
        
#if DEBUG
        if let detailedPharmacy = detailedPharmacy {
            print("Successfully fetched detailed pharmacy info: \(detailedPharmacy)")
        } else {
            print("No details found for pharmacy: \(pharmacy.name)")
        }
#endif
        
        return detailedPharmacy
    }
    
    func debouncefetchNearbyPharmacies(for coordinate: CLLocationCoordinate2D) {
        // 기존 작업 취소
        debounceWorkItem?.cancel()
        
        // 새로운 작업 생성
        debounceWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // Task로 비동기 작업 처리
            Task {
                // 비동기 API 호출
                let result = await PharmacyService.shared.getNearbyPharmacies(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                switch result {
                case .success(let newPharmacies):
                    // 새 약국 데이터를 처리
                    let pharmaciesToAdd = newPharmacies.filter { newPharmacy in
                        !self.pharmacies.contains(where: { $0.name == newPharmacy.name && $0.address == newPharmacy.address })
                    }
                    
                    // UI 업데이트 (메인 스레드)
                    DispatchQueue.main.async {
                        self.pharmacies.append(contentsOf: pharmaciesToAdd)
                    }
                    
                    // 약국 세부 정보 가져오기
                    for pharmacy in pharmaciesToAdd where pharmacy.operatingHours.isEmpty {
                        let pharmacyKey = "\(pharmacy.name) \(pharmacy.address)"
                        if !self.loadedPharmacies.contains(pharmacyKey) {
                            Task {
                                if let city = pharmacy.city.first, let lastCity = pharmacy.city.last {
                                    let normalizedCity = self.normalizeCityName(city)
                                    if let detailedPharmacy = await PharmacyManager.shared.getPharmacyInfo_async(
                                        q0: normalizedCity,
                                        q1: lastCity,
                                        pageNo: "1",
                                        numOfRows: "10",
                                        qn: pharmacy.name
                                    ) {
                                        // UI 업데이트 (메인 스레드)
                                        DispatchQueue.main.async {
                                            if let index = self.pharmacies.firstIndex(where: { $0.name == detailedPharmacy.name }) {
                                                self.pharmacies[index].operatingHours = detailedPharmacy.operatingHours
                                                let today = getDay(from: Date())
                                                let hours = operatingHours(for: today, operatingHours: detailedPharmacy.operatingHours)
                                                self.pharmacies[index].isOpen = isOpenNow(startTime: hours.start, endTime: hours.end)
                                            }
                                            self.loadedPharmacies.insert(pharmacyKey)
                                        }
                                    }
                                }
                            }
                        }
                    }
                case .failure(let error):
                    // 에러 처리
                    DispatchQueue.main.async {
#if DEBUG
                        print("Failed to fetch nearby pharmacies: \(error)")
#endif
                    }
                }
            }
        }
        
        // 디바운스 딜레이 설정 (0.6초)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: debounceWorkItem!)
    }
    
    // 도시 이름 변환 함수
    func normalizeCityName(_ city: String) -> String {
        switch city {
        case "서울": return "서울특별시"
        case "부산": return "부산광역시"
        case "대구": return "대구광역시"
        case "인천": return "인천광역시"
        case "광주": return "광주광역시"
        case "대전": return "대전광역시"
        case "울산": return "울산광역시"
        case "세종": return "세종특별자치시"
        case "경기": return "경기도"
        case "강원": return "강원도"
        case "충북": return "충청북도"
        case "충남": return "충청남도"
        case "전북": return "전라북도"
        case "전남": return "전라남도"
        case "경북": return "경상북도"
        case "경남": return "경상남도"
        case "제주": return "제주특별자치도"
        default: return city
        }
    }
}

extension CLLocationCoordinate2D {
    func toCityName(completion: @escaping ([String]?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: self.latitude, longitude: self.longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Geocoding failed with error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let placemark = placemarks?.first {
                // 디버깅 출력
                let details = "\(placemark)"
                //print("Placemark details: \(details)")

                // "대한민국" 기준으로 "시"와 "구" 추출
                var city = ""
                var district = ""

                if let countryRange = details.range(of: "대한민국") {
                    // "대한민국" 이후 텍스트 추출
                    let afterCountry = details[countryRange.upperBound...] // " 부산광역시 남구 수영로 306"
                    let components = afterCountry.split(separator: " ") // ["부산광역시", "남구", "수영로", "306"]

                    if components.count > 1 {
                        city = String(components[0]) // "부산광역시"
                        district = String(components[1]) // "남구"
                    }
                }

                // 결과 출력
                //print("Parsed City: \(city), Parsed District: \(district)")

                // 결과 반환
                if !city.isEmpty && !district.isEmpty {
                    completion([city, district])
                } else if !city.isEmpty {
                    completion([city])
                } else {
                    completion(nil)
                }
            } else {
                print("No placemarks found.")
                completion(nil)
            }
        }
    }
}

// SwiftUI View에서 LocationManager 사용
struct MapView: View {
    @StateObject private var viewModel = LocationManager()
    @State private var selectedPlace: Pharmacy? // 선택된 약국 정보
    @State private var showDetailView = false // 모달 표시 여부
    @State private var searchText: String = "" // 검색어 저장
    @State private var selectedPharmacy: Pharmacy? // 선택된 검색 결과
    @State private var detent: PresentationDetent = .fraction(0.18) // 시트 크기를 관리하는 상태 변수

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
                
                
                ForEach(viewModel.pharmacies, id: \.name) { pharmacy in
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: pharmacy.latitude, longitude: pharmacy.longitude)) {
                        Button {
                            selectedPlace = pharmacy
                            
                            if selectedPlace != nil {
                                DispatchQueue.main.async {
                                    self.showDetailView.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: "pill.circle")
                                .resizable()
                                .foregroundColor(pharmacy.isOpen == true ? .red : .gray)
                                //.foregroundColor(.green)
                                .background(Circle().fill(Color.white))
                                .frame(width: 30, height: 30)
                                .shadow(radius: 4)
                        }
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

            .sheet(item: $selectedPlace) { place in
                PharmacyDetailView(pharmacy: place, detent: $detent)
                    .presentationDetents([.fraction(0.18), .fraction(0.67)], selection: $detent)
                    .presentationDragIndicator(.hidden)// 선택 가능 크기 지정
            }
            
            VStack {
                Spacer()
                    .frame(height: 100)
                
                HStack {
                    TextField("약국 이름을 검색하세요", text: $searchText)
                        .onDisappear {
                            // 키보드 닫기
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .onSubmit {
                            // 엔터키 입력 시 검색 실행
                            viewModel.searchPharmacies(by: searchText)
                            
                            // 키보드 닫기
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 3)
                    
                    Button(action: {
                        viewModel.searchPharmacies(by: searchText)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(.maincolor))
                            .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                    .onDisappear {
                        // 키보드 닫기
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .padding(.horizontal, 30)
                
                if !viewModel.searchResults.isEmpty {
                    VStack(spacing: 0) {
                        List(viewModel.searchResults, id: \.name) { pharmacy in
                            Button {
                                selectedPharmacy = pharmacy
                                viewModel.moveToLocation(latitude: pharmacy.latitude, longitude: pharmacy.longitude) // 카메라 이동
                                viewModel.searchResults = []
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(pharmacy.name)
                                        .font(.headline)
                                    Text(pharmacy.address)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .listStyle(PlainListStyle()) // 기본 스타일 유지
                        .cornerRadius(20) // 리스트 자체를 둥글게
                        .frame(maxHeight: 400) // 리스트 최대 높이 제한
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20) // 리스트 전체를 감싸는 둥근 배경
                            .fill(Color.white) // 배경색 설정
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2) // 그림자 추가
                    )
                    .padding(.horizontal, 20) // 외부 여백 추가
                }
                
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

//#Preview {
//    MapView()
//}

struct PharmacyDetailView: View {
    var pharmacy: Pharmacy
    @Binding var detent: PresentationDetent // 시트 크기 상태를 바인딩으로 연결

    @State private var showCopyAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                HStack {
                    Text(pharmacy.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Button {
                        // 유효한 detent 값만 설정
                        if detent == .fraction(0.18) {
                            detent = .fraction(0.67) // 확장
                        } else {
                            detent = .fraction(0.18) // 축소
                        }
                    } label: {
                        Image(systemName: (detent == .fraction(0.18)) ? "ellipsis.circle" : "arrow.down")
                            .font(.system(size: 23))
                            .padding(.leading, 5)
                            .foregroundColor(.gray)
                            .font(.title)
                            
                    }
                    
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(pharmacy.isOpen ? .red : .gray)
                            .frame(width: 100, height: 40)
                        
                        Text(pharmacy.isOpen ? "영업중" : "영업종료")
                            .foregroundColor(pharmacy.isOpen ? .red : .gray)
                    }
                }
                
                Spacer()
                    .frame(height: 10)
                
                let today = getDay(from: Date())
                let hours = operatingHours(for: today, operatingHours: pharmacy.operatingHours)
                
                HStack {
                    Image(systemName: "clock")
                    Text("\(hours.start) ~ \(hours.end)")
                        .font(.system(size: 15))
                }
                
                Spacer()
                    .frame(height: 10)
                
                HStack {
                    Image(systemName: "mappin.circle")
                    Text("\(pharmacy.address)")
                        .font(.system(size: 15))
                }
                
                Spacer()
                    .frame(height: 10)
                
                HStack {
                    Image(systemName: "phone")
                    Text("\(pharmacy.phone)")
                        .font(.system(size: 15))
                    
                    Button {
                        UIPasteboard.general.string = pharmacy.phone
                        showCopyAlert = true
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                            .padding(.leading, 5)
                    }
                    .alert("전화번호가 복사되었습니다", isPresented: $showCopyAlert) {
                        Button("확인", role: .cancel) {}
                    }
                }
                
                Text("운영시간")
                    .font(.system(size: 23, weight: .bold))
                    .padding(.top, 30)
                
                Spacer()
                    .frame(height: 10)
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"], id: \.self) { day in
                        HStack {
                            Text(day.prefix(1)) // 요일 첫 글자만 표시
                                .font(.system(size: 15, weight: .bold))
                                .frame(width: 30)
                                .foregroundColor(day == "토요일" || day == "일요일" ? .red : .primary) // 주말 강조
                            
                            //                        Spacer()
                            
                            Text(formattedOperatingHours(for: day))
                                .font(.system(size: 15))
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(day == "토요일" || day == "일요일" ? Color.red.opacity(0.1) : Color.gray.opacity(0.1)) // 주말 강조 배경
                                )
                            
                        }
                        .padding(.vertical, 4) // 요일 간 간격
                    }
                }
                .padding(.top, 10)
            }
            .padding()
            .navigationTitle("약국 상세 정보")
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    // 특정 요일에 대한 운영 시간을 가져오는 함수
    private func formattedOperatingHours(for day: String) -> String {
        let hours = operatingHours(for: day, operatingHours: pharmacy.operatingHours)
        return "\(hours.start) - \(hours.end)"
    }
}



struct PharmacyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // 샘플 약국 데이터를 생성합니다.
        /*
        let samplePharmacy = Pharmacy(
            name: "샘플 약국",
            latitude: 37.5665,
            longitude: 126.9780,
            address: "서울특별시 강남구 테헤란로 123",
            city: ["서울특별시", "강남구"],
            roadAddress: "서울특별시 강남구 테헤란로 123",
            phone: "02-123-4567",
            operatingHours: [
                "월요일": "09:00 - 18:00",
                "화요일": "09:00 - 18:00",
                "수요일": "09:00 - 18:00",
                "목요일": "09:00 - 18:00",
                "금요일": "09:00 - 18:00",
                "토요일": "10:00 - 14:00",
                "일요일": "휴무"
            ]
        )
        */
        // State를 사용하여 detent 값을 관리하고 이를 Binding으로 전달합니다.
        StateWrapper()
            .previewLayout(.sizeThatFits)
    }

    // State를 관리하기 위한 래퍼 뷰
    struct StateWrapper: View {
        @State private var detent: PresentationDetent = .fraction(0.18)

        var body: some View {
            PharmacyDetailView(
                pharmacy: Pharmacy(
                    name: "샘플 약국",
                    latitude: 37.5665,
                    longitude: 126.9780,
                    address: "서울특별시 강남구 테헤란로 123",
                    city: ["서울특별시", "강남구"],
                    roadAddress: "서울특별시 강남구 테헤란로 123",
                    phone: "02-123-4567",
                    operatingHours: [
                        "월요일": "09:00 - 18:00",
                        "화요일": "09:00 - 18:00",
                        "수요일": "09:00 - 18:00",
                        "목요일": "09:00 - 18:00",
                        "금요일": "09:00 - 18:00",
                        "토요일": "10:00 - 14:00",
                        "일요일": "휴무"
                    ]
                ),
                detent: $detent
            )
        }
    }
}
