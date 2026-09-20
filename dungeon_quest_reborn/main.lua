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
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/babadz207/animal/main/mcp_loader.lua"))() end)
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/babadz207/animal/main/dungeon_quest_kaitun.lua?t=" .. tostring(tick())))() end)
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
    AutoEnterGame = true,             -- Tự động bấm Play & Bỏ qua hướng dẫn
    AutoProgressionDungeon = true,    -- Tự động chọn Dungeon cao nhất theo Level
    AutoProgressionDifficulty = true, -- TỰ ĐỘNG CHỌN ĐỘ KHÓ CAO NHẤT THEO LEVEL (Easy -> Medium -> Hard -> Insane -> Nightmare)
    FixedDungeon = "Desert Temple",   -- Dùng khi AutoProgressionDungeon = false
    Difficulty = "Easy",              -- Độ khó mặc định / dùng khi AutoProgressionDifficulty = false
    HardcoreMode = false,             -- Bật nếu muốn cày thêm 20% may mắn & exp
    PrivateLobby = true,              -- Tạo phòng riêng tư không bị quấy rối
    
    -- Combat & Movement (Đi bộ tiếp cận, Đánh thường, Xả skill & Đi lùi thông minh)
    KillAura = true,              -- Tự động đánh quái & Boss
    CombatRangeMage = 18,         -- Cự ly đứng xả skill của Pháp sư (14 - 18 studs)
    CombatRangeWarrior = 9.5,     -- Cự ly đánh của Chiến binh
    KiteDistanceMage = 14,        -- Cự ly bắt đầu lùi né đòn thường của Pháp sư (quái cận chiến tầm đánh 6 studs)
    KiteDistanceWarrior = 7.5,    -- Cự ly bắt đầu lùi của Chiến binh
    AutoSpamSkills = true,        -- Tự xả chiêu thức thông minh (Q/E, Backpack theo cự ly)
    AutoSwapSkills = false,       -- TẮT ĐỔI BỘ SKILL LIÊN TỤC (Giữ nguyên bộ kỹ năng chính, tránh giật nháy hotbar)
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
-- 2. DUNGEON & DIFFICULTY PROGRESSION TABLE (TỰ ĐỘNG CHỌN MAP & ĐỘ KHÓ CAO NHẤT)
--------------------------------------------------------------------------------
local DUNGEON_PROGRESSION = {
    -- Desert Temple (Lv 1 - 29)
    { Dungeon = "Desert Temple",   Difficulty = "Nightmare", MinLevel = 27 },
    { Dungeon = "Desert Temple",   Difficulty = "Insane",    MinLevel = 20 },
    { Dungeon = "Desert Temple",   Difficulty = "Hard",      MinLevel = 12 },
    { Dungeon = "Desert Temple",   Difficulty = "Medium",    MinLevel = 6 },
    { Dungeon = "Desert Temple",   Difficulty = "Easy",      MinLevel = 1 },

    -- Winter Outpost (Lv 30 - 49)
    { Dungeon = "Winter Outpost",  Difficulty = "Nightmare", MinLevel = 55 },
    { Dungeon = "Winter Outpost",  Difficulty = "Insane",    MinLevel = 50 },
    { Dungeon = "Winter Outpost",  Difficulty = "Hard",      MinLevel = 45 },
    { Dungeon = "Winter Outpost",  Difficulty = "Medium",    MinLevel = 38 },
    { Dungeon = "Winter Outpost",  Difficulty = "Easy",      MinLevel = 30 },

    -- Pirate Island (Lv 40 - 59)
    { Dungeon = "Pirate Island",   Difficulty = "Nightmare", MinLevel = 65 },
    { Dungeon = "Pirate Island",   Difficulty = "Insane",    MinLevel = 60 },
    { Dungeon = "Pirate Island",   Difficulty = "Hard",      MinLevel = 55 },
    { Dungeon = "Pirate Island",   Difficulty = "Medium",    MinLevel = 48 },
    { Dungeon = "Pirate Island",   Difficulty = "Easy",      MinLevel = 40 },

    -- King's Castle (Lv 50 - 69)
    { Dungeon = "King's Castle",   Difficulty = "Nightmare", MinLevel = 75 },
    { Dungeon = "King's Castle",   Difficulty = "Insane",    MinLevel = 70 },
    { Dungeon = "King's Castle",   Difficulty = "Hard",      MinLevel = 65 },
    { Dungeon = "King's Castle",   Difficulty = "Medium",    MinLevel = 58 },
    { Dungeon = "King's Castle",   Difficulty = "Easy",      MinLevel = 50 },

    -- The Underworld (Lv 60 - 79)
    { Dungeon = "The Underworld",  Difficulty = "Nightmare", MinLevel = 85 },
    { Dungeon = "The Underworld",  Difficulty = "Insane",    MinLevel = 80 },
    { Dungeon = "The Underworld",  Difficulty = "Hard",      MinLevel = 75 },
    { Dungeon = "The Underworld",  Difficulty = "Medium",    MinLevel = 68 },
    { Dungeon = "The Underworld",  Difficulty = "Easy",      MinLevel = 60 },

    -- Samurai Palace (Lv 70 - 84)
    { Dungeon = "Samurai Palace",  Difficulty = "Nightmare", MinLevel = 95 },
    { Dungeon = "Samurai Palace",  Difficulty = "Insane",    MinLevel = 90 },
    { Dungeon = "Samurai Palace",  Difficulty = "Hard",      MinLevel = 85 },
    { Dungeon = "Samurai Palace",  Difficulty = "Medium",    MinLevel = 78 },
    { Dungeon = "Samurai Palace",  Difficulty = "Easy",      MinLevel = 70 },

    -- The Canals (Lv 80 - 89)
    { Dungeon = "The Canals",      Difficulty = "Nightmare", MinLevel = 105 },
    { Dungeon = "The Canals",      Difficulty = "Insane",    MinLevel = 100 },
    { Dungeon = "The Canals",      Difficulty = "Hard",      MinLevel = 95 },
    { Dungeon = "The Canals",      Difficulty = "Medium",    MinLevel = 88 },
    { Dungeon = "The Canals",      Difficulty = "Easy",      MinLevel = 80 },

    -- Steampunk Sewers (Lv 85 - 99)
    { Dungeon = "Steampunk Sewers",Difficulty = "Nightmare", MinLevel = 115 },
    { Dungeon = "Steampunk Sewers",Difficulty = "Insane",    MinLevel = 110 },
    { Dungeon = "Steampunk Sewers",Difficulty = "Hard",      MinLevel = 100 },
    { Dungeon = "Steampunk Sewers",Difficulty = "Medium",    MinLevel = 92 },
    { Dungeon = "Steampunk Sewers",Difficulty = "Easy",      MinLevel = 85 },

    -- Orbital Outpost (Lv 100+)
    { Dungeon = "Orbital Outpost", Difficulty = "Nightmare", MinLevel = 130 },
    { Dungeon = "Orbital Outpost", Difficulty = "Insane",    MinLevel = 120 },
    { Dungeon = "Orbital Outpost", Difficulty = "Hard",      MinLevel = 112 },
    { Dungeon = "Orbital Outpost", Difficulty = "Medium",    MinLevel = 105 },
    { Dungeon = "Orbital Outpost", Difficulty = "Easy",      MinLevel = 100 },

    -- Volcanic Chambers (Lv 115+)
    { Dungeon = "Volcanic Chambers",Difficulty = "Nightmare",MinLevel = 145 },
    { Dungeon = "Volcanic Chambers",Difficulty = "Insane",   MinLevel = 135 },
    { Dungeon = "Volcanic Chambers",Difficulty = "Hard",     MinLevel = 125 },
    { Dungeon = "Volcanic Chambers",Difficulty = "Medium",   MinLevel = 120 },
    { Dungeon = "Volcanic Chambers",Difficulty = "Easy",     MinLevel = 115 },

    -- Aquatic Temple (Lv 130+)
    { Dungeon = "Aquatic Temple",  Difficulty = "Nightmare", MinLevel = 160 },
    { Dungeon = "Aquatic Temple",  Difficulty = "Insane",    MinLevel = 150 },
    { Dungeon = "Aquatic Temple",  Difficulty = "Hard",      MinLevel = 140 },
    { Dungeon = "Aquatic Temple",  Difficulty = "Medium",    MinLevel = 135 },
    { Dungeon = "Aquatic Temple",  Difficulty = "Easy",      MinLevel = 130 },

    -- Enchanted Forest (Lv 145+)
    { Dungeon = "Enchanted Forest",Difficulty = "Nightmare", MinLevel = 175 },
    { Dungeon = "Enchanted Forest",Difficulty = "Insane",    MinLevel = 165 },
    { Dungeon = "Enchanted Forest",Difficulty = "Hard",      MinLevel = 155 },
    { Dungeon = "Enchanted Forest",Difficulty = "Medium",    MinLevel = 150 },
    { Dungeon = "Enchanted Forest",Difficulty = "Easy",      MinLevel = 145 },

    -- Northern Lands (Lv 160+)
    { Dungeon = "Northern Lands",  Difficulty = "Nightmare", MinLevel = 190 },
    { Dungeon = "Northern Lands",  Difficulty = "Insane",    MinLevel = 180 },
    { Dungeon = "Northern Lands",  Difficulty = "Hard",      MinLevel = 170 },
    { Dungeon = "Northern Lands",  Difficulty = "Medium",    MinLevel = 165 },
    { Dungeon = "Northern Lands",  Difficulty = "Easy",      MinLevel = 160 },

    -- Oni Dungeon (Lv 175+)
    { Dungeon = "Oni Dungeon",     Difficulty = "Nightmare", MinLevel = 205 },
    { Dungeon = "Oni Dungeon",     Difficulty = "Insane",    MinLevel = 195 },
    { Dungeon = "Oni Dungeon",     Difficulty = "Hard",      MinLevel = 185 },
    { Dungeon = "Oni Dungeon",     Difficulty = "Medium",    MinLevel = 180 },
    { Dungeon = "Oni Dungeon",     Difficulty = "Easy",      MinLevel = 175 },

    -- Gilded Skies (Lv 190+)
    { Dungeon = "Gilded Skies",    Difficulty = "Nightmare", MinLevel = 220 },
    { Dungeon = "Gilded Skies",    Difficulty = "Insane",    MinLevel = 210 },
    { Dungeon = "Gilded Skies",    Difficulty = "Hard",      MinLevel = 200 },
    { Dungeon = "Gilded Skies",    Difficulty = "Medium",    MinLevel = 195 },
    { Dungeon = "Gilded Skies",    Difficulty = "Easy",      MinLevel = 190 },
}

local function GetBestDungeonProgression(level)
    level = tonumber(level) or 1
    local bestDungeon = "Desert Temple"
    local bestDiff = "Easy"
    local highestMinLvl = -1

    for _, entry in ipairs(DUNGEON_PROGRESSION) do
        if level >= entry.MinLevel and entry.MinLevel > highestMinLvl then
            highestMinLvl = entry.MinLevel
            bestDungeon = entry.Dungeon
            bestDiff = entry.Difficulty
        end
    end
    return bestDungeon, bestDiff
end

local function GetBestDungeonForLevel(level)
    local d, _ = GetBestDungeonProgression(level)
    return d
end

--------------------------------------------------------------------------------
-- 3. STATE TRACKING
--------------------------------------------------------------------------------
local State = {
    CurrentStatus = "Khởi động...",
    DungeonTarget = "Desert Temple",
    DifficultyTarget = "Easy",
    CurrentWave = 0,
    EnemiesRemaining = 0,
    TotalDungeonsCompleted = 0,
    AllocatedPoints = 0,
    SoldItemsCount = 0,
    StartTime = os.time(),
    EquippedBeforeJoin = false,
    HasCompleteSecondSet = false,
}

--------------------------------------------------------------------------------
-- 4. UTILITIES
--------------------------------------------------------------------------------
local function ClickButton(btn)
    if not btn or not btn:IsA("GuiButton") then return false end
    local clicked = false

    if type(getconnections) == "function" then
        -- Ưu tiên theo thứ tự: MouseButton1Click -> Activated -> MouseButton1Down
        -- Nếu tìm thấy và kích hoạt thành công một loại sự kiện, dừng lại để tránh double-toggle (bật rồi tắt ngay)
        local eventNames = {"MouseButton1Click", "Activated", "MouseButton1Down"}
        for _, evtName in ipairs(eventNames) do
            local conns = getconnections(btn[evtName])
            if conns and #conns > 0 then
                for _, c in ipairs(conns) do
                    if c.Enabled then
                        pcall(function() c:Fire() end)
                        clicked = true
                    end
                end
                if clicked then break end
            end
        end
    end

    if not clicked and typeof(firesignal) == "function" then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
        pcall(function() firesignal(btn.MouseButton1Down) end)
        clicked = true
    end

    return clicked
end

-- Lấy chính xác các Tool kỹ năng đang hiển thị trên hotbar (Backpack / Character)
local function GetActiveHotbarSkills()
    local qTool, eTool = nil, nil
    local containers = {LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character}
    for _, cont in ipairs(containers) do
        if cont then
            for _, t in ipairs(cont:GetChildren()) do
                if t:IsA("Tool") then
                    local s = t:FindFirstChild("abilitySlot") or t:FindFirstChild("slot")
                    local sVal = s and tostring(s.Value):lower()
                    if sVal == "q" then
                        qTool = t
                    elseif sVal == "e" then
                        eTool = t
                    end
                end
            end
        end
    end
    return qTool, eTool
end

-- Đảm bảo hotbar luôn có đầy đủ 2 chiêu (không bị tình trạng khuyết slot E hoặc kẹt ở Set 2 rỗng)
local lastEnsureSwapTime = 0
local function EnsureActiveSkillSetComplete()
    local qTool, eTool = GetActiveHotbarSkills()
    -- Nếu cả 2 slot Q và E đều đã có chiêu thì hotbar hoàn hảo, không cần thao tác gì
    if qTool and eTool then return true end

    -- Nếu bị khuyết chiêu (ví dụ có Q mà mất E hoặc ngược lại):
    local now = os.clock()
    if now - lastEnsureSwapTime < 1.5 then return false end
    lastEnsureSwapTime = now

    local abilitiesGui = PlayerGui:FindFirstChild("abilities")
    local swapBtn = abilitiesGui and abilitiesGui:FindFirstChild("Swap", true)
    local remotes = ReplicatedStorage:FindFirstChild("remotes")

    local beforeCount = (qTool and 1 or 0) + (eTool and 1 or 0)

    -- Kích hoạt đổi bộ kỹ năng (Swap) để lấy lại bộ chiêu đầy đủ
    if swapBtn then
        ClickButton(swapBtn)
    end
    if remotes and remotes:FindFirstChild("swapAbilitySet") then
        pcall(function() remotes.swapAbilitySet:FireServer() end)
    end
    if remotes and remotes:FindFirstChild("abilitySetSwapped") then
        pcall(function() remotes.abilitySetSwapped:FireServer() end)
    end

    task.wait(0.25)
    local newQ, newE = GetActiveHotbarSkills()
    local afterCount = (newQ and 1 or 0) + (newE and 1 or 0)

    -- Nếu đổi xong mà tệ hơn (ví dụ từ 1 chiêu thành 0 chiêu), swap ngược lại ngay
    if afterCount < beforeCount then
        if swapBtn then ClickButton(swapBtn) end
        if remotes and remotes:FindFirstChild("swapAbilitySet") then
            pcall(function() remotes.swapAbilitySet:FireServer() end)
        end
        return false
    end

    return (newQ and newE) ~= nil
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
    local equippedWeaponVal = LocalPlayer:FindFirstChild("weaponEquipped") and LocalPlayer.weaponEquipped.Value:lower() or ""
    local isMageWeapon = equippedWeaponVal:find("wand") or equippedWeaponVal:find("staff") or equippedWeaponVal:find("orb")
    local isWarriorWeapon = equippedWeaponVal:find("sword") or equippedWeaponVal:find("blade") or equippedWeaponVal:find("dagger")
        or equippedWeaponVal:find("axe") or equippedWeaponVal:find("hammer") or equippedWeaponVal:find("mace") or equippedWeaponVal:find("scythe")

    local isMage = false
    if Config.StatBuild == "Mage" then
        isMage = true
    elseif Config.StatBuild == "Warrior" then
        isMage = false
    else
        if isMageWeapon then
            isMage = true
        elseif isWarriorWeapon then
            isMage = false
        elseif sp > pp then
            isMage = true
        else
            isMage = false -- Mặc định của tân thủ Dungeon Quest luôn là Chiến Binh (Warrior)
        end
    end

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

    -- D. TỰ ĐỘNG TRANG BỊ KỸ NĂNG (ABILITIES) THÔNG MINH - CHUẨN COMBO RPG
    if invData.abilities then
        local rawAbilities = {}
        for key, item in pairs(invData.abilities) do
            if type(item) == "table" and (tonumber(item.levelReq) or 1) <= playerLvl then
                local num = tonumber(item.uniqueItemNum) or tonumber(key:match("%d+"))
                local name = tostring(item.name or "Ability")
                local nameLower = name:lower()
                local rScore = RARITY_SCORE[(tostring(item.rarity or "common")):lower()] or 1
                local physDmg = tonumber(item.physicalDamage) or 0
                local spellPwr = tonumber(item.spellPower) or 0
                local upgrade = tonumber(item.currentUpgrade) or 0

                -- 1. Nhận diện loại kỹ năng: Hồi máu, Cận chiến/Vật lý, hay Phép thuật
                local healKeywords = {"heal", "rejuvenat", "aura of life", "redemption", "inner sanctum", "holy circle", "holy barrier", "innervate", "blessing", "life pulse"}
                local isHeal = false
                for _, kw in ipairs(healKeywords) do
                    if nameLower:find(kw) then isHeal = true break end
                end

                local meleeKeywords = {"whirlwind", "strike", "slash", "slam", "stomp", "cleave", "spin", "smash", "leap", "blade", "gale", "quake", "tremor", "bash", "barrage"}
                local isMelee = false
                for _, kw in ipairs(meleeKeywords) do
                    if nameLower:find(kw) then isMelee = true break end
                end
                if physDmg > 0 then isMelee = true end

                local spellKeywords = {"fireball", "flame", "orb", "beam", "bolt", "blast", "ice", "lightning", "missile", "wave", "meteor", "storm", "nova"}
                local isSpell = false
                for _, kw in ipairs(spellKeywords) do
                    if nameLower:find(kw) then isSpell = true break end
                end
                if spellPwr > 0 then isSpell = true end

                -- 2. Tính điểm độ mạnh và mức độ ăn khớp với Class (Class Synergy)
                local baseScore = rScore * 20 + upgrade * 5
                if isMage then
                    baseScore = baseScore + spellPwr * 4 + (isSpell and 1500 or 0)
                else
                    baseScore = baseScore + physDmg * 4 + (isMelee and 1500 or 0)
                end
                -- Chiêu hồi máu cực kỳ giá trị để sinh tồn trong Dungeon
                if isHeal then
                    baseScore = baseScore + 2000
                end

                -- Làm sạch tên kỹ năng để lọc trùng chính xác (loại bỏ hậu tố level / nâng cấp)
                local baseCleanName = nameLower:gsub("%s*%(.*%)", ""):gsub("%s*[%+%-]%d+", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")

                table.insert(rawAbilities, {
                    num = num,
                    name = name,
                    baseName = baseCleanName,
                    score = baseScore,
                    isHeal = isHeal,
                    isMelee = isMelee,
                    isSpell = isSpell,
                    rarityScore = rScore,
                    equipped = item.equipped or {},
                })
            end
        end

        -- Sắp xếp tất cả các kỹ năng theo điểm số giảm dần
        table.sort(rawAbilities, function(a, b) return a.score > b.score end)

        -- 3. CHỌN KỸ NĂNG VÀO TỪNG SLOT THEO NGUYÊN TẮC:
        -- - Mỗi item (uniqueItemNum) chỉ được gán vào ĐÚNG 1 slot duy nhất!
        -- - Trong cùng một bộ (Set 1: Q & E hoặc Set 2: Q2 & E2), 2 chiêu TUYỆT ĐỐI KHÔNG TRÙNG baseName!
        local usedItemNums = {}
        local targetSlots = {}

        -- Set 1: Slot Q (Chiêu chủ lực tốt nhất)
        for _, ab in ipairs(rawAbilities) do
            if not usedItemNums[ab.num] then
                targetSlots["q"] = ab
                usedItemNums[ab.num] = true
                break
            end
        end

        -- Set 1: Slot E (Chiêu thứ 2 KHÁC LOẠI với Q)
        for _, ab in ipairs(rawAbilities) do
            if not usedItemNums[ab.num] then
                local conflictWithQ = targetSlots["q"] and (ab.baseName == targetSlots["q"].baseName)
                if not conflictWithQ then
                    targetSlots["e"] = ab
                    usedItemNums[ab.num] = true
                    break
                end
            end
        end

        -- Set 2: CHỈ trang bị Set 2 khi có ĐỦ CẢ 2 CHIÊU HỢP LỆ (Q2 và E2 khác loại nhau)!
        -- Tuyệt đối KHÔNG trang bị Set 2 nếu chỉ có 1 chiêu đơn lẻ, vì máy chủ sẽ tự động chuyển góc nhìn
        -- sang Set 2 khiến người chơi bị khuyết mất slot E (chỉ có 1 chiêu trên hotbar)!
        local candidateQ2 = nil
        local candidateE2 = nil
        for _, ab1 in ipairs(rawAbilities) do
            if not usedItemNums[ab1.num] then
                for _, ab2 in ipairs(rawAbilities) do
                    if ab2.num ~= ab1.num and not usedItemNums[ab2.num] then
                        if ab1.baseName ~= ab2.baseName then
                            candidateQ2 = ab1
                            candidateE2 = ab2
                            break
                        end
                    end
                end
                if candidateQ2 and candidateE2 then
                    break
                end
            end
        end

        if candidateQ2 and candidateE2 then
            targetSlots["q2"] = candidateQ2
            targetSlots["e2"] = candidateE2
            usedItemNums[candidateQ2.num] = true
            usedItemNums[candidateE2.num] = true
            State.HasCompleteSecondSet = true
        else
            targetSlots["q2"] = nil
            targetSlots["e2"] = nil
            State.HasCompleteSecondSet = false
        end

        -- 4. ĐỒNG BỘ TRANG BỊ VỚI GAME SERVER
        local unequipRemote = remotes and remotes:FindFirstChild("unequipItem")
        local equipRemote = remotes and remotes:FindFirstChild("equipItem")

        -- Bước A: Gỡ bỏ bất kỳ item nào đang ở SAI slot hoặc không còn được dùng
        for _, ab in ipairs(rawAbilities) do
            if type(ab.equipped) == "table" then
                for s, isEq in pairs(ab.equipped) do
                    if isEq == true then
                        local assignedAb = targetSlots[s]
                        if not assignedAb or assignedAb.num ~= ab.num then
                            if unequipRemote then
                                pcall(function() unequipRemote:InvokeServer("ability", ab.num) end)
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end

        -- Bước B: Gán từng item vào đúng slot đã định
        for slotName, ab in pairs(targetSlots) do
            if ab and ab.num then
                local isAlreadyInSlot = false
                if type(ab.equipped) == "table" then
                    isAlreadyInSlot = (ab.equipped[slotName] == true)
                end

                if not isAlreadyInSlot and equipRemote then
                    pcall(function()
                        equipRemote:InvokeServer("ability", ab.num, slotName)
                    end)
                    task.wait(0.15)
                end
            end
        end

        -- Đảm bảo sau khi trang bị, hotbar của nhân vật luôn hiển thị đầy đủ bộ kỹ năng (không bị khuyết E)
        EnsureActiveSkillSetComplete()
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
    local targetDungeon = Config.FixedDungeon or "Desert Temple"
    local targetDiff = Config.Difficulty or "Easy"

    if Config.AutoProgressionDungeon then
        local autoDungeon, autoDiff = GetBestDungeonProgression(playerLvl)
        targetDungeon = autoDungeon
        if Config.AutoProgressionDifficulty ~= false then
            targetDiff = autoDiff
        end
    end

    State.DungeonTarget = targetDungeon
    State.DifficultyTarget = targetDiff

    -- 1. KIỂM TRA ĐÃ CÓ PHÒNG CHƯA (Workspace.games.inLobby[Player.Name])
    local gamesFolder = workspace:FindFirstChild("games")
    local inLobbyFolder = gamesFolder and gamesFolder:FindFirstChild("inLobby")
    local myLobby = inLobbyFolder and inLobbyFolder:FindFirstChild(LocalPlayer.Name)

    if myLobby then
        State.CurrentStatus = "Đã có phòng! Xuất phát vào: " .. targetDungeon .. " (" .. targetDiff .. ")..."
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
            State.CurrentStatus = string.format("Tạo phòng: %s (%s)", targetDungeon, targetDiff)

            -- Chọn Dungeon
            local scroll = choose:FindFirstChild("ScrollingFrame", true)
            local dungBtn = scroll and scroll:FindFirstChild(targetDungeon) and scroll[targetDungeon]:FindFirstChild("TextButton")
            if dungBtn then
                ClickButton(dungBtn)
                task.wait(0.15)
            end

            -- Chọn Độ khó
            local right = choose:FindFirstChild("backgroundFillRight")
            local diffBtn = right and right:FindFirstChild(targetDiff) and right[targetDiff]:FindFirstChild("TextButton")
            if diffBtn then
                ClickButton(diffBtn)
                task.wait(0.15)
            end

            -- Bật phòng Private nếu cấu hình
            if Config.PrivateLobby then
                local privContainer = choose:FindFirstChild("private", true)
                local privBtn = privContainer and privContainer:FindFirstChildWhichIsA("GuiButton", true)
                if privBtn then
                    ClickButton(privBtn)
                    task.wait(0.1)
                end
            end

            -- Bấm Create Lobby trên giao diện
            local startMainContainer = choose:FindFirstChild("startMain", true)
            local startMainBtn = startMainContainer and startMainContainer:FindFirstChildWhichIsA("GuiButton", true)
            if startMainBtn then
                ClickButton(startMainBtn)
            end

            -- Đồng thời gọi Remote createLobby trực tiếp để đảm bảo 100%
            if remotes and remotes:FindFirstChild("createLobby") then
                pcall(function()
                    remotes.createLobby:InvokeServer(targetDungeon, targetDiff, false, 0, Config.PrivateLobby)
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

local function GetCooldownRemaining(btnContainer)
    if not btnContainer then return 0 end
    local cd = btnContainer:FindFirstChild("cooldownNumber", true)
    if cd and cd.Visible and cd.Text ~= "" then
        local num = tonumber(cd.Text:match("[%d%.]+"))
        return num or 0
    end
    return 0
end

local function IsOnCooldown(btnContainer)
    return GetCooldownRemaining(btnContainer) > 0.1
end

local function AreCurrentSkillsOnLongCooldown()
    local abilitiesGui = PlayerGui:FindFirstChild("abilities")
    if not abilitiesGui then return false end

    local leftBtn = abilitiesGui:FindFirstChild("LeftAbility", true)
    local rightBtn = abilitiesGui:FindFirstChild("RightAbility", true)

    local qCd = GetCooldownRemaining(leftBtn)
    local eCd = GetCooldownRemaining(rightBtn)

    -- Chỉ coi là hồi lâu nếu CẢ 2 chiêu đều còn hơn 3.5s (tránh đổi liên tục khi skill sắp hồi như 0.6s hay 1.1s)
    return (qCd > 3.5) and (eCd > 3.5)
end

local function SwapAbilitySet()
    if not Config.AutoSwapSkills then return false end
    -- BẢO VỆ TUYỆT ĐỐI: Tuyệt đối không swap nếu người chơi không có đủ 2 bộ chiêu hoàn chỉnh (4 kỹ năng)!
    -- Tránh việc swap sang bộ rỗng hoặc chỉ có 1 chiêu làm mất slot E!
    if not State.HasCompleteSecondSet then return false end
    if os.clock() - lastSwapTime < 4.0 then return false end -- Tối thiểu 4s mới được đổi lại

    local abilitiesGui = PlayerGui:FindFirstChild("abilities")
    local canSwapLabel = abilitiesGui and abilitiesGui:FindFirstChild("CanSwap", true)
    local canSwapReady = canSwapLabel and canSwapLabel.Visible and canSwapLabel.Text:lower():find("swap")
    if not canSwapReady then return false end

    lastSwapTime = os.clock()

    local swapBtn = abilitiesGui and abilitiesGui:FindFirstChild("Swap", true)
    if swapBtn and swapBtn:IsA("GuiButton") then
        ClickButton(swapBtn)
    end

    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    if remotes and remotes:FindFirstChild("swapAbilitySet") then
        pcall(function() remotes.swapAbilitySet:FireServer() end)
    end
    if remotes and remotes:FindFirstChild("abilitySetSwapped") then
        pcall(function() remotes.abilitySetSwapped:FireServer() end)
    end
    return true
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
    local abilitiesGui = PlayerGui:FindFirstChild("abilities")
    local leftBtn = abilitiesGui and abilitiesGui:FindFirstChild("LeftAbility", true)
    local rightBtn = abilitiesGui and abilitiesGui:FindFirstChild("RightAbility", true)

    local qTool, eTool = GetActiveHotbarSkills()

    local qName = qTool and qTool.Name or nil
    local eName = eTool and eTool.Name or nil

    local qRange = qTool and CalculateSkillRange(qName, qTool) or nil
    local eRange = eTool and CalculateSkillRange(eName, eTool) or nil
    local weaponRange = GetEquippedWeaponRange()

    local qCooldown = (not qTool) or IsOnCooldown(leftBtn) or (qTool:FindFirstChild("cooldown") and qTool.cooldown.Value > 0.1)
    local eCooldown = (not eTool) or IsOnCooldown(rightBtn) or (eTool:FindFirstChild("cooldown") and eTool.cooldown.Value > 0.1)

    -- Thu thập danh sách chiêu thức sát thương ĐANG SẴN SÀNG (không bị hồi chiêu)
    local readyDamagingSkills = {}
    if qTool and not qCooldown and qRange and not qRange.isHeal then
        table.insert(readyDamagingSkills, {name = qName, profile = qRange, slot = "Q", tool = qTool})
    end
    if eTool and not eCooldown and eRange and not eRange.isHeal then
        table.insert(readyDamagingSkills, {name = eName, profile = eRange, slot = "E", tool = eTool})
    end

    -- Chọn profile chiến đấu phù hợp nhất:
    local chosenProfile = nil
    local activeSkillInfo = ""

    if #readyDamagingSkills == 0 then
        -- CẢ 2 CHIÊU ĐỀU ĐANG HỒI (hoặc chỉ có chiêu Hồi máu hoặc không có chiêu):
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

        -- Nếu người chơi cầm vũ khí tầm xa (Wand/Staff/Bow) HOẶC có chiêu tầm xa sẵn sàng:
        -- Luôn ưu tiên giữ cự ly TẦM XA (16-18 studs) an toàn, tuyệt đối không lao cận chiến tự sát!
        if weaponRange.isRanged then
            chosenProfile = hasRangedReady and hasRangedReady.profile or weaponRange
            activeSkillInfo = string.format("%s (Pháp sư tầm xa: %dm)", hasRangedReady and hasRangedReady.name or "Gậy phép", math.floor(chosenProfile.preferred))
        elseif hasRangedReady and (not hasMeleeReady or (currentDist and currentDist > 10)) then
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
        q = qTool and {name = qName, onCd = qCooldown, range = qRange} or nil,
        e = eTool and {name = eName, onCd = eCooldown, range = eRange} or nil,
    }
end

--------------------------------------------------------------------------------
-- 10. DI CHUYỂN, TẦM NHÌN (LINE OF SIGHT) & ĐIỀU HƯỚNG CHỐNG KẸT TƯỜNG
--------------------------------------------------------------------------------

-- Bộ điều phối di chuyển mượt mà (chống giật lag, chống spam MoveTo làm khựng nhân vật)
local lastMoveCommandTime = 0
local lastMoveDestination = nil
local lastJumpTime = 0
local lastPlayerPos = nil
local lastPlayerMoveTime = 0
local strafeSign = 1
local lastStrafeSwitch = 0

local function SmoothMoveTo(hum, targetPos, forceImmediate)
    if not hum or not targetPos then return end
    local now = os.clock()
    if forceImmediate or not lastMoveDestination or (now - lastMoveCommandTime > 0.35) or ((targetPos - lastMoveDestination).Magnitude > 3.0) then
        lastMoveCommandTime = now
        lastMoveDestination = targetPos
        hum:MoveTo(targetPos)
    end
end

-- Danh sách bỏ qua Raycast (Người chơi, đồng đội, quái vật, vfx) để chỉ bắt đúng TƯỜNG CỨNG & VẬT CẢN BẢN ĐỒ
local function GetRaycastIgnoreList()
    local ignore = {}
    local char = LocalPlayer.Character
    if char then table.insert(ignore, char) end

    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character ~= char then
            table.insert(ignore, p.Character)
        end
    end

    local dung = workspace:FindFirstChild("dungeon")
    if dung then
        for _, room in ipairs(dung:GetChildren()) do
            local ef = room:FindFirstChild("enemyFolder")
            if ef then table.insert(ignore, ef) end
        end
    end

    local efLegacy = workspace:FindFirstChild("enemies") or workspace:FindFirstChild("enemyFolder")
    if efLegacy then table.insert(ignore, efLegacy) end

    local vfx = workspace:FindFirstChild("vfxPool") or workspace:FindFirstChild("abilities")
    if vfx then table.insert(ignore, vfx) end

    local drops = workspace:FindFirstChild("drops") or workspace:FindFirstChild("debris")
    if drops then table.insert(ignore, drops) end

    return ignore
end

-- Hàm nhận diện chướng ngại vật vật lý hoặc kiến trúc tường/cột trong map Dungeon
local function IsSolidObstruction(part)
    if not part or not part:IsA("BasePart") then return false end

    -- 1. Part có CanCollide = true: Bất kể tàng hình hay nhìn thấy được, nó đều là tường/barrier cản bước người chơi
    if part.CanCollide then
        return true
    end

    -- 2. Part là chi tiết tường/cột/kiến trúc trực quan (CanCollide = false nhưng che khuất tầm nhìn và đòn đánh)
    if part.Transparency < 0.8 then
        local nameLower = part.Name:lower()
        if nameLower:find("wall") or nameLower:find("col") or nameLower:find("pillar")
           or nameLower:find("door") or nameLower:find("gate") or nameLower:find("arch")
           or nameLower:find("room") or nameLower:find("prop") or nameLower:find("rock")
           or nameLower:find("statue") or nameLower:find("temple") or nameLower:find("stone") then
            return true
        end

        -- Nếu kích thước lớn và không phải là hiệu ứng kỹ năng / hạt bụi
        if part.Size.X > 2 or part.Size.Y > 2 or part.Size.Z > 2 then
            if not (nameLower:find("effect") or nameLower:find("vfx") or nameLower:find("hitbox")
               or nameLower:find("ball") or nameLower:find("spell") or nameLower:find("beam")
               or nameLower:find("particle") or nameLower:find("aura")) then
                return true
            end
        end
    end

    return false
end

-- Quét tia ở một độ cao nhất định, bỏ qua các part hiệu ứng/trigger xuyên qua được
local function CastCheckRay(fromPos, toPos, yOffset, extraIgnore)
    local currentFrom = fromPos + Vector3.new(0, yOffset, 0)
    local currentTo = toPos + Vector3.new(0, yOffset, 0)
    local dir = currentTo - currentFrom
    local totalDist = dir.Magnitude
    if totalDist < 0.5 then return true end

    local ignoreList = GetRaycastIgnoreList()
    if extraIgnore then
        if typeof(extraIgnore) == "table" then
            for _, item in ipairs(extraIgnore) do table.insert(ignoreList, item) end
        else
            table.insert(ignoreList, extraIgnore)
        end
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    for _ = 1, 8 do
        rayParams.FilterDescendantsInstances = ignoreList
        local hit = workspace:Raycast(currentFrom, dir, rayParams)
        if not hit then
            return true -- Thông thoáng, không chạm gì
        end

        local part = hit.Instance
        if IsSolidObstruction(part) then
            return false, part, hit.Distance -- Có vật cản!
        end

        -- Part xuyên qua được (trigger / effect nhỏ) -> Thêm vào danh sách bỏ qua và quét tiếp
        table.insert(ignoreList, part)
        currentFrom = hit.Position + dir.Unit * 0.2
        dir = currentTo - currentFrom
        if dir.Magnitude < 0.5 then
            return true
        end
    end

    return false
end

-- Kiểm tra Tầm nhìn thẳng (Line of Sight Raycast chống kẹt tường 2 tầng: Ngang eo & Ngang ngực)
local function IsTargetVisible(fromPos, toPos, extraIgnore)
    -- Tầng 1: Ngang eo (+1.0 stud) - Bắt gờ tường thấp, bục bệ, rào chắn
    local waistClear = CastCheckRay(fromPos, toPos, 1.0, extraIgnore)
    if not waistClear then return false end

    -- Tầng 2: Ngang ngực (+2.2 studs) - Bắt tường, cột, xà ngang và mép cửa
    local chestClear = CastCheckRay(fromPos, toPos, 2.2, extraIgnore)
    if not chestClear then return false end

    return true
end

-- Tương thích ngược với các lệnh gọi HasLineOfSight cũ
local function HasLineOfSight(fromPos, toPos, ignoreList)
    return IsTargetVisible(fromPos, toPos, ignoreList)
end

-- Kiểm tra vật cản (tường, cột) theo một hướng để né khi di chuyển / đi lùi
local function CheckDirectionClear(fromPos, dir, distance)
    local checkFrom = fromPos + Vector3.new(0, 1.2, 0)
    local checkDir = dir.Unit * distance
    local ignoreList = GetRaycastIgnoreList()
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    for _ = 1, 6 do
        rayParams.FilterDescendantsInstances = ignoreList
        local hit = workspace:Raycast(checkFrom, checkDir, rayParams)
        if not hit then
            return true, distance
        end
        local part = hit.Instance
        if IsSolidObstruction(part) then
            return false, hit.Distance -- Có tường/cột cản trở ở khoảng cách hit.Distance
        end
        table.insert(ignoreList, part)
        checkFrom = hit.Position + dir.Unit * 0.2
        checkDir = dir.Unit * math.max(0, distance - (hit.Position - fromPos).Magnitude)
        if checkDir.Magnitude < 0.3 then
            return false, hit.Distance
        end
    end
    return true, distance
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
    -- AgentRadius = 1.8 giúp luồn lách qua các cửa hẹp, góc cột đền thờ mà không bị kẹt NavMesh
    local path = PathfindingService:CreatePath({
        AgentRadius = 1.8,
        AgentHeight = 4.5,
        AgentCanJump = true,
        WaypointSpacing = 3,
    })

    local ok = pcall(function()
        path:ComputeAsync(startPos, endPos)
    end)

    if ok and path.Status == Enum.PathStatus.Success then
        local wps = path:GetWaypoints()
        if wps and #wps > 0 then
            return wps
        end
    end

    -- Nếu đứng sát chân tường / bậc thềm: Nâng nhẹ vị trí xuất phát +1.5 stud để tính lại
    local nudgedStart = startPos + Vector3.new(0, 1.5, 0)
    ok = pcall(function()
        path:ComputeAsync(nudgedStart, endPos)
    end)
    if ok and path.Status == Enum.PathStatus.Success then
        local wps = path:GetWaypoints()
        if wps and #wps > 0 then
            return wps
        end
    end

    return nil
end

local function FollowWaypoints(targetPos)
    local root = GetRootPart()
    local hum = GetHumanoid()
    if not root or not hum then return end

    -- Bật AutoRotate để nhân vật tự xoay mặt theo từng khúc cua của hành lang
    hum.AutoRotate = true

    local now = os.clock()
    local needCompute = (not cachedPathWaypoints)
        or (now - lastPathTime > 1.2)
        or (cachedPathTarget and (targetPos - cachedPathTarget).Magnitude > 10)
        or (currentWaypointIndex > #cachedPathWaypoints)

    if needCompute then
        lastPathTime = now
        cachedPathTarget = targetPos
        cachedPathWaypoints = GetDungeonWaypoints(root.Position, targetPos)
        currentWaypointIndex = (cachedPathWaypoints and #cachedPathWaypoints > 1) and 2 or 1
    end

    if cachedPathWaypoints and #cachedPathWaypoints >= currentWaypointIndex then
        local wp = cachedPathWaypoints[currentWaypointIndex]
        if wp then
            local flatPlayerPos = Vector3.new(root.Position.X, wp.Position.Y, root.Position.Z)
            local wpDist = (wp.Position - flatPlayerPos).Magnitude
            if wpDist < 3.0 then
                currentWaypointIndex = currentWaypointIndex + 1
                if cachedPathWaypoints[currentWaypointIndex] then
                    wp = cachedPathWaypoints[currentWaypointIndex]
                end
            end
            if wp then
                if wp.Action == Enum.PathWaypointAction.Jump then
                    hum.Jump = true
                end
                SmoothMoveTo(hum, wp.Position, true)
            end
        end
    else
        -- Không tìm được đường thẳng tới targetPos (bị tường cản trở hoàn toàn):
        -- TUYỆT ĐỐI KHÔNG lao đầu vào tường!
        -- Tự động tìm hướng thoáng nhất trong phòng để bước ra không gian mở
        local bestDir = nil
        local maxClear = 0
        local testAngles = {0, 45, 90, 135, 180, 225, 270, 315}
        for _, deg in ipairs(testAngles) do
            local rad = math.rad(deg)
            local testDir = Vector3.new(math.sin(rad), 0, math.cos(rad))
            local clear, cDist = CheckDirectionClear(root.Position, testDir, 8)
            if cDist > maxClear then
                maxClear = cDist
                bestDir = testDir
            end
        end

        if bestDir and maxClear > 2.0 then
            hum.Jump = true
            local stepDist = math.min(5, maxClear - 1)
            SmoothMoveTo(hum, root.Position + bestDir * stepDist, true)
        end
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
local function CastAllAbilities(isBoss, mobCount, healthPercent, targetDist, skillsDebug)
    if not Config.AutoSpamSkills then return end
    local now = os.clock()
    if now - lastAbilityCastTime < 0.15 then return end
    lastAbilityCastTime = now

    local abilitiesGui = PlayerGui:FindFirstChild("abilities")
    local leftAbility = abilitiesGui and abilitiesGui:FindFirstChild("LeftAbility", true)
    local rightAbility = abilitiesGui and abilitiesGui:FindFirstChild("RightAbility", true)
    local leftBtn = leftAbility and leftAbility:FindFirstChildWhichIsA("GuiButton", true)
    local rightBtn = rightAbility and rightAbility:FindFirstChildWhichIsA("GuiButton", true)
    local remotes = ReplicatedStorage:FindFirstChild("remotes")

    -- 1. KIỂM TRA ĐIỀU KIỆN XẢ TỪNG CHIÊU Q VÀ E RIÊNG BIỆT
    -- CHỈ XẢ KHI QUÁI NẰM TRONG TẦM HIỆU LỰC (MAXCAST) CỦA CHIÊU ĐÓ!
    -- Không trong tầm thì TUYỆT ĐỐI KHÔNG XẢ CHIÊU!
    local canCastQ = false
    local canCastE = false

    if skillsDebug and skillsDebug.q and skillsDebug.q.name and not skillsDebug.q.onCd and skillsDebug.q.range then
        local qRange = skillsDebug.q.range
        if qRange.isHeal then
            canCastQ = (healthPercent < 0.75)
        else
            -- Chiêu sát thương: Bắt buộc quái phải nằm trong tầm đánh của chiêu Q
            if targetDist and qRange.maxCast and targetDist <= (qRange.maxCast + 0.5) then
                canCastQ = true
            end
        end
    end

    if skillsDebug and skillsDebug.e and skillsDebug.e.name and not skillsDebug.e.onCd and skillsDebug.e.range then
        local eRange = skillsDebug.e.range
        if eRange.isHeal then
            canCastE = (healthPercent < 0.75)
        else
            -- Chiêu sát thương: Bắt buộc quái phải nằm trong tầm đánh của chiêu E
            if targetDist and eRange.maxCast and targetDist <= (eRange.maxCast + 0.5) then
                canCastE = true
            end
        end
    end

    -- 2. KÍCH HOẠT CHIÊU THỨC TRONG BACKPACK (Nếu chiêu đó thỏa mãn điều kiện cự ly)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local slotVal = tool:FindFirstChild("abilitySlot") and tool.abilitySlot.Value:lower()
                local toolCanCast = false
                if slotVal == "q" then
                    toolCanCast = canCastQ
                elseif slotVal == "e" then
                    toolCanCast = canCastE
                else
                    local rProf = CalculateSkillRange(tool.Name, tool)
                    if rProf.isHeal then
                        toolCanCast = (healthPercent < 0.75)
                    elseif targetDist and rProf.maxCast and targetDist <= (rProf.maxCast + 0.5) then
                        toolCanCast = true
                    end
                end

                if toolCanCast then
                    local localEvt = tool:FindFirstChild("localEvent")
                    if localEvt and localEvt:IsA("BindableEvent") then
                        pcall(function() localEvt:Fire() end)
                    end
                end
            end
        end
    end

    -- 3. KÍCH HOẠT GUI BUTTON VÀ SERVER REMOTE CHO TỪNG CHIÊU THỨC RIÊNG BIỆT (CHỈ KHI TRONG TẦM VÀ THỰC SỰ CÓ CHIÊU)
    if canCastQ and skillsDebug and skillsDebug.q then
        if leftBtn then ClickButton(leftBtn) end
        if remotes and remotes:FindFirstChild("abilityCast") then
            pcall(function() remotes.abilityCast:FireServer(1) end)
        end
    end

    if canCastE and skillsDebug and skillsDebug.e then
        if rightBtn then ClickButton(rightBtn) end
        if remotes and remotes:FindFirstChild("abilityCast") then
            pcall(function() remotes.abilityCast:FireServer(2) end)
        end
    end

    -- 4. Nếu bật AutoSwapSkills VÀ cả 2 chiêu đều đang hồi rất lâu (> 3.5s): Mới đổi sang bộ kỹ năng thứ 2
    if Config.AutoSwapSkills and AreCurrentSkillsOnLongCooldown() then
        SwapAbilitySet()
    end
end


local function ProcessSmartCombat()
    if not Config.KillAura then return end
    if IsInLobby() then return end

    local root = GetRootPart()
    local hum = GetHumanoid()
    local char = LocalPlayer.Character
    if not root or not hum or hum.Health <= 0 then return end

    -- Đảm bảo hotbar luôn có đầy đủ bộ kỹ năng (không bị kẹt ở bộ skill rỗng/khuyết)
    EnsureActiveSkillSetComplete()

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

    -- 2. TÌM QUÁI VẬT MỤC TIÊU ƯU TIÊN (Ưu tiên quái nhìn thấy được & gần nhất)
    local targetMob = nil
    local shortestEffectiveDist = math.huge
    local livingMobs = #allMobs
    local isBossTarget = false

    for _, mob in ipairs(allMobs) do
        local mobHum = mob:FindFirstChildOfClass("Humanoid")
        local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
        if mobHum and mobHum.Health > 0 and mobRoot then
            local dist = (mobRoot.Position - root.Position).Magnitude
            -- Ưu tiên quái nhìn thấy được (Visible): Trừ 60 studs cự ly hiệu dụng
            -- Giúp nhân vật luôn dọn sạch quái trong cùng phòng/hành lang trước, KHÔNG BAO GIỜ bị hút vào quái sau bức tường!
            local isVis = false
            if dist < 90 then
                isVis = IsTargetVisible(root.Position, mobRoot.Position, mob)
            end
            local effectiveDist = dist - (isVis and 60 or 0)

            if effectiveDist < shortestEffectiveDist then
                shortestEffectiveDist = effectiveDist
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

    -- KIỂM TRA TẦM NHÌN (LINE OF SIGHT): QUÁI CÓ BỊ TƯỜNG CHE KHUẤT KHÔNG?
    local isTargetVis = IsTargetVisible(root.Position, mobRoot.Position, targetMob)

    -- NẾU QUÁI BỊ TƯỜNG CHE KHUẤT (NOT VISIBLE):
    -- Tuyệt đối KHÔNG chạy thẳng vào tường! KHÔNG đứng cự ly vàng hay lùi né trước bức tường!
    -- KHÔNG xả skill hay đánh thường vào tường vô ích!
    -- BẮT BUỘC DÙNG PATHFINDING TÌM ĐƯỜNG VÒNG QUA CỬA / HÀNH LANG!
    if not isTargetVis then
        State.CurrentStatus = string.format("🧭 Tìm đường qua tường tới %s (Cách: %dm)", targetMob.Name, math.floor(dist))
        FollowWaypoints(mobRoot.Position)
        return
    end

    -- 3. TÍNH TOÁN CỰ LI CHIẾN ĐẤU ĐỘNG THEO TỪNG CHIÊU THỨC & VŨ KHÍ HIỆN TẠI
    local combatProfile, activeSkillInfo, skillsDebug = GetDynamicCombatProfile(dist)
    local safeMinDist = combatProfile.minSafe or 7.0
    local safeMaxDist = combatProfile.maxCast or 9.0
    local preferredDist = combatProfile.preferred or 7.5
    local emergencyDodgeDist = combatProfile.emergencyDodge or 5.6

    -- Khi máu thấp: Tự động lùi sâu & mở rộng cự ly né tránh khẩn cấp (Emergency Distance Buffer)
    if healthPercent < 0.25 then
        safeMinDist = safeMinDist + 7
        safeMaxDist = safeMaxDist + 5
        preferredDist = preferredDist + 6
        emergencyDodgeDist = emergencyDodgeDist + 3
    elseif healthPercent < 0.45 then
        safeMinDist = safeMinDist + 4
        safeMaxDist = safeMaxDist + 4
        preferredDist = preferredDist + 4
        emergencyDodgeDist = emergencyDodgeDist + 1.5
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

    -- Bật xoay tự nhiên của Humanoid để chống giật hình (Jitter-free smooth movement)
    hum.AutoRotate = true

    -- HỆ THỐNG PHÁT HIỆN & TỰ ĐỘNG GIẢI KẸT ĐỊA HÌNH TOÀN DIỆN (UNIVERSAL ANTI-STUCK)
    -- Tự động kích hoạt ở mọi cự ly: nếu bị kẹt tường/góc cột/bậc thềm > 1.2s -> Tự động nhảy và né ra vùng thoáng
    local now = os.clock()
    local isCurrentlyStuck = false

    if not lastPlayerPos then
        lastPlayerPos = root.Position
        lastPlayerMoveTime = now
    else
        local movedDist = (root.Position - lastPlayerPos).Magnitude
        if movedDist >= 1.2 then
            lastPlayerPos = root.Position
            lastPlayerMoveTime = now
        elseif (now - lastPlayerMoveTime) > 1.2 then
            isCurrentlyStuck = true
        end
    end

    if isCurrentlyStuck then
        cachedPathWaypoints = nil
        lastPathTime = 0
        hum.Jump = true
        hum.AutoRotate = true

        -- Quét 8 hướng xung quanh để tìm khoảng không gian rộng nhất thoát hiểm
        local bestEscapeDir = nil
        local maxClearDist = 0
        local escapeAngles = {0, 45, 90, 135, 180, 225, 270, 315}
        for _, deg in ipairs(escapeAngles) do
            local rad = math.rad(deg)
            local testDir = Vector3.new(math.sin(rad), 0, math.cos(rad))
            local clear, cDist = CheckDirectionClear(root.Position, testDir, 8)
            if cDist > maxClearDist then
                maxClearDist = cDist
                bestEscapeDir = testDir
            end
        end

        if bestEscapeDir and maxClearDist > 2.0 then
            local escapeStep = math.min(5, maxClearDist - 1.2)
            SmoothMoveTo(hum, root.Position + bestEscapeDir * escapeStep, true)
            State.CurrentStatus = string.format("🚨 Tự gỡ kẹt góc tường/cột (Né ra %.1fm)", escapeStep)
        else
            hum.Jump = true
            SmoothMoveTo(hum, root.Position - root.CFrame.LookVector * 4, true)
            State.CurrentStatus = "🚨 Tự gỡ kẹt khẩn cấp (Nhảy lùi)!"
        end

        lastPlayerPos = root.Position
        lastPlayerMoveTime = now - 0.4
        return
    end

    -- Khi trong phạm vi giao chiến và có tầm nhìn trực tiếp: Xoay mặt nhìn thẳng vào quái vật
    -- (Chỉ ép CFrame khi đứng yên xả đòn; khi đang di chuyển lùi/né thì để Humanoid tự xoay chạy hết tốc độ)
    if isTargetVis and dist <= safeMaxDist and hum.MoveDirection.Magnitude < 0.1 then
        local lookAtTarget = Vector3.new(mobRoot.Position.X, root.Position.Y, mobRoot.Position.Z)
        local toMob = (lookAtTarget - root.Position)
        if toMob.Magnitude > 0.1 then
            root.CFrame = CFrame.lookAt(root.Position, lookAtTarget)
        end
    else
        hum.AutoRotate = true
    end

    -- 4. DI CHUYỂN, TIẾP CẬN & ĐI LÙI NÉ ĐÒN ĐÁNH THƯỜNG THÔNG MINH THEO CỰ LI CHIÊU
    if dist < safeMinDist then
        -- A. QUÁ GẦN: ĐI LÙI DỨT KHOÁT ĐỂ NÉ ĐÒN ĐÁNH THƯỜNG CỦA QUÁI
        local backClear, backDist = CheckDirectionClear(root.Position, awayDir, 6)
        local chosenMoveTarget = nil

        if backClear or backDist > 3.5 then
            local backStep = math.min(combatProfile.isRanged and 8 or 5, math.max(2, backDist - 1.5))
            chosenMoveTarget = root.Position + awayDir * backStep
            State.CurrentStatus = string.format("🔄 Đi lùi né đánh thường [%s] (Cách: %.1fm)", activeSkillInfo, dist)
            -- Nhảy lùi khẩn cấp chỉ khi quái áp sát nguy hiểm (có debounce 0.8s chống nhảy giật liên tục)
            if dist < emergencyDodgeDist and (now - lastJumpTime > 0.8) then
                hum.Jump = true
                lastJumpTime = now
            end
        else
            -- Phía sau vướng tường/cột: Circle-Strafe né sang bên thoáng nhất
            local leftClear, leftDist = CheckDirectionClear(root.Position, leftDir, 5)
            local rightClear, rightDist = CheckDirectionClear(root.Position, rightDir, 5)
            if leftDist >= 3.0 or rightDist >= 3.0 then
                local chosenDir = (leftDist >= rightDist) and leftDir or rightDir
                local sideStep = math.min(5, math.max(2, math.max(leftDist, rightDist) - 1.5))
                chosenMoveTarget = root.Position + chosenDir * sideStep
                State.CurrentStatus = string.format("🔄 Lùi né tường (Circle Strafe) [%s]", activeSkillInfo)
            else
                -- Bị dồn sát góc tường: Tuyệt đối KHÔNG đâm đầu vào tường! Đứng yên đối mặt quái và chém trả
                chosenMoveTarget = nil
                State.CurrentStatus = string.format("🛡️ Đứng vững đánh trả quái (Lưng tựa tường) [%s]", activeSkillInfo)
            end
        end

        if chosenMoveTarget then
            SmoothMoveTo(hum, chosenMoveTarget, true)
        end

    elseif dist <= safeMaxDist then
        -- B. CỰ LY VÀNG: Vừa xa tầm đánh của quái vừa trúng tầm skill!
        local strafePart = (strafeSign > 0) and leftDir or rightDir
        local maintainDir = (awayDir * 0.5 + strafePart * 0.5).Unit

        -- Kiểm tra xem hướng duy trì cự ly vàng có bị vướng tường không
        local dirClear, dirDist = CheckDirectionClear(root.Position, maintainDir, 4)
        local goldenTarget = nil

        if dirClear or dirDist > 3.0 then
            local step = math.min(4, math.max(1.5, dirDist - 1.5))
            goldenTarget = root.Position + maintainDir * step
            State.CurrentStatus = string.format("⚔️ Cự ly vàng [%s] (Cách: %.1fm | Quái HP: %d/%d)", activeSkillInfo, dist, enemyHp, enemyMaxHp)
        else
            -- Hướng maintain bị tường cản -> Thử strafe sang hướng ngược lại
            local altStrafe = -strafePart
            local altClear, altDist = CheckDirectionClear(root.Position, altStrafe, 4)
            if altClear or altDist > 3.0 then
                strafeSign = -strafeSign -- Đảo hướng strafe
                local step = math.min(4, math.max(1.5, altDist - 1.5))
                goldenTarget = root.Position + altStrafe * step
                State.CurrentStatus = string.format("⚔️ Đổi hướng né tường [%s]", activeSkillInfo)
            else
                -- Không còn khoảng trống: Đứng yên đối mặt quái xả skill
                goldenTarget = nil
                State.CurrentStatus = string.format("⚔️ Cự ly vàng (Đứng vững vị trí) [%s]", activeSkillInfo)
            end
        end

        if goldenTarget then
            SmoothMoveTo(hum, goldenTarget, false)
        end

    else
        -- C. Ở XA: Tiếp cận quái trong tầm nhìn trực tiếp
        State.CurrentStatus = string.format("🏃 Tiếp cận %s [%s] (Cách: %dm | HP: %d/%d)", targetMob.Name, activeSkillInfo, math.floor(dist), enemyHp, enemyMaxHp)
        SmoothMoveTo(hum, mobRoot.Position, false)
    end

    -- Chống kẹt va chạm trực diện: Nếu phát hiện có tường/cột ngay sát trước mặt (< 2.0 studs)
    local frontClear, frontDist = CheckDirectionClear(root.Position, root.CFrame.LookVector, 2.2)
    if not frontClear and frontDist < 1.8 then
        local leftClear, leftDist = CheckDirectionClear(root.Position, leftDir, 3.5)
        local rightClear, rightDist = CheckDirectionClear(root.Position, rightDir, 3.5)
        local dodgeDir = (leftDist >= rightDist) and leftDir or rightDir
        hum:MoveTo(root.Position + dodgeDir * 3)
    end

    -- 5. ĐÁNH THƯỜNG VỚI VŨ KHÍ
    local weaponAttackRange = (combatProfile.isRanged or GetEquippedWeaponRange().isRanged) and 24 or 8.5
    if dist <= weaponAttackRange then
        AttackWithWeapon(mobRoot.Position)
    end

    -- 6. XẢ SKILL THÔNG MINH (Chỉ xả khi quái nằm TRONG TẦM HIỆU LỰC của từng chiêu!)
    CastAllAbilities(isBossTarget, livingMobs, healthPercent, dist, skillsDebug)
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
        QueueReconnect()

        -- Kiểm tra nếu người chơi vừa lên cấp và đủ điều kiện mở Dungeon / Độ khó mới:
        local currentLvl = GetPlayerLevel()
        local nextDungeon, nextDiff = GetBestDungeonProgression(currentLvl)
        local isCurrentTier = (nextDungeon == State.DungeonTarget and nextDiff == (State.DifficultyTarget or Config.Difficulty))

        if Config.AutoProgressionDungeon and not isCurrentTier then
            State.CurrentStatus = string.format("🎉 Lên cấp %d! Chuyển sang mốc mới: %s (%s)...", currentLvl, nextDungeon, nextDiff)
            local returnBtn = PlayerGui:FindFirstChild("ReturnConfirmation", true) or (replayGui and replayGui:FindFirstChild("return", true))
            if returnBtn and returnBtn:IsA("GuiButton") then
                ClickButton(returnBtn)
            end
            local remotes = ReplicatedStorage:FindFirstChild("remotes")
            if remotes and remotes:FindFirstChild("returnToLobby") then
                pcall(function() remotes.returnToLobby:FireServer() end)
            end
            task.wait(2.5)
            return
        end

        State.CurrentStatus = "Chiến thắng! Đang bấm Replay trận mới..."
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
            mapLbl.Text = "🏰 Map: " .. tostring(State.DungeonTarget) .. " (" .. tostring(State.DifficultyTarget or Config.Difficulty) .. ")"
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

    -- Luồng 1: Combat, Di chuyển & Đi lùi Kiting mượt mà (Tần số 10 FPS chuẩn physics Roblox)
    task.spawn(function()
        while task.wait(0.1) do
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
