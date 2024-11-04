//
//  MainTabVIew.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var container: DIContainer
    //@EnvironmentObject var homeVM: HomeViewModel
    @State private var selectedTab: MainTabType = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(MainTabType.allCases, id: \.self) { tab in
                Group {
                    switch tab {
                    case .home:
                        HomeView(viewModel: .init(container: container, userId: authVM.userId ?? ""))
                    case .map:
                        MapView()
                    case .profile:
                        ProfileView(profileVM: ProfileViewModel(container: container, userId: authVM.userId ?? "없음", currentUser: authVM.currentUser))
                        //ProfileView(profileVM: .init(container: container, userId: authVM.userId ?? ""))

                    }
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.imageName())
                }
                .tag(tab)
            }
        }

        .tint(Color.mainorange) // 주황색으로 설정
    }
    init() {
        UITabBar.appearance().backgroundColor = .white
        //UITabBar.appearance().unselectedItemTintColor = UIColor(Color.bkText)
    }
}

#Preview {
    MainTabView()
}

