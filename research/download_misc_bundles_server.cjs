const http = require('http');
const fs = require('fs');
const path = require('path');
const https = require('https');

const miscDir = path.join(__dirname, 'downloaded_assets', 'Misc');
fs.mkdirSync(miscDir, { recursive: true });

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

async function processAndDownloadMisc(itemsArray) {
    console.log(`🚀 [SIÊU TỐC 25 WORKERS] Tải toàn bộ ${itemsArray.length} Icon Vật Phẩm Bundle/Gift/Present/Bag...\n`);
    const startTime = Date.now();

    const batchSize = 50;
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
                        const cleanName = `${sanitizeFilename(itemObj.id)}.png`;
                        downloadQueue.push({ url: imgUrl, destPath: path.join(miscDir, cleanName), filename: cleanName });
                    }
                }
            }
        } catch (err) {}
    });

    console.log(`✅ Đã lấy link ảnh cho ${downloadQueue.length} file PNG!`);
    let downloadedCount = 0;
    let skippedCount = 0;

    await runParallelPool(downloadQueue, 25, async (task) => {
        try {
            const status = await downloadFile(task.url, task.destPath);
            if (status === 'downloaded') {
                downloadedCount++;
                console.log(`  ✅ Đã tải thành công: "${task.filename}"`);
            } else {
                skippedCount++;
            }
        } catch (err) {}
    });

    // Also sanitize old files in Misc/ directory that have numeric asset IDs
    const files = fs.readdirSync(miscDir);
    for (const file of files) {
        const match = file.match(/^(.*?)_\d+\.png$/i);
        if (match) {
            const cleanName = `${match[1].trim()}.png`;
            const srcPath = path.join(miscDir, file);
            const destPath = path.join(miscDir, cleanName);
            if (!fs.existsSync(destPath)) {
                fs.copyFileSync(srcPath, destPath);
                console.log(`  ✨ Tạo file tên đẹp: "${cleanName}"`);
            }
            fs.unlinkSync(srcPath);
        }
    }

    const elapsedSeconds = ((Date.now() - startTime) / 1000).toFixed(2);

    console.log('\n==================================================');
    console.log('🎉 TỔNG KẾT TẢI & CHUẨN HÓA BUNDLE / GIFT / PRESENT:');
    console.log(`⏱️ Thời gian hoàn tất: ${elapsedSeconds} Giây!`);
    console.log(`• Tải mới thành công: ${downloadedCount} file PNG`);
    console.log(`• Đã có sẵn: ${skippedCount} file PNG`);
    console.log(`📂 Thư mục: ${miscDir}`);
    console.log('==================================================');
}

const server = http.createServer((req, res) => {
    if (req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const items = JSON.parse(body);
                console.log(`📥 Nhận ${items.length} Vật Phẩm Misc/Bundle/Gift từ Roblox!`);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: 'ok', count: items.length }));

                processAndDownloadMisc(items);
            } catch (err) {
                res.writeHead(400);
                res.end('Invalid JSON');
            }
        });
    } else {
        res.writeHead(200);
        res.end('Misc Bundle Server Running');
    }
});

server.listen(18888, '0.0.0.0', () => {
    console.log('🌐 Máy chủ nhận dữ liệu Misc/Bundle chạy tại cổng 18888!');
});
