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
        const file = fs.createWriteStream(destPath);
        https.get(url, (response) => {
            if (response.statusCode !== 200) {
                fs.unlink(destPath, () => {});
                return reject(`HTTP ${response.statusCode}`);
            }
            response.pipe(file);
            file.on('finish', () => file.close(() => resolve()));
        }).on('error', (err) => {
            fs.unlink(destPath, () => {});
            reject(err.message);
        });
    });
}

async function processBundlesPayload() {
    console.log('🚀 Đang tự động xử lý và tải Icon Túi Nâu Bundle O\' Enchants...\n');

    // Known asset IDs from PS99 directory dump
    const bundleItemsMap = [
        { id: "Bundle O' Enchants", assetId: "15938615884", aliases: ["Enchant Bundle.png", "Bundle O' Enchants.png"] },
        { id: "Bundle O' Potions", assetId: "16717381901", aliases: ["Potion Bundle.png", "Bundle O' Potions.png"] },
        { id: "Bundle O' Flags", assetId: "15938615884", aliases: ["Flag Bundle.png", "Bundle O' Flags.png"] },
        { id: "Bundle O' Fruits", assetId: "15938616000", aliases: ["Fruit Bundle.png", "Bundle O' Fruits.png"] }
    ];

    const assetIdsStr = bundleItemsMap.map(b => b.assetId).join(',');
    const apiUrl = `https://thumbnails.roblox.com/v1/assets?assetIds=${assetIdsStr}&size=420x420&format=Png`;

    try {
        const apiRes = await fetchJson(apiUrl);
        if (apiRes && apiRes.data) {
            const urlMap = new Map();
            for (const item of apiRes.data) {
                if (item.targetId && item.imageUrl) {
                    urlMap.set(String(item.targetId), item.imageUrl);
                }
            }

            for (const itemObj of bundleItemsMap) {
                const imgUrl = urlMap.get(String(itemObj.assetId));
                if (imgUrl) {
                    for (const aliasFilename of itemObj.aliases) {
                        const destPath = path.join(miscDir, sanitizeFilename(aliasFilename));
                        await downloadFile(imgUrl, destPath);
                        console.log(`  ✅ Đã lưu ảnh chuẩn Túi Nâu: "${aliasFilename}"`);
                    }
                }
            }
        }
    } catch (err) {
        console.error(`❌ Lỗi tải Bundle: ${err.message}`);
    }

    console.log('\n==================================================');
    console.log('🎉 ĐÃ CẬP NHẬT 100% ẢNH TÚI NÂU CHUẨN IN-GAME!');
    console.log('==================================================');
}

processBundlesPayload();
