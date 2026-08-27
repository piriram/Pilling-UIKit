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
- 호스팅 최종 선택 (§12 참고, 아직 미확정)
- 장애 모니터링/알림 방식 (§13 참고, 아이디어 단계)

## 11. 마일스톤 제안

0. 호스팅 결정 (§12) 후 서버 배포 환경 세팅
1. API 계약 재정의 및 문서화 (§7 리스크 반영, 응답 스키마 고정)
2. device_token 등록/갱신 흐름 재구현 + 상태 모델링
3. 사이클/복용 기록 동기화 (race condition 없는 구조로)
4. 서버 알림 발송 + 로컬 알림 fallback 검증
5. TestFlight 배포 후 실기기 알림 동작 확인

## 12. 호스팅 옵션 비교

기존 자택 서버(M2 Air + Duck DNS, $0)를 안정적인 환경으로 옮기는 걸 검토 중. AWS와 Firebase Functions를 먼저 비교했고, 이후 범위를 넓혀 조사함.

**AWS vs Firebase Functions**: 이미 FastAPI + SQLite로 클린아키텍처를 짜놓은 상태라, AWS(상시 가동 인스턴스) 쪽이 코드를 거의 그대로 옮길 수 있어 더 맞음. Firebase Functions는 서버리스라 SQLite(파일 기반 DB)가 안 맞고, FastAPI 구조도 Functions 형태로 다시 쪼개야 해서 재작업이 큼.

**AWS 자체 비용**:
- Lightsail $5/월: 512MB RAM · 1 vCPU · 20GB SSD · 1TB 트래픽, 고정 IPv4 포함 — 컴퓨트/스토리지/트래픽/IP가 한 가격에 번들
- EC2 직접 구성 $10~11/월: t4g.micro($6.13) + EBS 8GB($0.6~1) + 퍼블릭 IPv4($3.6, 2024년부터 AWS가 IP 자체에 과금 시작) + VPC/보안그룹 등 직접 설정 필요

**대안 전체 비교** (코드 변경 없이 지금 구조를 그대로 옮길 수 있는지 기준):

| 옵션 | 월 비용 | SQLite 그대로 | 설정 난이도 | 상시 가동 안정성 | 코드 변경 |
|---|---|---|---|---|---|
| 자택 서버 (현재, M2 Air) | $0 | ✅ | 이미 됨 | 낮음 (정전/네트워크/재부팅에 취약) | 없음 |
| Fly.io | ~$2 | ✅ (volume) | 쉬움 (`flyctl deploy`) | 높음 | 없음 |
| Railway | ~$5 (크레딧) | ✅ (volume) | 제일 쉬움 (git push) | 높음 | 없음 |
| Lightsail | $5 | ✅ | 보통 | 높음 | 없음 |
| DigitalOcean Droplet | $4~6 | ✅ | 보통 | 높음 | 없음 |
| EC2 직접 구성 | $10~11 | ✅ | 어려움 (VPC/보안그룹 등) | 높음 | 없음 |
| Oracle Cloud Always Free | $0 | ✅ | 어려움 (EC2급 직접 설정) | 중간 (계정 회수 사례 있음) | 없음 |
| Raspberry Pi (자가 호스팅) | $0 (+ 초기 하드웨어) | ✅ | 보통 | 중간 (가정 네트워크 의존은 동일) | 없음 |
| Google Cloud Run | 사용량 기반 | ❌ (디스크 휘발성 → Cloud SQL/Litestream 필요) | 보통 | 높음 | 있음 (DB 계층) |
| AWS App Runner | 사용량 기반 | ❌ (동일 문제) | 보통 | 높음 | 있음 (DB 계층) |
| Firebase Functions | 사용량 기반 | ❌ (Firestore로 전환 필요) | 어려움 (구조 재설계) | 높음 | 큼 (아키텍처 전체) |

**"EC2급 직접 설정"의 의미**: 관리형 플랫폼(PaaS)이 아니라 빈 VM 하나만 주어지는 방식. SSH로 접속해 Python/의존성 설치, `systemd`로 프로세스 자동 재시작 등록, nginx 리버스 프록시 + Let's Encrypt 인증서 발급/갱신, 방화벽 포트 오픈(Oracle Cloud는 OS iptables + 콘솔 Security List 둘 다 열어야 함)까지 전부 직접 해야 함. Railway/Fly.io 같은 PaaS는 이 과정이 아예 없음.

**현재 방향**: 지금 규모(개인 프로젝트, 1인 개발)엔 **Fly.io** 또는 **Lightsail $5 플랜**이 가장 현실적. 완전 무료가 최우선이면 Oracle Always Free. 최종 확정 전.

## 13. 운영 모니터링 (아이디어, 미검증)

서버 장애 시 텔레그램으로 알림받는 방식 검토 중 — `piriram/DoSurf-API`에서 쓰는 방식을 참고하려 했으나 세션 도구 문제로 아직 확인 못함 (재확인 예정).

일반적인 구현 방향 두 가지:

1. **직접 구현** — 알림 스케줄러(APScheduler 등) 옆에 헬스체크 로직을 붙이고, 실패 시 Telegram Bot API로 메시지 전송
2. **외부 무료 서비스** — UptimeRobot, Healthchecks.io 등은 엔드포인트만 등록하면 주기적으로 핑을 보내고 실패 시 Telegram 연동 알림까지 내장. 서버 프로세스 자체가 죽는 경우 자체 헬스체크 로직도 같이 죽으므로, 외부 서비스 쪽이 더 안전함

`DoSurf-API` 확인 후 방식 확정 예정.

## 부록. 이 PRD 작성 전 진행한 저장소 정리

- `feat/#2` → `archive/feat-2-server-sync`로 브랜치명 변경 (사용 중단 표시, 커밋 이력은 보존)
- `develop` 브랜치를 `main`(f09436f) 기준으로 fast-forward 갱신 (기존 develop이 5개월 전 상태로 뒤처져 있었음)
- `CLAUDE.md`의 Git 컨벤션을 `piriram/hop_wheel-robot` 방식(`타입: 요약` 커밋 형식, 브랜치 네이밍, PR 규칙)으로 교체
- 앞으로 서버 연동 작업은 `develop`에서 분기해서 진행
