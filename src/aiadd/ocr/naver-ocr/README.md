# 네이버 CLOVA OCR을 이용한 신용카드 정보 추출

이 스크립트는 네이버 클라우드 플랫폼의 CLOVA OCR API를 사용하여 신용카드 이미지에서 카드 번호, 유효기간, 카드 소유자 이름, 카드 타입 등의 정보를 추출합니다.

## 사전 준비

1. 네이버 클라우드 플랫폼 계정 생성 및 로그인
2. CLOVA OCR 서비스 신청 및 API 키 발급
3. 필요한 Python 패키지 설치

## 설치 방법

1. 필요한 패키지 설치:
```bash
pip install requests python-dotenv
```

2. 환경 변수 설정:
   - `.env.example` 파일을 `.env`로 복사
   - 네이버 클라우드 콘솔에서 발급받은 API URL과 Secret Key로 값 변경

```bash
cp .env.example .env
# .env 파일을 편집하여 실제 API URL과 Secret Key 입력
```

## 사용 방법

1. 기본 사용법:
```bash
python card_ocr.py
```

2. 특정 이미지 파일 지정:
```bash
python card_ocr.py /path/to/your/credit_card_image.jpg
```

## 결과 확인

실행 결과는 다음과 같이 출력됩니다:
```
===== 신용카드 정보 추출 결과 =====
카드 번호: 1234 5678 9012 3456
유효기간: 12/25
카드 소유자: HONG GIL DONG
카드 타입: VISA
==================================
```

또한 API 응답 전체 내용은 `ocr_response.json` 파일에 저장되어 디버깅에 활용할 수 있습니다.

## 주의사항

- 신용카드 정보는 민감한 개인정보이므로 보안에 주의하세요.
- 테스트 목적으로만 사용하고, 실제 카드 정보는 안전하게 관리하세요.
- 네이버 클라우드 플랫폼의 사용량에 따라 비용이 발생할 수 있습니다.

## 참고 자료

- [네이버 클라우드 플랫폼 CLOVA OCR 가이드](https://guide.ncloud-docs.com/docs/clovaocr-example01)
- [CLOVA OCR 신용카드 인식 예제](https://davelogs.tistory.com/39)