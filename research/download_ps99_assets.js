const fs = require('fs');
const path = require('path');
const https = require('https');

// Read assets mapping JSON file
const mapFilePath = path.join(__dirname, 'ps99_all_assets_map.json');
const outputDir = path.join(__dirname, 'downloaded_assets');

if (!fs.existsSync(mapFilePath)) {
    console.error(`❌ Không tìm thấy file: ${mapFilePath}`);
    console.log('👉 Vui lòng chạy script ps99_dump_all_asset_urls.luau trong Roblox để xuất ra file ps99_all_assets_map.json trước!');
    process.exit(1);
}

const assetsMap = JSON.parse(fs.readFileSync(mapFilePath, 'utf8'));

// Helper function to sanitize file names for Windows
function sanitizeFilename(name) {
    return name.replace(/[\\/:*?"<>|]/g, '_').trim();
}

// Download function with HTTPS
function downloadFile(url, destPath) {
    return new Promise((resolve, reject) => {
        if (fs.existsSync(destPath)) {
            // Already downloaded, skip
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

    for (const [categoryName, itemsList] of Object.entries(assetsMap)) {
        if (!Array.isArray(itemsList) || itemsList.length === 0) continue;

        const catDir = path.join(outputDir, categoryName);
        fs.mkdirSync(catDir, { recursive: true });

        console.log(`📁 Danh mục: ${categoryName} (${itemsList.length} items)`);

        for (let i = 0; i < itemsList.length; i++) {
            const item = itemsList[i];
            if (!item.Url || !item.ID) continue;

            const filename = `${sanitizeFilename(item.ID)}_${item.AssetId}.png`;
            const destPath = path.join(catDir, filename);

            try {
                const status = await downloadFile(item.Url, destPath);
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

            // Small delay to prevent rate limit
            await new Promise(r => setTimeout(r, 50));
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
