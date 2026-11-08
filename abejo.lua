local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local function fetch(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" and #body > 0 then return body end
    return nil
end

local fluentChunk = fetch("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
if not fluentChunk then return warn("[TRS] Failed to download Fluent.") end
local Fluent = loadstring(fluentChunk)()

if _G.TRSPanelLoaded then pcall(function() _G.TRSPanelLoaded:Destroy() end) end
_G.TRSPanelLoaded = Instance.new("Folder")

if not isfolder("TRS_Panel") then makefolder("TRS_Panel") end
local CurrentLang = "EN"
if isfile("TRS_Panel/Lang.txt") then
    local read = readfile("TRS_Panel/Lang.txt")
    if read ~= "" then CurrentLang = read end
end

local Translations = {
    EN = { welcome = "Welcome, ", connected = "Connected", executor = "Executor: ", stats = "Live Stats", abilities = "Player Abilities", reset = "Reset Character", vision = "Environment", fullbright = "Fullbright", fullDesc = "Removes fog and darkness", combat = "Combat System", autoClick = "Auto Clicker", clickDesc = "Activates tools automatically", delay = "Delay (ms)", stamina = "Infinite Stamina", players = "Player Actions", tpClosest = "Teleport to Closest", selectPlayer = "Select Player", tpSelected = "Teleport to Selected", esp = "Player ESP", espDesc = "Highlights other players", revAct = "Revenant Tracker", revEsp = "Revenant ESP", revEspDesc = "Highlights the boss", tpRev = "Go to Revenant", revStatus = "Revenant Status", limbs = "Limb Health", farm = "Scrap Farming", scrapEsp = "Scrap ESP", scrapEspDesc = "Highlights scraps", scrapType = "Scrap type filter", scan = "Rescan Scraps", scanDesc = "Forces a new scan now", tpScrap = "Go to Closest Scrap", autoFarm = "Auto Farm", autoFarmDesc = "Teleports to closest scrap", seerEsp = "Seer Orb ESP", seerEspDesc = "Highlights Seer orbs", tpSeer = "Go to Closest Seer Orb", prompts = "Auto Interact", promptsDesc = "Fires prompts automatically", teleport = "Teleport Locations", goTo = "Go to ", util = "Utilities", antiRag = "Anti Ragdoll", antiBarrier = "Anti Barrier", antiBarrierDesc = "Moves barbed wire away", fastRepair = "Fast Power Repair", fastRepairDesc = "Shortens hold time", antiAfk = "Anti-AFK", opti = "Optimization", optiTerrain = "Remove Terrain Details", optiTerrainDesc = "Removes grass/details", optiMat = "Simplify Materials", optiMatDesc = "SmoothPlastic on map", optiShadow = "Disable Shadows", optiShadowDesc = "Turns off shadows", hop = "Server Hop", hopDesc = "Joins a new server", settings = "Settings", lang = "Language (Reloads UI)", unload = "Unload Panel", unloadDesc = "Removes the panel", logs = "Server Logs", hourLog = "Hour Activations", roundLog = "Round Activations", worldLog = "World Events", none = "None yet.", waiting = "Waiting for events..." },
    MX = { welcome = "Bienvenido, ", connected = "Conectado", executor = "Executor: ", stats = "Stats en Vivo", abilities = "Habilidades", reset = "Reiniciar Personaje", vision = "Entorno", fullbright = "Fullbright", fullDesc = "Quita la niebla y oscuridad", combat = "Sistema de Combate", autoClick = "Auto Clicker", clickDesc = "Activa herramientas automáticamente", delay = "Retardo (ms)", stamina = "Stamina Infinita", players = "Acciones de Jugadores", tpClosest = "Ir al Más Cercano", selectPlayer = "Elegir Jugador", tpSelected = "Ir al Elegido", esp = "ESP de Jugadores", espDesc = "Resalta a otros jugadores", revAct = "Rastreador Revenant", revEsp = "ESP del Revenant", revEspDesc = "Resalta al jefe", tpRev = "Ir al Revenant", revStatus = "Estado del Revenant", limbs = "Salud de Extremidades", farm = "Farmeo de Scraps", scrapEsp = "ESP de Scraps", scrapEspDesc = "Resalta cada scrap", scrapType = "Filtro de tipo", scan = "Reescanear Scraps", scanDesc = "Fuerza un escaneo ahora", tpScrap = "Ir al Scrap Más Cercano", autoFarm = "Auto Farmear", autoFarmDesc = "Teletransporta al scrap más cercano", seerEsp = "ESP de Orbes Seer", seerEspDesc = "Resalta los orbes Seer", tpSeer = "Ir al Orbe Seer Más Cercano", prompts = "Auto Interactuar", promptsDesc = "Activa prompts automáticamente", teleport = "Puntos de Teletransporte", goTo = "Ir a ", util = "Utilidades", antiRag = "Anti Ragdoll", antiBarrier = "Anti Barrera", antiBarrierDesc = "Aleja el alambre", fastRepair = "Reparación Rápida", fastRepairDesc = "Acorta el tiempo de mantener", antiAfk = "Anti-AFK", opti = "Optimización", optiTerrain = "Quitar Detalles del Terreno", optiTerrainDesc = "Quita pasto/detalles", optiMat = "Simplificar Materiales", optiMatDesc = "SmoothPlastic en el mapa", optiShadow = "Apagar Sombras", optiShadowDesc = "Desactiva sombras", hop = "Server Hop", hopDesc = "Salta a otro servidor", settings = "Ajustes", lang = "Idioma (Recarga UI)", unload = "Descargar Panel", unloadDesc = "Quita el panel", logs = "Registros del Servidor", hourLog = "Horas Activadas", roundLog = "Rondas Activadas", worldLog = "Eventos del Mundo", none = "Nada todavía.", waiting = "Esperando eventos..." }
}
local L = Translations[CurrentLang]

local Window = Fluent:CreateWindow({
    Title = "The Revenant: Sunrisen [HALLOWS] - HUD Made By @kyyabe08",
    SubTitle = "v26.0",
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
local function doTeleport(pos) local h = getHRP(); if h and pos then h.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)); return true end return false end
local function notify(title, content) 
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = content,
            Duration = 4,
            Icon = "rbxassetid://13491664797"
        })
    end)
end
local function getExecutor() if identifyexecutor then local ok, name = pcall(identifyexecutor); if ok then return name end end return "Unknown" end

Tabs.Main:AddSection("Account Information")
Tabs.Main:AddParagraph({ Title = "The Revenant: Sunrisen [HALLOWS]", Content = "HUD Made By @kyyabe08\n" .. L.welcome .. LocalPlayer.Name })
Tabs.Main:AddParagraph({ Title = "System Status", Content = string.format("Connected: %s\n%s%s", L.connected, L.executor, getExecutor()) })
UI.LiveStats = Tabs.Main:AddParagraph({ Title = L.stats, Content = "..." })
Tabs.Main:AddSection(L.abilities)
Tabs.Main:AddButton({ Title = L.reset, Icon = "refresh-cw", Callback = function() local h = getHumanoid(); if h then h.Health = 0 end end })
Tabs.Main:AddSection(L.vision)
Tabs.Main:AddToggle("Fullbright", { Title = L.fullbright, Description = L.fullDesc, Default = false, Callback = function(s)
    if s then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
    else
        Lighting.Ambient = Color3.fromRGB(70, 70, 70); Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.FogEnd = 1000; Lighting.GlobalShadows = true
    end
end })

Tabs.Combat:AddSection(L.combat)
local _autoClick = false
Tabs.Combat:AddToggle("AutoClicker", { Title = L.autoClick, Description = L.clickDesc, Default = false, Callback = function(s) _autoClick = s end })
local _clickDelay = 0.1
Tabs.Combat:AddSlider("ClickDelay", { Title = L.delay, Default = 100, Min = 10, Max = 1000, Rounding = 0, Callback = function(v) _clickDelay = v / 1000 end })

task.spawn(function()
    while task.wait(_clickDelay) do
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
                if tool then pcall(function() tool:Activate() end) end
            end
        end
    end
end)

Tabs.Revenant:AddSection(L.revAct)
UI.revPara = Tabs.Revenant:AddParagraph({ Title = L.revStatus, Content = "Not spawned" })
UI.revEsp = Tabs.Revenant:AddToggle("RevESP", { Title = L.revEsp, Description = L.revEspDesc, Default = false })
Tabs.Revenant:AddButton({ Title = L.tpRev, Icon = "navigation", Callback = function()
    local npcs = Workspace:FindFirstChild("NPCs")
    local rev = npcs and npcs:FindFirstChild("Revenant")
    local hrp = rev and rev:FindFirstChild("HumanoidRootPart")
    if hrp then doTeleport(hrp.Position) end
end })

local revStatus = "none"
task.spawn(function()
    while task.wait(1) do
        local npcs = Workspace:FindFirstChild("NPCs")
        local rev = npcs and npcs:FindFirstChild("Revenant")
        
        if rev then
            local hum = rev:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.Health > 0 and revStatus ~= "alive" then
                    revStatus = "alive"
                    notify("Revenant", "The Revenant has spawned!")
                elseif hum.Health <= 0 and revStatus == "alive" then
                    revStatus = "dead"
                    notify("Revenant", "The Revenant has died!")
                end
            end
        else
            if revStatus == "alive" or revStatus == "dead" then
                revStatus = "none"
            end
        end
    end
end)

Tabs.Farm:AddSection(L.farm)
local ScrapHighlights = {}
Tabs.Farm:AddButton({ Title = L.scan, Icon = "search", Callback = function()
    for _, hl in pairs(ScrapHighlights) do if hl then hl:Destroy() end end
    ScrapHighlights = {}
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
end })
Tabs.Farm:AddButton({ Title = L.tpScrap, Icon = "navigation", Callback = function()
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
local _autoFarmScraps = false
Tabs.Farm:AddToggle("AutoFarm", { Title = L.autoFarm, Icon = "map-pin", Default = false, Callback = function(s) _autoFarmScraps = s end })

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

Tabs.Players:AddSection(L.players)
local PlayerESP = {}
Tabs.Players:AddToggle("PlayerESP", { Title = L.esp, Icon = "eye", Default = false })
Tabs.Players:AddButton({ Title = L.tpClosest, Icon = "navigation", Callback = function()
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

Tabs.Teleport:AddSection(L.teleport)
local locs = {
    ["Shop"] = Vector3.new(-287, -13, -454), ["Power Station"] = Vector3.new(-244, 21, 212),
    ["Scrap Building"] = Vector3.new(-458, -3, 23), ["Bunker Elevator"] = Vector3.new(-97, -61, 167),
    ["Bunker Inside"] = Vector3.new(-137, -112, 359), ["Church"] = Vector3.new(359, 16, 403),
    ["Cave"] = Vector3.new(110, 14, -209)
}
for name, pos in pairs(locs) do Tabs.Teleport:AddButton({ Title = L.goTo .. name, Icon = "map-pin", Callback = function() doTeleport(pos) end }) end

Tabs.Utilities:AddSection(L.util)
Tabs.Utilities:AddToggle("AntiRagdoll", { Title = L.antiRag, Icon = "shield-check", Default = true })
task.spawn(function()
    while task.wait(0.5) do
        if Options.AntiRagdoll.Value and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end) end
        end
    end
end)
Tabs.Utilities:AddButton({ Title = L.hop, Icon = "server", Callback = function()
    notify("Server Hop", "Searching...")
    pcall(function()
        local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, v in pairs(servers.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer)
                break
            end
        end
    end)
end })

Tabs.Logs:AddSection(L.logs)
local hourText, roundText, worldText = Tabs.Logs:AddParagraph({ Title = L.hourLog, Content = "None yet." }), Tabs.Logs:AddParagraph({ Title = L.roundLog, Content = "None yet." }), Tabs.Logs:AddParagraph({ Title = L.worldLog, Content = "Waiting for events..." })
local hourHistory, roundHistory, worldHistory = {}, {}, {}

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

local function addWorldLog(text, color)
    table.insert(worldHistory, 1, "[" .. os.date("%X") .. "] " .. text)
    if #worldHistory > 10 then table.remove(worldHistory) end
    updateLogs()
    if color then notify("Event", text) end
end

task.spawn(function()
    local RS_Values = ReplicatedStorage:WaitForChild("Values", 10)
    if not RS_Values then return end
    local HourActive = RS_Values:WaitForChild("HourActive", 10)
    local HourName = HourActive and HourActive:WaitForChild("HourName", 10)
    if HourName then
        HourName.Changed:Connect(function(val)
            if val and val ~= "" and val ~= "None" then
                hourHistory[val] = (hourHistory[val] or 0) + 1
                addWorldLog("Hour Activated: " .. val, Color3.fromRGB(255, 200, 0))
                notify("Hour", val .. " has started!")
                updateLogs()
            end
        end)
    end
    local SRoundActive = RS_Values:WaitForChild("SRoundActive", 10)
    local RoundName = SRoundActive and SRoundActive:WaitForChild("RoundName", 10)
    if RoundName then
        RoundName.Changed:Connect(function(val)
            if val and val ~= "" and val ~= "None" then
                roundHistory[val] = (roundHistory[val] or 0) + 1
                addWorldLog("Round Activated: " .. val, Color3.fromRGB(200, 50, 200))
                notify("Round", val .. " has started!")
                updateLogs()
            end
        end)
    end
    local BM_Active = RS_Values:FindFirstChild("BlackMarketActive")
    if BM_Active then
        BM_Active.Changed:Connect(function(val)
            if val then
                addWorldLog("Black Market is OPEN", Color3.fromRGB(0, 255, 0))
                notify("Black Market", "The Black Market has opened!")
            else
                addWorldLog("Black Market CLOSED", Color3.fromRGB(255, 0, 0))
                notify("Black Market", "The Black Market has closed.")
            end
        end)
    end
end)

task.spawn(function()
    local shedExisted = false
    while task.wait(2) do
        local shed = Workspace:FindFirstChild("Shed")
        if shed and not shedExisted then
            shedExisted = true
            addWorldLog("Shed has spawned!", Color3.fromRGB(150, 0, 255))
            notify("Shed", "The Shed has appeared!")
        elseif not shed and shedExisted then
            shedExisted = false
            addWorldLog("Shed has despawned.", Color3.fromRGB(100, 100, 100))
        end
    end
end)

Tabs.Settings:AddSection(L.settings)
Tabs.Settings:AddDropdown("Language", {
    Title = L.lang, Values = { "English", "Español" },
    Default = (CurrentLang == "EN" and "English") or "Español", Multi = false,
    Callback = function(v)
        local newLang = (v == "English" and "EN") or "MX"
        if newLang ~= CurrentLang then
            if writefile then pcall(writefile, "TRS_Panel/Lang.txt", newLang) end
            notify("System", "Reloading UI...")
            task.wait(1)
            if Fluent then Fluent:Destroy() end
            _G.TRSPanelLoaded:Destroy()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/abehix/TRS-Hud/main/abejo.lua"))()
        end
    end
})
Tabs.Settings:AddButton({ Title = "Force Reload", Icon = "refresh-cw", Callback = function()
    if Fluent then Fluent:Destroy() end
    _G.TRSPanelLoaded:Destroy()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/abehix/TRS-Hud/main/abejo.lua"))()
end })

task.spawn(function()
    local lastFrame = tick()
    local frames = 0
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - lastFrame >= 1 then
            local fps = frames; frames = 0; lastFrame = tick()
            local hum = getHumanoid(); local hrp = getHRP()
            if UI.LiveStats then
                local hpText, speedText = "0", "0"
                if hum and hrp then
                    hpText = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                    local vel = hrp.AssemblyLinearVelocity
                    speedText = math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude)
                end
                UI.LiveStats:SetDesc(string.format("Health: %s\nWalkSpd: %s\nFPS: %d", hpText, speedText, fps))
            end
            if UI.revPara then
                local npcs = Workspace:FindFirstChild("NPCs")
                local rev = npcs and npcs:FindFirstChild("Revenant")
                if rev then
                    local rHum = rev:FindFirstChildOfClass("Humanoid")
                    UI.revPara:SetDesc(rHum and ("Health: " .. math.floor(rHum.Health)) or "Not spawned")
                else
                    UI.revPara:SetDesc("Not spawned")
                end
            end
        end
    end)
end)

Window:SelectTab(1)
notify("TRS Panel", "System Initialized.")

LocalPlayer.CharacterRemoving:Connect(function() 
    for _, hl in pairs(ScrapHighlights) do if hl then hl:Destroy() end end
    ScrapHighlights = {}
    _autoFarmScraps = false
end)
