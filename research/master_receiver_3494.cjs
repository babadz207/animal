const http = require('http');
const fs = require('fs');
const path = require('path');
const { downloadPetsArray } = require('./download_entire_game_pets.cjs');

let allPetsCollection = new Map();

const server = http.createServer((req, res) => {
    if (req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const petsChunk = JSON.parse(body);
                for (const item of petsChunk) {
                    if (item.id && item.assetId) {
                        allPetsCollection.set(`${item.id}_${item.assetId}`, item);
                    }
                }
                console.log(`📥 Nhận đợt dữ liệu Pet mới: +${petsChunk.length} Pets (Tổng cộng hiện tại: ${allPetsCollection.size} / 3,494 Pets)`);
                
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: 'ok', currentTotal: allPetsCollection.size }));

                if (req.headers['x-is-final'] === 'true' || allPetsCollection.size >= 3400) {
                    const finalArray = Array.from(allPetsCollection.values());
                    console.log(`\n🎉 ĐÃ NHẬN ĐỦ 100% TOÀN BỘ ${finalArray.length} PETS TỪ GAME! BẮT ĐẦU TẢI 30 LUỒNG SONG SONG...\n`);
                    downloadPetsArray(finalArray);
                }
            } catch (err) {
                console.error('Lỗi JSON:', err.message);
                res.writeHead(400);
                res.end('Invalid JSON');
            }
        });
    } else {
        res.writeHead(200);
        res.end('Master 3,494 Pets Receiver Server Running');
    }
});

server.listen(28888, '0.0.0.0', () => {
    console.log('🌐 Server Nhận 100% Dữ Liệu 3,494 Pets sẵn sàng tại cổng 28888!');
});
