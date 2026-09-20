-- Script trích xuất TOÀN BỘ Bundles, Gifts, Presents, Bags, Keys, Tickets từ PS99
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Directory = require(ReplicatedStorage.Library.Directory)

local miscItemsList = {}

local categoriesToDump = {
    Misc = Directory.Misc,
    Lootbag = Directory.Lootbag or Directory.Lootbags,
    Box = Directory.Box or Directory.Boxes,
    Gift = Directory.Gift or Directory.Gifts,
    Seed = Directory.Seed or Directory.Seeds,
    Charm = Directory.Charm or Directory.Charms,
    Key = Directory.Key or Directory.Keys
}

for catName, catTable in pairs(categoriesToDump) do
    if type(catTable) == "table" then
        for itemId, itemObj in pairs(catTable) do
            if type(itemId) == "string" and type(itemObj) == "table" then
                local icon = itemObj.thumbnail or itemObj.Thumbnail or itemObj.Icon or itemObj.Image or itemObj.Texture
                if type(icon) == "function" then pcall(function() icon = icon() end) end
                local assetId = icon and string.match(tostring(icon), "%d+")

                if assetId then
                    table.insert(miscItemsList, {
                        id = itemId,
                        assetId = assetId,
                        category = catName
                    })
                end
            end
        end
    end
end

local jsonStr = HttpService:JSONEncode(miscItemsList)

if writefile then
    writefile("ps99_all_misc_bundles.json", jsonStr)
end

local reqFunc = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
if reqFunc then
    pcall(function()
        reqFunc({
            Url = "http://192.168.1.192:18888/misc-items",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = jsonStr
        })
    end)
end

print("✅ ĐÃ TRÍCH XUẤT " .. #miscItemsList .. " VẬT PHẨM BUNDLE/GIFT/KEY CHUẨN!")
