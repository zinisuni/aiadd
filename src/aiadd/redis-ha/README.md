# Redis Sentinel HA 구성

이 프로젝트는 Redis Sentinel을 사용한 고가용성(HA) 구성을 Docker Compose로 구현하고, 웹 기반 모니터링 시스템을 제공합니다.

## 시스템 구성

- Redis 마스터 노드 1개
- Redis 복제본(replica) 노드 2개
- Redis Sentinel 노드 3개
- 웹 기반 모니터링 대시보드
- RedisInsight 모니터링 도구

## 시스템 구성도

```mermaid
graph TD
    subgraph Sentinel Cluster
        S1(Sentinel 1)
        S2(Sentinel 2)
        S3(Sentinel 3)
    end

    subgraph Redis Nodes
        M[Master]
        R1[Replica 1]
        R2[Replica 2]
    end

    subgraph Monitoring
        D[Dashboard]
        RI[RedisInsight]
    end

    S1 -->|모니터링| M
    S2 -->|모니터링| M
    S3 -->|모니터링| M
    M -->|비동기 복제| R1
    M -->|비동기 복제| R2
    S1 <-->|쿼럼 통신| S2
    S1 <-->|쿼럼 통신| S3
    S2 <-->|쿼럼 통신| S3
    D -->|상태 확인| M
    D -->|상태 확인| R1
    D -->|상태 확인| R2
    D -->|상태 확인| S1
    D -->|상태 확인| S2
    D -->|상태 확인| S3
    RI -->|관리/모니터링| M
    RI -->|관리/모니터링| R1
    RI -->|관리/모니터링| R2
```

## 시스템 요구사항

- Docker 및 Docker Compose
- 웹 브라우저

## 설치 및 실행 방법

1. 저장소 클론

```bash
git clone <repository-url>
cd redis-ha
```

2. Docker Compose로 시스템 시작

```bash
docker-compose -f redis-sentinel.yml up -d
```

3. 모니터링 서비스 접속

- 커스텀 모니터링 대시보드: `http://localhost:5001`
- RedisInsight: `http://localhost:8003`

## 기능

### 모니터링 대시보드

- Redis 노드 및 Sentinel 상태 실시간 모니터링
- 마스터-복제본 관계 시각화 (Mermaid 다이어그램)
- 노드별 상세 정보 표시
- 자동 상태 갱신 (5초 간격)

### RedisInsight 활용하기

RedisInsight는 Redis Labs에서 제공하는 공식 GUI 도구로, Redis 인스턴스의 모니터링과 관리를 위한 강력한 기능을 제공합니다.

#### RedisInsight 초기 설정

1. 웹 브라우저에서 `http://localhost:8003` 접속
2. RedisInsight 초기 설정 페이지에서 "I already have a Redis database" 선택
3. 데이터베이스 추가:
   - **마스터 노드**:
     - Host: 172.28.0.10
     - Port: 6379
     - Name: Redis Master
   - **복제본 노드 1**:
     - Host: 172.28.0.11
     - Port: 6379
     - Name: Redis Replica 1
   - **복제본 노드 2**:
     - Host: 172.28.0.12
     - Port: 6379
     - Name: Redis Replica 2
   - **Sentinel 노드**:
     - Host: 172.28.0.13
     - Port: 26379
     - Name: Redis Sentinel
     - Type: Sentinel (고급 설정에서 선택)
     - Master Group: mymaster

#### RedisInsight 활용

- **Browser**: Redis 데이터 탐색 및 편집
- **Slowlog**: 느린 쿼리 분석
- **CLI**: Redis 명령 실행
- **Info**: 실시간 서버 성능 메트릭
- **Analytics**: 성능 분석
- **Profiler**: 명령어 프로파일링

### Failover 테스트

대시보드 상단에 있는 "Failover 테스트" 버튼을 클릭하여 수동으로 장애 조치를 시작할 수 있습니다. 이 기능은 Sentinel이 마스터 노드를 변경하도록 유도합니다.

## 장애 시나리오 테스트 방법

### 1. 마스터 노드 다운 시나리오

```bash
# 마스터 노드 중지
docker stop redis-master
```

Sentinel은 마스터 노드 다운을 감지하고 복제본 중 하나를 새로운 마스터로 승격시킵니다.

### 2. 네트워크 분리 시나리오

```bash
# 마스터 노드 네트워크 분리
docker network disconnect redis-ha_redis-net redis-master
```

### 3. 마스터 복구 시나리오

```bash
# 마스터 노드 재시작
docker start redis-master
```

이전 마스터 노드는 복제본으로 재구성됩니다.

## 모니터링 및 관리 명령어

### Redis CLI 접속

```bash
# 마스터 노드 접속
docker exec -it redis-master redis-cli

# 복제본 노드 접속
docker exec -it redis-replica1 redis-cli
docker exec -it redis-replica2 redis-cli
```

### Sentinel 정보 확인

```bash
# Sentinel 노드 접속
docker exec -it sentinel1 redis-cli -p 26379

# 마스터 정보 확인
sentinel master mymaster

# 복제본 목록 확인
sentinel replicas mymaster

# Sentinel 목록 확인
sentinel sentinels mymaster
```

## RedisInsight vs 커스텀 모니터링 대시보드 비교

| 기능 | RedisInsight | 커스텀 대시보드 |
|-----|-------------|----------------|
| 실시간 모니터링 | ✅ | ✅ |
| 데이터 탐색/편집 | ✅ | ❌ |
| Mermaid 시각화 | ❌ | ✅ |
| 성능 분석 | ✅ | ❌ |
| Redis 명령 실행 | ✅ | ❌ |
| Sentinel 관리 | ✅ | ✅ |
| Failover 테스트 | ✅ | ✅ |
| 사용자 정의 UI | ❌ | ✅ |

## 주요 구성 파일

- `redis-sentinel.yml`: Docker Compose 구성 파일
- `redis-master.conf`: 마스터 노드 설정
- `redis-replica1.conf`, `redis-replica2.conf`: 복제본 노드 설정
- `sentinel1.conf`, `sentinel2.conf`, `sentinel3.conf`: Sentinel 설정
- `app.py`: 모니터링 애플리케이션

## 시스템 종료

```bash
docker-compose -f redis-sentinel.yml down
```