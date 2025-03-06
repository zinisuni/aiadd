const express = require('express');
const Redis = require('redis');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Redis 클라이언트 설정
const redisClient = Redis.createClient({
    url: process.env.REDIS_URL || 'redis://redis:6379'
});

redisClient.connect().catch(console.error);

// 최대 동시 접속자 수
const MAX_CONCURRENT_USERS = process.env.MAX_CONCURRENT_USERS || 100;
// 예상 체류 시간 (초)
const ESTIMATED_SESSION_TIME = process.env.ESTIMATED_SESSION_TIME || 300;

async function getCurrentUsers() {
    const count = await redisClient.get('current_users') || '0';
    return parseInt(count);
}

async function getQueuePosition(userId) {
    const position = await redisClient.zScore('queue', userId);
    return position !== null ? position + 1 : null;
}

async function getQueueLength() {
    return await redisClient.zCard('queue');
}

// 대기열 상태 확인 API
app.get('/api/queue/status', async (req, res) => {
    try {
        const userId = req.ip; // 실제 구현시 세션 ID나 다른 식별자 사용 권장
        const currentUsers = await getCurrentUsers();
        const queuePosition = await getQueuePosition(userId);
        const queueLength = await getQueueLength();

        if (currentUsers < MAX_CONCURRENT_USERS) {
            // 바로 입장 가능
            await redisClient.zRem('queue', userId);
            return res.json({
                canProceed: true,
                redirectUrl: '/',
                queueCount: 0,
                estimatedWaitTime: 0,
                progress: 100
            });
        }

        if (!queuePosition) {
            // 대기열에 추가
            await redisClient.zAdd('queue', { score: Date.now(), value: userId });
        }

        const estimatedWaitTime = Math.ceil((queuePosition * ESTIMATED_SESSION_TIME) / MAX_CONCURRENT_USERS);
        const progress = Math.max(0, Math.min(100, (1 - queuePosition / queueLength) * 100));

        res.json({
            canProceed: false,
            queueCount: queueLength,
            estimatedWaitTime,
            progress
        });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.listen(port, () => {
    console.log(`Queue API server listening at http://localhost:${port}`);
});