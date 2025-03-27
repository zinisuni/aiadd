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

## 주요 포인트

### 클라이언트 측 설정

```javascript
// credentials 포함 요청
fetch('http://localhost:3000/api/data', {
  method: 'GET',
  credentials: 'include'  // 중요: 쿠키를 포함하려면 이 옵션 필요
});
```

### 서버 측 설정

```javascript
// CORS 설정
const corsOptions = {
  origin: 'http://127.0.0.1:8080',  // 클라이언트 도메인 명시
  credentials: true,  // 중요: 인증 정보 허용
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

// 쿠키 설정
res.cookie('testCookie', 'hello-cors', {
  maxAge: 900000,
  httpOnly: true,
  sameSite: 'none',  // 중요: 크로스 사이트 요청에는 'none' 필요
  secure: true,      // 중요: SameSite=None 사용 시 필수
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

## SameSite 속성 설명

쿠키의 SameSite 속성은 크로스 사이트 요청에서 쿠키 전송 여부를 결정합니다:

- `SameSite=Strict`: 동일 사이트 요청에만 쿠키 전송
- `SameSite=Lax`: 동일 사이트 + 상위 레벨 탐색(링크 클릭 등)에 쿠키 전송
- `SameSite=None`: 모든 크로스 사이트 요청에 쿠키 전송 (반드시 `Secure` 속성과 함께 사용)

## 주의사항

- `SameSite=None`은 HTTPS(Secure)가 필요합니다. 로컬 개발 환경에서는 이 제약으로 인해 제대로 작동하지 않을 수 있습니다.
- 브라우저마다 CORS와 쿠키 정책이 다를 수 있으므로 다양한 브라우저에서 테스트하는 것이 좋습니다.