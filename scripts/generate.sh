#!/bin/bash

####################################
# 다이어그램 생성용 유틸 설치
# sudo npm install -g @mermaid-js/mermaid-cli
#
# 1. 파라미터 처리:
#    - 파라미터가 없으면 현재 디렉토리(`.`)의 모든 .md 파일 처리
#    - 첫 번째 파라미터가 디렉토리면 해당 디렉토리의 모든 .md 파일 처리
#    - 첫 번째 파라미터가 파일이면 해당 파일만 처리
# 2. 작업 디렉토리 관리:
#    - 지정된 작업 디렉토리로 이동
#    - 작업 완료 후 원래 디렉토리로 복귀
# 3. 출력 메시지 개선:
#    - 작업 정보 표시
#    - 이미지 생성 완료 메시지에 경로 정보 추가
####################################

# 초기 설정
IMAGE_DIR="images"
CURRENT_DIR=$(pwd)

# 파라미터 처리
TARGET="$1"
if [ -z "$TARGET" ]; then
    # 파라미터가 없으면 현재 디렉토리 사용
    WORK_DIR="."
    MODE="directory"
elif [ -d "$TARGET" ]; then
    # 디렉토리인 경우
    WORK_DIR="$TARGET"
    MODE="directory"
    echo "Working directory: $WORK_DIR"
elif [ -f "$TARGET" ]; then
    # 파일인 경우
    WORK_DIR=$(dirname "$TARGET")
    FILE_NAME=$(basename "$TARGET")
    MODE="file"
    echo "Processing file: $TARGET"
else
    echo "Error: '$TARGET' is neither a valid file nor directory."
    exit 1
fi

# 작업 디렉토리로 이동
cd "$WORK_DIR" || exit 1

# 이미지 디렉토리 생성
mkdir -p $IMAGE_DIR

# 다이어그램 생성 함수
generate_diagram() {
    local file="$1"
    local filename=$(basename "$file" .md)
    echo "Generating diagram for $file..."
    mmdc -i "$file" -o "$IMAGE_DIR/${filename}.png" -b transparent -s 4 -q 1
}

# 모드에 따른 처리
if [ "$MODE" = "directory" ]; then
    # 디렉토리 모드: 모든 .md 파일 처리
    for file in *.md; do
        if [ -f "$file" ]; then  # 파일이 실제로 존재하는지 확인
            generate_diagram "$file"
        fi
    done
else
    # 파일 모드: 단일 파일 처리
    if [[ "$FILE_NAME" == *.md ]]; then
        generate_diagram "$FILE_NAME"
    else
        echo "Error: '$FILE_NAME' is not a markdown file."
        exit 1
    fi
fi

echo "All diagrams have been generated in $WORK_DIR/$IMAGE_DIR!"

# 원래 디렉토리로 복귀
cd "$CURRENT_DIR"