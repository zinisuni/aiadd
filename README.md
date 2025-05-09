# AIADD 및 AIADW 방법론

## 1. AIADD (AI Agent Driven Development)

[DeepWiki zinisuni/aiadd](https://deepwiki.com/zinisuni/aiadd/2-redis-high-availability-system)

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
- **redirect-test**: 리다이렉트 테스트를 위한 독립적인 서비스 모듈 (`src/aiadd/redirect-test`)

### 서브모듈 생성 및 등록 방법

#### 1. 기존 디렉토리를 서브모듈로 변환하는 방법

```bash
# 1. 메인 저장소에서 해당 디렉토리 제거 (인덱스에서만 제거, 파일은 유지)
git rm --cached -r src/aiadd/your-module

# 2. 해당 디렉토리가 이미 Git 저장소인지 확인
cd src/aiadd/your-module
git status

# 3. .git/modules/ 디렉토리에 bare 레포지토리 생성
cd ../../../  # 메인 프로젝트 루트로 이동
mkdir -p .git/modules/your-module
cp -r src/aiadd/your-module/.git/* .git/modules/your-module/

# 4. 서브모듈 디렉토리의 .git 파일 설정
cd src/aiadd/your-module
rm -rf .git
echo "gitdir: ../../../.git/modules/your-module" > .git

# 5. .gitmodules 파일에 서브모듈 정보 추가
cd ../../..  # 메인 프로젝트 루트로 이동
echo '[submodule "your-module"]' >> .gitmodules
echo '    path = src/aiadd/your-module' >> .gitmodules
echo '    url = ./.git/modules/your-module' >> .gitmodules

# 6. 서브모듈 초기화 및 업데이트
git submodule init
git submodule update

# 7. 변경사항 커밋
git add .gitmodules src/aiadd/your-module
git commit -m "feat: your-module을 서브모듈로 추가"
```

#### 2. 원격 저장소를 서브모듈로 추가하는 방법

```bash
# 원격 저장소를 서브모듈로 추가
git submodule add https://github.com/username/repo.git src/aiadd/your-module
git commit -m "feat: your-module 서브모듈 추가"
```

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
cd src/aiadd/your-module  # 특정 서브모듈 업데이트
git pull origin main
```

3. **서브모듈 작업**:
```bash
cd src/aiadd/your-module
git checkout main
# 작업 수행
git add .
git commit -m "작업 내용"
cd ../../../..  # 프로젝트 루트로 이동
git add src/aiadd/your-module
git commit -m "Update your-module submodule"
```

### 서브모듈 관리 주의사항

1. **서브모듈 변환 시 주의사항**:
   - 하위 디렉토리의 Git 이력 보존 여부 결정
   - 메인 저장소와의 충돌 방지
   - 절대 경로/상대 경로 선택 시 프로젝트 이동성 고려

2. **작업 순서 준수**:
   - 항상 서브모듈 내부에서 먼저 변경사항 커밋
   - 메인 저장소에서 서브모듈 변경사항 커밋
   - 서브모듈 브랜치 관리 주의

3. **협업 시 유의사항**:
   - 팀원들에게 서브모듈 사용 공지
   - clone 시 --recursive 옵션 사용 강조
   - 서브모듈 업데이트 절차 공유

4. **서브모듈 삭제 방법**:
```bash
# 1. .gitmodules 파일에서 해당 서브모듈 항목 제거
# 2. .git/config 파일에서 해당 서브모듈 항목 제거
# 3. 서브모듈 디렉토리 제거
git rm --cached path/to/submodule
rm -rf path/to/submodule
rm -rf .git/modules/submodule_name
# 4. 변경사항 커밋
git commit -m "Remove submodule"
```

5. **서브모듈 URL 변경 방법**:
```bash
# .gitmodules 파일 수정
git config --file=.gitmodules submodule.your-module.url NEW_URL
# 서브모듈 동기화
git submodule sync
# 변경사항 커밋
git add .gitmodules
git commit -m "Update submodule URL"
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