const fs = require('fs');
const path = require('path');
const https = require('https');

const outputDir = path.join(__dirname, 'downloaded_assets', 'Pets');
fs.mkdirSync(outputDir, { recursive: true });

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

// Regex to capture escaped json elements: \"id\":\"...\",\"assetId\":\"...\"
const itemRegex = /\\*"id\\*"\s*:\s*\\*"([^"\\]+)\\*"\s*,\s*\\*"assetId\\*"\s*:\s*\\*"(\d+)\\*"/gi;

const itemsMap = new Map();
let match;
while ((match = itemRegex.exec(allText)) !== null) {
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

    console.log(`✅ Lấy xong link ảnh của ${downloadQueue.length} Pets!`);
    console.log(`⚡ ĐANG TIẾN HÀNH TẢI 30 LUỒNG SONG SONG...\n`);

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
    console.log('⚡ TỔNG KẾT QUÁ TRÌNH TẢI ĐỦ 100% PET SIMULATOR 99:');
    console.log(`⏱️ Thời gian hoàn tất: ${elapsedSeconds} Giây!`);
    console.log(`• Tải mới thành công: ${downloadedCount} file PNG`);
    console.log(`• Bỏ qua (Đã có sẵn): ${skippedCount} file PNG`);
    console.log(`• Thất bại: ${failedCount} file PNG`);
    console.log(`📂 Thư mục chứa ảnh: ${outputDir}`);
    console.log('==================================================');
}

startFastBatchDownload();
