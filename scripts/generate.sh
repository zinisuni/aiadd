#!/bin/bash

####################################
# 다이어그램 생성용 유틸 설치
# sudo npm install -g @mermaid-js/mermaid-cli
#
# 1. 파라미터 처리 추가:
#    - 파라미터가 없으면 현재 디렉토리(`.`)를 사용
#    - 파라미터가 있으면 해당 디렉토리가 존재하는지 확인
#    - 디렉토리가 존재하지 않으면 에러 메시지와 함께 종료
# 2. 작업 디렉토리 관리:
#    - 지정된 작업 디렉토리로 이동
#    - 작업 완료 후 원래 디렉토리로 복귀
# 3. 출력 메시지 개선:
#    - 작업 디렉토리 정보 표시
#    - 이미지 생성 완료 메시지에 경로 정보 추가
# 사용 방법:
# ```bash
# # 현재 디렉토리에서 실행
# ./generate.sh
# # 특정 디렉토리에서 실행
# ./generate.sh /path/to/diagrams
# # 상대 경로로 실행
# ./generate.sh ../docs/diagrams
# ```

# 스크립트가 성공적으로 수정되었습니다. 이제 다음과 같이 사용할 수 있습니다:
# 1. 현재 디렉토리의 다이어그램 생성:
# ```bash
# ./scripts/generate.sh
# ```
# 2. 특정 디렉토리의 다이어그램 생성:
# ```bash
# ./scripts/generate.sh docs/development/methodology
# ```
####################################

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