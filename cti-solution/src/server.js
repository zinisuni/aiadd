/**
 * Asterisk CTI 시스템 - AGI 서버
 *
 * 이 서버는 다음 두 가지 주요 기능을 제공합니다:
 * 1. AGI(Asterisk Gateway Interface) 서버: 통화 처리 로직
 * 2. 웹 서버: 상태 모니터링 및 아웃바운드 콜 API
 */

const AGI = require('agi-node');
const express = require('express');
const ami = require('asterisk-manager');
const app = express();

// JSON 요청 처리를 위한 미들웨어
app.use(express.json());

// AGI 서버 설정
const agiServer = new AGI();

// AMI(Asterisk Manager Interface) 연결 설정
const manager = new ami(5038, 'asterisk', process.env.AMI_USERNAME || 'admin', process.env.AMI_PASSWORD || 'password');

/**
 * AGI 연결 핸들러
 * 모든 수신 통화에 대한 처리 로직을 정의합니다.
 */
agiServer.on('connection', async (agi) => {
  console.log('새로운 통화 수신:', new Date().toISOString());

  try {
    // 1. 통화 응답
    await agi.answer();
    console.log('통화 응답 완료');

    // 2. 환영 메시지 재생
    await agi.streamFile('welcome');
    console.log('환영 메시지 재생 완료');

    // 3. 사용자 입력 대기 (3초)
    await agi.waitForDigit(3000);
    console.log('사용자 입력 대기 완료');

    // 4. 메뉴 안내 재생
    await agi.streamFile('menu');
    console.log('메뉴 안내 재생 완료');

    // 5. 사용자 선택 입력 받기 (최대 5초 대기, 1자리 입력)
    const { result } = await agi.getData('custom/enter-option', 5000, 1);
    console.log('사용자 선택:', result);

    // 6. 사용자 선택에 따른 처리
    if (result === '1') {
      // 상담원 연결
      await agi.streamFile('transfer-to-agent');
      await agi.exec('Dial', 'SIP/agent-extension');
      console.log('상담원 연결 시도');
    } else if (result === '2') {
      // 자동 안내 서비스
      await agi.streamFile('auto-service');
      console.log('자동 안내 서비스 실행');
    } else {
      // 잘못된 입력
      await agi.streamFile('invalid-option');
      await agi.hangup();
      console.log('잘못된 입력으로 통화 종료');
    }
  } catch (err) {
    console.error('통화 처리 중 오류 발생:', err);
    await agi.hangup();
  }
});

/**
 * 상태 확인 엔드포인트
 * 서버의 정상 작동 여부를 확인합니다.
 */
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

/**
 * 아웃바운드 콜 API
 * 외부로 발신 통화를 시도합니다.
 *
 * @param {string} number - 발신할 전화번호
 * @param {string} agent - 상담원 내선번호
 */
app.post('/api/call/outbound', async (req, res) => {
  const { number, agent } = req.body;

  if (!number || !agent) {
    return res.status(400).json({
      error: '전화번호와 상담원 번호가 필요합니다.'
    });
  }

  try {
    // Asterisk로 발신 요청
    await manager.action({
      action: 'Originate',
      channel: `SIP/${number}@trunk-provider`,
      context: 'from-internal',
      exten: agent,
      priority: 1,
      callerid: `${number} <${number}>`
    });

    console.log(`발신 요청 성공: ${number} -> ${agent}`);
    res.json({ success: true });
  } catch (error) {
    console.error('발신 요청 실패:', error);
    res.status(500).json({ error: error.message });
  }
});

// AGI 서버 시작
agiServer.listen(4573, () => {
  console.log('AGI 서버 시작됨 - 포트: 4573');
});

// 웹 서버 시작
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`웹 서버 시작됨 - 포트: ${PORT}`);
});