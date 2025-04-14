#!/bin/bash

echo "RedisInsight 컨테이너 설정을 시작합니다..."

# 기존 컨테이너 중지 및 제거
docker stop redisinsight 2>/dev/null
docker rm redisinsight 2>/dev/null

# RedisInsight 컨테이너 시작
echo "RedisInsight 컨테이너를 시작합니다..."
docker run -d --name redisinsight -p 8003:8001 redislabs/redisinsight:latest

# 컨테이너가 완전히 시작될 때까지 대기
echo "RedisInsight 컨테이너가 완전히 시작될 때까지 잠시 대기합니다..."
sleep 5

# RedisInsight API 엔드포인트
REDISINSIGHT_API="http://localhost:8003/api/instance"

# Redis 인스턴스 자동 추가
echo "Redis 인스턴스를 자동으로 추가합니다..."

# Master 인스턴스 추가
echo "Master 인스턴스 추가 중..."
curl -X POST $REDISINSIGHT_API \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Redis Master",
    "host": "host.docker.internal",
    "port": 6379,
    "connectionType": "STANDALONE"
  }' 2>/dev/null

# Replica 1 추가
echo "Replica 1 인스턴스 추가 중..."
curl -X POST $REDISINSIGHT_API \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Redis Replica 1",
    "host": "host.docker.internal",
    "port": 6380,
    "connectionType": "STANDALONE"
  }' 2>/dev/null

# Replica 2 추가
echo "Replica 2 인스턴스 추가 중..."
curl -X POST $REDISINSIGHT_API \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Redis Replica 2",
    "host": "host.docker.internal",
    "port": 6381,
    "connectionType": "STANDALONE"
  }' 2>/dev/null

# Sentinel 추가
echo "Sentinel 인스턴스 추가 중..."
curl -X POST $REDISINSIGHT_API \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Redis Sentinel",
    "sentinelHost": "host.docker.internal",
    "sentinelPort": 26379,
    "connectionType": "SENTINEL",
    "sentinelMaster": "mymaster"
  }' 2>/dev/null

# 컨테이너 상태 확인
echo "RedisInsight 컨테이너 상태 확인 중..."
docker ps -f name=redisinsight

echo "Redis 서버 연결 상태 확인 중..."
echo "Redis Master (6379): $(docker exec -it redis-master redis-cli -h redis-master -p 6379 ping 2>/dev/null || echo '연결 실패')"
echo "Redis Replica 1 (6380): $(docker exec -it redis-master redis-cli -h host.docker.internal -p 6380 ping 2>/dev/null || echo '연결 실패')"
echo "Redis Replica 2 (6381): $(docker exec -it redis-master redis-cli -h host.docker.internal -p 6381 ping 2>/dev/null || echo '연결 실패')"
echo "Redis Sentinel (26379): $(docker exec -it redis-master redis-cli -h host.docker.internal -p 26379 ping 2>/dev/null || echo '연결 실패')"

echo ""
echo "====================================================================="
echo "RedisInsight 자동 설정이 완료되었습니다."
echo "웹 브라우저에서 http://localhost:8003 에 접속하여 RedisInsight를 사용할 수 있습니다."
echo ""
echo "다음 Redis 인스턴스가 자동으로 추가되었습니다:"
echo "1. Redis Master - host.docker.internal:6379"
echo "2. Redis Replica 1 - host.docker.internal:6380"
echo "3. Redis Replica 2 - host.docker.internal:6381"
echo "4. Redis Sentinel - host.docker.internal:26379 (Sentinel 유형)"
echo ""
echo "자세한 설정 정보는 README.md 파일을 참조하세요."
echo "====================================================================="