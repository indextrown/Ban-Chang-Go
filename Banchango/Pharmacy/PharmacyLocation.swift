//
//  PharmacyLocation.swift
//  Banchango
//
//  Created by 김동현 on 11/4/24.
//

import Foundation

// Codable: Json에서 객체로 변환(디코딩) 혹은 반대로(인코딩) 역할
// CodingKeys: Json 키와 Swift 변수명을 매핑할 수 있게 해주는 열거형


// MARK: - 약국 정보를 표현하는 Model
struct Pharmacy: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String        // 약국이름
    var latitude: Double    // 위도
    var longitude: Double   // 경도
    var address: String     // 주소
    let city: [String]      // [시, 군]
    let roadAddress: String // 도로명 주소
    var phone: String       // 전화번호
    var operatingHours: [String:String] = [:]
    var isOpen: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case name = "place_name"
        case latitude = "y"
        case longitude = "x"
        case address = "address_name"
        case roadAddress = "road_address_name"
        case phone = "phone"
    }
    
    // MARK: - Json에서 값을 추출하여 구조체의 각 속성에 할당
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        // 문자열 좌표를 Double로 변환
        latitude = Double(try container.decode(String.self, forKey: .latitude)) ?? 0.0
        longitude = Double(try container.decode(String.self, forKey: .longitude)) ?? 0.0
        
        address = try container.decode(String.self, forKey: .address)
        roadAddress = try container.decode(String.self, forKey: .roadAddress)
        phone = try container.decode(String.self, forKey: .phone)
        
        // 주소에서 시, 군 정보 추출
        let addressComponents = address.split(separator: " ")
        city = addressComponents.prefix(2).map { String($0) }
    }
    
    // Pharmacy 객체를 XML이나 JSON 파싱 과정 없이 직접 코드 내에서 생성할 수 있도록 지원
    init(name: String, latitude: Double, longitude: Double, address: String, city: [String], roadAddress: String, phone: String, operatingHours: [String: String] = [:]) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
        self.roadAddress = roadAddress
        self.phone = phone
        self.operatingHours = operatingHours
    }
    
}

// MARK: - API 호출 시 발생할 수 있는 오류 정의. 에러타입을 명확히 구분하여 오류 발생 시 구체적인 에러 유형 전달 가능
enum APIError: Error {
    case invalidURL
    case requestFailed
    case noData
    case decodingError
}

// MARK: - API응답 형식에 맞춘 모델, 여러 Pharmacy 객체를 포함하는 documennts 배열을 정의( JSON 응답 구조체 정의)
// MARK: - Api에서 받아온 전체 응답을 처리하기 위한 용도
struct PharmacyResponse: Codable {
    let documents: [Pharmacy]
}

// MARK: - 카카오API를 통해 특정 위치 주변의 약국 정보를 가져오는 역할을 하는 싱글톤 클래스
class PharmacyService {
    static let shared = PharmacyService() // 싱글톤 인스턴스
    private let apiKey = Bundle.main.infoDictionary?["PHARMACY_SERVICE_API_KEY"] ?? ""
    private init() {} // private 생성자
    
    // MARK: -  특정 위치에서 반경 내의 약국 정보를 가져오는 비동기 함수
    func getNearbyPharmacies(latitude: Double, longitude: Double, radius: Int = 1000) async -> Result<[Pharmacy], APIError> {
        
        let urlSecondString = Bundle.main.infoDictionary?["PHARMACY_SERVICE_URL"] as? String ?? ""
        
        let urlString = "https://\(urlSecondString)&x=\(longitude)&y=\(latitude)&radius=\(radius)"
        
        
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let pharmacyResponse = try JSONDecoder().decode(PharmacyResponse.self, from: data)
            return .success(pharmacyResponse.documents)
        } catch {
            if (error as? URLError)?.code == .notConnectedToInternet {
                return .failure(.requestFailed)
            }
            return .failure(.decodingError)
        }
    }
}

// MARK: - PharmacyXMLParser
class PharmacyXMLParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentPharmacy = Pharmacy(name: "", latitude: 0.0, longitude: 0.0, address: "", city: [], roadAddress: "", phone: "")
    private var pharmacies: [Pharmacy] = []
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return }
        
        switch currentElement {
        case "dutyName":
            currentPharmacy.name += trimmedString
        case "dutyAddr":
            currentPharmacy.address += trimmedString
        case "wgs84Lat": // 위도 처리
            if let latitude = Double(trimmedString) {
                currentPharmacy.latitude = latitude
            }
        case "wgs84Lon": // 경도 처리
            if let longitude = Double(trimmedString) {
                currentPharmacy.longitude = longitude
            }
        case "dutyTel1":
            currentPharmacy.phone += trimmedString
        case "dutyTime1s":
            currentPharmacy.operatingHours["mon_s"] = trimmedString
        case "dutyTime1c":
            currentPharmacy.operatingHours["mon_e"] = trimmedString
        case "dutyTime2s":
            currentPharmacy.operatingHours["tue_s"] = trimmedString
        case "dutyTime2c":
            currentPharmacy.operatingHours["tue_e"] = trimmedString
        case "dutyTime3s":
            currentPharmacy.operatingHours["wed_s"] = trimmedString
        case "dutyTime3c":
            currentPharmacy.operatingHours["wed_e"] = trimmedString
        case "dutyTime4s":
            currentPharmacy.operatingHours["thu_s"] = trimmedString
        case "dutyTime4c":
            currentPharmacy.operatingHours["thu_e"] = trimmedString
        case "dutyTime5s":
            currentPharmacy.operatingHours["fri_s"] = trimmedString
        case "dutyTime5c":
            currentPharmacy.operatingHours["fri_e"] = trimmedString
        case "dutyTime6s":
            currentPharmacy.operatingHours["sat_s"] = trimmedString
        case "dutyTime6c":
            currentPharmacy.operatingHours["sat_e"] = trimmedString
        case "dutyTime7s":
            currentPharmacy.operatingHours["sun_s"] = trimmedString
        case "dutyTime7c":
            currentPharmacy.operatingHours["sun_e"] = trimmedString
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            pharmacies.append(currentPharmacy)
            currentPharmacy = Pharmacy(name: "", latitude: 0.0, longitude: 0.0, address: "", city: [], roadAddress: "", phone: "")
        }
    }
    
    func getParsedPharmacies() -> [Pharmacy] {
        return pharmacies
    }
}



// MARK: - PharmacyManager
class PharmacyManager {
    static let shared = PharmacyManager()
    private init() {}
    func getPharmacyInfo_async(q0: String, q1: String, pageNo: String, numOfRows: String, qn: String) async -> Pharmacy? {
            
            let baseSecondURL = Bundle.main.infoDictionary?["PHARMACY_MANAGER_URL"] as? String ?? ""
            let baseURL = "https://" + baseSecondURL
        
            let serviceKey = Bundle.main.infoDictionary?["PHARMACY_MANAGER_API_KEY"] ?? ""
            let qt = "1"
            let ord = "NAME"

            // 올바르게 인코딩된 값 생성
            guard let encodedQn = qn.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedQ0 = q0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedQ1 = q1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                print("Failed to encode URL parameters.")
                return nil
            }

            let urlString = "\(baseURL)?serviceKey=\(serviceKey)&QT=\(qt)&QN=\(encodedQn)&ORD=\(ord)&pageNo=\(pageNo)&numOfRows=\(numOfRows)&Q0=\(encodedQ0)&Q1=\(encodedQ1)"
            
            //print("Request URL: \(urlString)") // 요청 URL 출력

            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return nil
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
//                let (data, response) = try await URLSession.shared.data(from: url)
                //print("Received data size: \(data.count) bytes") // 데이터 크기 출력
                
//                if let httpResponse = response as? HTTPURLResponse {
//                    //print("HTTP Response Status Code: \(httpResponse.statusCode)") // HTTP 응답 코드 출력
//                }

                let parser = XMLParser(data: data)
                let xmlParserDelegate = PharmacyXMLParser()
                parser.delegate = xmlParserDelegate

                if parser.parse(), let parsedPharmacy = xmlParserDelegate.getParsedPharmacies().first {
                    //print("Parsed pharmacy: \(parsedPharmacy.name)") // 파싱된 약국 이름 출력
                    return parsedPharmacy
                } else {
                    //print("Failed to parse XML or no pharmacies found.")
                    return nil
                }
            } catch {
                print("Error: \(error.localizedDescription)")
                return nil
            }
        }
    
    func getPharmaciesInfo_async(q0: String, q1: String, pageNo: String, numOfRows: String, qn: String) async -> [Pharmacy]? {
        let baseSecondURL = Bundle.main.infoDictionary?["PHARMACY_MANAGER_URL"] as? String ?? ""
        let baseURL = "https://" + baseSecondURL
        let serviceKey = Bundle.main.infoDictionary?["PHARMACY_MANAGER_API_KEY"] ?? ""
        let qt = "1"
        let ord = "NAME"

        guard let encodedQn = qn.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedQ0 = q0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedQ1 = q1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode URL parameters.")
            return nil
        }

        let urlString = "\(baseURL)?serviceKey=\(serviceKey)&QT=\(qt)&QN=\(encodedQn)&ORD=\(ord)&pageNo=\(pageNo)&numOfRows=\(numOfRows)&Q0=\(encodedQ0)&Q1=\(encodedQ1)"

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            // 디버깅: API로부터 받은 XML 데이터 출력

            let parser = XMLParser(data: data)
            let xmlParserDelegate = PharmacyXMLParser()
            parser.delegate = xmlParserDelegate

            if parser.parse() {
                let parsedPharmacies = xmlParserDelegate.getParsedPharmacies()
                //print("Parsed Pharmacies: \(parsedPharmacies)")
                return parsedPharmacies
            } else {
                print("Failed to parse XML or no pharmacies found.")
                return nil
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }

    }

}



func testFetchPharmacyInfo() async {
    // 호출할 파라미터 설정
    let q0 = "부산" // 시도
    let q1 = "남구" // 시군구
    let pageNo = "1" // 페이지 번호
    let numOfRows = "10" // 한 페이지에 보여줄 약국 수
    let qn = "한마음약국" // 검색할 약국 이름

    // PharmacyManager 인스턴스에서 함수 호출
    if let pharmacy = await PharmacyManager.shared.getPharmacyInfo_async(q0: q0, q1: q1, pageNo: pageNo, numOfRows: numOfRows, qn: qn) {
        print("약국 이름: \(pharmacy.name)")
        print("주소: \(pharmacy.address)")
        print("전화번호: \(pharmacy.phone)")
        print("위도: \(pharmacy.latitude), 경도: \(pharmacy.longitude)")
        print("운영 시간: \(pharmacy.operatingHours)")
    } else {
        print("약국 정보를 가져오는 데 실패했습니다.")
    }
}

func timeStringToDate(_ timeString: String) -> Date? {
    let timeComponents = timeString.components(separatedBy: ":")
    guard timeComponents.count == 2,
          let hour = Int(timeComponents[0]),
          let minute = Int(timeComponents[1]) else {
        return nil
    }
    
    // 만약 시간이 24시를 넘는다면, 이를 다음날 시간으로 변환
    var adjustedHour = hour
    if hour >= 24 {
        adjustedHour = hour - 24
    }

    // 현재 날짜를 가져옴
    let today = Date()
    let calendar = Calendar.current

    // 날짜 컴포넌트를 설정하고, 시간이 24시를 넘는 경우 하루를 더해줌
    var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
    if hour >= 24 {
        dateComponents.day! += 1
    }
    dateComponents.hour = adjustedHour
    dateComponents.minute = minute

    let date = calendar.date(from: dateComponents)
    //print("변환된 시간: \(timeString) -> \(String(describing: date))") // 디버깅용
    return date
}
// 현재 시간과 영업 시간을 비교하는 함수

func isOpenNow(startTime: String, endTime: String) -> Bool {
    let currentTime = Date() // 현재 시간

    // 시작 시간과 종료 시간을 변환
    guard let startDate = timeStringToDate(startTime),
          let adjustedEndTime = adjustEndTime(endTime),
          let endDate = timeStringToDate(adjustedEndTime) else {
        return false
    }

    // 종료 시간이 새벽으로 넘어가는 경우: 두 조건을 모두 확인
    if endTime > "24:00" {
        return currentTime >= startDate || currentTime <= endDate
    } else {
        // 일반적인 경우
        return currentTime >= startDate && currentTime <= endDate
    }
}

// 종료 시간을 조정하는 함수
func adjustEndTime(_ endTime: String) -> String? {
    let timeComponents = endTime.components(separatedBy: ":")
    guard timeComponents.count == 2,
          let hour = Int(timeComponents[0]),
          let minute = Int(timeComponents[1]) else {
        return nil
    }

    // 시간이 24시를 넘는 경우 처리
    if hour >= 24 {
        let adjustedHour = hour - 24
        return String(format: "%02d:%02d", adjustedHour, minute)
    }

    return endTime // 24시 이하인 경우 그대로 반환
}

// 요일 확인
func getDay(from date: Date) -> String {
    let dateFormatter = DateFormatter()
    
    dateFormatter.locale = Locale(identifier: "ko_KR") // 한국어로 요일
    dateFormatter.dateFormat = "EEEE" // 요일을 '월요일', '화요일' 등의 형태로 표시
    let day = dateFormatter.string(from: date)
    return day
}

// 시간을 "1100" -> "11:00" 형식으로 변환
func formatTime(_ time: String) -> String {
    guard time.count == 4 else { return time }
    let hour = time.prefix(2)
    let minute = time.suffix(2)
    return "\(hour):\(minute)"
}

func operatingHours(for day: String, operatingHours: [String: String]) -> (start: String, end: String) {
        switch day {
        case "월요일":
            return (formatTime(operatingHours["mon_s"] ?? "정보 없음"), formatTime(operatingHours["mon_e"] ?? "정보 없음"))
        case "화요일":
            return (formatTime(operatingHours["tue_s"] ?? "정보 없음"), formatTime(operatingHours["tue_e"] ?? "정보 없음"))
        case "수요일":
            return (formatTime(operatingHours["wed_s"] ?? "정보 없음"), formatTime(operatingHours["wed_e"] ?? "정보 없음"))
        case "목요일":
            return (formatTime(operatingHours["thu_s"] ?? "정보 없음"), formatTime(operatingHours["thu_e"] ?? "정보 없음"))
        case "금요일":
            return (formatTime(operatingHours["fri_s"] ?? "정보 없음"), formatTime(operatingHours["fri_e"] ?? "정보 없음"))
        case "토요일":
            return (formatTime(operatingHours["sat_s"] ?? "정보 없음"), formatTime(operatingHours["sat_e"] ?? "정보 없음"))
        case "일요일":
            return (formatTime(operatingHours["sun_s"] ?? "정보 없음"), formatTime(operatingHours["sun_e"] ?? "정보 없음"))
        default:
            return ("정보 없음", "정보 없음")
        }
    }
