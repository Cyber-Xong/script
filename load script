-- 🐢 Turtle Lib Minimal
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Lib/main/source.lua"))()
local w = lib:Window("MM2 Summer Farm Ball", Color3.fromRGB(238,130,238))

local plr = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local character = plr.Character or plr.CharacterAdded:Wait()
local humPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local map
local highlights = {}
local godConnection, fleeConnection

plr.CharacterAdded:Connect(function(char)
    character = char
    humPart = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
end)

local function getMap()
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") and m:GetAttribute("MapID") then
            map = m
            return
        end
    end
end
getMap()
workspace.DescendantAdded:Connect(getMap)
workspace.DescendantRemoving:Connect(function(m) if m == map then map = nil end end)

local function setupGodMode()
    if humanoid then
        if godConnection then godConnection:Disconnect() end
        godConnection = humanoid.HealthChanged:Connect(function()
            if humanoid.Health < humanoid.MaxHealth and _G.GodMode then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
    end
end

-- 🛡️ Auto-recharge God Mode (chaque partie)
task.spawn(function()
    while true do
        if _G.GodMode and humanoid then
            humanoid.Health = humanoid.MaxHealth
            setupGodMode()
        end
        task.wait(2)
    end
end)

local function moveTo(pos)
    if not humPart then return end
    local dist = (humPart.Position - pos).Magnitude
    local time = math.clamp(dist / 25, 1, 4)
    local tween = TweenService:Create(humPart, TweenInfo.new(time, Enum.EasingStyle.Linear), { CFrame = CFrame.new(pos) })
    tween:Play()
    tween.Completed:Wait()
end

local function collect(coin)
    local visual = coin:FindFirstChild("CoinVisual") or coin
    if visual then
        firetouchinterest(humPart, visual, 0)
        firetouchinterest(humPart, visual, 1)
    end
end

local function startFarm()
    while _G.Farm do
        if not map then getMap() end
        local container = map and map:FindFirstChild("CoinContainer")
        if container then
            local closest, dist = nil, math.huge
            for _, coin in ipairs(container:GetChildren()) do
                if coin:IsA("Part") and coin.Name == "Coin_Server" and coin:GetAttribute("CoinID") == "BeachBall" then
                    local vis = coin:FindFirstChild("CoinVisual")
                    if vis and vis.Transparency < 1 then
                        local d = (humPart.Position - coin.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = coin
                        end
                    end
                end
            end
            if closest then
                moveTo(closest.Position + Vector3.new(0, 2, 0))
                collect(closest)
                task.wait(0.5)
            else
                task.wait(1.2)
            end
        else
            task.wait(1)
        end
    end
end

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
    for _, hl in pairs(highlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    highlights = {}
end

local function scanRoles()
    while _G.TrackRoles do
        clearHighlights()
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= plr and player.Character then
                local hasGun = player.Backpack:FindFirstChild("Gun") or player.Character:FindFirstChild("Gun")
                local hasKnife = player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife")
                if hasKnife then
                    createHighlight(player, Color3.fromRGB(255, 0, 0))
                elseif hasGun then
                    createHighlight(player, Color3.fromRGB(0, 120, 255))
                elseif _G.ShowInnocents then
                    createHighlight(player, Color3.fromRGB(255, 255, 255))
                end
            end
        end
        task.wait(2)
    end
    clearHighlights()
end

local function pickGun()
    while _G.PickGun do
        if map and humPart then
            local gun = map:FindFirstChild("GunDrop", true)
            if gun and gun:IsA("Part") then
                local oldCFrame = humPart.CFrame
                humPart.CFrame = CFrame.new(gun.Position + Vector3.new(0, 2, 0))
                task.wait(0.3)
                firetouchinterest(humPart, gun, 0)
                firetouchinterest(humPart, gun, 1)
                task.wait(0.3)
                humPart.CFrame = oldCFrame
                task.wait(1.5)
            else
                task.wait(1)
            end
        else
            getMap()
            task.wait(1)
        end
    end
end

local function fuirTueur()
    if fleeConnection then fleeConnection:Disconnect() end
    fleeConnection = RunService.Heartbeat:Connect(function()
        if not _G.FuirTueur then fleeConnection:Disconnect() return end
        if not humPart or not map then return end
        local murderHumPart = nil
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= plr and player.Character then
                local knife = player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife")
                if knife then
                    murderHumPart = player.Character:FindFirstChild("HumanoidRootPart")
                    break
                end
            end
        end
        if murderHumPart then
            local dist = (humPart.Position - murderHumPart.Position).Magnitude
            if dist < 20 then
                local fleeDir = (humPart.Position - murderHumPart.Position).Unit
                local fleePos = humPart.Position + fleeDir * 25
                humPart.CFrame = CFrame.new(fleePos.X, humPart.Position.Y, fleePos.Z)
            end
        end
    end)
end

local function tpNearInnocentOnce()
    if not humPart then return end
    local found = false
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hasGun = player.Backpack:FindFirstChild("Gun") or player.Character:FindFirstChild("Gun")
            local hasKnife = player.Backpack:FindFirstChild("Knife") or player.Character:FindFirstChild("Knife")
            if not hasGun and not hasKnife then
                local pos = player.Character.HumanoidRootPart.Position + Vector3.new(3, 0, 0)
                humPart.CFrame = CFrame.new(pos.X, humPart.Position.Y, pos.Z)
                found = true
                break
            end
        end
    end
    if not found then warn("Aucun innocent trouvé.") end
end

-- 🔘 GLOBALS INIT
_G.Farm = false
_G.GodMode = false
_G.TrackRoles = false
_G.PickGun = false
_G.FuirTueur = false
_G.ShowInnocents = false

-- ✅ INTERFACE
w:Toggle("🎈 AutoFarm BeachBalls", false, function(v)
    _G.Farm = v
    if v then task.spawn(startFarm) end
end)

w:Toggle("🛡️ God Mode", false, function(v)
    _G.GodMode = v
    if v then setupGodMode() else
        if godConnection then godConnection:Disconnect() end
    end
end)

w:Toggle("🔍 Afficher M & S", false, function(v)
    _G.TrackRoles = v
    if v then task.spawn(scanRoles) end
end)

w:Toggle("⚪ Montrer Innos", false, function(v)
    _G.ShowInnocents = v
end)

w:Toggle("🔫 Ramasser Gun", false, function(v)
    _G.PickGun = v
    if v then task.spawn(pickGun) end
end)

w:Toggle("🏃‍♂️ Fuir le Tueur", false, function(v)
    _G.FuirTueur = v
    if v then fuirTueur() end
end)

w:Button("📍 TP à un Innocent", function()
    tpNearInnocentOnce()
end)

w:Button("💤 Anti-AFK", function()
    local vu = cloneref(game:GetService("VirtualUser"))
    plr.Idled:Connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)

w:Label("🌀 Version ULTRA STABLE – mousta34", Color3.fromRGB(238,130,238))
