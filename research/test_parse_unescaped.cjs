const fs = require('fs');
const path = require('path');
const { downloadPetsArray } = require('./download_entire_game_pets.cjs');

const logPath = 'C:\\Users\\levan\\.gemini\\antigravity-ide\\brain\\9d7edb1f-ad20-45c8-bda1-9a368f26cbda\\.system_generated\\logs\\transcript_full.jsonl';
let txt = fs.readFileSync(logPath, 'utf8');

// Unescape escaped slashes and quotes completely
txt = txt.replace(/\\"/g, '"').replace(/\\\\/g, '\\');

const itemRegex = /"id"\s*:\s*"([^"]+)"\s*,\s*"assetId"\s*:\s*"(\d+)"/g;

const itemsMap = new Map();
let match;
while ((match = itemRegex.exec(txt)) !== null) {
    const id = match[1].trim();
    const assetId = match[2].trim();
    if (id && assetId && assetId.length >= 3 && !id.includes('{') && !id.includes('}')) {
        itemsMap.set(`${id}_${assetId}`, { id, assetId });
    }
}

const itemsArray = Array.from(itemsMap.values());

console.log('==================================================');
console.log(`📦 LOAD THÀNH CÔNG TỔNG CỘNG ${itemsArray.length} / 3,494 PETS TRONG GAME!`);
console.log('==================================================\n');

downloadPetsArray(itemsArray);
