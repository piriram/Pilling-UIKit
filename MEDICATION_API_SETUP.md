# 약물 정보 API 연동 설정 가이드

## 완료된 작업

### 1. 아키텍처 레이어
- DTO 모델: `MedicationDTO.swift` (API 응답 구조)
- Domain Model: `MedicationInfo.swift` (비즈니스 로직용 모델)
- Error 타입: `MedicationAPIError.swift` (에러 핸들링)
- API Service: `MedicationAPIService.swift` (네트워크 레이어)
- Repository Protocol: `MedicationRepositoryProtocol.swift`
- Repository 구현: `MedicationRepository.swift` (3단계 데이터 전략)

### 2. 데이터 모델 확장
- `PillInfo` 모델 확장: 약물 상세 정보 필드 추가 (제조사, 성분, 복용법, 품목코드)
- `DosageParser`: 용법용량 텍스트에서 복용일/휴약일 파싱

### 3. UI 컴포넌트
- `MedicationSearchTableViewCell`: 검색 결과 셀

### 4. 설정 파일
- `Config.xcconfig.template`: API 키 설정 템플릿
- `.gitignore.medication`: API 키 보안 설정 가이드

## 남은 작업 (UI 통합)

### 1. PillTypeBottomSheetViewController 수정
현재 수동 입력 방식을 다음과 같이 개선 필요:

```swift
// TODO: MedicationRepository 주입
private let medicationRepository: MedicationRepositoryProtocol

// TODO: 검색 결과 TableView 추가
private let searchResultsTableView: UITableView

// TODO: TextField 텍스트 변경 이벤트 바인딩
pillNameTextField.rx.text
    .orEmpty
    .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
    .distinctUntilChanged()
    .flatMapLatest { keyword -> Observable<[MedicationInfo]> in
        guard !keyword.isEmpty else {
            return Observable.just([])
        }
        return self.medicationRepository.searchMedication(keyword: keyword)
    }
    .bind(to: searchResultsTableView.rx.items(
        cellIdentifier: MedicationSearchTableViewCell.identifier,
        cellType: MedicationSearchTableViewCell.self
    )) { index, medication, cell in
        cell.configure(with: medication)
    }
    .disposed(by: disposeBag)

// TODO: TableView 셀 선택 이벤트
searchResultsTableView.rx.modelSelected(MedicationInfo.self)
    .subscribe(onNext: { [weak self] medication in
        let pillInfo = medication.toPillInfo()
        self?.pillNameTextField.text = pillInfo.name
        self?.selectedTakingDays = pillInfo.takingDays
        self?.selectedBreakDays = pillInfo.breakDays
        self?.selectedTakingDaysRelay.accept(pillInfo.takingDays)
        self?.selectedBreakDaysRelay.accept(pillInfo.breakDays)
        self?.takingDaysButton.setTitle("\\(pillInfo.takingDays)일", for: .normal)
        self?.breakDaysButton.setTitle("\\(pillInfo.breakDays)일", for: .normal)
        self?.searchResultsTableView.isHidden = true
    })
    .disposed(by: disposeBag)
```

### 2. DIContainer 수정
```swift
// TODO: MedicationRepository 싱글톤 추가
func makeMedicationRepository() -> MedicationRepositoryProtocol {
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "MFDS_API_KEY") as? String ?? ""
    let apiService = MedicationAPIService(apiKey: apiKey)
    return MedicationRepository(apiService: apiService)
}
```

### 3. Info.plist 설정
```xml
<key>MFDS_API_KEY</key>
<string>$(MFDS_API_KEY)</string>
```

## API 키 발급 방법

1. [공공데이터포털](https://www.data.go.kr) 회원가입 및 로그인
2. [의약품 제품 허가정보 API](https://www.data.go.kr/data/15095677/openapi.do) 페이지 접속
3. "활용 신청" 버튼 클릭
4. 승인 대기 (보통 1-2시간)
5. 승인 후 발급된 서비스 키 복사
6. `Config.xcconfig.template`을 `Config.xcconfig`로 복사
7. `YOUR_API_KEY_HERE`를 실제 API 키로 교체

## 데이터 흐름

1. 사용자가 약 이름 입력 시작
2. debounce(300ms) 후 Repository.searchMedication() 호출
3. Repository가 캐시 확인 → API 호출 → 폴백 데이터 순으로 처리
4. 검색 결과 TableView에 표시
5. 사용자가 약 선택
6. DosageParser로 복용일/휴약일 파싱
7. PillInfo 객체 생성 (상세 정보 포함)
8. ViewModel에 전달 → UserDefaults 저장

## 테스트 방법

```swift
// 1. API 호출 테스트
let apiKey = "YOUR_API_KEY"
let service = MedicationAPIService(apiKey: apiKey)
service.fetchMedications(keyword: "야즈")
    .subscribe(onNext: { medications in
        print("검색 결과: \\(medications.count)개")
    })
    .disposed(by: disposeBag)

// 2. Repository 테스트
let repository = MedicationRepository(apiService: service)
repository.searchMedication(keyword: "머시론")
    .subscribe(onNext: { medications in
        for med in medications {
            let pillInfo = med.toPillInfo()
            print("\\(pillInfo.name): \\(pillInfo.takingDays)일 복용, \\(pillInfo.breakDays)일 휴약")
        }
    })
    .disposed(by: disposeBag)
```

## 참고 자료

- [포트폴리오 작성 가이드](PORTFOLIO_PUBLIC_API.md)
- [식약처 API 문서](https://www.data.go.kr/data/15095677/openapi.do)
