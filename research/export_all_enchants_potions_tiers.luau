-- Script trích xuất TOÀN BỘ Tier (từ Tier 1 đến Tier 10) của Enchants và Potions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Directory = require(ReplicatedStorage.Library.Directory)

local romanNumerals = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"}

local tierAssetsList = {}

local function extractTiersFromCategory(categoryTable, categoryName)
    if not categoryTable then return end
    for baseId, pObj in pairs(categoryTable) do
        if type(baseId) == "string" and type(pObj) == "table" then
            -- Tiers table in PS99 Directory
            local tiers = pObj.Tiers or pObj.tierIcons or pObj.tiers
            local maxTier = pObj.MaxTier or 10

            if type(tiers) == "table" then
                for tierNum = 1, maxTier do
                    local tierObj = tiers[tierNum]
                    local icon = tierObj and (tierObj.Icon or tierObj.thumbnail or tierObj.Texture or tierObj) or (pObj.Icon or pObj.thumbnail)
                    if type(icon) == "function" then pcall(function() icon = icon() end) end
                    local assetId = icon and string.match(tostring(icon), "%d+")

                    if assetId then
                        local romanStr = romanNumerals[tierNum] or tostring(tierNum)
                        table.insert(tierAssetsList, {
                            id = baseId .. " " .. romanStr,
                            baseId = baseId,
                            tier = tierNum,
                            roman = romanStr,
                            assetId = assetId,
                            category = categoryName
                        })
                    end
                end
            else
                -- Single tier item or fallback
                local icon = pObj.Icon or pObj.thumbnail or pObj.Texture
                if type(icon) == "function" then pcall(function() icon = icon() end) end
                local assetId = icon and string.match(tostring(icon), "%d+")
                if assetId then
                    table.insert(tierAssetsList, {
                        id = baseId .. " I",
                        baseId = baseId,
                        tier = 1,
                        roman = "I",
                        assetId = assetId,
                        category = categoryName
                    })
                end
            end
        end
    end
end

extractTiersFromCategory(Directory.Enchants, "Enchant")
extractTiersFromCategory(Directory.Potions, "Potion")

local jsonStr = HttpService:JSONEncode(tierAssetsList)

if writefile then
    writefile("ps99_all_roman_tiers.json", jsonStr)
end

local reqFunc = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
if reqFunc then
    pcall(function()
        reqFunc({
            Url = "http://192.168.1.192:18888/all-tiers",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = jsonStr
        })
    end)
end

print("✅ ĐÃ XUẤT THÀNH CÔNG " .. #tierAssetsList .. " ICON POTION & ENCHANT THEO CÁC TIER I -> X!")
