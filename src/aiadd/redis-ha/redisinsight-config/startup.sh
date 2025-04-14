#!/bin/bash

# RedisInsight 자동 구성 스크립트
echo "RedisInsight 자동 구성 스크립트 실행 중..."

# 이전 RedisInsight 컨테이너 및 볼륨 정리
docker-compose -f /Users/hspark/Code/hspark/aiadd/src/aiadd/redis-ha/redis-sentinel.yml stop redisinsight
docker-compose -f /Users/hspark/Code/hspark/aiadd/src/aiadd/redis-ha/redis-sentinel.yml rm -f redisinsight
docker volume rm redis-ha_redisinsight-data || true

# RedisInsight 재시작
echo "RedisInsight 컨테이너 시작 중..."
docker-compose -f /Users/hspark/Code/hspark/aiadd/src/aiadd/redis-ha/redis-sentinel.yml up -d redisinsight

# RedisInsight가 초기화될 때까지 잠시 대기
echo "RedisInsight 초기화 중... (10초 대기)"
sleep 10

# API를 통한 데이터베이스 등록
echo "API를 통해 Redis 데이터베이스 등록 시작..."
./redisinsight-config/add_databases.sh

echo "RedisInsight 설정이 완료되었습니다."
echo "브라우저에서 http://localhost:8003 으로 접속하세요."
echo ""
echo "RedisInsight에 다음 데이터베이스가 자동으로 등록되었습니다:"
echo "- Redis Master: host.docker.internal:6379"
echo "- Redis Replica 1: host.docker.internal:6380"
echo "- Redis Replica 2: host.docker.internal:6381"
echo "- Sentinel Cluster: Master Group 'mymaster', Sentinels host.docker.internal:26379, host.docker.internal:26380, host.docker.internal:26381"
echo ""
echo "자동 구성이 실패한 경우, README.md의 '수동 설정 방법'을 참고하세요."