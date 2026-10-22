-- Mor x Mama Hub (Roblox Studio / own experience)
-- Rayfield GUI must be available as a ModuleScript named "Rayfield"
-- Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- Fling Aura is intentionally limited to a consent-based server mechanic in your own game.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Rayfield = require(ReplicatedStorage:WaitForChild("Rayfield"))

local Window = Rayfield:CreateWindow({
    Name = "Mor x Mama Hub",
    LoadingTitle = "Mor x Mama Hub",
    LoadingSubtitle = "Private experience tools",
    ConfigurationSaving = { Enabled = false },
    KeySystem = true,
    KeySettings = {
        Title = "Mor x Mama Hub",
        Subtitle = "Enter Key",
        Note = "Key: moor",
        FileName = "MorMamaHub",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {"moor"}
    }
})

local Tab = Window:CreateTab("Player")
local VisualTab = Window:CreateTab("Visuals")
local UtilityTab = Window:CreateTab("Utilities")

local walkSpeed = 16
local jumpPower = 50
local flySpeed = 50
local flying = false
local noclip = false
local antiFling = false
local espEnabled = false
local flingAuraEnabled = false
local flingStrength = 100
local flyConnection
local noclipConnection
local antiFlingConnection
local espObjects = {}
local selectedPlayerName = nil

local function character()
    return player.Character
end

local function humanoid()
    local char = character()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function rootPart(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function applyMovement()
    local hum = humanoid()
    if hum then
        hum.WalkSpeed = walkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = jumpPower
    end
end

player.CharacterAdded:Connect(function()
    task.wait(0.25)
    applyMovement()
end)

Tab:CreateSlider({
    Name = "ความเร็ว",
    Range = {1, 500},
    Increment = 1,
    CurrentValue = walkSpeed,
    Callback = function(value)
        walkSpeed = value
        applyMovement()
    end
})

Tab:CreateSlider({
    Name = "พลังกระโดด",
    Range = {1, 500},
    Increment = 1,
    CurrentValue = jumpPower,
    Callback = function(value)
        jumpPower = value
        applyMovement()
    end
})

Tab:CreateSlider({
    Name = "ความเร็วบิน",
    Range = {1, 500},
    Increment = 1,
    CurrentValue = flySpeed,
    Callback = function(value)
        flySpeed = value
    end
})

Tab:CreateToggle({
    Name = "บิน (WASD, Space ขึ้น, Ctrl ลง)",
    CurrentValue = false,
    Callback = function(enabled)
        flying = enabled
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        if not enabled then return end

        flyConnection = RunService.Heartbeat:Connect(function()
            local char = character()
            local root = rootPart(char)
            local hum = humanoid()
            local camera = workspace.CurrentCamera
            if not root or not hum or not camera then return end

            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end

            root.AssemblyLinearVelocity = direction.Magnitude > 0
                and direction.Unit * flySpeed
                or Vector3.zero
        end)
    end
})

Tab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(enabled)
        noclip = enabled
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end

        if enabled then
            noclipConnection = RunService.Stepped:Connect(function()
                local char = character()
                if not char then return end
                for _, item in ipairs(char:GetDescendants()) do
                    if item:IsA("BasePart") then item.CanCollide = false end
                end
            end)
        else
            local char = character()
            if char then
                for _, item in ipairs(char:GetDescendants()) do
                    if item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then
                        item.CanCollide = true
                    end
                end
            end
        end
    end
})

Tab:CreateToggle({
    Name = "Anti-Fling (ป้องกันตัวเอง)",
    CurrentValue = false,
    Callback = function(enabled)
        antiFling = enabled
        if antiFlingConnection then
            antiFlingConnection:Disconnect()
            antiFlingConnection = nil
        end
        if enabled then
            antiFlingConnection = RunService.Heartbeat:Connect(function()
                local root = rootPart(character())
                if root and root.AssemblyLinearVelocity.Magnitude > 100 then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end
            end)
        end
    end
})

local function removeESP(target)
    local bundle = espObjects[target]
    if not bundle then return end
    if bundle.highlight then bundle.highlight:Destroy() end
    if bundle.billboard then bundle.billboard:Destroy() end
    espObjects[target] = nil
end

local function addESP(target)
    if target == player or not espEnabled then return end
    removeESP(target)
    local char = target.Character
    local root = rootPart(char)
    if not char or not root then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "MorMamaESP"
    highlight.Adornee = char
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(0, 255, 80)
    highlight.OutlineColor = Color3.fromRGB(0, 255, 80)
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0
    highlight.Parent = char

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MorMamaESPName"
    billboard.Adornee = root
    billboard.Size = UDim2.fromOffset(180, 32)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = root

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = target.Name
    label.TextColor3 = Color3.fromRGB(0, 255, 80)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Parent = billboard

    espObjects[target] = {highlight = highlight, billboard = billboard}
end

VisualTab:CreateToggle({
    Name = "ESP Green (ผ่านกำแพง)",
    CurrentValue = false,
    Callback = function(enabled)
        espEnabled = enabled
        if enabled then
            for _, target in ipairs(Players:GetPlayers()) do addESP(target) end
        else
            for target in pairs(espObjects) do removeESP(target) end
        end
    end
})

local function watchPlayer(target)
    target.CharacterAdded:Connect(function()
        task.wait(0.5)
        addESP(target)
    end)
end

for _, target in ipairs(Players:GetPlayers()) do
    if target ~= player then watchPlayer(target) end
end

Players.PlayerAdded:Connect(function(target)
    watchPlayer(target)
    if espEnabled then task.wait(0.5); addESP(target) end
end)

Players.PlayerRemoving:Connect(removeESP)

local function playerNames()
    local names = {}
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then table.insert(names, target.Name) end
    end
    table.sort(names)
    return names
end

UtilityTab:CreateDropdown({
    Name = "เลือกผู้เล่นเพื่อ Teleport",
    Options = playerNames(),
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(option)
        selectedPlayerName = option[1]
    end
})

UtilityTab:CreateButton({
    Name = "Teleport ไปหาผู้เล่นที่เลือก",
    Callback = function()
        local target = selectedPlayerName and Players:FindFirstChild(selectedPlayerName)
        local myRoot = rootPart(character())
        local targetRoot = target and rootPart(target.Character)
        if myRoot and targetRoot then
            character():PivotTo(targetRoot.CFrame * CFrame.new(0, 0, 3))
        end
    end
})

UtilityTab:CreateButton({
    Name = "รีเฟรชรายชื่อผู้เล่น",
    Callback = function()
        Rayfield:Notify({
            Title = "Mor x Mama Hub",
            Content = "หาก Dropdown ไม่อัปเดต ให้ปิดแล้วเปิด GUI ใหม่ตาม API ของ Rayfield เวอร์ชันนี้",
            Duration = 4
        })
    end
})

UtilityTab:CreateSlider({
    Name = "Fling Aura strength (เกมของตัวเองเท่านั้น)",
    Range = {1, 1000000},
    Increment = 1,
    CurrentValue = flingStrength,
    Callback = function(value)
        flingStrength = value
    end
})

UtilityTab:CreateToggle({
    Name = "Fling Aura (ระบบเซิร์ฟเวอร์แบบยินยอม)",
    CurrentValue = false,
    Callback = function(enabled)
        flingAuraEnabled = enabled
        local remote = ReplicatedStorage:FindFirstChild("ConsentFlingAura")
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer(enabled, flingStrength)
        else
            Rayfield:Notify({
                Title = "Fling Aura",
                Content = "ต้องสร้าง RemoteEvent ConsentFlingAura และตรวจสิทธิ์ผู้เล่นใน ServerScript ก่อน",
                Duration = 5
            })
        end
    end
})

Rayfield:Notify({
    Title = "Mor x Mama Hub",
    Content = "Loaded. ใช้เฉพาะในเกมที่คุณพัฒนา/ได้รับอนุญาต",
    Duration = 4
})
