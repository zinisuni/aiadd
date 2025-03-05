# 네이버 CLOVA OCR을 이용한 신용카드 정보 추출 - Spring Boot 버전

이 프로젝트는 네이버 클라우드 플랫폼의 CLOVA OCR API를 사용하여 신용카드 이미지에서 카드 번호, 유효기간, 카드 소유자 이름, 카드 타입 등의 정보를 추출하는 Spring Boot 애플리케이션입니다.

## 기능

- 신용카드 이미지 업로드
- 네이버 CLOVA OCR API를 통한 텍스트 추출
- 카드 번호, 유효기간, 카드 소유자 이름, 카드 타입 인식
- 결과 시각화 및 표시

## 사전 준비

1. 네이버 클라우드 플랫폼 계정 생성 및 로그인
2. CLOVA OCR 서비스 신청 및 API 키 발급
3. JDK 11 이상 설치
4. Gradle 설치

## 설치 및 실행 방법

### 1. 프로젝트 클론

```bash
git clone <repository-url>
cd spring-ocr
```

### 2. 환경 설정

`application.properties` 파일에서 네이버 CLOVA OCR API 설정을 수정합니다:

```properties
# Naver CLOVA OCR API 설정
naver.ocr.api.url=https://xxxxxxxx.apigw.ntruss.com/custom/v1/xxxx/xxxxxxxx
naver.ocr.secret.key=xxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. 빌드 및 실행

```bash
./gradlew build
./gradlew bootRun
```

또는 JAR 파일로 실행:

```bash
./gradlew build
java -jar build/libs/spring-ocr-0.0.1-SNAPSHOT.jar
```

### 4. 애플리케이션 접속

웹 브라우저에서 다음 URL로 접속합니다:

```
http://localhost:8080
```

## 프로젝트 구조

```
src/main/java/com/aiadd/ocr/naver/
├── NaverOcrApplication.java        # 메인 애플리케이션 클래스
├── controller/
│   └── OcrController.java          # 웹 요청 처리 컨트롤러
├── service/
│   └── NaverOcrService.java        # OCR 처리 서비스
└── dto/
    └── CardInfoDto.java            # 카드 정보 데이터 전송 객체

src/main/resources/
├── application.properties          # 애플리케이션 설정
├── static/
│   ├── css/
│   │   └── style.css               # 스타일시트
│   └── js/
│       └── script.js               # 자바스크립트
└── templates/
    ├── index.html                  # 메인 페이지
    └── result.html                 # 결과 페이지
```

## API 엔드포인트

- `GET /`: 메인 페이지
- `POST /ocr/card`: 카드 이미지 업로드 및 OCR 처리
- `GET /result`: 결과 페이지

## 주의사항

- 신용카드 정보는 민감한 개인정보이므로 보안에 주의하세요.
- 테스트 목적으로만 사용하고, 실제 카드 정보는 안전하게 관리하세요.
- 네이버 클라우드 플랫폼의 사용량에 따라 비용이 발생할 수 있습니다.

## 참고 자료

- [네이버 클라우드 플랫폼 CLOVA OCR 가이드](https://guide.ncloud-docs.com/docs/clovaocr-example01)
- [Spring Boot 공식 문서](https://spring.io/projects/spring-boot)
- [Thymeleaf 공식 문서](https://www.thymeleaf.org/documentation.html)

## 환경별 API 응답 구조 차이

Naver CLOVA OCR API는 개발 환경과 운영 환경에서 다른 응답 구조를 반환할 수 있습니다. 이 프로젝트는 두 환경 모두에서 작동하도록 설계되었습니다.

### 응답 구조 비교

1. **개발 환경 (dev)**
   - 응답에 `fields` 배열이 포함됨
   - 각 필드는 `inferText` 속성에 인식된 텍스트를 포함
   - 응답 파일: `ocr_response-dev.json`

2. **운영 환경 (prod)**
   - 응답에 `creditCard` 객체가 포함됨
   - `creditCard.result` 객체 내에 `cardNumber`, `validThru`, `cardHolder` 등의 정보가 직접 제공됨
   - 응답 파일: `ocr_response-prod.json`

### 디버깅 방법

환경별 응답 구조를 확인하려면:

```bash
# 개발 환경에서 실행
./gradlew bootRun --args='--spring.profiles.active=dev'

# 운영 환경에서 실행
./gradlew bootRun --args='--spring.profiles.active=prod'
```

각 환경에서 실행 후 생성된 `ocr_response-{env}.json` 파일을 비교하여 응답 구조의 차이를 확인할 수 있습니다.