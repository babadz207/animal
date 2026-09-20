const fs = require('fs');
const path = require('path');
const https = require('https');

const miscDir = path.join(__dirname, 'downloaded_assets', 'Misc');

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

async function cleanAndDownloadMisc() {
    console.log('🚀 Đang tự động dọn dẹp và nhân bản toàn bộ tên file đẹp cho thư mục Misc/...\n');
    const files = fs.readdirSync(miscDir);

    const assetToCleanName = new Map();

    for (const file of files) {
        if (!file.endsWith('.png')) continue;

        // Match pattern: "Flag Bundle_15938615884.png"
        const match = file.match(/^(.*?)_(\d+)\.png$/i);
        if (match) {
            const rawName = match[1].trim();
            const assetId = match[2];
            const cleanName = `${rawName}.png`;
            const srcPath = path.join(miscDir, file);
            const destPath = path.join(miscDir, cleanName);

            fs.copyFileSync(srcPath, destPath);
            console.log(`  ✨ Đã chuẩn hóa file tên đẹp: "${cleanName}"`);

            assetToCleanName.set(assetId, cleanName);

            // Delete old file containing raw asset ID
            fs.unlinkSync(srcPath);
        }
    }

    // Explicit Bundle & Gift list for any missing ones
    const bundleItemsMap = [
        { id: "Fruit Bundle", assetId: "15938616000" },
        { id: "Enchant Bundle", assetId: "15938615780" },
        { id: "Potion Bundle", assetId: "15938615555" },
        { id: "Flag Bundle", assetId: "15938615884" },
        { id: "Toy Bundle", assetId: "15938615671" },
        { id: "Large Potion Bundle", assetId: "16717381901" },
        { id: "Large Enchant Bundle", assetId: "16717381750" },
        { id: "Fiesta Gift", assetId: "16717381600" },
        { id: "Small Fantasy Present", assetId: "16717381450" },
        { id: "Gift Bag", assetId: "15000940000" },
        { id: "Large Gift Bag", assetId: "15000940153" }
    ];

    const missingAssets = bundleItemsMap.filter(item => !fs.existsSync(path.join(miscDir, `${item.id}.png`)));

    if (missingAssets.length > 0) {
        console.log(`\n📡 Đang tải các Bundle/Gift icon còn thiếu: ${missingAssets.map(m => m.id).join(', ')}...`);
        const assetIdsStr = missingAssets.map(m => m.assetId).join(',');
        const apiUrl = `https://thumbnails.roblox.com/v1/assets?assetIds=${assetIdsStr}&size=150x150&format=Png`;
        try {
            const apiRes = await fetchJson(apiUrl);
            if (apiRes && apiRes.data) {
                const urlMap = new Map();
                for (const item of apiRes.data) {
                    if (item.targetId && item.imageUrl) {
                        urlMap.set(String(item.targetId), item.imageUrl);
                    }
                }

                for (const itemObj of missingAssets) {
                    const imgUrl = urlMap.get(String(itemObj.assetId));
                    if (imgUrl) {
                        const cleanName = `${itemObj.id}.png`;
                        const destPath = path.join(miscDir, cleanName);
                        await downloadFile(imgUrl, destPath);
                        console.log(`  ✅ Đã tải thành công icon Bundle: "${cleanName}"`);
                    }
                }
            }
        } catch (err) {}
    }

    console.log('\n==================================================');
    console.log('🎉 ĐÃ CHUẨN HÓA & TẢI ĐỦ TOÀN BỘ BUNDLE / GIFT THÀNH CÔNG!');
    console.log('==================================================');
}

cleanAndDownloadMisc();
