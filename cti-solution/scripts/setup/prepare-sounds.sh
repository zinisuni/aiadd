#!/bin/bash

# 음성 파일 디렉토리 생성
mkdir -p sounds

# 기본 인사말 생성 (텍스트를 음성으로 변환)
echo "안녕하세요. CTI 시스템 테스트입니다." > sounds/welcome.txt
echo "1번은 상담원 연결, 2번은 자동 안내입니다." > sounds/menu.txt
echo "상담원과 연결합니다. 잠시만 기다려주세요." > sounds/transfer-to-agent.txt
echo "자동 안내 서비스입니다." > sounds/auto-service.txt
echo "잘못된 입력입니다. 다시 시도해주세요." > sounds/invalid-option.txt

# 컨테이너 내부에서 음성 파일 변환 실행
docker-compose exec asterisk bash -c '
  for file in /var/lib/asterisk/sounds/custom/*.txt; do
    if [ -f "$file" ]; then
      base=$(basename "$file" .txt)
      text=$(cat "$file")
      echo "$text" | text2wave -o "${file%.*}.wav"
      sox "${file%.*}.wav" -r 8000 -c 1 "${file%.*}.gsm"
      rm "${file%.*}.wav"
      rm "$file"
    fi
  done
'