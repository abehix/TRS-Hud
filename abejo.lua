local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local function fetch(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" and #body > 0 then return body end
    return nil
end

-- Cargamos Fluent sin aditamentos (SaveManager quitado para evitar crashes)
local fluentChunk = fetch("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
if not fluentChunk then return warn("[TRS] No se pudo descargar Fluent. Revisa tu internet.") end
local Fluent = loadstring(fluentChunk)()

-- Limpieza de versiones anteriores
if _G.TRSPanelLoaded then pcall(function() _G.TRSPanelLoaded:Destroy() end) end
_G.TRSPanelLoaded = Instance.new("Folder")

local CurrentLang = "EN"
local Translations = {
    EN = { welcome = "Welcome, ", connected = "Connected", executor = "Executor: ", stats = "Live Stats", abilities = "Player Abilities", reset = "Reset Character", vision = "Environment", fullbright = "Fullbright", fullDesc = "Removes fog and darkness", combat = "Combat System", autoClick = "Auto Clicker", clickDesc = "Activates tools automatically", delay = "Delay (ms)", players = "Player Actions", tpClosest = "Teleport to Closest", esp = "Player ESP", espDesc = "Highlights other players", revAct = "Revenant Tracker", revEsp = "Revenant ESP", revEspDesc = "Highlights the boss", tpRev = "Go to Revenant", revStatus = "Revenant Status", limbs = "Limb Health", farm = "Scrap Farming", scan = "Rescan Scraps", tpScrap = "Go to Closest Scrap", autoFarm = "Auto Farm", prompts = "Auto Interact", teleport = "Teleport Locations", goTo = "Go to ", util = "Utilities", antiRag = "Anti Ragdoll", antiAfk = "Anti-AFK", opti = "Optimization", optiTerrain = "Remove Terrain Details", optiMat = "Simplify Materials", optiShadow = "Disable Shadows", hop = "Server Hop", settings = "Settings", lang = "Language", logs = "Server Logs", hourLog = "Hour Activations", roundLog = "Round Activations", worldLog = "World Events" },
    MX = { welcome = "Bienvenido, ", connected = "Conectado", executor = "Executor: ", stats = "Stats en Vivo", abilities = "Habilidades", reset = "Reiniciar Personaje", vision = "Entorno", fullbright = "Fullbright", fullDesc = "Quita la niebla y oscuridad", combat = "Sistema de Combate", autoClick = "Auto Clicker", clickDesc = "Activa herramientas automáticamente", delay = "Retardo (ms)", players = "Acciones de Jugadores", tpClosest = "Ir al Más Cercano", esp = "ESP de Jugadores", espDesc = "Resalta a otros jugadores", revAct = "Rastreador Revenant", revEsp = "ESP del Revenant", revEspDesc = "Resalta al jefe", tpRev = "Ir al Revenant", revStatus = "Estado del Revenant", limbs = "Salud de Extremidades", farm = "Farmeo de Scraps", scan = "Reescanear Scraps", tpScrap = "Ir al Scrap Más Cercano", autoFarm = "Auto Farmear", prompts = "Auto Interactuar", teleport = "Puntos de Teletransporte", goTo = "Ir a ", util = "Utilidades", antiRag = "Anti Ragdoll", antiAfk = "Anti-AFK", opti = "Optimización", optiTerrain = "Quitar Detalles del Terreno", optiMat = "Simplificar Materiales", optiShadow = "Apagar Sombras", hop = "Server Hop", settings = "Ajustes", lang = "Idioma", logs = "Registros del Servidor", hourLog = "Horas Activadas", roundLog = "Rondas Activadas", worldLog = "Eventos del Mundo" }
}
local L = Translations[CurrentLang]

local Window = Fluent:CreateWindow({
    Title = "The Revenant: Sunrisen [HALLOWS] - HUD Made By @kyyabe08",
    SubTitle = "v25.0 Debug",
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
local function notify(title, content) Fluent:Notify({ Title = title, Content = content, Duration = 4 }) end
local function getExecutor() if identifyexecutor then local ok, name = pcall(identifyexecutor); if ok then return name end end return "Unknown" end

-- TOASTS
local ToastGui = Instance.new("ScreenGui")
ToastGui.Name = "TRS_Toasts"
ToastGui.ResetOnSpawn = false
ToastGui.Parent = CoreGui
local ToastLayout = Instance.new("UIListLayout")
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ToastLayout.Padding = UDim.new(0, 10)
ToastLayout.Parent = ToastGui

local function showToast(text, color)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Parent = ToastGui
    local stroke = Instance.new("UIStroke", frame); stroke.Color = color
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -10, 1, 0); label.BackgroundTransparency = 1; label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1); label.Font = Enum.Font.GothamBold; label.TextSize = 12
    task.spawn(function()
        task.wait(4)
        TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        task.wait(0.5)
        if frame.Parent then frame:Destroy() end
    end)
end

-- ==========================================
-- 1. DASHBOARD
-- ==========================================
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

-- ==========================================
-- 2. COMBAT
-- ==========================================
Tabs.Combat:AddSection(L.combat)
local _autoClick = false
Tabs.Combat:AddToggle("AutoClicker", { Title = L.autoClick, Description = L.clickDesc, Default = false, Callback = function(s) _autoClick = s end })

task.spawn(function()
    while task.wait(0.1) do
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

-- ==========================================
-- 3. REVENANT
-- ==========================================
Tabs.Revenant:AddSection(L.revAct)
UI.revPara = Tabs.Revenant:AddParagraph({ Title = L.revStatus, Content = "Not spawned" })
UI.tpRev = Tabs.Revenant:AddButton({ Title = L.tpRev, Icon = "navigation", Callback = function()
    local npcs = Workspace:FindFirstChild("NPCs")
    local rev = npcs and npcs:FindFirstChild("Revenant")
    local hrp = rev and rev:FindFirstChild("HumanoidRootPart")
    if hrp then doTeleport(hrp.Position) end
end })

-- ==========================================
-- 4. FARM
-- ==========================================
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

-- ==========================================
-- 5. PLAYERS
-- ==========================================
Tabs.Players:AddSection(L.players)
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

-- ==========================================
-- 6. TELEPORT & UTILITIES
-- ==========================================
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

-- ==========================================
-- 7. SETTINGS
-- ==========================================
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
            if ToastGui then ToastGui:Destroy() end
            _G.TRSPanelLoaded:Destroy()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/abehix/TRS-Hud/main/abejo.lua"))()
        end
    end
})

Tabs.Settings:AddButton({ Title = "Force Reload (Fix UI)", Icon = "refresh-cw", Callback = function()
    if Fluent then Fluent:Destroy() end
    if ToastGui then ToastGui:Destroy() end
    _G.TRSPanelLoaded:Destroy()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/abehix/TRS-Hud/main/abejo.lua"))()
end })

-- ==========================================
-- LOOPS
-- ==========================================
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
