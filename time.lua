--[[
    PURE HITBOX EXPANDER v7 – Intangible, Massive, Smooth
    - Other players' avatars stay NORMAL
    - Their hitbox becomes MASSIVE (1-10x) via intangible ghost parts
    - YOU CAN WALK THROUGH THEM – no physical blockage
    - They move perfectly – no flying, no stuttering
    - Auto-applies to new players
    - Toggle ON/OFF instantly
    - Tiny GUI (135px), foldable, draggable
    Works on: Delta, Felix, Codex, Synapse, Krnl, etc.
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local IsActive = false
local SelectedScale = 5
local GhostData = {} -- tracks ghost parts per player
local HeartbeatConn = nil

-- ─── CREATE AN INTANGIBLE GHOST HITBOX FOR A PLAYER ───
local function createGhostHitbox(player, scale)
    if player == Player then return end          -- Skip yourself
    if not player.Character then return end
    
    local char = player.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Remove old ghost if exists
    if GhostData[player] then
        if GhostData[player].part then
            GhostData[player].part:Destroy()
        end
        GhostData[player] = nil
    end
    
    -- Create the invisible giant hitbox (INTANGIBLE)
    local ghost = Instance.new("Part")
    local rootSize = root.Size
    ghost.Size = Vector3.new(
        rootSize.X * scale,
        rootSize.Y * scale,
        rootSize.Z * scale
    )
    ghost.CFrame = root.CFrame
    ghost.Anchored = true                -- No physics interference
    ghost.CanCollide = false             -- YOU CAN WALK THROUGH – CRITICAL
    ghost.CanQuery = true                -- Registers for GetPartsInBounds
    ghost.CanTouch = true                -- Registers for Touch events
    ghost.Transparency = 1               -- Completely invisible
    ghost.Material = Enum.Material.Plastic
    ghost.Name = "GhostHitbox"
    ghost.Parent = workspace             -- Needs to be in workspace to interact
    
    -- Store for updating
    GhostData[player] = {
        part = ghost,
        root = root,
        scale = scale
    }
end

-- ─── UPDATE ALL GHOSTS EVERY FRAME ───
local function updateGhosts()
    for player, data in pairs(GhostData) do
        if data.root and data.root.Parent then
            -- Make ghost follow the RootPart perfectly
            data.part.CFrame = data.root.CFrame
        else
            -- Player died or left – clean up
            if data.part then
                data.part:Destroy()
            end
            GhostData[player] = nil
        end
    end
end

-- ─── APPLY TO ALL PLAYERS ───
local function applyToAll(scale)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player then
            createGhostHitbox(player, scale)
        end
    end
    -- Start heartbeat if not already running
    if not HeartbeatConn then
        HeartbeatConn = RunService.Heartbeat:Connect(updateGhosts)
    end
end

-- ─── REMOVE GHOST FOR A PLAYER ───
local function removeGhost(player)
    if GhostData[player] then
        if GhostData[player].part then
            GhostData[player].part:Destroy()
        end
        GhostData[player] = nil
    end
end

-- ─── RESET ALL GHOSTS ───
local function resetAll()
    for player in pairs(GhostData) do
        removeGhost(player)
    end
    GhostData = {}
    if HeartbeatConn then
        HeartbeatConn:Disconnect()
        HeartbeatConn = nil
    end
end

-- ─── HANDLE NEW CHARACTERS ───
local function onCharacterAdded(player, char)
    if player == Player then return end
    task.wait(0.2) -- Wait for parts to load
    if IsActive then
        createGhostHitbox(player, SelectedScale)
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

-- ─── TINY GUI (135px, FOLDABLE, DRAGGABLE) ───
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PureHitboxGUI"
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
    stroke.Color = Color3.fromRGB(0, 255, 200)
    stroke.Transparency = 0.6
    stroke.Parent = mainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 24)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎯 HIT"
    titleText.TextColor3 = Color3.fromRGB(0, 255, 200)
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

    -- Content panel
    local contentPanel = Instance.new("Frame")
    contentPanel.Size = UDim2.new(1, 0, 1, -24)
    contentPanel.Position = UDim2.new(0, 0, 0, 24)
    contentPanel.BackgroundTransparency = 1
    contentPanel.Parent = mainFrame

    -- Toggle ON/OFF
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

    -- Scale label
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

    -- Scale display
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

    -- Minus button
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

    -- Plus button
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

    -- Current scale display (big)
    local currentScaleText = Instance.new("TextLabel")
    currentScaleText.Size = UDim2.new(0.85, 0, 0, 28)
    currentScaleText.Position = UDim2.new(0.075, 0, 0.60, 0)
    currentScaleText.BackgroundTransparency = 1
    currentScaleText.Text = "5x"
    currentScaleText.TextColor3 = Color3.fromRGB(0, 255, 200)
    currentScaleText.TextScaled = true
    currentScaleText.Font = Enum.Font.Bangers
    currentScaleText.Parent = contentPanel

    -- ─── GUI LOGIC ───

    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        minBtn.Text = isMinimized and "+" or "−"
        contentPanel.Visible = not isMinimized
        mainFrame.Size = isMinimized and UDim2.new(0, 135, 0, 24) or UDim2.new(0, 135, 0, 160)
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

    -- Scale update
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
        -- Quick cycle through 1-10
        local nums = {1,2,3,4,5,6,7,8,9,10}
        local idx = 1
        for i, v in ipairs(nums) do
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

-- ─── CLEANUP ───
local function cleanup()
    resetAll()
end

-- ─── INJECT GUI ───
local gui = createGUI()
gui.Parent = Player.PlayerGui

print("🎯 PURE HITBOX EXPANDER LOADED!")
print("💀 Other players have MASSIVE hitboxes (1-10x).")
print("🚶 You can walk right through them – ZERO blockage.")
print("🔥 They move smooth, you dominate. Toggle ON/OFF anytime.")

gui.AncestryChanged:Connect(function()
    if not gui.Parent then
        cleanup()
    end
end)
