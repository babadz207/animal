-- =================================================================
-- 👑 PS99 - GOLDEN/RAINBOW PET CRAFT & 500-STUD CLICKER HUB
-- =================================================================

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

getgenv().AutoDetectBreakables = false

-- Xóa UI cũ nếu có
if CoreGui:FindFirstChild("PS99VerifiedHubUI") then
    CoreGui.PS99VerifiedHubUI:Destroy()
end

-- 📍 HÀM MÔ PHỎNG CÚ CHẠM MÀN HÌNH CHÍNH XÁC VÀO TỌA ĐỘ VẬT THỂ UI
local function clickGuiObject(guiObj)
    if not (guiObj and guiObj.Visible) then return end
    pcall(function()
        local absPos = guiObj.AbsolutePosition
        local absSize = guiObj.AbsoluteSize
        local centerX = absPos.X + (absSize.X / 2)
        local centerY = absPos.Y + (absSize.Y / 2) + 36 -- Cộng offset thanh điều hướng

        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.04)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    end)
end

-- 📍 HÀM TÌM VỊ TRÍ Ô VÀNG MÁY ÉP IN-GAME
local function getMachineCFrame(machineName)
    local targetPos = nil
    pcall(function()
        local things = workspace:FindFirstChild("__THINGS")
        if things then
            for _, descendant in pairs(things:GetDescendants()) do
                if descendant:IsA("Model") and (descendant.Name == machineName or string.find(descendant.Name, machineName)) then
                    local pad = descendant:FindFirstChild("Pad", true) or descendant:FindFirstChild("Circle", true) or descendant.PrimaryPart or descendant:FindFirstChildWhichIsA("BasePart", true)
                    if pad then
                        targetPos = pad.CFrame * CFrame.new(0, 3, 0)
                        break
                    end
                end
            end
        end
    end)
    return targetPos
end

-- 🟡 HÀM BẤM CHẠM MÀN HÌNH VÀO CÁC Ô PET VÀ NÚT OK! TRÊN UI
local function hardwareProcessMachineUI(machineGuiName)
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local machines = pGui and pGui:FindFirstChild("_MACHINES")
    local gui = machines and machines:FindFirstChild(machineGuiName)

    if gui and gui.Frame then
        local itemsFrame = gui.Frame:FindFirstChild("ItemsFrame")
        local usingFrame = gui.Frame:FindFirstChild("UsingFrame")
        local okBtn = usingFrame and usingFrame:FindFirstChild("Ok")

        -- 1. Chọc nút Ok! nếu đã có sẵn pet trong khay
        if okBtn then
            clickGuiObject(okBtn)
            task.wait(0.1)
        end

        -- 2. Chọc lần lượt vào các ô Pet đang hiện trên màn hình và chọc nút Ok!
        if itemsFrame and okBtn then
            for _, slot in pairs(itemsFrame:GetDescendants()) do
                if (slot:IsA("TextButton") or slot:IsA("ImageButton")) and slot.Visible and slot.Name == "ItemSlot" then
                    local fullName = string.lower(slot:GetFullName())
                    if not string.find(fullName, "huge") and not string.find(fullName, "titanic") then
                        -- Chạm ô Pet
                        clickGuiObject(slot)
                        task.wait(0.1)
                        -- Chạm nút OK! màu xanh
                        clickGuiObject(okBtn)
                        task.wait(0.15)
                    end
                end
            end
        end
    end
end

-- 🚀 TELEPORT TỚI MÁY ÉP -> CHẠM MÀN HÌNH ÉP -> TELEPORT VỀ
local function teleportAndCraft(machineName, guiName)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- 1. Lưu lại vị trí đứng ban đầu
    local oldCFrame = root.CFrame

    -- 2. Tìm vị trí Ô Vàng và Teleport tới
    local machineCFrame = getMachineCFrame(machineName)

    if machineCFrame then
        print("⚡ Teleport tới Ô Vàng " .. machineName .. "...")
        root.CFrame = machineCFrame
        task.wait(0.8) -- Chờ game mở giao diện UI
    end

    -- 3. Thực hiện chọc phần cứng vào màn hình ép Pet 3 đợt
    for loop = 1, 3 do
        hardwareProcessMachineUI(guiName)
        task.wait(0.3)
    end

    task.wait(0.5)

    -- 4. Teleport quay trở lại vị trí ban đầu!
    if oldCFrame and root then
        print("🔄 Đã ép xong! Teleport quay lại vị trí cũ!")
        root.CFrame = oldCFrame
    end
end

-- 🎨 KHUNG GIAO DIỆN CHUẨN GÓC MÀN HÌNH
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PS99VerifiedHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 195, 0, 134)
Frame.Position = UDim2.new(1, -210, 0, 45)
Frame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = Frame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(80, 95, 150)
UIStroke.Thickness = 1.5
UIStroke.Parent = Frame

-- NÚT 1: ÉP PET GOLDEN
local GoldBtn = Instance.new("TextButton")
GoldBtn.Size = UDim2.new(1, -16, 0, 36)
GoldBtn.Position = UDim2.new(0, 8, 0, 8)
GoldBtn.BackgroundColor3 = Color3.fromRGB(220, 155, 20)
GoldBtn.Text = "🟡 Ép Pet Golden Ngay"
GoldBtn.TextColor3 = Color3.fromRGB(20, 20, 30)
GoldBtn.TextSize = 12
GoldBtn.Font = Enum.Font.GothamBold
GoldBtn.Parent = Frame

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 8)
BtnCorner1.Parent = GoldBtn

GoldBtn.MouseButton1Click:Connect(function()
    GoldBtn.Text = "⏳ Teleport Ép Golden..."
    task.spawn(function()
        teleportAndCraft("GoldMachine", "GoldMachine")
        GoldBtn.Text = "🟡 Ép Pet Golden Ngay"
    end)
end)

-- NÚT 2: ÉP PET RAINBOW
local RainbowBtn = Instance.new("TextButton")
RainbowBtn.Size = UDim2.new(1, -16, 0, 36)
RainbowBtn.Position = UDim2.new(0, 8, 0, 48)
RainbowBtn.BackgroundColor3 = Color3.fromRGB(140, 55, 220)
RainbowBtn.Text = "🌈 Ép Pet Rainbow Ngay"
RainbowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RainbowBtn.TextSize = 12
RainbowBtn.Font = Enum.Font.GothamBold
RainbowBtn.Parent = Frame

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 8)
BtnCorner2.Parent = RainbowBtn

RainbowBtn.MouseButton1Click:Connect(function()
    RainbowBtn.Text = "⏳ Teleport Ép Rainbow..."
    task.spawn(function()
        teleportAndCraft("RainbowMachine", "RainbowMachine")
        RainbowBtn.Text = "🌈 Ép Pet Rainbow Ngay"
    end)
end)

-- NÚT 3: AUTO DETECT BREAKABLE
local DetectBtn = Instance.new("TextButton")
DetectBtn.Size = UDim2.new(1, -16, 0, 36)
DetectBtn.Position = UDim2.new(0, 8, 0, 88)
DetectBtn.BackgroundColor3 = Color3.fromRGB(170, 40, 50)
DetectBtn.Text = "⚡ Auto Detect Click: OFF"
DetectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DetectBtn.TextSize = 11
DetectBtn.Font = Enum.Font.GothamBold
DetectBtn.Parent = Frame

local BtnCorner3 = Instance.new("UICorner")
BtnCorner3.CornerRadius = UDim.new(0, 8)
BtnCorner3.Parent = DetectBtn

DetectBtn.MouseButton1Click:Connect(function()
    getgenv().AutoDetectBreakables = not getgenv().AutoDetectBreakables
    if getgenv().AutoDetectBreakables then
        DetectBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 85)
        DetectBtn.Text = "⚡ Auto Detect Click: ON"
    else
        DetectBtn.BackgroundColor3 = Color3.fromRGB(170, 40, 50)
        DetectBtn.Text = "⚡ Auto Detect Click: OFF"
    end
end)

-- 🔍 ENGINE TỰ ĐỘNG DETECT BREAKABLES 500 STUDS
task.spawn(function()
    while true do
        if getgenv().AutoDetectBreakables then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local things = workspace:FindFirstChild("__THINGS")
                local breakables = things and things:FindFirstChild("Breakables")
                local net = ReplicatedStorage:FindFirstChild("Network")
                local damageRemote = net and (net:FindFirstChild("Breakables_PlayerDealDamage") or net:FindFirstChild("Breakables_PlayerClick"))

                if breakables and root and damageRemote then
                    for _, model in pairs(breakables:GetChildren()) do
                        if model:IsA("Model") or model:IsA("BasePart") then
                            local id = model.Name
                            local pos = model:IsA("Model") and model:GetPivot().Position or model.Position
                            if (pos - root.Position).Magnitude <= 500 then
                                for burst = 1, 5 do
                                    damageRemote:FireServer(tostring(id))
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.03)
    end
end)
