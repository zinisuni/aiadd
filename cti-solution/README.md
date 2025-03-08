# CTI 솔루션 프로젝트

## 프로젝트 구조
```
cti-solution/
├── src/              # 소스 코드
│   ├── server/       # 백엔드 서버 코드
│   ├── client/       # 프론트엔드 코드
│   └── lib/          # 공통 라이브러리
├── docs/             # 문서
│   ├── api/          # API 문서
│   ├── setup/        # 설치 가이드
│   └── design/       # 설계 문서
├── config/           # 설정 파일
│   ├── dev/          # 개발 환경 설정
│   └── prod/         # 운영 환경 설정
└── scripts/          # 유틸리티 스크립트
    ├── setup/        # 환경 설정 스크립트
    └── deploy/       # 배포 스크립트
```

## 기술 스택
- 백엔드: Node.js + Express
- 프론트엔드: React + TypeScript
- 데이터베이스: PostgreSQL
- 캐시: Redis
- 통신: WebSocket + WebRTC

## 주요 기능
1. 실시간 음성/영상 통화
2. 통화 녹음/녹화
3. 통화 품질 모니터링
4. 통계 및 리포팅
5. 사용자 관리

## 개발 환경 설정
1. 필수 요구사항
   - Node.js 18 이상
   - PostgreSQL 14 이상
   - Redis 6 이상

2. 설치 및 실행
   ```bash
   # 저장소 복제
   git clone [repository-url]
   cd cti-solution

   # 의존성 설치
   npm install

   # 개발 서버 실행
   npm run dev
   ```

## 배포 가이드
1. 환경 변수 설정
   ```bash
   cp config/dev/.env.example config/prod/.env
   # .env 파일 수정
   ```

2. 배포 스크립트 실행
   ```bash
   ./scripts/deploy/production.sh
   ```

## 문서
- [API 문서](docs/api/README.md)
- [설치 가이드](docs/setup/README.md)
- [아키텍처 설계](docs/design/architecture.md)

## 라이선스
MIT License