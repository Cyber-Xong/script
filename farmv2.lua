pcall(function()
    repeat task.wait() until game:IsLoaded()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humPart = character:WaitForChild("HumanoidRootPart")
    local map
    local antiAfkActive = false

    -------------------
    -- Map Update
    -------------------
    local function updateMap()
        for _, m in ipairs(workspace:GetChildren()) do
            if m:IsA("Model") and m:GetAttribute("MapID") then
                map = m
                break
            end
        end
    end
    updateMap()
    workspace.DescendantAdded:Connect(updateMap)
    workspace.DescendantRemoving:Connect(function(m)
        if m == map then map = nil end
    end)

    -------------------
    -- Respawn Gestion
    -------------------
    LocalPlayer.CharacterAdded:Connect(function(char)
        character = char
        humPart = char:WaitForChild("HumanoidRootPart")
    end)

    -------------------
    -- AutoFarm BeachBalls
    -------------------
    function startAutoFarm()
        task.spawn(function()
            while _G.Farm do
                if not character or not humPart then
                    task.wait(0.9)
                    character = LocalPlayer.Character
                    humPart = character and character:FindFirstChild("HumanoidRootPart")
                end

                if map and map:FindFirstChild("CoinContainer") then
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

                    if coinToCollect and humPart then
                        humPart.CFrame = coinToCollect.CFrame
                        task.wait(1.3)
                        humPart.CFrame = CFrame.new(132, 140, 60)
                        task.wait(1.3)
                    else
                        humPart.CFrame = CFrame.new(132, 140, 60)
                        task.wait(1.3)
                    end
                else
                    task.wait(1.3)
                end
            end
        end)
    end

    function stopAutoFarm()
        _G.Farm = false
    end

    -------------------
    -- God Mode
    -------------------
    local godModeConnection
    function setupGodMode()
        local humanoid = character:WaitForChild("Humanoid")
        if godModeConnection then godModeConnection:Disconnect() end
        godModeConnection = humanoid.HealthChanged:Connect(function()
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
                local dist = (humPart.Position - murdererHRP.Position).Magnitude
                if dist < 15 then
                    local fleeDir = (humPart.Position - murdererHRP.Position).Unit
                    local targetPos = humPart.Position + fleeDir * 20
                    humPart.CFrame = humPart.CFrame:Lerp(
                        CFrame.new(targetPos.X, humPart.Position.Y, targetPos.Z),
                        0.25
                    )
                end
            end
        end)
    end

    function stopFlee()
        if fleeTask then fleeTask:Disconnect() fleeTask = nil end
    end

    -------------------
    -- Track Roles
    -------------------
    local highlights = {}
    local rolesTask
    local function createHighlight(player, color)
        if player.Character then
            local highlight = Instance.new("Highlight")
            highlight.Name = "RoleAura"
            highlight.FillColor = color
            highlight.FillTransparency = 0.3
            highlight.OutlineTransparency = 1
            highlight.Adornee = player.Character
            highlight.Parent = player.Character
            highlights[player] = highlight
        end
    end
    local function clearHighlights()
        for _, hl in pairs(highlights) do if hl and hl.Parent then hl:Destroy() end end
        highlights = {}
    end
    function startScanRoles()
        if rolesTask then return end
        rolesTask = task.spawn(function()
            while _G.TrackRoles do
                clearHighlights()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hasGun = player.Backpack:FindFirstChild("Gun") or player.Character:FindFirstChild("Gun")
                        local hasKnife = player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife")
                        if hasKnife then
                            createHighlight(player, Color3.fromRGB(255,0,0))
                        elseif hasGun then
                            createHighlight(player, Color3.fromRGB(0,120,255))
                        else
                            createHighlight(player, Color3.fromRGB(255,255,255))
                        end
                    end
                end
                task.wait(2)
            end
            clearHighlights()
            rolesTask = nil
        end)
    end
    function stopScanRoles()
        _G.TrackRoles = false
        clearHighlights()
        rolesTask = nil
    end

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
                        humPart.CFrame = CFrame.new(gun.Position + Vector3.new(0,2,0))
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
            pickGunTask = nil
        end)
    end
    function stopPickGun()
        _G.PickGun = false
        if pickGunTask then
            task.cancel(pickGunTask)
            pickGunTask = nil
        end
    end

    -------------------
    -- NoClip
    -------------------
    local noclipConnection
    local function setNoClip(state)
        if state then
            noclipConnection = RunService.Stepped:Connect(function()
                if character and humPart then
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
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
            local hum = character:FindFirstChild("Humanoid")
            if hum:GetState() == Enum.HumanoidStateType.Freefall then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    -------------------
    -- Player Speed
    -------------------
    local function setSpeed(speed)
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = speed
        end
    end

    Players.LocalPlayer.CharacterAdded:Connect(function(char)
        character = char
        local hum = char:WaitForChild("Humanoid")
        hum.WalkSpeed = _G.PlayerSpeed or 16
    end)

    -------------------
    -- TP Lobby
    -------------------
    local function tpLobby()
        if character and humPart then
            humPart.CFrame = CFrame.new(132,140,60)
        end
    end

    -------------------
    -- TP Random Innocent
    -------------------
    local function tpRandomInnocent()
        local candidates = {}
        for _, pl in pairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Team == LocalPlayer.Team and pl.Character then
                table.insert(candidates, pl)
            end
        end
        if #candidates > 0 then
            local target = candidates[math.random(1,#candidates)]
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and humPart then
                humPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
            end
        end
    end

    -------------------
    -- Anti-AFK
    -------------------
    if not antiAfkActive then
        antiAfkActive = true
        for _, conn in pairs(getconnections or function() return {} end)(Players.LocalPlayer.Idled) do
            conn:Disable()
        end
    end

    print("Script MM2 Summer chargé avec succès !")
end)



-- Vérifie si l'UI existe déjà
if game.CoreGui:FindFirstChild("MM2SummerUI") then
    game.CoreGui:FindFirstChild("MM2SummerUI"):Destroy()
end

-- Crée la ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2SummerUI"
screenGui.Parent = game.CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Crée le cadre principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 300)
frame.Position = UDim2.new(0, 10, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Titre
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "MM2 Summer Script"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextScaled = true
title.Parent = frame

-- Fonction pour créer des boutons
local function createButton(name, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = name
    btn.TextScaled = true
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
end

-- Boutons
createButton("AutoFarm BeachBalls", 40, function()
    _G.Farm = not _G.Farm
    if _G.Farm then
        print("AutoFarm activé")
        task.spawn(startAutoFarm)
    else
        print("AutoFarm désactivé")
        stopAutoFarm()
    end
end)

createButton("God Mode", 80, function()
    _G.GodMode = not _G.GodMode
    if _G.GodMode then
        print("God Mode activé")
        setupGodMode()
    else
        print("God Mode désactivé")
        stopGodMode()
    end
end)

createButton("Fuir Murder", 120, function()
    _G.FuirTueur = not _G.FuirTueur
    if _G.FuirTueur then
        print("Fuite activée")
        startFlee()
    else
        print("Fuite désactivée")
        stopFlee()
    end
end)

createButton("Pick Gun", 160, function()
    _G.PickGun = not _G.PickGun
    if _G.PickGun then
        print("Pick Gun activé")
        startPickGun()
    else
        print("Pick Gun désactivé")
        stopPickGun()
    end
end)

createButton("NoClip", 200, function()
    _G.NoClip = not _G.NoClip
    setNoClip(_G.NoClip)
    print("NoClip " .. (_G.NoClip and "activé" or "désactivé"))
end)

createButton("Scan Roles", 240, function()
    _G.TrackRoles = not _G.TrackRoles
    if _G.TrackRoles then
        startScanRoles()
        print("Scan Roles activé")
    else
        stopScanRoles()
        print("Scan Roles désactivé")
    end
end)
