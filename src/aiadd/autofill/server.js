const https = require('https');
const fs = require('fs');
const path = require('path');

// 자체 서명 인증서 옵션
const options = {
  key: fs.readFileSync(path.join(__dirname, 'key.pem')),
  cert: fs.readFileSync(path.join(__dirname, 'cert.pem'))
};

// 요청 핸들러
const server = https.createServer(options, (req, res) => {
  // URL 파싱
  const url = req.url === '/' ? '/readme.html' : req.url;
  const filePath = path.join(__dirname, url);
  const extname = String(path.extname(filePath)).toLowerCase();

  // MIME 타입 설정
  const mimeTypes = {
    '.html': 'text/html',
    '.js': 'text/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpg',
    '.gif': 'image/gif'
  };

  const contentType = mimeTypes[extname] || 'application/octet-stream';

  // 파일 읽기
  fs.readFile(filePath, (error, content) => {
    if (error) {
      if(error.code == 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end('404 Not Found');
      } else {
        res.writeHead(500);
        res.end(`서버 오류: ${error.code}`);
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

// 서버 시작
const PORT = 3000;
server.listen(PORT, () => {
  console.log(`서버가 https://localhost:${PORT}/ 에서 실행 중입니다.`);
  console.log(`readme.html을 보려면 https://localhost:${PORT}/readme.html 로 접속하세요.`);
});