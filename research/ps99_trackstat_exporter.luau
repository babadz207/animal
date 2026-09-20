--[[
    Pet Simulator 99 - Ultimate TrackStat Data Exporter Script (With Shiny Fruit & Tier 1-10 Dynamic Icon URLs)
    Includes: Profile, Slots, 100% Fixed Equipped Pets (75/75), MaxZone = 279, Huge Pets, Titanic (TTN),
    Gargantuan (GGT) & ALL Regular Pets Analytics with Precise Tier-Based PNG Icon URLs (Tier I ➔ Tier X) & Shiny Fruits!
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer
local Save = require(ReplicatedStorage.Library.Client.Save)
local Directory = require(ReplicatedStorage.Library.Directory)

local data = Save.Get()

-- Helper function to safely extract Roblox Image Asset Icon URL & ID for ANY item, ANY Tier (1-10) and Shiny Fruit
local function SafeGetDirectoryObj(dirTable, id)
    local obj = nil
    pcall(function()
        if dirTable and dirTable[id] ~= nil then
            obj = dirTable[id]
        end
    end)
    return obj
end

local function GetItemIconData(id, rawCategory, tier, isShiny)
    local obj = nil
    
    if rawCategory == "Enchant" then obj = SafeGetDirectoryObj(Directory.Enchants, id)
    elseif rawCategory == "Potion" then obj = SafeGetDirectoryObj(Directory.Potions, id)
    elseif rawCategory == "Fruit" then obj = SafeGetDirectoryObj(Directory.Fruits, id)
    elseif rawCategory == "Currency" then obj = SafeGetDirectoryObj(Directory.Currency, id)
    elseif rawCategory == "Consumable" then obj = SafeGetDirectoryObj(Directory.Consumables, id)
    elseif rawCategory == "Card" then obj = SafeGetDirectoryObj(Directory.CardItems, id)
    elseif rawCategory == "Charm" then obj = SafeGetDirectoryObj(Directory.Charms, id)
    elseif rawCategory == "Lootbox" or rawCategory == "Box" then obj = SafeGetDirectoryObj(Directory.Lootboxes, id) or SafeGetDirectoryObj(Directory.Boxes, id)
    elseif rawCategory == "Misc" then obj = SafeGetDirectoryObj(Directory.MiscItems, id)
    end
    
    if not obj then
        obj = SafeGetDirectoryObj(Directory.Consumables, id) or SafeGetDirectoryObj(Directory.MiscItems, id) or SafeGetDirectoryObj(Directory.Enchants, id) or SafeGetDirectoryObj(Directory.Potions, id)
    end
    
    if not obj then return nil end
    
    local icon = nil
    if isShiny and obj.ShinyIcon then
        icon = obj.ShinyIcon
    else
        icon = obj.Icon or obj.Image or obj.IconId or obj.Thumbnail or obj.Texture
    end

    if type(icon) == "function" then
        pcall(function()
            icon = icon(tier or 1)
        end)
    end
    
    if type(icon) == "string" or type(icon) == "number" then
        local str = tostring(icon)
        local assetId = string.match(str, "%d+")
        if assetId then
            return {
                Raw = str,
                AssetId = assetId,
                IconUrl = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. assetId .. "&width=150&height=150&format=png"
            }
        end
        return { Raw = str }
    end
    return nil
end

local function GetPetIconUrl(petId)
    local petIcon = nil
    pcall(function()
        local pObj = SafeGetDirectoryObj(Directory.Pets, petId)
        if pObj then
            local rawIcon = pObj.Thumbnail or pObj.Icon or pObj.Image or pObj.Texture
            if type(rawIcon) == "function" then
                pcall(function() rawIcon = rawIcon() end)
            end
            local assetId = rawIcon and string.match(tostring(rawIcon), "%d+")
            if assetId then
                petIcon = "https://www.roblox.com/asset-thumbnail/image?assetId=" .. assetId .. "&width=150&height=150&format=png"
            end
        end
    end)
    return petIcon
end

-- Map Rank Numbers to Rank Titles in PS99
local RankTitleByNumber = {
    [1] = "Noob", [2] = "Beginner", [3] = "Rookie", [4] = "Adventurer", [5] = "Experienced",
    [6] = "Pro", [7] = "Elite", [8] = "Expert", [9] = "Master", [10] = "Legend",
    [11] = "Champion", [12] = "Superstar", [13] = "Guardian", [14] = "Titan", [15] = "Sentinel",
    [16] = "Vanguard", [17] = "Crusader", [18] = "Conqueror", [19] = "Monarch", [20] = "Ascendant",
    [21] = "Awakened", [22] = "Architect", [23] = "Visionary", [24] = "Prodigy", [25] = "Seer",
    [26] = "Celestial", [27] = "Apex", [28] = "Oracle", [29] = "Voidborn", [30] = "Cosmic",
    [31] = "Demigod", [32] = "Mythic", [33] = "Realmlord", [34] = "Ancient", [35] = "Mythkeeper",
    [36] = "Soulforge", [37] = "Starbreaker", [38] = "Timekeeper", [39] = "Kingmaker", [40] = "Herald"
}

-- 1. PRECISE ZONE ANALYTICS (#279 Hollow Veil Castle)
local maxUnlockedZoneNum = 1
local maxUnlockedZoneName = "Spawn"
local totalZonesInGame = 279
local currentWorldNum = tonumber(data.RecentWorld) or 4

if data and data.UnlockedZones and Directory.Zones then
    for zoneName, isUnlocked in pairs(data.UnlockedZones) do
        if isUnlocked then
            local zObj = SafeGetDirectoryObj(Directory.Zones, zoneName)
            if zObj then
                local zNum = zObj.ZoneNumber or zObj.Number or 0
                if zNum > maxUnlockedZoneNum then
                    maxUnlockedZoneNum = zNum
                    maxUnlockedZoneName = zoneName
                end
            end
        end
    end
end

if maxUnlockedZoneNum == 1 and data.LastZoneBoughtEggs then
    local zObj = SafeGetDirectoryObj(Directory.Zones, data.LastZoneBoughtEggs)
    if zObj then
        maxUnlockedZoneNum = zObj.ZoneNumber or zObj.Number or 279
        maxUnlockedZoneName = data.LastZoneBoughtEggs
    end
end

local zoneAnalytics = {
    MaxZoneNumber = maxUnlockedZoneNum,           -- 279
    MaxZoneName = maxUnlockedZoneName,             -- "Hollow Veil Castle"
    MaxZoneDisplay = "Zone " .. tostring(maxUnlockedZoneNum) .. " (#" .. tostring(maxUnlockedZoneNum) .. " " .. maxUnlockedZoneName .. ")",
    TotalZonesInGame = totalZonesInGame,           -- 279
    CurrentWorldNumber = currentWorldNum,          -- World 4
    LastZoneBoughtEggs = data.LastZoneBoughtEggs or "Hollow Veil Castle"
}

-- 2. EXACT 75/75 EQUIPPED PETS DETECTOR (PetCmds.GetEquipped 1-to-1 Slot Counter)
local equippedPetsList = {}

pcall(function()
    local PetCmds = require(ReplicatedStorage.Library.Client.PetCmds)
    if PetCmds and PetCmds.GetEquipped then
        local equippedMap = PetCmds.GetEquipped()
        if equippedMap then
            for euid, info in pairs(equippedMap) do
                if type(info) == "table" and info.uid then
                    local petData = data and data.Inventory and data.Inventory.Pet and data.Inventory.Pet[info.uid]
                    local id = petData and petData.id or "Unknown"
                    local typeName = petData and (petData.pt == 1 and "Golden" or (petData.pt == 2 and "Rainbow" or "Normal")) or "Normal"
                    local isShiny = petData and (petData.sh and true or false) or false
                    local lowerId = string.lower(id)
                    local isHuge = string.find(lowerId, "huge") ~= nil
                    local isTitanic = string.find(lowerId, "titanic") ~= nil
                    local isGargantuan = string.find(lowerId, "gargantuan") ~= nil
                    
                    table.insert(equippedPetsList, {
                        EquipSlotID = euid,
                        UUID = info.uid,
                        ID = id,
                        Type = typeName,
                        Shiny = isShiny,
                        IsHuge = isHuge,
                        IsTitanic = isTitanic,
                        IsGargantuan = isGargantuan,
                        IconUrl = GetPetIconUrl(id)
                    })
                end
            end
        end
    end
end)

local totalEquippedPetsCount = #equippedPetsList -- 75 Pets!
local maxPetsEquippedSlots = data.MaxPetsEquipped or 75

local equippedPetsSummary = {
    TotalEquippedPetsCount = totalEquippedPetsCount, -- 75
    MaxPetsEquippedSlots = maxPetsEquippedSlots,     -- 75
    EquippedDisplay = tostring(totalEquippedPetsCount) .. "/" .. tostring(maxPetsEquippedSlots) .. " Pets",
    EquippedPetsList = equippedPetsList
}

-- 3. General Profile Metadata & Equipment Slots
local slotsInfo = {
    MaxPetSlots = maxPetsEquippedSlots,
    PetSlotsPurchased = data.PetSlotsPurchased or 71,
    MaxEggHatchSlots = 15 + (data.EggSlotsPurchased or 70),
    EggSlotsPurchased = data.EggSlotsPurchased or 70,
    MaxEnchantSlots = data.MaxEnchantsEquipped or 5,
    EquippedUltimate = data.EquippedUltimateId or "TNT Shower",
    AutoEquipPetsEnabled = data.AutoEquipPets or true
}

local profile = {
    Username = lp.Name,
    DisplayName = lp.DisplayName,
    UserId = lp.UserId,
    PlaceId = game.PlaceId,
    JobId = game.JobId,
    RankNumber = data.Rank or 17,
    Rebirths = data.Rebirths or 0,
    TotalEggHatches = data.EggHatches or data.EggsHatched or 0,
    TotalSessions = data.TotalSessions or 0,
    PlayTimeHours = math.floor((data.Age or 0) / 3600),
    RaidCompletions = data.RaidCompletions or 0,
    TotalRollsV2 = data.TotalRollsV2 or 0,
    Diamonds = lp:FindFirstChild("leaderstats") and lp.leaderstats:FindFirstChild("💎 Diamonds") and lp.leaderstats["💎 Diamonds"].Value or 0,
    Slots = slotsInfo,
    Zone = zoneAnalytics
}

-- 4. Lucky Block Event Analytics & Active Buffs
local luckyBlockAnalytics = {
    LuckyBreakoutBossesDefeated = data.LuckyBreakoutBossesDefeated2026 or 0,
    LuckyBreakoutLevelsCleared = data.LuckyBreakoutLevelsCleared2026 or 0,
    EventUpgrades = data.EventUpgrades or {},
    ActiveBuffs = {},
    EventConsumableBoosters = {}
}

if data.Buffs then
    for buffName, buffData in pairs(data.Buffs) do
        if type(buffData) == "table" then
            luckyBlockAnalytics.ActiveBuffs[buffName] = {
                RemainingSeconds = math.floor(buffData.remaining or 0),
                RemainingHours = math.floor((buffData.remaining or 0) / 3600)
            }
        end
    end
end

-- 5. Precise Rank & Star Calculations
local rankTitle = RankTitleByNumber[profile.RankNumber] or "Unknown"
local rewardsLeftCount = 0
local totalStarsSumForRank = 0
local totalStarsRemainingForNextRank = 0
local currentTierProgressStars = data.Stars or 0
local activeQuestsStarsSum = 0

local rankObj = SafeGetDirectoryObj(Directory.Ranks, rankTitle)

local redeemedMap = data.RedeemedRankRewards or {}
if rankObj and rankObj.Rewards then
    local rewardsList = rankObj.Rewards
    local isFirstUnclaimed = true
    
    for idx, rewardItem in ipairs(rewardsList) do
        local starsRequired = rewardItem.StarsRequired or 0
        totalStarsSumForRank = totalStarsSumForRank + starsRequired
        
        if not redeemedMap[idx] and not redeemedMap[tostring(idx)] then
            rewardsLeftCount = rewardsLeftCount + 1
            if isFirstUnclaimed then
                totalStarsRemainingForNextRank = totalStarsRemainingForNextRank + math.max(0, starsRequired - currentTierProgressStars)
                isFirstUnclaimed = false
            else
                totalStarsRemainingForNextRank = totalStarsRemainingForNextRank + starsRequired
            end
        end
    end
end

local currentStarsEarnedInRank = math.max(0, totalStarsSumForRank - totalStarsRemainingForNextRank)
local rankProgressDisplay = "Rank " .. tostring(profile.RankNumber) .. " (" .. tostring(currentStarsEarnedInRank) .. "/" .. tostring(totalStarsSumForRank) .. ")"

local activeQuestsList = {}
if data.Goals then
    for slot, goalData in pairs(data.Goals) do
        if type(goalData) == "table" then
            local stars = goalData.Stars or goalData.S or 0
            activeQuestsStarsSum = activeQuestsStarsSum + stars
            table.insert(activeQuestsList, {
                Slot = slot,
                GoalID = goalData.ID,
                Progress = goalData.Progress or 0,
                Target = goalData.Amount or 0,
                Stars = stars
            })
        end
    end
end

local rankAnalytics = {
    CurrentRankNumber = profile.RankNumber,
    CurrentRankTitle = rankTitle,
    RankProgressString = rankProgressDisplay,
    CurrentStarsEarnedInRank = currentStarsEarnedInRank,
    TotalStarsSumForRank = totalStarsSumForRank,
    RewardsLeftCount = rewardsLeftCount,
    CurrentTierStars = currentTierProgressStars,
    TotalStarsRemainingForNextRank = totalStarsRemainingForNextRank,
    ActiveQuestsStarsAvailable = activeQuestsStarsSum,
    RemainingStarsAfterActiveQuests = math.max(0, totalStarsRemainingForNextRank - activeQuestsStarsSum),
    ActiveQuests = activeQuestsList
}

-- 6. 100% NATIVE INVENTORY WITH DYNAMIC SHINY FRUITS & TIER-BASED ITEM ICON URLS
local nativeInventory = {}

if data and data.Inventory then
    for categoryName, categoryData in pairs(data.Inventory) do
        if type(categoryData) == "table" and categoryName ~= "Pet" then
            local categoryItems = {}
            for uuid, item in pairs(categoryData) do
                if type(item) == "table" and item.id then
                    local id = item.id
                    local amount = item._am or item.Amount or 1
                    local tier = item.tn or item.Tier or 1
                    local isShiny = item.sh or item.Shiny or false
                    local iconData = GetItemIconData(id, categoryName, tier, isShiny)
                    
                    local itemEntry = {
                        UUID = uuid,
                        ID = id,
                        Tier = tier,
                        Shiny = isShiny,
                        Amount = amount,
                        Category = categoryName,
                        IconAssetId = iconData and iconData.AssetId or nil,
                        IconUrl = iconData and iconData.IconUrl or nil
                    }
                    table.insert(categoryItems, itemEntry)

                    if categoryName == "Consumable" then
                        local lowerId = string.lower(id)
                        if string.find(lowerId, "lucky") or string.find(lowerId, "breakout") then
                            table.insert(luckyBlockAnalytics.EventConsumableBoosters, itemEntry)
                        end
                    end
                end
            end
            nativeInventory[categoryName] = categoryItems
        end
    end
end

-- 7. COMPLETE PET ANALYTICS (REGULAR PETS, HUGE PETS, TITANICS, GARGANTUANS)
local ownedHugeList = {}
local ownedHugeTypes = {}
local ownedTitanicList = {}
local ownedGargantuanList = {}
local ownedRegularPetsList = {}

if data and data.Inventory and data.Inventory.Pet then
    for uuid, petData in pairs(data.Inventory.Pet) do
        local id = petData.id or "Unknown"
        local lowerId = string.lower(id)
        local typeName = petData.pt == 1 and "Golden" or (petData.pt == 2 and "Rainbow" or "Normal")
        local isShiny = petData.sh and true or false
        local amount = petData._am or petData.Amount or 1
        local petIconUrl = GetPetIconUrl(id)
        
        local petEntry = {
            UUID = uuid,
            ID = id,
            Type = typeName,
            Shiny = isShiny,
            Amount = amount,
            IconUrl = petIconUrl
        }

        if string.find(lowerId, "huge") then
            table.insert(ownedHugeList, petEntry)
            ownedHugeTypes[id] = (ownedHugeTypes[id] or 0) + 1
        elseif string.find(lowerId, "titanic") then
            table.insert(ownedTitanicList, petEntry)
        elseif string.find(lowerId, "gargantuan") then
            table.insert(ownedGargantuanList, petEntry)
        else
            table.insert(ownedRegularPetsList, petEntry)
        end
    end
end

local allHugePetsInGame = {}
local unownedHugePets = {}
local allTitanicPetsInGame = {}
local allGargantuanPetsInGame = {}

pcall(function()
    if Directory.Pets then
        for petId, _ in pairs(Directory.Pets) do
            if type(petId) == "string" then
                local lowerId = string.lower(petId)
                local petIconUrl = GetPetIconUrl(petId)
                local dbEntry = { ID = petId, IconUrl = petIconUrl }
                
                if string.find(lowerId, "huge") then
                    table.insert(allHugePetsInGame, dbEntry)
                    if not ownedHugeTypes[petId] then
                        table.insert(unownedHugePets, dbEntry)
                    end
                elseif string.find(lowerId, "titanic") then
                    table.insert(allTitanicPetsInGame, dbEntry)
                elseif string.find(lowerId, "gargantuan") then
                    table.insert(allGargantuanPetsInGame, dbEntry)
                end
            end
        end
    end
end)

local uniqueOwnedCount = 0
for _ in pairs(ownedHugeTypes) do
    uniqueOwnedCount = uniqueOwnedCount + 1
end

-- 8. Complete TrackStat Dump Object
local trackstatPayload = {
    Timestamp = os.time(),
    
    -- TOP-LEVEL DIRECT PROPERTIES FOR WEB UI PARSERS:
    MaxZone = maxUnlockedZoneNum,                   -- 279
    Zone = maxUnlockedZoneNum,                      -- 279
    MaxZoneNumber = maxUnlockedZoneNum,             -- 279
    MaxZoneName = maxUnlockedZoneName,               -- "Hollow Veil Castle"
    EquippedPets = totalEquippedPetsCount,          -- 75
    EquippedPetsCount = totalEquippedPetsCount,     -- 75
    PetEquip = totalEquippedPetsCount,              -- 75
    MaxPetsEquipped = maxPetsEquippedSlots,         -- 75
    Rank = profile.RankNumber,                      -- 17
    Diamonds = profile.Diamonds,                    -- 14143212
    
    -- STRUCTURED SUB-OBJECTS:
    Profile = profile,
    Slots = slotsInfo,
    EquippedPetsSummary = equippedPetsSummary,      -- 75/75 Pets Equipped!
    ZoneAnalytics = zoneAnalytics,                  -- Zone 279 (#279 Hollow Veil Castle)
    RankAnalytics = rankAnalytics,                  -- Rank 17 (446/566)
    LuckyBlockEvent = luckyBlockAnalytics,
    Inventory = nativeInventory,
    Mastery = data.Mastery or {},
    RegularPetSummary = {
        TotalRegularPetsOwnedCount = #ownedRegularPetsList,
        OwnedRegularPetsList = ownedRegularPetsList
    },
    HugePetSummary = {
        TotalHugePetsOwnedCount = #ownedHugeList,
        UniqueHugeTypesOwnedCount = uniqueOwnedCount,
        TotalHugeTypesInGame = #allHugePetsInGame,
        UnownedHugeTypesCount = #unownedHugePets,
        OwnedHugeList = ownedHugeList,
        UnownedHugeList = unownedHugePets
    },
    TitanicPetSummary = {
        TotalTitanicsOwnedCount = #ownedTitanicList,
        TotalTitanicTypesInGame = #allTitanicPetsInGame,
        OwnedTitanicList = ownedTitanicList,
        AllTitanicsInGame = allTitanicPetsInGame
    },
    GargantuanPetSummary = {
        TotalGargantuansOwnedCount = #ownedGargantuanList,
        TotalGargantuanTypesInGame = #allGargantuanPetsInGame,
        OwnedGargantuanList = ownedGargantuanList,
        AllGargantuansInGame = allGargantuanPetsInGame
    }
}

-- Print Summary Console Output
print("==================================================")
print("[TrackStat] Complete Pet & Shiny Fruit Analytics Exported for " .. profile.Username)
print("• Shiny Fruits: Dynamic Shiny Fruit Icon URLs enabled!")
print("• Regular Pets Owned: " .. tostring(#ownedRegularPetsList) .. " Types/Entries")
print("• Huge Pets Owned: " .. tostring(#ownedHugeList) .. " Pets (" .. tostring(uniqueOwnedCount) .. " Types)")
print("• Equipped Pets: " .. tostring(totalEquippedPetsCount) .. " / " .. tostring(maxPetsEquippedSlots) .. " Pets Equipped")
print("==================================================")

return trackstatPayload
