-- 🐢 Turtle Lib Minimal
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Lib/main/source.lua"))()

local w = lib:Window("MM2 Summer Full Script", Color3.fromRGB(238, 130, 238))

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Variables globales
local map
local farmingTask, fleeTask, rolesTask, pickGunTask
local godModeConnection
local afkConnection

local highlights = {}

local function getMap()
    for _, m in ipairs(workspace:GetChildren()) do
        if m:IsA("Model") and m:GetAttribute("MapID") then
            return m
        end
    end
end

local function updateMap()
    map = getMap()
end

updateMap()
workspace.DescendantAdded:Connect(updateMap)
workspace.DescendantRemoving:Connect(function(m)
    if m == map then map = nil end
end)

-- Mise à jour character à chaque respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    character = char
    humPart = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")

    -- Redémarrage automatique des tâches actives
    if _G.Farm then startAutoFarm() end
    if _G.FuirTueur then startFlee() end
    if _G.GodMode then setupGodMode() end
    if _G.TrackRoles then startScanRoles() end
    if _G.PickGun then startPickGun() end
end)

-- Anti AFK
local function startAntiAfk()
    if afkConnection then return end
    afkConnection = LocalPlayer.Idled:Connect(function()
        local vu = game:GetService("VirtualUser")
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function stopAntiAfk()
    if afkConnection then
        afkConnection:Disconnect()
        afkConnection = nil
    end
end

-- Tween déplacement
local function moveTo(pos)
    if not humPart then return end
    local dist = (humPart.Position - pos).Magnitude
    local time = math.clamp(dist / 20, 0.7, 3)
    local tween = TweenService:Create(humPart, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
    tween.Completed:Wait()
end

local function collect(ball)
    local visual = ball:FindFirstChild("CoinVisual") or ball
    if visual then
        firetouchinterest(humPart, visual, 0)
        firetouchinterest(humPart, visual, 1)
    end
end

-- AutoFarm
function startAutoFarm()
    if farmingTask then return end
    farmingTask = task.spawn(function()
        while _G.Farm do
            if not map then updateMap() end
            if not humPart then task.wait(1) continue end

            local container = map and map:FindFirstChild("CoinContainer")
            if container then
                local closest, dist = nil, math.huge
                for _, ball in ipairs(container:GetChildren()) do
                    if ball:IsA("Part") and ball.Name == "Coin_Server" and ball:GetAttribute("CoinID") == "BeachBall" then
                        local vis = ball:FindFirstChild("CoinVisual")
                        if vis and vis.Transparency < 1 then
                            local d = (humPart.Position - ball.Position).Magnitude
                            if d < dist then
                                dist = d
                                closest = ball
                            end
                        end
                    end
                end
                if closest then
                    moveTo(closest.Position + Vector3.new(0, 2, 0))
                    collect(closest)
                    task.wait(0.6)
                else
                    task.wait(1.5)
                end
            else
                task.wait(1)
            end
        end
        farmingTask = nil
    end)
end

function stopAutoFarm()
    _G.Farm = false
    farmingTask = nil
end

-- God Mode
function setupGodMode()
    if godModeConnection then godModeConnection:Disconnect() end
    godModeConnection = humanoid.HealthChanged:Connect(function()
        if humanoid.Health < humanoid.MaxHealth and _G.GodMode then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
end

function stopGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
end

-- Fuir le tueur
function startFlee()
    if fleeTask then return end
    fleeTask = RunService.Heartbeat:Connect(function()
        if not _G.FuirTueur then
            fleeTask:Disconnect()
            fleeTask = nil
            return
        end
        if not humPart or not map then return end

        local murdererHRP = nil
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
                local fleePos = humPart.Position + fleeDir * 25
                humPart.CFrame = CFrame.new(fleePos.X, humPart.Position.Y, fleePos.Z)
            end
        end
    end)
end

function stopFlee()
    if fleeTask then
        fleeTask:Disconnect()
        fleeTask = nil
    end
end

-- Highlights Roles
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
        rolesTask = nil
    end)
end

function stopScanRoles()
    _G.TrackRoles = false
    clearHighlights()
    rolesTask = nil
end

-- Pick Gun
function startPickGun()
    if pickGunTask then return end
    pickGunTask = task.spawn(function()
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
                    task.wait(2)
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
    pickGunTask = nil
end

-- Interface Turtle Lib

w:Toggle("🎈 AutoFarm BeachBalls", false, function(v)
    _G.Farm = v
    if v then startAutoFarm() else stopAutoFarm() end
end)

w:Toggle("💪 God Mode", false, function(v)
    _G.GodMode = v
    if v then setupGodMode() else stopGodMode() end
end)

w:Toggle("🏃‍♂️ Fuir le Tueur", false, function(v)
    _G.FuirTueur = v
    if v then startFlee() else stopFlee() end
end)

w:Toggle("👁️ Afficher M & S", false, function(v)
    _G.TrackRoles = v
    if v then startScanRoles() else stopScanRoles() end
end)

w:Toggle("🛡️ Afficher Innocents", false, function(v)
    _G.ShowInnocents = v
end)

w:Toggle("🔫 Ramasser le Gun", false, function(v)
    _G.PickGun = v
    if v then startPickGun() else stopPickGun() end
end)

w:Toggle("💤 Anti-AFK", false, function(v)
    if v then startAntiAfk() else stopAntiAfk() end
end)

w:Label("🌀 Script complet et optimisé – mousta34", Color3.fromRGB(238,130,238))
