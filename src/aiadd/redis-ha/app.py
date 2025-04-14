from flask import Flask, render_template, jsonify
import redis
import json
import time

app = Flask(__name__)

def get_redis_status():
    nodes = [
        {'host': 'redis-master', 'port': 6379, 'name': 'redis-master'},
        {'host': 'redis-replica1', 'port': 6379, 'name': 'redis-replica1'},
        {'host': 'redis-replica2', 'port': 6379, 'name': 'redis-replica2'},
    ]

    sentinel_nodes = [
        {'host': 'sentinel1', 'port': 26379, 'name': 'sentinel1'},
        {'host': 'sentinel2', 'port': 26379, 'name': 'sentinel2'},
        {'host': 'sentinel3', 'port': 26379, 'name': 'sentinel3'},
    ]

    status = {}

    # Redis 노드 상태 확인
    for node in nodes:
        try:
            r = redis.Redis(host=node['host'], port=node['port'], socket_timeout=1, decode_responses=True)
            info = r.info()
            status[node['name']] = {
                'role': info.get('role', ''),
                'connected': True,
                'master_host': info.get('master_host', 'N/A'),
                'connected_slaves': info.get('connected_slaves', 0),
                'master_link_status': info.get('master_link_status', 'N/A')
            }
        except Exception as e:
            status[node['name']] = {
                'role': 'unknown',
                'connected': False,
                'error': str(e)
            }

    # Sentinel 노드 상태 확인
    for node in sentinel_nodes:
        try:
            sentinel = redis.Redis(host=node['host'], port=node['port'], socket_timeout=1, decode_responses=True)
            master_info = sentinel.execute_command('SENTINEL master mymaster')
            master_info_dict = {master_info[i]: master_info[i+1] for i in range(0, len(master_info), 2)}

            status[node['name']] = {
                'role': 'sentinel',
                'connected': True,
                'master_name': 'mymaster',
                'master_host': master_info_dict.get('ip', 'N/A'),
                'master_port': master_info_dict.get('port', 'N/A'),
                'master_status': 'ok' if int(master_info_dict.get('is-odown-sentinel', 0)) == 0 else 'down'
            }
        except Exception as e:
            status[node['name']] = {
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
        sentinel = redis.Redis(host='sentinel1', port=26379, socket_timeout=5)
        result = sentinel.execute_command('SENTINEL failover mymaster')
        return jsonify({'status': 'success', 'message': f'Failover initiated: {result}'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)