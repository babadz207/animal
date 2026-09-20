const fs = require('fs');
const path = require('path');
const https = require('https');

const fruits = [
    { ID: 'Watermelon', AssetId: '16717381270' },
    { ID: 'Apple', AssetId: '15030757644' },
    { ID: 'Banana', AssetId: '15030757462' },
    { ID: 'Orange', AssetId: '15030757291' },
    { ID: 'Pineapple', AssetId: '15030757105' },
    { ID: 'Rainbow', AssetId: '15030756988' },
    { ID: 'Candycane', AssetId: '15636388090' }
];

const destDir = path.join(__dirname, 'downloaded_assets', 'Fruit');
fs.mkdirSync(destDir, { recursive: true });

async function downloadFruits() {
    const assetIds = fruits.map(f => f.AssetId).join(',');
    const apiUrl = `https://thumbnails.roblox.com/v1/assets?assetIds=${assetIds}&size=150x150&format=Png`;

    https.get(apiUrl, (res) => {
        let raw = '';
        res.on('data', c => raw += c);
        res.on('end', () => {
            const data = JSON.parse(raw);
            if (data && data.data) {
                data.data.forEach(item => {
                    const fruit = fruits.find(f => f.AssetId === String(item.targetId));
                    if (fruit && item.imageUrl) {
                        const filePath = path.join(destDir, `${fruit.ID}_${fruit.AssetId}.png`);
                        const file = fs.createWriteStream(filePath);
                        https.get(item.imageUrl, r => {
                            r.pipe(file);
                            file.on('finish', () => {
                                file.close(() => console.log(`✅ Tải thành công Fruit: ${fruit.ID}_${fruit.AssetId}.png`));
                            });
                        });
                    }
                });
            }
        });
    });
}

downloadFruits();
