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
    let latitude: Double    // 위도
    let longitude: Double   // 경도
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
    private let apiKey = "f755f389dc23ec846d0a0d6c5f294536" // API 키
    private init() {} // private 생성자
    
    // MARK: -  특정 위치에서 반경 내의 약국 정보를 가져오는 비동기 함수
    func getNearbyPharmacies(latitude: Double, longitude: Double, radius: Int = 1000) async -> Result<[Pharmacy], APIError> {
        let urlString = "https://dapi.kakao.com/v2/local/search/category.json?category_group_code=PM9&x=\(longitude)&y=\(latitude)&radius=\(radius)"
        
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
    
    // 두 위치 간 거리 계산 함수
//    func distance(from location1: CLLocation, to location2: CLLocation) -> CLLocationDistance {
//        return location1.distance(from: location2)
//    }
}


/*
// MARK: - PharmacyXMLParser 내부에서 호출되며, XML 응답 데이터를 Pharmacy 구조체에 매핑하는 데 사용됩니다. 단독으로는 API 요청을 수행하지 않으며, 단순히 데이터를 파싱하는 역할에 집중합니다.
//  XML 데이터를 Pharmacy 구조체와 매핑하는 역할
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


// MARK: - PharmacyManager: PharmacyService와 비슷하게 API 호출을 관리하는 역할을 하며, 약국의 기본 정보와 추가 정보를 비동기적으로 요청합니다.
class PharmacyManager {
    static let shared = PharmacyManager()
    private init() {}

    // 데이터를 요청하고, XML 데이터로 응답을 받습니다.
    func getPharmacyInfo_async_(q0: String, q1: String, pageNo: String, numOfRows: String, qn: String) async -> Pharmacy? {
        let baseURL = "https://apis.data.go.kr/B552657/ErmctInsttInfoInqireService/getParmacyListInfoInqire"
        let serviceKey = "vYvbOXShpiN13vBxmVUlC0kkxVrD%2B9V3EF7O41ExML40kZenS8KX1KYHEJcXpXhmtUm3WVdxnUWsGmDMjMQRBw%3D%3D"
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
            let parser = XMLParser(data: data)
            let xmlParserDelegate = PharmacyXMLParser()
            parser.delegate = xmlParserDelegate

            if parser.parse(), let parsedPharmacy = xmlParserDelegate.getParsedPharmacies().first {
                return parsedPharmacy
            } else {
                print("Failed to parse XML.")
                return nil
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 데이터를 요청하고, XML 데이터로 응답을 받습니다.
    func getPharmacyInfo_async(q0: String, q1: String, pageNo: String, numOfRows: String, qn: String) async -> Pharmacy? {
        let baseURL = "https://apis.data.go.kr/B552657/ErmctInsttInfoInqireService/getParmacyListInfoInqire"
        let serviceKey = "vYvbOXShpiN13vBxmVUlC0kkxVrD%2B9V3EF7O41ExML40kZenS8KX1KYHEJcXpXhmtUm3WVdxnUWsGmDMjMQRBw%3D%3D"
        let qt = "1"
        let ord = "NAME"

        guard let encodedQn = qn.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedQ0 = q0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedQ1 = q1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode URL parameters.")
            return nil
        }

        let urlString = "\(baseURL)?serviceKey=\(serviceKey)&QT=\(qt)&QN=\(encodedQn)&ORD=\(ord)&pageNo=\(pageNo)&numOfRows=\(numOfRows)&Q0=\(encodedQ0)&Q1=\(encodedQ1)"
        
        print("Request URL: \(urlString)") // 요청 URL 출력

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print("Received data size: \(data.count) bytes") // 데이터 크기 출력
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status Code: \(httpResponse.statusCode)") // HTTP 응답 코드 출력
            }

            let parser = XMLParser(data: data)
            let xmlParserDelegate = PharmacyXMLParser()
            parser.delegate = xmlParserDelegate

            if parser.parse(), let parsedPharmacy = xmlParserDelegate.getParsedPharmacies().first {
                print("Parsed pharmacy: \(parsedPharmacy.name)") // 파싱된 약국 이름 출력
                return parsedPharmacy
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


*/
// MARK: - PharmacyXMLParser
// MARK: - PharmacyXMLParser
class PharmacyXMLParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentPharmacy = Pharmacy(name: "", latitude: 0.0, longitude: 0.0, address: "", city: [], roadAddress: "", phone: "")
    private var pharmacies: [Pharmacy] = []
    
    // XML 시작 태그를 만났을 때 호출되는 메서드
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
    }
    
    // XML 태그 내의 값을 발견했을 때 호출되는 메서드
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return }
        
        // 디버깅: 현재 요소와 값을 출력
        switch currentElement {
        case "dutyName":
            currentPharmacy.name += trimmedString
        case "dutyAddr":
            currentPharmacy.address += trimmedString
        case "dutyTel1": // 전화번호 태그 처리
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
    
    // XML 종료 태그를 만났을 때 호출되는 메서드
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            pharmacies.append(currentPharmacy)
            currentPharmacy = Pharmacy(name: "", latitude: 0.0, longitude: 0.0, address: "", city: [], roadAddress: "", phone: "")
        }
    }
    
    // 파싱된 약국 정보를 반환하는 메서드
    func getParsedPharmacies() -> [Pharmacy] {
        return pharmacies
    }
}


// MARK: - PharmacyManager
class PharmacyManager {
    static let shared = PharmacyManager()
    private init() {}
    func getPharmacyInfo_async(q0: String, q1: String, pageNo: String, numOfRows: String, qn: String) async -> Pharmacy? {
            let baseURL = "https://apis.data.go.kr/B552657/ErmctInsttInfoInqireService/getParmacyListInfoInqire"
            let serviceKey = "vYvbOXShpiN13vBxmVUlC0kkxVrD%2B9V3EF7O41ExML40kZenS8KX1KYHEJcXpXhmtUm3WVdxnUWsGmDMjMQRBw%3D%3D"
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
                    print("Failed to parse XML or no pharmacies found.")
                    return nil
                }
            } catch {
                print("Error: \(error.localizedDescription)")
                return nil
            }
        }

    func getPharmacyInfo_async_(q0: String, q1: String, pageNo: String, numOfRows: String, qn: String) async -> Pharmacy? {
        let baseURL = "https://apis.data.go.kr/B552657/ErmctInsttInfoInqireService/getParmacyListInfoInqire"
        let serviceKey = "vYvbOXShpiN13vBxmVUlC0kkxVrD%2B9V3EF7O41ExML40kZenS8KX1KYHEJcXpXhmtUm3WVdxnUWsGmDMjMQRBw%3D%3D"
        let qt = "1"
        let ord = "NAME"

        guard let encodedQn = qn.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedQ0 = q0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedQ1 = q1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode URL parameters.")
            return nil
        }

        let urlString = "\(baseURL)?serviceKey=\(serviceKey)&QT=\(qt)&QN=\(encodedQn)&ORD=\(ord)&pageNo=\(pageNo)&numOfRows=\(numOfRows)&Q0=\(encodedQ0)&Q1=\(encodedQ1)"
        
        print("Request URL: \(urlString)") // 요청 URL 출력

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print("Received data size: \(data.count) bytes") // 데이터 크기 출력
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status Code: \(httpResponse.statusCode)") // HTTP 응답 코드 출력
            }

            let parser = XMLParser(data: data)
            let xmlParserDelegate = PharmacyXMLParser()
            parser.delegate = xmlParserDelegate

            if parser.parse(), let parsedPharmacy = xmlParserDelegate.getParsedPharmacies().first {
                print("Parsed pharmacy: \(parsedPharmacy.name)") // 파싱된 약국 이름 출력
                return parsedPharmacy
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
    if let pharmacy = await PharmacyManager.shared.getPharmacyInfo_async_(q0: q0, q1: q1, pageNo: pageNo, numOfRows: numOfRows, qn: qn) {
        print("약국 이름: \(pharmacy.name)")
        print("주소: \(pharmacy.address)")
        print("전화번호: \(pharmacy.phone)")
        print("위도: \(pharmacy.latitude), 경도: \(pharmacy.longitude)")
        print("운영 시간: \(pharmacy.operatingHours)")
    } else {
        print("약국 정보를 가져오는 데 실패했습니다.")
    }
}


//    .onAppear {
//        Task {
//            await testFetchPharmacyInfo()
//        }
//    }


func timeStringToDate(_ timeString: String) -> Date? {
    let timeComponents = timeString.components(separatedBy: ":")
    guard timeComponents.count == 2,
          let hour = Int(timeComponents[0]),
          let minute = Int(timeComponents[1]) else {
        print("잘못된 시간 형식: \(timeString)")
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
    guard let startDate = timeStringToDate(startTime),
          let endDate = timeStringToDate(endTime) else {
        return false
    }
    
    //print("현재 시간: \(currentTime), 시작 시간: \(startDate), 종료 시간: \(endDate)")
    
    // 영업 종료 시간이 자정을 넘어가는 경우 처리
    if endDate < startDate {
        // 현재 시간이 영업 시작보다 이후이거나, 자정을 넘은 시간을 처리
        return currentTime >= startDate || currentTime <= endDate
    } else {
        // 일반적인 경우, 시작 시간과 종료 시간 사이에 있는지 확인
        return currentTime >= startDate && currentTime <= endDate
    }
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
