if _G.TRSPanelLoaded then pcall(function() _G.TRSPanelLoaded:Destroy() end) end
_G.TRSPanelLoaded = Instance.new("Folder")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local function safeGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then return res end
    
    return nil
end

local FluentSource = safeGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
if not FluentSource then return warn("[TRS] Error cargando UI.") end

local Fluent = loadstring(FluentSource)()
local SaveManager = loadstring(safeGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(safeGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Connections = setmetatable({}, { __mode = "k" })
local function track(conn) if conn then Connections[conn] = true end return conn end
local function disconnectAll() for conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end Connections = setmetatable({}, { __mode = "k" }) end

if not isfolder("TRS_Panel") then makefolder("TRS_Panel") end
local CurrentLang = "EN"
if isfile("TRS_Panel/Lang.txt") then
    local read = readfile("TRS_Panel/Lang.txt")
    if read ~= "" then CurrentLang = read end
end

local Translations = {
    EN = { welcome = "Welcome, ", connected = "Connected to Server", executor = "Executor: ", stats = "Live Stats", abilities = "Abilities & Speed", loopSpeed = "LoopSpeed (Infinite Yield)", enterSpeed = "Enter your desired WalkSpeed:", reset = "Reset Character", vision = "Environment", fullbright = "Fullbright", combat = "Combat", autoClick = "Auto Clicker", players = "Players", tpClosest = "Teleport to Closest Player", revAct = "Revenant Tracker", revEsp = "Revenant ESP", tpRev = "Go to Revenant", farm = "Scrap Farming", scan = "Scan Scraps", autoFarm = "Auto Farm", prompts = "Auto Interact", teleport = "Map Teleport", util = "Utilities", antiRag = "Anti Ragdoll", antiAfk = "Anti-AFK", settings = "Settings", logs = "Server Logs", hourLog = "Hour Activations", roundLog = "Round Activations" },
    MX = { welcome = "Bienvenido, ", connected = "Conectado al Servidor", executor = "Executor: ", stats = "Stats en Vivo", abilities = "Habilidades y Velocidad", loopSpeed = "LoopSpeed (Infinite Yield)", enterSpeed = "Ingresa tu velocidad (WalkSpeed):", reset = "Reiniciar Personaje", vision = "Entorno", fullbright = "Fullbright", combat = "Combate", autoClick = "Auto Clicker", players = "Jugadores", tpClosest = "Ir al Jugador Más Cercano", revAct = "Rastreador Revenant", revEsp = "ESP del Revenant", tpRev = "Ir al Revenant", farm = "Farmeo de Scraps", scan = "Escanear Scraps", autoFarm = "Auto Farmear", prompts = "Auto Interactuar", teleport = "Teletransporte", util = "Utilidades", antiRag = "Anti Ragdoll", antiAfk = "Anti-AFK", settings = "Ajustes", logs = "Registros del Servidor", hourLog = "Horas Activadas", roundLog = "Rondas Activadas" }
}
local L = Translations[CurrentLang]

local Window = Fluent:CreateWindow({
    Title = "The Revenant: Sunrisen [HALLOWS 🎃] - HUD Made By @kyyabe08",
    SubTitle = "v16.0 Ultimate Pro Edition",
    TabWidth = 180,
    Size = UDim2.fromOffset(650, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Players = Window:AddTab({ Title = "Players", Icon = "users" }),
    Revenant = Window:AddTab({ Title = "Revenant", Icon = "skull" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "shovel" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map" }),
    Utilities = Window:AddTab({ Title = "Utilities", Icon = "shield" }),
    Logs = Window:AddTab({ Title = "Server Logs", Icon = "scroll-text" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options
local UI = {}

local function getHRP() local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHumanoid() local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function doTeleport(pos) local h = getHRP(); if h and pos then h.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)); return true end return false end
local function notify(title, content) Fluent:Notify({ Title = title, Content = content, Duration = 4 }) end
local function getExecutor() if identifyexecutor then local ok, name = pcall(identifyexecutor); if ok then return name end end return "Unknown" end

-- ==========================================
-- 1. DASHBOARD & INFO
-- ==========================================
Tabs.Main:AddSection("Account Information")
UI.HeaderPara = Tabs.Main:AddParagraph({ 
    Title = "The Revenant: Sunrisen [HALLOWS 🎃]", 
    Content = "HUD Made By @kyyabe08\n" .. L.welcome .. LocalPlayer.Name 
})
UI.NetStats = Tabs.Main:AddParagraph({ 
    Title = "System Status", 
    Content = string.format("🟢 %s\n⚙️ %s%s", L.connected, L.executor, getExecutor()) 
})
UI.LiveStats = Tabs.Main:AddParagraph({ Title = L.stats, Content = "..." })

Tabs.Main:AddSection(L.abilities)
local _loopSpeed = false
local _loopSpeedVal = 16

UI.loopSpeed = Tabs.Main:AddToggle("LoopSpeed", {
    Title = L.loopSpeed,
    Default = false,
    Callback = function(state)
        _loopSpeed = state
        if state then
            local input = Window:Dialog({
                Title = L.loopSpeed,
                Content = L.enterSpeed,
                Buttons = { { Title = "Set", Callback = function() end }, { Title = "Cancel", Callback = function() Options.LoopSpeed:Set(false); _loopSpeed = false end } }
            })
            -- Nota: Fluent Dialog no soporta textbox nativo fácilmente, usamos un Input personalizado
            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(0, 200, 0, 30)
            textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            textBox.PlaceholderText = "WalkSpeed"
            textBox.Parent = input.Main
            textBox.Position = UDim2.new(0.5, -100, 1, -35)
            textBox.FocusLost:Connect(function()
                local num = tonumber(textBox.Text)
                if num then _loopSpeedVal = num end
                textBox:Destroy()
            end)
        end
    end
})

task.spawn(function()
    while task.wait(0.1) do
        if _loopSpeed then
            local hum = getHumanoid()
            if hum and hum.WalkSpeed ~= _loopSpeedVal then hum.WalkSpeed = _loopSpeedVal end
        end
    end
end)

UI.reset = Tabs.Main:AddButton({ Title = L.reset, Callback = function() local h = getHumanoid(); if h then h.Health = 0 end end })

Tabs.Main:AddSection(L.vision)
UI.fullbright = Tabs.Main:AddToggle("Fullbright", { Title = L.fullbright, Default = false, Callback = function(s)
    if s then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
    else
        Lighting.Ambient = Color3.fromRGB(70, 70, 70); Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.FogEnd = 1000; Lighting.GlobalShadows = true
    end
end })

-- ==========================================
-- 2. COMBAT & ANTI-AFK
-- ==========================================
Tabs.Combat:AddSection(L.combat)
local _autoClick = false
local _clickDelay = 0.1
UI.autoClick = Tabs.Combat:AddToggle("AutoClicker", { Title = L.autoClick, Default = false, Callback = function(s) _autoClick = s end })
UI.clickDelay = Tabs.Combat:AddSlider("ClickDelay", { Title = "Delay (ms)", Default = 100, Min = 10, Max = 1000, Rounding = 0, Callback = function(v) _clickDelay = v / 1000 end })

task.spawn(function()
    while true do
        task.wait(_clickDelay)
        if _autoClick and LocalPlayer.Character then
            local cam = workspace.CurrentCamera
            if cam then
                local center = cam.ViewportSize / 2
                pcall(function()
                    VirtualUser:Button1Down(Vector2.new(center.X, center.Y), cam.CFrame)
                    task.wait(0.01)
                    VirtualUser:Button1Up(Vector2.new(center.X, center.Y), cam.CFrame)
                end)
                local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool.Parent == LocalPlayer.Character then pcall(function() tool:Activate() end) end
            end
        end
    end
end)

local _antiAfk = true
UI.antiAfkToggle = Tabs.Utilities:AddToggle("AntiAFK", { Title = L.antiAfk, Default = true, Callback = function(s) _antiAfk = s end })
task.spawn(function()
    while task.wait(60) do
        if _antiAfk then
            pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
        end
    end
end)

-- ==========================================
-- 3. REVENANT TRACKER
-- ==========================================
Tabs.Revenant:AddSection(L.revAct)
local revESP = nil
UI.revEspToggle = Tabs.Revenant:AddToggle("RevESP", { Title = L.revEsp, Default = false })
UI.tpRev = Tabs.Revenant:AddButton({ Title = L.tpRev, Callback = function()
    local npcs = Workspace:FindFirstChild("NPCs")
    local rev = npcs and npcs:FindFirstChild("Revenant")
    local hrp = rev and rev:FindFirstChild("HumanoidRootPart")
    if hrp then doTeleport(hrp.Position) end
end })

local revAlive = false
local revLastHP = 0

task.spawn(function()
    while task.wait(1) do
        if Options.RevESP.Value then
            local npcs = Workspace:FindFirstChild("NPCs")
            local rev = npcs and npcs:FindFirstChild("Revenant")
            if rev and not revESP then
                revESP = Instance.new("Highlight")
                revESP.FillColor = Color3.fromRGB(255, 0, 100)
                revESP.FillTransparency = 0.4
                revESP.OutlineColor = Color3.fromRGB(255, 255, 255)
                revESP.Adornee = rev
                revESP.Parent = rev
            elseif not rev and revESP then
                revESP:Destroy(); revESP = nil
            end
        elseif revESP then
            revESP:Destroy(); revESP = nil
        end

        -- Revenant Events
        local npcs = Workspace:FindFirstChild("NPCs")
        local rev = npcs and npcs:FindFirstChild("Revenant")
        local hum = rev and rev:FindFirstChildOfClass("Humanoid")
        
        if rev and hum then
            if not revAlive then
                revAlive = true
                notify("🚨 Revenant", "The Revenant has spawned!")
            end
            if hum.Health <= 0 and revLastHP > 0 then
                revAlive = false
                notify("💀 Revenant", "The Revenant has died!")
            end
            revLastHP = hum.Health
        else
            if revAlive then
                revAlive = false
                revLastHP = 0
                notify("❓ Revenant", "The Revenant has despawned/left.")
            end
        end
    end
end)

-- ==========================================
-- 4. FARM & SCRAPS
-- ==========================================
Tabs.Farm:AddSection(L.farm)
local ScrapHighlights = {}
local _autoFarmScraps = false
local _autoPrompt = false

local function clearHighlights()
    for scrap, hl in pairs(ScrapHighlights) do if hl and hl.Parent then hl:Destroy() end end
    table.clear(ScrapHighlights)
end

local function scanScraps()
    clearHighlights()
    local map = Workspace:FindFirstChild("MAP") or Workspace:FindFirstChild("Map")
    local folder = map and map:FindFirstChild("Scraps")
    if not folder then return notify("Farm", "Scraps not found.") end
    local count = 0
    for _, desc in ipairs(folder:GetDescendants()) do
        if desc:IsA("Model") and (desc.Name == "Scrap" or desc.Name:match("^Scrap")) then
            local primary = desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart")
            if primary then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 170, 0); hl.FillTransparency = 0.4
                hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Adornee = desc; hl.Parent = desc
                ScrapHighlights[desc] = hl
                count = count + 1
            end
        end
    end
    notify("Farm", "Found " .. count .. " scraps.")
end

UI.scan = Tabs.Farm:AddButton({ Title = L.scan, Callback = scanScraps })
UI.tpScrap = Tabs.Farm:AddButton({ Title = "Go to Closest Scrap", Callback = function()
    local myHRP = getHRP(); if not myHRP then return end
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
    if closest then local primary = closest.PrimaryPart or closest:FindFirstChildWhichIsA("BasePart"); doTeleport(primary.Position) end
end })
UI.autoFarm = Tabs.Farm:AddToggle("AutoFarm", { Title = L.autoFarm, Default = false, Callback = function(s) _autoFarmScraps = s end })
UI.autoPrompt = Tabs.Farm:AddToggle("AutoPrompt", { Title = L.prompts, Default = false, Callback = function(s) _autoPrompt = s end })

task.spawn(function()
    while task.wait(1) do
        if _autoFarmScraps then
            local myHRP = getHRP()
            if myHRP then
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
                if closest then local primary = closest.PrimaryPart or closest:FindFirstChildWhichIsA("BasePart"); doTeleport(primary.Position) end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.15) do
        if _autoPrompt then
            local myHRP = getHRP()
            if myHRP then
                for _, desc in ipairs(Workspace:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled then
                        local parent = desc.Parent
                        local pos
                        if parent:IsA("BasePart") then pos = parent.Position
                        elseif parent:IsA("Model") then local p = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart"); if p then pos = p.Position end end
                        if pos and (pos - myHRP.Position).Magnitude <= (desc.MaxActivationDistance + 5) then
                            pcall(function()
                                desc.HoldDuration = 0
                                if fireproximityprompt then fireproximityprompt(desc) else desc:InputHoldBegin(); task.wait(); desc:InputHoldEnd() end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- 5. PLAYERS & ESP
-- ==========================================
Tabs.Players:AddSection(L.players)
local PlayerESP = {}
UI.espToggle = Tabs.Players:AddToggle("PlayerESP", { Title = "Player ESP", Default = false })
UI.tpClosest = Tabs.Players:AddButton({ Title = L.tpClosest, Callback = function()
    local myHRP = getHRP(); if not myHRP then return end
    local closest, dist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local target = plr.Character:FindFirstChild("HumanoidRootPart")
            if target then local d = (target.Position - myHRP.Position).Magnitude; if d < dist then dist = d; closest = target end end
        end
    end
    if closest then doTeleport(closest.Position) end
end })

task.spawn(function()
    while task.wait(0.5) do
        if Options.PlayerESP.Value then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and not PlayerESP[plr] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(255, 50, 50); hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.Adornee = plr.Character; hl.Parent = plr.Character
                    PlayerESP[plr] = hl
                end
            end
        else
            for plr, hl in pairs(PlayerESP) do if hl and hl.Parent then hl:Destroy() end PlayerESP[plr] = nil end
        end
    end
end)

-- ==========================================
-- 6. SERVER LOGS (Hours, Rounds, Shed, Market, Players)
-- ==========================================
Tabs.Logs:AddSection(L.logs)
local hourText = Tabs.Logs:AddParagraph({ Title = L.hourLog, Content = "None yet." })
local roundText = Tabs.Logs:AddParagraph({ Title = L.roundLog, Content = "None yet." })
local worldText = Tabs.Logs:AddParagraph({ Title = "World Events", Content = "Waiting for events..." })

local hourHistory = {}
local roundHistory = {}
local worldHistory = {}

local function updateLogs()
    local hStr, rStr, wStr = "", "", ""
    for k, v in pairs(hourHistory) do hStr = hStr .. k .. " (x" .. v .. ")\n" end
    for k, v in pairs(roundHistory) do rStr = rStr .. k .. " (x" .. v .. ")\n" end
    if hStr == "" then hStr = "None" end
    if rStr == "" then rStr = "None" end
    hourText:SetDesc(hStr)
    roundText:SetDesc(rStr)
    
    for i = #worldHistory, 1, -1 do wStr = wStr .. worldHistory[i] .. "\n" end
    if wStr == "" then wStr = "Waiting for events..." end
    worldText:SetDesc(wStr)
end

local function addWorldLog(text)
    table.insert(worldHistory, 1, "[" .. os.date("%X") .. "] " .. text)
    if #worldHistory > 10 then table.remove(worldHistory) end
    updateLogs()
end

-- ReplicatedStorage Trackers
task.spawn(function()
    local RS_Values = ReplicatedStorage:WaitForChild("Values", 10)
    if not RS_Values then return end
    
    local HourActive = RS_Values:WaitForChild("HourActive", 10)
    local HourName = HourActive and HourActive:WaitForChild("HourName", 10)
    if HourName then
        track(HourName.Changed:Connect(function(val)
            if val and val ~= "" and val ~= "None" then
                hourHistory[val] = (hourHistory[val] or 0) + 1
                addWorldLog("Hour Activated: " .. val)
                notify("🕒 Hour", val .. " has started!")
                updateLogs()
            end
        end))
    end

    local SRoundActive = RS_Values:WaitForChild("SRoundActive", 10)
    local RoundName = SRoundActive and SRoundActive:WaitForChild("RoundName", 10)
    if RoundName then
        track(RoundName.Changed:Connect(function(val)
            if val and val ~= "" and val ~= "None" then
                roundHistory[val] = (roundHistory[val] or 0) + 1
                addWorldLog("Round Activated: " .. val)
                notify("⚔️ Round", val .. " has started!")
                updateLogs()
            end
        end))
    end

    local BM_Active = RS_Values:FindFirstChild("BlackMarketActive")
    if BM_Active then
        track(BM_Active.Changed:Connect(function(val)
            if val then
                addWorldLog("Black Market is OPEN")
                notify("💰 Black Market", "The Black Market has opened!")
            else
                addWorldLog("Black Market CLOSED")
                notify("💰 Black Market", "The Black Market has closed.")
            end
        end))
    end
end)

-- Shed Tracker
task.spawn(function()
    local shedExisted = false
    while task.wait(2) do
        local shed = Workspace:FindFirstChild("Shed")
        if shed and not shedExisted then
            shedExisted = true
            addWorldLog("Shed has spawned!")
            notify("🏠 Shed", "The Shed has appeared in the map!")
        elseif not shed and shedExisted then
            shedExisted = false
            addWorldLog("Shed has despawned.")
        end
    end
end)

-- Player Tracker
local function onPlayerAdded(plr)
    if plr ~= LocalPlayer then
        addWorldLog(plr.Name .. " joined the server.")
        notify("👋 Player Joined", plr.Name)
    end
end
local function onPlayerRemoving(plr)
    if plr ~= LocalPlayer then
        addWorldLog(plr.Name .. " left the server.")
        notify("🚪 Player Left", plr.Name)
    end
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ==========================================
-- 7. TELEPORT
-- ==========================================
Tabs.Teleport:AddSection(L.teleport)
local locs = {
    ["Shop"] = Vector3.new(-287, -13, -454), ["Power Station"] = Vector3.new(-244, 21, 212),
    ["Scrap Building"] = Vector3.new(-458, -3, 23), ["Bunker Elevator"] = Vector3.new(-97, -61, 167),
    ["Bunker Inside"] = Vector3.new(-137, -112, 359), ["Church"] = Vector3.new(359, 16, 403),
    ["Cave"] = Vector3.new(110, 14, -209)
}
for name, pos in pairs(locs) do Tabs.Teleport:AddButton({ Title = "Go to " .. name, Callback = function() doTeleport(pos) end }) end

-- ==========================================
-- 8. UTILITIES & SETTINGS
-- ==========================================
Tabs.Utilities:AddSection(L.util)
UI.antiRag = Tabs.Utilities:AddToggle("AntiRagdoll", { Title = L.antiRag, Default = true })
task.spawn(function()
    while task.wait(0.5) do
        if Options.AntiRagdoll.Value and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false); hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false) end) end
        end
    end
end)

Tabs.Settings:AddSection(L.settings)
UI.lang = Tabs.Settings:AddDropdown("Language", {
    Title = "Language / Idioma", Values = { "English", "Español" },
    Default = (CurrentLang == "EN" and "English") or "Español", Multi = false,
    Callback = function(v)
        local newLang = (v == "English" and "EN") or "MX"
        if newLang ~= CurrentLang then
            writefile("TRS_Panel/Lang.txt", newLang)
            notify("System", "Reloading UI...")
            task.wait(1.5)
            if Fluent then Fluent:Destroy() end
            _G.TRSPanelLoaded:Destroy()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/abehix/TRS-Hud/main/abejo.lua"))()
        end
    end
})

if SaveManager and InterfaceManager then
    SaveManager:SetLibrary(Fluent); InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("TRS_Panel"); SaveManager:SetFolder("TRS_Panel/Configs")
    InterfaceManager:BuildInterfaceSection(Tabs.Settings); SaveManager:BuildConfigSection(Tabs.Settings)
end

-- ==========================================
-- 9. LIVE UPDATES LOOP
-- ==========================================
task.spawn(function()
    local lastFrame = tick()
    local frames = 0
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - lastFrame >= 1 then
            local fps = frames; frames = 0; lastFrame = tick()
            local hum = getHumanoid(); local hrp = getHRP()
            local npcs = Workspace:FindFirstChild("NPCs")
            local rev = npcs and npcs:FindFirstChild("Revenant")
            local revHRP = rev and rev:FindFirstChild("HumanoidRootPart")
            
            local hpText, speedText, revText = "0", "0", "N/A"
            if hum and hrp then
                hpText = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                local vel = hrp.AssemblyLinearVelocity
                speedText = math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude)
                if revHRP then revText = math.floor((revHRP.Position - hrp.Position).Magnitude) .. " studs" end
            end
            UI.LiveStats:SetDesc(string.format("Health: %s\nSpeed: %s\nRev Dist: %s\nFPS: %d", hpText, speedText, revText, fps))
        end
    end)
end)

Window:SelectTab(1)
notify("TRS Panel", "System Initialized.")
addWorldLog("HUD Loaded and Monitoring.")

LocalPlayer.CharacterRemoving:Connect(function() clearHighlights(); _autoFarmScraps = false end)

_G.TRSPanelLoaded.Destroying:Connect(function()
    disconnectAll(); clearHighlights()
    for _, hl in pairs(PlayerESP) do if hl and hl.Parent then hl:Destroy() end end
end)
