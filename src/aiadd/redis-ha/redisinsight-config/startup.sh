#!/bin/bash

echo "RedisInsight 컨테이너 설정을 시작합니다..."

# 기존 컨테이너 중지 및 제거
docker stop redisinsight 2>/dev/null
docker rm redisinsight 2>/dev/null

# RedisInsight 컨테이너 시작
echo "RedisInsight 컨테이너를 시작합니다..."
docker run -d --name redisinsight \
  --network redis-ha_redis-net \
  -p 8003:8001 \
  -e REDISINSIGHT_AUTO_UPDATE_CHECK=0 \
  -e REDISINSIGHT_HOST=0.0.0.0 \
  --add-host=redis-master:172.28.0.10 \
  --add-host=redis-replica1:172.28.0.11 \
  --add-host=redis-replica2:172.28.0.12 \
  --add-host=sentinel1:172.28.0.13 \
  --add-host=sentinel2:172.28.0.14 \
  --add-host=sentinel3:172.28.0.15 \
  redislabs/redisinsight:1.14.0

# 컨테이너가 완전히 시작될 때까지 대기
echo "RedisInsight 컨테이너가 완전히 시작될 때까지 잠시 대기합니다..."
sleep 15

echo "RedisInsight 서버가 시작되었습니다."
echo "웹 브라우저에서 http://localhost:8003 에 접속하여 RedisInsight를 사용할 수 있습니다."
echo ""
echo "브라우저에서 접속한 후, 아래 Redis 인스턴스를 수동으로 추가해 주세요:"
echo "1. Redis Master - redis-master:6379 (Standalone 유형)"
echo "2. Redis Replica 1 - redis-replica1:6379 (Standalone 유형)"
echo "3. Redis Replica 2 - redis-replica2:6379 (Standalone 유형)"
echo "4. Redis Sentinel - sentinel1:26379 (Sentinel 유형, Master 그룹명: mymaster)"
echo ""
echo "Docker Compose 네트워크 내부 IP 주소를 사용하면 CORS 문제를 피할 수 있습니다:"
echo "- redis-master: 172.28.0.10"
echo "- redis-replica1: 172.28.0.11"
echo "- redis-replica2: 172.28.0.12"
echo "- sentinel1: 172.28.0.13"
echo ""
echo "RedisInsight에서는 자동 설정 API 접근 시 CSRF 보호가 활성화되어 있어 스크립트를 통한 자동 추가가 어렵습니다."
echo "웹 인터페이스를 통해 직접 추가하는 것이 권장됩니다."
echo ""

# 컨테이너 상태 확인
echo "RedisInsight 컨테이너 상태 확인 중..."
docker ps -f name=redisinsight

echo "Redis 서버 연결 상태 확인 중..."
echo "Redis Master (6379): $(docker exec -it redisinsight redis-cli -h redis-master -p 6379 ping 2>/dev/null || echo '연결 실패')"
echo "Redis Replica 1 (6380): $(docker exec -it redisinsight redis-cli -h redis-replica1 -p 6379 ping 2>/dev/null || echo '연결 실패')"
echo "Redis Replica 2 (6381): $(docker exec -it redisinsight redis-cli -h redis-replica2 -p 6379 ping 2>/dev/null || echo '연결 실패')"
echo "Redis Sentinel (26379): $(docker exec -it redisinsight redis-cli -h sentinel1 -p 26379 ping 2>/dev/null || echo '연결 실패')"

echo ""
echo "====================================================================="
echo "RedisInsight 설정이 완료되었습니다."
echo "자세한 설정 정보는 README.md 파일을 참조하세요."
echo "====================================================================="