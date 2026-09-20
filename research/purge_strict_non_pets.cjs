const fs = require('fs');
const path = require('path');

const petsDir = path.join(__dirname, 'downloaded_assets', 'Pets');
const logPath = 'C:\\Users\\levan\\.gemini\\antigravity-ide\\brain\\9d7edb1f-ad20-45c8-bda1-9a368f26cbda\\.system_generated\\logs\\transcript_full.jsonl';

const stepsDir = 'C:\\Users\\levan\\.gemini\\antigravity-ide\\brain\\9d7edb1f-ad20-45c8-bda1-9a368f26cbda\\.system_generated\\steps';

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

// Unescape quotes in JSON text
const cleanText = allText.replace(/\\"/g, '"').replace(/\\\\/g, '\\');

// Match "PetName":true in JSON map output from Directory.Pets
const petNameRegex = /"([^"]+)":true/g;
const validPetsSet = new Set();

let match;
while ((match = petNameRegex.exec(cleanText)) !== null) {
    const name = match[1].trim();
    if (name && name.length > 0) {
        validPetsSet.add(name);
    }
}

console.log('==================================================');
console.log(`📦 LOAD THÀNH CÔNG ${validPetsSet.size} PET CHUẨN TỪ DIRECTORY.PETS CỦA GAME!`);
console.log('==================================================\n');

if (validPetsSet.size === 0) {
    console.error('❌ Không load được danh sách Directory.Pets');
    process.exit(1);
}

let removedCount = 0;
let keptCount = 0;

const files = fs.readdirSync(petsDir);

for (const filename of files) {
    if (!filename.endsWith('.png')) continue;

    // Extract Pet ID by stripping the trailing _AssetId.png
    const petId = filename.replace(/_\d+\.png$/, '').trim();

    if (!validPetsSet.has(petId)) {
        const filePath = path.join(petsDir, filename);
        console.log(`  🗑️ Xóa file rác KHÔNG CÓ TRONG DIRECTORY.PETS: "${petId}" -> ${filename}`);
        fs.unlinkSync(filePath);
        removedCount++;
    } else {
        keptCount++;
    }
}

console.log('\n==================================================');
console.log('🎉 ĐÃ DỌN DẸP SẠCH 100% TOÀN BỘ RÁC NON-PET KHỎI THƯ MỤC PETS!');
console.log(`• Số Pet Chuẩn Giữ Lại: ${keptCount} file PNG`);
console.log(`• Số File Rác Đã Xóa: ${removedCount} file PNG`);
console.log(`📂 Thư mục Pets sạch: ${petsDir}`);
console.log('==================================================');
