const fs = require('fs');
const path = require('path');

const petsDir = path.join(__dirname, 'downloaded_assets', 'Pets');

const files = fs.readdirSync(petsDir);
let count = 0;

for (const f of files) {
    // Check if filename contains single quote (Apple'_..., Banana'_..., Candycane'_...)
    if (f.includes("'")) {
        fs.unlinkSync(path.join(petsDir, f));
        console.log(`  🗑️ Xóa file Trái cây sót: ${f}`);
        count++;
    }
}

console.log(`\n🎉 Đã dọn sạch ${count} file Trái cây sót khỏi thư mục Pets!`);
