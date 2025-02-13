#!/bin/bash

# README.md 생성 스크립트

# 디렉토리 목록과 설명을 배열로 정의
directories=(
    "docs/planning"
    "docs/development"
    "docs/design"
    "docs/accounting"
    "docs/sales"
    "docs/legal"
    "docs/marketing"
    "docs/hr"
    "docs/customer_service"
    "docs/it_support"
    "src/aiadd"
    "src/aiadw"
    "src/common"
    "src/tests"
    "data"
    "config"
    "scripts"
    "images"
)

create_readme() {
    local dir=$1
    local title=${dir##*/}
    local content=""

    case $dir in
        "docs/planning")
            content="프로젝트 기획 및 요구사항 문서를 저장하는 디렉토리입니다.\n\n## 포함되는 문서\n- 프로젝트 제안서\n- 요구사항 명세서\n- 일정 계획서\n- 리소스 계획"
            ;;
        "docs/development")
            content="개발 관련 문서를 저장하는 디렉토리입니다.\n\n## 포함되는 문서\n- 기술 명세서\n- API 문서\n- 데이터베이스 스키마\n- 개발 가이드라인"
            ;;
        "docs/design")
            content="디자인 관련 문서와 자료를 저장하는 디렉토리입니다.\n\n## 포함되는 문서\n- UI/UX 디자인 가이드\n- 목업 및 프로토타입\n- 디자인 에셋\n- 스타일 가이드"
            ;;
        "docs/accounting")
            content="회계 관련 문서를 저장하는 디렉토리입니다.\n\n## 포함되는 문서\n- 예산 계획\n- 비용 보고서\n- 재무 분석\n- 회계 정책"
            ;;
        "docs/sales")
            content="영업 관련 문서를 저장하는 디렉토리입니다.\n\n## 포함되는 문서\n- 영업 전략\n- 판매 보고서\n- 고객 분석\n- 시장 조사 자료"
            ;;
        "docs/legal")
            content="법률 관련 문서를 저장하는 디렉토리입니다.\n\n## 포함되는 문서\n- 계약서\n- 법률 검토 의견\n- 규정 및 정책\n- 라이선스"
            ;;
        "docs/marketing")
            content="마케팅 관련 문서를 저장하는 디렉토리입니다.\n\n## 포함되는 문서\n- 마케팅 전략\n- 캠페인 계획\n- 마케팅 분석\n- 홍보 자료"
            ;;
        "docs/hr")
            content="인사 관련 문서를 저장하는 디렉토리입니다.\n\n## 포함되는 문서\n- 인사 정책\n- 채용 계획\n- 교육 자료\n- 평가 기준"
            ;;
        "docs/customer_service")
            content="고객 서비스 관련 문서를 저장하는 디렉토리입니다.\n\n## 포함되는 문서\n- 고객 응대 매뉴얼\n- 서비스 품질 기준\n- 고객 피드백\n- FAQ"
            ;;
        "docs/it_support")
            content="IT 지원 관련 문서를 저장하는 디렉토리입니다.\n\n## 포함되는 문서\n- 시스템 운영 매뉴얼\n- 장애 대응 절차\n- 보안 정책\n- 인프라 구성도"
            ;;
        "src/aiadd")
            content="AI Agent Driven Development (AIADD) 관련 소스 코드를 저장하는 디렉토리입니다.\n\n## 주요 기능\n- AI 에이전트 코어\n- 개발 자동화 도구\n- 코드 생성기\n- 테스트 자동화"
            ;;
        "src/aiadw")
            content="AI Agent Driven Work (AIADW) 관련 소스 코드를 저장하는 디렉토리입니다.\n\n## 주요 기능\n- 업무 자동화 도구\n- 워크플로우 엔진\n- 데이터 분석 도구\n- 의사결정 지원 시스템"
            ;;
        "src/common")
            content="공통으로 사용되는 유틸리티 및 라이브러리 코드를 저장하는 디렉토리입니다.\n\n## 포함 내용\n- 공통 유틸리티\n- 헬퍼 함수\n- 상수 정의\n- 공통 인터페이스"
            ;;
        "src/tests")
            content="테스트 코드를 저장하는 디렉토리입니다.\n\n## 테스트 종류\n- 단위 테스트\n- 통합 테스트\n- 성능 테스트\n- E2E 테스트"
            ;;
        "data")
            content="프로젝트에서 사용되는 데이터 파일을 저장하는 디렉토리입니다.\n\n## 데이터 종류\n- 학습 데이터\n- 테스트 데이터\n- 설정 데이터\n- 임시 데이터"
            ;;
        "config")
            content="프로젝트 설정 파일을 저장하는 디렉토리입니다.\n\n## 설정 파일\n- 환경 설정\n- API 설정\n- 데이터베이스 설정\n- 로깅 설정"
            ;;
        "scripts")
            content="프로젝트에서 사용되는 각종 스크립트를 저장하는 디렉토리입니다.\n\n## 스크립트 종류\n- 초기화 스크립트\n- 배포 스크립트\n- 유틸리티 스크립트\n- 데이터 처리 스크립트"
            ;;
        "images")
            content="프로젝트에서 사용되는 이미지 파일을 저장하는 디렉토리입니다.\n\n## 이미지 종류\n- 스크린샷\n- 다이어그램\n- 아이콘\n- 기타 이미지 자료"
            ;;
    esac

    if [ -n "$content" ]; then
        echo "Creating README.md in $dir"
        echo -e "# ${title}\n\n${content}" > "$dir/README.md"
    fi
}

# 각 디렉토리에 README.md 생성
for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        create_readme "$dir"
    fi
done

echo "README.md files have been created successfully!"