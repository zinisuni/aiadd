# CORS와 쿠키 전송 테스트

이 프로젝트는 Cross-Origin Resource Sharing(CORS)와 타 도메인 간 쿠키 전송 테스트를 위한 간단한 샘플 코드입니다.

## 개요

브라우저의 Same-Origin Policy에 의해 다른 도메인(origin)으로의 요청에는 제약이 있습니다. 특히 쿠키와 같은 인증 정보의 전송은 추가적인 설정이 필요합니다. 이 프로젝트는 다음 항목을 테스트합니다:

1. CORS 환경에서 `credentials: 'include'` 옵션 사용
2. 서버 측의 `Access-Control-Allow-Credentials: true` 설정
3. 쿠키의 `SameSite` 속성 설정에 따른 동작 차이
4. `Secure` 속성 필요 조건

## 구성

- `index.html`: 클라이언트 페이지 (버튼 클릭으로 여러 요청 테스트)
- `client-server.js`: 클라이언트 웹 서버 (포트 8080)
- `server.js`: API 서버 (포트 3000)

## 테스트 시나리오

### 성공 케이스 (쿠키 전송 성공)
1. 쿠키 설정 버튼 클릭 - 서버에서 3종류의 쿠키를 설정합니다:
   - `testCookie`: SameSite=None, Secure=true (HTTPS에서만 작동)
   - `localTestCookie`: SameSite=Lax (일부 크로스 사이트 요청에서 전송)
   - `strictCookie`: SameSite=Strict (동일 사이트 요청에서만 전송)

2. 'credentials 포함 요청' 버튼 클릭 - `fetch(..., { credentials: 'include' })` 옵션으로 API 요청
3. 결과 확인 - `localTestCookie`만 서버에 전송됩니다. (HTTP 환경이므로 `testCookie`는 전송 안됨)

### 실패 케이스 1 (클라이언트 설정 문제)
1. 쿠키 설정 버튼 클릭
2. 'credentials 미포함 요청' 버튼 클릭 - `fetch(..., { credentials: 'omit' })` 옵션으로 API 요청
3. 결과 확인 - 서버에 쿠키가 전송되지 않음

### 실패 케이스 2 (서버 설정 문제)
1. 쿠키 설정 버튼 클릭
2. '서버 측 credentials: false 테스트' 버튼 클릭 - 서버 측에서 `Access-Control-Allow-Credentials: false`로 설정된 엔드포인트 호출
3. 결과 확인 - 브라우저가 서버로 쿠키를 전송해도 서버에서 처리하지 않음

## 주요 포인트

### 클라이언트 측 설정

```javascript
// credentials 포함 요청 (성공 케이스)
fetch('http://localhost:3000/api/data', {
  method: 'GET',
  credentials: 'include'  // 중요: 쿠키를 포함하려면 이 옵션 필요
});

// credentials 미포함 요청 (실패 케이스)
fetch('http://localhost:3000/api/data', {
  method: 'GET',
  credentials: 'omit'  // 쿠키 전송 안함
});
```

### 서버 측 설정

```javascript
// 성공 케이스 - CORS 설정
const corsOptionsSuccess = {
  origin: 'http://127.0.0.1:8080',  // 클라이언트 도메인 명시
  credentials: true,  // 중요: 인증 정보 허용
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

// 실패 케이스 - CORS 설정
const corsOptionsFailure = {
  origin: 'http://127.0.0.1:8080',
  credentials: false,  // 인증 정보 거부
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

// 쿠키 설정 예제
// SameSite=none (모든 크로스 사이트에서 전송 가능, 보안 강화 필요)
res.cookie('testCookie', 'hello-cors', {
  maxAge: 900000,
  httpOnly: true,
  sameSite: 'none',  // 중요: 크로스 사이트 요청에는 'none' 필요
  secure: true,      // 중요: SameSite=None 사용 시 필수
});

// SameSite=lax (제한적인 크로스 사이트 요청에서 전송 가능)
res.cookie('localTestCookie', 'local-test', {
  maxAge: 900000,
  httpOnly: true,
  sameSite: 'lax'
});

// SameSite=strict (크로스 사이트에서 전송 불가)
res.cookie('strictCookie', 'strict-mode', {
  maxAge: 900000,
  httpOnly: true,
  sameSite: 'strict'
});
```

## 설치 및 실행

1. 필요한 패키지 설치:
   ```bash
   cd /Users/hspark/Code/hspark/aiadd/src/aiadd/cors
   npm install
   ```

2. 애플리케이션 실행:
   ```bash
   cd /Users/hspark/Code/hspark/aiadd/src/aiadd/cors
   npm start
   ```

3. 브라우저에서 접속:
   - 클라이언트: http://127.0.0.1:8080
   - API 서버: http://localhost:3000

## 테스트 결과 해석

### 성공 케이스
- 응답에 `cookies` 객체에 `localTestCookie`가 포함되어 있으면 성공
- HTTP 환경에서는 `testCookie`가 전송되지 않음 (SameSite=None은 Secure 속성이 필요하므로)
- `strictCookie`도 전송되지 않음 (SameSite=Strict는 크로스 사이트 요청에서 전송 안됨)

### 실패 케이스
- 클라이언트 설정 문제: `cookies` 객체가 비어있음 (`credentials: 'omit'` 때문)
- 서버 설정 문제: 브라우저가 쿠키를 전송해도 서버가 받지 않음 (`credentials: false` 때문)

## SameSite 속성 설명

쿠키의 SameSite 속성은 크로스 사이트 요청에서 쿠키 전송 여부를 결정합니다:

- `SameSite=Strict`: 동일 사이트 요청에만 쿠키 전송
- `SameSite=Lax`: 동일 사이트 + 상위 레벨 탐색(링크 클릭 등)에 쿠키 전송
- `SameSite=None`: 모든 크로스 사이트 요청에 쿠키 전송 (반드시 `Secure` 속성과 함께 사용)

## 주의사항

- `SameSite=None`은 HTTPS(Secure)가 필요합니다. 로컬 개발 환경에서는 이 제약으로 인해 제대로 작동하지 않을 수 있습니다.
- 브라우저마다 CORS와 쿠키 정책이 다를 수 있으므로 다양한 브라우저에서 테스트하는 것이 좋습니다.
- 실제 프로덕션 환경에서는 HTTPS를 사용하여 쿠키의 모든 옵션이 제대로 작동하는지 확인해야 합니다.