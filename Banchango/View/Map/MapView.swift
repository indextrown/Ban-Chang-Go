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

    // 디바운스를 위한 작업 항목
    private var debounceWorkItem: DispatchWorkItem?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // CLLocationManagerDelegate: 위치 업데이트 메서드
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        // 첫 위치 업데이트에만 카메라 위치를 설정
        if isFirstUpdate {
            position = .camera(
                MapCamera(centerCoordinate: location.coordinate, distance: 5000, heading: 0, pitch: 0)
            )
            isFirstUpdate = false
        }
        
        // 현재 위치를 업데이트
        self.location = location
        
        // 디바운스를 사용하여 너무 자주 호출되는 것을 방지
        debounceWorkItem?.cancel()
        debounceWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.region.center = location.coordinate
        }
        
        if let workItem = debounceWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    }
}

// SwiftUI View에서 LocationManager 사용
struct MapView: View {
    @StateObject private var viewModel = LocationManager()

    var body: some View {
        ZStack {
            Map(position: $viewModel.position) {
                //UserAnnotation()
                // 사용자 위치에 커스텀 MapMarker 표시
                if let location = viewModel.location {
                    // 사용자 위치에 커스텀 마커를 추가
                    Annotation("내 위치", coordinate: location.coordinate) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 15, height: 15)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(radius: 3)
                    }
                }
            }
            .ignoresSafeArea()
            
            /* MARK: - 현재 위치 디버깅용
            VStack {
                if let location = viewModel.location {
                    Text("현재 위치: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                        .padding(8)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(8)
                        .foregroundColor(.bkText)
                        .padding(.top, 50)
                } else {
                    Text("위치 정보를 불러오는 중입니다...")
                        .padding(8)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(8)
                        .foregroundColor(.bkText)
                        .padding(.top, 50)
                }
                Spacer()
            }
             */
            
        }
    }
}

#Preview {
    MapView()
}
