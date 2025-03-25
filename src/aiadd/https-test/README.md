# HTTPS 인증서 만료 테스트

이 프로젝트는 인증서가 만료된 HTTPS API에 대한 jQuery AJAX 요청을 테스트하기 위한 환경입니다.

## 기능

- 브라우저에서 직접 HTTPS 요청 (인증서 오류 확인)
- Node.js 프록시 서버를 통한 HTTPS 요청 (인증서 검증 우회)
- 요청 결과 및 오류 정보 확인
- 여러 HTTPS API 테스트 지원
- 다양한 요청 형식 지원 (JSON, form-urlencoded)
- 쿠키 및 세션 포함 요청 지원

## 테스트 대상 API

### 1. TapPay API

```
URL: https://54.180.207.85:60443/mobile/api/internal/tap/getStatus
Method: POST
Headers:
  - API-TRANSACTION-TAPPAY-ARS: 123123123
  - Content-Type: application/json
  - Authorization: Basic dXBsdXNtb2JpbGU6Y2FsbGdhdGUtdGFwcGF5
Body:
  - {"clientToken": "20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330"}
```

### 2. Boinenpay 로그인 API

```
URL: https://dev.boinenpay.com/login
Method: POST
Headers:
  - Content-Type: application/x-www-form-urlencoded; charset=UTF-8
  - Accept: */*
  - Referer: https://dev.boinenpay.com/login
  (및 기타 브라우저 기본 헤더)
Cookie:
  - SESSION=YWMxMGNkNmUtNmNmNC00ZWNlLThiNDgtMTU4NWVjN2E1ZDU0
Body (form-urlencoded):
  - id=product&password=gate25!@$
```

## 설치 및 실행

1. 의존성 패키지 설치

```bash
npm install
```

2. 프록시 서버 실행

```bash
npm start
```

3. 브라우저에서 접속

```
http://localhost:3000
```

## 테스트 방법

1. 드롭다운 메뉴에서 테스트할 API를 선택합니다.

2. 요청 방식 선택:
   - jQuery AJAX: 기본 jQuery를 사용한 요청
   - Axios: Axios 라이브러리를 사용한 요청
   - Fetch API: 브라우저 기본 Fetch API를 사용한 요청
   - 프록시 서버: Node.js 프록시 서버를 통한 우회 요청 (가장 안정적)

3. 요청 보내기 버튼 클릭

## 주의사항

브라우저에서 직접 요청 시 다음과 같은 문제가 발생할 수 있습니다:
- 인증서 오류: 만료된 인증서를 사용하는 서버에 대한 요청은 브라우저에서 차단됩니다.
- CORS 오류: 브라우저의 동일 출처 정책으로 인해 직접 요청이 차단될 수 있습니다.
- 쿠키 전송 제한: 브라우저에서는 쿠키 전송에 제약이 있을 수 있습니다.

이러한 문제를 해결하기 위해서는 프록시 서버 방식을 사용하는 것이 가장 효과적입니다.

이 테스트 환경은 개발 및 디버깅 목적으로만 사용해야 합니다. 인증서 검증을 우회하는 방식은 보안상 위험할 수 있으므로 실제 프로덕션 환경에서는 사용하지 마세요.