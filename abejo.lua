local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local function safeGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then return res else return nil end
end

local FluentSource = safeGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
if not FluentSource then return warn("[TRS Panel] Error: No se pudo descargar Fluent.") end

local Fluent = loadstring(FluentSource)()
local SaveManager = loadstring(safeGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(safeGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Connections = setmetatable({}, { __mode = "k" })
local function track(conn)
    if conn then Connections[conn] = true end
    return conn
end

local function disconnectAll()
    for conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = setmetatable({}, { __mode = "k" })
end

-- === SISTEMA DE TRADUCCIONES ===
local Translations = {
    EN = {
        systemInfo = "System Information",
        welcome = "Welcome, ",
        executor = "Executor: ",
        status = "Status: Loaded correctly.",
        stats = "Live Statistics",
        waiting = "Waiting for character...",
        speed = "Speed: ",
        health = "Health: ",
        abilities = "Player Abilities",
        infStamina = "Infinite Stamina",
        infStaminaDesc = "Prevents fatigue when running or attacking.",
        resetChar = "Reset Character",
        resetCharDesc = "Forces immediate respawn.",
        combat = "Combat Automation",
        autoClick = "Auto Clicker",
        autoClickDesc = "Automatically clicks and activates tools.",
        delay = "Delay (ms)",
        players = "Player Actions",
        tpClosest = "Teleport to Closest Player",
        tpClosestDesc = "Teleports you to the nearest player.",
        farm = "Farming System",
        scanScraps = "Scan Scraps",
        scanScrapsDesc = "Highlights scraps on the map.",
        tpScrap = "Go to Closest Scrap",
        tpScrapDesc = "Teleports to the nearest scanned scrap.",
        autoFarm = "Auto Farm",
        autoFarmDesc = "Automatically teleports to the closest scrap.",
        revenant = "Revenant Actions",
        tpRev = "Go to Revenant",
        tpRevDesc = "Teleports to the Revenant NPC.",
        teleport = "Points of Interest",
        goTo = "Go to ",
        utilities = "Server Bypasses",
        antiRagdoll = "Anti Ragdoll",
        antiRagdollDesc = "Prevents your character from falling.",
        settings = "Settings",
        language = "Language / Idioma",
        langDesc = "Select your preferred language."
    },
    MX = {
        systemInfo = "Información del Sistema",
        welcome = "Bienvenido, ",
        executor = "Executor: ",
        status = "Estado: Cargado correctamente.",
        stats = "Estadísticas en Vivo",
        waiting = "Esperando personaje...",
        speed = "Velocidad: ",
        health = "Salud: ",
        abilities = "Habilidades del Jugador",
        infStamina = "Stamina Infinita",
        infStaminaDesc = "Evita el cansancio al correr o atacar.",
        resetChar = "Reiniciar Personaje",
        resetCharDesc = "Fuerza tu respawn inmediato.",
        combat = "Automatización de Combate",
        autoClick = "Auto Clicker",
        autoClickDesc = "Clic automático y activación de herramientas.",
        delay = "Retardo (ms)",
        players = "Acciones de Jugadores",
        tpClosest = "Ir al Jugador Más Cercano",
        tpClosestDesc = "Teletranspórtate al jugador más cercano.",
        farm = "Sistema de Farmeo",
        scanScraps = "Escanear Scraps",
        scanScrapsDesc = "Resalta los scraps en el mapa.",
        tpScrap = "Ir al Scrap Más Cercano",
        tpScrapDesc = "Teletranspórtate al scrap escaneado más cercano.",
        autoFarm = "Auto Farm",
        autoFarmDesc = "Teletransporte automático al scrap más cercano.",
        revenant = "Acciones del Revenant",
        tpRev = "Ir al Revenant",
        tpRevDesc = "Teletranspórtate hacia el NPC Revenant.",
        teleport = "Puntos de Interés",
        goTo = "Ir a ",
        utilities = "Bypasses del Servidor",
        antiRagdoll = "Anti Ragdoll",
        antiRagdollDesc = "Evita que tu personaje se caiga o quede tirado.",
        settings = "Ajustes",
        language = "Language / Idioma",
        langDesc = "Selecciona tu idioma preferido."
    },
    ES = {
        systemInfo = "Información del Sistema",
        welcome = "Bienvenido, ",
        executor = "Executor: ",
        status = "Estado: Cargado correctamente.",
        stats = "Estadísticas en Directo",
        waiting = "Esperando personaje...",
        speed = "Velocidad: ",
        health = "Salud: ",
        abilities = "Habilidades del Jugador",
        infStamina = "Estamina Infinita",
        infStaminaDesc = "Evita el cansancio al correr o atacar.",
        resetChar = "Reiniciar Personaje",
        resetCharDesc = "Fuerza tu reaparición inmediata.",
        combat = "Automatización de Combate",
        autoClick = "Auto Clicker",
        autoClickDesc = "Clic automático y activación de herramientas.",
        delay = "Retardo (ms)",
        players = "Acciones de Jugadores",
        tpClosest = "Ir al Jugador Más Cercano",
        tpClosestDesc = "Teletranspórtate al jugador más cercano.",
        farm = "Sistema de Farmeo",
        scanScraps = "Escanear Scraps",
        scanScrapsDesc = "Resalta los scraps en el mapa.",
        tpScrap = "Ir al Scrap Más Cercano",
        tpScrapDesc = "Teletranspórtate al scrap escaneado más cercano.",
        autoFarm = "Auto Farm",
        autoFarmDesc = "Teletransporte automático al scrap más cercano.",
        revenant = "Acciones del Revenant",
        tpRev = "Ir al Revenant",
        tpRevDesc = "Teletranspórtate hacia el NPC Revenant.",
        teleport = "Puntos de Interés",
        goTo = "Ir a ",
        utilities = "Bypasses del Servidor",
        antiRagdoll = "Anti Ragdoll",
        antiRagdollDesc = "Evita que tu personaje se caiga o quede tirado.",
        settings = "Ajustes",
        language = "Language / Idioma",
        langDesc = "Selecciona tu idioma preferido."
    }
}

local CurrentLang = "MX"
local L = Translations[CurrentLang]

local Window = Fluent:CreateWindow({
    Title = "TRS Panel",
    SubTitle = "v11.0 Professional",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 480),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Players = Window:AddTab({ Title = "Players", Icon = "users" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "shovel" }),
    Revenant = Window:AddTab({ Title = "Revenant", Icon = "skull" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map" }),
    Utilities = Window:AddTab({ Title = "Utilities", Icon = "shield" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options
local UI_Elements = {}

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function doTeleport(pos)
    local hrp = getHRP()
    if hrp and pos then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

local function notify(title, content, duration)
    Fluent:Notify({ Title = title, Content = content, Duration = duration or 3 })
end

-- === UI: DASHBOARD ===
UI_Elements.MainSec1 = Tabs.Main:AddSection(L.systemInfo)
UI_Elements.MainPara = Tabs.Main:AddParagraph({
    Title = L.welcome .. LocalPlayer.Name,
    Content = L.executor .. (identifyexecutor and identifyexecutor() or "Unknown") .. "\n" .. L.status
})

UI_Elements.MainSec2 = Tabs.Main:AddSection(L.abilities)
UI_Elements.StaminaToggle = Tabs.Main:AddToggle("StaminaInf", {
    Title = L.infStamina,
    Description = L.infStaminaDesc,
    Default = false,
    Callback = function(state) notify("Habilidades", L.infStamina .. ": " .. (state and "ON" or "OFF")) end
})

UI_Elements.ResetBtn = Tabs.Main:AddButton({
    Title = L.resetChar,
    Description = L.resetCharDesc,
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end
})

-- === UI: COMBAT ===
local _autoClick = false
local _clickDelay = 0.1
UI_Elements.CombatSec = Tabs.Combat:AddSection(L.combat)
UI_Elements.AutoClickToggle = Tabs.Combat:AddToggle("AutoClicker", {
    Title = L.autoClick,
    Description = L.autoClickDesc,
    Default = false,
    Callback = function(state) _autoClick = state end
})
UI_Elements.ClickDelay = Tabs.Combat:AddSlider("ClickDelay", {
    Title = L.delay,
    Default = 100, Min = 10, Max = 1000, Rounding = 0,
    Callback = function(value) _clickDelay = value / 1000 end
})

-- === UI: PLAYERS ===
UI_Elements.PlrSec = Tabs.Players:AddSection(L.players)
UI_Elements.TpClosestBtn = Tabs.Players:AddButton({
    Title = L.tpClosest,
    Description = L.tpClosestDesc,
    Callback = function()
        local myHRP = getHRP()
        if not myHRP then return end
        local closest, dist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local target = plr.Character:FindFirstChild("HumanoidRootPart")
                if target then
                    local d = (target.Position - myHRP.Position).Magnitude
                    if d < dist then dist = d; closest = target end
                end
            end
        end
        if closest then doTeleport(closest.Position) end
    end
})

-- === UI: FARM ===
local ScrapHighlights = {}
local _autoFarmScraps = false

local function clearHighlights()
    for scrap, hl in pairs(ScrapHighlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    table.clear(ScrapHighlights)
end

local function scanScraps()
    clearHighlights()
    local map = Workspace:FindFirstChild("MAP") or Workspace:FindFirstChild("Map")
    local folder = map and map:FindFirstChild("Scraps")
    if not folder then return notify("Farm", "Scraps not found", 4) end
    local count = 0
    for _, desc in ipairs(folder:GetDescendants()) do
        if desc:IsA("Model") and (desc.Name == "Scrap" or desc.Name:match("^Scrap")) then
            local primary = desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart")
            if primary then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 170, 0)
                hl.FillTransparency = 0.4
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Adornee = desc
                hl.Parent = desc
                ScrapHighlights[desc] = hl
                count = count + 1
            end
        end
    end
    notify("Farm", "Found " .. count .. " scraps.", 3)
end

UI_Elements.FarmSec = Tabs.Farm:AddSection(L.farm)
UI_Elements.ScanBtn = Tabs.Farm:AddButton({
    Title = L.scanScraps,
    Description = L.scanScrapsDesc,
    Callback = function() scanScraps() end
})

UI_Elements.TpScrapBtn = Tabs.Farm:AddButton({
    Title = L.tpScrap,
    Description = L.tpScrapDesc,
    Callback = function()
        local myHRP = getHRP()
        if not myHRP then return end
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
        end
    end
})

UI_Elements.AutoFarmToggle = Tabs.Farm:AddToggle("AutoFarm", {
    Title = L.autoFarm,
    Description = L.autoFarmDesc,
    Default = false,
    Callback = function(state) _autoFarmScraps = state end
})

-- === UI: REVENANT ===
UI_Elements.RevSec = Tabs.Revenant:AddSection(L.revenant)
UI_Elements.TpRevBtn = Tabs.Revenant:AddButton({
    Title = L.tpRev,
    Description = L.tpRevDesc,
    Callback = function()
        local npcs = Workspace:FindFirstChild("NPCs")
        local rev = npcs and npcs:FindFirstChild("Revenant")
        local hrp = rev and rev:FindFirstChild("HumanoidRootPart")
        if hrp then doTeleport(hrp.Position) end
    end
})

-- === UI: TELEPORT ===
UI_Elements.TpSec = Tabs.Teleport:AddSection(L.teleport)
local locations = {
    ["Shop"] = Vector3.new(-287, -13, -454),
    ["Power Station"] = Vector3.new(-244, 21, 212),
    ["Scrap Building"] = Vector3.new(-458, -3, 23),
    ["Bunker Elevator"] = Vector3.new(-97, -61, 167),
    ["Bunker Inside"] = Vector3.new(-137, -112, 359),
    ["Church"] = Vector3.new(359, 16, 403),
    ["Cave"] = Vector3.new(110, 14, -209)
}

UI_Elements.LocationBtns = {}
for name, pos in pairs(locations) do
    UI_Elements.LocationBtns[name] = Tabs.Teleport:AddButton({
        Title = L.goTo .. name,
        Callback = function() doTeleport(pos) end
    })
end

-- === UI: UTILITIES ===
UI_Elements.UtilSec = Tabs.Utilities:AddSection(L.utilities)
UI_Elements.AntiRagdollToggle = Tabs.Utilities:AddToggle("AntiRagdoll", {
    Title = L.antiRagdoll,
    Description = L.antiRagdollDesc,
    Default = true,
    Callback = function(state) notify("Utility", L.antiRagdoll .. ": " .. (state and "ON" or "OFF")) end
})

-- === UI: SETTINGS (Language) ===
UI_Elements.SetSec = Tabs.Settings:AddSection(L.settings)
UI_Elements.LangDropdown = Tabs.Settings:AddDropdown("Language", {
    Title = L.language,
    Description = L.langDesc,
    Values = { "English", "Español (Latinoamérica)", "Español (España)" },
    Default = "Español (Latinoamérica)",
    Multi = false,
    Callback = function(value)
        if value == "English" then CurrentLang = "EN"
        elseif value == "Español (Latinoamérica)" then CurrentLang = "MX"
        elseif value == "Español (España)" then CurrentLang = "ES" end
        L = Translations[CurrentLang]
        UpdateLanguage()
    end
})

-- FUNCIÓN QUE ACTUALIZA TODOS LOS TEXTOS
function UpdateLanguage()
    UI_Elements.MainSec1.Title = L.systemInfo
    UI_Elements.MainPara.Title = L.welcome .. LocalPlayer.Name
    UI_Elements.MainPara:SetDesc(L.executor .. (identifyexecutor and identifyexecutor() or "Unknown") .. "\n" .. L.status)
    UI_Elements.MainSec2.Title = L.abilities
    UI_Elements.StaminaToggle:SetTitle(L.infStamina)
    UI_Elements.StaminaToggle:SetDesc(L.infStaminaDesc)
    UI_Elements.ResetBtn:SetTitle(L.resetChar)
    UI_Elements.ResetBtn:SetDesc(L.resetCharDesc)

    UI_Elements.CombatSec.Title = L.combat
    UI_Elements.AutoClickToggle:SetTitle(L.autoClick)
    UI_Elements.AutoClickToggle:SetDesc(L.autoClickDesc)
    UI_Elements.ClickDelay:SetTitle(L.delay)

    UI_Elements.PlrSec.Title = L.players
    UI_Elements.TpClosestBtn:SetTitle(L.tpClosest)
    UI_Elements.TpClosestBtn:SetDesc(L.tpClosestDesc)

    UI_Elements.FarmSec.Title = L.farm
    UI_Elements.ScanBtn:SetTitle(L.scanScraps)
    UI_Elements.ScanBtn:SetDesc(L.scanScrapsDesc)
    UI_Elements.TpScrapBtn:SetTitle(L.tpScrap)
    UI_Elements.TpScrapBtn:SetDesc(L.tpScrapDesc)
    UI_Elements.AutoFarmToggle:SetTitle(L.autoFarm)
    UI_Elements.AutoFarmToggle:SetDesc(L.autoFarmDesc)

    UI_Elements.RevSec.Title = L.revenant
    UI_Elements.TpRevBtn:SetTitle(L.tpRev)
    UI_Elements.TpRevBtn:SetDesc(L.tpRevDesc)

    UI_Elements.TpSec.Title = L.teleport
    for name, btn in pairs(UI_Elements.LocationBtns) do
        btn:SetTitle(L.goTo .. name)
    end

    UI_Elements.UtilSec.Title = L.utilities
    UI_Elements.AntiRagdollToggle:SetTitle(L.antiRagdoll)
    UI_Elements.AntiRagdollToggle:SetDesc(L.antiRagdollDesc)

    UI_Elements.SetSec.Title = L.settings
    UI_Elements.LangDropdown:SetTitle(L.language)
    UI_Elements.LangDropdown:SetDesc(L.langDesc)
end

-- LOOPS (Background Tasks)
task.spawn(function()
    local hooked = false
    while task.wait(1) do
        if Options.StaminaInf.Value and not hooked then
            pcall(function()
                for _, obj in pairs(getgc(true)) do
                    if type(obj) == "function" then
                        local info = debug.getinfo(obj)
                        if info.name == "TakeStamina" then hookfunction(obj, function() return end)
                        elseif info.name == "CheckStamina" then hookfunction(obj, function() return true end) end
                    end
                end
            end)
            hooked = true
        end
    end
end)

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
                if closest then
                    local primary = closest.PrimaryPart or closest:FindFirstChildWhichIsA("BasePart")
                    doTeleport(primary.Position)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if Options.AntiRagdoll.Value and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
                end)
            end
        end
    end
end)

local StatsParagraph = Tabs.Main:AddParagraph({ Title = L.stats, Content = L.waiting })
task.spawn(function()
    while task.wait(1) do
        local hum = getHumanoid()
        local hrp = getHRP()
        if hum and hrp then
            local vel = hrp.AssemblyLinearVelocity
            local spd = math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude)
            local hp = math.floor(hum.Health)
            local maxhp = math.floor(hum.MaxHealth)
            StatsParagraph:SetDesc(string.format("%s%d | %s%d/%d", L.speed, spd, L.health, hp, maxhp))
        else
            StatsParagraph:SetDesc(L.waiting)
        end
    end
end)

if SaveManager and InterfaceManager then
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("TRS_Panel")
    SaveManager:SetFolder("TRS_Panel/Configs")
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)
end

task.wait(0.5)
Window:SelectTab(1)
notify("TRS Panel", "Loaded / Cargado", 3)

LocalPlayer.CharacterRemoving:Connect(function()
    clearHighlights()
    _autoFarmScraps = false
end)

script.Destroying:Connect(function()
    disconnectAll()
    clearHighlights()
end)
