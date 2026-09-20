const fs = require('fs');
const path = require('path');

const enchantDir = path.join(__dirname, 'downloaded_assets', 'Enchant');
const potionDir = path.join(__dirname, 'downloaded_assets', 'Potion');

const numToRoman = { 1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V', 6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X' };

function processFolder(targetDir) {
    if (!fs.existsSync(targetDir)) return;
    const files = fs.readdirSync(targetDir);

    const baseMap = new Map();

    for (const file of files) {
        if (!file.endsWith('.png')) continue;

        // Match patterns like: "Coins_Tier_7_15801602105.png" or "Coins_Tier_7.png" or "Blast_15012896094.png"
        const tierMatch = file.match(/^(.*?)_Tier_(\d+)/i);
        if (tierMatch) {
            const baseName = tierMatch[1].trim();
            const tierNum = parseInt(tierMatch[2]);
            const romanStr = numToRoman[tierNum] || string(tierNum);
            const romanFilename = `${baseName} ${romanStr}.png`;
            const srcPath = path.join(targetDir, file);
            const destPath = path.join(targetDir, romanFilename);

            fs.copyFileSync(srcPath, destPath);
            console.log(`  ✅ Đã tạo file số La Mã: "${romanFilename}"`);

            if (!baseMap.has(baseName)) baseMap.set(baseName, []);
            baseMap.get(baseName)[tierNum] = destPath;
        } else {
            const cleanName = file.replace(/_\d+\.png$/, '').trim();
            const romanFilename = `${cleanName} I.png`;
            const srcPath = path.join(targetDir, file);
            const destPath = path.join(targetDir, romanFilename);

            fs.copyFileSync(srcPath, destPath);
            console.log(`  ✅ Đã tạo file số La Mã: "${romanFilename}"`);

            if (!baseMap.has(cleanName)) baseMap.set(cleanName, []);
            baseMap.get(cleanName)[1] = destPath;
        }
    }

    // Fallback copy for any missing tiers in baseMap (e.g. Criticals III..X)
    for (const [baseName, tiers] of baseMap.entries()) {
        const availableTiers = Object.keys(tiers).map(Number);
        if (availableTiers.length > 0) {
            const samplePath = tiers[availableTiers[0]];
            for (let t = 1; t <= 10; t++) {
                const romanStr = numToRoman[t];
                const destFilename = `${baseName} ${romanStr}.png`;
                const destPath = path.join(targetDir, destFilename);

                if (!fs.existsSync(destPath) && samplePath) {
                    fs.copyFileSync(samplePath, destPath);
                    console.log(`  ⚡ Tự động tạo fallback cho Tier còn thiếu: "${destFilename}"`);
                }
            }
        }
    }
}

console.log('🚀 Đang tự động chuẩn hóa 100% tên file số La Mã (I -> X) cho Enchants & Potions...\n');
processFolder(enchantDir);
processFolder(potionDir);

console.log('\n==================================================');
console.log('🎉 ĐÃ CHUẨN HÓA 100% FILE SỐ LA MÃ (I -> X) THÀNH CÔNG!');
console.log('==================================================');
