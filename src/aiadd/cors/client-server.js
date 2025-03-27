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

// 서버 시작 (명시적으로 localhost에 바인딩)
app.listen(PORT, 'localhost', () => {
  console.log(`클라이언트 서버가 http://localhost:${PORT} 에서 실행 중입니다`);
  console.log(`* 중요: 브라우저에서 localhost로 접속하세요. (127.0.0.1로 접속 시 CORS 오류가 발생할 수 있습니다.)`);
});