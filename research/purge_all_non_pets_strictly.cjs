const fs = require('fs');
const path = require('path');

const petsDir = path.join(__dirname, 'downloaded_assets', 'Pets');

const purePetNamesSet = new Set([
    '1x1x1x1_76631033930341.png',
    '404 Demon_14968169046.png',
    'A-36_15260350888.png',
    'Abomination_88470325736458.png',
    'Abstract Agony_101176910442920.png',
    'Abstract Dominus_78101983924468.png',
    'Abstract Dragon_105288293277261.png',
    'Abyss Carbuncle_132835629822914.png',
    'Abyssal Axolotl_16471612420.png',
    'Abyssal Dolphin_16471612276.png',
    'Doodle Ducky_14968215066.png',
    'Doodle Elephant_14968215385.png',
    'Doodle Fairy_14968215596.png',
    'Doodle Fish_14968215888.png',
    'Doodle Flamingo_14968216185.png',
    'Doodle Fox_14968216406.png',
    'Doodle Green Cobra_14968216688.png',
    'Doodle Griffin_14968216873.png',
    'Doodle Hydra_14968217100.png',
    'Doodle Lamb_14968217417.png',
    'Holofoil Tiger_135178148412108.png',
    'Hologram Axolotl_14968258075.png',
    'Hologram Cat_14968258457.png',
    'Hologram Shark_14968258877.png',
    'Hologram Tiger_14968259117.png',
    'Holographic Axolotl Ball_124267383251291.png',
    'Holographic Axolotl_17270073365.png',
    'Holographic Bear_17270073529.png',
    'Holographic Cat_17270073739.png',
    'Huge Icy Phoenix_77587429055460.png',
    'Huge Inferno Cat_14976463498.png',
    'Huge Inferno Dominus_14976463903.png',
    'Huge Inferno Stealth Bobcat_18644411865.png',
    'Huge Inferno Stealth Cat_18644412090.png',
    'Huge Inkwell Wisp_92033856546098.png',
    'Huge Irish Badger_132795639308777.png',
    'Huge Irish Wolfhound_116172441228488.png',
    'Huge Jaguar_121900456724248.png',
    'Huge Treasure Turtle_18556268254.png',
    'Huge Tree Frog_109144627334415.png',
    'Huge Triceratops_18758757156.png',
    'Huge Tripod Dominus_71758495838669.png',
    'Huge Tripod Octopus_93268363716893.png',
    'Huge Triumphant Eagle_125309090308516.png',
    'Huge Trojan Horse_127674627495853.png',
    'Huge Tropical Flamingo_18644413250.png',
    'Huge Tropical Parrot_18644413700.png',
    'Huge_16011869296.png',
    'Pentangelus_18151025598.png',
    'Peppermint Angelus_15715878441.png',
    'Persimmony Cricket_119442296386528.png',
    'Petal Pixie_128196215824394.png',
    'Phantom Wolf_14968300948.png',
    'Phoenix_14968301259.png',
    'Piggy Piggy_91744460123887.png',
    'Piggy_14968301566.png',
    'Pinata Cat_14968301921.png',
    'Pinata Dog_14968302180.png',
    'Teddy Bear_15715877102.png',
    'Telescope Owl_98284750058098.png',
    'Temple Toucan_116256840601341.png',
    'Temporal Owl_18882335787.png',
    'Tennis Squirrel_123282088983028.png',
    'The Easter Bunny_14968350999.png',
    'Three Headed Dragon_14968351447.png',
    'Thunder Bear_16746709043.png',
    'Tiedye Axolotl_14968351742.png',
    'Tiedye Bear_14968352252.png'
]);

const files = fs.readdirSync(petsDir);

let deletedCount = 0;
let keptCount = 0;

for (const file of files) {
    if (!purePetNamesSet.has(file)) {
        fs.unlinkSync(path.join(petsDir, file));
        console.log(`  🗑️ XÓA TRIỆT ĐỂ FILE RÁC NON-PET: ${file}`);
        deletedCount++;
    } else {
        keptCount++;
    }
}

console.log('\n==================================================');
console.log('🎉 TỔNG KẾT THƯ MỤC PETS CHUẨN 100% PURE PETS:');
console.log(`• Số File Rác Đã Xóa: ${deletedCount} file PNG`);
console.log(`• Số Pet Thật Chuẩn Giữ Lại: ${keptCount} file PNG`);
console.log(`📂 Thư mục: ${petsDir}`);
console.log('==================================================');
