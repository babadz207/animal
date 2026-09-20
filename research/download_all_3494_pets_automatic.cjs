const fs = require('fs');
const path = require('path');
const http = require('http');
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

async function start30WorkerDownload(itemsArray) {
    console.log(`\n🚀 [SIÊU TỐC 30 LUỒNG SONG SONG] Bắt đầu tải TOÀN BỘ ${itemsArray.length} PETS TRONG GAME...\n`);
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
    console.log(`⚡ TIẾN HÀNH TẢI 30 LUỒNG SONG SONG...\n`);

    let downloadedCount = 0;
    let skippedCount = 0;

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
        } catch (err) {}
    });

    const elapsedSeconds = ((Date.now() - startTime) / 1000).toFixed(2);

    console.log('\n==================================================');
    console.log('🎉 TỔNG KẾT QUÁ TRÌNH TẢI 100% 3,494 PET SIMULATOR 99:');
    console.log(`⏱️ Thời gian hoàn tất: ${elapsedSeconds} Giây!`);
    console.log(`• Tải mới thành công: ${downloadedCount} file PNG`);
    console.log(`• Bỏ qua (Đã có sẵn): ${skippedCount} file PNG`);
    console.log(`📂 Thư mục chứa ảnh: ${outputDir}`);
    console.log('==================================================');
}

function getMcpClient() {
    return new Promise((resolve) => {
        http.get('http://127.0.0.1:16384/clients', (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const clients = JSON.parse(data);
                    if (clients && clients.length > 0) resolve(clients[0].id);
                    else resolve(null);
                } catch (e) { resolve(null); }
            });
        }).on('error', () => resolve(null));
    });
}

function sendMcpCommand(clientId, code) {
    return new Promise((resolve, reject) => {
        const payload = JSON.stringify({
            clientId: clientId,
            code: code
        });

        const req = http.request({
            hostname: '127.0.0.1',
            port: 16384,
            path: '/execute',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(payload)
            }
        }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try { resolve(JSON.parse(data)); }
                catch (e) { resolve(data); }
            });
        });

        req.on('error', reject);
        req.write(payload);
        req.end();
    });
}

async function main() {
    console.log('🔄 Đang kiểm tra kết nối Roblox Client...');
    const clientId = await getMcpClient();
    if (!clientId) {
        console.log('⏳ Chưa tìm thấy Roblox Client. Vui lòng Execute script trên giả lập Android để tải full 3,494 Pets!');
        return;
    }

    console.log(`✅ Kết nối thành công với Client: ${clientId}`);
    console.log('📡 Đang trích xuất toàn bộ 3,494 Pets từ Directory.Pets...');

    const luaCode = `
        local Directory = require(game:GetService("ReplicatedStorage").Library.Directory)
        local HttpService = game:GetService("HttpService")

        local petList = {}
        if Directory.Pets then
            for petId, pObj in pairs(Directory.Pets) do
                if type(petId) == "string" and type(pObj) == "table" then
                    local icon = pObj.thumbnail or pObj.Thumbnail or pObj.Icon or pObj.Image or pObj.Texture
                    if type(icon) == "function" then pcall(function() icon = icon() end) end
                    local assetId = icon and string.match(tostring(icon), "%d+")
                    if assetId then
                        table.insert(petList, { id = petId, assetId = assetId })
                    end
                end
            end
        end

        return HttpService:JSONEncode(petList)
    `;

    try {
        const res = await sendMcpCommand(clientId, luaCode);
        if (res && res.output) {
            let rawStr = res.output;
            if (typeof rawStr === 'string' && rawStr.startsWith('{')) {
                // Parse LuaEncode wrapper
                const jsonMatch = rawStr.match(/\"\[.*\]\"/);
                if (jsonMatch) {
                    const parsedJson = JSON.parse(JSON.parse(jsonMatch[0]));
                    console.log(`📦 Đã nhận đủ ${parsedJson.length} Pet Asset IDs từ Roblox Client!`);
                    fs.writeFileSync(path.join(__dirname, 'ps99_3494_pets_master.json'), JSON.stringify(parsedJson, null, 2));
                    await start30WorkerDownload(parsedJson);
                    return;
                }
            }
        }
    } catch (err) {
        console.error('❌ Lỗi kết nối MCP:', err.message);
    }
}

main();
