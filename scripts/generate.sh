#!/bin/bash

# 작업 경로 처리
WORK_DIR="."
if [ "$1" != "" ]; then
    if [ -d "$1" ]; then
        WORK_DIR="$1"
        echo "Working directory: $WORK_DIR"
    else
        echo "Error: Directory '$1' does not exist."
        exit 1
    fi
fi

# 작업 디렉토리로 이동
cd "$WORK_DIR" || exit 1

# 이미지 디렉토리 생성
IMAGE_DIR="images"
mkdir -p $IMAGE_DIR

# 모든 .md 파일에 대해 다이어그램 생성
for file in *.md; do
    if [ "$file" != "README.md" ]; then
        filename=$(basename "$file" .md)
        echo "Generating diagram for $file..."
        # 이미지 품질 향상을 위한 옵션 추가
        # -b transparent: 배경을 투명하게
        # -s 4: 4배 크기로 스케일업
        # --pdfFit: PDF 출력시 페이지에 맞춤
        # -q 1: 최고 품질 설정
        mmdc -i "$file" -o "$IMAGE_DIR/${filename}.png" -b transparent -s 4 -q 1
    fi
done

echo "All diagrams have been generated in $WORK_DIR/$IMAGE_DIR!"

# 원래 디렉토리로 복귀 (필요한 경우를 위해)
cd - > /dev/null