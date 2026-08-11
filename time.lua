--[[
    HITBOX XTREME v2 – By ShawarmaDev
    - Real part scaling (server-replicated hitbox)
    - Root offset for distance-based bombs
    - Collapsible, draggable, compact GUI
    - Auto-respawn handling
    Works on: Delta, Felix, Codex, Synapse, Krnl, etc.
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:FindFirstChild("HumanoidRootPart")

-- Config
local ScaleFactors = { ["Small"] = 1.8, ["Medium"] = 3.5, ["Large"] = 6.0 }
local SelectedMode = "Medium"
local IsActive = false
local IsGuiOpen = true
local OriginalSizes = {}
local RootOffset = 12 -- studs to push root forward when active

-- Helper to get all parts
local function getAllParts(char)
    local parts = {}
    if not char then return parts end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            table.insert(parts, v)
        end
    end
    return parts
end

-- Save original sizes
local function saveOriginalSizes(char)
    OriginalSizes = {}
    for _, part in ipairs(getAllParts(char)) do
        OriginalSizes[part] = part.Size
    end
end

-- Apply the scaling
local function applyHitbox(char, scale)
    if not char then return end
    if not OriginalSizes or next(OriginalSizes) == nil then
        saveOriginalSizes(char)
    end
    for part, origSize in pairs(OriginalSizes) do
        if part and part.Parent then
            local s = scale
            -- Make RootPart extra chunky to catch distance checks
            if part.Name == "HumanoidRootPart" then
                s = scale * 1.2
            end
            part.Size = Vector3.new(origSize.X * s, origSize.Y * s, origSize.Z * s)
        end
    end
    -- Root offset trick (push root forward to fake proximity)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and IsActive then
        local offset = root.CFrame.LookVector * RootOffset
        root.CFrame = root.CFrame + offset
    end
end

local function resetHitbox(char)
    if not char then return end
    for part, origSize in pairs(OriginalSizes) do
        if part and part.Parent then
            part.Size = origSize
        end
    end
    -- Reset root position offset (only if we moved it)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root:FindFirstChild("BodyPosition") then
        root.BodyPosition:Destroy()
    end
end

-- Create the compact, foldable GUI
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShawarmaHitboxPro"
    screenGui.ResetOnSpawn = false

    -- Main container (SMALLER SIZE: 180x200)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 180, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -90, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame

    -- Glass border
    local border = Instance.new("UIStroke")
    border.Thickness = 1
    border.Color = Color3.fromRGB(255, 180, 50)
    border.Transparency = 0.6
    border.Parent = mainFrame

    -- Title Bar (draggable + minimize)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "⚡ HITBOX"
    titleText.TextColor3 = Color3.fromRGB(255, 200, 80)
    titleText.TextScaled = true
    titleText.Font = Enum.Font.Bangers
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 30, 1, 0)
    minBtn.Position = UDim2.new(0.85, 0, 0, 0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextScaled = true
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Parent = titleBar

    -- Content panel (toggled by minBtn)
    local contentPanel = Instance.new("Frame")
    contentPanel.Size = UDim2.new(1, 0, 1, -30)
    contentPanel.Position = UDim2.new(0, 0, 0, 30)
    contentPanel.BackgroundTransparency = 1
    contentPanel.Parent = mainFrame

    -- Toggle (ON/OFF)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.8, 0, 0, 35)
    toggleBtn.Position = UDim2.new(0.1, 0, 0.05, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    toggleBtn.Text = "🔴 OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamMedium
    toggleBtn.BorderSizePixel = 0
    local togCorner = Instance.new("UICorner")
    togCorner.CornerRadius = UDim.new(0, 6)
    togCorner.Parent = toggleBtn
    toggleBtn.Parent = contentPanel

    -- Dropdown display (Small / Medium / Large)
    local dropDisplay = Instance.new("TextButton")
    dropDisplay.Size = UDim2.new(0.8, 0, 0, 30)
    dropDisplay.Position = UDim2.new(0.1, 0, 0.30, 0)
    dropDisplay.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    dropDisplay.Text = "📐 Medium"
    dropDisplay.TextColor3 = Color3.fromRGB(200, 200, 255)
    dropDisplay.TextScaled = true
    dropDisplay.Font = Enum.Font.GothamMedium
    dropDisplay.BorderSizePixel = 0
    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 6)
    dropCorner.Parent = dropDisplay
    dropDisplay.Parent = contentPanel

    -- Dropdown options (collapsible list)
    local optFrame = Instance.new("Frame")
    optFrame.Size = UDim2.new(0.8, 0, 0, 90)
    optFrame.Position = UDim2.new(0.1, 0, 0.48, 0)
    optFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    optFrame.BackgroundTransparency = 0.3
    optFrame.BorderSizePixel = 0
    optFrame.Visible = false
    optFrame.ClipsDescendants = true
    optFrame.Parent = contentPanel
    local optCorner = Instance.new("UICorner")
    optCorner.CornerRadius = UDim.new(0, 6)
    optCorner.Parent = optFrame

    local options = {"Small", "Medium", "Large"}
    for i, name in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamMedium
        btn.BorderSizePixel = 0
        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 4)
        bCorner.Parent = btn
        btn.Parent = optFrame
        btn.LayoutOrder = i

        btn.MouseButton1Click:Connect(function()
            SelectedMode = name
            dropDisplay.Text = "📐 " .. name
            optFrame.Visible = false
            if IsActive then
                local char = Player.Character
                if char then
                    saveOriginalSizes(char)
                    applyHitbox(char, ScaleFactors[name])
                end
            end
        end)
    end

    -- Toggle logic
    toggleBtn.MouseButton1Click:Connect(function()
        IsActive = not IsActive
        toggleBtn.Text = IsActive and "🟢 ON" or "🔴 OFF"
        toggleBtn.BackgroundColor3 = IsActive and Color3.fromRGB(30, 130, 30) or Color3.fromRGB(50, 50, 70)
        local char = Player.Character
        if not char then return end
        if IsActive then
            saveOriginalSizes(char)
            applyHitbox(char, ScaleFactors[SelectedMode])
        else
            resetHitbox(char)
        end
    end)

    -- Dropdown toggle
    dropDisplay.MouseButton1Click:Connect(function()
        optFrame.Visible = not optFrame.Visible
    end)

    -- Minimize / Expand logic
    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        minBtn.Text = isMinimized and "+" or "−"
        contentPanel.Visible = not isMinimized
        mainFrame.Size = isMinimized and UDim2.new(0, 180, 0, 30) or UDim2.new(0, 180, 0, 200)
    end)

    -- Dragging logic (title bar)
    local dragObj = { dragging = false, startPos = nil, startMouse = nil }
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragObj.dragging = true
            dragObj.startPos = mainFrame.Position
            dragObj.startMouse = input.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragObj.dragging then
            local delta = input.Position - dragObj.startMouse
            mainFrame.Position = UDim2.new(
                dragObj.startPos.X.Scale,
                dragObj.startPos.X.Offset + delta.X,
                dragObj.startPos.Y.Scale,
                dragObj.startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragObj.dragging = false
        end
    end)

    return screenGui
end

-- Character respawn handling
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:FindFirstChild("HumanoidRootPart")
    OriginalSizes = {}
    task.wait(0.3) -- Wait for parts to replicate
    if IsActive then
        saveOriginalSizes(newChar)
        applyHitbox(newChar, ScaleFactors[SelectedMode])
    end
end)

-- Inject GUI
local gui = createGUI()
gui.Parent = Player.PlayerGui

print("🔥 SHAWARMA HITBOX XTREME LOADED – Go break their physics!")
