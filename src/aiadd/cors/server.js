const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const path = require('path');

const app = express();
const PORT = 3000;

// 기본 미들웨어 설정
app.use(cookieParser());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// CORS 설정
const corsOptions = {
  origin: 'http://127.0.0.1:8080', // 클라이언트 서버 주소
  credentials: true, // 쿠키 포함 허용
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));

// 쿠키 설정 엔드포인트
app.get('/set-cookie', (req, res) => {
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

  res.json({ message: '쿠키가 설정되었습니다' });
});

// 쿠키 삭제 엔드포인트
app.get('/clear-cookie', (req, res) => {
  res.clearCookie('testCookie');
  res.clearCookie('localTestCookie');
  res.json({ message: '쿠키가 삭제되었습니다' });
});

// API 데이터 엔드포인트
app.get('/api/data', (req, res) => {
  // 쿠키 확인
  const cookies = req.cookies;

  res.json({
    message: 'API 데이터 요청 성공',
    cookies: cookies,
    time: new Date().toISOString()
  });
});

// 서버 시작
app.listen(PORT, () => {
  console.log(`서버가 http://localhost:${PORT} 에서 실행 중입니다`);
  console.log(`CORS가 허용된 클라이언트: ${corsOptions.origin}`);
});