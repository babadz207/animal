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
                if equipClassRemote t-- 🏥 3. LUỒNG QUY TRÌNH QUẢN LÝ BỆNH NHÂN THEO THỜI GIAN THỰC (AUTO TAKE PHOTO -> STAMP FORMS -> CHECK-IN):
-- 1. ĐỨNG TẠI BÀN TIẾP TÂN CHỜ BỆNH NHÂN ĐẾN CỬA SỔ
-- 2. KHI BỆNH NHÂN ĐẾN -> CHỤP ẢNH (TAKE PHOTO) -> ĐÓNG DẤU (STAMP FORMS) -> TIẾP NHẬN
-- 3. CHỜ BỆNH NHÂN ĐI VÀO PHÒNG BỆNH -> CHUYỂN SANG PHÒNG KHÁM VÀ CHỮA BỆNH
-- 4. QUAY TRỞ LẠI BÀN TIẾP TÂN CHỜ BỆNH NHÂN TIẾP THEO

local receptionDeskCFrame = CFrame.new(-103.95, 3.10, -2.59)
local coffeeCFrame = CFrame.new(-123.77, 3.80, 10.31)

local function handleMatchGameplay()
    if game.PlaceId == 104522435597696 or string.find(string.lower(game.Name), "hospital") then
        pcall(function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            -- 🔍 DÒ TÌM PROXIMITY PROMPT ĐANG HOẠT ĐỘNG
            local activeBedPrompt = nil
            local activeAnalyzerPrompt = nil
            local activeMonitorPrompt = nil
            local activeCameraPrompt = nil
            local activeFormPrompt = nil

            -- Dò tìm Prompt Máy Ảnh (Take Photo) & Đóng Dấu (Stamp Forms)
            local checkInFolder = workspace.Misc:FindFirstChild("CheckIn")
            if checkInFolder then
                local cam = checkInFolder:FindFirstChild("Camera")
                local form = checkInFolder:FindFirstChild("Form")
                if cam then
                    local p = cam:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p and p.Enabled then activeCameraPrompt = p end
                end
                if form then
                    local p = form:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p and p.Enabled then activeFormPrompt = p end
                end
            end

            -- Dò tìm các nút trong Phòng Khám & Giường Bệnh
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

            -- 🔧 BƯỚC THỦ THUẬT: KHÔI PHỤC & TỰ ĐỘNG SỬA MÁY ẢNH NẾU BỊ HỎNG (AUTO REPAIR CAMERA)
            if checkInFolder then
                local cam = checkInFolder:FindFirstChild("Camera")
                if cam then
                    for _, p in pairs(cam:GetDescendants()) do
                        if p:IsA("ProximityPrompt") and p.Enabled then
                            local act = string.lower(p.ActionText or "")
                            if string.find(act, "fix") or string.find(act, "repair") or string.find(act, "sửa") then
                                Stats.CurrentStatus = "🔧 Máy Ảnh bị hỏng! Đang tự động sửa Máy Ảnh..."
                                root.CFrame = cam:GetPivot() * CFrame.new(0, 3, 0)
                                task.wait(0.2)
                                if fireproximityprompt then fireproximityprompt(p, 0) end
                                task.wait(0.4)
                            end
                        end
                    end
                end
            end

            -- 📌 TRƯỜNG HỢP 1: BỆNH NHÂN TỚI CỬA SỔ -> QUY TRÌNH KIỂM TRA ẢNH & CHECK-IN ĐẦY ĐỦ
            if activeCameraPrompt or activeFormPrompt then
                -- BƯỚC A: Chụp Ảnh Bệnh Nhân (Take Photo)
                if activeCameraPrompt and activeCameraPrompt.Parent then
                    Stats.CurrentStatus = "📸 1. Đang bấm Chụp Ảnh Bệnh Nhân (Take Photo)..."
                    local p = activeCameraPrompt.Parent
                    local pos = p:IsA("BasePart") and p.CFrame or p:GetPivot()
                    root.CFrame = pos * CFrame.new(0, 3, 0)
                    task.wait(0.2)
                    if fireproximityprompt then fireproximityprompt(activeCameraPrompt, 0) end
                    task.wait(0.3)
                end

                -- BƯỚC B: TỰ ĐỘNG LẬT ẢNH & KIỂM TRA ẢNH BỆNH NHÂN (REVEAL PHOTO & INSPECT)
                Stats.CurrentStatus = "🖼️ 2. Đang lật & Kiểm tra Ảnh Bệnh Nhân..."
                local revealRemote = Net:FindFirstChild("RE/RevealPhoto")
                local inspectRemote = Net:FindFirstChild("RE/InspectChanged")
                if revealRemote then revealRemote:FireServer() end
                if inspectRemote then inspectRemote:FireServer(true) end
                task.wait(0.3)

                -- BƯỚC C: ĐĂNG KÝ MÁY TÍNH & IN THẺ BỆNH NHÂN (REGISTER & PRINT BADGE)
                if checkInFolder then
                    local compModel = checkInFolder:FindFirstChild("Computer")
                    local printModel = checkInFolder:FindFirstChild("Printer")
                    local badgeModel = checkInFolder:FindFirstChild("PatientBadgeBase")

                    if compModel then
                        local p = compModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p and p.Enabled then
                            root.CFrame = compModel:GetPivot() * CFrame.new(0, 3, 0)
                            task.wait(0.15)
                            if fireproximityprompt then fireproximityprompt(p, 0) end
                        end
                    end

                    if printModel then
                        local p = printModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p and p.Enabled then
                            root.CFrame = printModel:GetPivot() * CFrame.new(0, 3, 0)
                            task.wait(0.15)
                            if fireproximityprompt then fireproximityprompt(p, 0) end
                        end
                    end

                    if badgeModel then
                        local p = badgeModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p and p.Enabled then
                            root.CFrame = badgeModel:GetPivot() * CFrame.new(0, 3, 0)
                            task.wait(0.15)
                            if fireproximityprompt then fireproximityprompt(p, 0) end
                        end
                    end
                end

                -- BƯỚC D: Đóng Dấu Hồ Sơ (Stamp Forms)
                if activeFormPrompt and activeFormPrompt.Parent then
                    Stats.CurrentStatus = "📋 4. Đang bấm Đóng Dấu Hồ Sơ (Stamp Forms)..."
                    local p = activeFormPrompt.Parent
                    local pos = p:IsA("BasePart") and p.CFrame or p:GetPivot()
                    root.CFrame = pos * CFrame.new(0, 3, 0)
                    task.wait(0.2)
                    if fireproximityprompt then fireproximityprompt(activeFormPrompt, 0) end
                    task.wait(0.3)
                end

                -- BƯỚC E: Chấp nhận Bệnh nhân
                local dialogRemote = Net:FindFirstChild("RE/DialogDecision")
                if dialogRemote then dialogRemote:FireServer(true) end

                Stats.CurrentStatus = "⏳ Đang chờ Bệnh Nhân đi vào Phòng Bệnh..."
                task.wait(1.5)

            -- 📌 TRƯỜNG HỢP 2: BỆNH NHÂN CẦN KHÁM & CHỮA TRỊ IN-ROOM (4 BƯỚC THỜI GIAN THỰC)
            elseif activeBedPrompt or activeAnalyzerPrompt or activeMonitorPrompt then
                pcall(function()
                    local medicalFolder = workspace.Rooms:FindFirstChild("Medical") or workspace.Rooms:FindFirstChild("Emergency")
                    if medicalFolder then
                        for _, room in pairs(medicalFolder:GetChildren()) do
                            local minigame = room:FindFirstChild("Minigame", true)
                            if minigame then
                                local analyzer = minigame:FindFirstChild("Analyzer")
                                local monitor = minigame:FindFirstChild("Monitor")
                                local bed = minigame:FindFirstChild("Bed") and minigame.Bed:FindFirstChild("InBed")
                                local medicineFolderInRoom = minigame:FindFirstChild("Medicine") or workspace.Rooms:FindFirstChild("Medicine", true)

                                -- 1. BƯỚC A: TELEPORT MÁY BÊN TRÁI (ANALYZER) -> XÉT NGHIỆM MẪU DNA
                                if analyzer then
                                    local p = analyzer:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if p and p.Enabled then
                                        Stats.CurrentStatus = "🔬 1. Teleport Máy Bên Trái (Analyzer) - Phân tích mẫu..."
                                        root.CFrame = analyzer:GetPivot() * CFrame.new(0, 3, 0)
                                        task.wait(0.2)
                                        if fireproximityprompt then fireproximityprompt(p, 0) end
                                        task.wait(0.3)
                                    end
                                end

                                -- 2. BƯỚC B: TELEPORT MÁY BÊN PHẢI (MONITOR) -> XỬ LÝ KẾT QUẢ & XÁC ĐỊNH BỆNH
                                if monitor then
                                    for _, p in pairs(monitor:GetChildren()) do
                                        if p:IsA("ProximityPrompt") and p.Enabled then
                                            Stats.CurrentStatus = "💻 2. Teleport Máy Bên Phải (Monitor) - Xác định bệnh nhân bị gì..."
                                            root.CFrame = monitor:GetPivot() * CFrame.new(0, 3, 0)
                                            task.wait(0.2)
                                            if fireproximityprompt then fireproximityprompt(p, 0) end
                                            task.wait(0.3)
                                        end
                                    end
                                end

                                -- 3. BƯỚC C: TELEPORT TỚI KỆ THUỐC -> LẤY ĐÚNG DỤNG CỤ Y TẾ ĐIỀU TRỊ
                                local bp = LocalPlayer:FindFirstChild("Backpack")
                                local toolCount = (bp and #bp:GetChildren() or 0) + (char and #char:GetChildren() or 0)
                                
                                if toolCount < 3 and medicineFolderInRoom then
                                    for _, medModel in pairs(medicineFolderInRoom:GetChildren()) do
                                        local medPrompt = medModel:FindFirstChildWhichIsA("ProximityPrompt", true)
                                        if medPrompt and medPrompt.Enabled then
                                            Stats.CurrentStatus = "💊 3. Teleport tới Kệ Thuốc (" .. medModel.Name .. ") - Lấy dụng cụ y tế..."
                                            local pos = medModel:IsA("BasePart") and medModel.CFrame or medModel:GetPivot()
                                            root.CFrame = pos * CFrame.new(0, 3, 0)
                                            task.wait(0.2)
                                            if fireproximityprompt then fireproximityprompt(medPrompt, 0) end
                                            task.wait(0.3)
                                            break
                                        end
                                    end
                                end

                                -- 4. BƯỚC D: TELEPORT GIƯỜNG BỆNH -> PHẪU THUẬT & CHỮA TRỊ (APPLY TREATMENT)
                                if bed then
                                    local p = bed:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if p and p.Enabled then
                                        Stats.CurrentStatus = "🩺 4. Teleport tới Giường Bệnh - Chữa trị bệnh nhân..."
                                        root.CFrame = bed:IsA("BasePart") and bed.CFrame or bed:GetPivot() * CFrame.new(0, 3, 0)
                                        task.wait(0.2)
                                        if fireproximityprompt then
                                            fireproximityprompt(p, 0)
                                            Stats.PatientsHealed = Stats.PatientsHealed + 1
                                        end
                                        task.wait(0.4)
                                    end
                                end
                            end
                        end
                    end
                end)

            -- 📌 TRƯỜNG HỢP 3: CHƯA CÓ BỆNH NHÂN NÀO -> ĐỨNG TẠI BÀN TIẾP TÂN NGHỈ VÀ CHỜ
            else
                Stats.CurrentStatus = "⏳ 1. Đang đứng tại Bàn Tiếp Tân chờ Bệnh Nhân mới đến..."
                if (root.Position - receptionDeskCFrame.Position).Magnitude > 8 then
                    root.CFrame = receptionDeskCFrame
                end
            end

            -- ☕ TỰ ĐỘNG UỐNG CÀ PHÊ DUY TRÌ SANITY 100%
            local coffeeRemote = Net:FindFirstChild("RE/ApplySpeedEffect")
            if coffeeRemote then coffeeRemote:FireServer("Coffee") end

            local coffeeModel = workspace.Misc:FindFirstChild("CoffeeMachine")
            local coffeePrompt = coffeeModel and coffeeModel:FindFirstChildWhichIsA("ProximityPrompt", true)
            if coffeePrompt and coffeePrompt.Enabled then
                if fireproximityprompt then fireproximityprompt(coffeePrompt, 0) end
            end

            -- 👾 TỰ ĐỘNG THOÁT KHỎI QUÁI VẬT BẮT / GIẪY GIỤA THOÁT CẦU (AUTO ESCAPE MONSTER GRAB)
            local touchRemote = Net:FindFirstChild("RE/Touch")
            local controlRemote = Net:FindFirstChild("RE/ControlEnableSwitch")
            local outGhostRemote = Net:FindFirstChild("RE/OutGhost")
            local selfReviveRemote = Net:FindFirstChild("RF/TrySelfRevive")

            if touchRemote then touchRemote:FireServer() end
            if controlRemote then controlRemote:FireServer(true) end
            if outGhostRemote then outGhostRemote:FireServer() end
            if selfReviveRemote then pcall(function() selfReviveRemote:InvokeServer() end) end

            -- Dò tìm nút Giãy Giụa / Struggle / Escape khi bị Quái túm
            for _, desc in pairs(workspace:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled then
                    local act = string.lower(desc.ActionText or "")
                    local name = string.lower(desc.Name or "")
                    if string.find(act, "struggle") or string.find(act, "escape") or string.find(act, "break") or string.find(act, "kick") or string.find(act, "resist") or string.find(name, "struggle") or string.find(name, "escape") then
                        Stats.CurrentStatus = "👾 Bị Quái Vật bắt! Đang tự động giãy giụa giải thoát..."
                        if fireproximityprompt then fireproximityprompt(desc, 0) end
                    end
                end
            end

            -- 🛡️ TỰ ĐỘNG BẮN TASER/SCANNER DIỆT QUÁI BẮT (HỒI +2 SANITY)
            local ghostRemote = Net:FindFirstChild("RE/ScannerKillGhost")
            local extRemote = Net:FindFirstChild("RE/ExtinguisherBubbleHitGhost")
            local taserRemote = Net:FindFirstChild("RE/TaserFired")

            if ghostRemote then ghostRemote:FireServer() end
            if extRemote then extRemote:FireServer() end
            if taserRemote then taserRemote:FireServer() end

            local playAgain = Net:FindFirstChild("RE/PlayAgainVote")
            if playAgain then playAgain:FireServer(true) end
        end)
    end
end       local ghostRemote = Net:FindFirstChild("RE/ScannerKillGhost")
            local extRemote = Net:FindFirstChild("RE/ExtinguisherBubbleHitGhost")
            local taserRemote = Net:FindFirstChild("RE/TaserFired")
            local touchRemote = Net:FindFirstChild("RE/Touch")

            if ghostRemote then ghostRemote:FireServer() end
            if extRemote then extRemote:FireServer() end
            if taserRemote then taserRemote:FireServer() end
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
