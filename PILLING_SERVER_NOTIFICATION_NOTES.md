# Pilling 서버/알림 구상 문서

## 1. 배경

`Pilling`에서 단순 로컬 알림만 주는 방식이 아니라, 사용자 상태에 따라 동작이 달라지는 조건형 알림 시스템을 만들고 싶다.

## 2. 확정된 방향

| 항목 | 결정 |
|------|------|
| 서버 위치 | 집 M2 Air (상시 가동) |
| 개발 머신 | M3 Pro ← 현재 작업 환경. 코드 작성/푸시는 여기서 |
| 서버 언어 | Python |
| 웹 프레임워크 | FastAPI |
| 알림 방식 | APNs (Apple Push Notification Service) |
| DB | SQLite |
| HTTPS | Duck DNS + Let's Encrypt |

## 3. 알림 조건 (상태 기반)

단순 시간 반복 알림이 아니라 조건을 보고 발송 여부 결정:

- 며칠 이상 앱 미접속 → 알림 중단
- 휴약일 → 알림 중단
- 사용자 상태에 따라 알림 강도/메시지 조절 (듀오링고 방식)

## 4. 앱 → 서버로 전송할 데이터

- 오늘 약 먹었는지 여부
- 피임약 정보 (사이클 등)
- 알림 받을 시간

## 5. 시스템 흐름

```
앱 → (HTTPS) → M2 Air 서버 → APNs → iOS 기기
```

## 6. 집 맥북(M2 Air) 서버 설정 필요 항목

1. Duck DNS 도메인 발급 (무료)
2. Duck DNS 클라이언트로 IP 자동 업데이트
3. 라우터 포트 포워딩 (443 → M2 Air)
4. Let's Encrypt SSL 인증서 발급
5. Python 서버 실행

## 7. Apple/iOS 정책 관련

- 자체 서버에서 알림 발송 로직 관리: 허용
- 조건에 따라 푸시 알림 보내거나 멈추기: 허용
- 주의: 알림을 앱 사용 필수 조건처럼 강제 금지
- 주의: 스팸성 다량 발송 금지
- 주의: 민감한 건강 정보 알림 문구에 직접 노출 금지

## 8. 서버 구조 (예정) — 클린아키텍처

iOS 앱과 동일한 클린아키텍처 적용. 의존성 방향: `presentation → usecases → domain ← infra`

```
pilling-server/
├── domain/
│   ├── entities.py             # User, PillRecord, NotificationSetting
│   └── interfaces.py           # Repository 프로토콜
├── usecases/
│   ├── check_notification.py   # 오늘 알림 보낼지 판단
│   └── record_pill_taken.py    # 복약 기록
├── infra/
│   ├── sqlite_repository.py    # DB 구현체
│   └── apns_service.py         # APNs 발송 구현체
├── presentation/
│   └── router.py               # FastAPI 라우터 (Controller 역할)
├── scheduler.py                # 조건 체크 & 알림 스케줄러
├── main.py
├── requirements.txt
└── .env                        # APNs 키 (gitignore)
```

**iOS ↔ 서버 레이어 대응:**

| iOS | Python 서버 |
|-----|-------------|
| Entity | `domain/entities.py` |
| Repository Protocol | `domain/interfaces.py` |
| UseCase | `usecases/` |
| Repository 구현체 | `infra/sqlite_repository.py` |
| ViewController | `presentation/router.py` |

## 9. 알림 타입

| 타입 | 트리거 | MVP | 비고 |
|------|--------|-----|------|
| 매일 복용 알림 | 매일 정해진 시간 | O | 휴약일이면 스킵 |
| 복용 재개 알림 | 휴약일 종료 시점 | O | "다음 약은 준비하셨나요?" |
| 이탈 감지 알림 | 앱 미접속 N일 이상 | O | N일 수 미결, 무반응 반복 시 알림 중단 |
| 복용 확인 재알림 | 알림 후 N시간 내 미확인 | - | "드셨나요?" 재알림 |
| 사이클 종료 임박 알림 | 약 소진 며칠 전 | - | "미리 구매하세요" |
| 복용 달성 격려 알림 | 연속 복용 N일 달성 | - | 7일, 21일 등 milestone |

## 10. 로컬 알림 처리 방향

서버 알림 도입 후 기존 `LocalNotificationManager`는 제거하지 않고 **서버 알림의 fallback**으로 유지.

- 서버(M2 Air) 꺼지거나 네트워크 문제 시 → 로컬 알림이 보조
- 평상시엔 서버 알림이 메인

## 11. 추가 고려 사항

### 기술

| 항목 | 내용 | 우선순위 |
|------|------|---------|
| Device Token 관리 | 앱 재설치/OS 업데이트 시 토큰 변경됨. 서버가 항상 최신 토큰 유지해야 함 | 높음 |
| 서버 API 인증 | API 주소 아는 누구나 호출 가능. 최소 API Key 필요 | 높음 |
| 맥북 재시작 자동 실행 | M2 Air 재시작 시 서버 자동으로 올라와야 함 (`launchd` 설정) | 높음 |
| 타임존 | 사용자 기기 타임존 기준으로 알림 시간 계산해야 함 | 중간 |
| APNs 환경 분리 | 개발(sandbox) / 배포(production) 엔드포인트 다름. 혼동 주의 | 중간 |
| 건강 데이터 암호화 | 복약 기록 SQLite 평문 저장 시 보안 리스크 | 낮음 |

### UX/정책

| 항목 | 내용 |
|------|------|
| 알림 비활성화 동기화 | 앱에서 알림 끄면 서버에도 반영 필요 |

## 12. 개발 환경 & 배포 방식

### 머신 역할 분리

| 머신 | 역할 |
|------|------|
| M3 Pro | 코드 작성, iOS 개발, git push, 서버 코드 작성 |
| M2 Air | 서버 실행 환경. git pull 후 서버 가동 |

### M2 Air 접속 방법

- Tailscale로 M2 Air에 SSH 접속
- 터미널 alias: `m2-mac` → `ram@100.72.222.21`

### 코드 전달 방법

- 서버 코드: GitHub 별도 repo → M3 Pro에서 push → M2 Air에서 `git pull`
- 문서 전송 필요 시: `scp PILLING_SERVER_NOTIFICATION_NOTES.md ram@100.72.222.21:~/`

### 개발 방식

- M3 Pro에서 코드 작성 (Claude Code 활용)
- push → M2 Air에서 pull → 서버 재시작 사이클
- M2 Air에서도 `claude` 명령어 직접 실행 가능

## 13. 미결 사항

- APNs 인증 방식 확정 (JWT `.p8` 키 방식 권장)
- Apple Developer 계정에서 키 발급 필요
- Duck DNS 도메인명 결정
- 이탈 감지 알림 기준 N일 수 결정
