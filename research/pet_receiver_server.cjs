const http = require('http');
const fs = require('fs');
const path = require('path');
const https = require('https');

const outputDir = path.join(__dirname, 'downloaded_assets', 'Pets');
fs.mkdirSync(outputDir, { recursive: true });

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

// Ultra-fast Parallel Worker Pool
async function runParallelPool(items, concurrency, taskFn) {
    let index = 0;
    const workers = Array(concurrency).fill(null).map(async () => {
        while (index < items.length) {
            const currentIndex = index++;
            try {
                await taskFn(items[currentIndex], currentIndex);
            } catch (err) {
                // Ignore single file download error and continue
            }
        }
    });
    await Promise.all(workers);
}

async function startFastBatchDownload(itemsArray) {
    console.log(`🚀 [SIÊU TỐC ĐA LUỒNG - 25 PARALLEL WORKERS] Bắt đầu tải ${itemsArray.length} Pet Icons...\n`);
    const startTime = Date.now();

    // 1. Query Roblox API for asset CDN URLs in batches of 100 with 5 parallel workers
    const batchSize = 100;
    const batches = [];
    for (let i = 0; i < itemsArray.length; i += batchSize) {
        batches.push(itemsArray.slice(i, i + batchSize));
    }

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

    console.log(`⚡ Đang tiến hành tải ${downloadQueue.length} ảnh PNG với 25 luồng song song...`);

    let downloadedCount = 0;
    let skippedCount = 0;
    let failedCount = 0;

    // 2. Download files with 25 parallel streams simultaneously
    await runParallelPool(downloadQueue, 25, async (task) => {
        try {
            const status = await downloadFile(task.url, task.destPath);
            if (status === 'downloaded') {
                downloadedCount++;
                if (downloadedCount % 50 === 0 || downloadedCount === downloadQueue.length) {
                    console.log(`  ⚡ [${downloadedCount}/${downloadQueue.length}] ✅ Tải xong: ${task.filename}`);
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
    console.log('⚡ TỔNG KẾT QUÁ TRÌNH TẢI ICON PET SIÊU TỐC:');
    console.log(`⏱️ Tổng thời gian: ${elapsedSeconds} Giây!`);
    console.log(`• Tải mới thành công: ${downloadedCount} file PNG`);
    console.log(`• Bỏ qua (Đã có sẵn): ${skippedCount} file PNG`);
    console.log(`• Thất bại: ${failedCount} file PNG`);
    console.log(`📂 Thư mục lưu: ${outputDir}`);
    console.log('==================================================');
}

const server = http.createServer((req, res) => {
    if (req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const pets = JSON.parse(body);
                console.log(`📥 Nhận được dữ liệu ${pets.length} Pets từ Roblox!`);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: 'ok', count: pets.length }));
                
                // Start ultra-fast parallel download
                startFastBatchDownload(pets);
            } catch (err) {
                console.error('Lỗi JSON:', err.message);
                res.writeHead(400);
                res.end('Invalid JSON');
            }
        });
    } else {
        res.writeHead(200);
        res.end('Ultra-Fast Pet Receiver Server Running');
    }
});

server.listen(18888, '0.0.0.0', () => {
    console.log('🌐 Server Pet Receiver Siêu Tốc sẵn sàng tại cổng 18888!');
});
