const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');
const https = require('https');
const path = require('path');

const app = express();
const PORT = 3000;

// CORS 설정 - 모든 오리진 허용하는 강화된 설정
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD', 'PATCH'],
  allowedHeaders: ['*'],
  exposedHeaders: ['*'],
  credentials: true,
  maxAge: 86400 // 24시간 캐싱
}));

// 모든 요청에 CORS 헤더 추가 미들웨어
app.use((req, res, next) => {
  // 모든 출처 허용 (더 안전한 프로덕션 환경에서는 특정 도메인으로 제한해야 함)
  res.header('Access-Control-Allow-Origin', '*');

  // 모든 HTTP 메서드 허용
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH');

  // 모든 헤더 허용
  res.header('Access-Control-Allow-Headers', '*');

  // 브라우저에 노출할 헤더
  res.header('Access-Control-Expose-Headers', '*');

  // 인증 정보 허용
  res.header('Access-Control-Allow-Credentials', 'true');

  // 프리플라이트 캐시 시간 (24시간)
  res.header('Access-Control-Max-Age', '86400');

  // OPTIONS 요청에 즉시 응답
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  next();
});

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname)));

// 인증서 검증 무시 설정
const httpsAgent = new https.Agent({
  rejectUnauthorized: false
});

// CORS 헤더 강화 엔드포인트
app.get('/enhance-cors', (req, res) => {
  res.json({
    status: 'success',
    message: 'CORS 헤더 강화가 이미 적용되어 있습니다.',
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Expose-Headers': '*',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Max-Age': '86400'
    }
  });
});

// 프록시 엔드포인트 설정
app.post('/proxy', async (req, res) => {
  try {
    console.log('프록시 요청을 받았습니다:', req.body);

    const {
      url,
      method = 'GET',
      headers = {},
      body,
      cookies = {},
      contentType,
      formData
    } = req.body;

    if (!url) {
      return res.status(400).json({ error: 'URL이 필요합니다.' });
    }

    console.log(`요청 URL: ${url}`);
    console.log(`요청 메서드: ${method}`);
    console.log('요청 헤더:', headers);

    // 요청 데이터 로깅
    if (body) {
      console.log('요청 본문 (JSON):', body);
    }
    if (formData) {
      console.log('요청 폼 데이터:', formData);
    }
    if (Object.keys(cookies).length > 0) {
      console.log('요청 쿠키:', cookies);
    }

    // 쿠키 문자열 생성
    const cookieString = Object.entries(cookies)
      .map(([key, value]) => `${key}=${value}`)
      .join('; ');

    // 헤더에 쿠키 추가
    const requestHeaders = { ...headers };
    if (cookieString) {
      requestHeaders.cookie = cookieString;
    }

    // 요청 본문 준비
    let requestBody;
    if (method !== 'GET') {
      if (contentType === 'application/json' && body) {
        requestBody = JSON.stringify(body);
        requestHeaders['content-type'] = 'application/json';
      } else if (contentType === 'application/x-www-form-urlencoded' && formData) {
        requestBody = formData;
        requestHeaders['content-type'] = 'application/x-www-form-urlencoded; charset=UTF-8';
      }
    }

    console.log('최종 요청 헤더:', requestHeaders);
    if (requestBody) {
      console.log('최종 요청 본문:', requestBody);
    }

    // fetch API를 사용하여 대상 서버에 요청
    const response = await fetch(url, {
      method: method,
      headers: requestHeaders,
      body: method !== 'GET' ? requestBody : undefined,
      agent: httpsAgent, // 인증서 검증 무시
    });

    // 응답 처리
    const contentTypeResponse = response.headers.get('content-type');

    // 응답 상태와 헤더 로깅
    console.log(`응답 상태: ${response.status} ${response.statusText}`);
    console.log('응답 헤더:', [...response.headers.entries()]);

    // 컨텐츠 타입에 따라 응답 처리
    let responseData;
    if (contentTypeResponse && contentTypeResponse.includes('application/json')) {
      responseData = await response.json();
      console.log('JSON 응답:', responseData);
    } else {
      responseData = await response.text();
      console.log('텍스트 응답:', responseData.substring(0, 200) + (responseData.length > 200 ? '...' : ''));

      // JSON 응답인데 Content-Type이 잘못 설정된 경우 처리 시도
      try {
        if (responseData.trim().startsWith('{') || responseData.trim().startsWith('[')) {
          responseData = JSON.parse(responseData);
          console.log('텍스트 응답을 JSON으로 파싱:', responseData);
        }
      } catch (e) {
        console.log('텍스트 응답을 JSON으로 파싱 실패');
      }
    }

    // 응답 쿠키 처리
    const responseCookies = {};
    const setCookieHeaders = response.headers.raw()['set-cookie'];
    if (setCookieHeaders) {
      console.log('응답 쿠키:', setCookieHeaders);
    }

    // 클라이언트에 응답 전송
    return res.status(response.status).json({
      status: response.status,
      statusText: response.statusText,
      headers: Object.fromEntries([...response.headers.entries()]),
      cookies: setCookieHeaders || [],
      data: responseData
    });
  } catch (error) {
    console.error('프록시 요청 에러:', error);

    return res.status(500).json({
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// TapPay 전용 엔드포인트 (클라이언트에서 직접 접근)
app.get('/direct-tap', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>TapPay API 직접 테스트</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        pre { background: #f5f5f5; padding: 10px; border-radius: 4px; overflow: auto; }
        button { padding: 10px 15px; background: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer; }
        .error { color: red; }
        .success { color: green; }
      </style>
    </head>
    <body>
      <h1>TapPay API 직접 테스트</h1>
      <p>이 페이지는 서버에서 직접 TapPay API를 호출하여 CORS 문제를 우회합니다.</p>

      <div>
        <button id="sendRequest">API 호출하기</button>
      </div>

      <h2>결과:</h2>
      <pre id="result">아직 요청하지 않았습니다.</pre>

      <script>
        document.getElementById('sendRequest').addEventListener('click', function() {
          const resultElement = document.getElementById('result');
          resultElement.textContent = '요청 중...';
          resultElement.className = '';

          fetch('/tap/getStatus', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              clientToken: "20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330"
            })
          })
          .then(response => response.json())
          .then(data => {
            resultElement.textContent = JSON.stringify(data, null, 2);
            resultElement.className = 'success';
          })
          .catch(error => {
            resultElement.textContent = '오류 발생: ' + error.message;
            resultElement.className = 'error';
          });
        });
      </script>
    </body>
    </html>
  `);
});

// 바로가기 엔드포인트 - TapPay 직접 호출 (서버 측 호출)
app.get('/call-tap', async (req, res) => {
  try {
    const url = 'https://54.180.207.85:60443/mobile/api/internal/tap/getStatus';

    // 고정된 요청 헤더
    const headers = {
      'API-TRANSACTION-TAPPAY-ARS': '123123123',
      'Content-Type': 'application/json',
      'Authorization': 'Basic dXBsdXNtb2JpbGU6Y2FsbGdhdGUtdGFwcGF5'
    };

    // 요청 본문
    const requestBody = JSON.stringify({
      clientToken: "20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330"
    });

    console.log('서버에서 TapPay API 직접 호출:', { url, headers });

    // 서버에서 직접 API 호출
    const response = await fetch(url, {
      method: 'POST',
      headers: headers,
      body: requestBody,
      agent: httpsAgent // 인증서 검증 무시
    });

    // 응답 처리
    const responseText = await response.text();

    // JSON 파싱 시도
    let responseData;
    try {
      responseData = JSON.parse(responseText);
    } catch (e) {
      responseData = { raw: responseText };
    }

    // 결과 페이지 렌더링
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>TapPay API 호출 결과</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
          pre { background: #f5f5f5; padding: 10px; border-radius: 4px; overflow: auto; }
          .status { padding: 10px; border-radius: 4px; margin-bottom: 20px; }
          .success { background: #e7f7e7; }
          .error { background: #f7e7e7; }
        </style>
      </head>
      <body>
        <h1>TapPay API 호출 결과</h1>

        <div class="status ${response.ok ? 'success' : 'error'}">
          <h2>상태: ${response.status} ${response.statusText}</h2>
        </div>

        <h2>응답 데이터:</h2>
        <pre>${JSON.stringify(responseData, null, 2)}</pre>

        <h2>응답 헤더:</h2>
        <pre>${JSON.stringify(Object.fromEntries([...response.headers.entries()]), null, 2)}</pre>

        <p><a href="/">메인으로 돌아가기</a></p>
      </body>
      </html>
    `);

  } catch (error) {
    console.error('서버 측 API 호출 오류:', error);

    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>TapPay API 호출 오류</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
          .error { background: #f7e7e7; padding: 10px; border-radius: 4px; }
          pre { background: #f5f5f5; padding: 10px; border-radius: 4px; overflow: auto; }
        </style>
      </head>
      <body>
        <h1>TapPay API 호출 오류</h1>

        <div class="error">
          <h2>오류 발생</h2>
          <p>${error.message}</p>
        </div>

        <h2>상세 정보:</h2>
        <pre>${error.stack}</pre>

        <p><a href="/">메인으로 돌아가기</a></p>
      </body>
      </html>
    `);
  }
});

// TapPay 전용 엔드포인트 (POST 요청 처리)
app.post('/tap/getStatus', async (req, res) => {
  try {
    const url = 'https://54.180.207.85:60443/mobile/api/internal/tap/getStatus';

    // 고정된 요청 헤더
    const headers = {
      'API-TRANSACTION-TAPPAY-ARS': '123123123',
      'Content-Type': 'application/json',
      'Authorization': 'Basic dXBsdXNtb2JpbGU6Y2FsbGdhdGUtdGFwcGF5'
    };

    // 클라이언트 토큰 설정 (요청 본문에서 가져오거나 기본값 사용)
    const clientToken = req.body?.clientToken || "20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330";
    const requestBody = JSON.stringify({ clientToken });

    console.log('TapPay API 요청:', { url, headers, body: { clientToken } });

    // TapPay API 직접 호출
    const response = await fetch(url, {
      method: 'POST',
      headers: headers,
      body: requestBody,
      agent: httpsAgent, // 인증서 검증 무시
    });

    // 응답 데이터 추출
    const responseData = await response.text();
    console.log('TapPay API 응답 (텍스트):', responseData);

    // JSON 변환 시도
    let jsonData;
    try {
      jsonData = JSON.parse(responseData);
      console.log('TapPay API 응답 (JSON):', jsonData);
    } catch (e) {
      console.log('TapPay API 응답을 JSON으로 파싱 실패');
      jsonData = { rawResponse: responseData };
    }

    // 클라이언트에 응답
    res.json({
      status: response.status,
      statusText: response.statusText,
      data: jsonData
    });
  } catch (error) {
    console.error('TapPay API 요청 오류:', error);
    res.status(500).json({
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// CORS 디버깅 메시지
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url} - Origin: ${req.headers.origin || '없음'}`);

  // CORS 관련 헤더 디버깅
  const corsHeaders = [
    'origin',
    'access-control-request-method',
    'access-control-request-headers',
    'authorization',
    'content-type',
    'api-transaction-tappay-ars',
  ];

  const corsLog = corsHeaders
    .filter(header => req.headers[header])
    .map(header => `${header}: ${req.headers[header]}`)
    .join('\n');

  if (corsLog) {
    console.log('CORS 관련 헤더:');
    console.log(corsLog);
  }

  next();
});

// 모든 인증서 관련 요청 로깅
app.all('/cert-log', (req, res) => {
  console.log('======== 인증서 로깅 요청 ========');
  console.log('요청 방식:', req.method);
  console.log('요청 헤더:', req.headers);
  console.log('요청 쿠키:', req.cookies);
  console.log('요청 본문:', req.body);
  console.log('요청 쿼리:', req.query);
  console.log('================================');

  res.json({
    status: 'success',
    message: '요청이 서버 로그에 기록되었습니다.',
    receivedHeaders: req.headers,
    receivedBody: req.body,
    receivedQuery: req.query
  });
});

// 모든 경로에 대한 OPTIONS 요청 처리
app.options('*', (req, res) => {
  console.log('OPTIONS 요청 처리:', req.url);

  // CORS 헤더 추가
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH');
  res.header('Access-Control-Allow-Headers', '*');

  // 200 응답 즉시 반환
  res.status(200).end();
});

// 직접 인증서 체크 페이지
app.get('/cert-check', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>인증서 체크 도구</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        button { padding: 10px 15px; background: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer; margin-right: 10px; margin-bottom: 10px; }
        pre { background: #f5f5f5; padding: 10px; border-radius: 4px; overflow: auto; }
        .error { color: red; }
        .success { color: green; }
        .methods { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <h1>인증서 체크 및 우회 도구</h1>

      <div class="methods">
        <button id="checkImage">이미지 로드 테스트</button>
        <button id="checkFetch">Fetch API 테스트</button>
        <button id="checkXhr">XHR 테스트</button>
        <button id="checkForm">Form 테스트</button>
        <button id="checkNoCors">No-CORS 테스트</button>
        <button id="checkIframe">iframe 테스트</button>
        <button id="checkScript">Script 태그 테스트</button>
      </div>

      <h2>결과:</h2>
      <div id="result">결과가 여기에 표시됩니다.</div>

      <script>
        // 결과 영역
        const resultDiv = document.getElementById('result');

        // 결과 표시 함수
        function showResult(html) {
          resultDiv.innerHTML = html;
        }

        // 이미지 로드 테스트
        document.getElementById('checkImage').addEventListener('click', function() {
          showResult('<p>이미지 로드 중...</p>');

          const img = new Image();
          img.onload = function() {
            showResult('<p class="success">이미지 로드 성공</p>');
          };
          img.onerror = function() {
            showResult('<p class="error">이미지 로드 실패 (인증서 오류)</p>');
          };
          img.src = 'https://54.180.207.85:60443/favicon.ico';
        });

        // Fetch API 테스트
        document.getElementById('checkFetch').addEventListener('click', function() {
          showResult('<p>Fetch API 요청 중...</p>');

          fetch('https://54.180.207.85:60443/mobile/api/internal/tap/getStatus', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'API-TRANSACTION-TAPPAY-ARS': '123123123',
              'Authorization': 'Basic dXBsdXNtb2JpbGU6Y2FsbGdhdGUtdGFwcGF5'
            },
            body: JSON.stringify({
              clientToken: "20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330"
            })
          })
          .then(response => response.json())
          .then(data => {
            showResult('<p class="success">Fetch 요청 성공</p><pre>' + JSON.stringify(data, null, 2) + '</pre>');
          })
          .catch(error => {
            showResult('<p class="error">Fetch 요청 실패: ' + error.message + '</p>');
          });
        });

        // XHR 테스트
        document.getElementById('checkXhr').addEventListener('click', function() {
          showResult('<p>XHR 요청 중...</p>');

          const xhr = new XMLHttpRequest();
          xhr.open('POST', 'https://54.180.207.85:60443/mobile/api/internal/tap/getStatus');

          xhr.setRequestHeader('Content-Type', 'application/json');
          xhr.setRequestHeader('API-TRANSACTION-TAPPAY-ARS', '123123123');
          xhr.setRequestHeader('Authorization', 'Basic dXBsdXNtb2JpbGU6Y2FsbGdhdGUtdGFwcGF5');

          xhr.onload = function() {
            showResult('<p class="success">XHR 요청 성공 (상태: ' + xhr.status + ')</p><pre>' + xhr.responseText + '</pre>');
          };

          xhr.onerror = function() {
            showResult('<p class="error">XHR 요청 실패 (상태: ' + xhr.status + ', readyState: ' + xhr.readyState + ')</p>');
          };

          xhr.send(JSON.stringify({
            clientToken: "20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330"
          }));
        });

        // Form 테스트
        document.getElementById('checkForm').addEventListener('click', function() {
          showResult('<p>Form 요청 준비 중...</p>');

          // 숨겨진 iframe 생성
          const iframeName = 'testFrame' + Date.now();
          const iframe = document.createElement('iframe');
          iframe.name = iframeName;
          iframe.style.width = '100%';
          iframe.style.height = '200px';
          iframe.style.border = '1px solid #ddd';

          resultDiv.innerHTML = '';
          resultDiv.appendChild(iframe);
          resultDiv.appendChild(document.createElement('p')).textContent = 'iframe 내에서 요청 결과를 확인하세요.';

          // 폼 생성
          const form = document.createElement('form');
          form.method = 'POST';
          form.action = 'https://54.180.207.85:60443/mobile/api/internal/tap/getStatus';
          form.target = iframeName;
          form.enctype = 'text/plain';

          // 입력 필드 추가
          const input = document.createElement('input');
          input.type = 'hidden';
          input.name = '{"clientToken"';
          input.value = ':"20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330"}';

          form.appendChild(input);
          document.body.appendChild(form);

          // 폼 제출
          form.submit();

          // 폼 제거
          setTimeout(() => {
            document.body.removeChild(form);
          }, 1000);
        });

        // No-CORS 테스트
        document.getElementById('checkNoCors').addEventListener('click', function() {
          showResult('<p>No-CORS 요청 중...</p>');

          fetch('https://54.180.207.85:60443/mobile/api/internal/tap/getStatus', {
            method: 'POST',
            mode: 'no-cors',
            headers: {
              'Content-Type': 'application/json',
              'API-TRANSACTION-TAPPAY-ARS': '123123123',
              'Authorization': 'Basic dXBsdXNtb2JpbGU6Y2FsbGdhdGUtdGFwcGF5'
            },
            body: JSON.stringify({
              clientToken: "20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330"
            })
          })
          .then(response => {
            showResult('<p class="success">No-CORS 요청이 완료되었습니다 (응답 타입: ' + response.type + ')</p>' +
              '<p>참고: no-cors 모드에서는 응답 내용에 접근할 수 없습니다.</p>');
          })
          .catch(error => {
            showResult('<p class="error">No-CORS 요청 실패: ' + error.message + '</p>');
          });
        });

        // iframe 테스트
        document.getElementById('checkIframe').addEventListener('click', function() {
          showResult('<p>iframe 생성 중...</p>');

          const iframe = document.createElement('iframe');
          iframe.style.width = '100%';
          iframe.style.height = '200px';
          iframe.style.border = '1px solid #ddd';

          // 보안 오류가 발생할 것이라는 메시지 추가
          iframe.onload = function() {
            console.log('iframe 로드됨');
          };

          iframe.onerror = function() {
            console.log('iframe 오류 발생');
          };

          iframe.src = 'https://54.180.207.85:60443/mobile/api/internal/tap/getStatus';

          resultDiv.innerHTML = '';
          resultDiv.appendChild(iframe);
          resultDiv.appendChild(document.createElement('p')).textContent = '※ 대부분의 경우 인증서 오류로 인해 페이지가 로드되지 않습니다.';
        });

        // Script 태그 테스트
        document.getElementById('checkScript').addEventListener('click', function() {
          showResult('<p>Script 태그 로드 중...</p>');

          // JSONP와 유사한 방식으로 시도
          window.scriptCallback = function(data) {
            showResult('<p class="success">Script 로드 성공, 콜백 호출됨</p><pre>' + JSON.stringify(data, null, 2) + '</pre>');
          };

          const script = document.createElement('script');
          script.src = 'https://54.180.207.85:60443/mobile/api/internal/tap/getStatus?callback=scriptCallback';

          script.onload = function() {
            const p = document.createElement('p');
            p.className = 'success';
            p.textContent = 'Script 태그가 로드되었습니다';
            resultDiv.appendChild(p);
          };

          script.onerror = function() {
            showResult('<p class="error">Script 태그 로드 실패 (인증서 오류)</p>');
          };

          document.body.appendChild(script);

          // 스크립트 제거
          setTimeout(() => {
            if (script.parentNode) {
              document.body.removeChild(script);
            }
          }, 5000);
        });
      </script>
    </body>
    </html>
  `);
});

// 홈페이지에 새 기능 링크 추가
app.get('/', (req, res, next) => {
  if (req.url === '/' && !req.originalUrl.includes('.')) {
    const homepageWithLinks = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>인증서 만료 테스트 도구</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
          .links { display: flex; flex-direction: column; gap: 10px; margin: 20px 0; }
          .link { display: block; padding: 10px 15px; background: #f5f5f5; border-radius: 4px; text-decoration: none; color: #333; }
          .link:hover { background: #e5e5e5; }
          .main-link { background: #4CAF50; color: white; font-weight: bold; }
          .main-link:hover { background: #45a049; }
          h1 { border-bottom: 1px solid #ddd; padding-bottom: 10px; }
        </style>
      </head>
      <body>
        <h1>인증서 만료 테스트 도구</h1>

        <div class="links">
          <a href="/index.html" class="link main-link">HTTPS 인증서 만료 테스트 (메인 페이지)</a>
          <a href="/call-tap" class="link">서버에서 직접 API 호출</a>
          <a href="/direct-tap" class="link">테스트 페이지</a>
          <a href="/cert-check" class="link">인증서 체크 도구</a>
          <a href="/enhance-cors" class="link">CORS 헤더 강화</a>
        </div>

        <p>위 링크 중 하나를 선택하여 테스트를 진행하세요.</p>
      </body>
      </html>
    `;
    return res.send(homepageWithLinks);
  }
  next();
});

// JSONP 스타일 엔드포인트 - GET 요청으로 스크립트 형태로 응답 제공
app.get('/jsonp-tap', (req, res) => {
  const callback = req.query.callback || 'callback';
  const clientToken = req.query.clientToken || "20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330";

  console.log('JSONP 요청:', { callback, clientToken });

  // 인증서 검증 없이 TapPay API 호출
  (async () => {
    try {
      const response = await fetch('https://54.180.207.85:60443/mobile/api/internal/tap/getStatus', {
        method: 'POST',
        headers: {
          'API-TRANSACTION-TAPPAY-ARS': '123123123',
          'Content-Type': 'application/json',
          'Authorization': 'Basic dXBsdXNtb2JpbGU6Y2FsbGdhdGUtdGFwcGF5'
        },
        body: JSON.stringify({ clientToken }),
        agent: httpsAgent
      });

      const responseText = await response.text();
      let jsonData;

      try {
        jsonData = JSON.parse(responseText);
      } catch (e) {
        jsonData = { raw: responseText, error: 'JSON 파싱 오류' };
      }

      // JSONP 형식으로 응답
      res.set('Content-Type', 'application/javascript');
      res.send(`${callback}(${JSON.stringify({
        status: response.status,
        statusText: response.statusText,
        data: jsonData
      })})`);

    } catch (error) {
      // 오류 발생시 콜백으로 오류 전달
      res.set('Content-Type', 'application/javascript');
      res.send(`${callback}(${JSON.stringify({
        error: error.message
      })})`);
    }
  })();
});

// IMG 비콘 요청 처리 (1x1 투명 픽셀 반환)
app.get('/beacon-tap', async (req, res) => {
  const clientToken = req.query.clientToken || "20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330";

  console.log('이미지 비콘 요청:', { clientToken });

  // 백그라운드에서 API 호출 (결과는 로그로만 확인)
  (async () => {
    try {
      const response = await fetch('https://54.180.207.85:60443/mobile/api/internal/tap/getStatus', {
        method: 'POST',
        headers: {
          'API-TRANSACTION-TAPPAY-ARS': '123123123',
          'Content-Type': 'application/json',
          'Authorization': 'Basic dXBsdXNtb2JpbGU6Y2FsbGdhdGUtdGFwcGF5'
        },
        body: JSON.stringify({ clientToken }),
        agent: httpsAgent
      });

      const responseText = await response.text();
      console.log('비콘 요청 응답:', responseText);
    } catch (error) {
      console.error('비콘 요청 오류:', error);
    }
  })();

  // 1x1 투명 GIF 반환 (비콘)
  const pixel = Buffer.from('R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==', 'base64');
  res.set('Content-Type', 'image/gif');
  res.send(pixel);
});

// 고급 우회 테스트 페이지
app.get('/advanced-bypass', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>고급 CORS 및 인증서 우회 테스트</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        button { padding: 10px 15px; background: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer; margin-right: 10px; margin-bottom: 10px; }
        pre { background: #f5f5f5; padding: 10px; border-radius: 4px; overflow: auto; }
        .error { color: red; }
        .success { color: green; }
        .methods { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <h1>고급 CORS 및 인증서 우회 테스트</h1>
      <p>프리플라이트 검사 없이 AJAX 요청을 시도하는 방법들입니다.</p>

      <div class="methods">
        <button id="jsonpTest">JSONP 요청</button>
        <button id="beaconTest">이미지 비콘 요청</button>
        <button id="formPostTest">폼 POST 요청</button>
        <button id="simpleFetchTest">단순 Fetch 요청</button>
        <button id="iframePostTest">iframe POST 메시지</button>
      </div>

      <h2>결과:</h2>
      <div id="result">결과가 여기에 표시됩니다.</div>

      <script>
        // 결과 표시 함수
        function showResult(html) {
          document.getElementById('result').innerHTML = html;
        }

        // JSONP 테스트
        document.getElementById('jsonpTest').addEventListener('click', function() {
          showResult('<p>JSONP 요청 중...</p>');

          // 콜백 함수 정의
          window.jsonpCallback = function(data) {
            showResult('<p class="success">JSONP 응답 받음!</p><pre>' + JSON.stringify(data, null, 2) + '</pre>');
          };

          // 스크립트 태그 생성 및 추가
          const script = document.createElement('script');
          script.src = '/jsonp-tap?callback=jsonpCallback&clientToken=20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330';
          document.body.appendChild(script);

          // 일정 시간 후 스크립트 태그 제거
          setTimeout(() => {
            document.body.removeChild(script);
          }, 5000);
        });

        // 이미지 비콘 테스트
        document.getElementById('beaconTest').addEventListener('click', function() {
          showResult('<p>이미지 비콘 요청 중...</p>');

          const img = new Image();
          img.onload = function() {
            showResult('<p class="success">비콘 이미지 로드됨!</p><p>서버 로그에서 응답을 확인하세요.</p>');
          };
          img.onerror = function() {
            showResult('<p class="error">비콘 이미지 로드 실패</p>');
          };
          img.src = '/beacon-tap?clientToken=20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330&t=' + new Date().getTime();
        });

        // 폼 POST 테스트
        document.getElementById('formPostTest').addEventListener('click', function() {
          showResult('<p>폼 POST 요청 준비 중...</p>');

          // 히든 iframe 생성
          const iframeId = 'hiddenIframe' + Date.now();
          const iframe = document.createElement('iframe');
          iframe.id = iframeId;
          iframe.name = iframeId;
          iframe.style.width = '100%';
          iframe.style.height = '150px';
          iframe.style.border = '1px solid #ddd';

          document.getElementById('result').innerHTML = '';
          document.getElementById('result').appendChild(iframe);
          document.getElementById('result').appendChild(document.createElement('p')).textContent =
            '폼 POST 요청 결과는 iframe에 표시됩니다 (인증서 오류로 빈 화면이 표시될 수 있습니다).';

          // 폼 생성
          const form = document.createElement('form');
          form.method = 'POST';
          form.target = iframeId;
          form.action = '/tap/getStatus'; // 서버에서 처리되는 엔드포인트

          // 입력 필드 추가
          const input = document.createElement('input');
          input.type = 'hidden';
          input.name = 'clientToken';
          input.value = '20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330';

          form.appendChild(input);
          document.body.appendChild(form);

          // 폼 제출
          form.submit();

          // 폼 제거
          setTimeout(() => {
            document.body.removeChild(form);
          }, 1000);
        });

        // 단순 Fetch 요청
        document.getElementById('simpleFetchTest').addEventListener('click', function() {
          showResult('<p>단순 Fetch 요청 중...</p>');

          // text/plain 콘텐츠 타입으로 제한 (프리플라이트 없는 단순 요청)
          fetch('/tap/getStatus', {
            method: 'POST',
            headers: {
              'Content-Type': 'text/plain'
            },
            body: JSON.stringify({
              clientToken: '20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330'
            })
          })
          .then(response => response.json())
          .then(data => {
            showResult('<p class="success">단순 Fetch 요청 성공!</p><pre>' + JSON.stringify(data, null, 2) + '</pre>');
          })
          .catch(error => {
            showResult('<p class="error">단순 Fetch 요청 실패: ' + error.message + '</p>');
          });
        });

        // iframe POST 메시지
        document.getElementById('iframePostTest').addEventListener('click', function() {
          showResult('<p>iframe POST 메시지 테스트 중...</p>');

          // iframe 생성
          const iframe = document.createElement('iframe');
          iframe.style.width = '0';
          iframe.style.height = '0';
          iframe.style.border = 'none';
          iframe.style.display = 'none';

          // 메시지 수신 리스너
          window.addEventListener('message', function(event) {
            // 보안상의 이유로 출처 확인이 중요하지만, 여기서는 생략
            showResult('<p class="success">iframe으로부터 메시지 수신!</p><pre>' + JSON.stringify(event.data, null, 2) + '</pre>');
          }, { once: true });

          // iframe 로드 이벤트
          iframe.onload = function() {
            try {
              // iframe 내의 페이지로 메시지 전송 시도
              iframe.contentWindow.postMessage({
                clientToken: '20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330'
              }, '*');

              document.getElementById('result').innerHTML += '<p>iframe에 메시지를 전송했습니다. 응답을 기다리는 중...</p>';
            } catch(e) {
              document.getElementById('result').innerHTML += '<p class="error">iframe 접근 오류: ' + e.message + '</p>';
            }
          };

          // iframe 소스 설정 및 추가
          iframe.src = '/tap-iframe.html';
          document.body.appendChild(iframe);

          // 타임아웃 설정 및 정리
          setTimeout(() => {
            document.getElementById('result').innerHTML += '<p>10초 타임아웃 - 응답이 없습니다. 보안 제한으로 iframe 통신이 차단되었을 수 있습니다.</p>';
            document.body.removeChild(iframe);
          }, 10000);
        });
      </script>
    </body>
    </html>
  `);
});

// iframe 통신용 페이지
app.get('/tap-iframe.html', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Tap API iframe</title>
    </head>
    <body>
      <script>
        // 부모 창에서 메시지 수신
        window.addEventListener('message', function(event) {
          // 보안상의 이유로 출처 확인이 중요하지만, 테스트이므로 생략
          const clientToken = event.data.clientToken || "20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330";

          // 서버 엔드포인트로 요청
          fetch('/tap/getStatus', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({ clientToken })
          })
          .then(response => response.json())
          .then(data => {
            // 부모 창으로 결과 전송
            event.source.postMessage(data, event.origin);
          })
          .catch(error => {
            // 오류 발생시 부모 창에 알림
            event.source.postMessage({ error: error.message }, event.origin);
          });
        });
      </script>
    </body>
    </html>
  `);
});

// 서버 측에서 text/plain 요청 처리 로직 추가
app.use((req, res, next) => {
  const contentType = req.get('Content-Type');

  if (contentType && contentType.includes('text/plain') && req.method === 'POST') {
    let data = '';

    req.on('data', chunk => {
      data += chunk.toString();
    });

    req.on('end', () => {
      try {
        // text/plain으로 받은 JSON 문자열을 파싱
        req.body = JSON.parse(data);
        next();
      } catch (e) {
        console.error('text/plain 데이터 파싱 오류:', e);
        req.body = { rawText: data };
        next();
      }
    });
  } else {
    next();
  }
});

// 서버 시작
app.listen(PORT, () => {
  console.log(`프록시 서버가 http://localhost:${PORT}에서 실행 중입니다.`);
  console.log(`브라우저에서 http://localhost:${PORT}로 접속하여 테스트하세요.`);
  console.log(`CORS 강화 설정이 적용되었습니다.`);
  console.log(`TapPay 전용 엔드포인트: http://localhost:${PORT}/tap/getStatus`);
  console.log(`TapPay 바로 호출: http://localhost:${PORT}/call-tap`);
  console.log(`TapPay 직접 테스트: http://localhost:${PORT}/direct-tap`);
});