from flask import Flask, render_template, jsonify
import redis
import json
import time

app = Flask(__name__)

REDIS_NODES = {
    'redis-master': {'host': '172.28.0.10', 'port': 6379, 'name': 'redis-master'},
    'redis-replica1': {'host': '172.28.0.11', 'port': 6379, 'name': 'redis-replica1'},
    'redis-replica2': {'host': '172.28.0.12', 'port': 6379, 'name': 'redis-replica2'},
}

SENTINEL_NODES = {
    'sentinel1': {'host': '172.28.0.13', 'port': 26379, 'name': 'sentinel1'},
    'sentinel2': {'host': '172.28.0.14', 'port': 26379, 'name': 'sentinel2'},
    'sentinel3': {'host': '172.28.0.15', 'port': 26379, 'name': 'sentinel3'},
}

def get_redis_status():
    status = {}

    # Redis 노드 상태 확인
    for node_name, node in REDIS_NODES.items():
        try:
            r = redis.Redis(host=node['host'], port=node['port'], socket_timeout=1, decode_responses=True)
            info = r.info()
            status[node_name] = {
                'role': info.get('role', ''),
                'connected': True,
                'master_host': info.get('master_host', 'N/A'),
                'connected_slaves': info.get('connected_slaves', 0),
                'master_link_status': info.get('master_link_status', 'N/A')
            }
        except Exception as e:
            status[node_name] = {
                'role': 'unknown',
                'connected': False,
                'error': str(e)
            }

    # Sentinel 노드 상태 확인
    for node_name, node in SENTINEL_NODES.items():
        try:
            sentinel = redis.Redis(host=node['host'], port=node['port'], socket_timeout=1, decode_responses=True)
            master_info = sentinel.execute_command('SENTINEL master mymaster')
            master_info_dict = {master_info[i]: master_info[i+1] for i in range(0, len(master_info), 2)}

            status[node_name] = {
                'role': 'sentinel',
                'connected': True,
                'master_name': 'mymaster',
                'master_host': master_info_dict.get('ip', 'N/A'),
                'master_port': master_info_dict.get('port', 'N/A'),
                'master_status': 'ok' if int(master_info_dict.get('is-odown-sentinel', 0)) == 0 else 'down'
            }
        except Exception as e:
            status[node_name] = {
                'role': 'sentinel',
                'connected': False,
                'error': str(e)
            }

    return status

@app.route('/')
def dashboard():
    status = get_redis_status()
    return render_template('dashboard.html', status=status, status_json=json.dumps(status))

@app.route('/api/status')
def api_status():
    return jsonify(get_redis_status())

@app.route('/failover')
def trigger_failover():
    try:
        sentinel = redis.Redis(host=SENTINEL_NODES['sentinel1']['host'], port=SENTINEL_NODES['sentinel1']['port'], socket_timeout=5)
        result = sentinel.execute_command('SENTINEL failover mymaster')
        return jsonify({'status': 'success', 'message': f'Failover initiated: {result}'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)