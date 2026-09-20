const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const outputDir = path.join(__dirname, 'downloaded_assets', 'Pets');
fs.mkdirSync(outputDir, { recursive: true });

// Fetch pet asset list from Roblox MCP Server or from local JSON if saved
async function getPetListFromMcp() {
    return new Promise((resolve, reject) => {
        const req = http.request({
            hostname: '127.0.0.1',
            port: 16384,
            path: '/get_pets_data',
            method: 'GET'
        }, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                try { resolve(JSON.parse(body)); }
                catch (e) { reject(e); }
            });
        });
        req.on('error', reject);
        req.end();
    });
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

async function startBatchDownload() {
    console.log('🚀 Đang kết nối lấy danh sách 1,596 Pet Icon Assets...');
    let itemsArray = [];
    
    // Check local JSON first if exists
    const localJson = path.join(__dirname, 'ps99_pet_assets_map.json');
    if (fs.existsSync(localJson)) {
        itemsArray = JSON.parse(fs.readFileSync(localJson, 'utf8'));
    }

    if (!itemsArray || itemsArray.length === 0) {
        console.error('❌ Không tìm thấy danh sách Pet!');
        return;
    }

    console.log(`📦 Bắt đầu tự động tải toàn bộ ${itemsArray.length} Pet Icon PNG về thư mục downloaded_assets/Pets...\n`);
    let totalSuccess = 0;
    let totalSkipped = 0;
    let totalFailed = 0;

    const batchSize = 50;
    for (let i = 0; i < itemsArray.length; i += batchSize) {
        const batch = itemsArray.slice(i, i + batchSize);
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
                    if (!imgUrl) continue;

                    const filename = `${sanitizeFilename(itemObj.id)}_${itemObj.assetId}.png`;
                    const destPath = path.join(outputDir, filename);

                    try {
                        const status = await downloadFile(imgUrl, destPath);
                        if (status === 'downloaded') {
                            totalSuccess++;
                            console.log(`  [${i + 1}/${itemsArray.length}] ✅ Tải thành công Pet: ${filename}`);
                        } else {
                            totalSkipped++;
                        }
                    } catch (err) {
                        totalFailed++;
                        console.error(`  ❌ Lỗi tải ${itemObj.id}: ${err}`);
                    }
                }
            }
        } catch (err) {
            console.error(`  ❌ Lỗi API Thumbnails batch ${i}: ${err.message}`);
        }

        await new Promise(r => setTimeout(r, 60));
    }

    console.log('\n==================================================');
    console.log('🎉 TỔNG KẾT QUÁ TRÌNH TẢI ICON PET:');
    console.log(`• Tải mới thành công: ${totalSuccess} file PNG`);
    console.log(`• Bỏ qua (Đã có sẵn): ${totalSkipped} file PNG`);
    console.log(`• Thất bại: ${totalFailed} file PNG`);
    console.log(`📂 Thư mục chứa ảnh: ${outputDir}`);
    console.log('==================================================');
}

startBatchDownload();
