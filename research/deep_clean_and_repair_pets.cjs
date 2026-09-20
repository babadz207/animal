const fs = require('fs');
const path = require('path');
const https = require('https');

const petsDir = path.join(__dirname, 'downloaded_assets', 'Pets');

if (!fs.existsSync(petsDir)) {
    console.error(`❌ Thư mục không tồn tại: ${petsDir}`);
    process.exit(1);
}

console.log('🔍 BẮT ĐẦU QUÉT SÂU & LỌC TOÀN BỘ FILE HỎNG (958 BYTES) VÀ FILE VẬT PHẨM NON-PET...\n');

const files = fs.readdirSync(petsDir);

const nonPetKeywords = [
    'Card', 'Boost', 'Flag', 'Potion', 'Enchant', 'Fruit', 'Key', 'Token',
    'Container', 'Sprinkler', 'Shovel', 'Axe', 'Ticket', 'Jar', 'Orb', 'Dice',
    'Pinata Basher', 'Cocktail', 'Ornament', 'Cape', 'Swirl', 'Dust', 'Ball'
];

let corruptedDeleted = 0;
let nonPetDeleted = 0;
let validKept = 0;

const reDownloadTargets = [];

for (const filename of files) {
    if (!filename.endsWith('.png')) continue;
    const filePath = path.join(petsDir, filename);
    const stat = fs.statSync(filePath);

    // 1. Check corrupted/blank HTML response files (size <= 2000 bytes)
    if (stat.size <= 2000) {
        console.log(`  🗑️ Xóa file lỗi/trắng (${stat.size} bytes): ${filename}`);
        fs.unlinkSync(filePath);
        corruptedDeleted++;

        // Extract asset ID to retry
        const match = filename.match(/_(\d+)\.png$/);
        if (match) {
            const petName = filename.replace(/_\d+\.png$/, '');
            reDownloadTargets.push({ filename, petName, assetId: match[1], destPath: filePath });
        }
        continue;
    }

    // 2. Check non-pet items by keywords
    const isNonPet = nonPetKeywords.some(kw => {
        const regex = new RegExp(`\\b${kw}\\b`, 'i');
        return regex.test(filename);
    });

    if (isNonPet) {
        console.log(`  🗑️ Xóa file rác non-Pet (${filename.split('_')[0]}): ${filename}`);
        fs.unlinkSync(filePath);
        nonPetDeleted++;
        continue;
    }

    validKept++;
}

console.log('\n==================================================');
console.log('📊 KẾT QUẢ QUÉT THƯ MỤC PETS:');
console.log(`• File lỗi/trắng (958 bytes) đã xóa: ${corruptedDeleted}`);
console.log(`• File rác non-Pet (Card, Boost, Flag...) đã xóa: ${nonPetDeleted}`);
console.log(`• Số Pet chuẩn còn lại: ${validKept} file PNG`);
console.log('==================================================\n');

function fetchJson(url) {
    return new Promise((resolve, reject) => {
        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try { resolve(JSON.parse(data)); }
                catch (e) { reject(e); }
            });
        }).on('error', reject);
    });
}

function downloadFile(url, destPath) {
    return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(destPath);
        https.get(url, (response) => {
            if (response.statusCode !== 200) {
                fs.unlink(destPath, () => {});
                return reject(`HTTP ${response.statusCode}`);
            }
            response.pipe(file);
            file.on('finish', () => file.close(() => resolve('downloaded')));
        }).on('error', (err) => {
            fs.unlink(destPath, () => {});
            reject(err.message);
        });
    });
}

async function repairCorruptedPets() {
    if (reDownloadTargets.length === 0) {
        console.log('✅ Không có Pet hỏng nào cần tải lại!');
        return;
    }

    console.log(`🔄 Đang thử tải lại ảnh gốc sắc nét cho ${reDownloadTargets.length} Pet bị lỗi...`);
    const assetIds = reDownloadTargets.map(t => t.assetId).join(',');
    const apiUrl = `https://thumbnails.roblox.com/v1/assets?assetIds=${assetIds}&size=420x420&format=Png`;

    try {
        const apiRes = await fetchJson(apiUrl);
        if (apiRes && apiRes.data) {
            for (const item of apiRes.data) {
                if (item.targetId && item.imageUrl) {
                    const target = reDownloadTargets.find(t => t.assetId === String(item.targetId));
                    if (target) {
                        try {
                            await downloadFile(item.imageUrl, target.destPath);
                            console.log(`  ✨ [TẢI LẠI THÀNH CÔNG 420x420 HD]: ${target.filename}`);
                        } catch (e) {}
                    }
                }
            }
        }
    } catch (err) {
        console.error('Lỗi API repair:', err.message);
    }
}

repairCorruptedPets();
