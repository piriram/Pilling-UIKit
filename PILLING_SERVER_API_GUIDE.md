# Pilling Server API Guide

iOS 클라이언트 연동 가이드입니다.

## Base URL

```text
https://pilling.duckdns.org
```

개발(sandbox) 빌드도 동일한 URL 사용. Tailscale(`100.72.222.21:8443`)은 서버 직접 접근 시에만 사용.

---

## 인증

모든 요청에 `X-API-Key` 헤더를 포함해야 합니다.

```text
X-API-Key: <API_KEY>
```

키가 없거나 틀리면 `401 Unauthorized`를 반환합니다.

---

## Endpoints

### 사용자 등록

앱 최초 실행 또는 계정 생성 시 호출합니다.

```http
POST /users
```

**Request**

```json
{
  "user_id": "string",
  "device_token": "string"
}
```

**Response** `201`

```json
{
  "user_id": "string"
}
```

---

### Device Token 갱신

앱 재설치 또는 OS 업데이트 후 APNs 토큰이 바뀌면 호출합니다.
`application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` 콜백에서 호출 권장.

```http
PATCH /users/{user_id}/device-token
```

**Request**

```json
{
  "device_token": "string"
}
```

**Response** `200`

```json
{
  "user_id": "string"
}
```

**Errors**

- `404` - user not found

---

### 사용자 탈퇴

계정 삭제 시 호출합니다. 사용자 + 등록된 약 + 복용 기록이 모두 삭제됩니다.

```http
DELETE /users/{user_id}
```

**Response** `200`

```json
{
  "user_id": "string"
}
```

**Errors**

- `404` - user not found

---

### 약 등록

```http
POST /users/{user_id}/pills
```

**Request**

```json
{
  "name": "string",
  "scheduled_time": "HH:MM"
}
```

`scheduled_time` 형식: `"08:00"`, `"21:30"` 등 24시간제

**Response** `201`

```json
{
  "pill_id": "string"
}
```

**Errors**

- `404` - user not found

---

### 약 목록 조회

```http
GET /users/{user_id}/pills
```

**Response** `200`

```json
[
  {
    "pill_id": "string",
    "name": "string",
    "scheduled_time": "HH:MM"
  }
]
```

---

### 복용 기록

약을 복용했을 때 호출합니다. 서버는 이 기록을 보고 당일 알림 발송 여부를 결정합니다.

```http
POST /pills/{pill_id}/taken
```

**Response** `201`

```json
{
  "record_id": "string",
  "taken_at": "2026-05-06T08:00:00"
}
```

**Errors**

- `404` - pill not found

---

## 공통 에러

| 상태 코드 | 의미 |
|-----------|------|
| `401` | API Key 없음 또는 불일치 |
| `404` | 리소스 없음 |
| `409` | 중복 (이미 등록된 user_id, 당일 복용 기록 중복) |
| `422` | 입력값 형식 오류 (scheduled_time 등) |

---

## iOS 연동 흐름

```text
1. 앱 최초 실행
   └─ POST /users  (user_id, device_token 전송)

2. APNs 토큰 갱신 감지 시
   └─ PATCH /users/{user_id}/device-token

3. 약 등록
   └─ POST /users/{user_id}/pills

4. 약 복용 시
   └─ POST /pills/{pill_id}/taken

5. 계정 삭제
   └─ DELETE /users/{user_id}
```
