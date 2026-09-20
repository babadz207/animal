const fs = require('fs');
const path = require('path');
const { downloadPetsArray } = require('./download_entire_game_pets.cjs');

console.log('🔍 Bắt đầu tìm kiếm file master workspace ps99_pets_master_all.json trên máy tính...\n');

const searchPaths = [
    'd:\\chit\\mcp\\roblox-executor-mcp-main\\roblox-executor-mcp-main',
    process.env.USERPROFILE,
    path.join(process.env.USERPROFILE, 'Documents'),
    path.join(process.env.USERPROFILE, 'Desktop'),
    path.join(process.env.USERPROFILE, 'Downloads'),
    'C:\\LDPlayer',
    'C:\\Program Files\\BlueStacks_nxt'
];

let foundPath = null;
let foundPets = null;

for (const targetDir of searchPaths) {
    if (!targetDir || !fs.existsSync(targetDir)) continue;
    try {
        const p = path.join(targetDir, 'ps99_pets_master_all.json');
        if (fs.existsSync(p)) {
            foundPath = p;
            foundPets = JSON.parse(fs.readFileSync(p, 'utf8'));
            break;
        }
    } catch (e) {}
}

if (foundPets && foundPets.length > 0) {
    console.log(`✅ TÌM THẤY FILE DỮ LIỆU CHUẨN 100%: ${foundPath}`);
    console.log(`📦 TỔNG SỐ PET TRONG FILE: ${foundPets.length} PETS!\n`);
    downloadPetsArray(foundPets);
} else {
    console.log('📡 Chưa tìm thấy file workspace trực tiếp, đang tiến hành đọc tất cả bước dữ liệu đã thu thập...');
    
    // Combine step files
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
    downloadPetsArray(itemsArray);
}
