const fs = require('fs');
const path = require('path');

const petsDir = path.join(__dirname, 'downloaded_assets', 'Pets');

const exactNonPetList = [
    'Large Potion Bundle', 'Leprechaun Key', 'Locker Key', 'Massive Comet', 'Party Time',
    'Rainbow Eggs', 'Rainbow Flag', 'Secret Key Lower Half', 'Shiny Flag', 'Shiny Supercharge',
    'Strength Flag', 'Superior Wisdom', 'Tap Teamwork', 'Tech Key Lower Half', 'Tech Key Upper Half',
    'TNT', 'Toy Ball', 'Toy Bundle', 'Dino Lab Keycard', 'Exotic Treasure Flag', 'Fiesta Boss Key',
    'Flag Bundle', 'Hacker Key Hunter', 'Hasty Flag', 'Haunted Backrooms Key', 'PetName',
    'Anime Tanuki Card', 'Blue BIG Maskot Card', 'Camo Axolotl Card', 'Empyrean Lion Card',
    'Error Cat Card', 'Fairy Moth Card', 'Fancy Axolotl Card', 'Gamer Shiba Card', 'Ghostly Bunny Card',
    'Ghostly Cat Card', 'Ghostly Fox Card', 'Ghoul Horse Card', 'Hellhound Card', 'Hippomelon Card',
    'Hot Dooooog Card', 'Huge Anime Scorpion Card', 'Huge Arcade Dog Card', 'Huge Arcane Dominus Card',
    'Huge Blurred Axolotl Card', 'Huge Ghostly Dragon Card', 'Huge Hubert Card', 'Huge Nightmare Dog Card',
    'Huge Ninja Capybara Card', 'Huge Pog Cat Card', 'Huge Sea Dragon Card', 'Huge Storm Axolotl Card',
    'Huge Super Spider Card', 'Hydra Cat Card', 'Immortuus Card', 'Kung Fu Monkey Card',
    'Lumi Axolotl Card', 'Nature Axolotl Card', 'Ninja Otter Card', 'Ninja Snake Card', 'Noob Card',
    'Phantom Wolf Card', 'Pixel Dragon Card', 'Pog Dog Card', 'Pog Dragon Card', 'Pog Monkey Card',
    'Pog Shark Card', 'Retro Bulldog Card', 'Sensei Penguin Card', 'Super Axolotl Card', 'Super Bat Card',
    'Super Seal Card', 'Titanic Anime Cat Card', 'Titanic Cupcake Pegasus Card', 'Titanic Ghostly Wolf Card',
    'Titanic Pop Cat Card', 'Titanic Super Wolf Card', 'Wicked Agony Card'
];

let removed = 0;
let kept = 0;

const files = fs.readdirSync(petsDir);

for (const filename of files) {
    if (!filename.endsWith('.png')) continue;

    const petName = filename.replace(/_\d+\.png$/, '').trim();

    // Check if filename contains Card, Key, Flag, Bundle, TNT, Comet, Toy Ball, Potion Bundle or is in exact list
    const isGarbage = exactNonPetList.includes(petName) ||
                      petName.endsWith(" Card") ||
                      petName.endsWith(" Key") ||
                      petName.endsWith(" Flag") ||
                      petName.endsWith(" Bundle") ||
                      petName === "TNT" ||
                      petName === "Toy Ball" ||
                      petName === "Party Time" ||
                      petName === "Massive Comet" ||
                      petName === "Rainbow Eggs";

    if (isGarbage) {
        fs.unlinkSync(path.join(petsDir, filename));
        console.log(`  🗑️ Xóa file rác trong ảnh: ${filename}`);
        removed++;
    } else {
        kept++;
    }
}

console.log('\n==================================================');
console.log('🎉 ĐÃ DỌN SẠCH 100% TOÀN BỘ FILE RÁC TRONG ẢNH CỦA BẠN!');
console.log(`• Số Pet Thật Chuẩn Giữ Lại: ${kept} file PNG`);
console.log(`• Số File Rác Đã Xóa: ${removed} file PNG`);
console.log(`📂 Thư mục Pets chuẩn: ${petsDir}`);
console.log('==================================================');
