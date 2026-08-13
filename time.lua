--[[
    PERMANENT R6 + TOGGLEABLE HITBOX/NOCLIP v17 – FINAL CORRECT
    - ALL avatars are SMALL R6 (Classic Blocky) – ALWAYS ON
    - Hitbox = MASSIVE (1-10x) – TOGGLE ON/OFF
    - Noclip = WORKING – TOGGLE ON/OFF
    - R6 visual stays even when hitbox is OFF
    - Auto-apply to new players
    - Tiny GUI (135px)
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local IsActive = false
local SelectedScale = 5
local OriginalSizes = {}
local NoclipConn = nil
local R6Conn = nil

-- ─── GET ALL PARTS ───
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

-- ─── SAVE ORIGINAL SIZES ───
local function saveOriginalSizes(player)
    if not player.Character then return end
    OriginalSizes[player] = {}
    for _, part in ipairs(getAllParts(player.Character)) do
        OriginalSizes[player][part] = part.Size
    end
end

-- ─── APPLY HITBOX SCALE (BIG) ───
local function applyHitbox(player, scale)
    if player == Player then return end
    if not player.Character then return end
    
    if not OriginalSizes[player] then
        saveOriginalSizes(player)
    end
    
    local char = player.Character
    for part, origSize in pairs(OriginalSizes[player]) do
        if part and part.Parent then
            part.Size = Vector3.new(
                origSize.X * scale,
                origSize.Y * scale,
                origSize.Z * scale
            )
        end
    end
end

-- ─── RESET HITBOX ───
local function resetHitbox(player)
    if not OriginalSizes[player] then return end
    for part, origSize in pairs(OriginalSizes[player]) do
        if part and part.Parent then
            part.Size = origSize
        end
    end
    OriginalSizes[player] = nil
end

-- ─── APPLY TO ALL ───
local function applyToAll(scale)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player then
            applyHitbox(player, scale)
        end
    end
end

-- ─── RESET ALL ───
local function resetAll()
    for player in pairs(OriginalSizes) do
        resetHitbox(player)
    end
    OriginalSizes = {}
end

-- ─── NOCLIP ───
local function enableNoclip()
    if NoclipConn then return end
    NoclipConn = RunService.Heartbeat:Connect(function()
        if not IsActive then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Player and player.Character then
                for _, part in ipairs(getAllParts(player.Character)) do
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if NoclipConn then
        NoclipConn:Disconnect()
        NoclipConn = nil
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            for _, part in ipairs(getAllParts(player.Character)) do
                part.CanCollide = true
            end
        end
    end
end

-- ─── PERMANENT R6 (SMALL) – ALWAYS ON ───
local function forceSmallR6(player)
    if player == Player then return end
    if not player.Character then return end
    
    local char = player.Character
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Force R6
    if humanoid.RigType ~= Enum.HumanoidRigType.R6 then
        humanoid.RigType = Enum.HumanoidRigType.R6
        task.wait(0.1)
    end
    
    -- SMALL R6 sizes (VISUAL ONLY)
    local smallSizes = {
        Head = Vector3.new(1.5, 1.5, 1),
        Torso = Vector3.new(1.5, 1.7, 1),
        LeftArm = Vector3.new(0.8, 1.5, 0.8),
        RightArm = Vector3.new(0.8, 1.5, 0.8),
        LeftLeg = Vector3.new(0.8, 1.5, 0.8),
        RightLeg = Vector3.new(0.8, 1.5, 0.8)
    }
    
    for name, size in pairs(smallSizes) do
        local part = char:FindFirstChild(name)
        if not part then
            part = Instance.new("Part")
            part.Name = name
            part.Size = size
            part.Anchored = false
            part.CanCollide = true
            part.Parent = char
        else
            part.Size = size
        end
    end
    
    -- Remove accessories
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Hat") or child:IsA("Clothing") then
            child:Destroy()
        end
    end
end

-- ─── APPLY R6 TO ALL (PERMANENT) ───
local function applyR6ToAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player then
            if player.Character then
                forceSmallR6(player)
            end
        end
    end
end

-- ─── R6 OVERRIDE LOOP (PERMANENT) ───
local function enableR6Loop()
    if R6Conn then return end
    R6Conn = RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Player and player.Character then
                forceSmallR6(player)
            end
        end
    end)
end

local function disableR6Loop()
    if R6Conn then
        R6Conn:Disconnect()
        R6Conn = nil
    end
end

-- ─── HANDLE NEW CHARACTERS ───
local function onCharacterAdded(player, char)
    if player == Player then return end
    task.wait(0.2)
    -- R6 is ALWAYS applied
    forceSmallR6(player)
    if IsActive then
        saveOriginalSizes(player)
        applyHitbox(player, SelectedScale)
    end
end

-- ─── PLAYER ADDED ───
Players.PlayerAdded:Connect(function(player)
    if player == Player then return end
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end)

-- ─── EXISTING PLAYERS ───
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Player then
        if player.Character then
            onCharacterAdded(player, player.Character)
        end
        player.CharacterAdded:Connect(function(char)
            onCharacterAdded(player, char)
        end)
    end
end

-- ─── START R6 LOOP (ALWAYS ON) ───
enableR6Loop()

-- ─── GUI ───
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "R6HitboxNoclipGUI"
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 135, 0, 160)
    mainFrame.Position = UDim2.new(0.02, 0, 0.35, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(0, 255, 150)
    stroke.Transparency = 0.6
    stroke.Parent = mainFrame

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 24)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎯 R6"
    titleText.TextColor3 = Color3.fromRGB(0, 255, 150)
    titleText.TextScaled = true
    titleText.Font = Enum.Font.Bangers
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 24, 1, 0)
    minBtn.Position = UDim2.new(0.8, 0, 0, 0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextScaled = true
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Parent = titleBar

    local contentPanel = Instance.new("Frame")
    contentPanel.Size = UDim2.new(1, 0, 1, -24)
    contentPanel.Position = UDim2.new(0, 0, 0, 24)
    contentPanel.BackgroundTransparency = 1
    contentPanel.Parent = mainFrame

    -- Toggle (Hitbox + Noclip)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.85, 0, 0, 30)
    toggleBtn.Position = UDim2.new(0.075, 0, 0.05, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    toggleBtn.Text = "⛔ OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamMedium
    toggleBtn.BorderSizePixel = 0
    local togCorner = Instance.new("UICorner")
    togCorner.CornerRadius = UDim.new(0, 6)
    togCorner.Parent = toggleBtn
    toggleBtn.Parent = contentPanel

    -- Scale
    local scaleLabel = Instance.new("TextLabel")
    scaleLabel.Size = UDim2.new(0.5, 0, 0, 18)
    scaleLabel.Position = UDim2.new(0.075, 0, 0.28, 0)
    scaleLabel.BackgroundTransparency = 1
    scaleLabel.Text = "Scale"
    scaleLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    scaleLabel.TextScaled = true
    scaleLabel.Font = Enum.Font.GothamMedium
    scaleLabel.TextXAlignment = Enum.TextXAlignment.Left
    scaleLabel.Parent = contentPanel

    local scaleDisplay = Instance.new("TextButton")
    scaleDisplay.Size = UDim2.new(0.3, 0, 0, 22)
    scaleDisplay.Position = UDim2.new(0.6, 0, 0.28, 0)
    scaleDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    scaleDisplay.Text = "5"
    scaleDisplay.TextColor3 = Color3.fromRGB(255, 200, 100)
    scaleDisplay.TextScaled = true
    scaleDisplay.Font = Enum.Font.GothamBold
    scaleDisplay.BorderSizePixel = 0
    local sdCorner = Instance.new("UICorner")
    sdCorner.CornerRadius = UDim.new(0, 4)
    sdCorner.Parent = scaleDisplay
    scaleDisplay.Parent = contentPanel

    local minusBtn = Instance.new("TextButton")
    minusBtn.Size = UDim2.new(0.2, 0, 0, 22)
    minusBtn.Position = UDim2.new(0.075, 0, 0.43, 0)
    minusBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    minusBtn.Text = "−"
    minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minusBtn.TextScaled = true
    minusBtn.Font = Enum.Font.GothamBold
    minusBtn.BorderSizePixel = 0
    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 4)
    mCorner.Parent = minusBtn
    minusBtn.Parent = contentPanel

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size = UDim2.new(0.2, 0, 0, 22)
    plusBtn.Position = UDim2.new(0.5, 0, 0.43, 0)
    plusBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    plusBtn.Text = "+"
    plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    plusBtn.TextScaled = true
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.BorderSizePixel = 0
    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 4)
    pCorner.Parent = plusBtn
    plusBtn.Parent = contentPanel

    local currentScaleText = Instance.new("TextLabel")
    currentScaleText.Size = UDim2.new(0.85, 0, 0, 28)
    currentScaleText.Position = UDim2.new(0.075, 0, 0.60, 0)
    currentScaleText.BackgroundTransparency = 1
    currentScaleText.Text = "5x"
    currentScaleText.TextColor3 = Color3.fromRGB(0, 255, 150)
    currentScaleText.TextScaled = true
    currentScaleText.Font = Enum.Font.Bangers
    currentScaleText.Parent = contentPanel

    -- Info text
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(0.85, 0, 0, 15)
    infoText.Position = UDim2.new(0.075, 0, 0.80, 0)
    infoText.BackgroundTransparency = 1
    infoText.Text = "R6 ALWAYS ON"
    infoText.TextColor3 = Color3.fromRGB(100, 255, 100)
    infoText.TextScaled = true
    infoText.Font = Enum.Font.GothamMedium
    infoText.Parent = contentPanel

    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        minBtn.Text = isMinimized and "+" or "−"
        contentPanel.Visible = not isMinimized
        mainFrame.Size = isMinimized and UDim2.new(0, 135, 0, 24) or UDim2.new(0, 135, 0, 160)
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        IsActive = not IsActive
        toggleBtn.Text = IsActive and "✅ ON" or "⛔ OFF"
        toggleBtn.BackgroundColor3 = IsActive and Color3.fromRGB(20, 120, 20) or Color3.fromRGB(40, 40, 60)
        
        if IsActive then
            applyToAll(SelectedScale)
            enableNoclip()
        else
            resetAll()
            disableNoclip()
        end
    end)

    local function updateScale(newScale)
        newScale = math.clamp(newScale, 1, 10)
        SelectedScale = newScale
        scaleDisplay.Text = tostring(newScale)
        currentScaleText.Text = tostring(newScale) .. "x"
        if IsActive then
            resetAll()
            applyToAll(SelectedScale)
        end
    end

    minusBtn.MouseButton1Click:Connect(function() updateScale(SelectedScale - 1) end)
    plusBtn.MouseButton1Click:Connect(function() updateScale(SelectedScale + 1) end)

    scaleDisplay.MouseButton1Click:Connect(function()
        local nums = {1,2,3,4,5,6,7,8,9,10}
        local idx = 1
        for i, v in ipairs(nums) do if v == SelectedScale then idx = i end end
        idx = idx % 10 + 1
        updateScale(nums[idx])
    end)

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

local function cleanup()
    resetAll()
    disableNoclip()
    disableR6Loop()
end

local gui = createGUI()
gui.Parent = Player.PlayerGui

print("🎯 PERMANENT R6 + TOGGLEABLE HITBOX/NOCLIP LOADED!")
print("👀 ALL avatars are SMALL R6 (Classic Blocky) – ALWAYS.")
print("💀 Hitbox = MASSIVE (1-10x) – TOGGLE ON/OFF")
print("🚶 Noclip = WORKING – TOGGLE ON/OFF")
print("🔥 R6 stays even when hitbox is OFF.")

gui.AncestryChanged:Connect(function()
    if not gui.Parent then cleanup() end
end)
