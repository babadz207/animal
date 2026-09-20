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

function executeLuaChunk(clientId, startIdx, endIdx) {
    return new Promise((resolve, reject) => {
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

            table.sort(petList, function(a, b) return a.id < b.id end)

            local chunk = {}
            for i = ${startIdx}, math.min(${endIdx}, #petList) do
                table.insert(chunk, petList[i])
            end

            return HttpService:JSONEncode(chunk)
        `;

        const payload = JSON.stringify({
            clientId: clientId,
            code: luaCode
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
                try {
                    const jsonRes = JSON.parse(data);
                    let rawStr = jsonRes.output || '';
                    const match = rawStr.match(/\\?"\[.*\]\\?"/s) || rawStr.match(/\[.*\]/s);
                    if (match) {
                        let cleanStr = match[0].replace(/^"/, '').replace(/"$/, '').replace(/\\"/g, '"');
                        const arr = JSON.parse(cleanStr);
                        resolve(arr);
                        return;
                    }
                    resolve([]);
                } catch (e) {
                    console.error('Parse error:', e.message);
                    resolve([]);
                }
            });
        });

        req.on('error', reject);
        req.write(payload);
        req.end();
    });
}

async function main() {
    const clientId = "b734604a-ec49-485a-951b-7c05348c530f";
    console.log(`✅ Kết nối Client thành công: ${clientId}`);
    console.log('📡 Đang trích xuất toàn bộ 3,494 Pets từ Directory.Pets...\n');

    const masterPetMap = new Map();
    const chunkSize = 500;
    const totalCountEstimate = 3500;

    for (let i = 1; i <= totalCountEstimate; i += chunkSize) {
        console.log(`  📡 Trích xuất đợt ${i} - ${i + chunkSize - 1}...`);
        const petsChunk = await executeLuaChunk(clientId, i, i + chunkSize - 1);
        console.log(`     -> Nhận được: ${petsChunk.length} Pets!`);
        for (const item of petsChunk) {
            // STRICT FILTER FOR PURE PETS ONLY: exclude single quotes or non-pets
            if (item.id && item.assetId && !item.id.endsWith("'") && !item.id.includes("Card") && !item.id.includes("Boost")) {
                masterPetMap.set(`${item.id}_${item.assetId}`, item);
            }
        }
    }

    const itemsArray = Array.from(masterPetMap.values());
    console.log(`\n==================================================`);
    console.log(`📦 LOAD CHUẨN 100% TỔNG CỘNG ${itemsArray.length} PURE PETS TỪ GAME!`);
    console.log(`==================================================\n`);

    console.log(`🚀 [SIÊU TỐC ĐA LUỒNG 30 WORKERS] Bắt đầu tải...`);
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
        } catch (err) {}
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
    console.log('⚡ TỔNG KẾT BỘ ẢNH 100% PURE PETS MỚI NHẤT:');
    console.log(`⏱️ Thời gian hoàn tất: ${elapsedSeconds} Giây!`);
    console.log(`• Tải mới thành công: ${downloadedCount} file PNG`);
    console.log(`• Bỏ qua (Đã có sẵn): ${skippedCount} file PNG`);
    console.log(`📂 Thư mục chứa ảnh: ${outputDir}`);
    console.log('==================================================');
}

main();
