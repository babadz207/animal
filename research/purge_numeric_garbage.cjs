const fs = require('fs');
const path = require('path');

const petsDir = path.join(__dirname, 'downloaded_assets', 'Pets');

if (!fs.existsSync(petsDir)) {
    console.error(`❌ Thư mục không tồn tại: ${petsDir}`);
    process.exit(1);
}

console.log('🧹 Bắt đầu tiến hành QUÉT VÀ XÓA TRIỆT ĐỂ TOÀN BỘ CÁC FILE RÁC CHỈ CÓ MÃ SỐ TRONG THƯ MỤC PETS...\n');

let removedCount = 0;
let keptCount = 0;

const files = fs.readdirSync(petsDir);

for (const filename of files) {
    if (!filename.endsWith('.png')) continue;

    // Check if filename starts with pure digits before the underscore (e.g. 15000809958_15000809958.png)
    const pureNumericPrefixRegex = /^\d+_\d+\.png$/;
    
    if (pureNumericPrefixRegex.test(filename)) {
        const filePath = path.join(petsDir, filename);
        fs.unlinkSync(filePath);
        removedCount++;
        console.log(`  🗑️ Đã xóa file rác mã số: ${filename}`);
    } else {
        keptCount++;
    }
}

console.log('\n==================================================');
console.log('🎉 ĐÃ DỌN DẸP SẠCH BÓNG TẤT CẢ FILE MÃ SỐ RÁC KHỎI THƯ MỤC PETS!');
console.log(`• Số Pet có Tên Chuẩn giữ lại trong Pets/: ${keptCount} file PNG`);
console.log(`• Số file rác mã số đã xóa: ${removedCount} file PNG`);
console.log(`📂 Thư mục Pets chuẩn: ${petsDir}`);
console.log('==================================================');
