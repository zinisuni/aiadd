#!/bin/bash

# 서브모듈 관리 스크립트
# 사용법: ./manage.sh [명령] [옵션]

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 프로젝트 루트 디렉토리 설정
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
if [ -z "$PROJECT_ROOT" ]; then
    echo -e "${RED}오류: Git 저장소가 아닙니다.${NC}"
    exit 1
fi

# 도움말 출력
function show_help {
    echo -e "${BLUE}서브모듈 관리 스크립트${NC}"
    echo "사용법: $0 [명령] [옵션]"
    echo ""
    echo "명령:"
    echo "  add-local [경로] [이름]      - 로컬 디렉토리를 서브모듈로 추가"
    echo "  add-remote [URL] [경로]      - 원격 저장소를 서브모듈로 추가"
    echo "  update [이름]                - 서브모듈 업데이트 (이름 생략 시 모든 서브모듈)"
    echo "  remove [이름]                - 서브모듈 제거"
    echo "  list                         - 서브모듈 목록 표시"
    echo "  status                       - 서브모듈 상태 확인"
    echo "  help                         - 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0 add-local src/aiadd/my-module my-module"
    echo "  $0 add-remote https://github.com/user/repo.git src/aiadd/my-module"
    echo "  $0 update my-module"
    echo "  $0 remove my-module"
    echo ""
}

# 로컬 디렉토리를 서브모듈로 추가
function add_local_submodule {
    if [ $# -lt 2 ]; then
        echo -e "${RED}오류: 경로와 이름을 지정해야 합니다.${NC}"
        echo "사용법: $0 add-local [경로] [이름]"
        exit 1
    fi

    local MODULE_PATH="$1"
    local MODULE_NAME="$2"

    echo -e "${YELLOW}로컬 디렉토리 '$MODULE_PATH'를 '$MODULE_NAME' 서브모듈로 추가합니다...${NC}"

    # 1. 디렉토리가 존재하는지 확인
    if [ ! -d "$MODULE_PATH" ]; then
        echo -e "${RED}오류: '$MODULE_PATH' 디렉토리가 존재하지 않습니다.${NC}"
        exit 1
    fi

    # 2. 디렉토리가 Git 저장소인지 확인
    if [ ! -d "$MODULE_PATH/.git" ]; then
        echo -e "${RED}오류: '$MODULE_PATH'는 Git 저장소가 아닙니다.${NC}"
        exit 1
    fi

    # 3. 메인 저장소에서 해당 디렉토리 제거 (인덱스에서만 제거, 파일은 유지)
    echo "메인 저장소에서 디렉토리 제거 중..."
    git rm --cached -r "$MODULE_PATH"

    # 4. .git/modules/ 디렉토리에 bare 레포지토리 생성
    echo "Bare 레포지토리 생성 중..."
    mkdir -p "$PROJECT_ROOT/.git/modules/$MODULE_NAME"
    cp -r "$MODULE_PATH/.git/"* "$PROJECT_ROOT/.git/modules/$MODULE_NAME/"

    # 5. 서브모듈 디렉토리의 .git 파일 설정
    echo "서브모듈 .git 파일 설정 중..."
    rm -rf "$MODULE_PATH/.git"

    # 상대 경로 계산
    local REL_PATH=$(python -c "import os.path; print(os.path.relpath('$PROJECT_ROOT/.git/modules/$MODULE_NAME', '$(dirname "$MODULE_PATH")'))")
    echo "gitdir: $REL_PATH" > "$MODULE_PATH/.git"

    # 6. .gitmodules 파일에 서브모듈 정보 추가
    echo ".gitmodules 파일 업데이트 중..."
    if [ -f "$PROJECT_ROOT/.gitmodules" ]; then
        # 이미 해당 서브모듈이 있는지 확인
        if grep -q "\\[submodule \"$MODULE_NAME\"\\]" "$PROJECT_ROOT/.gitmodules"; then
            echo -e "${YELLOW}경고: '$MODULE_NAME' 서브모듈이 이미 .gitmodules 파일에 존재합니다.${NC}"
        else
            echo "[submodule \"$MODULE_NAME\"]" >> "$PROJECT_ROOT/.gitmodules"
            echo "    path = $MODULE_PATH" >> "$PROJECT_ROOT/.gitmodules"
            echo "    url = ./.git/modules/$MODULE_NAME" >> "$PROJECT_ROOT/.gitmodules"
        fi
    else
        echo "[submodule \"$MODULE_NAME\"]" > "$PROJECT_ROOT/.gitmodules"
        echo "    path = $MODULE_PATH" >> "$PROJECT_ROOT/.gitmodules"
        echo "    url = ./.git/modules/$MODULE_NAME" >> "$PROJECT_ROOT/.gitmodules"
    fi

    # 7. 서브모듈 초기화 및 업데이트
    echo "서브모듈 초기화 및 업데이트 중..."
    cd "$PROJECT_ROOT" && git submodule init && git submodule update

    echo -e "${GREEN}서브모듈 '$MODULE_NAME'이 성공적으로 추가되었습니다.${NC}"
    echo "변경사항을 커밋하려면 다음 명령을 실행하세요:"
    echo "git add .gitmodules $MODULE_PATH"
    echo "git commit -m \"feat: $MODULE_NAME 서브모듈 추가\""
}

# 원격 저장소를 서브모듈로 추가
function add_remote_submodule {
    if [ $# -lt 2 ]; then
        echo -e "${RED}오류: URL과 경로를 지정해야 합니다.${NC}"
        echo "사용법: $0 add-remote [URL] [경로]"
        exit 1
    fi

    local REPO_URL="$1"
    local MODULE_PATH="$2"

    echo -e "${YELLOW}원격 저장소 '$REPO_URL'를 '$MODULE_PATH' 경로에 서브모듈로 추가합니다...${NC}"

    # 서브모듈 추가
    cd "$PROJECT_ROOT" && git submodule add "$REPO_URL" "$MODULE_PATH"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}서브모듈이 성공적으로 추가되었습니다.${NC}"
        echo "변경사항을 커밋하려면 다음 명령을 실행하세요:"
        echo "git commit -m \"feat: $(basename "$MODULE_PATH") 서브모듈 추가\""
    else
        echo -e "${RED}서브모듈 추가 중 오류가 발생했습니다.${NC}"
    fi
}

# 서브모듈 업데이트
function update_submodule {
    cd "$PROJECT_ROOT"

    if [ $# -eq 0 ]; then
        echo -e "${YELLOW}모든 서브모듈을 업데이트합니다...${NC}"
        git submodule update --remote

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}모든 서브모듈이 성공적으로 업데이트되었습니다.${NC}"
        else
            echo -e "${RED}서브모듈 업데이트 중 오류가 발생했습니다.${NC}"
        fi
    else
        local MODULE_NAME="$1"
        local MODULE_PATH=""

        # .gitmodules 파일에서 서브모듈 경로 찾기
        if [ -f "$PROJECT_ROOT/.gitmodules" ]; then
            MODULE_PATH=$(git config -f .gitmodules --get "submodule.$MODULE_NAME.path")
        fi

        if [ -z "$MODULE_PATH" ]; then
            echo -e "${RED}오류: '$MODULE_NAME' 서브모듈을 찾을 수 없습니다.${NC}"
            exit 1
        fi

        echo -e "${YELLOW}'$MODULE_NAME' 서브모듈을 업데이트합니다...${NC}"

        if [ -d "$MODULE_PATH" ]; then
            cd "$MODULE_PATH" && git pull origin $(git rev-parse --abbrev-ref HEAD)

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}'$MODULE_NAME' 서브모듈이 성공적으로 업데이트되었습니다.${NC}"
                echo "메인 저장소에서 변경사항을 커밋하려면 다음 명령을 실행하세요:"
                echo "cd $PROJECT_ROOT && git add $MODULE_PATH && git commit -m \"chore: $MODULE_NAME 서브모듈 업데이트\""
            else
                echo -e "${RED}서브모듈 업데이트 중 오류가 발생했습니다.${NC}"
            fi
        else
            echo -e "${RED}오류: '$MODULE_PATH' 디렉토리가 존재하지 않습니다.${NC}"
        fi
    fi
}

# 서브모듈 제거
function remove_submodule {
    if [ $# -lt 1 ]; then
        echo -e "${RED}오류: 제거할 서브모듈 이름을 지정해야 합니다.${NC}"
        echo "사용법: $0 remove [이름]"
        exit 1
    fi

    local MODULE_NAME="$1"
    local MODULE_PATH=""

    # .gitmodules 파일에서 서브모듈 경로 찾기
    if [ -f "$PROJECT_ROOT/.gitmodules" ]; then
        MODULE_PATH=$(git config -f .gitmodules --get "submodule.$MODULE_NAME.path")
    fi

    if [ -z "$MODULE_PATH" ]; then
        echo -e "${RED}오류: '$MODULE_NAME' 서브모듈을 찾을 수 없습니다.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}'$MODULE_NAME' 서브모듈을 제거합니다...${NC}"

    # 1. .gitmodules 파일에서 해당 서브모듈 항목 제거
    git config -f .gitmodules --remove-section "submodule.$MODULE_NAME" 2>/dev/null

    # 2. .git/config 파일에서 해당 서브모듈 항목 제거
    git config --remove-section "submodule.$MODULE_NAME" 2>/dev/null

    # 3. 인덱스에서 서브모듈 제거
    git rm --cached "$MODULE_PATH"

    # 4. .git/modules에서 서브모듈 디렉토리 제거
    rm -rf "$PROJECT_ROOT/.git/modules/$MODULE_NAME"

    # 5. 서브모듈 디렉토리 제거 여부 확인
    read -p "서브모듈 디렉토리 '$MODULE_PATH'를 삭제하시겠습니까? (y/n): " CONFIRM
    if [[ $CONFIRM =~ ^[Yy]$ ]]; then
        rm -rf "$MODULE_PATH"
        echo "서브모듈 디렉토리가 삭제되었습니다."
    else
        echo "서브모듈 디렉토리는 유지됩니다."
    fi

    echo -e "${GREEN}서브모듈 '$MODULE_NAME'이 성공적으로 제거되었습니다.${NC}"
    echo "변경사항을 커밋하려면 다음 명령을 실행하세요:"
    echo "git add .gitmodules"
    echo "git commit -m \"chore: $MODULE_NAME 서브모듈 제거\""
}

# 서브모듈 목록 표시
function list_submodules {
    echo -e "${BLUE}서브모듈 목록:${NC}"

    if [ -f "$PROJECT_ROOT/.gitmodules" ]; then
        git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | \
        while read -r KEY PATH; do
            NAME=$(echo "$KEY" | sed 's/^submodule\.\(.*\)\.path$/\1/')
            URL=$(git config -f .gitmodules --get "submodule.$NAME.url")
            echo -e "${GREEN}$NAME${NC} ($PATH) - $URL"
        done
    else
        echo "서브모듈이 없습니다."
    fi
}

# 서브모듈 상태 확인
function check_status {
    echo -e "${BLUE}서브모듈 상태:${NC}"
    cd "$PROJECT_ROOT" && git submodule status
}

# 메인 함수
function main {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    case "$1" in
        add-local)
            shift
            add_local_submodule "$@"
            ;;
        add-remote)
            shift
            add_remote_submodule "$@"
            ;;
        update)
            shift
            update_submodule "$@"
            ;;
        remove)
            shift
            remove_submodule "$@"
            ;;
        list)
            list_submodules
            ;;
        status)
            check_status
            ;;
        help)
            show_help
            ;;
        *)
            echo -e "${RED}오류: 알 수 없는 명령 '$1'${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@"