const fs = require('fs');
const path = require('path');
const http = require('http');
const { downloadPetsArray } = require('./download_entire_game_pets.cjs');

function getMcpSessionId() {
    return new Promise((resolve) => {
        http.get('http://127.0.0.1:16384/clients', (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const clients = JSON.parse(data);
                    if (clients && clients.length > 0) {
                        resolve(clients[0].id);
                    } else {
                        resolve(null);
                    }
                } catch (e) {
                    resolve(null);
                }
            });
        }).on('error', () => resolve(null));
    });
}

function executeLuaCode(clientId, code) {
    return new Promise((resolve, reject) => {
        const payload = JSON.stringify({
            clientId: clientId,
            code: code
        });

        const req = http.request({
            hostname: '127.0.0.1',
            port: 16384,
            path: '/execute',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(payload)
            }
        }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => resolve(data));
        });

        req.on('error', reject);
        req.write(payload);
        req.end();
    });
}

async function fetchAllPetsDirect() {
    console.log('📡 Đang kết nối trực tiếp với Roblox Client để trích xuất 3,494 Pets...');
    const clientId = await getMcpSessionId();
    if (!clientId) {
        console.error('❌ Chưa tìm thấy Roblox Client kết nối!');
        return;
    }

    console.log(`✅ Kết nối thành công tới Roblox Client: ${clientId}`);
}

fetchAllPetsDirect();
