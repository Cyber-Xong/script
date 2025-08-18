pcall(function()
    repeat task.wait() until game:IsLoaded()

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local UIS = game:GetService("UserInputService")
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humPart = character:WaitForChild("HumanoidRootPart")
    local map

    -- Services
    local Vim = game:GetService("VirtualInputManager")
    
    --// Services
    local ReplicatedStorage = game:GetService("ReplicatedStorage")



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
    workspace.DescendantRemoving:Connect(function(m) if m == map then map = nil end end)

    -------------------
    -- Respawn
    -------------------
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
                    task.wait(1.55) -- mobile plus rapide, PC plus long
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
                        task.wait(isMobile and 1.65 or 0.9) -- temps de ramassage selon device
                        humPart.CFrame = CFrame.new(132, 140, 60) + Vector3.new(0, 4, 0) -- retour
                        task.wait(isMobile and 1.6 or 1.3) -- temps de retour selon device
                    else
                        humPart.CFrame = CFrame.new(132, 140, 60) + Vector3.new(0, 4, 0)
                        task.wait(2)
                    end
                else
                    task.wait(1.55)
                end
            end
        end)
    end
    
    function stopAutoFarm()
        _G.Farm = false
    end

    -------------------
    -- Fuir le Tueur
    -------------------
    local fleeTask
    local function startFlee()
        if fleeTask then return end
        _G.FuirTueur = true
        fleeTask = RunService.Heartbeat:Connect(function()
            if not _G.FuirTueur then fleeTask:Disconnect() fleeTask = nil return end
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
                if dist < 20 then
                    local fleeDir = (humPart.Position - murdererHRP.Position).Unit
                    local fleePos = humPart.Position + fleeDir * math.clamp(40 - dist, 20, 40)
                    humPart.CFrame = humPart.CFrame:Lerp(
                        CFrame.new(fleePos.X, humPart.Position.Y, fleePos.Z),
                        0.2
                    )
                end
            end
        end)
    end

    local function stopFlee()
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

    local function startScanRoles()
        if rolesTask then return end
        _G.TrackRoles = true
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

    local function stopScanRoles()
        _G.TrackRoles = false
        clearHighlights()
        rolesTask = nil
    end

    -------------------
    -- TP Functions
    -------------------
    local function tpLobby()
        if character and humPart then
            humPart.CFrame = CFrame.new(132, 140, 60)
        end
    end

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
            local target = candidates[math.random(1,#candidates)]
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and humPart then
                humPart.CFrame = targetHRP.CFrame * CFrame.new(3,0,0)
            end
        end
    end

    -------------------
    -- UI
    -------------------
    local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Lib/main/source.lua"))()
    local w = lib:Window("🏐 beachball farm V2.2 🏖️", Color3.fromRGB(238,130,238))

    w:Toggle("🎈 AutoFarm BeachBalls", false, function(v) _G.Farm = v if v then startAutoFarm() else stopAutoFarm() end end)
    w:Toggle("🏃‍♂️ Flee the killer", false, function(v) _G.FuirTueur = v if v then startFlee() else stopFlee() end end)
    w:Toggle("🔍 Track Roles", false, function(v) _G.TrackRoles = v if v then startScanRoles() else stopScanRoles() end end)
    w:Button("📌 TP to Lobby", tpLobby)
    w:Button("📌 TP to Random Innocent", tpRandomInnocent)

    w:Label("🌀 made by CSA-Studio 🌀", Color3.fromRGB(255,255,255))

---------------------------------------------------------------------------------------------------------------------------
                                --Part 2 Tools


    repeat task.wait() until game:IsLoaded()


    -- Variables principales
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    local currentSpeed = 16
    local multiJump = false
    local pickGunTask
    local noclipConnection

    -- UI Turtle Lib
    local win = lib:Window("🛠️ Tools Section 🧰", Color3.fromRGB(238,130,238))

    -------------------
    -- Respawn Gestion
    -------------------
    LocalPlayer.CharacterAdded:Connect(function(char)
        character = char
        humanoid = char:WaitForChild("Humanoid")
        hrp = char:WaitForChild("HumanoidRootPart")
    end)

    -------------------
    -- Pick Gun
    -------------------
    local function startPickGun()
        if pickGunTask then return end
        _G.PickGun = true
        pickGunTask = task.spawn(function()
            while _G.PickGun do
                if hrp then
                    local gun = workspace:FindFirstChild("GunDrop", true)
                    if gun and gun:IsA("Part") then
                        local originalPos = hrp.CFrame -- sauvegarde position actuelle
                        hrp.CFrame = CFrame.new(gun.Position + Vector3.new(0,2,0))
                        firetouchinterest(hrp, gun, 0)
                        firetouchinterest(hrp, gun, 1)
                        task.wait(0.5)
                        -- revenir à la position originale
                        if originalPos then
                            hrp.CFrame = originalPos
                        end
                        task.wait(1) -- petit wait pour éviter spam
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


    -------------------
    -- NoClip
    -------------------
    local function setNoClip(state)
        if state then
            noclipConnection = RunService.Stepped:Connect(function()
                if character and hrp then
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
    UIS.JumpRequest:Connect(function()
        if multiJump and humanoid and humanoid.Health > 0 then
            if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    -------------------
    -- WalkSpeed
    -------------------
    local function applySpeed()
        if humanoid and humanoid.Health > 0 then
            humanoid.WalkSpeed = currentSpeed
        end
    end

    task.spawn(function()
        while true do
            task.wait(0.1)
            applySpeed()
        end
    end)

    -------------------
    -- Helpers Kill All
    -------------------
    local function centerClick()
        local cam = workspace.CurrentCamera
        local vps = cam.ViewportSize
        Vim:SendMouseButtonEvent(vps.X/2, vps.Y/2, 0, true, game, 0)
        task.wait(0.05)
        Vim:SendMouseButtonEvent(vps.X/2, vps.Y/2, 0, false, game, 0)
    end

    local function equipTool(tool)
        if tool and humanoid.Health > 0 then
            pcall(function() humanoid:EquipTool(tool) end)
        end
    end

    local function killAll()
        if not character or not hrp then return end
        local knife = LocalPlayer.Backpack:FindFirstChild("Knife") or character:FindFirstChild("Knife")
        if not knife then
            lib:Notification("Pas Murderer", "Knife requis pour Kill All.", 3)
            return
        end
        equipTool(knife)
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = pl.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,0.25)
                centerClick()
                task.wait(0.4)
            end
        end
        lib:Notification("Kill All", "Tentative sur tous les joueurs effectuée.", 4)
    end

    -------------------
    -- UI
    -------------------
    win:Toggle("🔫 Pick Gun", false, function(v)
        _G.PickGun = v
        if v then startPickGun() else stopPickGun() end
    end)

    win:Toggle("🚪 NoClip", false, function(v) setNoClip(v) end)
    win:Toggle("🌀 Multiple Jump", false, function(v) multiJump = v end)
    win:Slider("⚡ WalkSpeed", 8, 25, 16, function(v) currentSpeed = math.clamp(v,8,25) applySpeed() end)

    win:Button("🔪 Kill All as murder", killAll)
    win:Label("🌀 CSA-Studio 🌀", Color3.fromRGB(255,255,255))

end)
    
