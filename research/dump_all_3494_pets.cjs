const fs = require('fs');
const path = require('path');
const https = require('https');

const outputDir = path.join(__dirname, 'downloaded_assets', 'Pets');
fs.mkdirSync(outputDir, { recursive: true });

const logPath = 'C:\\Users\\levan\\.gemini\\antigravity-ide\\brain\\9d7edb1f-ad20-45c8-bda1-9a368f26cbda\\.system_generated\\logs\\transcript_full.jsonl';
const logContent = fs.readFileSync(logPath, 'utf8');

const itemRegex = /ID\\?"?:\s*\\?"([^"\\]+)\\?"[^{}]*?AssetId\\?"?:\s*\\?"(\d+)\\?"|AssetId\\?"?:\s*\\?"(\d+)\\?"[^{}]*?ID\\?"?:\s*\\?"([^"\\]+)\\?"|id\\?"?:\s*\\?"([^"\\]+)\\?"[^{}]*?assetId\\?"?:\s*\\?"(\d+)\\?"|assetId\\?"?:\s*\\?"(\d+)\\?"[^{}]*?id\\?"?:\s*\\?"([^"\\]+)\\?"/g;

const itemsMap = new Map();
let match;
while ((match = itemRegex.exec(logContent)) !== null) {
    const id = match[1] || match[4] || match[5] || match[8];
    const assetId = match[2] || match[3] || match[6] || match[7];
    if (id && assetId) {
        itemsMap.set(`${id}_${assetId}`, { id, assetId });
    }
}

const itemsArray = Array.from(itemsMap.values());
console.log(`📦 ĐÃ DÒ TÌM THÀNH CÔNG TỔNG CỘNG ${itemsArray.length} PET ICON ĐỘC NHẤT TRONG GAME!`);

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
    console.log(`🚀 [SIÊU TỐC ĐA LUỒNG 30 WORKERS] Bắt đầu tải TOÀN BỘ ${itemsArray.length} PETS...\n`);
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
        } catch (err) {
            console.error(`❌ Lỗi API Thumbnails: ${err.message}`);
        }
    });

    console.log(`✅ Đã lấy xong link ảnh của ${downloadQueue.length} Pets!`);
    console.log(`⚡ Đang tiến hành TẢI SIÊU TỐC 30 LUỒNG SONG SONG...\n`);

    let downloadedCount = 0;
    let skippedCount = 0;
    let failedCount = 0;

    await runParallelPool(downloadQueue, 30, async (task) => {
        try {
            const status = await downloadFile(task.url, task.destPath);
            if (status === 'downloaded') {
                downloadedCount++;
                if (downloadedCount % 100 === 0 || downloadedCount === downloadQueue.length) {
                    console.log(`  ⚡ [${downloadedCount}/${downloadQueue.length}] ✅ Tải thành công Pet: ${task.filename}`);
                }
            } else {
                skippedCount++;
            }
        } catch (err) {
            failedCount++;
        }
    });

    const elapsedSeconds = ((Date.now() - startTime) / 1000).toFixed(2);

    console.log('\n==================================================');
    console.log('⚡ TỔNG KẾT QUÁ TRÌNH TẢI TOÀN BỘ PET SIMULATOR 99 SIÊU TỐC:');
    console.log(`⏱️ Thời gian hoàn tất: ${elapsedSeconds} Giây!`);
    console.log(`• Tải mới thành công: ${downloadedCount} file PNG`);
    console.log(`• Bỏ qua (Đã có sẵn): ${skippedCount} file PNG`);
    console.log(`• Thất bại: ${failedCount} file PNG`);
    console.log(`📂 Thư mục chứa ảnh: ${outputDir}`);
    console.log('==================================================');
}

startFastBatchDownload();
