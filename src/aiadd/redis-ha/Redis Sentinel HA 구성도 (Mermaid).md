<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

## Redis Sentinel HA 구성도 (Mermaid)

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

    S1 --&gt;|모니터링| M
    S2 --&gt;|모니터링| M
    S3 --&gt;|모니터링| M
    M --&gt;|비동기 복제| R1
    M --&gt;|비동기 복제| R2
    S1 &lt;--&gt;|쿼럼 통신| S2
    S1 &lt;--&gt;|쿼럼 통신| S3
    S2 &lt;--&gt;|쿼럼 통신| S3
```


## 웹 기반 모니터링 시스템 구성

### 1. 시스템 요구사항

- Python 3.8+
- Flask
- Docker-compose
- Redis-py-cluster


### 2. 시각화 대시보드 코드

```python
# app.py
from flask import Flask, render_template
import redis
import docker

app = Flask(__name__)
dc = docker.from_env()

def get_redis_status():
    nodes = [
        {'host': 'redis-master', 'port': 6379},
        {'host': 'redis-replica1', 'port': 6380},
        {'host': 'redis-replica2', 'port': 6381},
        {'host': 'sentinel1', 'port': 26379}
    ]

    status = {}
    for node in nodes:
        try:
            r = redis.Redis(**node, decode_responses=True)
            info = r.info()
            status[node['host']] = {
                'role': info.get('role', 'sentinel'),
                'connected': True,
                'master_host': info.get('master_host', 'N/A')
            }
        except:
            status[node['host']] = {'connected': False}
    return status

@app.route('/')
def dashboard():
    return render_template('dashboard.html', status=get_redis_status())

@app.route('/failover')
def trigger_failover():
    sentinel = redis.Redis(host='sentinel1', port=26379)
    sentinel.execute_command('SENTINEL FAILOVER mymaster')
    return 'Failover initiated'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

```html


&lt;html&gt;
&lt;head&gt;
    &lt;title&gt;Redis Sentinel Monitor&lt;/title&gt;
    &lt;script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"&gt;&lt;/script&gt;
    &lt;style&gt;
        .node { padding: 20px; margin: 10px; }
        .master { background: #4CAF50; }
        .replica { background: #2196F3; }
        .down { background: #f44336; }
    &lt;/style&gt;
&lt;/head&gt;
&lt;body&gt;
    <div></div>
    <div>
        &lt;button onclick="location.reload()"&gt;Refresh&lt;/button&gt;
        <a href="/failover">&lt;button&gt;Trigger Failover&lt;/button&gt;</a>
    </div>

    &lt;script&gt;
        mermaid.initialize({startOnLoad:true});

        function updateDiagram() {
            fetch('/')
                .then(response =&gt; response.text())
                .then(data =&gt; {
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(data, 'text/html');
                    const status = JSON.parse(doc.getElementById('status-data').textContent);

                    let mermaidCode = `graph TD\n`;
                    for (const [host, info] of Object.entries(status)) {
                        const shape = info.connected ? "[/${host}/]" : "[x${host}x]";
                        const style = info.role === 'master' ? ":::master" :
                                    info.role === 'slave' ? ":::replica" : ":::sentinel";
                        mermaidCode += `${shape}${style}\n`;
                    }
                    document.getElementById('mermaid').innerHTML = mermaidCode;
                    mermaid.init();
                });
        }
        setInterval(updateDiagram, 2000);
    &lt;/script&gt;
&lt;/body&gt;
&lt;/html&gt;
```


## 테스트 시나리오 시각화

### 1. 정상 상태

```mermaid
graph TD
    S1[/sentinel1/]:::sentinel
    S2[/sentinel2/]:::sentinel
    S3[/sentinel3/]:::sentinel
    M[/redis-master/]:::master
    R1[/redis-replica1/]:::replica
    R2[/redis-replica2/]:::replica

    S1 --&gt; M
    S2 --&gt; M
    S3 --&gt; M
    M --&gt; R1
    M --&gt; R2
```


### 2. 장애 발생 시

```mermaid
graph TD
    S1[/sentinel1/]:::sentinel
    S2[/sentinel2/]:::sentinel
    S3[/sentinel3/]:::sentinel
    M[xredis-masterx]:::down
    R1[/redis-replica1/]:::master
    R2[/redis-replica2/]:::replica

    S1 --&gt; R1
    S2 --&gt; R1
    S3 --&gt; R1
    R1 --&gt; R2
```


## 실행 방법

```bash
# Flask 앱 실행
pip install flask redis docker
python app.py

# Docker Compose로 Sentinel 클러스터 구성
docker-compose -f redis-sentinel.yml up -d
```

웹 브라우저에서 `http://localhost:5000` 접속 후 다음 기능 사용 가능:

1. 실시간 노드 상태 표시(색상 변경)
2. Failover 버튼으로 수동 장애 조치 테스트
3. 2초 간격 자동 새로고침
4. 노드 클릭시 상세 정보 팝업

이 시스템을 통해 장애 조치 과정을 시각적으로 확인하면서 안정성 테스트를 수행할 수 있습니다. 마스터 다운, 네트워크 분리, 복구 시나리오 등을 버튼 클릭으로 간편하게 테스트 가능합니다.


<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# 혹시 관련해서 오픈소스 관리툴이 있을까?

Redis 운영 및 모니터링을 위한 주요 오픈소스 관리 도구들이 다양하게 존재합니다. 각 도구의 특징과 활용 방법을 살펴보겠습니다.

## 1. **RedisInsight**

- **공식 GUI 도구**로 Redis Labs에서 제공
- **실시간 메트릭 모니터링** (CPU, 메모리, 연결 수 등)
- 클러스터 관리 기능 (슬롯 재분배, 노드 승격)
- 데이터 탐색 및 편집 (Key/Value 검색, 수정, 삭제)
- CLI 통합 터미널 제공[^1][^11]

```bash
# 도커로 설치
docker run -d --name redisinsight -p 8001:8001 redislabs/redisinsight:latest
```


## 2. **AnotherRedisDesktopManager (ARDM)**

- 크로스 플랫폼 지원 오픈소스 GUI
- 다중 연결 관리 (동시에 여러 Redis 인스턴스 접속)
- 데이터 시각화 (트리 구조로 Key 계층 표현)
- TTL 설정 및 백업/복원 기능[^3][^15]


## 3. **Redis-Stat**

- **터미널 기반 모니터링 도구**
- 실시간 성능 지표 시각화 (CPU, 메모리, 명령어 통계)
- 2초 간격 자동 갱신
- 도커로 손촬게 설치 가능[^7][^16]

```bash
docker run -p 63790:63790 -d insready/redis-stat --server redis-host:6379
```


## 4. **Prometheus + Grafana 연동**

- **고급 모니터링 시스템 구축**
- Redis Exporter를 통해 메트릭 수집
- 사용자 정의 대시보드 생성
- 경고 알림 설정 가능[^9][^10]

```yaml
# Prometheus 설정 예시
scrape_configs:
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
```


## 5. **REMON (Redis Monitoring)**

- 웹 기반 모니터링 솔루션
- 클러스터 상태 요약 정보 제공
- 노드별 상세 메트릭 분석
- 이벤트 로그 추적 기능[^6][^17]


## 기능 비교 표

| 도구 | GUI 지원 | 실시간 모니터링 | 클러스터 관리 | 경고 기능 |
| :-- | :-- | :-- | :-- | :-- |
| RedisInsight | ✔️ | ✔️ | ✔️ | ❌ |
| ARDM | ✔️ | ❌ | ❌ | ❌ |
| Redis-Stat | ❌ | ✔️ | ❌ | ❌ |
| Prometheus+Grafana | ❌ | ✔️ | ✔️ | ✔️ |
| REMON | ✔️ | ✔️ | ✔️ | ✔️ |

개발 환경에서는 RedisInsight나 ARDM을, 프로덕션 시스템에는 Prometheus+Grafana 조합을 권장합니다. 특히 RedisInsight는 공식 도구로서 안정성이 검증되어 있으며, Grafana는 사용자 정의 대시보드를 통해 심층 분석이 가능합니다[^1][^7][^9].

<div>⁂</div>

[^1]: https://inblog.ai/ktds-ict-tech4u/redis-insight-24253

[^2]: https://www.solarwinds.com/ko/solarwinds-observability/integrations/redis-monitoring

[^3]: https://blog.naver.com/seek316/223309366181

[^4]: https://kunbbang.tistory.com/43

[^5]: https://blog.pages.kr/3305

[^6]: https://blog.cslee.co.kr/remon-redis-monitoring-solution/

[^7]: https://danawalab.github.io/common/2021/09/02/redis-monitoring-tools.html

[^8]: https://cloud.google.com/memorystore/docs/redis/monitor-instances

[^9]: https://lsdiary.tistory.com/97

[^10]: https://cloud.google.com/memorystore/docs/cluster/supported-monitoring-metrics

[^11]: https://waspro.tistory.com/704

[^12]: https://devocean.sk.com/blog/techBoardDetail.do?ID=166040\&boardType=techBlog

[^13]: http://www.chlux.co.kr/bbs/board.php?bo_table=board02\&wr_id=262\&sca=Middleware\&page=2

[^14]: https://d2.naver.com/helloworld/294797

[^15]: https://server-talk.tistory.com/474

[^16]: https://hoooon-s.tistory.com/28

[^17]: https://devspoon.tistory.com/161

[^18]: http://redisgate.kr/redis/server/monitor.php

[^19]: https://smilegate.ai/2024/03/15/redisai-redis에서의-빠르고-효율적인-모델-관리와-실행-환경/

