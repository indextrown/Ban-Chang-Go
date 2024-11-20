//
//  PostureView.swift
//  Banchango
//
//  Created by 김동현 on 11/19/24.
//

import SwiftUI
import CoreBluetooth
import CoreMotion

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    
    @Published var isAirPodsConnected = false
    @Published var isBluetoothEnabled = false // 블루투스 활성화 상태
    
    override init() {
        super.init()
    }
    
    // 블루투스 초기화 및 장치 스캔 시작
    func startBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // 블루투스 상태 변경 시 호출되는 메서드
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            isBluetoothEnabled = true
            centralManager?.scanForPeripherals(withServices: nil, options: nil) // 블루투스 스캔 시작
        case .poweredOff:
            print("Bluetooth is powered off")
            isBluetoothEnabled = false
            self.isAirPodsConnected = false
        default:
            print("Bluetooth 상태: \(central.state.rawValue)")
        }
    }
    
    // 블루투스 장치가 발견되었을 때 호출되는 메서드
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        if let name = peripheral.name, name.contains("AirPods") {
            print("AirPods 발견: \(name)")
            self.peripheral = peripheral
            centralManager?.stopScan() // 에어팟을 찾았으면 스캔을 멈춥니다.
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    // 에어팟 연결 성공 시 호출되는 메서드
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("AirPods에 연결됨")
        self.isAirPodsConnected = true
    }
    
    // 에어팟 연결 해제 시 호출되는 메서드
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("AirPods 연결 해제됨")
        self.isAirPodsConnected = false
    }
}

// HeadphoneMotionManager 클래스
class HeadphoneMotionManager: ObservableObject {
    private var headphoneManager = CMHeadphoneMotionManager()
    
    @Published var isAuthorized = false
    @Published var isTracking = false
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var yaw: Double = 0.0
    
    @Published var remainTime: Int = 5
    @Published var isMonitoring = false
    @Published var isCalibrating = false
    @Published var calibrationTimer: Int = 5
    @Published var monitoringTimer: Int = 0
    @Published var isAlerting = false
    @Published var calibrationPitch: Double = 0.0
    @Published var calibrationRoll: Double = 0.0
    @Published var calibrationYaw: Double = 0.0
    
    private var timer: Timer?
    
    init() {
        updateAuthorization()
        startTracking()
    }
    
    func updateAuthorization() {
        isAuthorized = CMHeadphoneMotionManager.authorizationStatus() == .authorized
    }
    
    func startTracking() {
        guard headphoneManager.isDeviceMotionAvailable else { return }
        if isTracking { return }
        
        headphoneManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            DispatchQueue.main.async {
                self.pitch = motion.attitude.pitch
                self.roll = motion.attitude.roll
                self.yaw = motion.attitude.yaw
            }
        }
        isTracking = true
    }
    
    func stopTracking() {
        headphoneManager.stopDeviceMotionUpdates()
        isTracking = false
    }
    
    func calibrate() {
        if let motion = headphoneManager.deviceMotion {
            calibrationPitch = motion.attitude.pitch
            calibrationRoll = motion.attitude.roll
            calibrationYaw = motion.attitude.yaw
        }
    }
    
    func startMonitoring() {
        monitoringTimer = remainTime * 60
        isMonitoring = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.monitoringTimer > 0 {
                self.monitoringTimer -= 1
                let forwardHeadThreshold: Double = -0.4
                self.isAlerting = self.pitch < forwardHeadThreshold
                if self.isAlerting {
                    print("바른 자세를 해주세요")
                }
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            } else {
                self.stopMonitoring()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        isMonitoring = false
    }
    
    func startCalibration() {
        isCalibrating = true
        calibrationTimer = 5
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.calibrationTimer > 1 {
                self.calibrationTimer -= 1
            } else {
                self.timer?.invalidate()
                self.isCalibrating = false
                self.calibrate()
                self.startMonitoring()
            }
        }
    }
}

struct PostureView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var motionManager: HeadphoneMotionManager
    @State private var isAnimating = false // 회전 애니메이션 상태
    @State private var isMonitoring: Bool = false // 모니터링 상태 유지
    
    var body: some View {
        ZStack {
            // 배경색
            Color.gray1
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 30) {
                    // 상단 HStack
                    HStack(spacing: 20) {
                        // ZStack: AirPods 상태 아이콘 및 도넛 애니메이션
                        ZStack {
                            Circle()
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: bluetoothManager.isAirPodsConnected ? [.green, .green] : [.blue, .clear]),
                                        center: .center
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: 120, height: 152)
                                .rotationEffect(Angle(degrees: isAnimating && !bluetoothManager.isAirPodsConnected ? 360 : 0))
                                .animation(
                                    isAnimating && !bluetoothManager.isAirPodsConnected
                                    ? Animation.linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                    value: isAnimating
                                )
                                .onAppear {
                                    isAnimating = true
                                }
                            
                            Image("AirPods")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                                .foregroundColor(bluetoothManager.isAirPodsConnected ? .green : .blue)
                        }
                        
                        // VStack: 연결 상태 텍스트와 버튼
                        VStack(spacing: 10) {
                            // 연결 상태 텍스트
                            Text(bluetoothManager.isAirPodsConnected ? "에어팟이 연결되었습니다!" : "에어팟을 연결해주세요.")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(bluetoothManager.isAirPodsConnected ? .green : .red)
                            
                            // Bluetooth 연결 버튼
                            Button(action: {
                                bluetoothManager.startBluetooth()
                            }) {
                                HStack {
                                    Image(systemName: bluetoothManager.isAirPodsConnected ? "checkmark.circle.fill" : "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    
                                    Text(bluetoothManager.isAirPodsConnected ? "연결 완료" : "연결 시도")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(bluetoothManager.isAirPodsConnected ? .maincolor : .blue)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                            .disabled(bluetoothManager.isAirPodsConnected)
                        }
                    }
                    .padding(.horizontal)
                    
          
                    // 자세 교정 뷰
                    PostureSetupView()
                }
                .padding()
                .onAppear {
                    bluetoothManager.startBluetooth()
                }
            }
        }
    }
}



struct PostureSetupView: View {
    @EnvironmentObject var motionManager: HeadphoneMotionManager
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 200)
                .rotation3DEffect(.radians(motionManager.pitch), axis: (x: 1, y: 0, z: 0))
                .rotation3DEffect(.radians(motionManager.yaw), axis: (x: 0, y: 1, z: 0))
                .rotation3DEffect(.radians(motionManager.roll), axis: (x: 0, y: 0, z: 1))
                .padding()

            // 현재 Pitch, Roll, Yaw 표시
            VStack(spacing: 10) {
                Text("Pitch: \(motionManager.pitch, specifier: "%.2f")")
                Text("Roll: \(motionManager.roll, specifier: "%.2f")")
                Text("Yaw: \(motionManager.yaw, specifier: "%.2f")")
            }

            // 데이터 피커
            HStack {
                Text("모니터링 시간 (분):")
                Picker("", selection: $motionManager.remainTime) {
                    ForEach(Array(stride(from: 5, through: 60, by: 5)), id: \.self) { time in
                        Text("\(time)분").tag(time)
                    }
                }
                .frame(width: 100)
                .clipped()
            }

            // 기준 자세 설정 및 모니터링 버튼
            Button(action: {
                if motionManager.isMonitoring {
                    motionManager.stopMonitoring()
                } else if !motionManager.isCalibrating {
                    motionManager.startCalibration()
                }
            }) {
                Text(motionManager.isCalibrating
                     ? "등을 펴고 정면을 5초간 바라보세요... (\(motionManager.calibrationTimer)초)"
                     : motionManager.isMonitoring
                     ? "남은 시간: \(motionManager.monitoringTimer)초 (멈추기)"
                     : "바른 자세 설정")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(motionManager.isMonitoring ? Color.red :
                                motionManager.isCalibrating || !bluetoothManager.isAirPodsConnected ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(motionManager.isCalibrating && !motionManager.isMonitoring)

            // 자세 상태 메시지
            if motionManager.isMonitoring {
                Text(motionManager.isAlerting ? "자세가 틀어졌습니다!" : "바른 자세 유지 중입니다.")
                    .foregroundColor(motionManager.isAlerting ? .red : .green)
                    .font(.headline)
            }
        }
//        .onAppear {
//            motionManager.updateAuthorization()
//            motionManager.startTracking()
//        }
//        .onDisappear {
//            motionManager.stopTracking()
//        }
    }
}












struct PostureView_Previews: PreviewProvider {
    static var previews: some View {
        PostureView()
            .environmentObject(BluetoothManager())
    }
}

