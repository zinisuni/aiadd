#!/bin/bash

# Redis Sentinel HA Failover 테스트 스크립트
echo "Redis Sentinel HA Failover 테스트를 시작합니다..."

# 현재 마스터 확인
echo "현재 마스터 노드 확인 중..."
CURRENT_MASTER=$(docker exec -it sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster | head -n 1)
echo "현재 마스터: $CURRENT_MASTER"

# 마스터 노드 다운 시뮬레이션
echo "마스터 노드 다운 시뮬레이션 시작..."
docker stop redis-master
echo "마스터 노드가 중지되었습니다. Sentinel이 Failover를 감지할 때까지 대기 중..."
sleep 10

# 새로운 마스터 확인
echo "새로운 마스터 노드 확인 중..."
NEW_MASTER=$(docker exec -it sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster | head -n 1)
echo "새로운 마스터: $NEW_MASTER"

if [ "$CURRENT_MASTER" != "$NEW_MASTER" ]; then
  echo "성공: Failover가 정상적으로 수행되었습니다."
  echo "이전 마스터: $CURRENT_MASTER -> 새 마스터: $NEW_MASTER"
else
  echo "실패: Failover가 정상적으로 수행되지 않았습니다."
fi

# 이전 마스터 복구
echo "이전 마스터 노드 복구 중..."
docker start redis-master
echo "이전 마스터 노드가 복구되었습니다. 상태 확인 중..."
sleep 5

# 복구된 노드의 역할 확인
ROLE=$(docker exec -it redis-master redis-cli INFO replication | grep role | cut -d: -f2 | tr -d '\r')
echo "복구된 이전 마스터 노드의 현재 역할: $ROLE"

echo "테스트가 완료되었습니다. 웹 대시보드와 RedisInsight에서 상태를 확인해 보세요."
echo "  - 커스텀 대시보드: http://localhost:5001"
echo "  - RedisInsight: http://localhost:8002"