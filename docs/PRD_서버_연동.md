# PRD: 복약 알림 서버 연동 (Pilling Server Sync)

## 1. 배경

기존 `Pilling`은 로컬 알림(`LocalNotificationManager`)만으로 복약 알림을 제공한다. 사용자 상태(복용 여부, 휴약일, 미접속 기간)에 따라 알림 발송 여부·내용이 달라지는 조건형 알림을 만들려면 서버가 필요하다.

`feat/#2`(→ `archive/feat-2-server-sync`)에서 1차 시도가 있었으나 미완성 상태로 보류됨. 이 PRD는 `develop` 기준으로 재시작하기 위한 기획 문서다.

## 2. 목표

- 사용자 상태 기반 조건형 푸시 알림 (매일 복용 알림, 휴약일 스킵, 복용 재개 알림, 이탈 감지)
- 서버가 복약 사이클/기록을 인지하고 발송 여부를 판단
- 서버 장애 시 로컬 알림이 fallback으로 동작 (로컬 알림 제거 안 함)

## 3. 비목표

- 서버 자체의 인프라 이중화/오토스케일링 (1인 개발, 자택 서버 1대 운용 전제)
- 건강 데이터 서버 암호화 저장 (낮은 우선순위, 별도 검토)

## 4. 시스템 아키텍처

```
iOS 앱 → (HTTPS, X-API-Key) → 서버(FastAPI) → APNs → iOS 기기
                                   │
                              SQLite (User, Pill, PillRecord)
```

서버도 iOS와 동일한 클린아키텍처(`domain → usecases → infra ← presentation`) 적용.

| 구성 | 내용 |
|------|------|
| 서버 언어/프레임워크 | Python / FastAPI |
| DB | SQLite |
| 인증 | 요청 헤더 `X-API-Key` |
| 푸시 | APNs (JWT `.p8` 키 방식) |
| HTTPS | Duck DNS + Let's Encrypt |

## 5. API 명세

| 메서드 | 경로 | 용도 | 비고 |
|--------|------|------|------|
| POST | `/users` | 사용자 등록 (user_id, device_token) | 앱 최초 실행 시 |
| PATCH | `/users/{user_id}/device-token` | APNs 토큰 갱신 | 콜백에서 즉시 호출 |
| POST | `/users/{user_id}/heartbeat` | 생존 신호 (이탈 감지용) | 응답 body 없음 |
| DELETE | `/users/{user_id}` | 계정 삭제 (약/기록 전체 삭제) | |
| POST | `/users/{user_id}/pills` | 약 등록 | |
| GET | `/users/{user_id}/pills` | 약 목록 조회 | |
| PATCH | `/pills/{pill_id}/cycle` | 복약 사이클 갱신 (휴약일 알림 제어) | 응답 body 없음 |
| PATCH | `/pills/{pill_id}/message` | 알림 문구 갱신 | 응답 body 없음 |
| POST | `/pills/{pill_id}/taken` | 복용 기록 | 당일 발송 여부 판단 근거 |

공통 에러: `401`(API Key 불일치) / `404`(리소스 없음) / `409`(중복) / `422`(입력값 오류)

## 6. 알림 타입 (MVP)

| 타입 | 트리거 | 비고 |
|------|--------|------|
| 매일 복용 알림 | 정해진 시간 | 휴약일이면 스킵 |
| 복용 재개 알림 | 휴약일 종료 시점 | |
| 이탈 감지 알림 | 앱 미접속 N일 이상 | N일 기준 미결, 무반응 반복 시 알림 중단 |

MVP 이후: 복용 확인 재알림, 사이클 종료 임박 알림, 복용 달성 격려 알림.

## 7. 1차 시도에서 확인된 리스크 (재작업 시 반영)

| 문제 | 원인 | 대응 방향 |
|------|------|-----------|
| heartbeat/PATCH cycle/message 항상 디코딩 에러 | 서버는 `{"ok": true}` 등 반환, 클라이언트는 `UserResponse{user_id}`로 파싱 시도 | 응답 body 없는 엔드포인트는 `EmptyResponse`로 명확히 타입 분리, 계약을 API 문서에 명시 후 구현 |
| 에러가 `.catchAndReturn`으로 가려짐 | 실패를 성공처럼 삼켜 서버/클라이언트 문제 구분 불가 | 최소한 로깅은 유지, 무음 실패 금지 |
| device_token 등록 실패/덮어쓰기 반복 (시뮬레이터 미지원, 빈 토큰, placeholder가 실토큰 덮어씀, UUID로 매번 갱신) | APNs 콜백 타이밍과 로컬 상태 관리 미흡 | 토큰 상태를 명시적으로 모델링 (`none / placeholder / real`), 실토큰 수신 전엔 서버 등록 보류 |
| `syncPillToServer` race condition으로 PATCH 미전송 | 비동기 흐름에서 사이클 갱신과 서버 동기화 순서 보장 안 됨 | 동기화 큐 또는 명시적 순서 보장 구조 |
| Firebase 이중 초기화 크래시 | 서버 연동과 무관, 기존 Firebase 세팅과 충돌 | 재작업 시 Firebase 의존성 최소화 유지 (이미 FirebaseAnalytics 제거로 해결됨, 재도입 주의) |

## 8. 로컬 알림과의 관계

서버 알림 도입 후에도 `LocalNotificationManager`는 제거하지 않고 fallback으로 유지. 서버 다운/네트워크 문제 시 로컬 알림이 보조.

## 9. Apple 정책 체크

- 조건에 따라 푸시를 보내거나 멈추는 것: 허용
- 알림을 앱 사용 필수 조건처럼 강제: 금지
- 스팸성 다량 발송: 금지
- 민감한 건강 정보를 알림 문구에 직접 노출: 금지

## 10. 미결 사항

- 이탈 감지 알림 기준 N일 수
- 서버 API 문서(`PILLING_SERVER_API_GUIDE.md`)에 heartbeat/cycle/message 엔드포인트 반영 필요 (현재 문서 누락)
- 알림 비활성화(사용자가 앱에서 알림 끔) 상태를 서버에 어떻게 동기화할지
- 건강 데이터 SQLite 평문 저장 여부

## 11. 마일스톤 제안

1. API 계약 재정의 및 문서화 (§7 리스크 반영, 응답 스키마 고정)
2. device_token 등록/갱신 흐름 재구현 + 상태 모델링
3. 사이클/복용 기록 동기화 (race condition 없는 구조로)
4. 서버 알림 발송 + 로컬 알림 fallback 검증
5. TestFlight 배포 후 실기기 알림 동작 확인
