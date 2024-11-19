//
//  PostureView.swift
//  Banchango
//
//  Created by 김동현 on 11/19/24.
//

import SwiftUI
import CoreBluetooth

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

struct PostureView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var isAnimating = false // 회전 애니메이션 상태
    
    var body: some View {
        VStack(spacing: 30) {
            // AirPods 상태 아이콘 및 도넛 애니메이션
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: bluetoothManager.isAirPodsConnected ? [.green, .green] : [.blue, .clear]),
                            center: .center
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 150, height: 150)
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
                    .frame(width: 100, height: 100)
                    .foregroundColor(bluetoothManager.isAirPodsConnected ? .green : .blue)
            }
            
            // 연결 상태 텍스트
            Text(bluetoothManager.isAirPodsConnected ? "AirPods가 연결되었습니다!" : "AirPods을 연결해주세요.")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(bluetoothManager.isAirPodsConnected ? .green : .red)
                .padding(.bottom, 10)
            
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
                .frame(maxWidth: .infinity)
                .background(bluetoothManager.isAirPodsConnected ? Color.green : Color.blue)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .disabled(bluetoothManager.isAirPodsConnected)
            
            Spacer()
            
            // 자세 교정 뷰
            PostureSetupView()
        }
        .padding()
        .onAppear {
            bluetoothManager.startBluetooth()
        }
    }
}


struct PostureView2: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var isAnimating = false // 회전 애니메이션 상태
    var body: some View {
        VStack {
            HStack {
                ZStack {
                    if !bluetoothManager.isAirPodsConnected
                    {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.blue, .clear]),
                                    center: .center
                                ),
                                lineWidth: 5
                            )
                            .frame(width: 150, height: 150)
                            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                            .animation(
                                isAnimating ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: isAnimating
                            )
                            .onAppear {
                                isAnimating = true
                            }
                            .onDisappear {
                                isAnimating = false
                            }
                    }
                    
                    Image("AirPods")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                }
                
                VStack(spacing: 20) {
                    if bluetoothManager.isAirPodsConnected {
                        Text("AirPods가 연결되었습니다.")
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    } else {
                        Text("AirPods을 연결해주세요.")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    }
                    
                    Button(action: {
                        bluetoothManager.startBluetooth() // 사용자가 명시적으로 요청할 때 블루투스 초기화
                    }) {
                        Text("연결")
                            .padding()
                            .background(.maincolor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            Spacer()
                .frame(height:50)
            
            PostureSetupView()
        }
        .onAppear {
            bluetoothManager.startBluetooth()
        }
        .padding()
    }
}

struct PostureView_Previews: PreviewProvider {
    static var previews: some View {
        PostureView()
            .environmentObject(BluetoothManager())
    }
}

private struct PostureSetupView: View {
    @State private var isCollectingData = false // 데이터 수집 여부
    @State private var remainingTime = 5        // 남은 시간
    @State private var message = "바른 자세를 유지하세요!"
    
    fileprivate var body: some View {
        VStack {
            Text(message)
                .font(.headline)
                .foregroundColor(isCollectingData ? .blue : .gray)
            
            RectViewH(height: 200)
                .padding()
                .background(isCollectingData ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(10)
            if isCollectingData {
                Text("\(remainingTime)초 남았습니다")
                    .font(.title)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Button(action: {
                    //startDataCollection()
                }) {
                    Text("자세 탐지 시작")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}
