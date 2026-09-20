const fs = require('fs');
const path = require('path');
const https = require('https');

const mapFilePath = path.join(__dirname, 'ps99_all_assets_map.json');
const outputDir = path.join(__dirname, 'downloaded_assets');

if (!fs.existsSync(mapFilePath)) {
    console.error(`❌ Không tìm thấy file: ${mapFilePath}`);
    process.exit(1);
}

const assetsMapRaw = fs.readFileSync(mapFilePath, 'utf8');
const assetsMap = JSON.parse(assetsMapRaw);

function sanitizeFilename(name) {
    return name.replace(/[\\/:*?"<>|]/g, '_').trim();
}

function downloadFile(url, destPath) {
    return new Promise((resolve, reject) => {
        if (fs.existsSync(destPath)) {
            return resolve('skipped');
        }

        const file = fs.createWriteStream(destPath);
        https.get(url, (response) => {
            if (response.statusCode !== 200) {
                fs.unlink(destPath, () => {});
                return reject(`HTTP ${response.statusCode}`);
            }

            response.pipe(file);
            file.on('finish', () => {
                file.close(() => resolve('downloaded'));
            });
        }).on('error', (err) => {
            fs.unlink(destPath, () => {});
            reject(err.message);
        });
    });
}

async function startBatchDownload() {
    console.log('🚀 Bắt đầu tự động tải toàn bộ Icon Item & Pet Pet Simulator 99 về máy...\n');
    let totalSuccess = 0;
    let totalSkipped = 0;
    let totalFailed = 0;

    for (const [categoryName, itemsObj] of Object.entries(assetsMap)) {
        let itemsList = [];
        if (Array.isArray(itemsObj)) {
            itemsList = itemsObj;
        } else if (typeof itemsObj === 'object' && itemsObj !== null) {
            itemsList = Object.values(itemsObj);
        }
        
        if (itemsList.length === 0) continue;

        const catDir = path.join(outputDir, categoryName);
        fs.mkdirSync(catDir, { recursive: true });

        console.log(`📁 Danh mục: ${categoryName} (${itemsList.length} items)`);

        for (let i = 0; i < itemsList.length; i++) {
            const item = itemsList[i];
            if (!item.Url || !item.ID) continue;

            // Remove spaces in URL if present
            const cleanUrl = item.Url.replace(/\s+/g, '');
            const filename = `${sanitizeFilename(item.ID)}_${item.AssetId}.png`;
            const destPath = path.join(catDir, filename);

            try {
                const status = await downloadFile(cleanUrl, destPath);
                if (status === 'downloaded') {
                    totalSuccess++;
                    process.stdout.write(`  [${i + 1}/${itemsList.length}] ✅ Tải thành công: ${filename}\n`);
                } else {
                    totalSkipped++;
                }
            } catch (err) {
                totalFailed++;
                console.error(`  [${i + 1}/${itemsList.length}] ❌ Lỗi tải ${item.ID}: ${err}`);
            }

            await new Promise(r => setTimeout(r, 20));
        }
        console.log('');
    }

    console.log('==================================================');
    console.log('🎉 TỔNG KẾT QUÁ TRÌNH TẢI ASSETS HÌNH ẢNH:');
    console.log(`• Tải mới thành công: ${totalSuccess} file PNG`);
    console.log(`• Bỏ qua (Đã có sẵn): ${totalSkipped} file PNG`);
    console.log(`• Thất bại: ${totalFailed} file PNG`);
    console.log(`📂 Thư mục chứa ảnh: ${outputDir}`);
    console.log('==================================================');
}

startBatchDownload();
