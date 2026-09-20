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

async function processExactBundles(itemsArray) {
    console.log(`🚀 [EXACT BUNDLE DOWNLOADER] Đang tải ${itemsArray.length} Icon chuẩn cho Bundle O' Enchants...\n`);

    const assetIds = itemsArray.map(b => b.assetId).join(',');
    const apiUrl = `https://thumbnails.roblox.com/v1/assets?assetIds=${assetIds}&size=420x420&format=Png`;

    try {
        const apiRes = await fetchJson(apiUrl);
        if (apiRes && apiRes.data) {
            const urlMap = new Map();
            for (const item of apiRes.data) {
                if (item.targetId && item.imageUrl) {
                    urlMap.set(String(item.targetId), item.imageUrl);
                }
            }

            for (const itemObj of itemsArray) {
                const imgUrl = urlMap.get(String(itemObj.assetId));
                if (imgUrl) {
                    // Save both names: "Bundle O' Enchants.png" AND "Enchant Bundle.png"
                    const name1 = `${sanitizeFilename(itemObj.id)}.png`;
                    const path1 = path.join(miscDir, name1);
                    await downloadFile(imgUrl, path1);
                    console.log(`  ✅ Đã tải ảnh chuẩn: "${name1}"`);

                    if (itemObj.id === "Bundle O' Enchants" || itemObj.id === "Enchant Bundle") {
                        const pathAlias1 = path.join(miscDir, "Bundle O' Enchants.png");
                        const pathAlias2 = path.join(miscDir, "Enchant Bundle.png");
                        fs.copyFileSync(path1, pathAlias1);
                        fs.copyFileSync(path1, pathAlias2);
                        console.log(`  ✨ Đồng bộ cả 2 tên: "Bundle O' Enchants.png" & "Enchant Bundle.png"`);
                    }
                }
            }
        }
    } catch (err) {
        console.error(`❌ Lỗi tải Exact Bundle: ${err.message}`);
    }

    console.log('\n==================================================');
    console.log('🎉 ĐÃ CẬP NHẬT CHÍNH XÁC ICON BẰNG TÚI SÁCH NÂU!');
    console.log('==================================================');
}

const server = http.createServer((req, res) => {
    if (req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const items = JSON.parse(body);
                console.log(`📥 Nhận ${items.length} Exact Bundle items từ Roblox!`);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: 'ok', count: items.length }));

                processExactBundles(items);
            } catch (err) {
                res.writeHead(400);
                res.end('Invalid JSON');
            }
        });
    } else {
        res.writeHead(200);
        res.end('Exact Bundle Server Running');
    }
});

server.listen(18888, '0.0.0.0', () => {
    console.log('🌐 Máy chủ nhận dữ liệu Exact Bundle chạy tại cổng 18888!');
});
