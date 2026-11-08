if _G.__TRS_WINDOW then
    pcall(function() _G.__TRS_WINDOW:Destroy() end)
    _G.__TRS_WINDOW = nil
end
if getgenv and getgenv().TRS_HOOKS then
    for _, h in pairs(getgenv().TRS_HOOKS) do
        pcall(function() h:Disconnect() end)
    end
    getgenv().TRS_HOOKS = nil
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local okFluent, Fluent = pcall(function()
    return loadstring(game:HttpGetAsync("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not okFluent or not Fluent then
    return
end

local okSM, SaveManager = pcall(function()
    return loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)

local okIM, InterfaceManager = pcall(function()
    return loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not okSM then SaveManager = nil end
if not okIM then InterfaceManager = nil end

local Options = Fluent.Options

local Connections = setmetatable({}, { __mode = "k" })
local function track(conn)
    if conn then Connections[conn] = true end
    return conn
end

local Window = Fluent:CreateWindow({
    Title = "TRS Panel",
    SubTitle = "v9.0 Premium",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 480),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
    LoadingTitle = "TRS Panel",
    LoadingSubtitle = "Loading modules and preferences..."
})

_G.__TRS_WINDOW = Window

local Tabs = {
    Main = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Players = Window:AddTab({ Title = "Players", Icon = "users" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "shovel" }),
    Revenant = Window:AddTab({ Title = "Revenant", Icon = "skull" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Utilities = Window:AddTab({ Title = "Utilities", Icon = "wrench" }),
    Optimization = Window:AddTab({ Title = "Optimization", Icon = "gauge" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Notify = {}

function Notify.Success(title, content, duration)
    Fluent:Notify({ Title = title, Content = content, Duration = duration or 3, Icon = "check-circle" })
end

function Notify.Info(title, content, duration)
    Fluent:Notify({ Title = title, Content = content, Duration = duration or 3, Icon = "info" })
end

function Notify.Warning(title, content, duration)
    Fluent:Notify({ Title = title, Content = content, Duration = duration or 4, Icon = "alert-triangle" })
end

function Notify.Error(title, content, duration)
    Fluent:Notify({ Title = title, Content = content, Duration = duration or 5, Icon = "x-circle" })
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function doTeleport(pos)
    if not pos then return false end
    local hum = getHumanoid()
    local hrp = getHRP()
    if not hum or not hrp or hum.Health <= 0 then return false end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    return true
end

Tabs.Main:AddParagraph({ Title = "System Status", Content = "All modules loaded successfully." })
local StatsParagraph = Tabs.Main:AddParagraph({ Title = "Information", Content = "Waiting for data..." })

Tabs.Main:AddSection("Abilities")
local hooksInitialized = false
local oldTakeStamina, oldCheckStamina
local lastHookAttempt = 0

local function InitStaminaHooks()
    if hooksInitialized then return end
    if tick() - lastHookAttempt < 5 then return end
    lastHookAttempt = tick()
    local foundAny = false
    
    pcall(function() setthreadidentity(8) end)
    
    for _, object in pairs(getgc(true)) do
        if typeof(object) == "function" then
            local okInfo, info = pcall(debug.getinfo, object)
            if okInfo and info then
                if info.name == "TakeStamina" and not oldTakeStamina then
                    local ok, result = pcall(hookfunction, object, function(...)
                        if Options.StaminaInf and Options.StaminaInf.Value then
                            local hum = getHumanoid()
                            if hum and hum.Health > 0 then return end
                        end
                        return oldTakeStamina(...)
                    end)
                    if ok then oldTakeStamina = result; foundAny = true end
                elseif info.name == "CheckStamina" and not oldCheckStamina then
                    local ok, result = pcall(hookfunction, object, function(...)
                        if Options.StaminaInf and Options.StaminaInf.Value then
                            local hum = getHumanoid()
                            if hum and hum.Health > 0 then return true end
                        end
                        return oldCheckStamina(...)
                    end)
                    if ok then oldCheckStamina = result; foundAny = true end
                end
            end
        end
    end
    if foundAny then hooksInitialized = true end
end

Tabs.Main:AddToggle("StaminaInf", {
    Title = "Infinite Stamina",
    Default = false,
    Callback = function(state)
        if state and not hooksInitialized then InitStaminaHooks() end
        if state then Notify.Success("Abilities", "Infinite Stamina: ON") else Notify.Info("Abilities", "Infinite Stamina: OFF") end
    end
})

Tabs.Main:AddButton({
    Title = "Reset Character",
    Description = "Fast respawn",
    Callback = function()
        local hum = getHumanoid()
        if hum then Notify.Info("Character", "Resetting character..."); hum.Health = 0
        else Notify.Error("Character", "Humanoid not found.") end
    end
})

Tabs.Combat:AddSection("Automation")
local _autoClick = false
local _clickDelay = 0.1

Tabs.Combat:AddToggle("AutoClicker", {
    Title = "Auto Clicker",
    Default = false,
    Callback = function(state)
        _autoClick = state
        if state then Notify.Success("Combat", "Auto Clicker: ON") else Notify.Info("Combat", "Auto Clicker: OFF") end
    end
})

Tabs.Combat:AddSlider("ClickDelay", {
    Title = "Delay (ms)", Default = 100, Min = 10, Max = 1000, Rounding = 0,
    Callback = function(value) _clickDelay = value / 1000 end
})

task.spawn(function()
    while task.wait(0.05) do
        if _autoClick and LocalPlayer.Character then
            local cam = workspace.CurrentCamera
            if cam then
                local center = cam.ViewportSize / 2
                pcall(function()
                    VirtualUser:Button1Down(Vector2.new(center.X, center.Y), cam.CFrame)
                    task.wait(0.01)
                    VirtualUser:Button1Up(Vector2.new(center.X, center.Y), cam.CFrame)
                end)
                local char = LocalPlayer.Character
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool and tool.Parent == char then pcall(function() tool:Activate() end) end
            end
            task.wait(_clickDelay)
        end
    end
end)

Tabs.Utilities:AddSection("Game Utilities")

local ScrapHighlights = {}
local _autoFarmScraps = false

local function clearHighlights()
    for _, hl in pairs(ScrapHighlights) do if hl then hl:Destroy() end end
    table.clear(ScrapHighlights)
end

local function scanScraps()
    clearHighlights()
    local map = Workspace:FindFirstChild("MAP") or Workspace:FindFirstChild("Map")
    local folder = map and map:FindFirstChild("Scraps")
    if not folder then Notify.Error("Farm", "Scraps folder not found."); return 0 end
    
    local count = 0
    for _, desc in ipairs(folder:GetDescendants()) do
        if desc:IsA("Model") and (desc.Name == "Scrap" or desc.Name:match("^Scrap")) then
            local primary = desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart")
            if primary then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 170, 0)
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Adornee = desc
                hl.Parent = desc
                ScrapHighlights[desc] = hl
                count = count + 1
            end
        end
    end
    if count > 0 then Notify.Success("Farm", "Detected " .. count .. " scraps.") else Notify.Warning("Farm", "No scraps found.") end
    return count
end

Tabs.Farm:AddButton({
    Title = "Scan Scraps",
    Description = "Highlights all scraps on the map",
    Callback = function() scanScraps() end
})

Tabs.Farm:AddButton({
    Title = "Teleport to Closest Scrap",
    Callback = function()
        local myHRP = getHRP()
        if not myHRP then Notify.Error("Farm", "Character unavailable."); return end
        local closest, dist = nil, math.huge
        for scrap, _ in pairs(ScrapHighlights) do
            if scrap.Parent then
                local primary = scrap.PrimaryPart or scrap:FindFirstChildWhichIsA("BasePart")
                if primary then
                    local d = (primary.Position - myHRP.Position).Magnitude
                    if d < dist then dist = d; closest = scrap end
                end
            end
        end
        if closest then
            local primary = closest.PrimaryPart or closest:FindFirstChildWhichIsA("BasePart")
            doTeleport(primary.Position)
            Notify.Success("Farm", "Teleported to Scrap.")
        else Notify.Warning("Farm", "No scanned scraps found.") end
    end
})

Tabs.Farm:AddToggle("AutoFarm", {
    Title = "Auto Farm (Teleport)",
    Default = false,
    Callback = function(state)
        _autoFarmScraps = state
        if state then Notify.Success("Farm", "Auto Farm: ON") else Notify.Info("Farm", "Auto Farm: OFF") end
    end
})

task.spawn(function()
    while task.wait(1) do
        if _autoFarmScraps then
            if next(ScrapHighlights) == nil then scanScraps() end
            local myHRP = getHRP()
            if myHRP then
                local closest, dist = nil, math.huge
                for scrap, hl in pairs(ScrapHighlights) do
                    if scrap.Parent then
                        local primary = scrap.PrimaryPart or scrap:FindFirstChildWhichIsA("BasePart")
                        if primary then
                            local d = (primary.Position - myHRP.Position).Magnitude
                            if d < dist then dist = d; closest = scrap end
                        end
                    else
                        if hl then hl:Destroy() end
                        ScrapHighlights[scrap] = nil
                    end
                end
                if closest then
                    local primary = closest.PrimaryPart or closest:FindFirstChildWhichIsA("BasePart")
                    doTeleport(primary.Position)
                end
            end
        end
    end
end)

Tabs.Revenant:AddSection("NPC Tracking")
local _revenantTracking = false
local _revenantPresent = false
local _revenantConnection = nil
local _revenantRemovedConnection = nil
local _revenantHighlight = nil

local function getRevenant()
    local npcs = Workspace:FindFirstChild("NPCs")
    return npcs and npcs:FindFirstChild("Revenant")
end

local function startRevenantTracking()
    if _revenantConnection then return end
    local rev = getRevenant()
    _revenantPresent = rev ~= nil
    
    if _revenantPresent then 
        Notify.Success("Revenant", "Revenant detected. Highlight enabled.")
        if not _revenantHighlight then
            _revenantHighlight = Instance.new("Highlight")
            _revenantHighlight.FillColor = Color3.fromRGB(255, 0, 0)
            _revenantHighlight.FillTransparency = 0.5
            _revenantHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
            _revenantHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            _revenantHighlight.Adornee = rev
            _revenantHighlight.Parent = rev
        end
    else 
        Notify.Info("Revenant", "Waiting for spawn...") 
    end
    
    _revenantConnection = Workspace.DescendantAdded:Connect(function(desc)
        if desc.Name == "Revenant" and desc:IsA("Model") and not _revenantPresent then
            _revenantPresent = true
            Notify.Success("Revenant", "Revenant spawned. Highlight enabled.")
            if not _revenantHighlight then
                _revenantHighlight = Instance.new("Highlight")
                _revenantHighlight.FillColor = Color3.fromRGB(255, 0, 0)
                _revenantHighlight.FillTransparency = 0.5
                _revenantHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                _revenantHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                _revenantHighlight.Adornee = desc
                _revenantHighlight.Parent = desc
            end
        end
    end)
    track(_revenantConnection)
    
    _revenantRemovedConnection = Workspace.DescendantRemoving:Connect(function(desc)
        if desc.Name == "Revenant" and desc:IsA("Model") and _revenantPresent then
            _revenantPresent = false
            _revenantHighlight = nil
            Notify.Warning("Revenant", "Revenant despawned.")
        end
    end)
    track(_revenantRemovedConnection)
end

local function stopRevenantTracking()
    if _revenantConnection then _revenantConnection:Disconnect(); _revenantConnection = nil end
    if _revenantRemovedConnection then _revenantRemovedConnection:Disconnect(); _revenantRemovedConnection = nil end
    if _revenantHighlight then _revenantHighlight:Destroy(); _revenantHighlight = nil end
    _revenantPresent = false
    Notify.Info("Revenant", "Tracking and Highlight disabled.")
end

Tabs.Revenant:AddToggle("RevenantTrack", {
    Title = "Track Revenant (Highlight)",
    Default = false,
    Callback = function(state)
        _revenantTracking = state
        if state then startRevenantTracking() else stopRevenantTracking() end
    end
})

Tabs.Revenant:AddButton({
    Title = "Teleport to Revenant",
    Callback = function()
        local rev = getRevenant()
        local hrp = rev and rev:FindFirstChild("HumanoidRootPart")
        if hrp then
            doTeleport(hrp.Position)
            Notify.Success("Revenant", "Teleported to Revenant.")
        else Notify.Error("Revenant", "Revenant not found.") end
    end
})

Tabs.Players:AddSection("Player Tracking")
Tabs.Players:AddToggle("PlayerTracker", {
    Title = "Enable Player Tracker",
    Default = false,
    Callback = function(state)
        if state then Notify.Success("Players", "Player Tracker: ON") else Notify.Info("Players", "Player Tracker: OFF") end
    end
})

local TrackerHighlights = {}
task.spawn(function()
    while task.wait(1) do
        if Options.PlayerTracker and Options.PlayerTracker.Value then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if not TrackerHighlights[plr] then
                            local hl = Instance.new("Highlight")
                            hl.FillColor = Color3.fromRGB(0, 255, 0)
                            hl.FillTransparency = 0.7
                            hl.OutlineColor = Color3.fromRGB(0, 255, 0)
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Adornee = plr.Character
                            hl.Parent = plr.Character
                            TrackerHighlights[plr] = hl
                        end
                    end
                end
            end
            for plr, hl in pairs(TrackerHighlights) do
                if not plr.Character or not plr.Character.Parent then
                    if hl then hl:Destroy() end
                    TrackerHighlights[plr] = nil
                end
            end
        else
            for plr, hl in pairs(TrackerHighlights) do
                if hl then hl:Destroy() end
                TrackerHighlights[plr] = nil
            end
        end
    end
end)

Tabs.Players:AddButton({
    Title = "Teleport to Closest Player",
    Callback = function()
        local myHRP = getHRP()
        if not myHRP then Notify.Error("Players", "Character unavailable."); return end
        local closest, dist, closestName = nil, math.huge, nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local target = plr.Character:FindFirstChild("HumanoidRootPart")
                if target then
                    local d = (target.Position - myHRP.Position).Magnitude
                    if d < dist then dist = d; closest = target; closestName = plr.Name end
                end
            end
        end
        if closest and dist <= 500 then
            doTeleport(closest.Position)
            Notify.Success("Players", "Teleported to " .. closestName)
        elseif closest then Notify.Warning("Players", "Closest player is out of range (500 studs).")
        else Notify.Warning("Players", "No nearby players.") end
    end
})

Tabs.Teleport:AddSection("Locations")
local locations = {
    ["Shop"] = Vector3.new(-287, -13, -454),
    ["Power Station"] = Vector3.new(-244, 21, 212),
    ["Scrap Building"] = Vector3.new(-458, -3, 23),
    ["Bunker Elevator"] = Vector3.new(-97, -61, 167),
    ["Bunker Inside"] = Vector3.new(-137, -112, 359),
    ["Church"] = Vector3.new(359, 16, 403),
    ["Cave"] = Vector3.new(110, 14, -209)
}

for name, pos in pairs(locations) do
    Tabs.Teleport:AddButton({
        Title = name,
        Callback = function()
            if doTeleport(pos) then Notify.Success("Teleport", "Traveling to " .. name)
            else Notify.Error("Teleport", "Failed to teleport.") end
        end
    })
end

Tabs.Optimization:AddSection("Visual & Performance")
Tabs.Optimization:AddToggle("OptLighting", {
    Title = "Disable Shadows & Lights",
    Default = false,
    Callback = function(state)
        if state then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 2
            for _, v in pairs(Lighting:GetDescendants()) do
                if v:IsA("PostEffect") or v:IsA("Sky") then v.Enabled = false end
            end
            Notify.Success("Optimization", "Shadows and lights disabled.")
        else
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 100000
            Lighting.Brightness = 1
            Notify.Info("Optimization", "Lights restored.")
        end
    end
})

Tabs.Optimization:AddToggle("OptTextures", {
    Title = "Remove Map Textures",
    Default = false,
    Callback = function(state)
        if state then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
            end
            Notify.Success("Optimization", "Textures hidden.")
        else
            Notify.Info("Optimization", "Textures will return on respawn or map change.")
        end
    end
})

Tabs.Optimization:AddToggle("OptParticles", {
    Title = "Disable All Particles",
    Default = false,
    Callback = function(state)
        if state then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
            Notify.Success("Optimization", "Particles and smoke disabled.")
        end
    end
})

Tabs.Optimization:AddToggle("OptTerrain", {
    Title = "Simplify Terrain (Remove Details)",
    Default = false,
    Callback = function(state)
        if Terrain then
            if state then
                Terrain.Decoration = false
                Notify.Success("Optimization", "Terrain details removed.")
            else
                Terrain.Decoration = true
                Notify.Info("Optimization", "Terrain details restored.")
            end
        else
            Notify.Error("Optimization", "Terrain not found in Workspace.")
        end
    end
})

Tabs.Optimization:AddButton({
    Title = "Destroy Nearby Effects",
    Description = "Clears particles around you",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then
                    if v.Parent and v.Parent:IsA("BasePart") then
                        if (v.Parent.Position - hrp.Position).Magnitude < 150 then
                            v:Destroy()
                        end
                    end
                end
            end
            Notify.Success("Optimization", "Nearby effects destroyed.")
        end
    end
})

Tabs.Optimization:AddButton({
    Title = "Make All Materials Smooth",
    Description = "Removes detailed textures from parts",
    Callback = function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Material ~= Enum.Material.SmoothPlastic then
                v.Material = Enum.Material.SmoothPlastic
            end
        end
        Notify.Success("Optimization", "All materials set to Smooth Plastic.")
    end
})

if SaveManager and InterfaceManager then
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        InterfaceManager:SetFolder("TRS_Panel")
        SaveManager:SetFolder("TRS_Panel/Configs")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        SaveManager:BuildConfigSection(Tabs.Settings)
    end)
end

task.spawn(function()
    task.wait(1.5)
    pcall(function() Window:SelectTab(1) end)
    Notify.Success("TRS Panel", "System initialized successfully.", 4)
end)

task.spawn(function()
    while task.wait(1.5) do
        local hum = getHumanoid()
        local hrp = getHRP()
        if hum and hrp then
            local vel = hrp.AssemblyLinearVelocity
            local speed = math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude)
            local hp = math.floor(hum.Health)
            local maxhp = math.floor(hum.MaxHealth)
            StatsParagraph:SetDesc(string.format("Speed: %d | Health: %d/%d", speed, hp, maxhp))
        else StatsParagraph:SetDesc("Waiting for character...") end
    end
end)

track(LocalPlayer.CharacterAdded:Connect(function()
    hooksInitialized = false
    oldTakeStamina = nil
    oldCheckStamina = nil
end))

track(LocalPlayer.CharacterRemoving:Connect(function()
    clearHighlights()
    _autoFarmScraps = false
end))
