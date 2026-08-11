--[[
    ULTIMATE HITBOX CHANGER
    Works on: Delta, Felix, Codex, Synapse, etc.
    Features: On/Off toggle, 4 hitbox sizes, auto-reset on respawn.
    Made by a rebel who doesn't follow rules.
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RunService = game:GetService("RunService")

-- Store original sizes for each part
local originalSizes = {}
local currentScale = 1
local isToggled = false
local gui = nil

-- Create the GUI
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ShawarmaHitboxGUI"
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 240, 0, 320)
    mainFrame.Position = UDim2.new(0.5, -120, 0.5, -160)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    -- Drop shadow / glass effect
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://131233976" -- soft shadow
    shadow.ImageTransparency = 0.6
    shadow.Parent = mainFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "⚡ shawarmadev ⚡"
    title.TextColor3 = Color3.fromRGB(255, 200, 50)
    title.TextScaled = true
    title.Font = Enum.Font.Bangers
    title.TextStrokeTransparency = 0.3
    title.Parent = mainFrame

    -- Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.8, 0, 0, 45)
    toggleBtn.Position = UDim2.new(0.1, 0, 0.18, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggleBtn.Text = "🔘 OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.BorderSizePixel = 0
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleBtn
    toggleBtn.Parent = mainFrame

    -- Hitbox size dropdown (current selected)
    local sizeDisplay = Instance.new("TextButton")
    sizeDisplay.Size = UDim2.new(0.8, 0, 0, 40)
    sizeDisplay.Position = UDim2.new(0.1, 0, 0.38, 0)
    sizeDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    sizeDisplay.Text = "📏 Normal"
    sizeDisplay.TextColor3 = Color3.fromRGB(220, 220, 255)
    sizeDisplay.TextScaled = true
    sizeDisplay.Font = Enum.Font.GothamMedium
    sizeDisplay.BorderSizePixel = 0
    local sizeCorner = Instance.new("UICorner")
    sizeCorner.CornerRadius = UDim.new(0, 8)
    sizeCorner.Parent = sizeDisplay
    sizeDisplay.Parent = mainFrame

    -- Dropdown options container (hidden initially)
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(0.8, 0, 0, 140)
    optionsFrame.Position = UDim2.new(0.1, 0, 0.55, 0)
    optionsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    optionsFrame.BackgroundTransparency = 0.2
    optionsFrame.BorderSizePixel = 0
    optionsFrame.Visible = false
    optionsFrame.ClipsDescendants = true
    optionsFrame.Parent = mainFrame
    local optCorner = Instance.new("UICorner")
    optCorner.CornerRadius = UDim.new(0, 8)
    optCorner.Parent = optionsFrame

    local sizes = {"Normal", "Large", "Huge", "Massive"}
    local sizeFactors = {1, 1.8, 2.8, 4.2}

    local function createOption(text, factor, index)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamMedium
        btn.BorderSizePixel = 0
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        btn.Parent = optionsFrame
        btn.LayoutOrder = index

        btn.MouseButton1Click:Connect(function()
            sizeDisplay.Text = "📏 " .. text
            currentScale = factor
            optionsFrame.Visible = false
            if isToggled then applyHitbox(currentScale) end
        end)
        return btn
    end

    for i, name in ipairs(sizes) do
        createOption(name, sizeFactors[i], i)
    end

    -- Toggle functionality
    toggleBtn.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        toggleBtn.Text = isToggled and "🟢 ON" or "🔘 OFF"
        toggleBtn.BackgroundColor3 = isToggled and Color3.fromRGB(30, 120, 30) or Color3.fromRGB(60, 60, 80)
        if isToggled then
            applyHitbox(currentScale)
        else
            resetHitbox()
        end
    end)

    -- Show/hide dropdown on sizeDisplay click
    sizeDisplay.MouseButton1Click:Connect(function()
        optionsFrame.Visible = not optionsFrame.Visible
    end)

    -- Close dropdown if clicking elsewhere (optional: can add a global click catcher)
    return screenGui
end

-- Apply hitbox scaling
function applyHitbox(scale)
    local char = Player.Character
    if not char then return end
    -- Save original sizes if not saved yet
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not originalSizes[part] then
                originalSizes[part] = part.Size
            end
            -- Scale from original (so it doesn't compound)
            local orig = originalSizes[part]
            part.Size = Vector3.new(orig.X * scale, orig.Y * scale, orig.Z * scale)
        end
    end
end

function resetHitbox()
    for part, origSize in pairs(originalSizes) do
        if part and part.Parent then
            part.Size = origSize
        end
    end
    -- Optionally clear dict to avoid stale entries? We keep it for later reapply.
end

-- Handle character respawn
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    originalSizes = {} -- reset cache, will rebuild on apply
    if isToggled then
        wait(0.5) -- wait for parts to load
        applyHitbox(currentScale)
    end
end)

-- Initialize GUI
gui = createGUI()
gui.Parent = Player.PlayerGui

-- Small cleaning on player leave (optional)
Player.AncestryChanged:Connect(function()
    if not Player.Parent then
        gui:Destroy()
    end
end)

print("🔥 Shawarma Hitbox Changer LOADED – Ready to dominate!")
