const fs = require('fs');
const path = require('path');
const http = require('http');

const petsDir = path.join(__dirname, 'downloaded_assets', 'Pets');

if (!fs.existsSync(petsDir)) {
    console.error(`❌ Thư mục không tồn tại: ${petsDir}`);
    process.exit(1);
}

// List of non-pet keywords and exact item names to purge from Pets/ folder
const nonPetKeywords = [
    'Card_', 'Card ', 'Potion_', 'Flag_', 'Gem_', 'Key_', 'Ticket_', 'Token_', 
    'Hat_', 'Sprinkler_', 'Ornament_', 'Axe_', 'Shovel_', 'Rod_', 'Bundle_',
    'Mimic_', 'Breaker_', 'Hunter_', 'Overload_', 'Chest_', 'Orb_', 'Dice_',
    'TNT_', 'Watermelon_', 'Apple_', 'Banana_', 'Orange_', 'Pineapple_', 'Candycane_'
];

const nonPetExactNames = [
    'TNT', 'Tower Rebirth Token', 'Toy Ball', 'Toy Bundle', 'Treasure Hunter',
    'Ultra Rng Chest Luck', 'Walkspeed', 'Watermelon', 'Wicked Agony Card', 'Witch Hat',
    'Coins', 'Damage', 'Diamonds', 'Lucky', 'The Cocktail', 'Huge Potion',
    'Corruption', 'Fortune', 'Diamond Chest Mimic', 'Shiny Hunter', 'Tap Teamwork',
    'Massive Comet', 'Hacker Key Hunter', 'Lucky Block Breaker', 'Magic Orb',
    'Fireworks', 'Pinata Basher', 'Boss Chest Mimic', 'Swift Taps', 'Tap Power',
    'Blast', 'Huge Hunter', 'Shiny Supercharge', 'Mini Chest Fortune',
    'Active Huge Overload', 'Lucky Eggs', 'Strong Pets', 'Breakable Mayhem',
    'Magnet', 'Criticals', 'Angelic', 'Diamond Gift Hunter', 'Rainbow Eggs',
    'Diamond Orb', 'Exotic Pet', 'Superior Chest Mimic', 'Lightning', 'Chest Mimic',
    'Midas Touch', 'Lightning Orb', 'Boss Lucky Block', 'Super Magnet', 'Party Time',
    'Superior Wisdom', 'Super Lightning', 'Mega Chest Breaker', 'Starfall',
    'Super Shiny Hunter', 'Double Coins', 'Explosive', 'Large Taps', 'Chest Breaker',
    'Happy Pets', 'Demonic', 'Nightmare Orb', 'Fruity', 'Lucky Block',
    'Mega Lucky Dice', 'Pet Token Boost', 'Advanced Fishing Rod', 'Essence Fuel',
    'Lucky Raid Boss Key', 'Secret Key Lower Half', 'Lucky Gingerbread', 'Amethyst Gem',
    'Dino Lab Keycard', 'Clover V2', 'Snorkel', 'Bucket O\' Magic', 'Red Christmas Ornament',
    'Spring Egg Token', 'Rainbow Swirl', 'Normal Shovel', 'Tech Key Upper Half',
    'Iron Axe', 'Spring Yellow Sunflower Token', 'Adoption Token Boost', 'Spinny Wheel Ticket',
    'Locker Key', 'Bucket', 'Fantasy Spinny Wheel Ticket', 'Millionaire Ticket',
    'Legendary Glitch Core', 'Lockpick B', 'Stone Axe', 'Large Gift Bag', 'Leprechaun Key',
    'Rainbow Mini Chest', 'Fiesta Boss Key', 'Lockpick A', 'Exclusive Raffle Ticket',
    'Enchants Cape', 'Quartz Gem', 'Large Potion Bundle', 'Amethyst Shovel',
    'Golden Paw Ticket', 'Confetti Cannon', 'Magic Coin Jar', 'Pet Signature', 'Golden Axe',
    'Charm Hammer', 'Pets Cape', 'Haunted Backrooms Key', 'Tech Key Lower Half',
    'Basic Glitch Core', 'Pixel Rainbow Dust', 'Festive Dragon Ornament', 'Lucky Dice V2',
    'Lucky Dice', 'Strength Flag', 'Flag Bundle', 'Diamonds Flag', 'Hasty Flag',
    'Magnet Flag', 'Coins Flag', 'Rainbow Flag', 'Fortune Flag', 'Exotic Treasure Flag', 'Shiny Flag'
];

console.log('🧹 Bắt đầu tiến hành DỌN DẸP TOÀN BỘ rác Item/Potion/Enchant/Card ra khỏi thư mục Pets...\n');

let removedCount = 0;
let keptCount = 0;

const files = fs.readdirSync(petsDir);

for (const filename of files) {
    if (!filename.endsWith('.png')) continue;

    let isNonPet = false;

    // Check exact name match
    for (const exactName of nonPetExactNames) {
        if (filename.startsWith(`${exactName}_`)) {
            isNonPet = true;
            break;
        }
    }

    // Check keyword match
    if (!isNonPet) {
        for (const kw of nonPetKeywords) {
            if (filename.includes(kw)) {
                isNonPet = true;
                break;
            }
        }
    }

    if (isNonPet) {
        const filePath = path.join(petsDir, filename);
        fs.unlinkSync(filePath);
        removedCount++;
        console.log(`  🗑️ Đã xóa rác non-Pet khỏi thư mục Pets: ${filename}`);
    } else {
        keptCount++;
    }
}

console.log('\n==================================================');
console.log('🎉 ĐÃ DỌN DẸP SẠCH 100% RÁC NON-PET KHỎI THƯ MỤC PETS!');
console.log(`• Số Pet chuẩn giữ lại trong Pets/: ${keptCount} file PNG`);
console.log(`• Số file rác (TNT, Potion, Card, Enchant, Token...) đã xóa: ${removedCount} file PNG`);
console.log(`📂 Thư mục Pets chuẩn: ${petsDir}`);
console.log('==================================================');
