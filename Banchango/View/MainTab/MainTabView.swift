//
//  MainTabVIew.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI

enum MainTabType: CaseIterable {
    case home, map, profile
    
    var title: String {
        switch self {
        case .home: return "홈"
        case .map: return "지도"
        case .profile: return "프로필"
        }
    }
    
    func imageName(isSelected: Bool) -> String {
        switch self {
        case .home: return isSelected ? "house.fill" : "house"
        case .map: return isSelected ? "map.fill" : "map"
        case .profile: return isSelected ? "person.fill" : "person"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var container: DIContainer
    @StateObject var homeVM: HomeViewModel
    @State private var selectedTab: MainTabType = .home

    var body: some View {
        VStack(spacing: 0) {
            // 선택된 탭에 따라 다른 View를 표시
            ZStack {
                switch selectedTab {
                case .home:
                    HomeView()
                        .environmentObject(homeVM)
                        .ignoresSafeArea(edges: .top) // 최상단 여백 없이 채움
                case .map:
                    MapView()
                        .ignoresSafeArea(edges: .top)
                case .profile:
                    ProfileView()
                        .environmentObject(authVM)
                        .environmentObject(homeVM)
                        .ignoresSafeArea(edges: .top)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider() // 상단 구분선 추가
                .background(Color.gray.opacity(0.3))
            
            // Custom Tab Bar - 하단에 꽉 차게 구성
            HStack(spacing: 0) {
                ForEach(MainTabType.allCases, id: \.self) { tab in
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Image(systemName: tab.imageName(isSelected: selectedTab == tab))
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == tab ? .maincolor : .gray)
                        
                        Text(tab.title)
                            .font(.caption)
                            .foregroundColor(selectedTab == tab ? .maincolor : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white) // 탭바 배경 색상
                    .onTapGesture {
                        selectedTab = tab
                    }
                    
                    Spacer()
                }
            }
            .frame(height: 90) // 고정 높이
            .background(Color.white) // 탭바 배경
            .clipShape(Rectangle()) // 탭바의 모서리 부분이 깨지지 않도록 설정
            //.shadow(radius: 5) // 약간의 그림자 추가로 구분 명확하게
        }
        .edgesIgnoringSafeArea(.bottom) // 하단 여백 제거
        .background(Color.white.ignoresSafeArea()) // 전체 화면 배경 설정
    }
}
