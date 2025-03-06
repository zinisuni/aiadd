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

### 트러블슈팅

1. localhost 접속 안될 때:
```bash
# 컨테이너 상태 확인
docker-compose ps

# 각 서비스 로그 확인
docker-compose logs nginx
docker-compose logs api
docker-compose logs test-app
docker-compose logs redis
```

2. 일반적인 문제 해결:
- 포트 충돌: 8000, 3000, 6379, 8080 포트가 사용 중인지 확인
- 권한 문제: Docker 권한 확인
- 네트워크 문제: Docker 네트워크 상태 확인

## 테스트

### Playwright 테스트 실행

1. 테스트 환경 설정:
```bash
cd tests
npm install
```

2. 테스트 실행:
```bash
npm test
```

### 수동 테스트 방법

1. 동시 접속 테스트:
- 여러 브라우저 창 또는 시크릿 창으로 http://localhost:8000 접속
- 100명 초과 시 대기열 페이지로 자동 리다이렉트

2. 대기열 동작 확인:
- 대기 인원 수 표시 확인
- 예상 대기 시간 표시 확인
- 진행 상태바 동작 확인
- 자동 새로고침 동작 확인

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