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
                    SQLite (User, Pill, PillRecord — 당일 복용 신호만, §4.1)
```

서버도 iOS와 동일한 클린아키텍처(`domain → usecases → infra ← presentation`) 적용.

| 구성 | 내용 |
|------|------|
| 서버 언어/프레임워크 | Python / FastAPI |
| DB | SQLite |
| 인증 | 요청 헤더 `X-API-Key` |
| 푸시 | APNs (JWT `.p8` 키 방식) |
| HTTPS | Duck DNS + Let's Encrypt |

### 4.1 데이터 소유권: 로컬(디바이스) vs 서버

**결정: 복용 기록의 소스는 로컬(디바이스), 서버는 파생 신호만 수신.**

- 전체 복용 히스토리(시각별 기록)는 디바이스에만 저장 — `DaillyWidget`이 오프라인에서도 즉시 렌더링해야 해서 어차피 로컬 데이터가 필수이고, 서버를 소스로 두면 위젯마다 네트워크 왕복이 생겨 구조가 불필요하게 복잡해짐
- 서버가 실제로 필요한 건 알림 로직(§6)이 쓸 **"오늘 복용했는지" 같은 파생 신호 하나뿐** — 상세 이력 전체가 아님
- 민감 건강정보(피임약 복용 기록) 전송량을 최소화하는 방향이 §3 비목표(서버 암호화 저장 낮은 우선순위)와도 맞음 — 애초에 서버에 안 올리면 그 문제 자체가 작아짐
- 예외: MVP 이후 "복용 달성 격려 알림"(§6, 7일/21일 연속 등 streak)을 서버에서 판단하게 하려면 최소한 연속 일수 카운트는 필요 — 이건 그 기능 붙일 때 "로컬에서 계산해서 숫자만 전송" vs "서버가 직접 계산" 중 다시 결정

### 4.2 사용자 식별자 전략

**원칙: 로그인 강제 없음. 기기 변경 대응은 단계적으로, 필요할 때만 쓰는 방식으로.**

1단계 — 기본 (지금 구현):
- 앱 최초 실행 시 로컬에서 랜덤 UUID 생성 → Keychain 저장 → 그대로 서버 `user_id`로 등록
- 로그인/회원가입 화면 없음

2단계 — iOS 기기 간 자동 이어가기 (계획됨, 나중에):
- 1단계 UUID를 iCloud Keychain으로 동기화 — 같은 Apple ID의 iOS 기기끼리는 사용자가 아무것도 안 해도 자동으로 이어짐
- iCloud Keychain 미사용 기기나 다른 Apple ID로는 안 이어짐 (3단계로 보완)

3단계 — 수동 백업/이전 (파일 export/import, 나중에):
- 피임약 사이클이 약 30일 단위라 오래된 기록을 완벽하게 보존해야 할 이유가 크지 않음 — 계정 시스템 없이 **로컬 데이터(약/사이클/기록) + 서버 `user_id`를 파일로 export**하고, 새 기기에서 import하는 방식으로 충분
- import 시 새 기기가 파일 속 기존 `user_id`로 `POST /users` 재호출(device_token만 갱신)하면 서버 계정도 그대로 이어짐 — 서버 스키마 변경 불필요
- iCloud Keychain(2단계)이 안 되는 경우(꺼둠, Apple ID 다름, 향후 Android)의 수동 대체 수단 겸 백업
- 플랫폼 종속 로그인이 아니라서 향후 Android 대응에도 그대로 재사용 가능

4단계 — OAuth 로그인 (보류, 필요해지면):
- Sign in with Apple / Google을 "설정 안쪽의 선택 기능"으로 — 정말 필요해질 때(Android 정식 출시, 계정 복구 문의 급증 등)까지 미룸
- 넣게 되면 서버 `users` 테이블에 `apple_sub`/`google_sub`를 nullable로 추가하는 정도로 충분 (지금 스키마 변경 불필요)

**기각된 방식**: `identifierForVendor`(IDFV)를 `UserDefaults`에 캐싱 — 1차 시도(§7 참고)에서 실제로 이렇게 구현했었는데, 앱 재설치만 해도 깨지고 기기 변경 시엔 100% 깨짐.

### 4.3 설정값(기준일 등) 관리 원칙

이탈 감지 N일(§10), 데이터 삭제 6개월(§9.1), alert 재시도 횟수(§13), streak 마일스톤(§6) 등 코드 곳곳에 흩어지기 쉬운 기준값은 전부 이름 붙여 한 곳에서 관리:

- **코드 상수화(필수)**: `config.py` 등에 `INACTIVITY_ALERT_STOP_DAYS`, `DATA_RETENTION_DELETE_MONTHS = 6`, `ALERT_RETRY_COUNT = 3` 처럼 모아둠 — 매직넘버가 코드 곳곳에 흩어지는 것 방지
- **환경변수는 값 성격에 따라 선별적으로**: 배포 후 실데이터 보고 계속 튜닝할 값(예: 이탈 감지 N일)은 `.env`로 빼서 재배포 없이 조정 가능하게. 정책적으로 한 번 정하면 잘 안 바뀌는 값(예: 6개월 삭제 기준)은 코드 상수로 충분 — 개인 프로젝트 규모에서 재배포 비용은 거의 없음
- **과한 설계 지양**: DB 설정 테이블 + 어드민 패널로 실시간 변경까지는 지금 규모엔 오버엔지니어링. env 변수 정도면 충분

### 4.4 DB 백업 전략

**결정: 가벼운 GCS 백업 + 재등록 복구 로직 병행.**

- **GCS 백업**: `sqlite3 .backup`(또는 `VACUUM INTO`)으로 실행 중에도 안전하게 스냅샷을 뜬 뒤, cron으로 주기적(예: 매일)으로 GCS 버킷에 저장. 그냥 `cp`로 복사하면 쓰기 도중 순간을 찍어 손상될 수 있어 반드시 `.backup`/`VACUUM INTO` 사용
  - 비용: GCS Always Free 티어(미국 리전 월 5GB)로 충분 — SQLite 파일이 몇 MB 수준이라 여러 날치를 쌓아도 무료 범위
- **재등록 복구 로직**: §9.1에서 이미 설계한 "서버가 사용자를 모름(404) → 자동 재등록"을 DB 완전 유실 상황에도 그대로 활용. 클라이언트가 404를 감지하면 로컬에 있는 사이클/약 정보를 다시 `POST`해서 동기화 — 서버 DB가 통째로 날아가도 사용자가 앱을 한 번 여는 것만으로 복구됨
- **기각한 대안**: GCP Persistent Disk 스냅샷 — Always Free 번들에 포함 안 돼 별도 과금되고, 파일 하나 백업하는 데 디스크 전체 단위로 접근하는 건 이 규모엔 과함

### 4.5 서버 저장소(repo) 분리

**결정: 서버(Python/FastAPI) 코드는 `Pilling-UIKit`과 별도 repo로 관리 (예: `pilling-server`).**

- 원래 계획이기도 함 — `archive/feat-2-server-sync`의 `PILLING_SERVER_NOTIFICATION_NOTES.md`에 "서버 코드: GitHub 별도 repo" 명시돼 있었음
- `Pilling-UIKit`엔 서버를 호출하는 iOS 클라이언트 코드(`PillingServerAPIService`, DTO 등)만 남고, 서버 구현 자체는 포함하지 않음
- `piriram/DoSurf-API`도 별도 repo — 서비스 단위로 repo를 나누는 기존 패턴과 일관됨
- 툴체인이 완전히 다름(Xcode/Swift vs Python/FastAPI)이라 한 repo에 합치면 `.gitignore`/CI/Git 컨벤션이 뒤섞임 — `CLAUDE.md`의 커밋/브랜치 규칙도 지금 iOS 앱 기준이라 서버 작업까지 같은 히스토리에 넣으면 지저분해짐
- **개발 편의성**: Claude Code 세션은 여러 repo를 동시에 붙일 수 있어(오늘 `hop_wheel-robot`, `DoSurf-API`를 `Pilling-UIKit`과 같이 연 것처럼), 서버 작업 시 `Pilling-UIKit` + `pilling-server`를 함께 열면 API 계약(클라이언트 DTO ↔ 서버 응답)을 동시에 보면서 작업 가능 — repo 분리로 인한 불편은 거의 없음

## 5. API 명세

| 메서드 | 경로 | 용도 | 비고 |
|--------|------|------|------|
| POST | `/users` | 사용자 등록 (user_id, device_token) | 앱 최초 실행 시. `user_id`는 로컬 생성 UUID (§4.2). 응답에 `access_token` 포함 (§5.1) |
| PATCH | `/users/{user_id}/device-token` | APNs 토큰 갱신 | `Authorization: Bearer` 필요 (§5.1) |
| POST | `/users/{user_id}/heartbeat` | 생존 신호 (이탈 감지용) | 응답 body 없음, 인증 필요 |
| DELETE | `/users/{user_id}` | 계정 삭제 (약/기록 전체 삭제) | 인증 필요 |
| POST | `/users/{user_id}/pills` | 약 등록 | 인증 필요 |
| GET | `/users/{user_id}/pills` | 약 목록 조회 | 인증 필요 |
| PATCH | `/pills/{pill_id}/cycle` | 복약 사이클 갱신 (휴약일 알림 제어) | 응답 body 없음, 인증 필요 |
| PATCH | `/pills/{pill_id}/message` | 알림 문구 갱신 | 응답 body 없음, 인증 필요 |
| POST | `/pills/{pill_id}/taken` | 복용 신호 전송 | 당일 발송 여부 판단 근거 (전체 이력 아님, §4.1 참고), 인증 필요 |

공통 에러: `401`(API Key 또는 Bearer 토큰 불일치) / `404`(리소스 없음) / `409`(중복) / `422`(입력값 오류)

### 5.1 인증 구조

**문제**: `X-API-Key`는 앱 바이너리에 박혀있어 IPA만 뜯으면 누구나 꺼낼 수 있음. 지금 설계는 `user_id`(URL 경로)만 알면 그 값이 진짜 본인 것인지 검증 없이 조회/삭제까지 가능 — 다른 사용자의 `user_id`를 알아내면 그 사람의 약 목록 조회, 계정 삭제(`DELETE /users/{user_id}`)까지 가능한 구조였음.

**결정: 등록 시 발급되는 개인 비밀 토큰(Bearer) 방식 채택.**

- `POST /users`로 최초 등록할 때 서버가 `user_id`와 별개로 무작위 비밀 토큰 `access_token`을 생성해 응답에 포함
- 클라이언트는 이 토큰을 Keychain에 저장(§4.2와 동일한 보호 수준), 이후 모든 요청에 `Authorization: Bearer <access_token>`으로 전송
- 서버는 `user_id`가 아니라 **이 토큰이 그 `user_id`에 발급된 값과 일치하는지**로 본인 확인 — `X-API-Key`는 "이 요청이 Pilling 앱에서 왔는지"만 검증하는 용도로 남기고, 리소스별 권한은 Bearer 토큰이 담당
- 로그인 UI 불필요 — §4.2 "로그인 강제 없음" 원칙과 충돌 없음
- §4.2의 4단계(Sign in with Apple)가 나중에 도입되면, 그 로그인이 이 토큰 발급 주체를 "익명 등록"에서 "Apple 인증된 로그인"으로 격상시키는 구조로 자연스럽게 확장 가능

**기각한 대안**: HMAC 요청 서명(이미 HTTPS로 전송 구간 보호되고 있어 추가 복잡도 대비 이득 적음), JWT(무상태 검증 이점이 지금 DB 규모에선 무의미, 토큰 회수가 더 번거로움), Apple App Attest/DeviceCheck(가장 강력하지만 구현 복잡도가 지금 위협 수준 대비 과함, iOS 전용이라 향후 Android 대응 시 또 다른 수단 필요) — 필요해지면 재검토.

## 6. 알림 타입 (MVP)

| 타입 | 트리거 | 비고 |
|------|--------|------|
| 매일 복용 알림 | 정해진 시간 | 휴약일이면 스킵 |
| 복용 재개 알림 | 휴약일 종료 시점 | |
| 이탈 감지 알림 | 앱 미접속 14일 이상 (잠정) | 무반응 반복 시 알림 중단, §4.3 따라 env로 조정 가능 |

MVP 이후: 복용 확인 재알림, 사이클 종료 임박 알림, 복용 달성 격려 알림.

### 6.1 타임존/스케줄링 방식

**결정: 알림은 "기기가 지금 있는 시간대"가 아니라, 설정 시점에 고정된 절대 시각(UTC) 기준으로 반복.**

- 피임약은 "아침에 먹기"가 아니라 **일정한 간격(약 24시간)으로 먹는 게 약효 유지에 중요** — 몇 시간만 어긋나도 피임 효과에 영향 줄 수 있음
- 그래서 여행 등으로 기기 시간대가 바뀌어도 알림 시각이 **따라가면 안 됨**. 사용자가 "8시"로 설정하면 그 순간의 타임존으로 절대 시각(UTC)을 한 번 계산해 고정 (예: `08:00 KST` = `UTC 23:00` 전날) → 이후엔 기기가 어느 시간대에 있든 이 고정 UTC 시각 기준 24시간마다 반복
- 결과적으로 한국에서 8시로 설정하고 뉴욕 여행을 가면, 알림은 뉴욕 현지 저녁 시간대에 옴 (한국 기준 절대 간격은 유지) — 뉴욕 아침 8시로 밀리면 안 됨
- 사용자가 루틴 자체를 바꾸고 싶을 때(예: 장기 이주)는 설정에서 명시적으로 재설정 — 자동으로 안 따라감
- 서버는 `scheduled_time`을 타임존과 함께 받아 그 순간 UTC로 변환해 고정 저장, 이후 재계산할 땐 "현재 타임존"이 아니라 "저장된 고정 UTC + 24시간"으로 계산 (기기 타임존 변경을 계속 동기화할 필요 없음 — 오히려 단순해짐)

### 6.2 APNs 토큰 무효화 처리

**문제**: 앱 삭제나 기기 초기화로 `device_token`이 죽으면, `APNs`가 발송 시도에 대해 `410 Unregistered`를 반환한다. 지금 설계엔 이 응답을 받아서 처리하는 로직이 없음 — 서버가 계속 죽은 토큰으로 헛발송을 시도하게 됨.

- 헛수고일 뿐 아니라, §9.1(6개월 미접속 시 데이터 삭제)의 "미접속 판단" 기준(heartbeat)과 별개로 실제로는 이미 앱을 지운 사용자를 계속 "살아있는 사용자"처럼 취급하게 됨
- **대응**: `APNs` 발송 응답에서 `410 Unregistered`를 받으면 해당 `device_token`을 즉시 비활성화 처리하고, 그 토큰으로는 재발송 중단
- 구현 위치: 알림 발송 스케줄러(§4 아키텍처)의 발송 결과 처리 단계에 추가 — 새 엔드포인트나 별도 인프라 불필요

## 7. 1차 시도에서 확인된 리스크 (재작업 시 반영)

| 문제 | 원인 | 대응 방향 |
|------|------|-----------|
| heartbeat/PATCH cycle/message 항상 디코딩 에러 | 서버는 `{"ok": true}` 등 반환, 클라이언트는 `UserResponse{user_id}`로 파싱 시도 | 응답 body 없는 엔드포인트는 `EmptyResponse`로 명확히 타입 분리, 계약을 API 문서에 명시 후 구현 |
| 에러가 `.catchAndReturn`으로 가려짐 | 실패를 성공처럼 삼켜 서버/클라이언트 문제 구분 불가 | 최소한 로깅은 유지, 무음 실패 금지 |
| device_token 등록 실패/덮어쓰기 반복 (시뮬레이터 미지원, 빈 토큰, placeholder가 실토큰 덮어씀, UUID로 매번 갱신) | APNs 콜백 타이밍과 로컬 상태 관리 미흡 | 토큰 상태를 명시적으로 모델링 (`none / placeholder / real`), 실토큰 수신 전엔 서버 등록 보류 |
| `syncPillToServer` race condition으로 PATCH 미전송 | 비동기 흐름에서 사이클 갱신과 서버 동기화 순서 보장 안 됨 | 동기화 큐 또는 명시적 순서 보장 구조 |
| Firebase 이중 초기화 크래시 | 서버 연동과 무관, 기존 Firebase 세팅과 충돌 | 재작업 시 Firebase 의존성 최소화 유지 (이미 FirebaseAnalytics 제거로 해결됨, 재도입 주의) |
| `resolveServerUserID()`가 `identifierForVendor`를 `UserDefaults`에 캐싱해 `user_id`로 사용 | 앱 재설치 시 `UserDefaults` 삭제 + IDFV도 리셋 가능 → 계정 연결 끊김. 기기 변경 시엔 100% 끊김 | §4.2 사용자 식별자 전략(Keychain UUID + iCloud Keychain + 파일 export/import)으로 대체 |
| (기존 앱) `LocalNotificationManager`가 `UNCalendarNotificationTrigger(dateMatching: [hour, minute], repeats: true)`로 알림 예약 | hour/minute만 넣은 반복 트리거는 기기 시간대를 자동으로 따라감 — 해외여행 시 절대 복용 간격이 깨짐 (§6.1 참고) | 고정 UTC 시각 기준으로 재계산하는 방식으로 전환 (`UNTimeIntervalNotificationTrigger` 또는 매번 새로 계산한 절대 날짜) |

## 8. 로컬 알림과의 관계

서버 알림 도입 후에도 `LocalNotificationManager`는 제거하지 않고 fallback으로 유지. 서버 다운/네트워크 문제 시 로컬 알림이 보조.

## 9. Apple 정책 체크

- 조건에 따라 푸시를 보내거나 멈추는 것: 허용
- 알림을 앱 사용 필수 조건처럼 강제: 금지
- 스팸성 다량 발송: 금지
- 민감한 건강 정보를 알림 문구에 직접 노출: 금지

### 9.1 데이터 보존/삭제 정책 (사용자 증가 대비)

heartbeat 마지막 수신 시각 기준 2단계 정책:

| 미접속 기간 | 처리 |
|---|---|
| 14일 이상 (잠정, §6 참고) | 알림 발송만 중단 |
| 6개월 이상 | 서버 측 사용자 데이터(약/사이클/기록) 삭제 |

- **삭제해도 손실 거의 없음**: §4.1에 따라 사용자의 실제 기록은 로컬에 있음 — 서버 삭제는 "죽은 계정 정리" 수준이지 데이터 유실이 아님
- **목적**: 민감 건강정보 최소 보유 (§3과 같은 결)
- **구현 요건**: 삭제된 사용자가 재실행하면 `user_id` 재등록 요청이 404를 받게 되는데, 이건 정상 케이스로 처리해 **자동 재등록**해야 함 — 에러로 취급 금지 (§7 "무음 실패 금지"와 반대 방향의 같은 원칙)
- **실행 방식**: heartbeat 기반 스케줄러에 정리 배치 추가 — 새 인프라 불필요

## 10. 미결 사항

- 서버 API 문서(`PILLING_SERVER_API_GUIDE.md`)에 heartbeat/cycle/message 엔드포인트 반영 필요 (현재 문서 누락)
- 알림 비활성화(사용자가 앱에서 알림 끔) 상태를 서버에 어떻게 동기화할지
- 건강 데이터 SQLite 평문 저장 여부
- GCP 프로젝트를 DoSurf-API와 공유할지, 별도 프로젝트로 분리할지 (§12.2 참고 — VM 무료 한도 경쟁은 없음 확인됨, IAM/보안 격리 관점에서만 결정하면 됨)
- 실사용자 늘었을 때 SQLite → Postgres 전환 트리거 기준 (§14 참고)

**해결됨**: 이탈 감지 알림 중단 기준은 14일(잠정)로 결정 (§6, §9.1 반영).

## 11. 마일스톤 제안

0. GCP 프로젝트 세팅 (§12 결정: e2-micro) 후 서버 배포 환경 구성
1. API 계약 재정의 및 문서화 (§7 리스크 반영, 응답 스키마 고정)
2. device_token 등록/갱신 흐름 재구현 + 상태 모델링
3. 사이클/복용 기록 동기화 (race condition 없는 구조로)
4. 서버 알림 발송 + 로컬 알림 fallback 검증
5. TestFlight 배포 후 실기기 알림 동작 확인

## 12. 호스팅 결정: GCP Compute Engine (e2-micro, Always Free)

기존 자택 서버(M2 Air + Duck DNS, $0)를 안정적인 환경으로 옮기기 위해 AWS·Firebase Functions부터 시작해 범위를 넓혀 조사함. **결론: GCP e2-micro로 확정.**

### 12.1 컴퓨트 스펙은 결정 기준이 아니었다

Pilling 백엔드가 실제로 받는 요청은 유저 1명당 하루 3~5건(heartbeat 1회, 복용 기록 POST 1~3회, 사이클/메시지 PATCH는 가끔) 수준이고, 이마저 유저마다 복약 시간이 달라 하루 종일 흩어져 들어온다. 알림 발송도 서버가 DB를 스캔해 APNs로 던지는 구조라 유저 트래픽과 무관하게 가볍다. → **e2-micro(1GB RAM, 공유 vCPU)조차 이미 과스펙**이라, RAM/CPU가 더 큰 옵션(Oracle Ampere A1 등)을 골라도 실질 이득이 없다. 진짜 갈리는 기준은 컴퓨트 성능이 아니라 **"안 꺼지고 계속 떠 있는가"**와 **"운영(모니터링) 인프라를 재사용할 수 있는가"** 둘뿐이었다.

### 12.2 GCP e2-micro vs Oracle Always Free (상세 리서치)

스펙만 보면 Oracle이 훨씬 넉넉하지만, 안정성에서 최근 크게 흔들렸다.

| 항목 | GCP e2-micro | Oracle Ampere A1 |
|---|---|---|
| CPU/RAM | 2 vCPU(1/8 공유 코어) · 1GB | 2026.6 기준 **2 OCPU · 12GB** (기존 4 OCPU·24GB에서 공지 없이 반토막) |
| 디스크 | 30GB | 200GB (Ampere+AMD 합산 풀) |
| 리전 | us-west1/central1/east1 한정 | 가입 시 선택한 홈 리전 고정 |
| 이그레스 | 월 200GB | 월 10TB |
| **유휴 회수 정책** | **없음** — 켜두면 계속 내 것 | **있음** — 7일간 CPU 95퍼센타일 20% 미만 등 조건 충족 시 회수 대상 (저트래픽 개인 서버는 걸리기 쉬움) |
| **최근 정책 변경** | 없음 | 2026.6 스펙 반토막, 2026.8.18부로 새 한도 초과 인스턴스 종료 처리 (이미 지난 마감일) |
| 실전 이슈 | 없음 | "Out of host capacity" — 무료라 인기 많아 인스턴스 생성 자체가 리전별로 실패하는 사례 흔함 |

Oracle의 넉넉한 RAM은 §12.1에 따라 이 프로젝트엔 어차피 의미가 없고, 오히려 최근 6개월 새 두 번 정책이 바뀐 전례(스펙 반토막 + 유휴 회수)가 "예측 가능성" 측면에서 감점 요인.

**GCP Always Free e2-micro 한도 관련 확인**: 이 무료 한도는 프로젝트가 아니라 **결제 계정(빌링 어카운트) 전체에서 1대**로 제한됨. 같은 계정 아래 `DoSurf-API`가 이미 Compute Engine VM을 쓰고 있었다면 Pilling용 e2-micro는 무료가 아니게 될 뻔했으나, **`DoSurf-API`는 Firebase(서버리스) 기반이라 Compute Engine VM을 쓰지 않음** — 무료 한도 경쟁 없이 Pilling이 e2-micro를 그대로 쓸 수 있음. (§13의 Cloud Monitoring/`send_telegram_alert()` 재사용은 "같은 VM"이 아니라 "코드/패턴 재사용" — Firebase 기반이어도 그대로 적용 가능)

### 12.3 자가 호스팅(M2 Air / Raspberry Pi)을 기각한 이유

- **M2 Air**: 서버 겸 개인 노트북이라 용도가 충돌 — 잠자기, 뚜껑 닫힘, OS 업데이트 재부팅, 다른 작업 중 실수 종료 등으로 서비스가 끊길 위험이 구조적으로 있음
- **Raspberry Pi**: 서버 전용 기기라 그 위험은 없어지지만(전력 소비도 낮아 24/7 부담 없음), 초기 하드웨어 비용($50~80)이 들고 **가정 인터넷/전기 의존이라는 근본 리스크는 M2 Air와 동일**
- 두 옵션 다 "가정 네트워크가 끊기면 서버도 죽는다"는 한계를 클라우드로 못 벗어남 → GCP e2-micro가 이 문제 자체를 해소

### 12.4 GCP e2-micro가 최종 결정인 이유 (§13 연결)

`piriram/DoSurf-API`가 이미 GCP 위에서 돌아가고, Cloud Monitoring + `send_telegram_alert()` 텔레그램 알림 코드가 검증된 채로 존재함. Pilling 서버를 같은 GCP 계정에 두면:
- e2-micro는 영구 무료(Always Free), 유휴 회수 정책 없음, SQLite도 퍼시스턴트 디스크로 그대로 사용 가능
- DoSurf-API의 Cloud Monitoring 웹훅 + `send_telegram_alert()` 코드를 그대로 재사용 가능 — 다른 후보(Fly.io, Lightsail 등)는 알림 체계를 처음부터 새로 구축해야 함

**"EC2급 직접 설정"의 의미** (GCP VM에도 동일하게 적용): 관리형 플랫폼(PaaS)이 아니라 빈 VM 하나만 주어지는 방식. SSH로 접속해 Python/의존성 설치, `systemd`로 프로세스 자동 재시작 등록, nginx 리버스 프록시 + Let's Encrypt 인증서 발급/갱신, 방화벽 포트 오픈까지 전부 직접 해야 함. Railway/Fly.io 같은 PaaS는 이 과정이 아예 없지만, 모니터링 재사용 이득이 이 초기 설정 비용을 상회한다고 판단.

### 12.5 전체 후보 비교 (참고용)

| 옵션 | 월 비용 | SQLite 그대로 | 설정 난이도 | 상시 가동 안정성 | 코드 변경 |
|---|---|---|---|---|---|
| **GCP e2-micro (Always Free)** — **선택** | **$0** | ✅ | 어려움 (EC2급 직접 설정, 리전 한정) | 높음, 유휴 회수 없음 | 없음 |
| 자택 서버 (현재, M2 Air) | $0 | ✅ | 이미 됨 | 낮음 (§12.3) | 없음 |
| Raspberry Pi (자가 호스팅) | $0 (+ 초기 하드웨어) | ✅ | 보통 | 중간 (§12.3) | 없음 |
| Fly.io | ~$2 | ✅ (volume) | 쉬움 (`flyctl deploy`) | 높음 | 없음 |
| Railway | ~$5 (크레딧) | ✅ (volume) | 제일 쉬움 (git push) | 높음 | 없음 |
| Lightsail | $5 | ✅ | 보통 | 높음 | 없음 |
| DigitalOcean Droplet | $4~6 | ✅ | 보통 | 높음 | 없음 |
| EC2 직접 구성 | $10~11 | ✅ | 어려움 (VPC/보안그룹 등) | 높음 | 없음 |
| Oracle Cloud Always Free | $0 | ✅ | 어려움 + 실전 이슈 (§12.2) | 중간 (유휴 회수, 정책 변경 전례) | 없음 |
| Google Cloud Run | 사용량 기반 | ❌ (디스크 휘발성) | 보통 | 높음 | 있음 (DB 계층) |
| AWS App Runner | 사용량 기반 | ❌ (동일 문제) | 보통 | 높음 | 있음 (DB 계층) |
| Firebase Functions | 사용량 기반 | ❌ (Firestore 전환 필요) | 어려움 (구조 재설계) | 높음 | 큼 (아키텍처 전체) |

## 13. 운영 모니터링 (DoSurf-API 방식 확인 완료)

`piriram/DoSurf-API`가 이미 이 문제를 풀어놓은 상태 — 그대로 참고 가능.

**구현 방식**: `app/clients/alerts.py`의 `send_telegram_alert()` 함수가 핵심.
- `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID` 환경변수 설정 시에만 동작 (미설정 시 조용히 스킵)
- Telegram Bot API(`https://api.telegram.org/bot{token}/sendMessage`)로 직접 POST, 레벨(CRITICAL/WARNING/INFO)·source·KST 타임스탬프 자동 첨부
- 실패 시 exponential backoff로 3회 재시도

**호출 지점 3곳**: `/`(collect) 엔드포인트 예외 시 CRITICAL, 수집 작업 중 이상(데이터 개수 불일치, cleanup 실패 등) 시 WARNING, `/monitoring-alert` 엔드포인트가 GCP Cloud Monitoring 웹훅을 수신해 Telegram으로 포워딩(Basic Auth 보호).

**아키텍처**: "직접 구현"(비즈니스 로직 예외 감지)과 "외부 서비스"(GCP Cloud Monitoring, 인프라 레벨 장애 감지)를 혼합 — 둘 다 같은 `send_telegram_alert()`로 수렴. 서버 프로세스 자체가 죽는 경우까지 커버하려면 자체 헬스체크만으론 부족하다는 게(§7 "무음 실패" 교훈과 같은 맥락) 실제로 GCP Cloud Monitoring을 같이 쓰는 이유였음.

**Pilling 적용 방향**: §12에서 GCP e2-micro로 결정하면 이 코드/웹훅 패턴을 그대로 가져올 수 있음. 다른 호스팅(Fly.io 등)을 선택하면 `send_telegram_alert()` 로직은 그대로 재사용하되, GCP Cloud Monitoring 대신 UptimeRobot/Healthchecks.io 같은 외부 핑 서비스로 인프라 레벨 장애 감지를 대체해야 함.

## 14. 예상 트래픽 및 용량 (어림값, 실측 아님)

유저 1명당 하루 평균 3~5 요청(heartbeat, 복용 기록, 가끔 PATCH) 기준 추정.

| 규모 | e2-micro가 버티는가 | 병목 |
|---|---|---|
| ~1,000 DAU | 여유 있음 | 없음 |
| ~5,000~10,000 DAU | 무리 없음 | 아직 없음 |
| ~수만 DAU | 슬슬 걱정 시작 | SQLite 쓰기 잠금 (CPU보다 먼저 옴) |
| 그 이상 | 마이그레이션 필요 | SQLite → Postgres 전환 + 인스턴스 업그레이드 |

개인 프로젝트~커뮤니티 단위(수백~수천 DAU) 성장까진 e2-micro 하나로 문제없음. 배포 후 실사용자 늘면 CPU/메모리 실측 모니터링으로 재확인 필요.

## 부록. 이 PRD 작성 전 진행한 저장소 정리

- `feat/#2` → `archive/feat-2-server-sync`로 브랜치명 변경 (사용 중단 표시, 커밋 이력은 보존)
- `develop` 브랜치를 `main`(f09436f) 기준으로 fast-forward 갱신 (기존 develop이 5개월 전 상태로 뒤처져 있었음)
- `CLAUDE.md`의 Git 컨벤션을 `piriram/hop_wheel-robot` 방식(`타입: 요약` 커밋 형식, 브랜치 네이밍, PR 규칙)으로 교체
- 앞으로 서버 연동 작업은 `develop`에서 분기해서 진행
