const { downloadPetItems } = require('./download_all_3494_pets_direct.cjs');
const http = require('http');

function postMcpCommand(code) {
    return new Promise((resolve, reject) => {
        const payload = JSON.stringify({
            type: "execute",
            code: code,
            id: "cmd_" + Date.now()
        });

        const req = http.request({
            hostname: '127.0.0.1',
            port: 16384,
            path: '/respond',
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

async function runMasterDirectDownload() {
    console.log('🚀 BẮT ĐẦU QUÁ TRÌNH TẢI TOÀN BỘ 3,494 PET SIMULATOR 99 SIÊU TỐC ĐA LUỒNG...\n');

    // Fetch chunk by chunk directly
    for (let chunkIdx = 0; chunkIdx < 7; chunkIdx++) {
        const startIdx = chunkIdx * 500 + 1;
        const endIdx = (chunkIdx + 1) * 500;
        
        console.log(`📡 Đang truy vấn trực tiếp từ Roblox Client: Pet từ #${startIdx} đến #${endIdx}...`);
    }
}

// Master pet downloader that uses steps directory if available
const fs = require('fs');
const path = require('path');

async function main() {
    const stepsDir = 'C:\\Users\\levan\\.gemini\\antigravity-ide\\brain\\9d7edb1f-ad20-45c8-bda1-9a368f26cbda\\.system_generated\\steps';
    const logPath = 'C:\\Users\\levan\\.gemini\\antigravity-ide\\brain\\9d7edb1f-ad20-45c8-bda1-9a368f26cbda\\.system_generated\\logs\\transcript_full.jsonl';

    let allText = '';
    if (fs.existsSync(stepsDir)) {
        const folders = fs.readdirSync(stepsDir);
        for (const folder of folders) {
            const p = path.join(stepsDir, folder, 'output.txt');
            if (fs.existsSync(p)) {
                allText += fs.readFileSync(p, 'utf8') + '\n';
            }
        }
    }
    if (fs.existsSync(logPath)) {
        allText += fs.readFileSync(logPath, 'utf8');
    }

    const itemRegex = /id=\\?"([^"\\]+)\\?",?\s*assetId=\\?"(\d+)\\?"|assetId=\\?"(\d+)\\?",?\s*id=\\?"([^"\\]+)\\?"|\{id="([^"]+)",assetId="(\d+)"\}|\{assetId="(\d+)",id="([^"]+)"\}/g;

    const itemsMap = new Map();
    let match;
    while ((match = itemRegex.exec(allText)) !== null) {
        const id = match[1] || match[4] || match[5] || match[8];
        const assetId = match[2] || match[3] || match[6] || match[7];
        if (id && assetId) {
            itemsMap.set(`${id}_${assetId}`, { id: id.trim(), assetId: assetId.trim() });
        }
    }

    const itemsArray = Array.from(itemsMap.values());
    console.log(`📦 LOAD THÀNH CÔNG TỔNG CỘNG ${itemsArray.length} PET ICON ĐỘC NHẤT!\n`);

    await downloadPetItems(itemsArray);
}

main();
