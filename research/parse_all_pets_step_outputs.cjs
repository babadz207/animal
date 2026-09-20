const fs = require('fs');
const path = require('path');
const { downloadPetsArray } = require('./download_entire_game_pets.cjs');

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

// Ultra-flexible regex to match id and assetId anywhere in JSON string
const re = /\\?["']?id\\?["']?\s*:\\?\s*["']?([^"'\\]+)\\?["']?\s*,\s*\\?["']?assetId\\?["']?\s*:\\?\s*["']?(\d+)\\?["']?|\\?["']?assetId\\?["']?\s*:\\?\s*["']?(\d+)\\?["']?\s*,\s*\\?["']?id\\?["']?\s*:\\?\s*["']?([^"'\\]+)\\?["']?/gi;

const itemsMap = new Map();
let match;
while ((match = re.exec(allText)) !== null) {
    const id = match[1] || match[4];
    const assetId = match[2] || match[3];
    if (id && assetId && assetId.length >= 3 && !id.includes('{') && !id.includes('}')) {
        itemsMap.set(`${id.trim()}_${assetId.trim()}`, { id: id.trim(), assetId: assetId.trim() });
    }
}

const itemsArray = Array.from(itemsMap.values());
console.log(`==================================================`);
console.log(`📦 TRÍCH XUẤT THÀNH CÔNG TỔNG CỘNG ${itemsArray.length} PETS KHÁC NHAU IN GAME!`);
console.log(`==================================================\n`);

downloadPetsArray(itemsArray);
