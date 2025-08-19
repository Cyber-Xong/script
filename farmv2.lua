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

    -- Update map
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
    workspace.DescendantRemoving:Connect(function(m) if m == map then map = nil end end)

    -- Respawn gestion
    LocalPlayer.CharacterAdded:Connect(function(char)
        character = char
        humPart = char:WaitForChild("HumanoidRootPart")
    end)

    -------------------
    -- AutoFarm
    -------------------
    local isMobile = game:GetService("UserInputService").TouchEnabled

    function startAutoFarm()
        task.spawn(function()
            while _G.Farm do
                -- Vérification du personnage et de HumanoidRootPart
                if not character or not humPart then
                    task.wait(1.5) -- mobile plus rapide, PC plus long
                    character = LocalPlayer.Character
                    humPart = character and character:FindFirstChild("HumanoidRootPart")
                end
    
                if map and map:FindFirstChild("CoinContainer") then
                    local validCoins = {}
                    for _, coin in ipairs(map.CoinContainer:GetChildren()) do
                        if coin:IsA("Part") and coin.Name == "Coin_Server" and coin:GetAttribute("CoinID") == "BeachBall" then
                            local cv = coin:FindFirstChild("CoinVisual")
                            if cv and cv.Transparency ~= 1 then
                                table.insert(validCoins, coin)
                            end
                        end
                    end
    
                    if #validCoins > 0 and humPart then
                        -- choisir une pièce aléatoire
                        local coinToCollect = validCoins[math.random(1, #validCoins)]
                        humPart.CFrame = coinToCollect.CFrame
                        task.wait(isMobile and 1.6 or 0.9) -- temps de ramassage selon device
                        humPart.CFrame = CFrame.new(132, 140, 60) + Vector3.new(0, 4, 0) -- retour
                        task.wait(isMobile and 1.6 or 1.3) -- temps de retour selon device
                    else
                        humPart.CFrame = CFrame.new(132, 140, 60) + Vector3.new(0, 4, 0)
                        task.wait(2)
                    end
                else
                    task.wait(1.5)
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
        _G.FuirTueur = true
    
        fleeTask = RunService.Heartbeat:Connect(function()
            if not _G.FuirTueur then
                fleeTask:Disconnect()
                fleeTask = nil
                return
            end
    
            if not humPart or not map then return end
    
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
                if dist < 30 then -- distance de détection plus large
                    local fleeDir = (humPart.Position - murdererHRP.Position).Unit
                    local fleePos = humPart.Position + fleeDir * math.clamp(40 - dist, 20, 40)
    
                    -- déplacement fluide
                    humPart.CFrame = humPart.CFrame:Lerp(
                        CFrame.new(fleePos.X, humPart.Position.Y, fleePos.Z),
                        0.25 -- vitesse de fuite (0.1 = lent, 1 = TP direct)
                    )
                end
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
    local highlights = {}
    local rolesTask
    local function createHighlight(player, color)
        local highlight = Instance.new("Highlight")
        highlight.Name = "RoleAura"
        highlight.FillColor = color
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 1
        highlight.Adornee = player.Character
        highlight.Parent = player.Character
        highlights[player] = highlight
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
                            createHighlight(player, Color3.fromRGB(255,0,0)) -- Murder
                        elseif hasGun then
                            createHighlight(player, Color3.fromRGB(0,120,255)) -- Sheriff
                        else
                            createHighlight(player, Color3.fromRGB(255,255,255)) -- Innocent
                        end
                    end
                end
                task.wait(2)
            end
            clearHighlights()
            rolesTask = nil
        end)
    end
    function stopScanRoles() _G.TrackRoles = false clearHighlights() rolesTask = nil end

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
                        -- Téléportation au gun
                        humPart.CFrame = CFrame.new(gun.Position + Vector3.new(0, 2, 0))
                        
                        -- Simulation de "pickup"
                        firetouchinterest(humPart, gun, 0)
                        firetouchinterest(humPart, gun, 1)
                        
                        task.wait(0.5)
                    else
                        -- Pas de gun trouvé
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
            task.cancel(pickGunTask) -- stop propre
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
                        if part:IsA("BasePart") and part.CanCollide == true then
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
            -- Réactiver les collisions correctement
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
    -- TP Lobby
    -------------------
    local function tpLobby()
        if character and humPart then
            humPart.CFrame = CFrame.new(132, 140, 60)
        end
    end

    -------------------
    -- TP Map (vers un innocent random)
    -------------------
    local function tpRandomInnocent()
        local candidates = {}
        for _, pl in pairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                local hasGun = pl.Backpack:FindFirstChild("Gun") or pl.Character:FindFirstChild("Gun")
                local hasKnife = pl.Backpack:FindFirstChild("Knife") or pl.Character:FindFirstChild("Knife")
                if not hasGun and not hasKnife then
                    table.insert(candidates, pl)
                end
            end
        end
        if #candidates > 0 then
            local target = candidates[math.random(1, #candidates)]
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and humPart then
                humPart.CFrame = targetHRP.CFrame * CFrame.new(3, 0, 0)
            end
        end
    end

    -------------------
    -- Anti AFK
    -------------------
    local antiAfkActive = false
    local function antiAfk()
        if antiAfkActive then return end
        antiAfkActive = true
        LocalPlayer.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end


    
    -------------------
    -- UI
    -------------------
    local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Lib/main/source.lua"))()
    local w = lib:Window("MM2 Summer Full Script", Color3.fromRGB(238, 130, 238))

    w:Toggle("🎈 AutoFarm BeachBalls", false, function(v) _G.Farm = v if v then startAutoFarm() else stopAutoFarm() end end)
    w:Toggle("💪 2 Life", false, function(v) _G.GodMode = v if v then setupGodMode() else stopGodMode() end end)
    w:Toggle("🏃‍♂️ flee of killer", false , function(v) _G.FuirTueur = v if v then startFlee() else stopFlee() end end)
    w:Toggle("🔍 Track Roles", false, function(v) _G.TrackRoles = v if v then startScanRoles() else stopScanRoles() end end)
    w:Toggle("🔫 Pick Gun", false, function(v) _G.PickGun = v if v then startPickGun() else stopPickGun() end end)
    w:Toggle("🚪 NoClip", false, function(v) setNoClip(v) end)
    w:Toggle("🌀 Multiple Jump", false, function(v) multiJump = v end)
    

    -- Boutons
    w:Button("📌 TP to Lobby", function() tpLobby() end)
    w:Button("📌 TP to Random inno", function() tpRandomInnocent() end)
    w:Button("🕹️ Anti-AFK", function() antiAfk() end)

    -- Label
    w:Label("🌀 made by CSA-Studio 🌀" , Color3.fromRGB(255,255,255))
end)
