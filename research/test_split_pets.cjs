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

const itemsMap = new Map();

// Look for id and assetId strings
const parts = allText.split(/id["\\]*:/gi);
for (const part of parts) {
    const nameMatch = part.match(/^["\\'\s]*([^"'\\]+)["\\'\s]*/);
    const assetMatch = part.match(/assetId["\\]*:["\\'\s]*(\d+)/i);
    if (nameMatch && assetMatch) {
        const id = nameMatch[1].trim();
        const assetId = assetMatch[1].trim();
        if (id && assetId && assetId.length >= 3 && !id.includes('{') && !id.includes('}')) {
            itemsMap.set(`${id}_${assetId}`, { id, assetId });
        }
    }
}

const itemsArray = Array.from(itemsMap.values());
console.log(`==================================================`);
console.log(`📦 TRÍCH XUẤT THÀNH CÔNG TỔNG CỘNG ${itemsArray.length} PETS TRONG GAME!`);
console.log(`==================================================\n`);

downloadPetsArray(itemsArray);
