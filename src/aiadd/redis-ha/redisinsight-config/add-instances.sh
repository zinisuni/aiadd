#!/bin/bash

# RedisInsight 기본 URL
REDISINSIGHT_BASE="http://localhost:8003"

echo "CSRF 토큰을 가져오는 중..."
# 쿠키 파일 생성
COOKIES_FILE=$(mktemp)
echo "쿠키 파일: $COOKIES_FILE"

# 메인 페이지 접속하여 CSRF 토큰 가져오기
curl -s -c $COOKIES_FILE ${REDISINSIGHT_BASE} > /dev/null
curl -s -c $COOKIES_FILE -b $COOKIES_FILE ${REDISINSIGHT_BASE}/api/sessions > /dev/null

# 쿠키 파일에서 CSRF 토큰 추출
CSRF_TOKEN=$(grep csrftoken $COOKIES_FILE | tail -1 | awk '{print $7}')

if [ -z "$CSRF_TOKEN" ]; then
  echo "CSRF 토큰을 가져오지 못했습니다. 웹 인터페이스를 통해 수동으로 인스턴스를 추가해 주세요."
  echo "브라우저에서 http://localhost:8003 에 접속하세요."
  rm -f $COOKIES_FILE
  exit 1
fi

echo "CSRF 토큰: $CSRF_TOKEN"

echo "사용 가능한 API 엔드포인트 확인 중..."
echo -e "\nGET /api/"
curl -v -X GET "${REDISINSIGHT_BASE}/api/" -b $COOKIES_FILE 2>&1

echo -e "\nGET /api/instance/"
curl -v -X GET "${REDISINSIGHT_BASE}/api/instance/" -b $COOKIES_FILE 2>&1

echo -e "\nGET /api/instances/"
curl -v -X GET "${REDISINSIGHT_BASE}/api/instances/" -b $COOKIES_FILE 2>&1

echo -e "\nGET /api/database/"
curl -v -X GET "${REDISINSIGHT_BASE}/api/database/" -b $COOKIES_FILE 2>&1

echo -e "\nGET /api/databases/"
curl -v -X GET "${REDISINSIGHT_BASE}/api/databases/" -b $COOKIES_FILE 2>&1

echo -e "\nGET /api/redis/database/"
curl -v -X GET "${REDISINSIGHT_BASE}/api/redis/database/" -b $COOKIES_FILE 2>&1

echo "RedisInsight API 탐색 완료. 이제 인스턴스 추가를 시도합니다..."

# API 엔드포인트 배열 정의
API_ENDPOINTS=(
  "/api/instance/"
  "/api/instances/"
  "/api/database/"
  "/api/databases/"
  "/api/redis/database/"
)

# 마스터 인스턴스 데이터
MASTER_DATA='{
  "name": "Redis Master",
  "host": "host.docker.internal",
  "port": 6379,
  "connectionType": "STANDALONE"
}'

# 각 API 엔드포인트 시도
for endpoint in "${API_ENDPOINTS[@]}"; do
  echo -e "\n[Master 인스턴스 추가 중... - ${endpoint}]"
  echo "실행 명령어:"
  echo "curl -v -X POST ${REDISINSIGHT_BASE}${endpoint} \\
  -H \"Content-Type: application/json\" \\
  -H \"X-CSRFToken: $CSRF_TOKEN\" \\
  -H \"Referer: ${REDISINSIGHT_BASE}/\" \\
  -b $COOKIES_FILE \\
  -d '$MASTER_DATA'"

  MASTER_RESPONSE=$(curl -v -X POST "${REDISINSIGHT_BASE}${endpoint}" \
    -H "Content-Type: application/json" \
    -H "X-CSRFToken: $CSRF_TOKEN" \
    -H "Referer: ${REDISINSIGHT_BASE}/" \
    -b $COOKIES_FILE \
    -d "$MASTER_DATA" 2>&1)

  echo -e "\nMaster 응답 (${endpoint}):\n$MASTER_RESPONSE"

  # 응답 코드 확인
  if echo "$MASTER_RESPONSE" | grep -q "HTTP/1.1 2"; then
    echo "✅ Redis Master 인스턴스가 성공적으로 추가되었습니다. (API: ${endpoint})"
    WORKING_ENDPOINT="${endpoint}"
    break
  else
    echo "❌ Redis Master 인스턴스 추가에 실패했습니다. (API: ${endpoint})"
  fi
done

# 성공한 엔드포인트가 없으면 종료
if [ -z "$WORKING_ENDPOINT" ]; then
  echo -e "\n모든 API 엔드포인트에서 추가에 실패했습니다."

  # 브라우저에서 직접 확인을 위한 curl 명령 표시
  echo -e "\n수동으로 확인하기 위한 명령어:"
  echo "CSRF_TOKEN=\"$CSRF_TOKEN\""
  echo "curl -v -X POST \"${REDISINSIGHT_BASE}/api/instance/\" \\"
  echo "  -H \"Content-Type: application/json\" \\"
  echo "  -H \"X-CSRFToken: \$CSRF_TOKEN\" \\"
  echo "  -H \"Referer: ${REDISINSIGHT_BASE}/\" \\"
  echo "  -b \"csrftoken=\$CSRF_TOKEN\" \\"
  echo "  -d '$MASTER_DATA'"

  # 쿠키 파일 삭제
  rm -f $COOKIES_FILE

  echo -e "\n====================================================================="
  echo "Redis 인스턴스 추가 작업 실패"
  echo "브라우저에서 http://localhost:8003 에 접속하여 RedisInsight를 사용하려면 수동으로 인스턴스를 추가해야 합니다."
  echo -e "=====================================================================\n"

  echo "수동으로 Redis 인스턴스를 추가하려면 다음 단계를 따르세요:"
  echo "1. 브라우저에서 http://localhost:8003 에 접속"
  echo "2. 'Add Redis Database' 버튼 클릭"
  echo "3. 다음 정보 입력:"
  echo "   - Master: host.docker.internal:6379 (Standalone)"
  echo "   - Replica 1: host.docker.internal:6380 (Standalone)"
  echo "   - Replica 2: host.docker.internal:6381 (Standalone)"
  echo "   - Sentinel: host.docker.internal:26379 (Sentinel, Master 그룹명: mymaster)"

  exit 1
fi

# 성공한 엔드포인트가 있으면 나머지 인스턴스도 추가
echo -e "\n성공한 API 엔드포인트: ${WORKING_ENDPOINT}"

# Replica 1 추가
echo -e "\n[Replica 1 인스턴스 추가 중...]"
echo "실행 명령어:"
echo "curl -v -X POST ${REDISINSIGHT_BASE}${WORKING_ENDPOINT} \\
  -H \"Content-Type: application/json\" \\
  -H \"X-CSRFToken: $CSRF_TOKEN\" \\
  -H \"Referer: ${REDISINSIGHT_BASE}/\" \\
  -b $COOKIES_FILE \\
  -d '{
    \"name\": \"Redis Replica 1\",
    \"host\": \"host.docker.internal\",
    \"port\": 6380,
    \"connectionType\": \"STANDALONE\"
  }'"

REPLICA1_RESPONSE=$(curl -v -X POST "${REDISINSIGHT_BASE}${WORKING_ENDPOINT}" \
  -H "Content-Type: application/json" \
  -H "X-CSRFToken: $CSRF_TOKEN" \
  -H "Referer: ${REDISINSIGHT_BASE}/" \
  -b $COOKIES_FILE \
  -d '{
    "name": "Redis Replica 1",
    "host": "host.docker.internal",
    "port": 6380,
    "connectionType": "STANDALONE"
  }' 2>&1)

echo -e "\nReplica 1 응답:\n$REPLICA1_RESPONSE"

if echo "$REPLICA1_RESPONSE" | grep -q "HTTP/1.1 2"; then
  echo "✅ Redis Replica 1 인스턴스가 성공적으로 추가되었습니다."
else
  echo "❌ Redis Replica 1 인스턴스 추가에 실패했습니다."
fi

# Replica 2 추가
echo -e "\n[Replica 2 인스턴스 추가 중...]"
echo "실행 명령어:"
echo "curl -v -X POST ${REDISINSIGHT_BASE}${WORKING_ENDPOINT} \\
  -H \"Content-Type: application/json\" \\
  -H \"X-CSRFToken: $CSRF_TOKEN\" \\
  -H \"Referer: ${REDISINSIGHT_BASE}/\" \\
  -b $COOKIES_FILE \\
  -d '{
    \"name\": \"Redis Replica 2\",
    \"host\": \"host.docker.internal\",
    \"port\": 6381,
    \"connectionType\": \"STANDALONE\"
  }'"

REPLICA2_RESPONSE=$(curl -v -X POST "${REDISINSIGHT_BASE}${WORKING_ENDPOINT}" \
  -H "Content-Type: application/json" \
  -H "X-CSRFToken: $CSRF_TOKEN" \
  -H "Referer: ${REDISINSIGHT_BASE}/" \
  -b $COOKIES_FILE \
  -d '{
    "name": "Redis Replica 2",
    "host": "host.docker.internal",
    "port": 6381,
    "connectionType": "STANDALONE"
  }' 2>&1)

echo -e "\nReplica 2 응답:\n$REPLICA2_RESPONSE"

if echo "$REPLICA2_RESPONSE" | grep -q "HTTP/1.1 2"; then
  echo "✅ Redis Replica 2 인스턴스가 성공적으로 추가되었습니다."
else
  echo "❌ Redis Replica 2 인스턴스 추가에 실패했습니다."
fi

# Sentinel 추가
echo -e "\n[Sentinel 인스턴스 추가 중...]"
echo "실행 명령어:"
echo "curl -v -X POST ${REDISINSIGHT_BASE}${WORKING_ENDPOINT} \\
  -H \"Content-Type: application/json\" \\
  -H \"X-CSRFToken: $CSRF_TOKEN\" \\
  -H \"Referer: ${REDISINSIGHT_BASE}/\" \\
  -b $COOKIES_FILE \\
  -d '{
    \"name\": \"Redis Sentinel\",
    \"sentinelHost\": \"host.docker.internal\",
    \"sentinelPort\": 26379,
    \"connectionType\": \"SENTINEL\",
    \"sentinelMaster\": \"mymaster\"
  }'"

SENTINEL_RESPONSE=$(curl -v -X POST "${REDISINSIGHT_BASE}${WORKING_ENDPOINT}" \
  -H "Content-Type: application/json" \
  -H "X-CSRFToken: $CSRF_TOKEN" \
  -H "Referer: ${REDISINSIGHT_BASE}/" \
  -b $COOKIES_FILE \
  -d '{
    "name": "Redis Sentinel",
    "sentinelHost": "host.docker.internal",
    "sentinelPort": 26379,
    "connectionType": "SENTINEL",
    "sentinelMaster": "mymaster"
  }' 2>&1)

echo -e "\nSentinel 응답:\n$SENTINEL_RESPONSE"

if echo "$SENTINEL_RESPONSE" | grep -q "HTTP/1.1 2"; then
  echo "✅ Redis Sentinel 인스턴스가 성공적으로 추가되었습니다."
else
  echo "❌ Redis Sentinel 인스턴스 추가에 실패했습니다."
fi

# 쿠키 파일 삭제
echo -e "\n쿠키 파일 삭제 중..."
rm -f $COOKIES_FILE
echo "파일 삭제 완료: $COOKIES_FILE"

# 추가된 인스턴스 목록 확인
echo -e "\n추가된 인스턴스 목록 확인 중..."
echo "curl -s -X GET ${REDISINSIGHT_BASE}${WORKING_ENDPOINT}"
curl -s -X GET "${REDISINSIGHT_BASE}${WORKING_ENDPOINT}" | python -m json.tool 2>/dev/null || curl -s -X GET "${REDISINSIGHT_BASE}${WORKING_ENDPOINT}"

echo -e "\n====================================================================="
echo "Redis 인스턴스 추가 작업 완료"
echo "브라우저에서 http://localhost:8003 에 접속하여 RedisInsight를 사용할 수 있습니다."
echo -e "=====================================================================\n"
