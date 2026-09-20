const fs = require('fs');
const path = require('path');

const enchantDir = path.join(__dirname, 'downloaded_assets', 'Enchant');
const potionDir = path.join(__dirname, 'downloaded_assets', 'Potion');

function purgeOldAssetIdFiles(targetDir) {
    if (!fs.existsSync(targetDir)) return;
    const files = fs.readdirSync(targetDir);

    let deletedCount = 0;
    let keptCount = 0;

    for (const file of files) {
        if (!file.endsWith('.png')) continue;

        // Any file containing Asset ID like "_18222206298.png" or "_Tier_1_15030243757.png"
        const hasAssetId = /_\d+\.png$/i.test(file) || /_Tier_/i.test(file);

        if (hasAssetId) {
            fs.unlinkSync(path.join(targetDir, file));
            console.log(`  🗑️ XÓA FILE CŨ THỪA MA ASSET ID: "${file}"`);
            deletedCount++;
        } else {
            keptCount++;
        }
    }

    console.log(`\n==================================================`);
    console.log(`🎉 ĐÃ DỌN SẠCH THƯ MỤC ${path.basename(targetDir)}:`);
    console.log(`• Số file cũ chứa Asset ID / Tier_ cũ đã xóa: ${deletedCount}`);
    console.log(`• Số file tên đẹp chuẩn giữ lại: ${keptCount}`);
    console.log(`==================================================\n`);
}

console.log('🚀 Đang dọn dẹp toàn bộ file ảnh cũ bị dính đuôi Asset ID số rác...\n');
purgeOldAssetIdFiles(enchantDir);
purgeOldAssetIdFiles(potionDir);
