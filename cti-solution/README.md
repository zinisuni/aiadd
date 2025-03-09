# Asterisk 기반 CTI 솔루션

Docker 기반의 Asterisk CTI(Computer Telephony Integration) 솔루션입니다. 이 프로젝트는 내부 테스트용 환경을 포함하고 있어 별도의 외부 통신사 연동 없이도 기본적인 CTI 기능을 테스트할 수 있습니다.

## 시스템 구성

- Asterisk PBX: 오픈소스 통신 서버
- Node.js: AGI(Asterisk Gateway Interface) 서버
- Docker: 컨테이너화된 환경
- Elasticsearch & Kibana: 로깅 및 모니터링

## 시스템 요구사항

- Docker 20.10 이상
- Docker Compose 2.0 이상
- 포트 요구사항:
  - 3000: 웹 서버
  - 4573: AGI 서버
  - 5060: SIP (UDP/TCP)
  - 10000-20000: RTP 미디어 스트림

## 설치 및 실행 방법

1. 프로젝트 클론
```bash
git clone <repository-url>
cd cti-solution
```

2. 음성 파일 준비
```bash
# 스크립트 실행 권한 부여
chmod +x scripts/setup/prepare-sounds.sh

# 음성 파일 생성
./scripts/setup/prepare-sounds.sh
```

3. Docker 컨테이너 실행
```bash
docker-compose up -d
```

4. 로그 확인
```bash
docker-compose logs -f
```

## Asterisk 설정 상세 설명

### 1. SIP 설정 (sip.conf)
```ini
[general]
context=from-internal        # 기본 컨텍스트
allowguest=no               # 미등록 단말기 접근 차단
bindport=5060              # SIP 포트
bindaddr=0.0.0.0           # 모든 IP에서 접근 허용
nat=force_rport,comedia    # NAT 환경 지원
directmedia=no             # 미디어 직접 전송 비활성화

[1000]                     # 테스트용 내선번호 1
type=friend                # 송수신 모두 가능
host=dynamic               # IP 동적 할당
secret=test1000            # 비밀번호
...

[2000]                     # 테스트용 내선번호 2
...
```

### 2. 다이얼플랜 설정 (extensions.conf)
```ini
[from-internal]
; 내선 통화 설정
exten => _1XXX,1,NoOp(내선 통화)    # 1000번대 내선
exten => _2XXX,1,NoOp(내선 통화)    # 2000번대 내선

; IVR 테스트 (500번)
exten => 500,1,Answer()             # 자동응답 시스템

; 에코 테스트 (7777번)
exten => 7777,1,Answer()            # 음성 에코 테스트
```

## 테스트 환경 설정

### 1. SIP 소프트폰 설치
- Zoiper: https://www.zoiper.com/en/voip-softphone/download/current
- 또는 MicroSIP: https://www.microsip.org/downloads

### 2. 테스트 계정 설정

#### 첫 번째 테스트폰 (1000번)
```
SIP 서버: localhost (또는 서버 IP)
포트: 5060
사용자 이름: 1000
비밀번호: test1000
```

#### 두 번째 테스트폰 (2000번)
```
SIP 서버: localhost (또는 서버 IP)
포트: 5060
사용자 이름: 2000
비밀번호: test2000
```

## 테스트 시나리오

### 1. 기본 연결 테스트
```bash
# SIP 등록 상태 확인
docker-compose exec asterisk asterisk -rx "sip show peers"
```

### 2. 에코 테스트
1. 소프트폰에서 7777번으로 전화
2. 음성이 정상적으로 에코되는지 확인

### 3. 내선 통화 테스트
1. 1000번에서 2000번으로 전화
2. 2000번에서 1000번으로 전화

### 4. IVR 테스트
1. 500번으로 전화
2. 음성 안내 확인
3. 메뉴 선택 테스트

## 모니터링 및 문제 해결

### 1. 시스템 상태 확인
```bash
# 활성 채널 확인
docker-compose exec asterisk asterisk -rx "core show channels"

# SIP 피어 상태
docker-compose exec asterisk asterisk -rx "sip show peers"

# 실시간 로그 확인
docker-compose exec asterisk tail -f /var/log/asterisk/messages
```

### 2. 일반적인 문제 해결
- SIP 등록 실패: NAT 설정 확인
- 음성 단방향: RTP 포트 확인
- 음성 품질 문제: 네트워크 상태 확인

## 프로젝트 구조
```
cti-solution/
├── src/                    # 소스 코드
│   └── server.js          # AGI 서버
├── config/                 # 설정 파일
│   └── asterisk/          # Asterisk 설정
│       ├── sip.conf       # SIP 설정
│       └── extensions.conf # 다이얼플랜
├── scripts/               # 유틸리티 스크립트
│   └── setup/            # 환경 설정 스크립트
└── sounds/               # 음성 파일
```

## 라이선스
MIT License