const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const path = require('path');

// 메인 API 서버 (성공 케이스용)
const mainApp = express();
const PORT = 3000;

// CORS 비허용 서버 (실패 케이스용)
const restrictedApp = express();
const RESTRICTED_PORT = 3001;

// 공통 미들웨어 설정
[mainApp, restrictedApp].forEach(app => {
  app.use(cookieParser());
  app.use(express.json());
});

// 정적 파일 제공
mainApp.use(express.static(path.join(__dirname)));

// 성공 케이스용 CORS 설정 (credentials: true)
const corsOptionsSuccess = {
  origin: ['http://127.0.0.1:8080', 'http://localhost:8080'], // 클라이언트 서버 주소
  credentials: true, // 쿠키 포함 허용
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

// 실패 케이스용 CORS 설정 (credentials: false)
const corsOptionsFailure = {
  origin: ['http://127.0.0.1:8080', 'http://localhost:8080'], // 클라이언트 서버 주소
  credentials: false, // 쿠키 포함 차단
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

// 메인 서버에 CORS 적용 (성공 케이스)
mainApp.use(cors(corsOptionsSuccess));

// 제한 서버에 CORS 적용 (실패 케이스)
restrictedApp.use(cors(corsOptionsFailure));

// === 메인 서버(포트:3000) 라우트 ===

// 쿠키 설정 엔드포인트
mainApp.get('/set-cookie', (req, res) => {
  // SameSite=None과 Secure 옵션 설정
  res.cookie('testCookie', 'hello-cors', {
    maxAge: 900000,
    httpOnly: true,
    sameSite: 'none',
    secure: true, // HTTPS 필요 (개발 환경에서는 주의 필요)
  });

  // 로컬 개발에서 테스트용 (SameSite=lax)
  res.cookie('localTestCookie', 'local-test', {
    maxAge: 900000,
    httpOnly: true,
    sameSite: 'lax'
  });

  // SameSite=strict 쿠키 추가 (크로스 사이트에서 전송 안됨)
  res.cookie('strictCookie', 'strict-mode', {
    maxAge: 900000,
    httpOnly: true,
    sameSite: 'strict'
  });

  res.json({
    message: '쿠키가 설정되었습니다',
    cookies: {
      testCookie: 'SameSite=None, Secure (HTTPS 필요)',
      localTestCookie: 'SameSite=Lax (일부 크로스 사이트 요청에서 전송 가능)',
      strictCookie: 'SameSite=Strict (동일 사이트 요청에서만 전송 가능)'
    }
  });
});

// 쿠키 삭제 엔드포인트
mainApp.get('/clear-cookie', (req, res) => {
  res.clearCookie('testCookie');
  res.clearCookie('localTestCookie');
  res.clearCookie('strictCookie');
  res.json({ message: '쿠키가 삭제되었습니다' });
});

// API 데이터 엔드포인트 (credentials: true - 성공 케이스)
mainApp.get('/api/data', (req, res) => {
  // 쿠키 확인
  const cookies = req.cookies;

  res.json({
    message: 'API 데이터 요청 성공 (credentials: true)',
    server: 'main-server (포트:3000)',
    corsSettings: 'credentials:true 허용',
    cookies: cookies,
    cookiesReceived: Object.keys(cookies).length > 0,
    time: new Date().toISOString()
  });
});

// === 제한 서버(포트:3001) 라우트 ===

// 동일한 쿠키 설정 엔드포인트
restrictedApp.get('/set-cookie', (req, res) => {
  // SameSite=None과 Secure 옵션 설정
  res.cookie('testCookie', 'hello-cors-restricted', {
    maxAge: 900000,
    httpOnly: true,
    sameSite: 'none',
    secure: true,
  });

  res.cookie('localTestCookie', 'local-test-restricted', {
    maxAge: 900000,
    httpOnly: true,
    sameSite: 'lax'
  });

  res.json({
    message: '제한 서버에서 쿠키가 설정되었습니다',
    server: 'restricted-server (포트:3001)',
    corsSettings: 'credentials:false 설정'
  });
});

// API 데이터 엔드포인트 (credentials: false - 실패 케이스)
restrictedApp.get('/api/data', (req, res) => {
  const cookies = req.cookies;

  res.json({
    message: 'API 데이터 요청 (credentials: false)',
    server: 'restricted-server (포트:3001)',
    corsSettings: 'credentials:false 설정',
    cookies: cookies,
    cookiesReceived: Object.keys(cookies).length > 0,
    time: new Date().toISOString()
  });
});

// 서버 시작
mainApp.listen(PORT, () => {
  console.log(`메인 서버(성공 케이스)가 http://localhost:${PORT} 에서 실행 중입니다`);
  console.log(`CORS가 허용된 클라이언트: ${JSON.stringify(corsOptionsSuccess.origin)}`);
  console.log(`CORS credentials 설정: ${corsOptionsSuccess.credentials}`);
});

restrictedApp.listen(RESTRICTED_PORT, () => {
  console.log(`제한 서버(실패 케이스)가 http://localhost:${RESTRICTED_PORT} 에서 실행 중입니다`);
  console.log(`CORS가 허용된 클라이언트: ${JSON.stringify(corsOptionsFailure.origin)}`);
  console.log(`CORS credentials 설정: ${corsOptionsFailure.credentials}`);
});