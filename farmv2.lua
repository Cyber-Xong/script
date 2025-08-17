local success, err = pcall(function()
    repeat task.wait() until game:IsLoaded()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humPart = character:WaitForChild("HumanoidRootPart")
    local map
    local highlights = {}
    local connections = {}

    -- Fonction pour mettre à jour le map
    local function updateMap()
        map = nil
        for _, m in ipairs(workspace:GetChildren()) do
            if m:IsA("Model") and m:GetAttribute("MapID") then
                map = m
                break
            end
        end
    end
    updateMap()
    connections.updateMapAdded = workspace.DescendantAdded:Connect(updateMap)
    connections.updateMapRemoved = workspace.DescendantRemoving:Connect(function(m) if m == map then map = nil end end)

    -- Gestion respawn
    LocalPlayer.CharacterAdded:Connect(function(char)
        character = char
        humPart = char:WaitForChild("HumanoidRootPart")
    end)

    -------------------
    -- AutoFarm
    -------------------
    local autoFarmTask
    function startAutoFarm()
        _G.Farm = true
        autoFarmTask = task.spawn(function()
            while _G.Farm do
                if map and map:FindFirstChild("CoinContainer") and humPart then
                    local coinToCollect
                    for _, coin in ipairs(map.CoinContainer:GetChildren()) do
                        if coin:IsA("Part") and coin.Name == "Coin_Server" and coin:GetAttribute("CoinID") == "BeachBall" then
                            local cv = coin:FindFirstChild("CoinVisual")
                            if cv and cv.Transparency ~= 1 then
                                coinToCollect = coin
                                break
                            end
                        end
                    end
                    if coinToCollect then
                        humPart.CFrame = coinToCollect.CFrame
                        task.wait(1.3)
                    end
                    humPart.CFrame = CFrame.new(132, 140, 60)
                    task.wait(1.5)
                else
                    task.wait(1)
                end
            end
        end)
    end
    function stopAutoFarm()
        _G.Farm = false
        if autoFarmTask then task.cancel(autoFarmTask) autoFarmTask = nil end
    end

    -------------------
    -- God Mode
    -------------------
    local godModeConnection
    function setupGodMode()
        local humanoid = character:WaitForChild("Humanoid")
        if godModeConnection then godModeConnection:Disconnect() end
        godModeConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health < humanoid.MaxHealth and _G.GodMode then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
    end
    function stopGodMode()
        if godModeConnection then godModeConnection:Disconnect() godModeConnection = nil end
    end

    -------------------
    -- Fuir le Tueur
    -------------------
    local fleeTask
    function startFlee()
        if fleeTask then return end
        _G.FuirTueur = true
        fleeTask = RunService.Heartbeat:Connect(function()
            if not _G.FuirTueur or not humPart or not map then return end

            local murdererHRP
            for _, pl in pairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and pl.Character then
                    local knife = pl.Backpack:FindFirstChild("Knife") or pl.Character:FindFirstChild("Knife")
                    if knife then
                        murdererHRP = pl.Character:FindFirstChild("HumanoidRootPart")
                        break
                    end
                end
            end

            if murdererHRP then
                local dir = (humPart.Position - murdererHRP.Position).Unit
                local dist = (humPart.Position - murdererHRP.Position).Magnitude
                local fleePos = humPart.Position + dir * math.clamp(40 - dist, 20, 40)
                humPart.CFrame = humPart.CFrame:Lerp(CFrame.new(fleePos.X, humPart.Position.Y, fleePos.Z), 0.25)
            end
        end)
    end
    function stopFlee()
        _G.FuirTueur = false
        if fleeTask then fleeTask:Disconnect() fleeTask = nil end
    end

    -------------------
    -- Track Roles
    -------------------
    local rolesTask
    local function createHighlight(player, color)
        if player.Character then
            local hl = Instance.new("Highlight")
            hl.Name = "RoleAura"
            hl.FillColor = color
            hl.FillTransparency = 0.3
            hl.OutlineTransparency = 1
            hl.Adornee = player.Character
            hl.Parent = player.Character
            highlights[player] = hl
        end
    end
    local function clearHighlights()
        for _, hl in pairs(highlights) do if hl then hl:Destroy() end end
        highlights = {}
    end
    function startScanRoles()
        if rolesTask then return end
        _G.TrackRoles = true
        rolesTask = task.spawn(function()
            while _G.TrackRoles do
                clearHighlights()
                for _, pl in pairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer then
                        local hasGun = pl.Backpack:FindFirstChild("Gun") or pl.Character:FindFirstChild("Gun")
                        local hasKnife = pl.Backpack:FindFirstChild("Knife") or pl.Character:FindFirstChild("Knife")
                        if hasKnife then
                            createHighlight(pl, Color3.fromRGB(255,0,0))
                        elseif hasGun then
                            createHighlight(pl, Color3.fromRGB(0,120,255))
                        else
                            createHighlight(pl, Color3.fromRGB(255,255,255))
                        end
                    end
                end
                task.wait(2)
            end
            clearHighlights()
        end)
    end
    function stopScanRoles() _G.TrackRoles = false clearHighlights() end

    -------------------
    -- Pick Gun
    -------------------
    local pickGunTask
    function startPickGun()
        if pickGunTask then return end
        _G.PickGun = true
        pickGunTask = task.spawn(function()
            while _G.PickGun do
                if humPart then
                    local gun = workspace:FindFirstChild("GunDrop", true)
                    if gun and gun:IsA("Part") then
                        humPart.CFrame = CFrame.new(gun.Position + Vector3.new(0, 2, 0))
                        firetouchinterest(humPart, gun, 0)
                        firetouchinterest(humPart, gun, 1)
                        task.wait(0.5)
                    else
                        task.wait(1)
                    end
                else
                    task.wait(1)
                end
            end
        end)
    end
    function stopPickGun()
        _G.PickGun = false
        if pickGunTask then task.cancel(pickGunTask) pickGunTask = nil end
    end

    -------------------
    -- NoClip
    -------------------
    local noclipConnection
    local function setNoClip(state)
        if state then
            noclipConnection = RunService.Stepped:Connect(function()
                if character then
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        else
            if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end
    end

    -------------------
    -- Multiple Jump
    -------------------
    local multiJump = false
    UIS.JumpRequest:Connect(function()
        if multiJump and character and character:FindFirstChild("Humanoid") then
            local hum = character.Humanoid
            if hum:GetState() == Enum.HumanoidStateType.Freefall then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    -------------------
    -- TP Functions
    -------------------
    local function tpLobby()
        if humPart then humPart.CFrame = CFrame.new(132, 140, 60) end
    end
    local function tpRandomInnocent()
        local candidates = {}
        for _, pl in pairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                local hasGun = pl.Backpack:FindFirstChild("Gun") or pl.Character:FindFirstChild("Gun")
                local hasKnife = pl.Backpack:FindFirstChild("Knife") or pl.Character:FindFirstChild("Knife")
                if not hasGun and not hasKnife then table.insert(candidates, pl) end
            end
        end
        if #candidates > 0 then
            local target = candidates[math.random(1, #candidates)]
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and humPart then
                humPart.CFrame = targetHRP.CFrame * CFrame.new(3,0,0)
            end
        end
    end

    -------------------
    -- Anti AFK
    -------------------
    local function antiAfk()
        LocalPlayer.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
    end
    antiAfk()
end)

if not success then warn("Erreur Script: "..tostring(err)) end


-- Assurez-vous d'avoir Turtle Lib chargé
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/TurtleLib/main/UILib.lua"))()
local Window = Library:CreateWindow("MM2 Summer Hub", Enum.KeyCode.RightControl)

local MainTab = Window:CreateTab("Main")
local PlayerTab = Window:CreateTab("Player")

-- Toggle AutoFarm BeachBalls
MainTab:CreateToggle("AutoFarm BeachBalls", false, function(value)
    _G.Farm = value
    if value then startAutoFarm() else stopAutoFarm() end
end)

-- Toggle GodMode
PlayerTab:CreateToggle("GodMode", false, function(value)
    _G.GodMode = value
    if value then setupGodMode() else stopGodMode() end
end)

-- Toggle Fuite du Tueur
MainTab:CreateToggle("Fuir Tueur", false, function(value)
    if value then startFlee() else stopFlee() end
end)

-- Toggle Scan Roles (Highlight)
MainTab:CreateToggle("Highlight Roles", false, function(value)
    if value then startScanRoles() else stopScanRoles() end
end)

-- Toggle PickGun
MainTab:CreateToggle("Pick Gun", false, function(value)
    if value then startPickGun() else stopPickGun() end
end)

-- Toggle NoClip
PlayerTab:CreateToggle("NoClip", false, function(value)
    setNoClip(value)
end)

-- MultiJump
PlayerTab:CreateToggle("MultiJump", false, function(value)
    multiJump = value
end)

-- Teleports
MainTab:CreateButton("TP Lobby", function()
    tpLobby()
end)

MainTab:CreateButton("TP Random Innocent", function()
    tpRandomInnocent()
end)

-- AntiAFK activé par défaut
antiAfk()

