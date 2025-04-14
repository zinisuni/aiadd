# RedisInsight 연결 가이드

이 문서는 Redis Sentinel HA 환경에서 RedisInsight를 사용하여 Redis 인스턴스를 모니터링하고 관리하는 방법을 안내합니다.

## 사전 요구사항

- Docker 및 Docker Compose 설치
- Redis Sentinel HA 환경이 구성되어 있어야 함

## 환경 구성 방법

### 1. Docker Compose로 전체 환경 실행

전체 Redis Sentinel 환경과 RedisInsight를 함께 시작하려면 다음 명령어를 실행합니다:

```bash
cd /path/to/redis-ha
docker-compose -f redis-sentinel.yml up -d
```

이 명령은 다음 서비스들을 시작합니다:
- Redis Master (6379)
- Redis Replica 1 (6380)
- Redis Replica 2 (6381)
- Redis Sentinel 1 (26379)
- Redis Sentinel 2 (26380)
- Redis Sentinel 3 (26381)
- Redis Monitor (5001)
- RedisInsight (8003)

### 2. RedisInsight 접속 방법

브라우저에서 다음 URL로 접속합니다:
```
http://localhost:8003
```

### 3. Redis 인스턴스 추가 방법

RedisInsight 웹 인터페이스에서 다음과 같이 Redis 인스턴스를 추가합니다:

#### 3.1 Standalone 인스턴스 추가

1. RedisInsight 대시보드에서 "ADD REDIS DATABASE" 버튼 클릭
2. "Connect to a Redis Database" 선택
3. 다음 정보 입력:
   - **Host:** host.docker.internal (Docker에서 호스트 시스템에 접근하기 위한 특수 도메인)
   - **Port:** 6379 (Redis Master 포트)
   - **Name:** Redis Master
   - **Connection Type:** Standalone

같은 방식으로 Replica 인스턴스도 추가할 수 있습니다:
- Redis Replica 1: host.docker.internal:6380
- Redis Replica 2: host.docker.internal:6381

> **참고:** RedisInsight 컨테이너 내부에서는 `host.docker.internal` 도메인을 사용하여 호스트 시스템의 서비스에 접근할 수 있습니다. Docker Compose 설정에서 이 도메인이 추가되어 있습니다 (`extra_hosts: - "host.docker.internal:host-gateway"`).

#### 3.2 Sentinel 인스턴스 추가

1. RedisInsight 대시보드에서 "ADD REDIS DATABASE" 버튼 클릭
2. "Connect to a Redis Database" 선택
3. **Connection Type**을 "Sentinel"으로 선택
4. 다음 정보 입력:
   - **Sentinel Host:** host.docker.internal
   - **Sentinel Port:** 26379
   - **Master Group Name:** mymaster
   - **Name:** Redis Sentinel

## 문제 해결

### CORS/CSRF 문제

RedisInsight에서 발생하는 CORS/CSRF 관련 문제를 해결하기 위한 방법입니다:

1. **RedisInsight 웹 인터페이스 사용**: API 호출로 자동화하려 하지 말고 RedisInsight 웹 인터페이스를 통해 직접 Redis 인스턴스를 추가합니다.

2. **올바른 호스트 주소 사용**:
   - RedisInsight 컨테이너에서 Redis 서비스에 접근할 때는 `host.docker.internal`을 사용합니다.
   - 이는 Docker 컨테이너 내부에서 호스트 시스템으로 접근하는 특수 도메인입니다.

3. **프록시 우회 설정**: CORS 문제가 계속 발생하는 경우 RedisInsight 컨테이너를 다음과 같이 설정할 수 있습니다:
   ```yaml
   redisinsight:
     # ... 기존 설정 ...
     environment:
       - REDISINSIGHT_CORSALLOWORIGIN=http://localhost:8003
       - REDISINSIGHT_CORSALLOWCREDENTIALS=true
   ```

4. **Docker Compose 네트워크 검증**: Docker 컨테이너 간 연결은 아래 명령어로 검증할 수 있습니다:
   ```bash
   docker exec -it redis-master redis-cli -h redis-master -p 6379 ping
   docker exec -it redis-master redis-cli -h host.docker.internal -p 6379 ping
   ```

### 연결 구성도

```
[브라우저] --- localhost:8003 ---> [RedisInsight 컨테이너] ----host.docker.internal:포트----> [Redis 서비스들]
```

## 주의사항

- RedisInsight 이미지는 linux/amd64 플랫폼용으로 빌드되었으므로, Apple Silicon(M1/M2) 맥에서는 에뮬레이션을 통해 실행됩니다.
- Docker Compose를 통해 관리하면 모든 서비스가 동일한 네트워크 환경에서 실행되어 컨테이너 간 통신은 원활하게 이루어집니다.
- `host.docker.internal`을 사용하면 Docker 컨테이너에서 호스트 시스템의 서비스에 접근할 수 있습니다.
- 네트워크 문제가 발생하면 Docker Compose 설정의 `extra_hosts` 부분을 확인하세요.