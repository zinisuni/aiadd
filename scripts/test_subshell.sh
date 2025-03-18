#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== 서브쉘에서 전역 변수 동작 테스트 =====${NC}"

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

echo -e "${GREEN}==== 서브쉘 테스트 완료 ====${NC}"