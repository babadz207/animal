const fs = require('fs');
const path = require('path');

const enchantDir = path.join(__dirname, 'downloaded_assets', 'Enchant');
const potionDir = path.join(__dirname, 'downloaded_assets', 'Potion');

// List of Normal Enchants/Potions that ACTUALLY have Tiers 1-10 in PS99
const tieredBaseNames = new Set([
    'Coins', 'Criticals', 'Damage', 'Diamonds', 'Lucky Eggs',
    'Strong Pets', 'Tap Power', 'Walkspeed', 'Lucky', 'Treasure Hunter'
]);

function cleanupSpecialBooks(targetDir) {
    if (!fs.existsSync(targetDir)) return;
    const files = fs.readdirSync(targetDir);

    let deletedCount = 0;
    let createdCount = 0;

    for (const file of files) {
        if (!file.endsWith('.png')) continue;

        // Match roman numerals or _Tier_ format at end of file
        const romanMatch = file.match(/^(.*?)\s+(I|II|III|IV|V|VI|VII|VIII|IX|X)\.png$/i);
        const tierMatch = file.match(/^(.*?)_Tier_\d+/i);

        let baseName = null;
        if (romanMatch) baseName = romanMatch[1].trim();
        else if (tierMatch) baseName = tierMatch[1].trim();

        if (baseName && !tieredBaseNames.has(baseName)) {
            // This is a SPECIAL / EXCLUSIVE book with NO TIERS!
            // 1. Ensure a clean base file exists: "Active Huge Overload.png"
            const cleanFilename = `${baseName}.png`;
            const cleanPath = path.join(targetDir, cleanFilename);
            const currentPath = path.join(targetDir, file);

            if (!fs.existsSync(cleanPath)) {
                fs.copyFileSync(currentPath, cleanPath);
                console.log(`  ✨ Tạo file tên chuẩn duy nhất cho sách đặc biệt: "${cleanFilename}"`);
                createdCount++;
            }

            // 2. Delete redundant tier suffix files: "Active Huge Overload I.png", "Active Huge Overload_Tier_1.png", etc.
            if (file !== cleanFilename) {
                fs.unlinkSync(currentPath);
                console.log(`  🗑️ Xóa file Tier dư thừa cho sách đặc biệt: "${file}"`);
                deletedCount++;
            }
        }
    }

    console.log(`\n==================================================`);
    console.log(`🎉 ĐÃ DỌN SẠCH THƯ MỤC ${path.basename(targetDir)}:`);
    console.log(`• Số file Tier dư thừa đã xóa: ${deletedCount}`);
    console.log(`• Số file Sách Đặc Biệt tên chuẩn đã lưu: ${createdCount}`);
    console.log(`==================================================\n`);
}

console.log('🚀 Đang dọn dẹp và phân loại Sách Phù Phép Đặc Biệt (Exclusive Books không có Tier)...\n');
cleanupSpecialBooks(enchantDir);
cleanupSpecialBooks(potionDir);
