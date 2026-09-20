const fs = require('fs');
const path = require('path');

const petsDir = path.join(__dirname, 'downloaded_assets', 'Pets');

const nonPetNamesList = [
    'Coins', 'Criticals', 'Damage', 'Diamonds', 'Explosive', 'Fireworks', 'Fortune',
    'Fruity', 'Happy Pets', 'Huge Hunter', 'Lightning', 'Lucky', 'Magnet', 'Midas Touch',
    'Shiny Hunter', 'Starfall', 'Strong Pets', 'Super Magnet', 'Tap Power', 'Treasure Hunter',
    'Walkspeed', 'Watermelon', 'Lockpick', 'Rod', 'Gem', 'Bucket', 'Charm', 'Chest',
    'Confetti', 'Corruption', 'Essence', 'Fuel', 'Gift', 'Ornament', 'Dust', 'Swirl',
    'Snorkel', 'Hat', 'Cocktail', 'Token', 'Ticket', 'Rng', 'Sprinkler', 'Shovel', 'Axe',
    'Cape', 'Signature', 'Jar', 'Orb', 'Dice', 'Basher', 'Taps', 'Core', 'Hammer', 'Mayhem',
    'Angelic', 'Demonic', 'Exotic Pet', 'Clover V2', 'Fruit', 'Apple', 'Banana', 'Orange', 'Pineapple'
];

let removedCount = 0;
let keptCount = 0;

const files = fs.readdirSync(petsDir);

for (const filename of files) {
    if (!filename.endsWith('.png')) continue;

    const baseName = filename.replace(/_\d+\.png$/, '').trim();

    // Check if baseName matches any item in nonPetNamesList
    const isNonPet = nonPetNamesList.some(item => {
        return baseName === item || baseName.startsWith(item + ' ') || baseName.endsWith(' ' + item) || baseName.includes(' ' + item + ' ');
    });

    if (isNonPet) {
        const filePath = path.join(petsDir, filename);
        console.log(`  🗑️ Xóa triệt để file rác vật phẩm: "${baseName}" -> ${filename}`);
        fs.unlinkSync(filePath);
        removedCount++;
    } else {
        keptCount++;
    }
}

console.log('\n==================================================');
console.log('🎉 ĐÃ DỌN DẸP TRIỆT ĐỂ 100% RÁC NON-PET KHỎI THƯ MỤC PETS!');
console.log(`• Số Pet Chuẩn Giữ Lại trong Pets/: ${keptCount} file PNG`);
console.log(`• Số File Rác Đã Xóa: ${removedCount} file PNG`);
console.log(`📂 Thư mục Pets chuẩn: ${petsDir}`);
console.log('==================================================');
