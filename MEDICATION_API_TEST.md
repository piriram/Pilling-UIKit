# 의약품개요정보 API 테스트 가이드

## API 정보

- **API명**: 의약품개요정보(e약은요)
- **제공기관**: 식품의약품안전처
- **엔드포인트**: `https://apis.data.go.kr/1471000/DrbEasyDrugInfoService/getDrbEasyDrugList`
- **문서**: https://www.data.go.kr/data/15075057/openapi.do

## 테스트 방법

### 1. 앱 실행
```bash
# Xcode에서 실행하거나
open PillingApp.xcworkspace
```

### 2. 테스트 화면 접근
1. 앱 실행
2. 온보딩 완료
3. 약 설정 화면으로 이동
4. **화면을 4번 연속으로 탭**
5. "의약품 상세정보 API 테스트" 화면 열림

### 3. 테스트 시나리오

#### A. 예시 버튼 사용
- **머시론정 버튼** 클릭 → 자동으로 품목코드 입력
- **야즈정 버튼** 클릭 → 자동으로 품목코드 입력
- **센스데이정 버튼** 클릭 → 자동으로 품목코드 입력
- **검색** 버튼 클릭

#### B. 직접 입력
1. 품목기준코드 입력 (예: `200009522`)
2. **검색** 버튼 클릭

### 4. 확인 사항

테스트 화면에서 다음을 확인:

#### ✅ 복용 주기 파싱
```
💊 복용 주기 (파싱 결과)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
24일 복용 + 4일 휴약   (야즈정)
21일 복용 + 7일 휴약   (머시론정, 센스데이정 등)
```

#### ✅ 사용법 원본 데이터
```
📖 사용법 (원본)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
이 약은 피임 목적으로 1일 1정씩 24일간 복용...
```

#### ✅ 효능효과
```
🎯 효능효과
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
경구 피임...
```

#### ✅ 주의사항, 부작용, 보관법
API에서 제공하는 상세 정보 표시 확인

## 테스트 품목코드

| 약품명 | 품목기준코드 | 예상 결과 |
|--------|-------------|----------|
| 머시론정 | 200009522 | 21일 복용 + 7일 휴약 |
| 야즈정 | 200807400 | 24일 복용 + 4일 휴약 |
| 센스데이정 | 201706350 | 21일 복용 + 7일 휴약 |
| 야스민정 | 200801550 | 21일 복용 + 7일 휴약 |
| 멜리안정 | 200807207 | 21일 복용 + 7일 휴약 |
| 마이보라정 | 200800687 | 21일 복용 + 7일 휴약 |

## 파일 구조

```
PillingApp/
├── Infra/Network/MedicationAPI/
│   ├── MedicationDetailDTO.swift           # API 응답 DTO
│   └── MedicationDetailAPIService.swift    # API 서비스
└── Presentation/Test/
    └── MedicationDetailTestViewController.swift  # 테스트 화면
```

## 주요 기능

### 1. HTML 태그 제거
API 응답에 포함된 HTML 태그를 자동으로 제거:
```swift
<p>하루 1정씩 복용...</p> → 하루 1정씩 복용...
&nbsp; → (공백)
```

### 2. 복용 주기 자동 파싱
사용법(useMethodQesitm) 텍스트에서 복용 주기를 자동 감지:
```swift
"24일간 복용" → "24일 복용 + 4일 휴약"
"24정 복용"   → "24일 복용 + 4일 휴약"
"21일간 복용" → "21일 복용 + 7일 휴약"
"21정 복용"   → "21일 복용 + 7일 휴약"
```

## API 키 설정

### 1. API 키 발급
https://www.data.go.kr/data/15075057/openapi.do 에서 API 키 발급

### 2. Xcode에 환경변수 설정

**방법 A: Scheme 설정 (권장)**
1. Xcode에서 `Product` → `Scheme` → `Edit Scheme...`
2. `Run` → `Arguments` 탭
3. `Environment Variables` 섹션에 추가:
   - Name: `MFDS_DETAIL_API_KEY`
   - Value: `발급받은_API_키` (Encoding 버전)

**방법 B: xcconfig 파일 사용**
1. `Config.xcconfig` 파일 생성
2. 다음 추가:
   ```
   MFDS_DETAIL_API_KEY = 발급받은_API_키
   ```
3. `.gitignore`에 `Config.xcconfig` 추가

### 3. Info.plist 확인
```xml
<key>MFDS_DETAIL_API_KEY</key>
<string>$(MFDS_DETAIL_API_KEY)</string>
```

**주의**: API 키를 절대 커밋하지 마세요!

## 디버그 로그

Xcode 콘솔에서 다음 로그 확인:
```
🔍 [Detail API] Request URL: https://...
🔍 [Detail API] Response: {...}
✅ [Detail API] Success: 머시론정
```

## 트러블슈팅

### 1. API 오류 발생 시
- 품목기준코드가 정확한지 확인
- 네트워크 연결 확인
- API 키가 올바른지 확인

### 2. 파싱 결과가 "21일 복용 + 7일 휴약"로만 나올 때
- `useMethodQesitm` 필드에 "24일" 또는 "24정" 텍스트가 없는 경우
- 기본값이 21-7 주기로 설정됨

### 3. HTML 태그가 그대로 표시될 때
- `cleanHTML()` 함수 확인
- 정규표현식 패턴 확인

## 다음 단계

이 테스트가 성공하면:

1. **Repository 통합**: MedicationRepository에 상세 정보 조회 추가
2. **캐싱**: 상세 정보도 캐싱 적용
3. **UI 통합**: 약 선택 시 자동으로 복용 주기 업데이트
4. **성능 최적화**: 백그라운드 프리패치

## 브랜치 정보

- **브랜치명**: `feat/medication-detail-api-test`
- **기준 브랜치**: `feat/public-api-medication`
