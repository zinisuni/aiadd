# Nginx Queue System (대기열 시스템)

트래픽이 폭주할 때 대기열을 통해 서버 부하를 관리하는 시스템입니다.

## 시스템 구성

- Nginx (OpenResty): 트래픽 제어 및 대기열 관리
- Node.js API: 대기열 상태 관리
- Redis: 세션 및 대기열 데이터 저장
- Test App: 테스트용 웹 애플리케이션

## 설치 및 실행

### 요구사항

- Docker
- Docker Compose
- Node.js 18 이상 (테스트용)

### 실행 방법

1. 시스템 실행:
```bash
docker-compose up --build
```

2. 서비스 접속:
- 메인 서비스: http://localhost:8000
- API 서버: http://localhost:8000/api/queue/status
- 테스트 앱: http://localhost:8080

## 테스트

### Playwright 테스트 실행

1. 테스트 환경 설정:
```bash
cd tests
npm install
npx playwright install  # Playwright 브라우저 설치
```

2. 테스트 실행 방법:
```bash
# 전체 테스트 실행
npm test

# UI 모드로 테스트 실행 (브라우저 표시)
npm run test:headed

# 디버그 모드로 테스트 실행
npm run test:debug
```

3. 동시 접속 테스트:
```bash
# 특정 테스트만 실행
npm test -- tests/queue.spec.ts

# 특정 테스트 케이스만 실행
npm test -- -g "should redirect to waiting page when over capacity"
```

4. 테스트 결과 확인:
- 테스트 실행 후 `playwright-report` 디렉토리에서 HTML 리포트 확인
- `test-results` 디렉토리에서 실패한 테스트의 스크린샷과 트레이스 확인

### 테스트 시나리오

1. 동시 접속 테스트:
- 100명 이하 접속 시 메인 페이지 표시
- 100명 초과 접속 시 대기 페이지로 리다이렉트
- 대기열 정보 표시 (대기 인원, 예상 시간)
- 순서가 되면 자동으로 메인 페이지로 이동

2. 대기열 동작 테스트:
- 대기열 상태 자동 업데이트
- 진행 상태바 동작
- 예상 대기 시간 계산
- 대기열 순서 관리

### 테스트 커스터마이징

`tests/playwright.config.ts` 파일에서 다음 설정을 변경할 수 있습니다:

```typescript
{
  // 병렬 실행 설정
  workers: process.env.CI ? 1 : undefined,

  // 재시도 횟수
  retries: process.env.CI ? 2 : 0,

  // 타임아웃 설정
  timeout: 120 * 1000,

  // 테스트할 브라우저 설정
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
}
```

### 트러블슈팅

1. 테스트 실패 시:
```bash
# 상세 로그 확인
npm test -- --debug

# 특정 브라우저만 테스트
npm test -- --project=chromium
```

2. 일반적인 문제 해결:
- 포트 충돌: 8000, 3000, 6379, 8080 포트가 사용 중인지 확인
- 권한 문제: Docker 권한 확인
- 네트워크 문제: Docker 네트워크 상태 확인

## 환경 설정

### 환경 변수

- `MAX_CONCURRENT_USERS`: 최대 동시 접속자 수 (기본값: 100)
- `ESTIMATED_SESSION_TIME`: 예상 세션 시간(초) (기본값: 300)
- `PORT`: API 서버 포트 (기본값: 3000)
- `REDIS_URL`: Redis 연결 URL

### Nginx 설정

- `nginx/nginx.conf`: Nginx 설정 파일
- 주요 설정:
  - 동시 접속 제한
  - 대기열 리다이렉션
  - API 프록시
  - Redis 연동