Made By MBGAMER


-- Toggles:

-- F toggles aimbot.
-- T toggles ESP.
-- N toggles flight.
-- Z toggles auto teleport.




-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

-- Local Player
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Toggles
local aimbotEnabled = false
local espEnabled = false
local flyEnabled = false
local autoTPEnabled = false

-- Variables for flight
local flying = false
local flySpeed = 50

-- Table to store ESP BillboardGuis
local espBillboards = {}

-- Toggle Functions
function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
end

function toggleESP()
    espEnabled = not espEnabled
    if not espEnabled then
        for _, gui in pairs(espBillboards) do
            gui:Destroy()
        end
        espBillboards = {}
    end
end

function toggleFly()
    flyEnabled = not flyEnabled
    flying = flyEnabled
end

function toggleAutoTP()
    autoTPEnabled = not autoTPEnabled
end

-- Helper Functions
function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local humanoidRootPart = p.Character.HumanoidRootPart
            local screenPoint, isVisible = Camera:WorldToScreenPoint(humanoidRootPart.Position)
            if isVisible then
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(mouse.X, mouse.Y)).magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = p
                end
            end
        end
    end
    return closestPlayer
end

-- Aimbot Function
function aimbot()
    if aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local headPosition = Camera:WorldToScreenPoint(head.Position)
            mouse.X = headPosition.X
            mouse.Y = headPosition.Y
        end
    end
end

-- Function to create ESP BillboardGui
function createESPGui(targetPlayer)
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = targetPlayer.Character.HumanoidRootPart
    billboard.Size = UDim2.new(4, 0, 1.2, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true

    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1

    local outline = Instance.new("Frame", frame)
    outline.Size = UDim2.new(1, 0, 1, 0)
    outline.BackgroundTransparency = 0.7
    outline.BorderSizePixel = 0

    local healthLabel = Instance.new("TextLabel", frame)
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.new(1, 1, 1)
    healthLabel.TextStrokeTransparency = 0.5
    healthLabel.TextScaled = true
    healthLabel.Text = "Health: " .. targetPlayer.Character.Humanoid.Health

    local nameLabel = Instance.new("TextLabel", frame)
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextScaled = true
    nameLabel.Text = targetPlayer.Name

    espBillboards[targetPlayer.Name] = { Billboard = billboard, HealthLabel = healthLabel, Outline = outline }
    billboard.Parent = Camera
end

-- Function to update ESP
function updateESP()
    if espEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local humanoidRootPart = p.Character.HumanoidRootPart
                local screenPoint, isVisible = Camera:WorldToScreenPoint(humanoidRootPart.Position)
                if not espBillboards[p.Name] then
                    createESPGui(p)
                end
                local espInfo = espBillboards[p.Name]
                espInfo.Outline.BackgroundColor3 = isVisible and Color3.new(0, 1, 0) or Color3.new(1, 0, 0) -- Green if visible, red if not
                espInfo.HealthLabel.Text = "Health: " .. math.floor(p.Character.Humanoid.Health)
            end
        end
    end
end

-- Fly Function
function fly()
    if flying then
        local moveDirection = Vector3.new()
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + Camera.CFrame.RightVector
        end
        
        player.Character.HumanoidRootPart.Velocity = moveDirection.Unit * flySpeed
    end
end

-- Auto TP Function
function autoTPAndClick()
    if autoTPEnabled then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = target.Character.HumanoidRootPart.Position
            local playerPosition = player.Character.HumanoidRootPart.Position
            
            player.Character:SetPrimaryPartCFrame(CFrame.new(targetPosition + (targetPosition - playerPosition).Unit * 5))
            mouse1click()
        end
    end
end

-- Input Handling
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        toggleAimbot()
    elseif input.KeyCode == Enum.KeyCode.T then
        toggleESP()
    elseif input.KeyCode == Enum.KeyCode.N then
        toggleFly()
    elseif input.KeyCode == Enum.KeyCode.Z then
        toggleAutoTP()
    end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    aimbot()
    updateESP()
    fly()
    autoTPAndClick()
end)
