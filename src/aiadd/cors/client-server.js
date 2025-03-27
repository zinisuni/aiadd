const express = require('express');
const path = require('path');

const app = express();
const PORT = 8080;

// 정적 파일 제공
app.use(express.static(path.join(__dirname)));

// 기본 라우트
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// 서버 시작
app.listen(PORT, () => {
  console.log(`클라이언트 서버가 http://127.0.0.1:${PORT} 에서 실행 중입니다`);
});