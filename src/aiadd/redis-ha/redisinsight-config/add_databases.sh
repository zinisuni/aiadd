#!/bin/bash

# RedisInsight API를 통한 데이터베이스 자동 등록 스크립트
echo "RedisInsight API를 통한 데이터베이스 자동 등록 스크립트 실행 중..."

# RedisInsight API 엔드포인트 (RedisInsight v2의 API 경로)
API_URL="http://localhost:8003/api/v1"

# 초기 설정은 건너뛰고 데이터베이스 등록으로 바로 진행
echo "Redis 데이터베이스 추가 중..."

# Redis 데이터베이스 정보 정의
REDIS_INSTANCES=(
  "Redis Master|host.docker.internal|6379||Redis Master"
  "Redis Replica 1|host.docker.internal|6380||Redis Replica 1"
  "Redis Replica 2|host.docker.internal|6381||Redis Replica 2"
)

# Redis Sentinel 클러스터 정의
SENTINEL_MASTER_GROUP="mymaster"
SENTINEL_INSTANCES=(
  "host.docker.internal|26379"
  "host.docker.internal|26380"
  "host.docker.internal|26381"
)

# 일반 Redis 데이터베이스 추가 함수
add_redis_database() {
  local NAME=$1
  local HOST=$2
  local PORT=$3
  local PASSWORD=$4
  local DB_NAME=$5

  echo "Redis 데이터베이스 추가: $DB_NAME..."

  # Redis 데이터베이스 추가 요청
  RESULT=$(curl -s -X POST "${API_URL}/instance" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"${DB_NAME}\",
      \"connectionType\": \"STANDALONE\",
      \"host\": \"${HOST}\",
      \"port\": ${PORT},
      \"password\": \"${PASSWORD}\"
    }")

  # 결과 확인
  if [[ $RESULT == *"id"* ]]; then
    echo "Redis 데이터베이스가 성공적으로 추가되었습니다: $DB_NAME"
    return 0
  else
    echo "경고: Redis 데이터베이스 추가 실패: $DB_NAME"
    echo "응답: $RESULT"
    return 1
  fi
}

# Sentinel 클러스터 추가 함수
add_sentinel_cluster() {
  local MASTER_GROUP=$1
  local SENTINELS=$2
  local NAME="Redis Sentinel Cluster"

  echo "Redis Sentinel 클러스터 추가: $NAME..."

  # 센티널 목록 JSON 형식으로 변환
  local SENTINELS_JSON=""
  for sentinel in "${SENTINELS[@]}"; do
    IFS='|' read -r HOST PORT <<< "$sentinel"
    if [ -n "$SENTINELS_JSON" ]; then
      SENTINELS_JSON+=","
    fi
    SENTINELS_JSON+="{\"host\":\"$HOST\",\"port\":$PORT}"
  done

  # Sentinel 클러스터 추가 요청
  RESULT=$(curl -s -X POST "${API_URL}/instance" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"${NAME}\",
      \"connectionType\": \"SENTINEL\",
      \"sentinelMaster\": \"${MASTER_GROUP}\",
      \"sentinels\": [${SENTINELS_JSON}]
    }")

  # 결과 확인
  if [[ $RESULT == *"id"* ]]; then
    echo "Redis Sentinel 클러스터가 성공적으로 추가되었습니다: $NAME"
    return 0
  else
    echo "경고: Redis Sentinel 클러스터 추가 실패: $NAME"
    echo "응답: $RESULT"
    return 1
  fi
}

# RedisInsight가 준비될 때까지 대기
echo "RedisInsight API 준비 대기 중..."
sleep 5

# Redis 인스턴스 추가
for redis in "${REDIS_INSTANCES[@]}"; do
  IFS='|' read -r NAME HOST PORT PASSWORD DB_NAME <<< "$redis"
  add_redis_database "$NAME" "$HOST" "$PORT" "$PASSWORD" "$DB_NAME"
done

# Redis Sentinel 클러스터 추가
add_sentinel_cluster "$SENTINEL_MASTER_GROUP" "${SENTINEL_INSTANCES[@]}"

echo "RedisInsight 데이터베이스 자동 등록 완료"
echo "브라우저에서 http://localhost:8003 으로 접속하여 등록된 데이터베이스를 확인하세요."