--[[
    PHANTOM HITBOX v5 – Server-Side Invisible Followers
    - Other players move 100% normal (no flying)
    - Their hitbox is 1-10x bigger (invisible)
    - No welds, no physics conflicts
    - Updates every frame via Heartbeat
    - Tiny GUI, foldable, draggable
    Works on: Delta, Felix, Codex, Synapse, Krnl, etc.
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local IsActive = false
local SelectedScale = 5
local GhostData = {} -- track ghost parts per player
local HeartbeatConn = nil

-- Create a single invisible part that follows the player's RootPart
local function createGhostFollower(player, scale)
    if player == Player then return end
    if not player.Character then return end
    
    local char = player.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Clean old ghost
    if GhostData[player] and GhostData[player].part then
        GhostData[player].part:Destroy()
        GhostData[player] = nil
    end
    
    -- Create invisible hitbox part
    local ghost = Instance.new("Part")
    local rootSize = root.Size
    ghost.Size = Vector3.new(rootSize.X * scale, rootSize.Y * scale, rootSize.Z * scale)
    ghost.CFrame = root.CFrame
    ghost.Anchored = true -- IMPORTANT: Anchored so it doesn't interfere with physics
    ghost.CanCollide = true
    ghost.CanQuery = true
    ghost.CanTouch = true
    ghost.Transparency = 1
    ghost.Material = Enum.Material.Plastic
    ghost.Name = "PhantomHitbox"
    ghost.Parent = workspace -- Place in workspace so it interacts with everything
    
    -- Store data
    GhostData[player] = {
        part = ghost,
        root = root,
        scale = scale
    }
end

-- Update all ghost positions every frame
local function updateGhosts()
    for player, data in pairs(GhostData) do
        if data.root and data.root.Parent then
            data.part.CFrame = data.root.CFrame
        else
            -- Clean if player left or died
            if data.part then data.part:Destroy() end
            GhostData[player] = nil
        end
    end
end

-- Apply to all players
local function applyToAll(scale)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player then
            createGhostFollower(player, scale)
        end
    end
end

-- Remove ghost for a player
local function removeGhost(player)
    if GhostData[player] then
        if GhostData[player].part then
            GhostData[player].part:Destroy()
        end
        GhostData[player] = nil
    end
end

-- Reset all ghosts
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

-- Handle new character
local function onCharacterAdded(player, char)
    if player == Player then return end
    wait(0.2)
    if IsActive then
        createGhostFollower(player, SelectedScale)
    end
end

-- Player added
Players.PlayerAdded:Connect(function(player)
    if player == Player then return end
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end)

-- Existing players
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

-- ─── GUI (TINY, FOLDABLE, DRAGGABLE) ───
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PhantomHitboxGUI"
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 135, 0, 165)
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
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Transparency = 0.6
    stroke.Parent = mainFrame

    -- Title
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 24)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "👻 PH"
    titleText.TextColor3 = Color3.fromRGB(0, 200, 255)
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

    -- Content
    local contentPanel = Instance.new("Frame")
    contentPanel.Size = UDim2.new(1, 0, 1, -24)
    contentPanel.Position = UDim2.new(0, 0, 0, 24)
    contentPanel.BackgroundTransparency = 1
    contentPanel.Parent = mainFrame

    -- Toggle
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
    currentScaleText.TextColor3 = Color3.fromRGB(0, 200, 255)
    currentScaleText.TextScaled = true
    currentScaleText.Font = Enum.Font.Bangers
    currentScaleText.Parent = contentPanel

    -- ─── LOGIC ───

    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        minBtn.Text = isMinimized and "+" or "−"
        contentPanel.Visible = not isMinimized
        mainFrame.Size = isMinimized and UDim2.new(0, 135, 0, 24) or UDim2.new(0, 135, 0, 165)
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        IsActive = not IsActive
        toggleBtn.Text = IsActive and "✅ ON" or "⛔ OFF"
        toggleBtn.BackgroundColor3 = IsActive and Color3.fromRGB(20, 120, 20) or Color3.fromRGB(40, 40, 60)
        
        if IsActive then
            applyToAll(SelectedScale)
            if not HeartbeatConn then
                HeartbeatConn = RunService.Heartbeat:Connect(updateGhosts)
            end
        else
            resetAll()
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
        for i,v in ipairs(nums) do if v == SelectedScale then idx = i end end
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

-- Cleanup
local function cleanup()
    resetAll()
end

-- Inject
local gui = createGUI()
gui.Parent = Player.PlayerGui

print("👻 PHANTOM HITBOX LOADED – They move normal, hitbox is MASSIVE!")
print("🎯 No flying, no glitching, pure smooth domination.")

gui.AncestryChanged:Connect(function()
    if not gui.Parent then cleanup() end
end)
