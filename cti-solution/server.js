require('dotenv').config();
const express = require('express');
const VoiceResponse = require('twilio').twiml.VoiceResponse;
const app = express();

app.use(express.urlencoded({ extended: false }));

// 전화 수신 시 처리할 엔드포인트
app.post('/voice', (req, res) => {
  const twiml = new VoiceResponse();

  // 간단한 시나리오: 인사말 재생 후 메시지 남기기
  twiml.say({ language: 'ko-KR' }, '안녕하세요. CTI 시스템입니다.');
  twiml.pause({ length: 1 });
  twiml.say({ language: 'ko-KR' }, '잠시만 기다려주세요.');

  res.type('text/xml');
  res.send(twiml.toString());
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});