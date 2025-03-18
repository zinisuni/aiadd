#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 초기 환경 검증 함수
check_environment() {
  echo -e "${BLUE}===== 실행 환경 검증 중 =====${NC}"

  # 1. 쉘 환경 확인
  if [ -n "$ZSH_VERSION" ]; then
    DETECTED_SHELL="zsh"
    # zsh 버전 확인 - 실제 명령어로 확인
    ZSH_VERSION_OUTPUT=$(zsh --version 2>/dev/null)
    if [ $? -ne 0 ]; then
      echo -e "${YELLOW}⚠️ zsh 버전 확인 실패: zsh 명령을 직접 실행할 수 없습니다.${NC}"
      echo "환경 변수 버전 정보: $ZSH_VERSION"
    else
      echo "zsh 버전: $ZSH_VERSION_OUTPUT"
    fi
  elif [ -n "$BASH_VERSION" ]; then
    DETECTED_SHELL="bash"
    # Bash 버전 확인 - bash --version 명령으로 직접 확인
    BASH_VERSION_OUTPUT=$(bash --version 2>/dev/null | head -n 1)
    if [ $? -ne 0 ]; then
      echo -e "${RED}오류: bash 명령을 실행할 수 없습니다.${NC}"
      echo "환경 변수 버전 정보: $BASH_VERSION"
      return 1
    fi

    echo "Bash 버전: $BASH_VERSION_OUTPUT"

    # 버전 번호 추출 (GNU bash, version 5.1.16 -> 5)
    MAJOR_VERSION=$(echo "$BASH_VERSION_OUTPUT" | grep -oE 'version [0-9]+' | grep -oE '[0-9]+')

    if [ -z "$MAJOR_VERSION" ]; then
      echo -e "${YELLOW}⚠️ 버전 번호를 추출할 수 없습니다. 환경 변수 사용.${NC}"
      # 환경 변수에서 추출 (대체 방법)
      MAJOR_VERSION=$(echo $BASH_VERSION | cut -d. -f1)
    fi

    if [ "$MAJOR_VERSION" -lt 4 ]; then
      echo -e "${RED}오류: Bash 버전이 너무 낮습니다. 4.0 이상이 필요합니다.${NC}"
      echo "설치 방법: brew install bash (macOS) 또는 apt-get install bash (Ubuntu)"
      return 1
    fi
  else
    echo -e "${RED}오류: 지원되지 않는 쉘 환경입니다. Bash 또는 Zsh를 사용해주세요.${NC}"
    echo "현재 감지된 쉘: $SHELL"
    # 시스템에 bash가 설치되어 있는지 확인
    if command -v bash &>/dev/null; then
      echo -e "${YELLOW}bash 명령이 발견되었습니다. 다음 명령으로 실행해보세요:${NC}"
      echo "bash $(basename $0)"
    fi
    return 1
  fi

  # 2. 필수 명령어 확인
  local REQUIRED_COMMANDS="grep echo cat"
  local MISSING_COMMANDS=""

  for cmd in $REQUIRED_COMMANDS; do
    if ! command -v $cmd &> /dev/null; then
      MISSING_COMMANDS="$MISSING_COMMANDS $cmd"
    fi
  done

  if [ -n "$MISSING_COMMANDS" ]; then
    echo -e "${RED}오류: 다음 필수 명령어를 찾을 수 없습니다:${NC}$MISSING_COMMANDS"
    echo "이 스크립트를 실행하기 위해 필요한 패키지를 설치해주세요."
    return 1
  fi

  # 3. 서브쉘 테스트
  local SUBSHELL_TEST=$(echo "테스트" 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo -e "${RED}오류: 서브쉘 실행 테스트에 실패했습니다.${NC}"
    return 1
  fi

  # 환경 검증 성공
  echo -e "${GREEN}환경 검증 성공:${NC} $DETECTED_SHELL 쉘, 모든 필수 명령어 사용 가능"
  return 0
}

# 환경 검증 실행
if ! check_environment; then
  echo -e "${RED}===== 환경 검증 실패: 스크립트를 종료합니다 =====${NC}"
  exit 1
fi

# 환경 설정 - 서브쉘에서 명령어를 찾지 못하는 문제 해결
# 현재 쉘 감지
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

# PATH 환경 변수 설정
export PATH="$HOME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# 자주 사용하는 명령어 경로 설정
ECHO_CMD=$(command -v echo || echo "/bin/echo")
GREP_CMD=$(command -v grep || echo "/usr/bin/grep")
CAT_CMD=$(command -v cat || echo "/bin/cat")

echo -e "${BLUE}===== 서브쉘에서 전역 변수 동작 테스트 =====${NC}"
echo -e "${GREEN}실행 환경: $DETECTED_SHELL 쉘${NC}"

# 케이스 1: export 없는 일반 변수 (서브쉘에서 접근 가능)
NORMAL_VAR="일반 변수"
echo -e "${YELLOW}케이스 1: export 없는 일반 변수${NC}"
echo "부모 쉘: NORMAL_VAR = $NORMAL_VAR"
echo "서브쉘: NORMAL_VAR = $(echo $NORMAL_VAR)"
echo ""

# 케이스 2: export 된 환경 변수 (서브쉘에서 접근 가능)
export EXPORTED_VAR="내보낸 변수"
echo -e "${YELLOW}케이스 2: export 된 환경 변수${NC}"
echo "부모 쉘: EXPORTED_VAR = $EXPORTED_VAR"
echo "서브쉘: EXPORTED_VAR = $(echo $EXPORTED_VAR)"
echo ""

# 케이스 3: 서브쉘에서 변경한 변수 (부모 쉘에 영향 없음)
TEST_VAR="원래 값"
echo -e "${YELLOW}케이스 3: 서브쉘에서 변경한 변수${NC}"
echo "변경 전 부모 쉘: TEST_VAR = $TEST_VAR"
SUBSHELL_OUTPUT=$(TEST_VAR="서브쉘에서 변경한 값"; echo "TEST_VAR = $TEST_VAR")
echo "서브쉘 내부: $SUBSHELL_OUTPUT"
echo "변경 후 부모 쉘: TEST_VAR = $TEST_VAR (서브쉘의 변경이 부모에 영향 없음)"
echo ""

# 케이스 4: Command Substitution과 변수 할당
echo -e "${YELLOW}케이스 4: Command Substitution과 변수 할당${NC}"
VAR_FROM_SUBSHELL=$(echo "서브쉘의 출력")
echo "서브쉘 출력을 변수에 저장: VAR_FROM_SUBSHELL = $VAR_FROM_SUBSHELL"
echo ""

# 케이스 5: 서브쉘에서 선언한 변수 (부모 쉘에서 접근 불가)
echo -e "${YELLOW}케이스 5: 서브쉘에서 선언한 변수${NC}"
SUBSHELL_RESULT=$(SUBSHELL_ONLY_VAR="서브쉘에서만 존재하는 변수"; echo "SUBSHELL_ONLY_VAR = $SUBSHELL_ONLY_VAR")
echo "서브쉘 내부: $SUBSHELL_RESULT"
echo "부모 쉘: SUBSHELL_ONLY_VAR = $SUBSHELL_ONLY_VAR (정의되지 않음)"
echo ""

# 케이스 6: 파이프라인과 서브쉘
echo -e "${YELLOW}케이스 6: 파이프라인과 서브쉘${NC}"
PIPE_VAR="파이프 이전 값"
echo "파이프 이전: PIPE_VAR = $PIPE_VAR"
echo "파이프라인 테스트" | { PIPE_VAR="파이프 내부 값"; echo "파이프 내부: PIPE_VAR = $PIPE_VAR"; }
echo "파이프 이후: PIPE_VAR = $PIPE_VAR (파이프 내부 변경이 부모에 영향 없음)"
echo ""

# 케이스 7: 함수와 서브쉘
echo -e "${YELLOW}케이스 7: 함수와 서브쉘${NC}"
test_function() {
    echo "이 함수는 부모 쉘에서 정의되었습니다."
}

echo "부모 쉘에서 함수 호출:"
test_function

echo "일반 서브쉘에서 함수 호출:"
FUNC_RESULT=$(test_function)
echo "$FUNC_RESULT"

echo "진정한 격리된 서브쉘에서는 함수 접근 불가(하지만 bash에서는 작동):"
( echo "진정한 서브쉘"; test_function )
echo ""

# 케이스 8: 환경 변수 전달
echo -e "${YELLOW}케이스 8: 환경 변수 전달${NC}"
# 일반 변수는 서브쉘에 전달되지만 독립적인 서브쉘에는 전달되지 않음
REGULAR_VAR="일반 변수 값"
echo "부모 쉘: REGULAR_VAR = $REGULAR_VAR"
echo "일반 서브쉘: REGULAR_VAR = $(echo $REGULAR_VAR)"
echo "독립적인 서브쉘:"
(REGULAR_VAR="변경된 값"; echo "  내부: REGULAR_VAR = $REGULAR_VAR")
echo "부모 쉘(변경 후): REGULAR_VAR = $REGULAR_VAR (변경되지 않음)"

# export 변수는 서브쉘에 전달됨
echo ""
export EXPORTED_VAR2="내보낸 변수 값"
echo "부모 쉘: EXPORTED_VAR2 = $EXPORTED_VAR2"
echo "서브쉘에서: EXPORTED_VAR2 = $(echo $EXPORTED_VAR2)"
echo "독립적인 서브쉘에서 변경 시도:"
(export EXPORTED_VAR2="서브쉘에서 변경"; echo "  내부: EXPORTED_VAR2 = $EXPORTED_VAR2")
echo "부모 쉘(변경 시도 후): EXPORTED_VAR2 = $EXPORTED_VAR2 (변경되지 않음)"
echo ""

# 케이스 9: 서브쉘로 정보 전달하기
echo -e "${YELLOW}케이스 9: 서브쉘로 정보 전달하기${NC}"
echo "1. 환경 변수로 전달:"
export FOR_SUBSHELL="환경 변수로 전달된 값"
(echo "  서브쉘에서 접근: FOR_SUBSHELL = $FOR_SUBSHELL")

echo "2. 인자 전달 시뮬레이션:"
val="인자값"
(echo "  서브쉘에서 접근: val = $val")

echo "3. 파이프로 전달:"
echo "파이프로 전달된 값" | (read value; echo "  서브쉘에서 파이프로 받음: $value")

echo "4. 명시적 변수 전달(eval):"
VAR_TO_PASS="전달할 값"
(eval "MY_VAR=\"$VAR_TO_PASS\""; echo "  서브쉘에서 eval로 받음: MY_VAR = $MY_VAR")
echo ""

# 케이스 10: 서브쉘에서 부모 쉘로 정보 전달하기
echo -e "${YELLOW}케이스 10: 서브쉘에서 부모 쉘로 정보 전달하기${NC}"
echo "1. 출력 캡처:"
CAPTURED_OUTPUT=$(echo "서브쉘의 출력")
echo "  부모 쉘에서 캡처한 값: $CAPTURED_OUTPUT"

echo "2. 임시 파일 사용(예시만 표시):"
echo "  # 서브쉘에서 파일에 쓰기"
echo "  # (echo 'temp_data' > /tmp/data)"
echo "  # 부모 쉘에서 읽기"
echo "  # TEMP_DATA=\$(cat /tmp/data)"

echo "3. 명령어 대체:"
CALC_RESULT=$((5 + 7))
echo "  계산 결과: $CALC_RESULT"

echo "4. 부모로 변수 전달하는 방법이 없음:"
TEMP_VAR="원래 값"
SUB_RESULT=$(TEMP_VAR="서브쉘에서 변경"; echo "TEMP_VAR = $TEMP_VAR")
echo "  서브쉘 내부: $SUB_RESULT"
echo "  부모 쉘: TEMP_VAR = $TEMP_VAR (전달되지 않음)"
echo ""

# 케이스 11: 서브쉘에서 명령어 경로 문제 해결
echo -e "${YELLOW}케이스 11: 서브쉘에서 명령어 경로 문제 해결${NC}"
echo "1. 문제 시연 (주석 처리됨):"
echo "  # 잘못된 방법 - 서브쉘에서 명령어를 찾지 못할 수 있음"
echo "  # \$(grep \"pattern\" <<< \"test string\")"

echo "2. 해결책 1 - 명령어 경로 변수화:"
echo "  test string" | $GREP_CMD "string"
echo "  결과: 성공 (미리 찾은 GREP_CMD 변수 사용)"

echo "3. 해결책 2 - 서브쉘에서 PATH 설정:"
(
  # 서브쉘 내에서 PATH 설정
  export PATH="$HOME/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
  grep_result=$(grep "test" <<< "test string" 2>/dev/null)
  echo "  결과: $grep_result (서브쉘 내에서 PATH 설정)"
)

echo "4. 해결책 3 - 함수 내보내기 (bash 전용):"
if [ -n "$BASH_VERSION" ]; then
  # bash에서만 작동하는 함수 내보내기
  find_in_text() {
    grep "$1" <<< "$2"
  }
  export -f find_in_text

  result=$(find_in_text "test" "test string")
  echo "  결과: $result (내보낸 함수 사용)"
else
  echo "  결과: bash가 아니므로 함수 내보내기 테스트를 건너뜁니다."
fi
echo ""

echo -e "${GREEN}==== 서브쉘 테스트 완료 ====${NC}"
echo "더 자세한 내용은 SUBSHELL_README.md 파일을 참조하세요."