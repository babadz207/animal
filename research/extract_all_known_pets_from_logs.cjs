const fs = require('fs');
const path = require('path');
const https = require('https');

const outputDir = path.join(__dirname, 'downloaded_assets', 'Pets');
fs.mkdirSync(outputDir, { recursive: true });

const logPath = 'C:\\Users\\levan\\.gemini\\antigravity-ide\\brain\\9d7edb1f-ad20-45c8-bda1-9a368f26cbda\\.system_generated\\logs\\transcript_full.jsonl';
const txt = fs.readFileSync(logPath, 'utf8');

const itemRegex = /\\*"id\\*"\s*:\s*\\*"([^"\\]+)\\*"\s*,\s*\\*"assetId\\*"\s*:\s*\\*"(\d+)\\*"/gi;

const purePetsMap = new Map();

const nonPetKeywords = [
    'Card', 'Boost', 'Sprinkler', 'Flag', 'Potion', 'Enchant', 'Key', 'Axe', 'Shovel',
    'Orb', 'Dice', 'Token', 'Ticket', 'TNT', 'Bundle', 'Comet', 'Gift Bag', 'Wheel',
    'Cocktail', 'Ornament', 'Charm', 'Cape', 'Signature', 'Supercharge', 'Wisdom',
    'Teamwork', 'Taps', 'Lockpick', 'Rod', 'Gem', 'Jar', 'Dust', 'Swirl', 'Snorkel',
    'Hat', 'Rng', 'Hammer', 'Mayhem', 'Core', 'Angelic', 'Demonic', 'Exotic Pet',
    'Clover V2', 'Fruity', 'Happy Pets', 'Huge Hunter', 'Shiny Hunter', 'Super Shiny Hunter',
    'Midas Touch', 'Starfall', 'Strong Pets', 'Super Magnet', 'Magnet', 'Fortune',
    'Lightning', 'Fireworks', 'Explosive', 'Damage', 'Criticals', 'Coins', 'Diamonds',
    'Double Coins', 'Lucky', 'Lucky Eggs', 'Lucky Gingerbread', 'Walkspeed', 'Party Time',
    'Massive Comet', 'Large Taps', 'Toy Ball', 'Watermelon', 'Orange', 'Pineapple',
    'Banana', 'Apple', 'Candycane', 'Rainbow', 'Bucket'
];

let match;
while ((match = itemRegex.exec(txt)) !== null) {
    const id = match[1].trim();
    const assetId = match[2].trim();

    if (id.endsWith("'") || id.includes('{') || id.includes('}')) continue;

    let isNonPet = false;
    for (const kw of nonPetKeywords) {
        if (id === kw || id.endsWith(' ' + kw) || id.startsWith(kw + ' ') || id.includes(' ' + kw + ' ')) {
            isNonPet = true;
            break;
        }
    }

    if (!isNonPet && id && assetId && assetId.length >= 3) {
        purePetsMap.set(`${id}_${assetId}`, { id, assetId });
    }
}

const itemsArray = Array.from(purePetsMap.values());

console.log('==================================================');
console.log(`📦 BẮT ĐẦU QUÉT LẠI LỊCH SỬ DỮ LIỆU: TÌM THẤY ${itemsArray.length} PURE PETS!`);
console.log('==================================================\n');

function sanitizeFilename(name) {
    return name.replace(/[\\/:*?"<>|]/g, '_').trim();
}

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
        if (fs.existsSync(destPath)) return resolve('skipped');

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

async function runParallelPool(items, concurrency, taskFn) {
    let index = 0;
    const workers = Array(concurrency).fill(null).map(async () => {
        while (index < items.length) {
            const currentIndex = index++;
            try {
                await taskFn(items[currentIndex], currentIndex);
            } catch (err) {}
        }
    });
    await Promise.all(workers);
}

async function startFastBatchDownload() {
    console.log(`🚀 [SIÊU TỐC ĐA LUỒNG 30 WORKERS] Bắt đầu tải TOÀN BỘ ${itemsArray.length} PURE PETS...\n`);
    const startTime = Date.now();

    const batchSize = 100;
    const batches = [];
    for (let i = 0; i < itemsArray.length; i += batchSize) {
        batches.push(itemsArray.slice(i, i + batchSize));
    }

    console.log(`📡 Đang truy vấn Roblox API cho ${batches.length} đợt (100 Asset IDs/đợt)...`);
    const downloadQueue = [];

    await runParallelPool(batches, 5, async (batch) => {
        const assetIds = batch.map(b => b.assetId).join(',');
        const apiUrl = `https://thumbnails.roblox.com/v1/assets?assetIds=${assetIds}&size=150x150&format=Png`;
        try {
            const apiRes = await fetchJson(apiUrl);
            if (apiRes && apiRes.data) {
                const urlMap = new Map();
                for (const item of apiRes.data) {
                    if (item.targetId && item.imageUrl) {
                        urlMap.set(String(item.targetId), item.imageUrl);
                    }
                }

                for (const itemObj of batch) {
                    const imgUrl = urlMap.get(String(itemObj.assetId));
                    if (imgUrl) {
                        const filename = `${sanitizeFilename(itemObj.id)}_${itemObj.assetId}.png`;
                        const destPath = path.join(outputDir, filename);
                        downloadQueue.push({ url: imgUrl, destPath, filename, id: itemObj.id });
                    }
                }
            }
        } catch (err) {}
    });

    console.log(`✅ Lấy xong link ảnh của ${downloadQueue.length} Pets!`);
    console.log(`⚡ TIẾN HÀNH TẢI 30 LUỒNG SONG SONG...\n`);

    let downloadedCount = 0;
    let skippedCount = 0;

    await runParallelPool(downloadQueue, 30, async (task) => {
        try {
            const status = await downloadFile(task.url, task.destPath);
            if (status === 'downloaded') {
                downloadedCount++;
                if (downloadedCount % 50 === 0 || downloadedCount === downloadQueue.length) {
                    console.log(`  ⚡ [${downloadedCount}/${downloadQueue.length}] ✅ Tải thành công Pet: ${task.filename}`);
                }
            } else {
                skippedCount++;
            }
        } catch (err) {}
    });

    const elapsedSeconds = ((Date.now() - startTime) / 1000).toFixed(2);

    console.log('\n==================================================');
    console.log('🎉 TỔNG KẾT QUÁ TRÌNH TẢI PURE PETS:');
    console.log(`⏱️ Thời gian hoàn tất: ${elapsedSeconds} Giây!`);
    console.log(`• Tải mới thành công: ${downloadedCount} file PNG`);
    console.log(`• Bỏ qua (Đã có sẵn): ${skippedCount} file PNG`);
    console.log(`📂 Thư mục chứa ảnh: ${outputDir}`);
    console.log('==================================================');
}

startFastBatchDownload();
