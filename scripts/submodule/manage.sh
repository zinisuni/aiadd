#!/usr/bin/env bash
# 쉘 스크립트 자동 감지 - #!/bin/zsh에서 변경
# /usr/bin/env를 사용해 시스템에 설치된 bash를 사용

# 서브모듈 관리 스크립트
# 사용법: ./manage.sh [명령] [옵션]

# 현재 쉘 환경 감지 및 설정 로드
if [ -n "$ZSH_VERSION" ]; then
    DETECTED_SHELL="zsh"
    [ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc" 2>/dev/null || true
elif [ -n "$BASH_VERSION" ]; then
    DETECTED_SHELL="bash"
    [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true
else
    DETECTED_SHELL="sh"
    [ -f "$HOME/.profile" ] && source "$HOME/.profile" 2>/dev/null || true
fi

# 시스템 기본 PATH 설정
export PATH="$HOME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# 명령어 경로 찾기 유틸리티 함수
find_command_path() {
    local cmd="$1"
    local default_path="$2"
    local cmd_path=""

    # 방법 1: command -v 사용 (which보다 이식성 좋음)
    cmd_path=$(command -v "$cmd" 2>/dev/null || echo "")

    # 방법 2: 직접 경로 확인
    if [ -z "$cmd_path" ]; then
        for dir in /bin /usr/bin /usr/local/bin /opt/homebrew/bin; do
            if [ -x "$dir/$cmd" ]; then
                cmd_path="$dir/$cmd"
                break
            fi
        done
    fi

    # 결과 출력
    if [ -n "$cmd_path" ]; then
        echo "$cmd_path"
    else
        echo "$default_path"
    fi
}

# 자주 사용하는 명령어 경로 설정
GIT_CMD=$(find_command_path "git" "/usr/bin/git")
SED_CMD=$(find_command_path "sed" "/usr/bin/sed")
AWK_CMD=$(find_command_path "awk" "/usr/bin/awk")
GREP_CMD=$(find_command_path "grep" "/usr/bin/grep")
MKDIR_CMD=$(find_command_path "mkdir" "/bin/mkdir")
CP_CMD=$(find_command_path "cp" "/bin/cp")
RM_CMD=$(find_command_path "rm" "/bin/rm")

# OS 감지
case "$(uname -s)" in
    Darwin*)  OS_TYPE="macos" ;;
    Linux*)   OS_TYPE="linux" ;;
    CYGWIN*)  OS_TYPE="cygwin" ;;
    MINGW*)   OS_TYPE="windows" ;;
    *)        OS_TYPE="unknown" ;;
esac

# 초기 진단 정보 출력 (디버깅용, 실제 실행시 주석 처리 가능)
# echo "실행 환경: $DETECTED_SHELL 쉘, $OS_TYPE 운영체제"
# echo "Git 경로: $GIT_CMD"
# echo "Sed 경로: $SED_CMD"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 프로젝트 루트 디렉토리 설정
PROJECT_ROOT="$($GIT_CMD rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$PROJECT_ROOT" ]; then
    echo -e "${RED}오류: Git 저장소가 아닙니다.${NC}"
    exit 1
fi

# 유틸리티 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

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
        log_error "경로와 이름을 지정해야 합니다."
        echo "사용법: $0 add-local [경로] [이름]"
        exit 1
    fi

    local MODULE_PATH="$1"
    local MODULE_NAME="$2"

    log_info "로컬 디렉토리 '$MODULE_PATH'를 '$MODULE_NAME' 서브모듈로 추가합니다..."

    # 1. 디렉토리가 존재하는지 확인
    if [ ! -d "$MODULE_PATH" ]; then
        log_error "'$MODULE_PATH' 디렉토리가 존재하지 않습니다."
        exit 1
    fi

    # 2. 디렉토리가 Git 저장소인지 확인
    if [ ! -d "$MODULE_PATH/.git" ]; then
        log_error "'$MODULE_PATH'는 Git 저장소가 아닙니다."
        exit 1
    fi

    # 3. 메인 저장소에서 해당 디렉토리 제거 (인덱스에서만 제거, 파일은 유지)
    echo "메인 저장소에서 디렉토리 제거 중..."
    $GIT_CMD rm --cached -r "$MODULE_PATH"

    # 4. .git/modules/ 디렉토리에 bare 레포지토리 생성
    echo "Bare 레포지토리 생성 중..."
    $MKDIR_CMD -p "$PROJECT_ROOT/.git/modules/$MODULE_NAME"
    $CP_CMD -r "$MODULE_PATH/.git/"* "$PROJECT_ROOT/.git/modules/$MODULE_NAME/"

    # 5. 서브모듈 디렉토리의 .git 파일 설정
    echo "서브모듈 .git 파일 설정 중..."
    $RM_CMD -rf "$MODULE_PATH/.git"

    # 상대 경로 계산
    local REL_PATH
    if command -v python >/dev/null 2>&1; then
        REL_PATH=$(python -c "import os.path; print(os.path.relpath('$PROJECT_ROOT/.git/modules/$MODULE_NAME', '$(dirname "$MODULE_PATH")'))")
    else
        # python이 없는 경우 직접 경로 지정
        REL_PATH="../../.git/modules/$MODULE_NAME"
    fi
    echo "gitdir: $REL_PATH" > "$MODULE_PATH/.git"

    # 6. .gitmodules 파일에 서브모듈 정보 추가
    echo ".gitmodules 파일 업데이트 중..."
    if [ -f "$PROJECT_ROOT/.gitmodules" ]; then
        # 이미 해당 서브모듈이 있는지 확인
        if $GREP_CMD -q "\\[submodule \"$MODULE_NAME\"\\]" "$PROJECT_ROOT/.gitmodules"; then
            log_warn "'$MODULE_NAME' 서브모듈이 이미 .gitmodules 파일에 존재합니다."
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
    cd "$PROJECT_ROOT" && $GIT_CMD submodule init && $GIT_CMD submodule update

    log_info "서브모듈 '$MODULE_NAME'이 성공적으로 추가되었습니다."
    echo "변경사항을 커밋하려면 다음 명령을 실행하세요:"
    echo "$GIT_CMD add .gitmodules $MODULE_PATH"
    echo "$GIT_CMD commit -m \"feat: $MODULE_NAME 서브모듈 추가\""
}

# 원격 저장소를 서브모듈로 추가
function add_remote_submodule {
    if [ $# -lt 2 ]; then
        log_error "URL과 경로를 지정해야 합니다."
        echo "사용법: $0 add-remote [URL] [경로]"
        exit 1
    fi

    local REPO_URL="$1"
    local MODULE_PATH="$2"

    log_info "원격 저장소 '$REPO_URL'를 '$MODULE_PATH' 경로에 서브모듈로 추가합니다..."

    # 서브모듈 추가
    cd "$PROJECT_ROOT" && $GIT_CMD submodule add "$REPO_URL" "$MODULE_PATH"

    if [ $? -eq 0 ]; then
        log_info "서브모듈이 성공적으로 추가되었습니다."
        echo "변경사항을 커밋하려면 다음 명령을 실행하세요:"
        echo "$GIT_CMD commit -m \"feat: $(basename "$MODULE_PATH") 서브모듈 추가\""
    else
        log_error "서브모듈 추가 중 오류가 발생했습니다."
    fi
}

# 서브모듈 업데이트
function update_submodule {
    cd "$PROJECT_ROOT"

    if [ $# -eq 0 ]; then
        log_info "모든 서브모듈을 업데이트합니다..."
        $GIT_CMD submodule update --remote

        if [ $? -eq 0 ]; then
            log_info "모든 서브모듈이 성공적으로 업데이트되었습니다."
        else
            log_error "서브모듈 업데이트 중 오류가 발생했습니다."
        fi
    else
        local MODULE_NAME="$1"
        local MODULE_PATH=""

        # .gitmodules 파일에서 서브모듈 경로 찾기
        if [ -f "$PROJECT_ROOT/.gitmodules" ]; then
            MODULE_PATH=$($GIT_CMD config -f .gitmodules --get "submodule.$MODULE_NAME.path")
        fi

        if [ -z "$MODULE_PATH" ]; then
            log_error "'$MODULE_NAME' 서브모듈을 찾을 수 없습니다."
            exit 1
        fi

        log_info "'$MODULE_NAME' 서브모듈을 업데이트합니다..."

        if [ -d "$MODULE_PATH" ]; then
            cd "$MODULE_PATH" && $GIT_CMD pull origin $($GIT_CMD rev-parse --abbrev-ref HEAD)

            if [ $? -eq 0 ]; then
                log_info "'$MODULE_NAME' 서브모듈이 성공적으로 업데이트되었습니다."
                echo "메인 저장소에서 변경사항을 커밋하려면 다음 명령을 실행하세요:"
                echo "cd $PROJECT_ROOT && $GIT_CMD add $MODULE_PATH && $GIT_CMD commit -m \"chore: $MODULE_NAME 서브모듈 업데이트\""
            else
                log_error "서브모듈 업데이트 중 오류가 발생했습니다."
            fi
        else
            log_error "'$MODULE_PATH' 디렉토리가 존재하지 않습니다."
        fi
    fi
}

# 서브모듈 제거
function remove_submodule {
    if [ $# -lt 1 ]; then
        log_error "제거할 서브모듈 이름을 지정해야 합니다."
        echo "사용법: $0 remove [이름]"
        exit 1
    fi

    local MODULE_NAME="$1"
    local MODULE_PATH=""

    # .gitmodules 파일에서 서브모듈 경로 찾기
    if [ -f "$PROJECT_ROOT/.gitmodules" ]; then
        MODULE_PATH=$($GIT_CMD config -f .gitmodules --get "submodule.$MODULE_NAME.path")
    fi

    if [ -z "$MODULE_PATH" ]; then
        log_error "'$MODULE_NAME' 서브모듈을 찾을 수 없습니다."
        exit 1
    fi

    log_info "'$MODULE_NAME' 서브모듈을 제거합니다..."

    # 1. .gitmodules 파일에서 해당 서브모듈 항목 제거
    $GIT_CMD config -f .gitmodules --remove-section "submodule.$MODULE_NAME" 2>/dev/null

    # 2. .git/config 파일에서 해당 서브모듈 항목 제거
    $GIT_CMD config --remove-section "submodule.$MODULE_NAME" 2>/dev/null

    # 3. 인덱스에서 서브모듈 제거
    $GIT_CMD rm --cached "$MODULE_PATH"

    # 4. .git/modules에서 서브모듈 디렉토리 제거
    $RM_CMD -rf "$PROJECT_ROOT/.git/modules/$MODULE_NAME"

    # 5. 서브모듈 디렉토리 제거 여부 확인
    read -p "서브모듈 디렉토리 '$MODULE_PATH'를 삭제하시겠습니까? (y/n): " CONFIRM
    if [[ $CONFIRM =~ ^[Yy]$ ]]; then
        $RM_CMD -rf "$MODULE_PATH"
        echo "서브모듈 디렉토리가 삭제되었습니다."
    else
        echo "서브모듈 디렉토리는 유지됩니다."
    fi

    log_info "서브모듈 '$MODULE_NAME'이 성공적으로 제거되었습니다."
    echo "변경사항을 커밋하려면 다음 명령을 실행하세요:"
    echo "$GIT_CMD add .gitmodules"
    echo "$GIT_CMD commit -m \"chore: $MODULE_NAME 서브모듈 제거\""
}

# 서브모듈 목록 표시
function list_submodules {
    echo -e "${BLUE}서브모듈 목록:${NC}"

    if [ -f "$PROJECT_ROOT/.gitmodules" ]; then
        $GIT_CMD config -f .gitmodules --get-regexp '^submodule\..*\.path$' | \
        while read -r KEY PATH; do
            NAME=$($SED_CMD 's/^submodule\.\(.*\)\.path$/\1/' <<< "$KEY")
            URL=$($GIT_CMD config -f .gitmodules --get "submodule.$NAME.url")
            echo -e "${GREEN}$NAME${NC} ($PATH) - $URL"
        done
    else
        echo "서브모듈이 없습니다."
    fi
}

# 서브모듈 상태 확인
function check_status {
    echo -e "${BLUE}서브모듈 상태:${NC}"
    cd "$PROJECT_ROOT" && $GIT_CMD submodule status
}

# 메인 함수
function main {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    # 명령어 처리
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

# 메인 함수 실행
main "$@"