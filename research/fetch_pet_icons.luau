--[[
    Pet Simulator 99 - Pet Icon Extractor Script
    Trích xuất toàn bộ Pet Icon PNG (Equipped Pets, Inventory Pets, Huge Pets, Titanics, Gargantuans & ALL Pets)!
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Directory = require(ReplicatedStorage.Library.Directory)
local Save = require(ReplicatedStorage.Library.Client.Save)

local data = Save.Get()
local petMap = {}

local function ExtractPetAssetId(petId)
    local assetId = nil
    pcall(function()
        local pObj = Directory.Pets and Directory.Pets[petId]
        if pObj then
            local icon = pObj.Thumbnail or pObj.Icon or pObj.Image or pObj.Texture or pObj.IconId or pObj.AssetId
            if type(icon) == "function" then
                pcall(function() icon = icon() end)
            end
            if icon then
                assetId = string.match(tostring(icon), "%d+")
            end
        end
    end)
    return assetId
end

-- 1. Extract Inventory Pets (Regular, Huge, Titanic, Gargantuan)
if data and data.Inventory and data.Inventory.Pet then
    for uuid, petData in pairs(data.Inventory.Pet) do
        local petId = petData.id
        if petId and not petMap[petId] then
            local assetId = ExtractPetAssetId(petId)
            if assetId then
                petMap[petId] = assetId
            end
        end
    end
end

-- 2. Extract Equipped Pets
pcall(function()
    local PetCmds = require(ReplicatedStorage.Library.Client.PetCmds)
    if PetCmds and PetCmds.GetEquipped then
        local equippedMap = PetCmds.GetEquipped()
        if equippedMap then
            for euid, info in pairs(equippedMap) do
                local petData = data and data.Inventory and data.Inventory.Pet and data.Inventory.Pet[info.uid]
                local petId = petData and petData.id
                if petId and not petMap[petId] then
                    local assetId = ExtractPetAssetId(petId)
                    if assetId then petMap[petId] = assetId end
                end
            end
        end
    end
end)

-- 3. Extract ALL Huge, Titanic, Gargantuan & Regular Pets in Directory.Pets
if Directory.Pets then
    for petId, _ in pairs(Directory.Pets) do
        if type(petId) == "string" and not petMap[petId] then
            local assetId = ExtractPetAssetId(petId)
            if assetId then
                petMap[petId] = assetId
            end
        end
    end
end

local petList = {}
for id, assetId in pairs(petMap) do
    table.insert(petList, {
        ID = id,
        AssetId = assetId,
        Category = "Pets",
        Url = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. assetId .. "&width=150&height=150&format=png"
    })
end

print("==================================================")
print("🐾 TRÍCH XUẤT HOÀN TẤT " .. tostring(#petList) .. " PET ICON ASSETS!")
print("==================================================")

return petList
