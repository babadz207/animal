--[[
    Pet Simulator 99 - Master Asset Extractor Script
    Xuất danh sách toàn bộ ID & URL Icon PNG của TẤT CẢ Pets, Enchants, Potions, Fruits, Consumables, Flags, Keys, Cards...
    dùng để tải về máy tính và up lên Web Host!
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Directory = require(ReplicatedStorage.Library.Directory)

local function SafeGetObj(dirTable, id)
    local obj = nil
    pcall(function()
        if dirTable and dirTable[id] ~= nil then
            obj = dirTable[id]
        end
    end)
    return obj
end

local function ExtractAsset(id, categoryName, dirTable, tier)
    local obj = SafeGetObj(dirTable, id)
    if not obj then return nil end
    
    local icon = obj.Thumbnail or obj.Icon or obj.Image or obj.Texture
    if type(icon) == "function" then
        pcall(function() icon = icon(tier or 1) end)
    end
    
    if type(icon) == "string" or type(icon) == "number" then
        local str = tostring(icon)
        local assetId = string.match(str, "%d+")
        if assetId then
            return {
                ID = id,
                Category = categoryName,
                AssetId = assetId,
                Url = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. assetId .. "&width=150&height=150&format=png"
            }
        end
    end
    return nil
end

local allAssetsMap = {
    Pets = {},
    Enchants = {},
    Potions = {},
    Fruits = {},
    Consumables = {},
    Flags = {},
    Misc = {},
    Cards = {},
    Currencies = {},
    Charms = {},
    Lootboxes = {}
}

-- 1. Quét toàn bộ Pets (Regular, Huge, Titanic, Gargantuan)
if Directory.Pets then
    for petId, _ in pairs(Directory.Pets) do
        if type(petId) == "string" then
            local asset = ExtractAsset(petId, "Pet", Directory.Pets)
            if asset then table.insert(allAssetsMap.Pets, asset) end
        end
    end
end

-- 2. Quét Enchants
if Directory.Enchants then
    for id, _ in pairs(Directory.Enchants) do
        if type(id) == "string" then
            local asset = ExtractAsset(id, "Enchant", Directory.Enchants, 1)
            if asset then table.insert(allAssetsMap.Enchants, asset) end
        end
    end
end

-- 3. Quét Potions
if Directory.Potions then
    for id, _ in pairs(Directory.Potions) do
        if type(id) == "string" then
            local asset = ExtractAsset(id, "Potion", Directory.Potions, 1)
            if asset then table.insert(allAssetsMap.Potions, asset) end
        end
    end
end

-- 4. Quét Fruits
if Directory.Fruits then
    for id, _ in pairs(Directory.Fruits) do
        if type(id) == "string" then
            local asset = ExtractAsset(id, "Fruit", Directory.Fruits)
            if asset then table.insert(allAssetsMap.Fruits, asset) end
        end
    end
end

-- 5. Quét Consumables
if Directory.Consumables then
    for id, _ in pairs(Directory.Consumables) do
        if type(id) == "string" then
            local asset = ExtractAsset(id, "Consumable", Directory.Consumables)
            if asset then table.insert(allAssetsMap.Consumables, asset) end
        end
    end
end

-- 6. Quét Cards
if Directory.CardItems then
    for id, _ in pairs(Directory.CardItems) do
        if type(id) == "string" then
            local asset = ExtractAsset(id, "Card", Directory.CardItems)
            if asset then table.insert(allAssetsMap.Cards, asset) end
        end
    end
end

-- 7. Quét Currency
if Directory.Currency then
    for id, _ in pairs(Directory.Currency) do
        if type(id) == "string" then
            local asset = ExtractAsset(id, "Currency", Directory.Currency)
            if asset then table.insert(allAssetsMap.Currencies, asset) end
        end
    end
end

-- 8. Quét Misc & Flags
if Directory.MiscItems then
    for id, _ in pairs(Directory.MiscItems) do
        if type(id) == "string" then
            local asset = ExtractAsset(id, "Misc", Directory.MiscItems)
            if asset then
                if string.find(string.lower(id), "flag") then
                    table.insert(allAssetsMap.Flags, asset)
                else
                    table.insert(allAssetsMap.Misc, asset)
                end
            end
        end
    end
end

print("==================================================")
print("📦 DUMP TOÀN BỘ ASSETS PS99 HOÀN TẤT!")
print("• Pets: " .. tostring(#allAssetsMap.Pets) .. " Icon URLs")
print("• Enchants: " .. tostring(#allAssetsMap.Enchants) .. " Icon URLs")
print("• Potions: " .. tostring(#allAssetsMap.Potions) .. " Icon URLs")
print("• Fruits: " .. tostring(#allAssetsMap.Fruits) .. " Icon URLs")
print("• Consumables: " .. tostring(#allAssetsMap.Consumables) .. " Icon URLs")
print("• Currencies: " .. tostring(#allAssetsMap.Currencies) .. " Icon URLs")
print("• Misc & Flags: " .. tostring(#allAssetsMap.Misc + #allAssetsMap.Flags) .. " Icon URLs")
print("==================================================")

return allAssetsMap
