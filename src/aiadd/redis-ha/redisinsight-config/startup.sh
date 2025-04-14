#!/bin/bash

# RedisInsight 자동 구성 스크립트
echo "RedisInsight 자동 구성 스크립트 실행 중..."

# 이전 RedisInsight 컨테이너 및 볼륨 정리
docker-compose -f /Users/hspark/Code/hspark/aiadd/src/aiadd/redis-ha/redis-sentinel.yml stop redisinsight
docker-compose -f /Users/hspark/Code/hspark/aiadd/src/aiadd/redis-ha/redis-sentinel.yml rm -f redisinsight
docker volume rm redis-ha_redisinsight-data || true

# RedisInsight 재시작
docker-compose -f /Users/hspark/Code/hspark/aiadd/src/aiadd/redis-ha/redis-sentinel.yml up -d redisinsight

# RedisInsight가 초기화될 때까지 잠시 대기
echo "RedisInsight 초기화 중... (5초 대기)"
sleep 5

# 데이터베이스 구성 파일을 컨테이너 내부에 복사
echo "데이터베이스 구성 파일 복사 중..."
REDISINSIGHT_DB_DIR="/db"
docker exec redisinsight mkdir -p ${REDISINSIGHT_DB_DIR}/.redisinsight
docker cp /Users/hspark/Code/hspark/aiadd/src/aiadd/redis-ha/redisinsight-config/databases.json redisinsight:${REDISINSIGHT_DB_DIR}/.redisinsight/

echo "RedisInsight 설정이 완료되었습니다."
echo "브라우저에서 http://localhost:8003 으로 접속하세요."
echo ""
echo "자동 구성이 실패한 경우, README.md의 '수동 설정 방법'을 참고하세요."
echo "다음 정보를 사용하여 각 Redis 인스턴스를 수동으로 추가할 수 있습니다:"
echo "- Redis Master: host.docker.internal:6379"
echo "- Redis Replica 1: host.docker.internal:6380"
echo "- Redis Replica 2: host.docker.internal:6381"
echo "- Sentinel Cluster: Master Group 'mymaster', Sentinels host.docker.internal:26379, host.docker.internal:26380, host.docker.internal:26381"