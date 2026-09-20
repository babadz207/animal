const fs = require('fs');
const path = require('path');
const https = require('https');

const outputDir = path.join(__dirname, 'downloaded_assets', 'Pets');

const logPath = 'C:\\Users\\levan\\.gemini\\antigravity-ide\\brain\\9d7edb1f-ad20-45c8-bda1-9a368f26cbda\\.system_generated\\logs\\transcript_full.jsonl';
const txt = fs.readFileSync(logPath, 'utf8');

// Match JSON strings from steps 1146, 1148, 1150, 1152
const chunkRegex = /"\[\\?"{\\?"id\\?":\\?"1x1x1x1\\?"[\s\S]*?\]"/g;

const purePetsMap = new Map();

// General regex to parse any valid {"id":"PetName","assetId":"12345"}
const itemRegex = /\\*"id\\*"\s*:\s*\\*"([^"\\]+)\\*"\s*,\s*\\*"assetId\\*"\s*:\s*\\*"(\d+)\\*"/gi;

let match;
while ((match = itemRegex.exec(txt)) !== null) {
    const id = match[1].trim();
    const assetId = match[2].trim();

    // STRICT NON-PET EXCLUSION LIST (BASED ON GAME DIRECTORIES):
    // Directory.Pets ONLY contains real pets. It NEVER contains Items ending with single quotes (Apple', Banana', Candycane'), Keys, Flags, Potions, Enchants, TNT, Bundles, Dice, Cards.
    if (id.endsWith("'") ||
        id.includes("Card") || id.includes("Boost") || id.includes("Sprinkler") ||
        id.includes("Flag") || id.includes("Potion") || id.includes("Enchant") ||
        id.includes("Key") || id.includes("Axe") || id.includes("Shovel") ||
        id.includes("Orb") || id.includes("Dice") || id.includes("Token") ||
        id.includes("Ticket") || id.includes("TNT") || id.includes("Bundle") ||
        id.includes("Comet") || id.includes("Gift Bag") || id.includes("Wheel") ||
        id.includes("Cocktail") || id.includes("Ornament") || id.includes("Charm") ||
        id.includes("Cape") || id.includes("Signature") || id.includes("Supercharge") ||
        id.includes("Wisdom") || id.includes("Teamwork") || id.includes("Taps") ||
        id.includes("Lockpick") || id.includes("Rod") || id.includes("Gem") ||
        id.includes("Jar") || id.includes("Dust") || id.includes("Swirl") ||
        id.includes("Snorkel") || id.includes("Hat") || id.includes("Rng") ||
        id.includes("Hammer") || id.includes("Mayhem") || id.includes("Core") ||
        id.includes("Angelic") || id.includes("Demonic") || id.includes("Exotic Pet") ||
        id.includes("Clover V2") || id === "Fruity" || id === "Happy Pets" ||
        id === "Huge Hunter" || id === "Shiny Hunter" || id === "Super Shiny Hunter" ||
        id === "Midas Touch" || id === "Starfall" || id === "Strong Pets" ||
        id === "Super Magnet" || id === "Magnet" || id === "Fortune" || id === "Lightning" ||
        id === "Fireworks" || id === "Explosive" || id === "Damage" || id === "Criticals" ||
        id === "Coins" || id === "Diamonds" || id === "Double Coins" || id === "Lucky" ||
        id === "Lucky Eggs" || id === "Lucky Gingerbread" || id === "Walkspeed" ||
        id === "Party Time" || id === "Massive Comet" || id === "Large Taps" ||
        id === "Toy Ball" || id === "Watermelon" || id === "Orange" || id === "Pineapple" ||
        id === "Banana" || id === "Apple" || id === "Candycane" || id === "Rainbow") {
        continue;
    }

    if (id && assetId && assetId.length >= 3 && !id.includes('{') && !id.includes('}')) {
        purePetsMap.set(`${id}_${assetId}`, { id, assetId });
    }
}

const itemsArray = Array.from(purePetsMap.values());

console.log('==================================================');
console.log(`📦 LOAD THÀNH CÔNG DỮ LIỆU CHUẨN 100%: ${itemsArray.length} PURE PETS IN GAME!`);
console.log('==================================================\n');

// Clear output directory completely
if (fs.existsSync(outputDir)) {
    const oldFiles = fs.readdirSync(outputDir);
    for (const f of oldFiles) {
        fs.unlinkSync(path.join(outputDir, f));
    }
    console.log(`🧹 Đã làm sạch 100% thư mục Pets để chuẩn bị nạp lại toàn bộ Pet chuẩn!\n`);
} else {
    fs.mkdirSync(outputDir, { recursive: true });
}

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
    console.log('🎉 TỔNG KẾT QUÁ TRÌNH NẠP LẠI 100% PURE PETS SIMULATOR 99:');
    console.log(`⏱️ Thời gian hoàn tất: ${elapsedSeconds} Giây!`);
    console.log(`• Tải mới thành công: ${downloadedCount} file PNG`);
    console.log(`• Bỏ qua (Đã có sẵn): ${skippedCount} file PNG`);
    console.log(`📂 Thư mục chứa ảnh: ${outputDir}`);
    console.log('==================================================');
}

startFastBatchDownload();
