--[[
    OPPONENT HITBOX INFLATOR v3
    - Scales EVERY OTHER player's hitbox (1x to 10x)
    - Your character stays untouched
    - Tiny foldable GUI (140px)
    - Auto-applies to new players
    - Resets perfectly on toggle OFF
    Works on: Delta, Felix, Codex, Synapse, Krnl, etc.
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local IsActive = false
local SelectedScale = 5 -- default scale (1-10)
local OriginalSizes = {} -- stores original sizes per player
local Connections = {} -- track connections for cleanup

-- Get all parts of a character
local function getAllParts(char)
    local parts = {}
    if not char then return parts end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            table.insert(parts, v)
        end
    end
    return parts
end

-- Save original sizes for a player
local function savePlayerSizes(player)
    if not player.Character then return end
    OriginalSizes[player] = {}
    for _, part in ipairs(getAllParts(player.Character)) do
        OriginalSizes[player][part] = part.Size
    end
end

-- Apply hitbox scale to a specific player
local function applyToPlayer(player, scale)
    if player == Player then return end -- Skip yourself
    if not player.Character then return end
    
    if not OriginalSizes[player] then
        savePlayerSizes(player)
    end
    
    for part, origSize in pairs(OriginalSizes[player]) do
        if part and part.Parent then
            local s = scale
            -- Make RootPart extra big for maximum hitbox
            if part.Name == "HumanoidRootPart" then
                s = scale * 1.5
            end
            part.Size = Vector3.new(origSize.X * s, origSize.Y * s, origSize.Z * s)
        end
    end
end

-- Apply to ALL other players
local function applyToAll(scale)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player then
            applyToPlayer(player, scale)
        end
    end
end

-- Reset a specific player's hitbox
local function resetPlayer(player)
    if not OriginalSizes[player] then return end
    for part, origSize in pairs(OriginalSizes[player]) do
        if part and part.Parent then
            part.Size = origSize
        end
    end
    OriginalSizes[player] = nil
end

-- Reset ALL players
local function resetAll()
    for player in pairs(OriginalSizes) do
        resetPlayer(player)
    end
    OriginalSizes = {}
end

-- Cleanup connections for a player
local function cleanupPlayer(player)
    if Connections[player] then
        Connections[player]:Disconnect()
        Connections[player] = nil
    end
end

-- Character added handler
local function onCharacterAdded(player, character)
    if player == Player then return end
    wait(0.3) -- Wait for parts to load
    if IsActive then
        savePlayerSizes(player)
        applyToPlayer(player, SelectedScale)
    end
    
    -- Watch for new parts being added (for accessories, etc.)
    local partConn = character.ChildAdded:Connect(function(child)
        if child:IsA("BasePart") and IsActive and player ~= Player then
            -- Save original size for new part
            if OriginalSizes[player] then
                OriginalSizes[player][child] = child.Size
            end
            applyToPlayer(player, SelectedScale)
        end
    end)
    Connections[player] = partConn
end

-- Player added handler
Players.PlayerAdded:Connect(function(player)
    if player == Player then return end
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Player then
        if player.Character then
            savePlayerSizes(player)
            onCharacterAdded(player, player.Character)
        end
        player.CharacterAdded:Connect(function(char)
            onCharacterAdded(player, char)
        end)
    end
end

-- ─── TINY FOLDABLE GUI (140px) ───
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HitboxInflator"
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 140, 0, 180)
    mainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    -- Glow border
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Transparency = 0.5
    stroke.Parent = mainFrame

    -- Title bar (draggable + minimize)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 26)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎯 HIT"
    titleText.TextColor3 = Color3.fromRGB(100, 220, 255)
    titleText.TextScaled = true
    titleText.Font = Enum.Font.Bangers
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 1, 0)
    minBtn.Position = UDim2.new(0.8, 0, 0, 0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextScaled = true
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Parent = titleBar

    -- Content panel
    local contentPanel = Instance.new("Frame")
    contentPanel.Size = UDim2.new(1, 0, 1, -26)
    contentPanel.Position = UDim2.new(0, 0, 0, 26)
    contentPanel.BackgroundTransparency = 1
    contentPanel.Parent = mainFrame

    -- Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.85, 0, 0, 32)
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

    -- Scale selector (1-10 slider + display)
    local scaleLabel = Instance.new("TextLabel")
    scaleLabel.Size = UDim2.new(0.5, 0, 0, 20)
    scaleLabel.Position = UDim2.new(0.075, 0, 0.27, 0)
    scaleLabel.BackgroundTransparency = 1
    scaleLabel.Text = "Scale"
    scaleLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    scaleLabel.TextScaled = true
    scaleLabel.Font = Enum.Font.GothamMedium
    scaleLabel.TextXAlignment = Enum.TextXAlignment.Left
    scaleLabel.Parent = contentPanel

    local scaleDisplay = Instance.new("TextButton")
    scaleDisplay.Size = UDim2.new(0.3, 0, 0, 24)
    scaleDisplay.Position = UDim2.new(0.6, 0, 0.27, 0)
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

    -- +/- buttons for scale
    local minusBtn = Instance.new("TextButton")
    minusBtn.Size = UDim2.new(0.2, 0, 0, 24)
    minusBtn.Position = UDim2.new(0.075, 0, 0.42, 0)
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
    plusBtn.Size = UDim2.new(0.2, 0, 0, 24)
    plusBtn.Position = UDim2.new(0.5, 0, 0.42, 0)
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

    -- Current scale display (big)
    local currentScaleText = Instance.new("TextLabel")
    currentScaleText.Size = UDim2.new(0.85, 0, 0, 30)
    currentScaleText.Position = UDim2.new(0.075, 0, 0.58, 0)
    currentScaleText.BackgroundTransparency = 1
    currentScaleText.Text = "5x"
    currentScaleText.TextColor3 = Color3.fromRGB(0, 255, 200)
    currentScaleText.TextScaled = true
    currentScaleText.Font = Enum.Font.Bangers
    currentScaleText.Parent = contentPanel

    -- ─── LOGIC ───

    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        minBtn.Text = isMinimized and "+" or "−"
        contentPanel.Visible = not isMinimized
        mainFrame.Size = isMinimized and UDim2.new(0, 140, 0, 26) or UDim2.new(0, 140, 0, 180)
    end)

    -- Toggle
    toggleBtn.MouseButton1Click:Connect(function()
        IsActive = not IsActive
        toggleBtn.Text = IsActive and "✅ ON" or "⛔ OFF"
        toggleBtn.BackgroundColor3 = IsActive and Color3.fromRGB(20, 120, 20) or Color3.fromRGB(40, 40, 60)
        
        if IsActive then
            applyToAll(SelectedScale)
        else
            resetAll()
        end
    end)

    -- Scale adjust
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

    minusBtn.MouseButton1Click:Connect(function()
        updateScale(SelectedScale - 1)
    end)

    plusBtn.MouseButton1Click:Connect(function()
        updateScale(SelectedScale + 1)
    end)

    scaleDisplay.MouseButton1Click:Connect(function()
        -- Quick set: type a number (simple dialog)
        local input = game:GetService("GuiService"):AddSelectionPrompt()
        -- Fallback: just cycle
        local nums = {1,2,3,4,5,6,7,8,9,10}
        local idx = 1
        for i,v in ipairs(nums) do
            if v == SelectedScale then idx = i end
        end
        idx = idx % 10 + 1
        updateScale(nums[idx])
    end)

    -- Dragging
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

-- Cleanup on script end (if you stop it)
local function cleanup()
    resetAll()
    for player, conn in pairs(Connections) do
        conn:Disconnect()
    end
    Connections = {}
end

-- Inject GUI
local gui = createGUI()
gui.Parent = Player.PlayerGui

print("🔥 OPPONENT HITBOX INFLATOR LOADED – Scale 1-10, target others only!")
print("💀 Your hitbox stays normal. Everyone else becomes a giant target.")

-- Optional: cleanup when GUI is destroyed
gui.AncestryChanged:Connect(function()
    if not gui.Parent then
        cleanup()
    end
end)
