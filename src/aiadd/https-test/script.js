$(document).ready(function() {
  // API 정보 설정
  const apiConfigs = {
    tappay: {
      url: 'https://54.180.207.85:60443/mobile/api/internal/tap/getStatus',
      method: 'POST',
      headers: {
        'API-TRANSACTION-TAPPAY-ARS': '123123123',
        'Content-Type': 'application/json',
        'Authorization': 'Basic dXBsdXNtb2JpbGU6Y2FsbGdhdGUtdGFwcGF5'
      },
      body: {
        clientToken: '20250305100553-5O2aPtZmFvsn-4201AC1F5DEE529A75302330'
      },
      contentType: 'application/json'
    },
    'boinenpay-post': {
      url: 'https://dev.boinenpay.com/login',
      method: 'POST',
      headers: {
        'accept': '*/*',
        'accept-language': 'ko,en-US;q=0.9,en;q=0.8',
        'cache-control': 'no-cache',
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'origin': 'https://dev.boinenpay.com',
        'pragma': 'no-cache',
        'priority': 'u=1, i',
        'referer': 'https://dev.boinenpay.com/login',
        'sec-ch-ua': '"Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"macOS"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-origin',
        'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
        'x-requested-with': 'XMLHttpRequest'
      },
      cookies: {
        'SESSION': 'YWMxMGNkNmUtNmNmNC00ZWNlLThiNDgtMTU4NWVjN2E1ZDU0'
      },
      formData: 'id=product&password=gate25!@$',
      contentType: 'application/x-www-form-urlencoded'
    }
  };

  // 현재 선택된 API 설정
  let currentApi = 'tappay';
  let currentMethod = 'jquery';

  // API 선택 변경 이벤트
  $('#api-select').on('change', function() {
    currentApi = $(this).val();

    // 선택에 따라 정보 표시 변경
    $('.form-group').hide();
    $(`#${currentApi}-info`).show();
  });

  // 요청 방식 선택 변경 이벤트
  $('#method-select').on('change', function() {
    currentMethod = $(this).val();
  });

  // 결과 표시 함수
  function displayResult(type, message, data = null) {
    const $result = $('#result');
    let content = '';

    if (type === 'error') {
      content = `<div class="error">
        <strong>Error:</strong> ${message}
      </div>`;

      if (data) {
        content += `<div class="error-details">
          <pre>${JSON.stringify(data, null, 2)}</pre>
        </div>`;
      }
    } else {
      content = `<div class="success">
        <strong>Success:</strong> ${message}
      </div>`;

      if (data) {
        content += `<div class="success-details">
          <pre>${JSON.stringify(data, null, 2)}</pre>
        </div>`;
      }
    }

    $result.html(content);
  }

  // 현재 API 설정 가져오기
  function getCurrentApiConfig() {
    return apiConfigs[currentApi];
  }

  // jQuery AJAX 요청 함수
  function sendJQueryRequest() {
    const config = getCurrentApiConfig();
    $('#result').html(`<p>${currentApi} API jQuery 요청 중...</p>`);

    let ajaxConfig = {
      url: config.url,
      type: config.method,
      headers: config.headers,
      dataType: 'json',
      timeout: 10000,
      success: function(response) {
        displayResult('success', 'jQuery 요청이 성공했습니다.', response);
      },
      error: function(xhr, status, error) {
        let errorMessage = 'jQuery 요청이 실패했습니다.';
        let errorDetails = {
          status: xhr.status,
          statusText: xhr.statusText,
          responseText: xhr.responseText,
          error: error,
          ajaxStatus: status
        };

        // 인증서 관련 오류 확인
        if (xhr.status === 0 || (error === 'error' && status === 'error')) {
          errorMessage = '인증서 오류 또는 CORS 오류가 발생했습니다. 브라우저 콘솔에서 자세한 정보를 확인하세요.';
        }

        displayResult('error', errorMessage, errorDetails);

        // 콘솔에 추가 정보 출력
        console.error('jQuery AJAX Error:', {
          xhr: xhr,
          status: status,
          error: error
        });
      }
    };

    // Content-Type에 따라 데이터 형식 설정
    if (config.contentType === 'application/json') {
      ajaxConfig.contentType = 'application/json';
      if (config.body && config.method !== 'GET') {
        ajaxConfig.data = JSON.stringify(config.body);
      }
    } else if (config.contentType === 'application/x-www-form-urlencoded') {
      ajaxConfig.contentType = 'application/x-www-form-urlencoded; charset=UTF-8';
      if (config.formData && config.method !== 'GET') {
        ajaxConfig.data = config.formData;
      }
    }

    // 쿠키 추가 (브라우저에서는 자동으로 처리되지 않으므로 참고 정보로만 표시)
    if (config.cookies) {
      console.log('쿠키 정보가 있습니다. 브라우저에서 직접 요청 시 쿠키를 사용할 수 없습니다:', config.cookies);
    }

    $.ajax(ajaxConfig);
  }

  // Axios 요청 함수
  function sendAxiosRequest() {
    const config = getCurrentApiConfig();
    $('#result').html(`<p>${currentApi} API Axios 요청 중...</p>`);

    // Axios 요청 구성
    const axiosConfig = {
      url: config.url,
      method: config.method,
      headers: config.headers,
      timeout: 10000,
      // 인증서 검증 비활성화 옵션 (브라우저에서는 작동하지 않음)
      httpsAgent: {
        rejectUnauthorized: false
      }
    };

    // Content-Type에 따라 데이터 형식 설정
    if (config.method !== 'GET') {
      if (config.contentType === 'application/json' && config.body) {
        axiosConfig.data = config.body;
      } else if (config.contentType === 'application/x-www-form-urlencoded' && config.formData) {
        axiosConfig.data = config.formData;
      }
    }

    // CORS 오류 우회 시도 옵션
    axiosConfig.withCredentials = true;

    // 쿠키가 있는 경우 처리 (브라우저 제한으로 작동하지 않을 수 있음)
    if (config.cookies) {
      console.log('쿠키 정보가 있습니다. 브라우저에서 직접 요청 시 쿠키를 사용할 수 없습니다:', config.cookies);
    }

    axios(axiosConfig)
      .then(function(response) {
        displayResult('success', 'Axios 요청이 성공했습니다.', response.data);
      })
      .catch(function(error) {
        let errorMessage = 'Axios 요청이 실패했습니다.';
        let errorDetails = {
          message: error.message
        };

        if (error.response) {
          // 서버 응답이 있는 경우
          errorDetails.status = error.response.status;
          errorDetails.statusText = error.response.statusText;
          errorDetails.data = error.response.data;
        } else if (error.request) {
          // 요청이 전송되었지만 응답이 없는 경우 (네트워크 오류)
          errorMessage = '네트워크 오류가 발생했습니다. 인증서 오류 또는 CORS 오류일 수 있습니다.';
          errorDetails.request = '요청이 전송되었지만 응답이 없습니다.';
        }

        displayResult('error', errorMessage, errorDetails);
        console.error('Axios Error:', error);
      });
  }

  // Fetch API 요청 함수
  function sendFetchRequest() {
    const config = getCurrentApiConfig();
    $('#result').html(`<p>${currentApi} API Fetch 요청 중...</p>`);

    // Fetch 요청 옵션
    const fetchOptions = {
      method: config.method,
      headers: config.headers,
      // CORS 모드 - credentials 포함 (same-origin일 경우에만 작동)
      credentials: 'include',
      // 모드 설정 (no-cors는 응답을 읽을 수 없지만 요청은 전송됨)
      mode: 'cors'
    };

    // 요청 바디 추가
    if (config.method !== 'GET') {
      if (config.contentType === 'application/json' && config.body) {
        fetchOptions.body = JSON.stringify(config.body);
      } else if (config.contentType === 'application/x-www-form-urlencoded' && config.formData) {
        fetchOptions.body = config.formData;
      }
    }

    // 쿠키가 있는 경우 처리
    if (config.cookies) {
      console.log('쿠키 정보가 있습니다. 브라우저에서 직접 요청 시 쿠키를 사용할 수 없습니다:', config.cookies);
    }

    fetch(config.url, fetchOptions)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`);
        }

        const contentType = response.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
          return response.json().then(data => {
            displayResult('success', 'Fetch 요청이 성공했습니다.', data);
          });
        } else {
          return response.text().then(text => {
            try {
              // JSON 응답인데 Content-Type이 잘못 설정된 경우 파싱 시도
              const data = JSON.parse(text);
              displayResult('success', 'Fetch 요청이 성공했습니다.', data);
            } catch (e) {
              displayResult('success', 'Fetch 요청이 성공했습니다.', { text: text });
            }
          });
        }
      })
      .catch(error => {
        const errorMessage = 'Fetch 요청이 실패했습니다.';
        const errorDetails = { message: error.message };

        if (error.message.includes('Failed to fetch') || error.message.includes('NetworkError')) {
          errorDetails.note = '이 오류는 인증서 문제 또는 CORS 정책으로 인해 발생했을 수 있습니다.';
        }

        displayResult('error', errorMessage, errorDetails);
        console.error('Fetch Error:', error);
      });
  }

  // 프록시 서버를 통한 요청 전송 함수
  function sendProxyRequest() {
    const config = getCurrentApiConfig();
    $('#result').html(`<p>${currentApi} API 프록시 요청 중...</p>`);

    let requestData = {
      url: config.url,
      method: config.method,
      headers: config.headers
    };

    // Content-Type에 따라 데이터 형식 설정
    if (config.contentType === 'application/json') {
      requestData.contentType = 'application/json';
      if (config.body && config.method !== 'GET') {
        requestData.body = config.body;
      }
    } else if (config.contentType === 'application/x-www-form-urlencoded') {
      requestData.contentType = 'application/x-www-form-urlencoded';
      if (config.formData && config.method !== 'GET') {
        requestData.formData = config.formData;
      }
    }

    // 쿠키 정보 추가
    if (config.cookies) {
      requestData.cookies = config.cookies;
    }

    // 프록시 서버로 요청 전송
    $.ajax({
      url: '/proxy',
      type: 'POST',
      contentType: 'application/json',
      data: JSON.stringify(requestData),
      dataType: 'json',
      timeout: 15000,
      success: function(response) {
        if (response.status >= 200 && response.status < 300) {
          displayResult('success', '프록시 요청이 성공했습니다.', response.data);
        } else {
          displayResult('error', `프록시 요청 실패 (${response.status} ${response.statusText})`, response);
        }
      },
      error: function(xhr, status, error) {
        let errorMessage = '프록시 요청이 실패했습니다.';
        let errorDetails = {
          status: xhr.status,
          statusText: xhr.statusText,
          responseText: xhr.responseText,
          error: error,
          ajaxStatus: status
        };

        try {
          const responseData = JSON.parse(xhr.responseText);
          errorDetails.responseData = responseData;
        } catch (e) {}

        displayResult('error', errorMessage, errorDetails);

        console.error('프록시 요청 실패:', {
          xhr: xhr,
          status: status,
          error: error
        });
      }
    });
  }

  // 요청 전송 함수 - 선택된 방식에 따라 다른 함수 호출
  function sendRequest() {
    switch(currentMethod) {
      case 'jquery':
        sendJQueryRequest();
        break;
      case 'axios':
        sendAxiosRequest();
        break;
      case 'fetch':
        sendFetchRequest();
        break;
      case 'proxy':
        sendProxyRequest();
        break;
      default:
        sendJQueryRequest();
    }
  }

  // 버튼 이벤트 연결
  $('.button-send').on('click', sendRequest);

  // 결과 지우기 버튼 이벤트
  $('#clear-result').on('click', function() {
    $('#result').empty();
  });

  // 실패한 경우 프록시로 재시도 버튼 추가
  $(document).on('click', '.retry-with-proxy', function() {
    $('#method-select').val('proxy');
    $('.button-send').click();
  });

  // 새 명령어를 추가한 크롬 실행 버튼
  $('#launch-ultimate-chrome').on('click', function() {
    const isMac = navigator.platform.indexOf('Mac') !== -1;
    const timestamp = new Date().getTime();
    const userDataDir = isMac
      ? `/tmp/chrome-ultimate-${timestamp}`
      : `%TEMP%\\chrome-ultimate-${timestamp}`;

    // 더 강력한 CORS 우회 및 인증서 오류 무시 옵션 조합
    const command = isMac
      ? `open -n -a "Google Chrome" --args --ignore-certificate-errors --allow-insecure-localhost --disable-web-security --disable-features=OutOfBlinkCors,SameSiteByDefaultCookies,CookiesWithoutSameSiteMustBeSecure --disable-site-isolation-trials --user-data-dir="${userDataDir}"`
      : `start chrome --new-window --ignore-certificate-errors --allow-insecure-localhost --disable-web-security --disable-features=OutOfBlinkCors,SameSiteByDefaultCookies,CookiesWithoutSameSiteMustBeSecure --disable-site-isolation-trials --user-data-dir="${userDataDir}"`;

    const formattedCommand = runBrowser(command);

    $('#result').html(`<div class="info">
      <p>완전 우회 Chrome 실행 명령어:</p>
      <pre>${formattedCommand}</pre>
      <p>※ 이 Chrome 인스턴스는 가장 강력한 보안 우회 설정을 사용합니다:</p>
      <ul>
        <li><strong>CORS 완전 비활성화</strong>: 가장 엄격한 설정까지 비활성화</li>
        <li><strong>인증서 오류 무시</strong>: 만료된 인증서도 허용</li>
        <li><strong>사이트 격리 비활성화</strong>: 웹사이트 간 격리를 비활성화</li>
        <li><strong>CORS 관련 내부 컴포넌트 비활성화</strong>: Blink 엔진의 CORS 검사 비활성화</li>
      </ul>
      <p>※ 보안에 매우 취약하므로 테스트 목적으로만 사용하세요.</p>
      <p>※ 매번 새로운 프로필 디렉토리를 사용하여 확실하게 새 창으로 실행됩니다.</p>
    </div>`);
  });

  // 프록시 서버 CORS 헤더 강화 버튼
  $('#enhance-proxy').on('click', function() {
    const url = 'http://localhost:3000/enhance-cors';

    $.get(url)
      .done(function(response) {
        $('#result').html(`<div class="info">
          <p>프록시 서버 CORS 헤더 강화 완료:</p>
          <pre>${JSON.stringify(response, null, 2)}</pre>
        </div>`);
      })
      .fail(function(error) {
        $('#result').html(`<div class="error">
          <p>프록시 서버 CORS 강화 실패:</p>
          <pre>${JSON.stringify(error, null, 2)}</pre>
          <p>※ 프록시 서버가 실행 중인지 확인하세요.</p>
        </div>`);
      });
  });

  // CORS 오류 메시지 감지 함수 추가
  function isCORSError(error) {
    if (!error) return false;

    // 오류 메시지나 스택 트레이스에 CORS 관련 텍스트가 있는지 확인
    const errorText = (error.message || '') + (error.stack || '') + (error.toString() || '');
    const corsTerms = [
      'CORS', 'cross-origin', 'Access-Control-Allow-Origin',
      'has been blocked', 'Same Origin Policy', 'preflight',
      "No 'Access-Control-Allow-Origin'", "request doesn't pass access control check"
    ];

    return corsTerms.some(term => errorText.includes(term));
  }

  // 브라우저 직접 요청 함수에 CORS 처리 추가
  function sendDirectRequest(url, method, headers, data, dataType) {
    return new Promise((resolve, reject) => {
      const selectedMethod = $('#method-select').val();

      // 예외 발생 시 프록시로 자동 전환하는 핸들러
      const handleError = (error) => {
        if (isCORSError(error)) {
          // CORS 오류 감지 시 프록시로 자동 전환
          console.warn('CORS 오류 감지, 프록시 서버로 자동 전환합니다:', error);
          $('#result').append(`<p class="error">CORS 오류가 감지되어 프록시 서버로 자동 전환합니다...</p>`);

          // 프록시 서버로 재시도
          sendProxyRequest(url, method, headers, data, dataType)
            .then(resolve)
            .catch(reject);
        } else {
          reject(error);
        }
      };

      // ... existing code ...
    });
  }

  // 테스트 환경 정보 출력
  console.log('테스트 환경이 준비되었습니다.');
});