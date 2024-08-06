-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

-- Local Player
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Settings
local screenAimbotEnabled = false
local espEnabled = false
local flyEnabled = false
local noclipEnabled = false
local aimbotEnabled = false

-- Key Bindings
local aimbotKey = Enum.KeyCode.E
local screenAimbotKey = Enum.KeyCode.F
local espKey = Enum.KeyCode.T
local flyKey = Enum.KeyCode.N
local noclipKey = Enum.KeyCode.I

-- Fly Speed
local flySpeed = 50

-- Flight Variables
local flying = false

-- Functions
local function getClosestTarget()
    local closestTarget = nil
    local closestDistance = math.huge

    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player and target.Team ~= player.Team and target.Character and target.Character:FindFirstChild("Head") then
            local distance = (target.Character.Head.Position - player.Character.Head.Position).magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestTarget = target
            end
        end
    end

    return closestTarget
end

local function isTargetVisible(target)
    local head = target.Character:FindFirstChild("Head")
    if head then
        local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).unit * 500)
        local hitPart, hitPosition = workspace:FindPartOnRay(ray, player.Character)
        return not hitPart or hitPart:IsDescendantOf(target.Character)
    end
    return false
end

local function getClosestTargetOnScreen()
    local closestTarget = nil
    local closestDistance = math.huge

    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player and target.Team ~= player.Team and target.Character and target.Character:FindFirstChild("Head") then
            local headPosition, isOnScreen = Camera:WorldToViewportPoint(target.Character.Head.Position)
            if isOnScreen and isTargetVisible(target) then
                local distance = (target.Character.Head.Position - player.Character.Head.Position).magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestTarget = target
                end
            end
        end
    end

    return closestTarget
end

local function aimAt(target)
    local head = target.Character:FindFirstChild("Head")
    if head then
        local aimPosition = head.Position
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
    end
end

local function createESP(target)
    local character = target.Character
    if not character then return end

    -- Remove existing ESP if any
    local existingESP = character:FindFirstChild("ESP")
    if existingESP then
        existingESP:Destroy()
    end

    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP"
    espFolder.Parent = character

    -- Create BillboardGui for ESP outline
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = character:FindFirstChild("Head")
    billboard.Size = UDim2.new(0, 100, 0, 100) -- Adjust size as needed
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = espFolder

    -- Create the ESP outline
    local outline = Instance.new("Frame")
    outline.Size = UDim2.new(1, 0, 1, 0)
    outline.Position = UDim2.new(0, 0, 0, 0)
    outline.BackgroundTransparency = 1
    outline.BorderSizePixel = 0
    outline.Parent = billboard

    local outlineStroke = Instance.new("UIStroke")
    outlineStroke.Thickness = 5
    outlineStroke.Parent = outline

    -- Determine color based on team
    if target.Team == player.Team then
        outlineStroke.Color = Color3.fromRGB(0, 0, 255) -- Blue for teammates
    else
        outlineStroke.Color = Color3.fromRGB(255, 0, 0) -- Red for non-teammates
    end

    -- Create Background for name and health
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 1 -- Transparent background
    frame.Parent = billboard

    -- Create Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = target.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextSize = 18 -- Adjust text size as needed
    nameLabel.Parent = frame

    -- Create Health Label
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = tostring(math.floor(character:FindFirstChildOfClass("Humanoid").Health))
    healthLabel.TextColor3 = Color3.new(1, 0, 0)
    healthLabel.TextStrokeTransparency = 0.5
    healthLabel.TextSize = 18 -- Adjust text size as needed
    healthLabel.Parent = frame

    -- Update health label in real-time
    local function updateHealth()
        if character:FindFirstChildOfClass("Humanoid") then
            healthLabel.Text = tostring(math.floor(character:FindFirstChildOfClass("Humanoid").Health))
        end
    end

    -- Connect to HealthChanged event
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.HealthChanged:Connect(updateHealth)
    end

    -- Initial health update
    updateHealth()
end

local function removeESP(target)
    local espFolder = target.Character:FindFirstChild("ESP")
    if espFolder then
        espFolder:Destroy()
    end
end

local function fly()
    if flyEnabled then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "FlyBodyVelocity"
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Parent = hrp

            local bodyGyro = Instance.new("BodyGyro")
            bodyGyro.Name = "FlyBodyGyro"
            bodyGyro.CFrame = hrp.CFrame
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyGyro.P = 3000
            bodyGyro.Parent = hrp

            RunService.RenderStepped:Connect(function()
                if flyEnabled then
                    local direction = Vector3.new(0, 0, 0)
                    if flying then
                        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                            direction = direction + (Camera.CFrame.LookVector * flySpeed)
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                            direction = direction - (Camera.CFrame.LookVector * flySpeed)
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                            direction = direction - (Camera.CFrame.RightVector * flySpeed)
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                            direction = direction + (Camera.CFrame.RightVector * flySpeed)
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                            direction = direction + (Camera.CFrame.UpVector * flySpeed)
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                            direction = direction - (Camera.CFrame.UpVector * flySpeed)
                        end
                    end
                    bodyVelocity.Velocity = direction
                    bodyGyro.CFrame = Camera.CFrame
                else
                    local bv = hrp:FindFirstChild("FlyBodyVelocity")
                    if bv then bv:Destroy() end
                    local bg = hrp:FindFirstChild("FlyBodyGyro")
                    if bg then bg:Destroy() end
                end
            end)
        end
    end
end

local function noclip()
    RunService.Stepped:Connect(function()
        if noclipEnabled then
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        else
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)
end

-- Key Press Event
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == aimbotKey then
        aimbotEnabled = not aimbotEnabled
        print("Aimbot:", aimbotEnabled and "Enabled" or "Disabled")
    elseif input.KeyCode == screenAimbotKey then
        screenAimbotEnabled = not screenAimbotEnabled
        print("Screen Aimbot:", screenAimbotEnabled and "Enabled" or "Disabled")
    elseif input.KeyCode == espKey then
        espEnabled = not espEnabled
        if espEnabled then
            -- Create ESP for all players
            for _, target in pairs(Players:GetPlayers()) do
                if target ~= player then
                    createESP(target)
                end
            end
        else
            -- Remove ESP elements if disabled
            for _, target in pairs(Players:GetPlayers()) do
                if target ~= player then
                    removeESP(target)
                end
            end
        end
        print("ESP:", espEnabled and "Enabled" or "Disabled")
    elseif input.KeyCode == flyKey then
        flyEnabled = not flyEnabled
        flying = flyEnabled
        if flyEnabled then
            fly()
        end
    elseif input.KeyCode == noclipKey then
        noclipEnabled = not noclipEnabled
        noclip()
    end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getClosestTarget()
        if target then
            aimAt(target)
        end
    elseif screenAimbotEnabled then
        local target = getClosestTargetOnScreen()
        if target then
            aimAt(target)
        end
    end

    -- Update ESP elements
    if espEnabled then
        for _, target in pairs(Players:GetPlayers()) do
            if target ~= player and target.Character and target.Character:FindFirstChild("Head") then
                local espFolder = target.Character:FindFirstChild("ESP")
                if espFolder then
                    local outlineStroke = espFolder:FindFirstChildWhichIsA("UIStroke")
                    if outlineStroke then
                        if target.Team == player.Team then
                            outlineStroke.Color = Color3.fromRGB(0, 0, 255) -- Blue for teammates
                        else
                            outlineStroke.Color = Color3.fromRGB(255, 0, 0) -- Red for non-teammates
                        end
                    end
                end
            end
        end
    end
end)

-- Update ESP elements when a new player is added
Players.PlayerAdded:Connect(function(target)
    target.CharacterAdded:Connect(function(character)
        if espEnabled then
            wait(1) -- Ensure character is fully loaded
            createESP(target)
        end
    end)
end)

-- Update ESP elements when a player respawns
for _, target in pairs(Players:GetPlayers()) do
    target.CharacterAdded:Connect(function(character)
        if espEnabled then
            wait(1) -- Ensure character is fully loaded
            createESP(target)
        end
    end)
end
