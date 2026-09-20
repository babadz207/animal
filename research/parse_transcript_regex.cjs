const fs = require('fs');
const path = require('path');
const { downloadPetsArray } = require('./download_entire_game_pets.cjs');

const logPath = 'C:\\Users\\levan\\.gemini\\antigravity-ide\\brain\\9d7edb1f-ad20-45c8-bda1-9a368f26cbda\\.system_generated\\logs\\transcript_full.jsonl';
let txt = fs.readFileSync(logPath, 'utf8');

// Match any pattern containing id="..." and assetId="..."
const itemRegex = /id[^\w\d]+([a-zA-Z0-9_\-\s']+)[^\w\d]+assetId[^\w\d]+(\d+)|assetId[^\w\d]+(\d+)[^\w\d]+id[^\w\d]+([a-zA-Z0-9_\-\s']+)/gi;

const itemsMap = new Map();
let match;
while ((match = itemRegex.exec(txt)) !== null) {
    const id = match[1] || match[4];
    const assetId = match[2] || match[3];
    if (id && assetId && assetId.length >= 3) {
        itemsMap.set(`${id.trim()}_${assetId.trim()}`, { id: id.trim(), assetId: assetId.trim() });
    }
}

const itemsArray = Array.from(itemsMap.values());

console.log('==================================================');
console.log(`📦 LOAD THÀNH CÔNG TỔNG CỘNG ${itemsArray.length} / 3,494 PETS TRONG GAME!`);
console.log('==================================================\n');

downloadPetsArray(itemsArray);
