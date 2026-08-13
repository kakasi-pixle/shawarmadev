--[[
    GHOST HITBOX v4 – Invisible, Massive, Undetectable
    - Other players' VISUAL model stays normal
    - Their HITBOX becomes 1-10x bigger (invisible)
    - They move smooth as butter
    - Your hitbox untouched
    - Tiny foldable GUI
    Works on: Delta, Felix, Codex, Synapse, Krnl, etc.
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local IsActive = false
local SelectedScale = 5
local GhostParts = {} -- track invisible hitboxes per player

-- Create invisible hitbox attachments for a player
local function createGhostHitbox(player, scale)
    if player == Player then return end
    if not player.Character then return end
    
    local char = player.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Clean old ghost parts first
    if GhostParts[player] then
        for _, part in ipairs(GhostParts[player]) do
            part:Destroy()
        end
        GhostParts[player] = nil
    end
    
    local ghostGroup = {}
    local rootSize = root.Size
    
    -- Create a giant invisible hitbox around the RootPart
    local ghostBox = Instance.new("Part")
    ghostBox.Size = Vector3.new(rootSize.X * scale, rootSize.Y * scale, rootSize.Z * scale)
    ghostBox.CFrame = root.CFrame
    ghostBox.Anchored = false
    ghostBox.CanCollide = true
    ghostBox.CanQuery = true
    ghostBox.CanTouch = true
    ghostBox.Transparency = 1
    ghostBox.Material = Enum.Material.Plastic
    ghostBox.Name = "GhostHitbox"
    ghostBox.Parent = char
    
    -- Attach it to the RootPart so it follows perfectly
    local weld = Instance.new("Weld")
    weld.Part0 = root
    weld.Part1 = ghostBox
    weld.C0 = CFrame.new(0, 0, 0)
    weld.C1 = CFrame.new(0, 0, 0)
    weld.Parent = ghostBox
    
    table.insert(ghostGroup, ghostBox)
    
    -- Optionally add extra boxes for arms/legs if you want even more coverage
    local extraParts = {"Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
    for _, name in ipairs(extraParts) do
        local part = char:FindFirstChild(name)
        if part then
            local ghost = Instance.new("Part")
            local pSize = part.Size
            ghost.Size = Vector3.new(pSize.X * scale * 0.8, pSize.Y * scale * 0.8, pSize.Z * scale * 0.8)
            ghost.CFrame = part.CFrame
            ghost.Anchored = false
            ghost.CanCollide = true
            ghost.CanQuery = true
            ghost.CanTouch = true
            ghost.Transparency = 1
            ghost.Material = Enum.Material.Plastic
            ghost.Name = "GhostHitbox"
            ghost.Parent = char
            
            local weld2 = Instance.new("Weld")
            weld2.Part0 = part
            weld2.Part1 = ghost
            weld2.C0 = CFrame.new(0, 0, 0)
            weld2.C1 = CFrame.new(0, 0, 0)
            weld2.Parent = ghost
            
            table.insert(ghostGroup, ghost)
        end
    end
    
    GhostParts[player] = ghostGroup
end

-- Apply to all players
local function applyToAll(scale)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player then
            createGhostHitbox(player, scale)
        end
    end
end

-- Remove ghost hitboxes from a player
local function removeGhostHitbox(player)
    if GhostParts[player] then
        for _, part in ipairs(GhostParts[player]) do
            part:Destroy()
        end
        GhostParts[player] = nil
    end
end

-- Reset all ghost hitboxes
local function resetAll()
    for player in pairs(GhostParts) do
        removeGhostHitbox(player)
    end
    GhostParts = {}
end

-- Handle new characters
local function onCharacterAdded(player, char)
    if player == Player then return end
    wait(0.3)
    if IsActive then
        createGhostHitbox(player, SelectedScale)
    end
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

-- ─── GUI (140px, foldable, draggable) ───
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GhostHitboxGUI"
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 140, 0, 170)
    mainFrame.Position = UDim2.new(0.02, 0, 0.35, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(200, 50, 255)
    stroke.Transparency = 0.6
    stroke.Parent = mainFrame

    -- Title
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 26)
    titleBar.BackgroundTransparency = 1
    titleBar.Parent = mainFrame

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.7, 0, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "👻 GHOST"
    titleText.TextColor3 = Color3.fromRGB(200, 100, 255)
    titleText.TextScaled = true
    titleText.Font = Enum.Font.Bangers
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 1, 0)
    minBtn.Position = UDim2.new(0.8, 0, 0, 0)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextScaled = true
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Parent = titleBar

    -- Content
    local contentPanel = Instance.new("Frame")
    contentPanel.Size = UDim2.new(1, 0, 1, -26)
    contentPanel.Position = UDim2.new(0, 0, 0, 26)
    contentPanel.BackgroundTransparency = 1
    contentPanel.Parent = mainFrame

    -- Toggle
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

    -- Scale display
    local scaleLabel = Instance.new("TextLabel")
    scaleLabel.Size = UDim2.new(0.5, 0, 0, 20)
    scaleLabel.Position = UDim2.new(0.075, 0, 0.30, 0)
    scaleLabel.BackgroundTransparency = 1
    scaleLabel.Text = "Scale"
    scaleLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    scaleLabel.TextScaled = true
    scaleLabel.Font = Enum.Font.GothamMedium
    scaleLabel.TextXAlignment = Enum.TextXAlignment.Left
    scaleLabel.Parent = contentPanel

    local scaleDisplay = Instance.new("TextButton")
    scaleDisplay.Size = UDim2.new(0.3, 0, 0, 24)
    scaleDisplay.Position = UDim2.new(0.6, 0, 0.30, 0)
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
    minusBtn.Size = UDim2.new(0.2, 0, 0, 24)
    minusBtn.Position = UDim2.new(0.075, 0, 0.45, 0)
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
    plusBtn.Position = UDim2.new(0.5, 0, 0.45, 0)
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
    currentScaleText.Size = UDim2.new(0.85, 0, 0, 30)
    currentScaleText.Position = UDim2.new(0.075, 0, 0.62, 0)
    currentScaleText.BackgroundTransparency = 1
    currentScaleText.Text = "5x"
    currentScaleText.TextColor3 = Color3.fromRGB(200, 100, 255)
    currentScaleText.TextScaled = true
    currentScaleText.Font = Enum.Font.Bangers
    currentScaleText.Parent = contentPanel

    -- ─── LOGIC ───

    local isMinimized = false
    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        minBtn.Text = isMinimized and "+" or "−"
        contentPanel.Visible = not isMinimized
        mainFrame.Size = isMinimized and UDim2.new(0, 140, 0, 26) or UDim2.new(0, 140, 0, 170)
    end)

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

print("👻 GHOST HITBOX LOADED – Invisible, massive, undetectable!")
print("🎯 Other players move normally, but their hitbox is 1-10x bigger.")

gui.AncestryChanged:Connect(function()
    if not gui.Parent then cleanup() end
end)
