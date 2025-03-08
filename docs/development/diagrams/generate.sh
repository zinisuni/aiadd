#!/bin/bash

# 이미지 디렉토리 생성
IMAGE_DIR="images"
mkdir -p $IMAGE_DIR

# 모든 .md 파일에 대해 다이어그램 생성
for file in *.md; do
    if [ "$file" != "README.md" ]; then
        filename=$(basename "$file" .md)
        echo "Generating diagram for $file..."
        mmdc -i "$file" -o "$IMAGE_DIR/${filename}.png"
    fi
done

echo "All diagrams have been generated!"