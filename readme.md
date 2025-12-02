<div align=center>

# 🩹 반창고
### **가까운 약국부터, 오늘 걸음 수까지 한 번에 챙기는 건강 도우미**
반창고는 내 주변 약국 정보와 하루 걸음 수를 편하게 확인할 수 있는 **헬스 케어 보조 앱**입니다.  

</div>

<br/><br/>


<img width="1508" alt="banchango" src="https://github.com/user-attachments/assets/b8a37eea-687c-4a21-9594-5787e54783de">

# 1. 기능 소개
1. 내 주변 약국 자동 탐색 (지도 기반) 🗺️  
2. 현재 영업중/영업종료 여부 실시간 확인 ⏱️  
3. 약국 상세 정보: 전화번호·주소·운영시간 📍  
4. 검색창으로 약국 이름 빠르게 찾기 🔍  
5. 만보기 기능으로 오늘 걸음 수/칼로리 계산 🚶‍♂️🔥  

</br><br/>

# 2. 기술 스택
|library|description|
|:---:|:---:|
|**SwiftUI**| 전체 UI 구조 구성|
|**MapKit**| 지도 렌더링 및 카메라 위치 관리 |
|**CoreLocation**| GPS 기반 사용자 위치 추적 |
|**CLGeocoder**| 위도→시/군 변환 (역지오코딩) |
|**CMPedometer**| 걸음 수 추적 및 움직임 데이터 |
|**UserDefaults**| 만보기 데이터 저장 |

</br><br/>

# 3. 핵심 성과

### **1. 디바운스를 직접 구현하며 비동기 흐름과 성능 최적화를 이해한 경험**

> **문제**  
> 지도 중심 좌표가 움직일 때마다 약국 API가 호출되는 구조였기 때문에  
> 사용자가 지도를 빠르게 이동하면 불필요한 요청이 연속적으로 발생할 위험이 있었습니다.
>
> **해결**  
> 앱 개발을 처음 진행하던 시기라 Combine의 `debounce` 개념을 잘 모르던 상황이었지만,  
> 연속되는 위치 변경 이벤트를 제어할 필요성을 느껴  
> **GCD 기반의 디바운스를 직접 설계해 구현**했습니다.  
>
> 1) `cancel()`로 이전 예약 작업 취소  
> 2) 새로운 `DispatchWorkItem` 생성  
> 3) `asyncAfter`로 0.8초 뒤 실행 예약  
>
> 이 과정에서 이벤트가 다시 발생하면 이전 작업은 취소되어  
> **“마지막 이벤트만 유효하게 처리되는” 디바운스 구조**가 완성되었습니다.

```swift
func debouncefetchNearbyPharmacies(for coordinate: CLLocationCoordinate2D) {
    // 1) 기존 예약 취소
    debounceWorkItem?.cancel()

    // 2) 새 작업 생성
    debounceWorkItem = DispatchWorkItem { [weak self] in
        guard let self = self else { return }

        Task {
            let result = await PharmacyService.shared
                .getNearbyPharmacies(latitude: coordinate.latitude,
                                     longitude: coordinate.longitude)
            // ... 업데이트 로직
        }
    }

    // 3) 0.8초 뒤 실행 예약
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8,
                                  execute: debounceWorkItem!)
}
```

> **성과**  
> 🔸 지도 이동 시 API 중복 호출이 크게 줄어 부드러운 UX 확보   
> 🔸 디바운스를 직접 구현하면서 비동기 처리·이벤트 제어 흐름을 깊게 이해  
> 🔸 이후 Combine의 debounce를 학습할 때 개념이 빠르게 연결됨  
