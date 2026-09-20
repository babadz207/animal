const http = require('http');
const fs = require('fs');
const path = require('path');

const luauCode = `
local Directory = require(game:GetService("ReplicatedStorage").Library.Directory)
local Save = require(game:GetService("ReplicatedStorage").Library.Client.Save)

local data = Save.Get()
local petMap = {}

local function ExtractPetAssetId(petId)
    local assetId = nil
    pcall(function()
        local pObj = Directory.Pets and Directory.Pets[petId]
        if pObj then
            local icon = pObj.thumbnail or pObj.Thumbnail or pObj.Icon or pObj.Image or pObj.Texture
            if type(icon) == "function" then pcall(function() icon = icon() end) end
            if icon then assetId = string.match(tostring(icon), "%d+") end
        end
    end)
    return assetId
end

if data and data.Inventory and data.Inventory.Pet then
    for uuid, petData in pairs(data.Inventory.Pet) do
        local petId = petData.id
        if petId and not petMap[petId] then
            local assetId = ExtractPetAssetId(petId)
            if assetId then petMap[petId] = assetId end
        end
    end
end

if Directory.Pets then
    for petId, pObj in pairs(Directory.Pets) do
        if type(petId) == "string" and type(pObj) == "table" then
            local lowerId = string.lower(petId)
            if string.find(lowerId, "huge") or string.find(lowerId, "titanic") or string.find(lowerId, "gargantuan") then
                if not petMap[petId] then
                    local icon = pObj.thumbnail or pObj.Thumbnail or pObj.Icon or pObj.Image or pObj.Texture
                    if type(icon) == "function" then pcall(function() icon = icon() end) end
                    local assetId = icon and string.match(tostring(icon), "%d+")
                    if assetId then petMap[petId] = assetId end
                end
            end
        end
    end
end

local petList = {}
for id, assetId in pairs(petMap) do
    table.insert(petList, { id = id, assetId = assetId })
end

return petList
`;

// Execute code via local MCP HTTP server
const postData = JSON.stringify({ code: luauCode });

const req = http.request({
    hostname: '127.0.0.1',
    port: 16384,
    path: '/execute',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
    }
}, (res) => {
    let raw = '';
    res.on('data', chunk => raw += chunk);
    res.on('end', () => {
        try {
            const data = JSON.parse(raw);
            const items = data.result || data.data || [];
            console.log(`✅ Lấy được ${items.length} Pets từ MCP Server!`);
            
            const destPath = path.join(__dirname, 'ps99_pet_assets_map.json');
            fs.writeFileSync(destPath, JSON.stringify(items, null, 2), 'utf8');
            console.log(`📁 Đã lưu file: ${destPath}`);
        } catch (err) {
            console.error('Lỗi response:', err.message, raw);
        }
    });
});

req.on('error', (err) => {
    console.error('Lỗi kết nối MCP Server:', err.message);
});

req.write(postData);
req.end();
