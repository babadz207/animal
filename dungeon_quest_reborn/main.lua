--[[
    ========================================================================
    DUNGEON QUEST REBORN - FULL AUTO-ENTER & KAITUN AUTO-FARM
    ========================================================================
    Author: babadz207
    Repository: https://github.com/babadz207/animal
    Supported Executors: Delta, Fluxus, Synapse Z, Solara, Wave, Mobile, Emulator
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
-- AUTO RECONNECT ACROSS TELEPORTS
--------------------------------------------------------------------------------
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queue_on_teleport then
    queue_on_teleport([[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/babadz207/animal/main/dungeon_quest_reborn/main.lua"))()
    ]])
end

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------
local Config = {
    AutoEnterGame = true,     -- Tự động bấm Play và Skip Tutorial khi vào game
    AutoDungeon = true,       -- Tự động tạo phòng và Start Dungeon
    TargetDungeon = "Desert Temple", -- "Desert Temple", "Winter Outpost", "Pirate Island", v.v.
    Difficulty = "Easy",      -- "Easy", "Medium", "Hard", "Insane", "Nightmare"
    HardcoreMode = false,     -- Chế độ Hardcore (thêm kinh nghiệm / đồ hiếm)
    PrivateLobby = true,      -- Tạo phòng riêng tư để không bị phá
    
    KillAura = true,          -- Tự động bay quanh quái và tấn công
    SafeHeight = 12,          -- Khoảng cách bay an toàn trên đầu quái (God Mode)
    AutoSpamSkills = true,    -- Tự động spam toàn bộ chiêu thức (Fireball, Whirlwind...)
    AutoReplay = true,        -- Tự động bấm Replay khi thắng/thua trận
}

local State = {
    CurrentStatus = "Khởi động...",
    DungeonName = "",
    Wave = 0,
    Kills = 0,
    DungeonsDone = 0,
    StartTime = os.time(),
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
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

local function FireAllSignals(btn)
    ClickButton(btn)
end

local function GetRootPart()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

--------------------------------------------------------------------------------
-- 1. AUTO ENTER GAME (MÀN HÌNH TITLE & TUTORIAL)
--------------------------------------------------------------------------------
local function ProcessAutoEnter()
    if not Config.AutoEnterGame then return end

    -- Bấm nút Play màn hình mở đầu
    local intro = PlayerGui:FindFirstChild("introGui")
    if intro and intro.Enabled then
        local playBtn = intro:FindFirstChild("title") 
            and intro.title:FindFirstChild("Frame") 
            and intro.title.Frame:FindFirstChild("TextButton")
        if playBtn and playBtn.Visible then
            State.CurrentStatus = "Đang bấm nút Play mở đầu..."
            ClickButton(playBtn)
            task.wait(0.5)
        end
    end

    -- Tự động Skip Tutorial nếu hiện bảng xác nhận
    local tut = PlayerGui:FindFirstChild("tutorialConfirm")
    if tut and tut.Enabled then
        local skipBtn = tut:FindFirstChild("Frame")
            and tut.Frame:FindFirstChild("Frame")
            and tut.Frame.Frame:FindFirstChild("no")
            and tut.Frame.Frame.no:FindFirstChild("TextButton")
        if skipBtn then
            State.CurrentStatus = "Bỏ qua màn hướng dẫn Tutorial..."
            ClickButton(skipBtn)
            task.wait(0.5)
        end
    end
end

--------------------------------------------------------------------------------
-- 2. AUTO QUEUE & START DUNGEON (KHI Ở LOBBY)
--------------------------------------------------------------------------------
local function ProcessLobbyQueue()
    if not Config.AutoDungeon then return end
    
    local inLobby = workspace:FindFirstChild("Lobby") ~= nil
    local inGameVal = LocalPlayer:FindFirstChild("inGame") and LocalPlayer.inGame.Value
    local dungeonStarted = workspace:FindFirstChild("dungeonStarted") and workspace.dungeonStarted.Value

    if inLobby and not inGameVal and not dungeonStarted then
        local queueGui = PlayerGui:FindFirstChild("queueGui")
        local mainInterface = PlayerGui:FindFirstChild("mainInterface")

        -- Bước 1: Mở menu Play
        local playBtn = mainInterface and mainInterface:FindFirstChild("buttons") and mainInterface.buttons:FindFirstChild("playButton")
        if playBtn and (not queueGui or not queueGui.Enabled) then
            State.CurrentStatus = "Đang mở menu Dungeon..."
            ClickButton(playBtn)
            task.wait(0.6)
        end

        if queueGui and queueGui.Enabled then
            -- Bước 2: Bấm Create Dungeon nếu đang ở selectOption
            local selectOption = queueGui:FindFirstChild("selectOption")
            if selectOption and selectOption.Visible then
                local createGameBtn = selectOption:FindFirstChild("Frame") and selectOption.Frame:FindFirstChild("createGame")
                if createGameBtn then
                    State.CurrentStatus = "Chọn Tạo Phòng Dungeon..."
                    ClickButton(createGameBtn)
                    task.wait(0.6)
                end
            end

            -- Bước 3: Chọn Dungeon, Độ khó và Tạo Party trong chooseDungeon
            local choose = queueGui:FindFirstChild("chooseDungeon")
            if choose and choose.Visible then
                State.CurrentStatus = "Cấu hình Dungeon " .. Config.TargetDungeon .. "..."

                -- Chọn Dungeon
                local scroll = choose:FindFirstChild("backgroundFillLeft") and choose.backgroundFillLeft:FindFirstChild("ScrollingFrame")
                local dungBtn = scroll and scroll:FindFirstChild(Config.TargetDungeon) and scroll[Config.TargetDungeon]:FindFirstChild("TextButton")
                if dungBtn then
                    ClickButton(dungBtn)
                    task.wait(0.2)
                end

                -- Chọn Độ khó
                local rightSide = choose:FindFirstChild("backgroundFillRight")
                local diffBtn = rightSide and rightSide:FindFirstChild(Config.Difficulty) and rightSide[Config.Difficulty]:FindFirstChild("TextButton")
                if diffBtn then
                    ClickButton(diffBtn)
                    task.wait(0.2)
                end

                -- Bật Private Lobby nếu cần
                if Config.PrivateLobby then
                    local priv = choose:FindFirstChild("private") and choose.private:FindFirstChild("Frame") and choose.private.Frame:FindFirstChild("button")
                    if priv then
                        ClickButton(priv)
                        task.wait(0.1)
                    end
                end

                -- Bấm StartMain để tạo phòng
                local startMain = choose:FindFirstChild("backgroundFillMiddle") and choose.backgroundFillMiddle:FindFirstChild("startMain") and choose.backgroundFillMiddle.startMain:FindFirstChild("TextButton")
                if startMain then
                    State.CurrentStatus = "Đang tạo phòng Party..."
                    ClickButton(startMain)
                    task.wait(0.8)
                end
            end

            -- Bước 4: Khởi động trận đấu trong lobbyInfo
            local lobbyInfo = queueGui:FindFirstChild("lobbyInfo")
            if lobbyInfo and lobbyInfo.Visible then
                local startBtn = lobbyInfo:FindFirstChild("startBackground") 
                    and lobbyInfo.startBackground:FindFirstChild("startFrame") 
                    and lobbyInfo.startBackground.startFrame:FindFirstChild("startButton")
                if startBtn and startBtn.Visible then
                    State.CurrentStatus = "Bắt đầu Dungeon! Đang dịch chuyển..."
                    ClickButton(startBtn)
                    task.wait(1.5)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 3. AUTO COMBAT / KILL AURA (KHI TRONG DUNGEON)
--------------------------------------------------------------------------------
local function UseAbilities()
    if not Config.AutoSpamSkills then return end

    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char then return end

    -- Sử dụng các chiêu thức có sẵn
    local function CastTool(tool)
        if not tool then return end
        local shootEvent = tool:FindFirstChild("fireballShootEvent") or tool:FindFirstChild("spellEvent") or tool:FindFirstChild("abilityEvent")
        if shootEvent and shootEvent:IsA("RemoteEvent") then
            pcall(function()
                shootEvent:FireServer()
            end)
        end
        local localEvt = tool:FindFirstChild("localEvent")
        if localEvt and localEvt:IsA("BindableEvent") then
            pcall(function()
                localEvt:Fire()
            end)
        end
    end

    for _, t in pairs(char:GetChildren()) do
        if t:IsA("Tool") then CastTool(t) end
    end
    if backpack then
        for _, t in pairs(backpack:GetChildren()) do
            if t:IsA("Tool") then
                -- Tự equip chiêu thức hoặc kích hoạt
                pcall(function()
                    t.Parent = char
                    CastTool(t)
                end)
            end
        end
    end

    -- Sử dụng Remote abilityCast từ ReplicatedStorage
    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    if remotes and remotes:FindFirstChild("abilityCast") then
        pcall(function()
            remotes.abilityCast:FireServer(1)
            remotes.abilityCast:FireServer(2)
            remotes.abilityCast:FireServer(3)
        end)
    end
end

local function ProcessCombat()
    if not Config.KillAura then return end

    local enemiesFolder = workspace:FindFirstChild("enemies")
    if not enemiesFolder or #enemiesFolder:GetChildren() == 0 then return end

    local root = GetRootPart()
    local hum = GetHumanoid()
    if not root or not hum or hum.Health <= 0 then return end

    -- Tìm quái gần nhất còn sống
    local targetMob = nil
    local shortestDist = math.huge

    for _, mob in pairs(enemiesFolder:GetChildren()) do
        local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
        local mobHum = mob:FindFirstChildOfClass("Humanoid")
        if mobRoot and mobHum and mobHum.Health > 0 then
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
            State.CurrentStatus = "Đang diệt: " .. targetMob.Name .. " (" .. math.floor(shortestDist) .. "m)"
            
            -- Bay lơ lửng phía trên đầu quái vật (God Mode an toàn)
            local safePos = mobRoot.Position + Vector3.new(0, Config.SafeHeight, 0)
            root.CFrame = CFrame.new(safePos, mobRoot.Position)
            root.AssemblyLinearVelocity = Vector3.zero

            -- Tung chiêu liên tục
            UseAbilities()
        end
    end
end

--------------------------------------------------------------------------------
-- 4. AUTO REPLAY / CLAIM REWARD (KẾT THÚC TRẬN)
--------------------------------------------------------------------------------
local function ProcessAutoReplay()
    if not Config.AutoReplay then return end

    -- Nút Replay Dungeon
    local replayGui = PlayerGui:FindFirstChild("ReplayDungeonButton")
    if replayGui and replayGui.Enabled then
        local replayBtn = replayGui:FindFirstChild("Replay")
        if replayBtn and replayBtn.Visible then
            State.CurrentStatus = "Trận đấu kết thúc, đang Replay..."
            ClickButton(replayBtn)
            task.wait(1)
        end
    end

    -- Remote Replay
    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    if remotes and remotes:FindFirstChild("replayDungeon") then
        local rewardHolder = PlayerGui:FindFirstChild("rewardGuiHolder")
        if rewardHolder and #rewardHolder:GetChildren() > 0 then
            State.CurrentStatus = "Tự động nhận quà và Replay..."
            pcall(function()
                remotes.replayDungeon:FireServer()
            end)
            task.wait(1)
        end
    end
end

--------------------------------------------------------------------------------
-- 5. ANTI-AFK (CHỐNG BỊ KICK 20 PHÚT)
--------------------------------------------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
    print("[DungeonQuest] Anti-AFK triggered successfully.")
end)

--------------------------------------------------------------------------------
-- 6. LIVE UI DASHBOARD (GIAO DIỆN THEO DÕI)
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
    frame.Size = UDim2.new(0, 280, 0, 190)
    frame.Position = UDim2.new(0.02, 0, 0.25, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 170, 0)
    stroke.Thickness = 2
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 32)
    title.Text = "⚔️ DUNGEON QUEST KAITUN"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 185, 45)
    title.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
    title.BorderSizePixel = 0
    title.Parent = frame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 24)
    statusLabel.Position = UDim2.new(0, 10, 0, 40)
    statusLabel.Text = "Trạng thái: Khởi động..."
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 12
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.BackgroundTransparency = 1
    statusLabel.Parent = frame

    local dungeonLabel = Instance.new("TextLabel")
    dungeonLabel.Size = UDim2.new(1, -20, 0, 24)
    dungeonLabel.Position = UDim2.new(0, 10, 0, 68)
    dungeonLabel.Text = "Màn chơi: " .. Config.TargetDungeon .. " (" .. Config.Difficulty .. ")"
    dungeonLabel.Font = Enum.Font.Gotham
    dungeonLabel.TextSize = 11
    dungeonLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    dungeonLabel.TextXAlignment = Enum.TextXAlignment.Left
    dungeonLabel.BackgroundTransparency = 1
    dungeonLabel.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -20, 0, 34)
    toggleBtn.Position = UDim2.new(0, 10, 0, 140)
    toggleBtn.Text = "AUTO-FARM: ĐANG BẬT [ON]"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 12
    toggleBtn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        Config.AutoDungeon = not Config.AutoDungeon
        Config.KillAura = Config.AutoDungeon
        if Config.AutoDungeon then
            toggleBtn.Text = "AUTO-FARM: ĐANG BẬT [ON]"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        else
            toggleBtn.Text = "AUTO-FARM: ĐÃ TẮT [OFF]"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            State.CurrentStatus = "Đang tạm dừng..."
        end
    end)

    -- Update loop UI
    task.spawn(function()
        while task.wait(0.3) do
            if not frame or not frame.Parent then break end
            statusLabel.Text = "📌 " .. tostring(State.CurrentStatus)
            local inDung = workspace:FindFirstChild("dungeonStarted") and workspace.dungeonStarted.Value
            if inDung then
                local wave = workspace:FindFirstChild("currentWave") and workspace.currentWave.Value or 0
                local enemiesCount = workspace:FindFirstChild("enemies") and #workspace.enemies:GetChildren() or 0
                dungeonLabel.Text = string.format("⚔️ Wave: %d | Quái còn lại: %d", wave, enemiesCount)
            else
                dungeonLabel.Text = "🏰 Ở sảnh: " .. Config.TargetDungeon .. " (" .. Config.Difficulty .. ")"
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------
local function MainLoop()
    CreateDashboard()

    task.spawn(function()
        while task.wait(0.4) do
            pcall(ProcessAutoEnter)
            pcall(ProcessLobbyQueue)
            pcall(ProcessCombat)
            pcall(ProcessAutoReplay)
        end
    end)
end

MainLoop()
print("[DungeonQuest] Kaitun Auto-Farm fully initialized!")
