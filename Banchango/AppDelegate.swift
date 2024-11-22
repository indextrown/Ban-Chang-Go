//
//  AppDelegate.swift
//  Banchango
//
//  Created by 김동현 on 11/2/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import CoreBluetooth
import UserNotifications


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Firebase 초기화
        FirebaseApp.configure()
        
        // 알림 권한 허용
        requestNotificationPermission()
        
        // UNUserNotificationCenterDelegate 설정(Foreground 상태에서도 알림 표시)
        UNUserNotificationCenter.current().delegate = self
        
        
        
        /*
        gRPC 관련 환경 변수 설정 (GRPC_TRACE 제거)
        setenv("GRPC_VERBOSITY", "ERROR", 1)
        unsetenv("GRPC_TRACE") // GRPC_TRACE 환경 변수 제거
         */
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한 허용됨")
            } else {
                print("알림 권한 거부됨")
            }
        }
    }
    
    // Foreground 상태에서도 알림 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Foreground 상태에서도 배너와 소리 표시
        completionHandler([.banner, .sound])
    }
}
