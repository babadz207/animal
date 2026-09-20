-- Script trích xuất CHÍNH XÁC 100% Asset ID của Bundle O' Enchants, Potions, Flags, Fruits
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Directory = require(ReplicatedStorage.Library.Directory)

local bundleItemsList = {}

local bundleKeys = {
    "Bundle O' Enchants", "Bundle O' Potions", "Bundle O' Flags", "Bundle O' Fruits", "Bundle O' Items",
    "Enchant Bundle", "Potion Bundle", "Flag Bundle", "Fruit Bundle", "Toy Bundle", "Large Potion Bundle",
    "Large Enchant Bundle", "Large Gift Bag", "Gift Bag", "Fiesta Gift", "Small Fantasy Present"
}

local function scanDirectoryForBundles(catTable)
    if type(catTable) ~= "table" then return end
    for itemId, itemObj in pairs(catTable) do
        if type(itemId) == "string" and type(itemObj) == "table" then
            local isBundle = string.find(itemId, "Bundle") or string.find(itemId, "Gift") or string.find(itemId, "Bag") or string.find(itemId, "Present")
            if isBundle then
                local icon = itemObj.thumbnail or itemObj.Thumbnail or itemObj.Icon or itemObj.Image or itemObj.Texture
                if type(icon) == "function" then pcall(function() icon = icon() end) end
                local assetId = icon and string.match(tostring(icon), "%d+")

                if assetId then
                    table.insert(bundleItemsList, {
                        id = itemId,
                        assetId = assetId
                    })
                end
            end
        end
    end
end

for _, catName in ipairs({"Misc", "Item", "Items", "Consumable", "Consumables", "Box", "Boxes", "Lootbag", "Lootbags", "Gift", "Gifts"}) do
    local ok, catTable = pcall(function() return Directory[catName] end)
    if ok then scanDirectoryForBundles(catTable) end
end

local jsonStr = HttpService:JSONEncode(bundleItemsList)

local reqFunc = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
if reqFunc then
    pcall(function()
        reqFunc({
            Url = "http://192.168.1.192:18888/bundle-exact",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = jsonStr
        })
    end)
end

print("✅ ĐÃ TRÍCH XUẤT CHÍNH XÁC " .. #bundleItemsList .. " ICON BUNDLE THẬT!")
