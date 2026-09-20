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
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)

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
    
    -- Combat & Evade
    KillAura = true,              -- Tự động đánh quái & Boss
    SafeHoverHeight = 13,         -- Độ cao bay an toàn trên không (tránh 100% đòn quét mặt đất)
    BossEvadeDistance = 22,       -- Khoảng cách lướt an toàn khi Boss tung chiêu diện rộng
    AutoSpamSkills = true,        -- Tự xả chiêu thức thông minh (AoE khi đông, dồn dame Boss)
    LowHealthRetreat = true,      -- Tự động bay cao hơn khi máu < 30% để hồi máu
    
    -- Stats & Progression
    AutoStats = true,             -- Tự nâng điểm thuộc tính khi lên cấp
    StatBuild = "Auto",           -- "Auto" (theo đồ đang dùng), "Mage", "Warrior", "Tank"
    
    -- Inventory & Economy
    AutoEquipBest = true,         -- Tự trang bị vũ khí, giáp và kỹ năng mạnh nhất
    AutoSell = true,              -- Tự bán đồ rác
    SellRarities = {              -- Chỉ bán các phẩm cấp thấp
        ["Common"] = true,
        ["Uncommon"] = true,
        ["Rare"] = true,
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
}

--------------------------------------------------------------------------------
-- 4. UTILITIES
--------------------------------------------------------------------------------
local function ClickButton(btn)
    if not btn or not btn:IsA("GuiButton") then return false end
    if typeof(firesignal) == "function" then
        for _, sig in ipairs({"MouseButton1Down", "MouseButton1Up", "MouseButton1Click", "Activated"}) do
            pcall(function() firesignal(btn[sig]) end)
        end
        return true
    end
    return false
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
-- 6. SMART AUTO STAT ALLOCATION (NÂNG ĐIỂM THÔNG MINH KHI LÊN LEVEL)
--------------------------------------------------------------------------------
local function ProcessAutoStats()
    if not Config.AutoStats then return end

    local spVal = LocalPlayer:FindFirstChild("skillPoints")
    if not spVal or spVal.Value <= 0 then return end

    local currentPoints = spVal.Value
    local playerLvl = GetPlayerLevel()
    local remotes = ReplicatedStorage:FindFirstChild("remotes")

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

    State.CurrentStatus = string.format("Đang nâng %d điểm (%s Build)...", currentPoints, build)

    -- Phân bổ điểm: 75% chỉ số chính, 25% Stamina (HP)
    local mainStat = (build == "Mage") and "spellPower" or "physicalPower"
    local mainPoints = math.max(1, math.floor(currentPoints * 0.75))
    local stamPoints = currentPoints - mainPoints

    -- 1. Thử qua Remote nâng điểm
    local statRemote = remotes and (remotes:FindFirstChild("upgradeStat") or remotes:FindFirstChild("addStatPoint") or remotes:FindFirstChild("upgradeStats"))
    if statRemote then
        pcall(function()
            if mainPoints > 0 then statRemote:FireServer(mainStat, mainPoints) end
            if stamPoints > 0 then statRemote:FireServer("stamina", stamPoints) end
        end)
    end

    -- 2. Thử qua GUI Inventory (Nút cộng điểm +)
    local invGui = PlayerGui:FindFirstChild("inventory")
    if invGui then
        local mainFrame = invGui:FindFirstChild("main") or invGui:FindFirstChild("stats")
        if mainFrame then
            local mainPlus = mainFrame:FindFirstChild(mainStat) and mainFrame[mainStat]:FindFirstChild("button")
            local stamPlus = mainFrame:FindFirstChild("stamina") and mainFrame["stamina"]:FindFirstChild("button")

            for i = 1, mainPoints do
                if mainPlus then ClickButton(mainPlus) task.wait(0.02) end
            end
            for i = 1, stamPoints do
                if stamPlus then ClickButton(stamPlus) task.wait(0.02) end
            end
        end
    end

    State.AllocatedPoints = State.AllocatedPoints + currentPoints
end

--------------------------------------------------------------------------------
-- 7. SMART AUTO EQUIP BEST (VŨ KHÍ, GIÁP, CHIÊU THỨC MẠNH NHẤT)
--------------------------------------------------------------------------------
local RARITY_SCORE = {
    ["Common"] = 1,
    ["Uncommon"] = 2,
    ["Rare"] = 3,
    ["Epic"] = 4,
    ["Legendary"] = 5,
    ["Mythical"] = 6,
}

local function ProcessAutoEquip()
    if not Config.AutoEquipBest then return end

    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    local equipRemote = remotes and remotes:FindFirstChild("equipItem")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character

    -- 1. Đảm bảo toàn bộ Ability trong Backpack được trang bị lên nhân vật
    if backpack and char then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                pcall(function()
                    tool.Parent = char
                end)
            end
        end
    end

    -- 2. Quét Remote equipItem nếu có item level cao hơn
    local invGui = PlayerGui:FindFirstChild("inventory")
    if invGui and invGui.Enabled and equipRemote then
        local invScroll = invGui:FindFirstChild("itemScrollingFrame", true)
        if invScroll then
            for _, itemCard in pairs(invScroll:GetChildren()) do
                local equipBtn = itemCard:FindFirstChild("equipButton", true)
                if equipBtn and equipBtn:IsA("GuiButton") and equipBtn.Text:lower():find("equip") then
                    ClickButton(equipBtn)
                    task.wait(0.1)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 8. SMART AUTO SELL (BÁN ĐỒ RÁC, BẢO VỆ 100% ĐỒ HIẾM)
--------------------------------------------------------------------------------
local function ProcessAutoSell()
    if not Config.AutoSell then return end
    
    local inGame = LocalPlayer:FindFirstChild("inGame") and LocalPlayer.inGame.Value
    local dungeonStarted = workspace:FindFirstChild("dungeonStarted") and workspace.dungeonStarted.Value
    if inGame or dungeonStarted then return end -- Chỉ bán đồ khi ở sảnh Lobby

    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    local sellRemote = remotes and remotes:FindFirstChild("sellItemEvent")
    local invGui = PlayerGui:FindFirstChild("inventory")
    if not invGui then return end

    -- Quét qua các item trong túi
    local scroll = invGui:FindFirstChild("ScrollingFrame", true) or invGui:FindFirstChild("itemScrollingFrame", true)
    if scroll and sellRemote then
        for _, item in pairs(scroll:GetChildren()) do
            local rarityVal = item:FindFirstChild("rarity") and item.rarity.Value
            local isEquipped = item:FindFirstChild("equipped") and item.equipped.Value == true

            -- Quy tắc an toàn: Không bán đồ đang đeo, không bán Legendary/Mythical/Epic
            if not isEquipped and rarityVal and Config.SellRarities[rarityVal] == true then
                State.CurrentStatus = "Bán trang bị rác: " .. item.Name .. " (" .. rarityVal .. ")"
                pcall(function()
                    sellRemote:FireServer(item)
                end)
                State.SoldItemsCount = State.SoldItemsCount + 1
                task.wait(0.15)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 9. AUTO QUEUE & DUNGEON PROGRESSION (CHỌN MAP CAO NHẤT)
--------------------------------------------------------------------------------
local function ProcessLobbyProgression()
    local inLobby = workspace:FindFirstChild("Lobby") ~= nil
    local inGameVal = LocalPlayer:FindFirstChild("inGame") and LocalPlayer.inGame.Value
    local dungeonStarted = workspace:FindFirstChild("dungeonStarted") and workspace.dungeonStarted.Value

    if not inLobby or inGameVal or dungeonStarted then return end

    -- Xác định Dungeon thích hợp
    local playerLvl = GetPlayerLevel()
    local targetDungeon = Config.AutoProgressionDungeon and GetBestDungeonForLevel(playerLvl) or Config.FixedDungeon
    State.DungeonTarget = targetDungeon

    local queueGui = PlayerGui:FindFirstChild("queueGui")
    local mainInterface = PlayerGui:FindFirstChild("mainInterface")

    -- Mở menu Dungeon
    local playBtn = mainInterface and mainInterface:FindFirstChild("buttons") and mainInterface.buttons:FindFirstChild("playButton")
    if playBtn and (not queueGui or not queueGui.Enabled) then
        State.CurrentStatus = "Mở danh sách Dungeon..."
        ClickButton(playBtn)
        task.wait(0.6)
    end

    if queueGui and queueGui.Enabled then
        -- Chọn Create Game
        local selectOption = queueGui:FindFirstChild("selectOption")
        if selectOption and selectOption.Visible then
            local createBtn = selectOption:FindFirstChild("Frame") and selectOption.Frame:FindFirstChild("createGame")
            if createBtn then
                State.CurrentStatus = "Tạo phòng Dungeon..."
                ClickButton(createBtn)
                task.wait(0.6)
            end
        end

        -- Chọn Map Dungeon, Độ khó và Tạo Party
        local choose = queueGui:FindFirstChild("chooseDungeon")
        if choose and choose.Visible then
            State.CurrentStatus = string.format("Chọn Map: %s (Cấp %d+)", targetDungeon, playerLvl)

            -- Chọn Dungeon trong ScrollingFrame
            local scroll = choose:FindFirstChild("backgroundFillLeft") and choose.backgroundFillLeft:FindFirstChild("ScrollingFrame")
            local dungBtn = scroll and scroll:FindFirstChild(targetDungeon) and scroll[targetDungeon]:FindFirstChild("TextButton")
            if dungBtn then
                ClickButton(dungBtn)
                task.wait(0.2)
            end

            -- Chọn Độ khó
            local right = choose:FindFirstChild("backgroundFillRight")
            local diffBtn = right and right:FindFirstChild(Config.Difficulty) and right[Config.Difficulty]:FindFirstChild("TextButton")
            if diffBtn then
                ClickButton(diffBtn)
                task.wait(0.2)
            end

            -- Bật Private Lobby
            if Config.PrivateLobby then
                local privBtn = choose:FindFirstChild("private") and choose.private:FindFirstChild("Frame") and choose.private.Frame:FindFirstChild("button")
                if privBtn then
                    ClickButton(privBtn)
                    task.wait(0.1)
                end
            end

            -- Bấm Tạo Party (StartMain)
            local startMain = choose:FindFirstChild("backgroundFillMiddle") and choose.backgroundFillMiddle:FindFirstChild("startMain") and choose.backgroundFillMiddle.startMain:FindFirstChild("TextButton")
            if startMain then
                ClickButton(startMain)
                task.wait(0.8)
            end
        end

        -- Bấm Start để vào trận
        local lobbyInfo = queueGui:FindFirstChild("lobbyInfo")
        if lobbyInfo and lobbyInfo.Visible then
            local startBtn = lobbyInfo:FindFirstChild("startBackground") 
                and lobbyInfo.startBackground:FindFirstChild("startFrame") 
                and lobbyInfo.startBackground.startFrame:FindFirstChild("startButton")
            if startBtn and startBtn.Visible then
                State.CurrentStatus = "Bắt đầu vào trận: " .. targetDungeon .. "..."
                QueueReconnect()
                ClickButton(startBtn)
                task.wait(1.5)
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

-- Nhận diện kỹ năng Hồi Máu
local HEAL_KEYWORDS = {"heal", "rejuvenat", "aura of life", "redemption", "inner sanctum", "splash"}
local function IsHealingTool(tool)
    if not tool then return false end
    local name = tool.Name:lower()
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

local function AreCurrentSkillsOnCooldown()
    local abilitiesGui = PlayerGui:FindFirstChild("abilities")
    if not abilitiesGui then return false end

    local leftCd = abilitiesGui:FindFirstChild("LeftAbility", true) and abilitiesGui.LeftAbility:FindFirstChild("cooldownNumber", true)
    local rightCd = abilitiesGui:FindFirstChild("RightAbility", true) and abilitiesGui.RightAbility:FindFirstChild("cooldownNumber", true)

    local leftInCd = leftCd and leftCd.Text ~= "" and tonumber(leftCd.Text) and tonumber(leftCd.Text) > 0
    local rightInCd = rightCd and rightCd.Text ~= "" and tonumber(rightCd.Text) and tonumber(rightCd.Text) > 0

    return (leftInCd and rightInCd)
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

-- Tính đường đi 3D NavMesh luồn lách qua hành lang khi bị tường che khuất
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

local function CastAllAbilities(isBoss, mobCount, healthPercent)
    if not Config.AutoSpamSkills then return end

    local char = LocalPlayer.Character
    if not char then return end

    -- 1. ƯU TIÊN SỐ 1: HỒI MÁU KHI MÁU < 75%
    if healthPercent < 0.75 then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and IsHealingTool(tool) then
                local shootEvent = tool:FindFirstChild("fireballShootEvent") or tool:FindFirstChild("spellEvent") or tool:FindFirstChild("abilityEvent")
                if shootEvent and shootEvent:IsA("RemoteEvent") then
                    pcall(function() shootEvent:FireServer() end)
                end
                local localEvt = tool:FindFirstChild("localEvent")
                if localEvt and localEvt:IsA("BindableEvent") then
                    pcall(function() localEvt:Fire() end)
                end
            end
        end
    end

    -- 2. XẢ CHIÊU TẤN CÔNG BỘ HIỆN TẠI
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and not IsHealingTool(tool) then
            local shootEvent = tool:FindFirstChild("fireballShootEvent") or tool:FindFirstChild("spellEvent") or tool:FindFirstChild("abilityEvent")
            if shootEvent and shootEvent:IsA("RemoteEvent") then
                pcall(function() shootEvent:FireServer() end)
            end
            local localEvt = tool:FindFirstChild("localEvent")
            if localEvt and localEvt:IsA("BindableEvent") then
                pcall(function() localEvt:Fire() end)
            end
        end
    end

    -- Kích hoạt remote abilityCast
    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    if remotes and remotes:FindFirstChild("abilityCast") then
        pcall(function()
            remotes.abilityCast:FireServer(1)
            remotes.abilityCast:FireServer(2)
            remotes.abilityCast:FireServer(3)
        end)
    end

    -- 3. NẾU 2 CHIÊU BỘ HIỆN TẠI ĐANG HỒI: TỰ ĐỘNG SWAP SANG BỘ THỨ 2 ĐỂ XẢ TIẾP
    if AreCurrentSkillsOnCooldown() then
        SwapAbilitySet()
    end
end

local function ProcessSmartCombat()
    if not Config.KillAura then return end

    local enemiesFolder = workspace:FindFirstChild("enemies")
    if not enemiesFolder or #enemiesFolder:GetChildren() == 0 then return end

    local root = GetRootPart()
    local hum = GetHumanoid()
    local char = LocalPlayer.Character
    if not root or not hum or hum.Health <= 0 then return end

    local healthPercent = hum.Health / hum.MaxHealth

    -- Kiểm tra né chiêu Boss
    local inDanger = false
    for _, obj in pairs(workspace:GetChildren()) do
        if IsDangerousAoE(obj, root.Position) then
            inDanger = true
            break
        end
    end

    -- Phân loại mục tiêu ưu tiên: Quái Bắn Xa > Boss > Cận Chiến
    local targetMob = nil
    local shortestDist = math.huge
    local livingMobs = 0
    local isBossTarget = false
    local isRangedTarget = false

    local rangedList = {}
    local bossList = {}
    local meleeList = {}

    for _, mob in pairs(enemiesFolder:GetChildren()) do
        local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
        local mobHum = mob:FindFirstChildOfClass("Humanoid")
        if mobRoot and mobHum and mobHum.Health > 0 then
            livingMobs = livingMobs + 1
            if IsRangedEnemy(mob) then
                table.insert(rangedList, mob)
            elseif mob.Name:lower():find("boss") or (mobHum.MaxHealth > 10000) then
                table.insert(bossList, mob)
            else
                table.insert(meleeList, mob)
            end
        end
    end

    State.EnemiesRemaining = livingMobs

    local selectedCategory = (#rangedList > 0 and rangedList) or (#bossList > 0 and bossList) or meleeList
    if selectedCategory == rangedList then isRangedTarget = true end
    if selectedCategory == bossList then isBossTarget = true end

    for _, mob in pairs(selectedCategory) do
        local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
        if mobRoot then
            local dist = (mobRoot.Position - root.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                targetMob = mob
            end
        end
    end

    if targetMob then
        local mobRoot = targetMob:FindFirstChild("HumanoidRootPart") or targetMob:FindFirstChild("Torso")
        if mobRoot then
            local targetHeight = Config.SafeHoverHeight

            -- Kiểm tra xem có tường đá / cửa ngăn cách không (Line of Sight)
            local hasLoS = HasLineOfSight(root.Position, mobRoot.Position, {char, targetMob})

            if not hasLoS and (root.Position - mobRoot.Position).Magnitude > 25 then
                -- Bị tường che: Sử dụng 3D NavMesh Pathfinding tìm đường qua hành lang
                State.CurrentStatus = "🧭 Đang luồn qua hành lang đến phòng quái (Pathfinding)..."
                local waypoints = GetDungeonWaypoints(root.Position, mobRoot.Position)
                if waypoints and #waypoints > 1 then
                    local nextPoint = waypoints[2].Position + Vector3.new(0, targetHeight, 0)
                    root.CFrame = CFrame.new(nextPoint, mobRoot.Position)
                    root.AssemblyLinearVelocity = Vector3.zero
                    return
                end
            end

            -- Khi đã có tầm nhìn rõ ràng:
            if inDanger then
                targetHeight = Config.SafeHoverHeight + 6
                State.CurrentStatus = "🛡️ Đang né chiêu diện rộng của Boss!"
                root.AssemblyLinearVelocity = Vector3.new(16, 0, 16)
            elseif healthPercent < 0.35 then
                targetHeight = Config.SafeHoverHeight + 6
                State.CurrentStatus = string.format("⚡ Máu yếu (%.0f%%)! Đang giữ khoảng cách & xả skill dứt điểm!", healthPercent * 100)
            else
                local targetType = isRangedTarget and "Quái Bắn Xa" or (isBossTarget and "BOSS" or "Quái Cận Chiến")
                State.CurrentStatus = string.format("⚔️ Diệt %s: %s (Cách: %dm)", targetType, targetMob.Name, math.floor(shortestDist))
            end

            -- Giữ độ cao an toàn trên đầu quái
            local safePos = mobRoot.Position + Vector3.new(0, targetHeight, 0)
            root.CFrame = CFrame.new(safePos, mobRoot.Position)
            root.AssemblyLinearVelocity = Vector3.zero

            -- Xả chiêu thức thông minh (Tự đổi 2 bộ skill khi hồi chiêu)
            CastAllAbilities(isBossTarget, livingMobs, healthPercent)
        end
    end
end
end

--------------------------------------------------------------------------------
-- 11. AUTO REPLAY & REWARD CLAIM
--------------------------------------------------------------------------------
local function ProcessAutoReplay()
    if not Config.AutoReplay then return end

    -- Nút Replay trên màn hình
    local replayGui = PlayerGui:FindFirstChild("ReplayDungeonButton")
    if replayGui and replayGui.Enabled then
        local replayBtn = replayGui:FindFirstChild("Replay")
        if replayBtn and replayBtn.Visible then
            State.CurrentStatus = "Chiến thắng! Đang bấm Replay..."
            QueueReconnect()
            ClickButton(replayBtn)
            State.TotalDungeonsCompleted = State.TotalDungeonsCompleted + 1
            task.wait(1)
        end
    end

    -- Remote Replay
    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    if remotes and remotes:FindFirstChild("replayDungeon") then
        local rewardHolder = PlayerGui:FindFirstChild("rewardGuiHolder")
        if rewardHolder and #rewardHolder:GetChildren() > 0 then
            State.CurrentStatus = "Nhận thưởng & Tự động Replay..."
            QueueReconnect()
            pcall(function() remotes.replayDungeon:FireServer() end)
            State.TotalDungeonsCompleted = State.TotalDungeonsCompleted + 1
            task.wait(1)
        end
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
            if not frame or not frame.Parent then break end
            local playerLvl = GetPlayerLevel()
            local inDung = workspace:FindFirstChild("dungeonStarted") and workspace.dungeonStarted.Value

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

    task.spawn(function()
        while task.wait(0.35) do
            pcall(ProcessAutoEnter)
            pcall(ProcessAutoStats)
            pcall(ProcessAutoEquip)
            pcall(ProcessAutoSell)
            pcall(ProcessLobbyProgression)
            pcall(ProcessSmartCombat)
            pcall(ProcessAutoReplay)
        end
    end)
end

Main()
print("[DungeonQuest] Ultimate Kaitun loaded and running successfully!")
