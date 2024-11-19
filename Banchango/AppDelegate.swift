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


class AppDelegate: NSObject, UIApplicationDelegate {
    
    // var bluetoothManager: BluetoothManager?
    
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Firebase 초기화
        FirebaseApp.configure()
        
        // Bluetooth 초기화
//        bluetoothManager = BluetoothManager()
//        
//        // Bluetooth 상태 변경을 추적하려면 CBCenteralManager 초기화
//        let centralManager = CBCentralManager(delegate: bluetoothManager, queue: nil)
//
//        
        
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
}
