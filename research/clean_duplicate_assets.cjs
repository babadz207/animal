const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, 'downloaded_assets');

if (!fs.existsSync(baseDir)) {
    console.error(`❌ Không tìm thấy thư mục: ${baseDir}`);
    process.exit(1);
}

console.log('🚀 Bắt đầu quét và xóa bỏ các file ảnh trùng lặp Asset ID...\n');

let totalRemoved = 0;
let totalKept = 0;

const subdirs = fs.readdirSync(baseDir, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);

for (const sub of subdirs) {
    const folderPath = path.join(baseDir, sub);
    const files = fs.readdirSync(folderPath);

    // Group files by Asset ID (the numbers before .png)
    const assetMap = new Map();

    for (const filename of files) {
        if (!filename.endsWith('.png')) continue;

        const match = filename.match(/_(\d+)\.png$/);
        if (match) {
            const assetId = match[1];
            if (!assetMap.has(assetId)) {
                assetMap.set(assetId, []);
            }
            assetMap.get(assetId).push(filename);
        }
    }

    for (const [assetId, fileList] of assetMap.entries()) {
        if (fileList.length > 1) {
            // Sort to pick the best/cleanest filename to keep
            // Prefer keeping Tier-labelled names if present, or shortest name
            fileList.sort((a, b) => {
                const aHasTier = a.includes('_Tier_');
                const bHasTier = b.includes('_Tier_');
                if (aHasTier && !bHasTier) return -1;
                if (!aHasTier && bHasTier) return 1;
                return a.length - b.length;
            });

            const keepFile = fileList[0];
            const deleteFiles = fileList.slice(1);

            for (const delName of deleteFiles) {
                const delPath = path.join(folderPath, delName);
                fs.unlinkSync(delPath);
                totalRemoved++;
                console.log(`  🗑️ Đã xóa file trùng: [${sub}] ${delName} (Dùng ${keepFile})`);
            }
            totalKept++;
        } else {
            totalKept++;
        }
    }
}

console.log('\n==================================================');
console.log('🎉 ĐÃ DỌN DẸP SẠCH BÓNG CÁC FILE TRÙNG LẶP!');
console.log(`• Số file ảnh giữ lại (Độc nhất): ${totalKept} file PNG`);
console.log(`• Số file ảnh trùng lặp đã xóa: ${totalRemoved} file PNG`);
console.log('==================================================');
