#!/bin/bash

# RedisInsight 기본 URL
REDISINSIGHT_BASE="http://localhost:8003"
REDISINSIGHT_API="${REDISINSIGHT_BASE}/api/instance"

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

echo "Redis 인스턴스를 RedisInsight에 추가합니다..."

# Master 인스턴스 추가
echo "Master 인스턴스 추가 중..."
MASTER_RESPONSE=$(curl -s -X POST $REDISINSIGHT_API \
  -H "Content-Type: application/json" \
  -H "X-CSRFToken: $CSRF_TOKEN" \
  -H "Referer: ${REDISINSIGHT_BASE}/" \
  -b $COOKIES_FILE \
  -d '{
    "name": "Redis Master",
    "host": "host.docker.internal",
    "port": 6379,
    "connectionType": "STANDALONE"
  }')

echo "Master 응답: $MASTER_RESPONSE"

# Replica 1 추가
echo "Replica 1 인스턴스 추가 중..."
REPLICA1_RESPONSE=$(curl -s -X POST $REDISINSIGHT_API \
  -H "Content-Type: application/json" \
  -H "X-CSRFToken: $CSRF_TOKEN" \
  -H "Referer: ${REDISINSIGHT_BASE}/" \
  -b $COOKIES_FILE \
  -d '{
    "name": "Redis Replica 1",
    "host": "host.docker.internal",
    "port": 6380,
    "connectionType": "STANDALONE"
  }')

echo "Replica 1 응답: $REPLICA1_RESPONSE"

# Replica 2 추가
echo "Replica 2 인스턴스 추가 중..."
REPLICA2_RESPONSE=$(curl -s -X POST $REDISINSIGHT_API \
  -H "Content-Type: application/json" \
  -H "X-CSRFToken: $CSRF_TOKEN" \
  -H "Referer: ${REDISINSIGHT_BASE}/" \
  -b $COOKIES_FILE \
  -d '{
    "name": "Redis Replica 2",
    "host": "host.docker.internal",
    "port": 6381,
    "connectionType": "STANDALONE"
  }')

echo "Replica 2 응답: $REPLICA2_RESPONSE"

# Sentinel 추가
echo "Sentinel 인스턴스 추가 중..."
SENTINEL_RESPONSE=$(curl -s -X POST $REDISINSIGHT_API \
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
  }')

echo "Sentinel 응답: $SENTINEL_RESPONSE"

# 쿠키 파일 삭제
rm -f $COOKIES_FILE

echo ""
echo "====================================================================="
echo "Redis 인스턴스 추가 완료"
echo "브라우저에서 http://localhost:8003 에 접속하여 RedisInsight를 사용하실 수 있습니다."
echo "====================================================================="
