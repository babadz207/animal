const fs = require('fs');
const path = require('path');
const https = require('https');

const shinyFruits = [
    { ID: 'Shiny Watermelon', AssetId: '18577639540' },
    { ID: 'Shiny Apple', AssetId: '18577434379' },
    { ID: 'Shiny Banana', AssetId: '18577433706' },
    { ID: 'Shiny Orange', AssetId: '18577433264' },
    { ID: 'Shiny Pineapple', AssetId: '18577434101' },
    { ID: 'Shiny Rainbow', AssetId: '18577433891' }
];

const destDir = path.join(__dirname, 'downloaded_assets', 'Fruit');
fs.mkdirSync(destDir, { recursive: true });

async function downloadShinyFruits() {
    const assetIds = shinyFruits.map(f => f.AssetId).join(',');
    const apiUrl = `https://thumbnails.roblox.com/v1/assets?assetIds=${assetIds}&size=150x150&format=Png`;

    https.get(apiUrl, (res) => {
        let raw = '';
        res.on('data', c => raw += c);
        res.on('end', () => {
            const data = JSON.parse(raw);
            if (data && data.data) {
                data.data.forEach(item => {
                    const fruit = shinyFruits.find(f => f.AssetId === String(item.targetId));
                    if (fruit && item.imageUrl) {
                        const filePath = path.join(destDir, `${fruit.ID}_${fruit.AssetId}.png`);
                        const file = fs.createWriteStream(filePath);
                        https.get(item.imageUrl, r => {
                            r.pipe(file);
                            file.on('finish', () => {
                                file.close(() => console.log(`✅ Tải thành công Shiny Fruit: ${fruit.ID}_${fruit.AssetId}.png`));
                            });
                        });
                    }
                });
            }
        });
    });
}

downloadShinyFruits();
