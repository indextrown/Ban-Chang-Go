//
//  PostureView.swift
//  Banchango
//
//  Created by 김동현 on 11/19/24.
//

import SwiftUI
import CoreBluetooth
import CoreMotion
import Combine
import UserNotifications
import AVFoundation

final class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
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

final class HeadphoneMotionManageryes: ObservableObject {
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

final class HeadphoneMotionManager: ObservableObject {
    private var headphoneManager = CMHeadphoneMotionManager()
    private var cancellables = Set<AnyCancellable>()
    
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
        print("HeadphoneMotionManager 초기화됨")
        configureAudioSession()
        updateAuthorization()
        startTracking()
    }
    
    func updateAuthorization() {
        isAuthorized = CMHeadphoneMotionManager.authorizationStatus() == .authorized
        print("권한 상태: \(isAuthorized ? "허가됨" : "허가되지 않음")")
    }
    
    func configureAudioSession() {
        do {
            // 공유 오디오 세션 인스턴스를 가져온다, 모든 iOS 관련 작업이 이 인스턴스에서 관리됨
            // 오디오 세션은 시스템 수준에서 앱의 오디오 동작을 정의하고, 앱매대 독립적으로 설정 가능
            let audioSession = AVAudioSession.sharedInstance()

            // 다른 앱과 조화롭게 작동하도록 오디오 세션 카테고리 설정
            try audioSession.setCategory(
                // 소리가 없는 경우 다른 앱 방해 안 함(Youtube와 같은 오디오를 방해하지 않도록 설계), 모션 감지 앱에 적합
                .ambient,
                options: [.mixWithOthers]  // 다른 앱과 동시 실행 허용(음악, 동영상 앱과 자원을 공유 가능)
            )

            // 오디오 세션 활성화
            try audioSession.setActive(true)
            print("오디오 세션 활성화 완료")
        } catch {
            print("오디오 세션 설정 실패: \(error.localizedDescription)")
        }
    }

    
//    func configureAudioSession() {
//        do {
//            let audioSession = AVAudioSession.sharedInstance()
//            // 오디오 세션 카테고리 설정
//            try audioSession.setCategory(.playAndRecord, options: [.mixWithOthers])
//            // 오디오 세션 활성화
//            try audioSession.setActive(true)
//            print("오디오 세션 활성화 완료")
//        } catch {
//            print("오디오 세션 설정 실패: \(error.localizedDescription)")
//        }
//    }

    
    func startTracking() {
        guard headphoneManager.isDeviceMotionAvailable else { return }
        if isTracking { return }
        
        headphoneManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            
            let newPitch = motion.attitude.pitch
            let newRoll = motion.attitude.roll
            let newYaw = motion.attitude.yaw
            
            DispatchQueue.main.async {
                Just((newPitch, newRoll, newYaw))
                    .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
                    .sink { [weak self] pitch, roll, yaw in
                        self?.pitch = pitch
                        self?.roll = roll
                        self?.yaw = yaw
                    }
                    .store(in: &self.cancellables)
            }
        }
        isTracking = true
    }

    func stopTracking() {
        print("모션 데이터 업데이트 중지")
        headphoneManager.stopDeviceMotionUpdates()
        isTracking = false
    }
    
    func calibrate() {
        print("캘리브레이션 시작")
        if let motion = headphoneManager.deviceMotion {
            calibrationPitch = motion.attitude.pitch
            calibrationRoll = motion.attitude.roll
            calibrationYaw = motion.attitude.yaw
            print("캘리브레이션 완료: Pitch: \(calibrationPitch), Roll: \(calibrationRoll), Yaw: \(calibrationYaw)")
        } else {
            print("캘리브레이션 중 모션 데이터를 사용할 수 없음")
        }
    }
    
    func startMonitoring() {
        monitoringTimer = remainTime * 60
        isMonitoring = true
        // print("모니터링 시작: \(remainTime)분")
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.monitoringTimer > 0 {
                self.monitoringTimer -= 1
                let forwardHeadThreshold: Double = -0.4
                self.isAlerting = self.pitch < forwardHeadThreshold
                if self.isAlerting {
                    //print("경고: 바른 자세를 유지해주세요.")
                    scheduleNotification()
                }
            } else {
                self.stopMonitoring()
            }
        }
        
        // 백그라운드에서도 타이머 동작 가능하도록 처리
        DispatchQueue.global(qos: .background).async {
            RunLoop.current.add(self.timer!, forMode: .common)
            RunLoop.current.run()
        }
    }
    
    func stopMonitoring() {
        print("모니터링 중지")
        timer?.invalidate()
        isMonitoring = false
    }
    
    func startCalibration() {
        isCalibrating = true
        calibrationTimer = 5
        print("캘리브레이션 타이머 시작")
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.calibrationTimer > 1 {
                self.calibrationTimer -= 1
                // print("캘리브레이션 남은 시간: \(self.calibrationTimer)")
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
        NavigationStack {
            ZStack {
                // 배경색
                Color.gray1
                    .edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
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
                                .background(
                                    Circle()
                                        .fill(Color.white) // 흰색 배경 원
                                        .frame(width: 97, height: 97) // 흰색 배경 크기를 줄이기 위해 원 크기 조정
                                )
                                .frame(width: 100, height: 100)
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
                                .frame(width: 65, height: 65)
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
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // 자세 교정 뷰
                    PostureSetupView()
                    
                    Spacer()
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
            HStack {
                Text("사용방법")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.leading, 10)
                    
                NavigationLink(destination: HelpView()) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                Spacer()
                    
            }
            RectViewH(height: 400, color: .white)
                .overlay {
                    VStack {
                        Text("에어팟이 연결되면 모션을 감지할 수 있어요!")
                            .font(.system(size: 20, weight: .bold))
                            //.padding(.top, 10)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.mainorange, Color.maincolor]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 150, height: 200)
                            .rotation3DEffect(
                                .radians(motionManager.pitch),
                                axis: (x: 1, y: 0, z: 0)
                            )

                            .rotation3DEffect(
                                .radians(motionManager.roll),
                                axis: (x: 0, y: 0, z: 1)
                            )
                            .animation(.easeOut(duration: 0.2), value: motionManager.pitch)
                            .animation(.easeOut(duration: 0.2), value: motionManager.roll)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                     
                        
                        VStack(spacing: 10) {
                            Text("앞뒤 기울기: \(motionManager.pitch >= 0 ? " " : "")\(motionManager.pitch, specifier: "%.2f")")
                            Text("좌우 기울기: \(motionManager.roll >= 0 ? " " : "")\(motionManager.roll, specifier: "%.2f")")
                            Text("좌우 회전각: \(motionManager.yaw >= 0 ? " " : "")\(motionManager.yaw, specifier: "%.2f")")
                        }
                        //.font(.system(.body, design: .monospaced))
                        .font(.system(size: 13, design: .monospaced))
                    }
                }

           
            // 자세 상태 메시지
            if motionManager.isMonitoring {
                Text(motionManager.isAlerting ? "자세가 틀어졌습니다!" : "바른 자세 유지 중입니다.")
                    .foregroundColor(motionManager.isAlerting ? .red : .green)
                    .font(.headline)
            }
            
            HStack {
                Text("모니터링 시간 (분):")
                Picker("", selection: $motionManager.remainTime) {
                    ForEach(Array(stride(from: 5, through: 60, by: 5)), id: \.self) { time in
                        Text("\(time)분")
                            .tag(time)
                            
                    }
                }
                .accentColor(.maincolor) // 선택 항목 색상을 커스터마이징
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
                                motionManager.isCalibrating || !bluetoothManager.isAirPodsConnected ? Color.gray : Color.maincolor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(
                motionManager.isCalibrating
                || (!bluetoothManager.isAirPodsConnected && !motionManager.isMonitoring)
            ) // 모니터링 중일 때는 버튼 활성화
        }
    }
}

struct PostureView_Previews: PreviewProvider {
    static var previews: some View {
        PostureView()
            .environmentObject(BluetoothManager())
            .environmentObject(HeadphoneMotionManager())
    }
}



struct TimeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.white : Color.black)    // 텍스트 색상
            .padding()                  // 내부 여백
            .frame(maxWidth: .infinity) // 버튼 넓이 설정
            .background(
                configuration.isPressed ? Color.gray : Color.maincolor // 누를 때 색상 변경
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 2) // 테두리
            )
            .clipShape(RoundedRectangle(cornerRadius: 10)) // 둥근 모양
            //.padding() // 외부 여백
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed) // 애니메이션 추가
    }
}


func scheduleNotification() {
    let content = UNMutableNotificationContent()
    content.title = "자세 교정"
    content.body = "자세를 바르게 해주세요"
    content.sound = .default
    
    // 트리거 시간 설정(0초 후)
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    
    // 요청 생성
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    
    // 알림 등록
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("알림 등록 실패: \(error.localizedDescription)")
        } else {
            //print("일정 등록 성공")
        }
    }
}

struct HelpView: View {
    var body: some View {
        VStack {
            Text("Help View")
        }
    }
}
