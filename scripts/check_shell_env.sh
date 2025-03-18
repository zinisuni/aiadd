#!/usr/bin/env bash
# 쉘 환경 진단 스크립트
# 이 스크립트는 현재 쉘 환경이 서브쉘 스크립트 실행에 적합한지 확인합니다

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== 쉘 환경 진단 =====${NC}"

# 1. 현재 쉘 확인
echo -e "${YELLOW}1. 현재 쉘 환경${NC}"
CURRENT_SHELL=$(basename "$SHELL")
echo "현재 쉘: $CURRENT_SHELL"
echo "쉘 버전:"

if [ -n "$ZSH_VERSION" ]; then
  echo "ZSH 버전: $ZSH_VERSION"
  echo -e "${GREEN}✓ Zsh는 서브쉘 스크립트에 적합합니다.${NC}"
elif [ -n "$BASH_VERSION" ]; then
  echo "Bash 버전: $BASH_VERSION"
  BASH_MAJOR_VERSION=$(echo $BASH_VERSION | cut -d. -f1)

  if [ "$BASH_MAJOR_VERSION" -ge 4 ]; then
    echo -e "${GREEN}✓ Bash $BASH_VERSION은(는) 서브쉘 스크립트에 적합합니다.${NC}"
  else
    echo -e "${YELLOW}⚠ Bash $BASH_VERSION은(는) 오래된 버전입니다. 4.0 이상으로 업그레이드를 권장합니다.${NC}"
  fi
else
  echo -e "${RED}× 현재 쉘($CURRENT_SHELL)은 명확하게 지원되지 않습니다. Bash 또는 Zsh 사용을 권장합니다.${NC}"
fi

# 2. 서브쉘 기능 테스트
echo -e "\n${YELLOW}2. 서브쉘 기능 테스트${NC}"

# 명령어 치환 테스트
echo "명령어 치환 테스트: $(echo '정상')"
if [ "$(echo '정상')" = "정상" ]; then
  echo -e "${GREEN}✓ 명령어 치환이 정상 작동합니다.${NC}"
else
  echo -e "${RED}× 명령어 치환에 문제가 있습니다.${NC}"
fi

# 서브쉘 변수 테스트
TEST_VAR="외부"
RESULT=$(TEST_VAR="내부"; echo "$TEST_VAR")
echo "서브쉘 변수 테스트: $RESULT (내부여야 정상)"
if [ "$RESULT" = "내부" ]; then
  echo -e "${GREEN}✓ 서브쉘 변수 격리가 정상 작동합니다.${NC}"
else
  echo -e "${RED}× 서브쉘 변수 격리에 문제가 있습니다.${NC}"
fi

# 3. 필수 명령어 확인
echo -e "\n${YELLOW}3. 필수 명령어 확인${NC}"
REQUIRED_COMMANDS="git bash zsh grep sed awk cat echo mkdir cp rm"
MISSING_COMMANDS=()
FOUND_COMMANDS=()

for cmd in $REQUIRED_COMMANDS; do
  if command -v $cmd &> /dev/null; then
    FOUND_COMMANDS+=("$cmd")
  else
    MISSING_COMMANDS+=("$cmd")
  fi
done

if [ ${#MISSING_COMMANDS[@]} -eq 0 ]; then
  echo -e "${GREEN}✓ 모든 필수 명령어를 찾았습니다.${NC}"
else
  echo -e "${YELLOW}⚠ 다음 명령어를 찾을 수 없습니다: ${MISSING_COMMANDS[*]}${NC}"
  echo "이 명령어들은 일부 스크립트 실행에 필요할 수 있습니다."
fi

echo -e "${GREEN}✓ 사용 가능한 명령어: ${FOUND_COMMANDS[*]}${NC}"

# 4. PATH 설정 확인
echo -e "\n${YELLOW}4. PATH 환경 변수 확인${NC}"
echo "현재 PATH:"
echo "$PATH" | tr ':' '\n' | sed 's/^/  /'

# 일반적인 경로 확인
COMMON_PATHS=("/usr/bin" "/bin" "/usr/local/bin" "/usr/sbin" "/sbin")
MISSING_PATHS=()

for path in "${COMMON_PATHS[@]}"; do
  if [[ ":$PATH:" != *":$path:"* ]]; then
    MISSING_PATHS+=("$path")
  fi
done

if [ ${#MISSING_PATHS[@]} -eq 0 ]; then
  echo -e "${GREEN}✓ 모든 일반적인 경로가 PATH에 포함되어 있습니다.${NC}"
else
  echo -e "${YELLOW}⚠ 다음 경로가 PATH에 없습니다: ${MISSING_PATHS[*]}${NC}"
  echo "필요한 경우 .bashrc 또는 .zshrc 파일에 다음을 추가하세요:"
  echo "export PATH=\"\$PATH:${MISSING_PATHS[*]}\""
fi

# 5. 환경 설정 파일 확인
echo -e "\n${YELLOW}5. 쉘 설정 파일 확인${NC}"

check_config_file() {
  local file="$1"
  if [ -f "$file" ]; then
    echo -e "${GREEN}✓ $file 존재${NC}"

    # PATH 설정 확인
    if grep -q "PATH" "$file"; then
      echo "  - PATH 설정 발견"
    fi

    # 환경 변수 확인
    ENV_VAR_COUNT=$(grep -E "^export [A-Z]" "$file" | wc -l)
    echo "  - 환경 변수 설정: 약 $ENV_VAR_COUNT개"
  else
    echo -e "${YELLOW}⚠ $file 파일이 없습니다.${NC}"
  fi
}

if [ "$CURRENT_SHELL" = "zsh" ]; then
  check_config_file "$HOME/.zshrc"
  check_config_file "$HOME/.zprofile"
elif [ "$CURRENT_SHELL" = "bash" ]; then
  check_config_file "$HOME/.bashrc"
  check_config_file "$HOME/.bash_profile"
fi
check_config_file "$HOME/.profile"

# 6. 종합 평가
echo -e "\n${YELLOW}6. 종합 평가${NC}"

# 문제 카운트 계산
issues=0
[ -z "$ZSH_VERSION" ] && [ -z "$BASH_VERSION" ] && ((issues++))
[ ${#MISSING_COMMANDS[@]} -gt 0 ] && ((issues++))
[ ${#MISSING_PATHS[@]} -gt 0 ] && ((issues++))

if [ $issues -eq 0 ]; then
  echo -e "${GREEN}=====================================${NC}"
  echo -e "${GREEN}✓ 환경 진단 결과: 적합${NC}"
  echo -e "${GREEN}  현재 환경은 서브쉘 스크립트 실행에 적합합니다.${NC}"
  echo -e "${GREEN}=====================================${NC}"
elif [ $issues -eq 1 ]; then
  echo -e "${YELLOW}=====================================${NC}"
  echo -e "${YELLOW}⚠ 환경 진단 결과: 경미한 문제${NC}"
  echo -e "${YELLOW}  일부 경미한 문제가 있지만 대부분의 스크립트는 실행 가능합니다.${NC}"
  echo -e "${YELLOW}=====================================${NC}"
else
  echo -e "${RED}=====================================${NC}"
  echo -e "${RED}× 환경 진단 결과: 부적합${NC}"
  echo -e "${RED}  여러 문제가 발견되었습니다. 스크립트 실행에 문제가 있을 수 있습니다.${NC}"
  echo -e "${RED}  위 진단 결과를 참고하여 환경을 개선해주세요.${NC}"
  echo -e "${RED}=====================================${NC}"
fi

echo ""
echo "이 진단 결과를 스크립트 개발자에게 공유하면 문제 해결에 도움이 됩니다."
echo "진단 완료 시간: $(date)"