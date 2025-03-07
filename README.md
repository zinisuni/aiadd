# AIADD 및 AIADW 방법론

## 1. AIADD (AI Agent Driven Development)

**정의**: AIADD는 인공지능 에이전트가 소프트웨어 개발 프로세스를 주도하는 방법론입니다. 이 접근 방식에서는 AI가 개발자의 보조 역할을 넘어, 요구 사항 분석, 설계, 코딩, 테스트 및 배포의 전 과정을 주도적으로 수행합니다. AIADD는 개발 속도를 높이고, 코드 품질을 향상시키며, 반복적인 작업을 자동화하여 개발자의 창의적인 작업에 더 많은 시간을 할애할 수 있도록 합니다.

### 주요 특징:
- **자동화**: AI가 코드 생성, 버그 수정, 테스트 자동화 등을 수행하여 개발 프로세스를 효율화합니다.
- **지속적인 학습**: AI는 과거의 프로젝트 데이터를 학습하여 더 나은 결정을 내리고, 개발 패턴을 인식합니다.
- **협업**: AI와 인간 개발자가 협력하여 최적의 솔루션을 도출합니다.

## 2. AIADW (AI Agent Driven Work)

**정의**: AIADW는 인공지능 에이전트가 업무 프로세스를 주도하는 방법론입니다. 이 접근 방식에서는 AI가 비즈니스 프로세스의 자동화, 의사 결정 지원, 데이터 분석 및 고객 서비스 등 다양한 업무를 수행합니다. AIADW는 조직의 효율성을 높이고, 인적 자원의 부담을 줄이며, 데이터 기반의 의사 결정을 촉진합니다.

### 주요 특징:
- **업무 자동화**: 반복적이고 규칙 기반의 업무를 AI가 자동으로 처리하여 인적 자원의 효율성을 극대화합니다.
- **데이터 분석**: AI는 대량의 데이터를 분석하여 인사이트를 제공하고, 비즈니스 전략을 지원합니다.
- **의사 결정 지원**: AI는 실시간 데이터와 예측 분석을 통해 의사 결정 과정을 지원합니다.

## 3. Git 서브모듈 관리

프로젝트의 모듈성과 재사용성을 높이기 위해 일부 기능은 독립적인 Git 저장소로 관리되며, 메인 프로젝트에 서브모듈로 통합됩니다.

### 현재 서브모듈
- **google-ocr**: OCR 기능을 제공하는 독립적인 서비스 모듈 (`src/aiadd/ocr/google-ocr`)

### 서브모듈 사용법

1. **프로젝트 클론**:
```bash
git clone --recursive https://github.com/yourusername/aiadd.git
# 또는
git clone https://github.com/yourusername/aiadd.git
git submodule update --init --recursive
```

2. **서브모듈 업데이트**:
```bash
git submodule update --remote  # 모든 서브모듈을 최신 버전으로 업데이트
# 또는
cd src/aiadd/ocr/google-ocr  # 특정 서브모듈 업데이트
git pull origin main
```

3. **서브모듈 작업**:
```bash
cd src/aiadd/ocr/google-ocr
git checkout main
# 작업 수행
git add .
git commit -m "작업 내용"
cd ../../../..  # 프로젝트 루트로 이동
git add src/aiadd/ocr/google-ocr
git commit -m "Update google-ocr submodule"
```

### 디렉토리 구조
```
/aiadd
  ├── /docs                # 프로젝트 문서 및 자료
  │   ├── /planning        # 기획 관련 문서
  │   ├── /development     # 개발 관련 문서
  │   ├── /design          # 디자인 관련 문서
  │   ├── /accounting      # 회계 관련 문서
  │   ├── /sales           # 영업 관련 문서
  │   ├── /legal           # 법률 관련 문서
  │   ├── /marketing        # 마케팅 관련 문서
  │   ├── /hr              # 인사 관련 문서
  │   ├── /customer_service # 고객 서비스 관련 문서
  │   └── /it_support      # IT 지원 관련 문서
  ├── /src                 # 소스 코드
  │   ├── /aiadd          # AIADD 관련 코드
  │   │   ├── /ocr        # OCR 관련 기능
  │   │   │   └── /google-ocr  # Google OCR 서비스 (서브모듈)
  │   │   └── ...         # 기타 AIADD 관련 코드
  │   ├── /aiadw          # AIADW 관련 코드
  │   ├── /common         # 공통 모듈 및 유틸리티
  │   └── /tests          # 테스트 코드
  ├── /data               # 데이터 파일 및 스크립트
  ├── /config             # 설정 파일
  ├── /scripts            # 유틸리티 스크립트
  ├── /images             # 캡쳐 이미지 저장 공간
  └── README.md           # 프로젝트 개요 및 설명
```