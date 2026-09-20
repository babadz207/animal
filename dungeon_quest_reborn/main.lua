--[[
    ========================================================================
    DUNGEON QUEST REBORN - ULTIMATE SMART KAITUN / AUTO-FARM SCRIPT
    ========================================================================
    Author: babadz207
    Repository: https://github.com/babadz207/animal
    Supported: Delta, Fluxus, Synapse Z, Solara, Wave, Mobile, Emulator
    Features:
      1. Auto Enter Game & Skip Tutorial
      2. Auto Dungeon Progression (Highest level-eligible dungeon)
      3. Smart Boss Evade & Safe Altitude Hover (100% Anti-Cheat Safe)
      4. Smart Combat & AoE / Single-Target Skill Rotation
      5. Auto Stat Points Allocation (Smart Build: Mage / Warrior / Hybrid)
      6. Auto Equip Best Weapon, Armor & Abilities
      7. Smart Auto Sell (Trash filter, Strict Legendary / Mythical Protection)
      8. Auto Replay & Auto Loot Claiming 24/7
      9. Anti-AFK & Cross-Teleport Auto-Reconnection
    ========================================================================
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

--------------------------------------------------------------------------------
-- SESSION MANAGER (TỰ ĐỘNG DỪNG CÁC PHIÊN CŨ ĐANG CHẠY NGẦM)
--------------------------------------------------------------------------------
if getgenv and getgenv()._DQKaitunSession then
    getgenv()._DQKaitunSession = nil -- Ra tín hiệu dừng mọi vòng lặp cũ
    task.wait(0.4)
end

local CurrentSession = tick()
if getgenv then
    getgenv()._DQKaitunSession = CurrentSession
end

-- Xóa sạch giao diện cũ nếu có trên màn hình
pcall(function()
    local oldGui = PlayerGui:FindFirstChild("KaitunDashboard")
    if oldGui then oldGui:Destroy() end
    local coreGui = game:GetService("CoreGui"):FindFirstChild("KaitunDashboard")
    if coreGui then coreGui:Destroy() end
end)

--------------------------------------------------------------------------------
-- 0. AUTO-EXECUTE & PERSISTENCE ACROSS ALL MAPS / PLACE IDS
--------------------------------------------------------------------------------
local qot = queue_on_teleport or queueonteleport 
    or (syn and syn.queue_on_teleport) 
    or (fluxus and fluxus.queue_on_teleport)
    or (getgenv and getgenv().queue_on_teleport)

local TeleportScript = [[
    repeat task.wait() until game:IsLoaded()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/babadz207/animal/main/dungeon_quest_kaitun.lua?t=" .. tostring(tick())))()
]]

local function QueueReconnect()
    if qot then
        pcall(function()
            qot(TeleportScript)
        end)
    end
end

-- Kích hoạt queue ngay khi khởi động
QueueReconnect()

-- Lắng nghe sự kiện chuyển map của Roblox
pcall(function()
    LocalPlayer.OnTeleport:Connect(function(teleportState)
        QueueReconnect()
    end)
end)

-- Tự ghi vào thư mục autoexec của executor nếu có hỗ trợ
pcall(function()
    if writefile then
        local possibleFolders = {"autoexec", "scripts/autoexec", "Delta/autoexec", "Fluxus/autoexec"}
        for _, folder in ipairs(possibleFolders) do
            if isfolder and isfolder(folder) then
                writefile(folder .. "/dungeon_quest_kaitun.lua", TeleportScript)
                print("[DungeonQuest] Auto-execute file written to: " .. folder)
                break
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 1. CONFIGURATION
--------------------------------------------------------------------------------
local Config = {
    -- Game Flow
    AutoEnterGame = true,         -- Tự động bấm Play & Bỏ qua hướng dẫn
    AutoProgressionDungeon = true,-- Tự động chọn Dungeon cao nhất theo Level
    FixedDungeon = "Desert Temple",-- Dùng khi AutoProgressionDungeon = false
    Difficulty = "Easy",          -- "Easy", "Medium", "Hard", "Insane", "Nightmare"
    HardcoreMode = false,         -- Bật nếu muốn cày thêm 20% may mắn & exp
    PrivateLobby = true,          -- Tạo phòng riêng tư không bị quấy rối
    
    -- Combat & Movement (Đi bộ tiếp cận, Đánh thường, Xả skill & Đi lùi thông minh)
    KillAura = true,              -- Tự động đánh quái & Boss
    CombatRangeMage = 18,         -- Cự ly đứng xả skill của Pháp sư (14 - 18 studs)
    CombatRangeWarrior = 9.5,     -- Cự ly đánh của Chiến binh
    KiteDistanceMage = 14,        -- Cự ly bắt đầu lùi né đòn thường của Pháp sư (quái cận chiến tầm đánh 6 studs)
    KiteDistanceWarrior = 7.5,    -- Cự ly bắt đầu lùi của Chiến binh
    AutoSpamSkills = true,        -- Tự xả chiêu thức thông minh (Q/E, Backpack, Swap set)
    BossEvadeDistance = 20,       -- Khoảng cách né an toàn khi Boss tung vòng đỏ
    
    -- Stats & Progression
    AutoStats = true,             -- Tự nâng điểm thuộc tính khi lên cấp
    StatBuild = "Auto",           -- "Auto" (theo đồ đang dùng), "Mage", "Warrior", "Tank"
    
    -- Inventory & Economy
    AutoEquipBest = true,         -- Tự trang bị vũ khí, giáp và kỹ năng mạnh nhất
    AutoSell = false,             -- MẶC ĐỊNH TẮT: Bảo vệ 100% kho đồ tân thủ, không tự ý bán đồ đầu game!
    MinLevelToSell = 25,          -- Chỉ tự động bán đồ khi đạt từ Level 25 trở lên
    SellRarities = {              -- Chỉ bán các phẩm cấp thấp khi đã đủ điều kiện Level
        ["Common"] = true,
        ["Uncommon"] = false,     -- Giữ lại Uncommon cho người chơi mới
        ["Rare"] = false,         -- Giữ lại Rare trở lên
        ["Epic"] = false,         -- Giữ lại Epic trở lên
        ["Legendary"] = false,    -- Tuyệt đối không bán
        ["Mythical"] = false,     -- Tuyệt đối không bán
    },
    
    -- Replay
    AutoReplay = true,            -- Tự chơi lại trận đấu khi hoàn thành
}

--------------------------------------------------------------------------------
-- 2. DUNGEON LEVEL PROGRESSION TABLE
--------------------------------------------------------------------------------
local DUNGEON_TIERS = {
    { Name = "Gilded Skies",       MinLevel = 190 },
    { Name = "Oni Dungeon",        MinLevel = 175 },
    { Name = "Northern Lands",     MinLevel = 160 },
    { Name = "Enchanted Forest",   MinLevel = 145 },
    { Name = "Aquatic Temple",     MinLevel = 130 },
    { Name = "Volcanic Chambers",  MinLevel = 115 },
    { Name = "Orbital Outpost",    MinLevel = 100 },
    { Name = "Steampunk Sewers",   MinLevel = 85 },
    { Name = "The Canals",         MinLevel = 70 },
    { Name = "Samurai Palace",     MinLevel = 55 },
    { Name = "The Underworld",     MinLevel = 40 },
    { Name = "King's Castle",      MinLevel = 30 },
    { Name = "Pirate Island",      MinLevel = 20 },
    { Name = "Winter Outpost",     MinLevel = 10 },
    { Name = "Desert Temple",      MinLevel = 1 },
}

local function GetBestDungeonForLevel(level)
    level = tonumber(level) or 1
    for _, d in ipairs(DUNGEON_TIERS) do
        if level >= d.MinLevel then
            return d.Name
        end
    end
    return "Desert Temple"
end

--------------------------------------------------------------------------------
-- 3. STATE TRACKING
--------------------------------------------------------------------------------
local State = {
    CurrentStatus = "Khởi động...",
    DungeonTarget = "Desert Temple",
    CurrentWave = 0,
    EnemiesRemaining = 0,
    TotalDungeonsCompleted = 0,
    AllocatedPoints = 0,
    SoldItemsCount = 0,
    StartTime = os.time(),
    EquippedBeforeJoin = false,
}

--------------------------------------------------------------------------------
-- 4. UTILITIES
--------------------------------------------------------------------------------
local function ClickButton(btn)
    if not btn or not btn:IsA("GuiButton") then return false end
    local clicked = false

    -- 1. getconnections (Kích hoạt chính xác function lắng nghe Activated, MouseButton1Down/Up/Click mà KHÔNG can thiệp chuột thật)
    if getconnections then
        for _, evt in ipairs({"Activated", "MouseButton1Down", "MouseButton1Up", "MouseButton1Click"}) do
            local conns = getconnections(btn[evt])
            if conns and #conns > 0 then
                for _, conn in ipairs(conns) do
                    if conn.Enabled then
                        pcall(function() conn:Fire() end)
                        clicked = true
                    end
                end
            end
        end
    end

    -- 2. firesignal nếu có hỗ trợ
    if typeof(firesignal) == "function" then
        for _, sig in ipairs({"Activated", "MouseButton1Down", "MouseButton1Up", "MouseButton1Click"}) do
            pcall(function()
                firesignal(btn[sig])
                clicked = true
            end)
        end
    end

    return clicked
end

local function GetPlayButton()
    -- 1. Thử đường dẫn mặc định của Dungeon Quest
    local mainInterface = PlayerGui:FindFirstChild("mainInterface")
    if mainInterface then
        local btn = mainInterface:FindFirstChild("playButton", true)
        if btn and btn:IsA("GuiButton") and btn.Visible then return btn end
    end

    -- 2. Quét mọi ScreenGui tìm nút Play
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "KaitunDashboard" then
            for _, desc in pairs(gui:GetDescendants()) do
                if desc:IsA("GuiButton") and desc.Visible then
                    local name = desc.Name:lower()
                    if name == "playbutton" or name == "play" then
                        return desc
                    end
                    if desc:IsA("TextButton") and desc.Text:lower():find("play") then
                        return desc
                    end
                    local txt = desc:FindFirstChildOfClass("TextLabel")
                    if txt and txt.Text:lower():find("play") then
                        return desc
                    end
                end
            end
        end
    end
    return nil
end

local function IsInLobby()
    return workspace:FindFirstChild("Lobby") ~= nil
end

local function IsInDungeon()
    return not IsInLobby()
end

local function GetRootPart()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetPlayerLevel()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local lvl = ls and ls:FindFirstChild("Level")
    return lvl and lvl.Value or 1
end

--------------------------------------------------------------------------------
-- 5. AUTO ENTER GAME & TUTORIAL
--------------------------------------------------------------------------------
local function ProcessAutoEnter()
    if not Config.AutoEnterGame then return end

    -- Nút Play ở màn hình Intro
    local intro = PlayerGui:FindFirstChild("introGui")
    if intro and intro.Enabled then
        local playBtn = intro:FindFirstChild("title") 
            and intro.title:FindFirstChild("Frame") 
            and intro.title.Frame:FindFirstChild("TextButton")
        if playBtn and playBtn.Visible then
            State.CurrentStatus = "Bấm nút Play vào game..."
            ClickButton(playBtn)
            task.wait(0.5)
        end
    end

    -- Bỏ qua màn hình hướng dẫn Tutorial
    local tut = PlayerGui:FindFirstChild("tutorialConfirm")
    if tut and tut.Enabled then
        local skipBtn = tut:FindFirstChild("Frame")
            and tut.Frame:FindFirstChild("Frame")
            and tut.Frame.Frame:FindFirstChild("no")
            and tut.Frame.Frame.no:FindFirstChild("TextButton")
        if skipBtn then
            State.CurrentStatus = "Bỏ qua màn Tutorial..."
            ClickButton(skipBtn)
            task.wait(0.5)
        end
    end
end

--------------------------------------------------------------------------------
-- 6. SMART AUTO STAT ALLOCATION (NÂNG ĐIỂM THÔNG MINH QUA REMOTE)
--------------------------------------------------------------------------------
local function ProcessAutoStats()
    if not Config.AutoStats then return end

    local spVal = LocalPlayer:FindFirstChild("skillPoints")
    if not spVal or spVal.Value <= 0 then return end

    local currentPoints = spVal.Value
    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    local spendRemote = remotes and remotes:FindFirstChild("spendSkillPoint")
    if not spendRemote then return end

    -- Phân loại Build
    local build = Config.StatBuild
    if build == "Auto" then
        local sp = LocalPlayer:FindFirstChild("spellPower") and LocalPlayer.spellPower.Value or 0
        local pp = LocalPlayer:FindFirstChild("physicalPower") and LocalPlayer.physicalPower.Value or 0
        if sp >= pp then
            build = "Mage"
        else
            build = "Warrior"
        end
    end

    -- Phân bổ điểm: 75% chỉ số chính, 25% Stamina (HP)
    local mainStat = (build == "Mage") and "spellPower" or "physicalPower"
    local mainPoints = math.max(1, math.floor(currentPoints * 0.75))
    local stamPoints = currentPoints - mainPoints

    State.CurrentStatus = string.format("Nâng %d điểm (%s: +%d, Stamina: +%d)...", currentPoints, mainStat, mainPoints, stamPoints)

    -- Remote spendSkillPoint chính xác 100% của Dungeon Quest
    pcall(function()
        if mainPoints > 0 then spendRemote:FireServer(mainStat, mainPoints) end
        if stamPoints > 0 then spendRemote:FireServer("stamina", stamPoints) end
    end)

    State.AllocatedPoints = State.AllocatedPoints + currentPoints
end

--------------------------------------------------------------------------------
-- 7. SMART AUTO EQUIP BEST (VŨ KHÍ, GIÁP, CHIÊU THỨC QUA GAME REMOTE 100%)
--------------------------------------------------------------------------------
local RARITY_SCORE = {
    ["common"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 3,
    ["epic"] = 4,
    ["legendary"] = 5,
    ["mythical"] = 6,
    ["ultimate"] = 7,
}

local lastAttackTime = 0
local function EnsureWeaponEquipped()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and not tool:FindFirstChild("localEvent") then
        return tool
    end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and not item:FindFirstChild("localEvent") then
                local hum = GetHumanoid()
                if hum then
                    hum:EquipTool(item)
                    return item
                end
            end
        end
    end
    return tool
end

local function AttackWithWeapon(targetPos)
    local now = os.clock()
    if now - lastAttackTime < 0.16 then return end
    lastAttackTime = now

    local tool = EnsureWeaponEquipped()
    if tool then
        pcall(function() tool:Activate() end)
    end

    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    if remotes and remotes:FindFirstChild("weaponUsed") then
        pcall(function()
            remotes.weaponUsed:FireServer(targetPos)
        end)
    end
end

local lastEquipCheck = 0
local function ProcessAutoEquip()
    if not Config.AutoEquipBest then return end
    if os.clock() - lastEquipCheck < 2.0 then return end
    lastEquipCheck = os.clock()

    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    local reloadRemote = remotes and remotes:FindFirstChild("reloadInvy")
    local equipRemote = remotes and remotes:FindFirstChild("equipItem")
    if not reloadRemote or not equipRemote then return end

    local invData = nil
    pcall(function()
        invData = reloadRemote:InvokeServer()
    end)
    if type(invData) ~= "table" then return end

    local playerLvl = GetPlayerLevel()
    local sp = LocalPlayer:FindFirstChild("spellPower") and LocalPlayer.spellPower.Value or 0
    local pp = LocalPlayer:FindFirstChild("physicalPower") and LocalPlayer.physicalPower.Value or 0
    local isMage = (sp >= pp)

    -- A. TỰ ĐỘNG TRANG BỊ VŨ KHÍ MẠNH NHẤT
    if invData.weapons then
        local bestWeaponNum = nil
        local bestScore = -1
        local bestIsEquipped = false
        local bestName = ""

        for key, item in pairs(invData.weapons) do
            if type(item) == "table" and (tonumber(item.levelReq) or 1) <= playerLvl then
                local num = tonumber(item.uniqueItemNum) or tonumber(key:match("%d+"))
                local rScore = RARITY_SCORE[(tostring(item.rarity or "common")):lower()] or 1
                local damage = isMage and (tonumber(item.spellPower) or 0) or (tonumber(item.physicalDamage) or 0)
                local score = damage * 10 + rScore * 5 + (tonumber(item.currentUpgrade) or 0)

                if score > bestScore then
                    bestScore = score
                    bestWeaponNum = num
                    bestIsEquipped = (item.equipped == true)
                    bestName = tostring(item.name or "Weapon")
                end
            end
        end

        local currentWeapon = LocalPlayer:FindFirstChild("weaponEquipped") and LocalPlayer.weaponEquipped.Value or ""
        if bestWeaponNum and (not bestIsEquipped or currentWeapon ~= bestName) then
            State.CurrentStatus = "Trang bị vũ khí tốt nhất: " .. bestName
            pcall(function()
                equipRemote:InvokeServer("weapon", bestWeaponNum)
            end)
            task.wait(0.2)
        end
    end

    -- B. TỰ ĐỘNG TRANG BỊ NÓN (HELMET) MẠNH NHẤT
    if invData.helmets then
        local bestHelmetNum = nil
        local bestScore = -1
        local bestIsEquipped = false
        local bestName = ""

        for key, item in pairs(invData.helmets) do
            if type(item) == "table" and (tonumber(item.levelReq) or 1) <= playerLvl then
                local num = tonumber(item.uniqueItemNum) or tonumber(key:match("%d+"))
                local rScore = RARITY_SCORE[(tostring(item.rarity or "common")):lower()] or 1
                local statPower = isMage and (tonumber(item.spellPower) or 0) or (tonumber(item.physicalPower) or 0)
                local score = (tonumber(item.health) or 0) * 2 + statPower * 5 + rScore * 5

                if score > bestScore then
                    bestScore = score
                    bestHelmetNum = num
                    bestIsEquipped = (item.equipped == true)
                    bestName = tostring(item.name or "Helmet")
                end
            end
        end

        if bestHelmetNum and not bestIsEquipped then
            pcall(function()
                equipRemote:InvokeServer("helmet", bestHelmetNum)
            end)
            task.wait(0.2)
        end
    end

    -- C. TỰ ĐỘNG TRANG BỊ GIÁP (CHEST) MẠNH NHẤT
    if invData.chests then
        local bestChestNum = nil
        local bestScore = -1
        local bestIsEquipped = false
        local bestName = ""

        for key, item in pairs(invData.chests) do
            if type(item) == "table" and (tonumber(item.levelReq) or 1) <= playerLvl then
                local num = tonumber(item.uniqueItemNum) or tonumber(key:match("%d+"))
                local rScore = RARITY_SCORE[(tostring(item.rarity or "common")):lower()] or 1
                local statPower = isMage and (tonumber(item.spellPower) or 0) or (tonumber(item.physicalPower) or 0)
                local score = (tonumber(item.health) or 0) * 2 + statPower * 5 + rScore * 5

                if score > bestScore then
                    bestScore = score
                    bestChestNum = num
                    bestIsEquipped = (item.equipped == true)
                    bestName = tostring(item.name or "Chest")
                end
            end
        end

        if bestChestNum and not bestIsEquipped then
            pcall(function()
                equipRemote:InvokeServer("chest", bestChestNum)
            end)
            task.wait(0.2)
        end
    end

    -- D. TỰ ĐỘNG TRANG BỊ KỸ NĂNG (ABILITIES) VÀO Q, E, Q2, E2
    if invData.abilities then
        local sortedAbilities = {}
        for key, item in pairs(invData.abilities) do
            if type(item) == "table" and (tonumber(item.levelReq) or 1) <= playerLvl then
                local num = tonumber(item.uniqueItemNum) or tonumber(key:match("%d+"))
                local rScore = RARITY_SCORE[(tostring(item.rarity or "common")):lower()] or 1
                local power = (tonumber(item.spellPower) or 0) + (tonumber(item.physicalDamage) or 0)
                local isHeal = IsHealingTool and IsHealingTool(item)
                local name = tostring(item.name or ""):lower()
                local isRanged = name:find("fireball") or name:find("orb") or name:find("beam") or name:find("bolt") or name:find("blast") or name:find("missile")

                -- Ưu tiên kỹ năng: Hồi máu > Phép tầm xa cho Mage > Sát thương
                local score = power * 5 + rScore * 10
                if isHeal then score = score + 2000 end
                if isRanged and isMage then score = score + 1000 end

                table.insert(sortedAbilities, {
                    num = num,
                    name = item.name,
                    score = score,
                    isRanged = isRanged,
                    isHeal = isHeal,
                    equipped = item.equipped or {},
                })
            end
        end
        table.sort(sortedAbilities, function(a, b) return a.score > b.score end)

        local slots = {"e", "q", "e2", "q2"}
        local unequipRemote = remotes and remotes:FindFirstChild("unequipItem")

        for idx, slotName in ipairs(slots) do
            local ab = sortedAbilities[idx]
            if ab and ab.num then
                local isAlreadyInSlot = false
                if type(ab.equipped) == "table" then
                    isAlreadyInSlot = (ab.equipped[slotName] == true)
                end
                if not isAlreadyInSlot then
                    -- Nếu đang ở slot khác, unequip trước để tránh bị game chặn không cho gán slot mới
                    if unequipRemote and type(ab.equipped) == "table" then
                        for s, isEq in pairs(ab.equipped) do
                            if isEq == true and s ~= slotName then
                                pcall(function() unequipRemote:InvokeServer("ability", ab.num) end)
                                task.wait(0.1)
                                break
                            end
                        end
                    end
                    pcall(function()
                        equipRemote:InvokeServer("ability", ab.num, slotName)
                    end)
                    task.wait(0.15)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 8. SMART AUTO SELL (BẢO VỆ TUYỆT ĐỐI ĐỒ ĐẦU GAME CHO NGƯỜI CHƠI)
--------------------------------------------------------------------------------
local lastSellCheck = 0
local function ProcessAutoSell()
    if not Config.AutoSell then return end
    if not IsInLobby() then return end -- Chỉ bán đồ khi ở sảnh Lobby

    -- CHỐNG MẤT ĐỒ ĐẦU GAME: Dưới cấp 25 tuyệt đối không bán bất cứ món nào!
    local playerLvl = GetPlayerLevel()
    if playerLvl < (Config.MinLevelToSell or 25) then return end

    if os.clock() - lastSellCheck < 5.0 then return end
    lastSellCheck = os.clock()

    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    local reloadRemote = remotes and remotes:FindFirstChild("reloadInvy")
    local sellRemote = remotes and remotes:FindFirstChild("sellItemEvent")
    if not reloadRemote or not sellRemote then return end

    local invData = nil
    pcall(function()
        invData = reloadRemote:InvokeServer()
    end)
    if type(invData) ~= "table" then return end

    local sellPayload = {
        weapon = {},
        helmet = {},
        chest = {},
        ability = {}
    }
    local totalToSell = 0

    local function CheckAndQueueSell(category, itemsTable, minKeepCount)
        if not itemsTable then return end
        local unequippedItems = {}
        for key, item in pairs(itemsTable) do
            if type(item) == "table" then
                local isEquipped = false
                if type(item.equipped) == "table" then
                    for _, eq in pairs(item.equipped) do
                        if eq == true then isEquipped = true break end
                    end
                elseif item.equipped == true then
                    isEquipped = true
                end

                local rarity = tostring(item.rarity or ""):lower()
                local num = tonumber(item.uniqueItemNum) or tonumber(key:match("%d+"))
                local properRarity = rarity:gsub("^%l", string.upper)

                if not isEquipped and num and Config.SellRarities[properRarity] == true then
                    table.insert(unequippedItems, num)
                end
            end
        end

        -- Chỉ bán nếu số lượng đồ dự trữ vượt quá mức an toàn minKeepCount
        if #unequippedItems > (minKeepCount or 2) then
            for i = 1, #unequippedItems - (minKeepCount or 2) do
                table.insert(sellPayload[category], unequippedItems[i])
                totalToSell = totalToSell + 1
            end
        end
    end

    -- Luôn giữ lại tối thiểu 3 vũ khí, 6 kỹ năng, 2 nón, 2 giáp trong kho
    CheckAndQueueSell("weapon", invData.weapons, 3)
    CheckAndQueueSell("helmet", invData.helmets, 2)
    CheckAndQueueSell("chest", invData.chests, 2)
    CheckAndQueueSell("ability", invData.abilities, 6)

    if totalToSell > 0 then
        State.CurrentStatus = string.format("Bán %d món đồ trùng lặp dư thừa...", totalToSell)
        pcall(function()
            sellRemote:FireServer(sellPayload)
        end)
        State.SoldItemsCount = State.SoldItemsCount + totalToSell
    end
end

--------------------------------------------------------------------------------
-- 9. AUTO QUEUE & DUNGEON PROGRESSION (CHỌN MAP CAO NHẤT)
--------------------------------------------------------------------------------
local function ProcessLobbyProgression()
    if not IsInLobby() then
        State.EquippedBeforeJoin = false
        return
    end

    -- BẮT BUỘC: Kiểm tra & trang bị đầy đủ vũ khí, áo giáp, kỹ năng mạnh nhất TRƯỚC KHI tạo phòng hoặc vào map!
    if not State.EquippedBeforeJoin then
        State.CurrentStatus = "Trang bị kỹ năng & vũ khí trước khi vào map..."
        pcall(ProcessAutoEquip)
        pcall(ProcessAutoStats)
        State.EquippedBeforeJoin = true
        task.wait(0.5)
    end

    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    local playerLvl = GetPlayerLevel()
    local targetDungeon = Config.AutoProgressionDungeon and GetBestDungeonForLevel(playerLvl) or Config.FixedDungeon
    State.DungeonTarget = targetDungeon

    -- 1. KIỂM TRA ĐÃ CÓ PHÒNG CHƯA (Workspace.games.inLobby[Player.Name])
    local gamesFolder = workspace:FindFirstChild("games")
    local inLobbyFolder = gamesFolder and gamesFolder:FindFirstChild("inLobby")
    local myLobby = inLobbyFolder and inLobbyFolder:FindFirstChild(LocalPlayer.Name)

    if myLobby then
        State.CurrentStatus = "Đã có phòng! Xuất phát vào: " .. targetDungeon .. "..."
        QueueReconnect()

        -- Kích hoạt remote bắt đầu trận
        if remotes and remotes:FindFirstChild("startDungeon") then
            pcall(function() remotes.startDungeon:FireServer() end)
        end

        -- Click nút Start trên giao diện lobbyInfo nếu có
        local queueGui = PlayerGui:FindFirstChild("queueGui")
        local startBtn = queueGui and queueGui:FindFirstChild("lobbyInfo", true) 
            and queueGui.lobbyInfo:FindFirstChild("startButton", true)
        if startBtn then
            ClickButton(startBtn)
        end
        task.wait(1.5)
        return
    end

    -- 2. NẾU CHƯA CÓ PHÒNG: KIỂM TRA MENU queueGui
    local queueGui = PlayerGui:FindFirstChild("queueGui")
    local mainInterface = PlayerGui:FindFirstChild("mainInterface")

    local isQueueOpen = false
    if queueGui and queueGui.Enabled then
        local selOpt = queueGui:FindFirstChild("selectOption")
        local choose = queueGui:FindFirstChild("chooseDungeon")
        local lInfo = queueGui:FindFirstChild("lobbyInfo")
        if (selOpt and selOpt.Visible) or (choose and choose.Visible) or (lInfo and lInfo.Visible) then
            isQueueOpen = true
        end
    end

    -- Nếu chưa mở menu phòng: Bấm nút playButton trên mainInterface
    if not isQueueOpen then
        local playBtn = mainInterface and mainInterface:FindFirstChild("buttons") and mainInterface.buttons:FindFirstChild("playButton")
        if not playBtn then
            playBtn = GetPlayButton()
        end
        if playBtn then
            State.CurrentStatus = "Mở menu Dungeon..."
            ClickButton(playBtn)
            task.wait(0.6)
            return
        end
    end

    -- Khi menu queueGui đã mở:
    if queueGui then
        -- A. Màn hình chọn Create Game:
        local selectOption = queueGui:FindFirstChild("selectOption")
        if selectOption and selectOption.Visible then
            local createBtn = selectOption:FindFirstChild("createGame", true)
            if createBtn then
                State.CurrentStatus = "Bấm Create Game..."
                ClickButton(createBtn)
                task.wait(0.6)
                return
            end
        end

        -- B. Màn hình chọn Dungeon & Độ khó (chooseDungeon):
        local choose = queueGui:FindFirstChild("chooseDungeon")
        if choose and choose.Visible then
            State.CurrentStatus = string.format("Tạo phòng: %s (%s)", targetDungeon, Config.Difficulty)

            -- Chọn Dungeon
            local scroll = choose:FindFirstChild("ScrollingFrame", true)
            local dungBtn = scroll and scroll:FindFirstChild(targetDungeon) and scroll[targetDungeon]:FindFirstChild("TextButton")
            if dungBtn then
                ClickButton(dungBtn)
                task.wait(0.15)
            end

            -- Chọn Độ khó
            local right = choose:FindFirstChild("backgroundFillRight")
            local diffBtn = right and right:FindFirstChild(Config.Difficulty) and right[Config.Difficulty]:FindFirstChild("TextButton")
            if diffBtn then
                ClickButton(diffBtn)
                task.wait(0.15)
            end

            -- Bật phòng Private nếu cấu hình
            if Config.PrivateLobby then
                local privBtn = choose:FindFirstChild("private", true) and choose.private:FindFirstChild("button", true)
                if privBtn then
                    ClickButton(privBtn)
                    task.wait(0.1)
                end
            end

            -- Bấm Create Lobby trên giao diện
            local startMain = choose:FindFirstChild("startMain", true) and choose.startMain:FindFirstChild("TextButton", true)
            if startMain then
                ClickButton(startMain)
            end

            -- Đồng thời gọi Remote createLobby trực tiếp để đảm bảo 100%
            if remotes and remotes:FindFirstChild("createLobby") then
                pcall(function()
                    remotes.createLobby:InvokeServer(targetDungeon, Config.Difficulty, false, 0, Config.PrivateLobby)
                end)
            end

            task.wait(0.8)
            return
        end

        -- C. Màn hình phòng chờ (lobbyInfo):
        local lobbyInfo = queueGui:FindFirstChild("lobbyInfo")
        if lobbyInfo and lobbyInfo.Visible then
            local startBtn = lobbyInfo:FindFirstChild("startButton", true)
            if startBtn then
                State.CurrentStatus = "Bắt đầu vào trận: " .. targetDungeon .. "..."
                QueueReconnect()
                ClickButton(startBtn)
                if remotes and remotes:FindFirstChild("startDungeon") then
                    pcall(function() remotes.startDungeon:FireServer() end)
                end
                task.wait(1.5)
                return
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 10. SMART COMBAT & BOSS TELEGRAPH EVASION
--------------------------------------------------------------------------------
local function IsDangerousAoE(part, rootPos)
    if not part or not part:IsA("BasePart") then return false end
    local name = part.Name:lower()
    
    -- Kiểm tra tên báo hiệu đòn đánh của Boss
    local isDangerName = name:find("hitbox") or name:find("telegraph") or name:find("redzone") or name:find("indicator") or name:find("slam") or name:find("warning")
    
    -- Kiểm tra màu đỏ cảnh báo của vòng sát thương
    local isRed = (part.Color.R > 0.7 and part.Color.G < 0.3 and part.Color.B < 0.3)
    
    if (isDangerName or isRed) and (part.Position - rootPos).Magnitude < 25 then
        return true
    end
    return false
end

-- Nhận diện kỹ năng Hồi Máu / Hộ thuẫn
local HEAL_KEYWORDS = {"heal", "rejuvenat", "aura of life", "redemption", "inner sanctum", "holy circle", "holy barrier", "splash", "life pulse"}
local function IsHealingTool(tool)
    if not tool then return false end
    local name = ""
    if typeof(tool) == "Instance" then
        name = tool.Name:lower()
    elseif type(tool) == "table" then
        name = tostring(tool.name or tool.Name or ""):lower()
    else
        name = tostring(tool):lower()
    end
    for _, kw in ipairs(HEAL_KEYWORDS) do
        if name:find(kw) then return true end
    end
    return false
end

-- Nhận diện quái đánh xa (Ranged / Archer / Mage)
local function IsRangedEnemy(mob)
    if not mob then return false end
    local name = mob.Name:lower()
    return name:find("archer") or name:find("mage") or name:find("wizard") or name:find("ranged") or name:find("caster") or name:find("skeleton") or name:find("shooter")
end

-- Tự động đổi giữa 2 Bộ Skill (Dual Skill Set Swap)
local PathfindingService = game:GetService("PathfindingService")
local lastSwapTime = 0

local function SwapAbilitySet()
    if os.clock() - lastSwapTime < 0.6 then return false end
    lastSwapTime = os.clock()

    local abilitiesGui = PlayerGui:FindFirstChild("abilities")
    local swapBtn = abilitiesGui and abilitiesGui:FindFirstChild("Swap", true)
    if swapBtn and swapBtn:IsA("GuiButton") then
        ClickButton(swapBtn)
        return true
    end

    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    if remotes and remotes:FindFirstChild("abilitySetSwapped") then
        pcall(function() remotes.abilitySetSwapped:FireServer() end)
        return true
    end
    return false
end

local function IsOnCooldown(btnContainer)
    if not btnContainer then return false end
    local cd = btnContainer:FindFirstChild("cooldownNumber", true)
    if cd and cd.Visible and cd.Text ~= "" then
        local num = tonumber(cd.Text:match("[%d%.]+"))
        if num and num > 0.1 then return true end
    end
    return false
end

local function AreCurrentSkillsOnCooldown()
    local abilitiesGui = PlayerGui:FindFirstChild("abilities")
    if not abilitiesGui then return false end

    local leftBtn = abilitiesGui:FindFirstChild("LeftAbility", true)
    local rightBtn = abilitiesGui:FindFirstChild("RightAbility", true)

    return IsOnCooldown(leftBtn) and IsOnCooldown(rightBtn)
end

--------------------------------------------------------------------------------
-- 9. DYNAMIC SKILL & WEAPON RANGE SYSTEM (TÍNH CỰ LI CỦA TỪNG CHIÊU)
--------------------------------------------------------------------------------

local SKILL_RANGE_PROFILES = {
    MeleeAoE = {
        name = "Cận chiến diện rộng (Xoay 360°)",
        minSafe = 6.8,       -- Quái đánh thường tới ~5.2 studs. Ở 6.8 studs quái đánh hụt 100%.
        maxCast = 8.8,       -- Tầm xoay Whirlwind ~9.0 studs. Ở 8.8 studs đòn xoay trúng 100%.
        preferred = 7.5,     -- Cự ly vàng lý tưởng.
        emergencyDodge = 5.6,
        isRanged = false,
        isHeal = false,
    },
    MeleeStrike = {
        name = "Cận chiến chém đơn mục tiêu",
        minSafe = 6.6,
        maxCast = 8.2,
        preferred = 7.2,
        emergencyDodge = 5.5,
        isRanged = false,
        isHeal = false,
    },
    GroundSlam = {
        name = "Đập đất / Chấn động",
        minSafe = 7.5,
        maxCast = 11.5,
        preferred = 9.0,
        emergencyDodge = 5.8,
        isRanged = false,
        isHeal = false,
    },
    Ranged = {
        name = "Phép thuật / Đòn tầm xa",
        minSafe = 14.0,      -- Quái cận chiến hoàn toàn bất lực không thể tới gần.
        maxCast = 22.0,      -- Tầm bắn chuẩn xác.
        preferred = 17.0,    -- Cự ly vàng tầm xa.
        emergencyDodge = 9.5,
        isRanged = true,
        isHeal = false,
    },
    Support = {
        name = "Hồi máu / Hộ thuẫn",
        minSafe = nil,
        maxCast = 999,
        preferred = nil,
        emergencyDodge = nil,
        isRanged = false,
        isHeal = true,
    },
}

-- Phân loại và tính cự li của một kỹ năng dựa trên tên và đặc tính của nó
local function CalculateSkillRange(skillName, toolInstance)
    local name = tostring(skillName or (toolInstance and toolInstance.Name) or ""):lower()

    if toolInstance and typeof(toolInstance) == "Instance" then
        if toolInstance:FindFirstChild("fireballShootEvent") then
            return SKILL_RANGE_PROFILES.Ranged
        end
        if toolInstance:FindFirstChild("holyCircleEvent") or toolInstance:FindFirstChild("absorbEvent") then
            return SKILL_RANGE_PROFILES.Support
        end
    end

    -- 1. Hồi máu / Buff hỗ trợ (Không giới hạn cự ly tới quái)
    local healKeywords = {"heal", "rejuvenat", "aura of life", "redemption", "inner sanctum", "holy circle", "holy barrier", "innervate", "blessing", "roar", "taunt", "berserk", "life pulse", "splash"}
    for _, kw in ipairs(healKeywords) do
        if name:find(kw) then
            return SKILL_RANGE_PROFILES.Support
        end
    end

    -- 2. Cận chiến xoay 360 độ (Whirlwind, Blade Storm, Revolver, Cyclone...)
    local meleeAoeKeywords = {"whirlwind", "blade storm", "revolver", "spinning", "flame cyclone", "gale slice", "rending slice", "ghostly rampage", "spiral", "sweep"}
    for _, kw in ipairs(meleeAoeKeywords) do
        if name:find(kw) then
            return SKILL_RANGE_PROFILES.MeleeAoE
        end
    end

    -- 3. Đập đất / Chấn động trung bình (Ground Slam, Stomp, Earth Kick, Nova...)
    local groundKeywords = {"slam", "stomp", "smash", "earth kick", "earth clap", "ice nova", "electric field", "electric boom", "totem", "burst", "quake", "tremor"}
    for _, kw in ipairs(groundKeywords) do
        if name:find(kw) then
            return SKILL_RANGE_PROFILES.GroundSlam
        end
    end

    -- 4. Kỹ năng tầm xa / Bắn chưởng / Phóng đạn
    local rangedKeywords = {"fireball", "bolt", "blast", "beam", "ray", "spray", "needles", "missile", "arrow", "shot", "shuriken", "throw", "cannon", "bomb", "orb", "barrage", "pulse", "tsunami", "vortex", "flames", "spikes", "icicle", "shards", "cloud", "lightning", "poison"}
    for _, kw in ipairs(rangedKeywords) do
        if name:find(kw) then
            return SKILL_RANGE_PROFILES.Ranged
        end
    end

    -- 5. Chém / Đánh cận chiến đơn mục tiêu
    local strikeKeywords = {"strike", "slash", "blow", "lash", "stab", "thrust", "crush", "punch", "kick", "bite", "cleave"}
    for _, kw in ipairs(strikeKeywords) do
        if name:find(kw) then
            return SKILL_RANGE_PROFILES.MeleeStrike
        end
    end

    -- Mặc định fallback theo chỉ số hiện tại
    local sp = LocalPlayer:FindFirstChild("spellPower") and LocalPlayer.spellPower.Value or 0
    local pp = LocalPlayer:FindFirstChild("physicalPower") and LocalPlayer.physicalPower.Value or 0
    return (sp >= pp) and SKILL_RANGE_PROFILES.Ranged or SKILL_RANGE_PROFILES.MeleeAoE
end

-- Tính cự ly của Vũ khí đang cầm (Đánh thường)
local function GetEquippedWeaponRange()
    local weaponName = LocalPlayer:FindFirstChild("weaponEquipped") and LocalPlayer.weaponEquipped.Value or ""
    local name = weaponName:lower()

    local isRanged = name:find("wand") or name:find("staff") or name:find("orb") or name:find("bow") or name:find("crossbow") or name:find("gun")
    if isRanged then
        return SKILL_RANGE_PROFILES.Ranged
    else
        return SKILL_RANGE_PROFILES.MeleeStrike
    end
end

-- Xác định cự ly chiến đấu động tối ưu dựa trên từng chiêu đang trang bị & thời gian hồi chiêu
local function GetDynamicCombatProfile(currentDist)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local abilitiesGui = PlayerGui:FindFirstChild("abilities")
    local leftBtn = abilitiesGui and abilitiesGui:FindFirstChild("LeftAbility", true)
    local rightBtn = abilitiesGui and abilitiesGui:FindFirstChild("RightAbility", true)

    local qTool, eTool = nil, nil
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local slotVal = t:FindFirstChild("abilitySlot") and t.abilitySlot.Value:lower()
                if slotVal == "q" then
                    qTool = t
                elseif slotVal == "e" then
                    eTool = t
                end
            end
        end
    end

    local qName = qTool and qTool.Name or "Skill Q"
    local eName = eTool and eTool.Name or "Skill E"

    local qRange = CalculateSkillRange(qName, qTool)
    local eRange = CalculateSkillRange(eName, eTool)
    local weaponRange = GetEquippedWeaponRange()

    local qCooldown = IsOnCooldown(leftBtn) or (qTool and qTool:FindFirstChild("cooldown") and qTool.cooldown.Value > 0.1)
    local eCooldown = IsOnCooldown(rightBtn) or (eTool and eTool:FindFirstChild("cooldown") and eTool.cooldown.Value > 0.1)

    -- Thu thập danh sách chiêu thức sát thương ĐANG SẴN SÀNG (không bị hồi chiêu)
    local readyDamagingSkills = {}
    if not qCooldown and not qRange.isHeal then
        table.insert(readyDamagingSkills, {name = qName, profile = qRange, slot = "Q", tool = qTool})
    end
    if not eCooldown and not eRange.isHeal then
        table.insert(readyDamagingSkills, {name = eName, profile = eRange, slot = "E", tool = eTool})
    end

    -- Chọn profile chiến đấu phù hợp nhất:
    local chosenProfile = nil
    local activeSkillInfo = ""

    if #readyDamagingSkills == 0 then
        -- CẢ 2 CHIÊU ĐỀU ĐANG HỒI (hoặc chỉ có chiêu Hồi máu):
        -- Dùng cự ly của Vũ khí đánh thường (Wand bắn xa 17m hoặc Kiếm chém 7.2m)
        chosenProfile = weaponRange
        activeSkillInfo = string.format("Vũ khí [%s]", chosenProfile.isRanged and "Tầm xa" or "Cận chiến")
    else
        -- CÓ CHIÊU SẴN SÀNG:
        local hasMeleeReady = nil
        local hasRangedReady = nil

        for _, item in ipairs(readyDamagingSkills) do
            if item.profile.isRanged then
                hasRangedReady = item
            else
                hasMeleeReady = item
            end
        end

        if hasRangedReady and (not hasMeleeReady or (currentDist and currentDist > 12)) then
            chosenProfile = hasRangedReady.profile
            activeSkillInfo = string.format("%s (Chiêu %s - Tầm xa: %dm)", hasRangedReady.name, hasRangedReady.slot, math.floor(chosenProfile.preferred))
        elseif hasMeleeReady then
            chosenProfile = hasMeleeReady.profile
            activeSkillInfo = string.format("%s (Chiêu %s - Cận chiến: %.1fm)", hasMeleeReady.name, hasMeleeReady.slot, chosenProfile.preferred)
        else
            chosenProfile = readyDamagingSkills[1].profile
            activeSkillInfo = string.format("%s (Chiêu %s)", readyDamagingSkills[1].name, readyDamagingSkills[1].slot)
        end
    end

    return chosenProfile, activeSkillInfo, {
        q = {name = qName, onCd = qCooldown, range = qRange},
        e = {name = eName, onCd = eCooldown, range = eRange},
    }
end

-- Kiểm tra Tầm nhìn thẳng (Line of Sight Raycast)
local function HasLineOfSight(fromPos, toPos, ignoreList)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = ignoreList or {}
    
    local dir = toPos - fromPos
    local result = workspace:Raycast(fromPos, dir, rayParams)
    return result == nil
end

-- Kiểm tra vật cản (tường, cột) theo một hướng để né khi đi lùi
local function CheckDirectionClear(fromPos, dir, distance)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {LocalPlayer.Character}
    local ef = workspace:FindFirstChild("enemyFolder") or (workspace:FindFirstChild("dungeon") and workspace.dungeon:FindFirstChild("enemyFolder", true))
    if ef then table.insert(ignore, ef) end
    rayParams.FilterDescendantsInstances = ignore

    local result = workspace:Raycast(fromPos, dir * distance, rayParams)
    local hitDist = result and result.Distance or distance
    return (result == nil), hitDist
end

-- Tìm vòng đỏ / telegraph đòn đánh của Boss trong khu vực
local function FindNearbyBossHazard(rootPos, maxDist)
    local dung = workspace:FindFirstChild("dungeon")
    if not dung then return nil end

    for _, desc in ipairs(dung:GetDescendants()) do
        if desc:IsA("BasePart") and IsDangerousAoE(desc, rootPos) then
            local dist = (desc.Position - rootPos).Magnitude
            if dist < maxDist then
                return desc
            end
        end
    end
    return nil
end

-- Tính đường đi 3D NavMesh luồn lách qua hành lang khi bị tường che khuất (có caching chống giật lag)
local cachedPathWaypoints = nil
local cachedPathTarget = nil
local lastPathTime = 0
local currentWaypointIndex = 1

local function GetDungeonWaypoints(startPos, endPos)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2.5,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4,
    })
    
    local ok = pcall(function()
        path:ComputeAsync(startPos, endPos)
    end)
    
    if ok and path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    end
    return nil
end

local function FollowWaypoints(targetPos)
    local root = GetRootPart()
    local hum = GetHumanoid()
    if not root or not hum then return end

    local now = os.clock()
    local needCompute = (not cachedPathWaypoints)
        or (now - lastPathTime > 1.2)
        or (cachedPathTarget and (targetPos - cachedPathTarget).Magnitude > 12)
        or (currentWaypointIndex > #cachedPathWaypoints)

    if needCompute then
        lastPathTime = now
        cachedPathTarget = targetPos
        cachedPathWaypoints = GetDungeonWaypoints(root.Position, targetPos)
        currentWaypointIndex = 2
    end

    if cachedPathWaypoints and #cachedPathWaypoints >= currentWaypointIndex then
        local wp = cachedPathWaypoints[currentWaypointIndex]
        if wp then
            local wpDist = (Vector3.new(wp.Position.X, root.Position.Y, wp.Position.Z) - root.Position).Magnitude
            if wpDist < 3.5 then
                currentWaypointIndex = currentWaypointIndex + 1
                if cachedPathWaypoints[currentWaypointIndex] then
                    wp = cachedPathWaypoints[currentWaypointIndex]
                end
            end
            if wp then
                if wp.Action == Enum.PathWaypointAction.Jump then
                    hum.Jump = true
                end
                hum:MoveTo(wp.Position)
            end
        end
    else
        hum:MoveTo(targetPos)
    end
end

local function GetAllDungeonEnemies()
    local mobs = {}
    local dung = workspace:FindFirstChild("dungeon")
    if dung then
        for _, room in ipairs(dung:GetChildren()) do
            local ef = room:FindFirstChild("enemyFolder") or (room.Name == "enemyFolder" and room)
            if ef then
                for _, mob in ipairs(ef:GetChildren()) do
                    local hum = mob:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        table.insert(mobs, mob)
                    end
                end
            end
        end
    end

    local efLegacy = workspace:FindFirstChild("enemies") or workspace:FindFirstChild("enemyFolder")
    if efLegacy then
        for _, mob in ipairs(efLegacy:GetChildren()) do
            local hum = mob:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(mobs, mob)
            end
        end
    end

    if #mobs == 0 and dung then
        for _, desc in ipairs(dung:GetDescendants()) do
            if desc:IsA("Humanoid") and desc.Health > 0 and desc.Parent ~= LocalPlayer.Character then
                table.insert(mobs, desc.Parent)
            end
        end
    end

    return mobs
end

local lastAbilityCastTime = 0
local function CastAllAbilities(isBoss, mobCount, healthPercent, targetDist)
    if not Config.AutoSpamSkills then return end
    local now = os.clock()
    if now - lastAbilityCastTime < 0.2 then return end
    lastAbilityCastTime = now

    -- 1. Kích hoạt chiêu thức trực tiếp trong Backpack theo cự ly chuẩn xác của chiêu đó
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local rangeProfile = CalculateSkillRange(tool.Name, tool)
                local canCast = true
                if rangeProfile.isHeal then
                    canCast = (healthPercent < 0.75)
                else
                    -- Không xả chiêu khi quái ở ngoài tầm đánh (tránh đánh gió / lãng phí cooldown)
                    if targetDist and rangeProfile.maxCast and targetDist > (rangeProfile.maxCast + 2.0) then
                        canCast = false
                    end
                end

                if canCast then
                    local localEvt = tool:FindFirstChild("localEvent")
                    if localEvt and localEvt:IsA("BindableEvent") then
                        pcall(function() localEvt:Fire() end)
                    end
                end
            end
        end
    end

    -- 2. Kích hoạt kỹ năng Q và E qua GUI Button signals (100% không đụng tới chuột)
    local abilitiesGui = PlayerGui:FindFirstChild("abilities")
    local leftAbility = abilitiesGui and abilitiesGui:FindFirstChild("LeftAbility", true)
    local rightAbility = abilitiesGui and abilitiesGui:FindFirstChild("RightAbility", true)
    local leftBtn = leftAbility and leftAbility:FindFirstChildWhichIsA("GuiButton", true)
    local rightBtn = rightAbility and rightAbility:FindFirstChildWhichIsA("GuiButton", true)

    if leftBtn then ClickButton(leftBtn) end
    if rightBtn then ClickButton(rightBtn) end

    -- 3. Kích hoạt remote abilityCast
    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    if remotes and remotes:FindFirstChild("abilityCast") then
        pcall(function()
            remotes.abilityCast:FireServer(1)
            remotes.abilityCast:FireServer(2)
        end)
    end

    -- 4. Nếu cả 2 chiêu đang hồi HOẶC game báo "Can swap": Tự động đổi sang bộ kỹ năng thứ 2 để xả tiếp
    local canSwapLabel = abilitiesGui and abilitiesGui:FindFirstChild("CanSwap", true)
    local canSwapReady = canSwapLabel and canSwapLabel.Visible and canSwapLabel.Text:lower():find("swap")
    if AreCurrentSkillsOnCooldown() or canSwapReady then
        SwapAbilitySet()
    end
end

-- Chống kẹt địa hình khi đi bộ
local lastPlayerPos = nil
local lastPlayerMoveTime = 0
local strafeSign = 1
local lastStrafeSwitch = 0

local function ProcessSmartCombat()
    if not Config.KillAura then return end
    if IsInLobby() then return end

    local root = GetRootPart()
    local hum = GetHumanoid()
    local char = LocalPlayer.Character
    if not root or not hum or hum.Health <= 0 then return end

    local allMobs = GetAllDungeonEnemies()
    if #allMobs == 0 then
        hum.AutoRotate = true
        return
    end

    local healthPercent = hum.Health / hum.MaxHealth

    -- 1. ƯU TIÊN NÉ CHIÊU DIỆN RỘNG (TELEGRAPH RED ZONE) CỦA BOSS
    local bossHazard = FindNearbyBossHazard(root.Position, Config.BossEvadeDistance or 20)
    if bossHazard then
        local hazardDiff = root.Position - bossHazard.Position
        local escapeDir = Vector3.new(hazardDiff.X, 0, hazardDiff.Z)
        local escapeUnit = (escapeDir.Magnitude > 0.1) and escapeDir.Unit or Vector3.new(1, 0, 0)
        State.CurrentStatus = "⚡ Đang lướt né vòng đỏ (Telegraph) của Boss!"
        hum.AutoRotate = true
        hum:MoveTo(root.Position + escapeUnit * 8)
        return
    end

    -- 2. TÌM QUÁI VẬT MỤC TIÊU ƯU TIÊN (Quái gần nhất còn sống)
    local targetMob = nil
    local shortestDist = math.huge
    local livingMobs = #allMobs
    local isBossTarget = false

    for _, mob in ipairs(allMobs) do
        local mobHum = mob:FindFirstChildOfClass("Humanoid")
        local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
        if mobHum and mobHum.Health > 0 and mobRoot then
            local dist = (mobRoot.Position - root.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                targetMob = mob
            end
        end
    end

    State.EnemiesRemaining = livingMobs

    if not targetMob then
        hum.AutoRotate = true
        return
    end

    local mobRoot = targetMob:FindFirstChild("HumanoidRootPart") or targetMob:FindFirstChild("Torso")
    local mobHum = targetMob:FindFirstChildOfClass("Humanoid")
    if not mobRoot or not mobHum or mobHum.Health <= 0 then
        hum.AutoRotate = true
        return
    end

    local diff = root.Position - mobRoot.Position
    local dist = diff.Magnitude
    local enemyHp = math.floor(mobHum.Health)
    local enemyMaxHp = math.floor(mobHum.MaxHealth)
    isBossTarget = (mobHum.MaxHealth > 10000) or (targetMob.Name:lower():find("boss") ~= nil)

    -- 3. TÍNH TOÁN CỰ LI CHIẾN ĐẤU ĐỘNG THEO TỪNG CHIÊU THỨC & VŨ KHÍ HIỆN TẠI
    local combatProfile, activeSkillInfo, skillsDebug = GetDynamicCombatProfile(dist)
    local safeMinDist = combatProfile.minSafe or 7.0
    local safeMaxDist = combatProfile.maxCast or 9.0
    local preferredDist = combatProfile.preferred or 7.5
    local emergencyDodgeDist = combatProfile.emergencyDodge or 5.6

    -- Khi máu thấp (< 40%): Lùi thêm 4 studs an toàn để hồi phục
    if healthPercent < 0.4 then
        safeMinDist = safeMinDist + 4
        safeMaxDist = safeMaxDist + 4
        preferredDist = preferredDist + 4
    end

    -- Hướng lùi ra xa quái vật (trên mặt phẳng ngang X-Z)
    local horizontalDiff = Vector3.new(diff.X, 0, diff.Z)
    local awayDir = (horizontalDiff.Magnitude > 0.1) and horizontalDiff.Unit or Vector3.new(0, 0, 1)
    local leftDir = Vector3.new(-awayDir.Z, 0, awayDir.X).Unit
    local rightDir = -leftDir

    -- Đảo hướng strafe mỗi 2.5 giây để di chuyển tự nhiên và linh hoạt
    local now = os.clock()
    if now - lastStrafeSwitch > 2.5 then
        strafeSign = -strafeSign
        lastStrafeSwitch = now
    end

    -- Luôn xoay nhân vật nhìn thẳng vào quái vật để đòn đánh & kỹ năng trúng 100%
    local lookAtPos = Vector3.new(mobRoot.Position.X, root.Position.Y, mobRoot.Position.Z)
    pcall(function()
        root.CFrame = CFrame.lookAt(root.Position, lookAtPos)
    end)

    -- Kiểm tra chống kẹt địa hình
    if not lastPlayerPos then
        lastPlayerPos = root.Position
        lastPlayerMoveTime = now
    else
        local moved = (root.Position - lastPlayerPos).Magnitude
        if moved > 1.2 then
            lastPlayerPos = root.Position
            lastPlayerMoveTime = now
        elseif now - lastPlayerMoveTime > 1.2 then
            hum.Jump = true
            cachedPathWaypoints = nil
            lastPlayerMoveTime = now
        end
    end

    -- 4. DI CHUYỂN, TIẾP CẬN & ĐI LÙI NÉ ĐÒN ĐÁNH THƯỜNG THÔNG MINH THEO CỰ LI CHIÊU
    if dist < safeMinDist then
        -- A. QUÁ GẦN: ĐI LÙI NGAY LẬP TỨC ĐỂ NÉ ĐÒN ĐÁNH THƯỜNG CỦA QUÁI
        hum.AutoRotate = false

        local backClear, backDist = CheckDirectionClear(root.Position, awayDir, 7)
        local chosenMoveTarget = nil

        if backClear or backDist > 4.0 then
            -- Phía sau thông thoáng: Lùi dứt khoát
            local backStep = combatProfile.isRanged and 10 or 6
            chosenMoveTarget = root.Position + awayDir * backStep
            State.CurrentStatus = string.format("🔄 Đi lùi né đánh thường [%s] (Cách: %.1fm)", activeSkillInfo, dist)
            -- Nhảy lùi khẩn cấp chỉ khi quái áp sát nguy hiểm vào vùng đánh trúng
            if dist < emergencyDodgeDist then
                hum.Jump = true
            end
        else
            -- Phía sau vướng tường/cột: Circle-Strafe né sang bên thoáng nhất
            local leftClear, leftDist = CheckDirectionClear(root.Position, leftDir, 5)
            local rightClear, rightDist = CheckDirectionClear(root.Position, rightDir, 5)
            local chosenDir = (leftDist >= rightDist) and leftDir or rightDir
            chosenMoveTarget = root.Position + chosenDir * 7
            State.CurrentStatus = string.format("🔄 Lùi né tường (Circle Strafe) [%s]", activeSkillInfo)
        end

        hum:MoveTo(chosenMoveTarget)

    elseif dist <= safeMaxDist then
        -- B. CỰ LY VÀNG: Vừa xa tầm đánh của quái vừa trúng tầm skill!
        hum.AutoRotate = false
        local strafePart = (strafeSign > 0) and leftDir or rightDir
        local maintainDir = (awayDir * 0.7 + strafePart * 0.4).Unit

        State.CurrentStatus = string.format("⚔️ Cự ly vàng [%s] (Cách: %.1fm | Quái HP: %d/%d)", activeSkillInfo, dist, enemyHp, enemyMaxHp)
        hum:MoveTo(root.Position + maintainDir * 4)

    else
        -- C. Ở XA: Tiếp cận quái
        local closeApproachDist = safeMaxDist + 5
        if dist <= closeApproachDist then
            hum.AutoRotate = true
            hum:MoveTo(root.Position - awayDir * 4)
        else
            State.CurrentStatus = string.format("🏃 Tiếp cận %s [%s] (Cách: %dm | HP: %d/%d)", targetMob.Name, activeSkillInfo, math.floor(dist), enemyHp, enemyMaxHp)
            hum.AutoRotate = true
            local hasLOS = HasLineOfSight(root.Position, mobRoot.Position, {char, targetMob})
            if hasLOS then
                hum:MoveTo(mobRoot.Position)
            else
                FollowWaypoints(mobRoot.Position)
            end
        end
    end

    -- 5. ĐÁNH THƯỜNG VỚI VŨ KHÍ
    local weaponAttackRange = (combatProfile.isRanged or GetEquippedWeaponRange().isRanged) and 24 or 8.5
    if dist <= weaponAttackRange then
        AttackWithWeapon(mobRoot.Position)
    end

    -- 6. XẢ SKILL THÔNG MINH (Chỉ xả khi quái trong cự ly hữu hiệu của từng chiêu)
    CastAllAbilities(isBossTarget, livingMobs, healthPercent, dist)
end

--------------------------------------------------------------------------------
-- 11. DUNGEON READY UP (TỰ ĐỘNG BẤM READY KHI VÀO TRẬN ĐẤU)
--------------------------------------------------------------------------------
local function ProcessDungeonReady()
    if not IsInDungeon() then return end

    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    if remotes and remotes:FindFirstChild("readyUp") then
        pcall(function() remotes.readyUp:FireServer() end)
    end
    if remotes and remotes:FindFirstChild("startDungeon") then
        pcall(function() remotes.startDungeon:FireServer() end)
    end

    local readyGui = PlayerGui:FindFirstChild("readyGui") or PlayerGui:FindFirstChild("dungeonReady")
    if readyGui and readyGui.Enabled then
        local btn = readyGui:FindFirstChildWhichIsA("GuiButton", true)
        if btn and btn.Visible then
            ClickButton(btn)
        end
    end

    local startBtnGui = PlayerGui:FindFirstChild("startButton")
    if startBtnGui and startBtnGui.Enabled then
        local btn = startBtnGui:FindFirstChildWhichIsA("GuiButton", true)
        if btn and btn.Visible then
            ClickButton(btn)
        end
    end
end

--------------------------------------------------------------------------------
-- 12. AUTO REPLAY & REWARD CLAIM (CHỈ REPLAY KHI KẾT THÚC TRẬN ĐẤU)
--------------------------------------------------------------------------------
local hasReplayedThisDungeon = false
local function ProcessAutoReplay()
    if not Config.AutoReplay then return end

    -- Tuyệt đối KHÔNG chạy AutoReplay khi đang ở Lobby!
    if IsInLobby() then
        hasReplayedThisDungeon = false
        return
    end

    if hasReplayedThisDungeon then return end

    -- Chỉ kích hoạt khi trận đấu ĐÃ THẬT SỰ KẾT THÚC (dungeonComplete = true hoặc Replay Button xuất hiện)
    local dungeonComplete = workspace:FindFirstChild("dungeonComplete") and workspace.dungeonComplete.Value
    local replayGui = PlayerGui:FindFirstChild("ReplayDungeonButton")
    local replayBtn = replayGui and replayGui.Enabled and replayGui:FindFirstChild("Replay", true)

    if dungeonComplete == true or (replayBtn and replayBtn.Visible) then
        hasReplayedThisDungeon = true
        State.TotalDungeonsCompleted = State.TotalDungeonsCompleted + 1
        State.CurrentStatus = "Chiến thắng! Đang bấm Replay trận mới..."
        QueueReconnect()

        local remotes = ReplicatedStorage:FindFirstChild("remotes")
        if remotes and remotes:FindFirstChild("replayDungeon") then
            pcall(function() remotes.replayDungeon:FireServer() end)
        end

        if replayBtn and replayBtn.Visible then
            ClickButton(replayBtn)
        end

        task.wait(2.5)
    end
end

--------------------------------------------------------------------------------
-- 12. ANTI-AFK (CHỐNG MẤT KẾT NỐI 20 PHÚT)
--------------------------------------------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
    print("[DungeonQuest] Anti-AFK bypass activated.")
end)

--------------------------------------------------------------------------------
-- 13. MODERN UI DASHBOARD
--------------------------------------------------------------------------------
local function CreateDashboard()
    pcall(function()
        local old = PlayerGui:FindFirstChild("DQ_Kaitun_Dashboard")
        if old then old:Destroy() end
    end)

    local screen = Instance.new("ScreenGui")
    screen.Name = "DQ_Kaitun_Dashboard"
    screen.ResetOnSpawn = false
    screen.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 310, 0, 240)
    frame.Position = UDim2.new(0.02, 0, 0.22, 0)
    frame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(241, 196, 15)
    stroke.Thickness = 2
    stroke.Parent = frame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 36)
    title.Text = "⚔️ DUNGEON QUEST SMART KAITUN"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
    title.BorderSizePixel = 0
    title.Parent = frame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = title

    -- Labels
    local function CreateInfoLabel(yPos)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -24, 0, 20)
        lbl.Position = UDim2.new(0, 12, 0, yPos)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 11
        lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.BackgroundTransparency = 1
        lbl.Parent = frame
        return lbl
    end

    local statusLbl = CreateInfoLabel(42)
    local mapLbl = CreateInfoLabel(66)
    local levelLbl = CreateInfoLabel(90)
    local statsLbl = CreateInfoLabel(114)
    local extraLbl = CreateInfoLabel(138)

    -- Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -24, 0, 36)
    toggleBtn.Position = UDim2.new(0, 12, 0, 185)
    toggleBtn.Text = "AUTO-FARM: ĐANG CHẠY [ON]"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 12
    toggleBtn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        Config.KillAura = not Config.KillAura
        if Config.KillAura then
            toggleBtn.Text = "AUTO-FARM: ĐANG CHẠY [ON]"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        else
            toggleBtn.Text = "AUTO-FARM: TẠM DỪNG [OFF]"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            State.CurrentStatus = "Đã tạm dừng..."
        end
    end)

    -- Update loop UI
    task.spawn(function()
        while task.wait(0.3) do
            if getgenv and getgenv()._DQKaitunSession ~= CurrentSession then break end
            if not frame or not frame.Parent then break end
            local playerLvl = GetPlayerLevel()
            local inDung = IsInDungeon()

            statusLbl.Text = "📌 " .. tostring(State.CurrentStatus)
            mapLbl.Text = "🏰 Map: " .. tostring(State.DungeonTarget) .. " (" .. Config.Difficulty .. ")"
            levelLbl.Text = string.format("⭐ Cấp độ: Lv.%d | Điểm thừa: %d", playerLvl, LocalPlayer:FindFirstChild("skillPoints") and LocalPlayer.skillPoints.Value or 0)
            
            if inDung then
                local wave = workspace:FindFirstChild("currentWave") and workspace.currentWave.Value or 0
                statsLbl.Text = string.format("⚔️ Wave: %d | Quái còn lại: %d", wave, State.EnemiesRemaining)
            else
                statsLbl.Text = "🛡️ Chế độ Né Boss & Safe Hover: BẬT"
            end

            extraLbl.Text = string.format("📦 Đã cày xong: %d trận | Đã bán: %d đồ", State.TotalDungeonsCompleted, State.SoldItemsCount)
        end
    end)
end

--------------------------------------------------------------------------------
-- 14. MAIN EXECUTION LOOP
--------------------------------------------------------------------------------
local function Main()
    CreateDashboard()

    -- Luồng 1: Combat, Di chuyển & Đi lùi Kiting thời gian thực (Cực kỳ mượt mà, phản hồi cao ~16 FPS)
    task.spawn(function()
        while task.wait(0.06) do
            if getgenv and getgenv()._DQKaitunSession ~= CurrentSession then
                print("[DungeonQuest] Dừng luồng combat cũ.")
                break
            end
            pcall(ProcessSmartCombat)
        end
    end)

    -- Luồng 2: Quản lý Game State, Lobby, Trang bị, Bán đồ, Nâng điểm, Replay (Chu kỳ 0.5s)
    task.spawn(function()
        while task.wait(0.5) do
            if getgenv and getgenv()._DQKaitunSession ~= CurrentSession then
                print("[DungeonQuest] Dừng luồng quản lý cũ.")
                break
            end
            pcall(ProcessAutoEnter)
            pcall(ProcessAutoStats)
            pcall(ProcessAutoEquip)
            pcall(ProcessAutoSell)
            pcall(ProcessLobbyProgression)
            pcall(ProcessDungeonReady)
            pcall(ProcessAutoReplay)
        end
    end)
end

Main()
print("[DungeonQuest] Ultimate Kaitun loaded and running successfully!")
