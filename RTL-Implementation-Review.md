# Pilling 앱 RTL 구현 검토 보고서

## 요약

**현재 RTL 지원 수준: 4/10 (부분적 지원)**

아랍어 번역은 완료되었으나, UI 레이아웃과 방향성 처리가 불완전하여 아랍어 사용자에게 부자연스러운 경험을 제공할 가능성이 높음.

## 1. semanticContentAttribute 사용 현황

### 현재 적용된 위치 (3곳)

| 파일 | 줄 | 설정 | 용도 | 적절성 |
|-----|---|------|------|-------|
| DashboardMiddleView.swift | 114 | `.forceLeftToRight` | 진행도 표시 (1/30) | ✅ 적절 |
| StasticsViewController.swift | 35 | `.forceRightToLeft` | 기간 선택 버튼 | ✅ 적절 |
| StatisticsContentView.swift | 30 | `.forceRightToLeft` | 기간 선택 버튼 | ✅ 적절 |

### 적용이 필요한 위치

```swift
// ❌ 현재: semanticContentAttribute 미적용
let chevronButton = UIButton()
chevronButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)

// ✅ 개선: 버튼 방향 명시
chevronButton.semanticContentAttribute = .forceLeftToRight
```

**필요한 파일:**
- SettingViewController.swift (chevron 아이콘들)
- DashboardTopButtonsView.swift (상단 버튼들)
- ChartContainerView.swift (좌우 화살표)

## 2. TextAlignment 고정값 문제

### 문제가 있는 코드

```swift
// ❌ PillSettingViewController.swift:27,36
mainTitleLabel.textAlignment = .left
subtitleLabel.textAlignment = .left

// ❌ TimeSettingViewController.swift:30,39
titleLabel.textAlignment = .left
subtitleLabel.textAlignment = .left

// ❌ SettingViewController.swift:134
messageLabel.textAlignment = .right
```

### 개선 방안

```swift
// ✅ 자동 정렬 (시스템이 RTL 자동 처리)
titleLabel.textAlignment = .natural

// ✅ 또는 설정 생략 (기본값이 natural)
// titleLabel.textAlignment = .left  // 이 줄 삭제
```

### 영향받는 화면

- 약 복용 설정 화면
- 시간 설정 화면
- 통계 화면
- 설정 화면

## 3. 이미지 엣지 인셋 문제

### 심각한 문제

```swift
// ❌ StasticsViewController.swift:36
button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
```

**문제점:**
- RTL에서도 `left`/`right` 값이 그대로 적용됨
- 아이콘과 텍스트 간격이 역방향으로 보임

**해결 방법:**

```swift
// ✅ 방법 1: semanticContentAttribute 사용
button.semanticContentAttribute = .forceRightToLeft

// ✅ 방법 2: configuration 사용 (iOS 15+)
var config = UIButton.Configuration.plain()
config.imagePadding = 4
config.imagePlacement = .trailing
button.configuration = config
```

## 4. 아이콘 방향 처리

### 방향 전환이 필요한 아이콘

| 아이콘 | 현재 상태 | RTL 필요 | 개선 필요 |
|--------|---------|---------|----------|
| chevron.right | 미처리 | ✅ | 🔴 긴급 |
| chevron.left | 미처리 | ✅ | 🔴 긴급 |
| chevron.down | 부분 처리 | ❌ | ✅ 완료 |
| clock.fill | 미처리 | ❌ | - |
| pills | 미처리 | ❌ | - |

### SF Symbols RTL 지원

```swift
// ✅ iOS 13+에서 SF Symbols는 자동으로 RTL 변형 제공
let chevronImage = UIImage(systemName: "chevron.forward")
// RTL: 자동으로 왼쪽 화살표로 변경됨

// ❌ 하지만 "chevron.right"는 방향 고정
let chevronRight = UIImage(systemName: "chevron.right")
// RTL: 여전히 오른쪽 화살표
```

**권장사항:**
- `chevron.right` → `chevron.forward` 변경
- `chevron.left` → `chevron.backward` 변경

## 5. StackView 정렬 문제

### 현재 코드

```swift
// DashboardMiddleView.swift
dateInfoStackView.alignment = .leading

// RTL에서: leading은 여전히 왼쪽으로 정렬됨 (논리적으로 오른쪽이어야 함)
```

### 개선 방안

```swift
// ✅ 방법 1: .natural 사용
dateInfoStackView.alignment = .natural

// ✅ 방법 2: 명시적 처리
if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
    dateInfoStackView.alignment = .trailing
} else {
    dateInfoStackView.alignment = .leading
}
```

## 6. 레이아웃 상수 하드코딩 문제

### 문제가 있는 패턴

```swift
// ❌ DashboardMiddleView.swift:131
characterImageView.snp.makeConstraints { make in
    make.leading.equalToSuperview().inset(contentInset)
    make.width.equalTo((UIScreen.main.bounds.width - contentInset) / 2)
}
```

**문제점:**
- `leading`을 사용했지만 너비 계산이 하드코딩됨
- RTL에서도 동일한 위치에 렌더링될 가능성

**개선:**

```swift
// ✅ 양쪽 여백 일관성 유지
characterImageView.snp.makeConstraints { make in
    make.horizontalEdges.equalToSuperview().inset(contentInset)
    make.height.equalTo(150)
}
```

## 7. 아랍어 로컬라이제이션 상태

### ✅ 완료된 부분

- Info.plist에 `ar` 등록 완료
- 197개 문자열 번역 완료
- 모든 주요 화면 번역 제공

### ⚠️ 주의사항

아랍어 텍스트 특성:
- 높이가 더 높음 (발음 부호)
- 간결함 (연결성)
- 발음 부호 사용 시 수직 간격 필요

```swift
// 현재 레이블 설정
label.font = Typography.body1(.medium)

// ✅ 아랍어 고려 (10% 크기 증가)
if Locale.current.language.languageCode?.identifier == "ar" {
    label.font = Typography.body1(.medium).withSize(originalSize * 1.1)
}
```

## 8. 우선순위별 개선 과제

### 🔴 P1 (긴급 - 사용자에게 직접 보임)

#### 1. TextAlignment 수정
```swift
// 모든 .left, .right → .natural로 변경
// 파일: PillSettingViewController, TimeSettingViewController, SettingViewController
```

#### 2. imageEdgeInsets 제거
```swift
// StasticsViewController.swift:36
// UIEdgeInsets 삭제하고 semanticContentAttribute 사용
```

#### 3. chevron 아이콘 수정
```swift
// "chevron.right" → "chevron.forward"
// "chevron.left" → "chevron.backward"
```

### 🟡 P2 (중요 - 테스트 필요)

#### 1. StackView alignment
```swift
// .leading → .natural
// 파일: DashboardMiddleView, DashboardGuideView
```

#### 2. semanticContentAttribute 확대 적용
```swift
// 모든 방향성 버튼에 적용
// 파일: SettingViewController, DashboardTopButtonsView
```

#### 3. 화살표 버튼 로직 검토
```swift
// ChartContainerView의 left/right 버튼
// RTL에서는 논리적 방향이 반대
```

### 🟢 P3 (개선 - 향후)

#### 1. 아랍어 폰트 크기 조정
```swift
// 라틴 대문자와 함께 사용 시 10% 증가
```

#### 2. RTL 테스트 자동화
```swift
// UI 테스트에서 아랍어 로케일 강제 설정
```

#### 3. 레이아웃 상수 중앙화
```swift
struct LayoutConstants {
    static let horizontalMargin: CGFloat = 16
    // 모든 offset 일관성 유지
}
```

## 9. 파일별 수정 목록

### StasticsViewController.swift
- [ ] Line 35: imageEdgeInsets 제거
- [ ] Line 35: semanticContentAttribute 적용

### SettingViewController.swift
- [ ] Line 69: textAlignment .right 제거
- [ ] Line 134: textAlignment .right 제거
- [ ] chevron 아이콘들에 semanticContentAttribute 적용

### PillSettingViewController.swift
- [ ] Line 27: textAlignment .left → .natural
- [ ] Line 36: textAlignment .left → .natural

### TimeSettingViewController.swift
- [ ] Line 30: textAlignment .left → .natural
- [ ] Line 39: textAlignment .left → .natural

### DashboardMiddleView.swift
- [ ] Line 92: alignment .leading → .natural
- [ ] Line 131-132: 레이아웃 검토

### ChartContainerView.swift
- [ ] Line 42, 49: chevron.left/right → backward/forward
- [ ] 화살표 버튼 로직 RTL 대응

### DashboardTopButtonsView.swift
- [ ] Line 88-102: 버튼 배치 RTL 검토

## 10. 테스트 시나리오

### RTL 테스트 방법

1. **시뮬레이터 설정**
   ```
   Settings → General → Language & Region
   → iPhone Language → العربية (Arabic)
   ```

2. **테스트할 화면**
   - [ ] 대시보드
   - [ ] 약 복용 설정
   - [ ] 시간 설정
   - [ ] 통계 화면
   - [ ] 설정 화면

3. **확인할 항목**
   - [ ] 텍스트 오른쪽 정렬
   - [ ] 아이콘 방향 반전
   - [ ] 버튼 순서 반전
   - [ ] 스택뷰 정렬
   - [ ] 캘린더 방향

### 예상 문제 시뮬레이션

#### 현재 (영어)
```
┌────────────────────────┐
│ [⚙️] [ℹ️]    설정      │
│                        │
│ 약 복용 설정           │
│ ─────────────► [>]     │
└────────────────────────┘
```

#### 예상 (아랍어 - 현재 코드)
```
┌────────────────────────┐
│ [⚙️] [ℹ️]    الإعدادات │  ← 아이콘이 왼쪽에 고정
│                        │
│ إعدادات الحبة          │  ← 왼쪽 정렬 (틀림)
│ ─────────────► [>]     │  ← 화살표 방향 안 바뀜
└────────────────────────┘
```

#### 올바른 (아랍어 - 개선 후)
```
┌────────────────────────┐
│    الإعدادات    [ℹ️] [⚙️] │  ← 아이콘 오른쪽
│                        │
│          إعدادات الحبة │  ← 오른쪽 정렬
│     [<] ◄───────────── │  ← 화살표 방향 반전
└────────────────────────┘
```

## 11. 참고 자료

### Apple 가이드라인
- [Right to Left - HIG](https://developer.apple.com/design/human-interface-guidelines/right-to-left)
- WWDC: "Get it right (to left)"

### 프로젝트 문서
- `Arabic-App-Design-Notes.md`: 아랍어 디자인 가이드
- `iOS26-Multilingual-Guide.md`: iOS 26 다국어 기능

### 구현 체크리스트
1. SF Symbols: `chevron.forward`/`backward` 사용
2. TextAlignment: `.natural` 사용
3. semanticContentAttribute: 방향성 요소에 적용
4. StackView: `.natural` alignment
5. 테스트: 아랍어 로케일에서 전체 플로우 확인

## 12. 다음 단계

1. P1 긴급 수정 적용
2. 아랍어 로케일 테스트
3. P2 중요 항목 순차 적용
4. UI 스크린샷 비교
5. P3 장기 개선 계획 수립

---

**작성일**: 2026-01-03
**검토 대상**: Pilling-iOS05 프로젝트
**RTL 지원 점수**: 4/10 → 목표: 9/10
