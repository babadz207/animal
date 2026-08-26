-- =================================================================
-- 👑 ANIMAL HOSPITAL - KAITUN LIVE DASHBOARD & AUTO 24/7
-- =================================================================

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Net = ReplicatedStorage:WaitForChild("Util"):WaitForChild("Net")

getgenv().KaitunEnabled = true

local Stats = {
    CurrentStatus = "Đang khởi tạo hệ thống...",
    GemsClaimed = 0,
    PatientsHealed = 0,
    StartTime = os.time()
}

-- 🔄 AUTO TELEPORT PERSISTENCE
local queueOnTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
if queueOnTeleport then
    pcall(function()
        queueOnTeleport([[
            task.wait(2)
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/babadz207/animal/main/animal_hospital_kaitun.lua"))()
            end)
        ]])
    end)
end

-- Xóa UI cũ nếu có
if CoreGui:FindFirstChild("AnimalHospitalDashboardUI") then
    CoreGui.AnimalHospitalDashboardUI:Destroy()
end

-- 🎨 KHUNG GIAO DIỆN HIỆN ĐẠI DASHBOARD
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnimalHospitalDashboardUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 210)
MainFrame.Position = UDim2.new(1, -275, 0, 50)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 210, 140)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- TIÊU ĐỀ
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 32)
Title.BackgroundTransparency = 1
Title.Text = "👑 ANIMAL HOSPITAL - KAITUN LIVE"
Title.TextColor3 = Color3.fromRGB(0, 230, 150)
Title.TextSize = 11
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- HIỂN THỊ TRẠNG THÁI REAL-TIME
local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, -20, 0, 42)
StatusBox.Position = UDim2.new(0, 10, 0, 35)
StatusBox.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
StatusBox.BorderSizePixel = 0
StatusBox.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusBox

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -12, 1, 0)
StatusLabel.Position = UDim2.new(0, 6, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "📍 " .. Stats.CurrentStatus
StatusLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
StatusLabel.TextSize = 10
StatusLabel.TextWrapped = true
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusBox

-- HIỂN THỊ THỐNG KÊ
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -20, 0, 45)
StatsLabel.Position = UDim2.new(0, 10, 0, 82)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "💎 Gems/Rewards: 0  |  🩺 Trị Bệnh: 0\n⏱️ Thời Gian Chạy: 00:00:00"
StatsLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
StatsLabel.TextSize = 10
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.Parent = MainFrame

-- NÚT BẬT TẮT AUTO
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 34)
ToggleBtn.Position = UDim2.new(0, 10, 0, 132)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 85)
ToggleBtn.Text = "⚡ KAITUN AUTO: ON"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 11
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = MainFrame

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 8)
BtnCorner1.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().KaitunEnabled = not getgenv().KaitunEnabled
    if getgenv().KaitunEnabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 85)
        ToggleBtn.Text = "⚡ KAITUN AUTO: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 40, 50)
        ToggleBtn.Text = "⚡ KAITUN AUTO: OFF"
    end
end)

-- NÚT THU HOẠCH GEM NGAY
local ClaimBtn = Instance.new("TextButton")
ClaimBtn.Size = UDim2.new(1, -20, 0, 30)
ClaimBtn.Position = UDim2.new(0, 10, 0, 170)
ClaimBtn.BackgroundColor3 = Color3.fromRGB(210, 150, 20)
ClaimBtn.Text = "💎 Nhận Gems Sổ Sách Ngay"
ClaimBtn.TextColor3 = Color3.fromRGB(20, 20, 30)
ClaimBtn.TextSize = 10
ClaimBtn.Font = Enum.Font.GothamBold
ClaimBtn.Parent = MainFrame

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 8)
BtnCorner2.Parent = ClaimBtn

-- 🕒 CẬP NHẬT UI REAL-TIME
task.spawn(function()
    while true do
        local elapsed = os.time() - Stats.StartTime
        local hours = math.floor(elapsed / 3600)
        local mins = math.floor((elapsed % 3600) / 60)
        local secs = elapsed % 60
        local timeStr = string.format("%02d:%02d:%02d", hours, mins, secs)

        StatusLabel.Text = "📍 " .. Stats.CurrentStatus
        StatsLabel.Text = "💎 Gems/Rewards: " .. Stats.GemsClaimed .. "  |  🩺 Trị Bệnh: " .. Stats.PatientsHealed .. "\n⏱️ Thời Gian Chạy: " .. timeStr
        task.wait(0.5)
    end
end)

-- 🏠 1. CHỈ VÀO Ô TRỐNG (0 NGƯỜI) - NẾU CÓ NGƯỜI THÌ ĐỨNG BÊN NGOÀI CHỜ
local function handleLobby()
    if game.PlaceId ~= 104522435597696 then
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local roomsFolder = workspace:FindFirstChild("Rooms")
            local emptyTouchPart = nil

            if roomsFolder then
                for _, room in pairs(roomsFolder:GetChildren()) do
                    local t = room:FindFirstChild("Touch")
                    if t and t:IsA("BasePart") then
                        -- Kiểm tra xem có người chơi khác đứng gần ô này không (bán kính 12 studs)
                        local isOccupied = false
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                local dist = (p.Character.HumanoidRootPart.Position - t.Position).Magnitude
                                if dist <= 12 then
                                    isOccupied = true
                                    break
                                end
                            end
                        end

                        if not isOccupied then
                            emptyTouchPart = t
                            break
                        end
                    end
                end
            end

            -- Nếu tìm được ô hoàn toàn trống
            if emptyTouchPart then
                Stats.CurrentStatus = "⚡ Đã tìm thấy ô trống - Teleport vào xếp hàng..."
                root.CFrame = emptyTouchPart.CFrame * CFrame.new(0, 3, 0)
                task.wait(0.3)

                -- Kích hoạt START NOW
                local quickStart = Net:FindFirstChild("RE/Quickstart")
                if quickStart then
                    Stats.CurrentStatus = "🚀 Bấm START NOW vào trận ngay!"
                    quickStart:FireServer()
                end
            else
                -- Nếu tất cả các ô đều có người: Đứng bên ngoài sân chờ ô trống
                Stats.CurrentStatus = "⏳ Tất cả các ô đều có người! Đang đứng ngoài chờ ô trống..."
                local waitSpot = CFrame.new(-91.3, 22.5, -15.0) -- Vị trí đứng chờ ngoài sân
                if (root.Position - waitSpot.Position).Magnitude > 15 then
                    root.CFrame = waitSpot
                end
            end
        end)
    end
end

-- 🩺 2. MỞ KHÓA CLASS & NHẬN GEMS
local lastClassCheck = 0
local function claimGemsAndClasses()
    pcall(function()
        local claimRemote = Net:FindFirstChild("RE/ClaimBookReward")
        local equipClassRemote = Net:FindFirstChild("RE/EquipClass")

        local BookData = require(ReplicatedStorage.Data.Book)
        if claimRemote and BookData then
            for bookId, _ in pairs(BookData) do
                claimRemote:FireServer(bookId)
                Stats.GemsClaimed = Stats.GemsClaimed + 1
            end
        end

        if os.time() - lastClassCheck > 10 then
            lastClassCheck = os.time()
            local bestClasses = {"Nurse", "Secretary", "Psychologist", "Paramedic", "Doctor", "Surgeon"}
            for _, cName in ipairs(bestClasses) do
                if equipClassRemote then equipClassRemote:FireServer(cName) end
            end
        end
    end)
end

ClaimBtn.MouseButton1Click:Connect(function()
    ClaimBtn.Text = "⏳ Đang Nhận Gems..."
    claimGemsAndClasses()
    task.wait(1)
    ClaimBtn.Text = "💎 Nhận Gems Sổ Sách Ngay"
end)

-- 🏥 3. LUỒNG QUY TRÌNH CHƠI LẦN LƯỢT CHUẨN XÁC 100%:
-- BƯỚC 1: Check-in tại Bàn Tiếp Tân -> Phân biệt Bệnh Nhân Thường hay Quỷ/Dị Thường
-- BƯỚC 2: Phân tích mẫu bệnh tại Analyzer
-- BƯỚC 3: Xử lý kết quả kiểm tra tại Monitor
-- BƯỚC 4: Teleport tới Giường phẫu thuật/chữa bệnh (Apply Treatment)
local function handleMatchGameplay()
    if game.PlaceId == 104522435597696 or string.find(string.lower(game.Name), "hospital") then
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            -- BƯỚC 1: CHẠY ĐẾN BÀN TIẾP TÂN DÒ CHECK-IN BỆNH NHÂN MỚI
            local receptionPrompt = nil
            for _, descendant in pairs(workspace:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") and descendant.Enabled then
                    local act = string.lower(descendant.ActionText or "")
                    local obj = string.lower(descendant.ObjectText or "")
                    if string.find(act, "check") or string.find(act, "reception") or string.find(obj, "patient") or string.find(act, "inspect") then
                        receptionPrompt = descendant
                        break
                    end
                end
            end

            if receptionPrompt and receptionPrompt.Parent then
                Stats.CurrentStatus = "📋 BƯỚC 1: Đang Check-in Bệnh nhân tại Bàn Tiếp Tân..."
                local pos = receptionPrompt.Parent:IsA("BasePart") and receptionPrompt.Parent.CFrame or receptionPrompt.Parent:GetPivot()
                root.CFrame = pos * CFrame.new(0, 3, 0)
                task.wait(0.2)
                if fireproximityprompt then fireproximityprompt(receptionPrompt, 0) end
                task.wait(0.4)

                -- Tự động chấp nhận Bệnh Nhân Thường hoặc Xử Lý Quỷ (Skinwalker)
                local dialogRemote = Net:FindFirstChild("RE/DialogDecision")
                if dialogRemote then
                    dialogRemote:FireServer(true)
                end
            end

            -- BƯỚC 2: DÒ CÁC PHÒNG BỆNH ĐANG CÓ BỆNH NHÂN NẰM GIƯỜNG
            local activeBedPrompt = nil
            local activeAnalyzerPrompt = nil
            local activeMonitorPrompt = nil

            for _, descendant in pairs(workspace:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") and descendant.Enabled then
                    local act = string.lower(descendant.ActionText or "")
                    if string.find(act, "apply") then
                        activeBedPrompt = descendant
                    elseif string.find(act, "analyze") then
                        activeAnalyzerPrompt = descendant
                    elseif string.find(act, "process") then
                        activeMonitorPrompt = descendant
                    end
                end
            end

            -- BƯỚC 2: KHÁM BỆNH & PHÂN TÍCH MẪU TẠI ANALYZER
            if activeAnalyzerPrompt and activeAnalyzerPrompt.Parent then
                Stats.CurrentStatus = "🔬 BƯỚC 2: Phân tích mẫu bệnh nhân tại Analyzer..."
                local pos = activeAnalyzerPrompt.Parent:IsA("BasePart") and activeAnalyzerPrompt.Parent.CFrame or activeAnalyzerPrompt.Parent:GetPivot()
                root.CFrame = pos * CFrame.new(0, 3, 0)
                task.wait(0.2)
                if fireproximityprompt then fireproximityprompt(activeAnalyzerPrompt, 0) end
                task.wait(0.3)
            end

            -- BƯỚC 3: XỬ LÝ KẾT QUẢ TẠI MONITOR
            if activeMonitorPrompt and activeMonitorPrompt.Parent then
                Stats.CurrentStatus = "💻 BƯỚC 3: Xử lý kết quả khám bệnh tại Monitor..."
                local pos = activeMonitorPrompt.Parent:IsA("BasePart") and activeMonitorPrompt.Parent.CFrame or activeMonitorPrompt.Parent:GetPivot()
                root.CFrame = pos * CFrame.new(0, 3, 0)
                task.wait(0.2)
                if fireproximityprompt then fireproximityprompt(activeMonitorPrompt, 0) end
                task.wait(0.3)
            end

            -- BƯỚC 4: CHỮA BỆNH TẠI GIƯỜNG (APPLY TREATMENT)
            if activeBedPrompt and activeBedPrompt.Parent then
                Stats.CurrentStatus = "🩺 BƯỚC 4: Teleport tới Giường phẫu thuật/chữa bệnh..."
                local pos = activeBedPrompt.Parent:IsA("BasePart") and activeBedPrompt.Parent.CFrame or activeBedPrompt.Parent:GetPivot()
                root.CFrame = pos * CFrame.new(0, 3, 0)
                task.wait(0.2)
                if fireproximityprompt then
                    fireproximityprompt(activeBedPrompt, 0)
                    Stats.PatientsHealed = Stats.PatientsHealed + 1
                end
                task.wait(0.4)
            end

            -- 🛡️ MẸO SINH TỒN 1: TỰ ĐỘNG GIẢI MINIGAME OXY & NHỊP TIM
            Stats.CurrentStatus = "Đang tự giải Minigame Oxy & Nhịp Tim..."
            local hbRemote = Net:FindFirstChild("RE/HeartbeatMinigameComplete")
            local oxyRemote = Net:FindFirstChild("RE/OxygenPumpComplete")
            local payRemote = Net:FindFirstChild("RE/OxygenPumpPay")

            if hbRemote then hbRemote:FireServer(true) end
            if oxyRemote then oxyRemote:FireServer(true) end
            if payRemote then payRemote:FireServer() end

            -- 🛡️ MẸO SINH TỒN 2: TỰ ĐỘNG DÙNG TASER/SCANNER DIỆT DỊ THƯỜNG (HỒI +2 SANITY & CASH)
            local ghostRemote = Net:FindFirstChild("RE/ScannerKillGhost")
            local extRemote = Net:FindFirstChild("RE/ExtinguisherBubbleHitGhost")
            local taserRemote = Net:FindFirstChild("RE/TaserFired")
            local photoRemote = Net:FindFirstChild("RE/RevealPhoto")

            if ghostRemote then ghostRemote:FireServer() end
            if extRemote then extRemote:FireServer() end
            if taserRemote then taserRemote:FireServer() end
            if photoRemote then photoRemote:FireServer() end

            -- 🛡️ MẸO SINH TỒN 3: TỰ ĐỘNG THOÁT QUÁI DƯỚI GIƯỜNG (BED MONSTER STRUGGLE)
            local touchRemote = Net:FindFirstChild("RE/Touch")
            if touchRemote then touchRemote:FireServer() end

            local playAgain = Net:FindFirstChild("RE/PlayAgainVote")
            if playAgain then playAgain:FireServer(true) end
        end)
    end
end

-- 🔄 ENGINE KAITUN MAIN LOOP
task.spawn(function()
    while true do
        if getgenv().KaitunEnabled then
            handleLobby()
            claimGemsAndClasses()
            handleMatchGameplay()
        end
        task.wait(0.5)
    end
end)

print("👑 VERIFIED ROOM1.TOUCH LOBBY KAITUN LOADED!")
