const fs = require('fs');
const path = require('path');
const https = require('https');

const inputPath = path.join(__dirname, 'ps99_all_assets_map.json');
const outputDir = path.join(__dirname, 'downloaded_assets');

if (!fs.existsSync(inputPath)) {
    console.error(`❌ Không tìm thấy file: ${inputPath}`);
    process.exit(1);
}

const rawText = fs.readFileSync(inputPath, 'utf8');

// Parse items using Regex
const itemRegex = /"ID":\s*"([^"]+)"[^{}]*?"AssetId":\s*"(\d+)"[^{}]*?"Category":\s*"([^"]+)"/g;

const itemsMap = new Map();
let match;
while ((match = itemRegex.exec(rawText)) !== null) {
    const id = match[1];
    const assetId = match[2];
    const category = match[3];
    itemsMap.set(assetId, { id, assetId, category });
}

const itemsArray = Array.from(itemsMap.values());
console.log(`📦 Tìm thấy tổng cộng ${itemsArray.length} vật phẩm & Pet độc nhất!`);

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
    console.log('🚀 Bắt đầu tự động tải toàn bộ Icon PNG từ Roblox CDN về máy...\n');
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
                        urlMap.set(tostring(item.targetId), item.imageUrl);
                    }
                }

                for (const itemObj of batch) {
                    const imgUrl = urlMap.get(tostring(itemObj.assetId));
                    if (!imgUrl) continue;

                    const catDir = path.join(outputDir, itemObj.category);
                    fs.mkdirSync(catDir, { recursive: true });

                    const filename = `${sanitizeFilename(itemObj.id)}_${itemObj.assetId}.png`;
                    const destPath = path.join(catDir, filename);

                    try {
                        const status = await downloadFile(imgUrl, destPath);
                        if (status === 'downloaded') {
                            totalSuccess++;
                            console.log(`  ✅ Tải thành công: [${itemObj.category}] ${filename}`);
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

        await new Promise(r => setTimeout(r, 100));
    }

    function tostring(val) { return String(val); }

    console.log('\n==================================================');
    console.log('🎉 TỔNG KẾT QUÁ TRÌNH TẢI ASSETS HÌNH ẢNH:');
    console.log(`• Tải mới thành công: ${totalSuccess} file PNG`);
    console.log(`• Bỏ qua (Đã có sẵn): ${totalSkipped} file PNG`);
    console.log(`• Thất bại: ${totalFailed} file PNG`);
    console.log(`📂 Thư mục chứa ảnh: ${outputDir}`);
    console.log('==================================================');
}

startBatchDownload();
