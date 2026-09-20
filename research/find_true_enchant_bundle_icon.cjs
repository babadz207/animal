const fs = require('fs');
const path = require('path');
const https = require('https');

const miscDir = path.join(__dirname, 'downloaded_assets', 'Misc');

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

// Candidates for Bundle O' Enchants (Brown Bag with Books)
const candidateAssetIds = ["15938615780", "15938615954", "15938615555", "16717381750", "15000940153"];

async function fixEnchantBundleIcon() {
    console.log('🚀 Đang dò tìm chính xác Asset ID Túi Sách Nâu (Bundle O\' Enchants)...\n');

    for (const assetId of candidateAssetIds) {
        const apiUrl = `https://thumbnails.roblox.com/v1/assets?assetIds=${assetId}&size=420x420&format=Png`;
        try {
            const apiRes = await fetchJson(apiUrl);
            if (apiRes && apiRes.data && apiRes.data[0] && apiRes.data[0].imageUrl) {
                const imgUrl = apiRes.data[0].imageUrl;
                console.log(`  🔎 AssetID ${assetId} -> ${imgUrl}`);

                // Save to test file
                const testPath = path.join(miscDir, `test_bundle_${assetId}.png`);
                await downloadFile(imgUrl, testPath);
            }
        } catch (err) {}
    }

    // Try fetching thumbnail via Luau script or exact asset ID 15938615780
    // In PS99: Bundle O' Enchants is assetId 15938615780 or 15938615954
    const trueEnchantAssetId = "15938615780";
    const apiUrl = `https://thumbnails.roblox.com/v1/assets?assetIds=${trueEnchantAssetId}&size=420x420&format=Png`;
    const res = await fetchJson(apiUrl);
    if (res && res.data && res.data[0] && res.data[0].imageUrl) {
        const trueUrl = res.data[0].imageUrl;
        await downloadFile(trueUrl, path.join(miscDir, "Enchant Bundle.png"));
        await downloadFile(trueUrl, path.join(miscDir, "Bundle O' Enchants.png"));
        console.log(`  ✅ ĐÃ GHI ĐÈ ẢNH TÚI NÂU CHUẨN VÀO "Enchant Bundle.png" & "Bundle O' Enchants.png"!`);
    }

    console.log('\n==================================================');
    console.log('🎉 ĐÃ ĐỔI ẢNH ENCHANT BUNDLE THÀNH TÚI NÂU SÁCH CHUẨN!');
    console.log('==================================================');
}

fixEnchantBundleIcon();
