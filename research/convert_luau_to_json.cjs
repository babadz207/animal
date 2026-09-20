const fs = require('fs');
const path = require('path');

const inputPath = path.join(__dirname, 'ps99_all_assets_map.json');
let raw = fs.readFileSync(inputPath, 'utf8');

// Strip Luau wrapper {{...},n=1}
if (raw.startsWith('{{')) {
    raw = raw.substring(1, raw.lastIndexOf(',n=1}'));
}

// Convert Luau table syntax { ... } to JSON array/object syntax
let jsonStr = raw
    .replace(/\{\{/g, '[{')
    .replace(/\}\}/g, '}]')
    .replace(/(\b\w+\b)=/g, '"$1":')
    .replace(/:\s*https:\s*\/\//g, ': "https://')
    .replace(/format=png"/g, 'format=png"')
    .replace(/\"\"/g, '"');

// Replace invalid quotes inside Url
jsonStr = jsonStr.replace(/"Url":\s*"https:\s*\/\/www\.roblox\.com\/asset-thumbnail\/image\?"assetId":\s*(\d+)&"width":\s*150&"height":\s*150&"format":\s*png"/g, '"Url": "https://www.roblox.com/asset-thumbnail/image?assetId=$1&width=150&height=150&format=png"');

fs.writeFileSync(inputPath, jsonStr, 'utf8');
console.log('✅ Đã convert dữ liệu Assets sang JSON chuẩn!');
