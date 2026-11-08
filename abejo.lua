local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Lighting = game:GetService("Lighting")

local function safeGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then return res end
    return nil
end

local FluentSource = safeGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
if not FluentSource then return warn("[TRS Panel] Error al cargar UI.") end

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

local Translations = {
    EN = { welcome = "Welcome, ", executor = "Executor: ", status = "System Online", stats = "Live Stats", abilities = "Player Abilities", infStamina = "Infinite Stamina", speed = "Speed (WalkSpeed)", jump = "Jump Power", reset = "Reset Character", vision = "Vision / Environment", fullbright = "Fullbright (No Fog)", combat = "Combat Automation", autoClick = "Auto Clicker", clickDesc = "Clicks and activates tools automatically.", players = "Player Actions", tpClosest = "Teleport to Closest Player", esp = "Player ESP (Highlight)", farm = "Farming System", scanScraps = "Scan Scraps", scanDesc = "Highlights scrap models.", tpScrap = "Go to Closest Scrap", autoFarm = "Auto Farm Scraps", autoPrompt = "Auto Interact Prompts", revenant = "Revenant Actions", tpRev = "Go to Revenant", teleport = "Locations", goTo = "Go to ", utilities = "Bypasses", antiRagdoll = "Anti Ragdoll", settings = "Settings", language = "Language", settingsUI = "Interface Settings" },
    MX = { welcome = "Bienvenido, ", executor = "Executor: ", status = "Sistema en Línea", stats = "Estadísticas", abilities = "Habilidades", infStamina = "Stamina Infinita", speed = "Velocidad (WalkSpeed)", jump = "Fuerza de Salto", reset = "Reiniciar Personaje", vision = "Visión / Entorno", fullbright = "Fullbright (Sin Niebla)", combat = "Automatización de Combate", autoClick = "Auto Clicker", clickDesc = "Hace clic y activa herramientas automáticamente.", players = "Acciones de Jugadores", tpClosest = "Ir al Jugador Más Cercano", esp = "ESP de Jugadores (Resaltar)", farm = "Sistema de Farmeo", scanScraps = "Escanear Scraps", scanDesc = "Resalta los scraps en el mapa.", tpScrap = "Ir al Scrap Más Cercano", autoFarm = "Auto Farmear Scraps", autoPrompt = "Auto Interactuar Objetos", revenant = "Acciones del Revenant", tpRev = "Ir al Revenant", teleport = "Ubicaciones", goTo = "Ir a ", utilities = "Bypasses", antiRagdoll = "Anti Ragdoll", settings = "Ajustes", language = "Idioma", settingsUI = "Ajustes de Interfaz" },
    ES = { welcome = "Bienvenido, ", executor = "Executor: ", status = "Sistema en Línea", stats = "Estadísticas", abilities = "Habilidades", infStamina = "Estamina Infinita", speed = "Velocidad (WalkSpeed)", jump = "Fuerza de Salto", reset = "Reiniciar Personaje", vision = "Visión / Entorno", fullbright = "Fullbright (Sin Niebla)", combat = "Automatización de Combate", autoClick = "Auto Clicker", clickDesc = "Hace clic y activa herramientas automáticamente.", players = "Acciones de Jugadores", tpClosest = "Ir al Jugador Más Cercano", esp = "ESP de Jugadores (Resaltar)", farm = "Sistema de Farmeo", scanScraps = "Escanear Scraps", scanDesc = "Resalta los scraps en el mapa.", tpScrap = "Ir al Scrap Más Cercano", autoFarm = "Auto Farmear Scraps", autoPrompt = "Auto Interactuar Objetos", revenant = "Acciones del Revenant", tpRev = "Ir al Revenant", teleport = "Ubicaciones", goTo = "Ir a ", utilities = "Bypasses", antiRagdoll = "Anti Ragdoll", settings = "Ajustes", language = "Idioma", settingsUI = "Ajustes de Interfaz" }
}

local CurrentLang = "MX"
local L = Translations[CurrentLang]

local Window = Fluent:CreateWindow({
    Title = "TRS Panel",
    SubTitle = "v12.0 Elite",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 500),
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
local UI = {}

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

local function notify(title, content)
    Fluent:Notify({ Title = title, Content = content, Duration = 3 })
end

UI.MainPara = Tabs.Main:AddParagraph({ Title = L.welcome .. LocalPlayer.Name, Content = L.status })
UI.abilities = Tabs.Main:AddSection(L.abilities)

UI.stamina = Tabs.Main:AddToggle("StaminaInf", {
    Title = L.infStamina,
    Default = false,
    Callback = function(s) notify("Ability", L.infStamina .. ": " .. (s and "ON" or "OFF")) end
})

UI.speed = Tabs.Main:AddSlider("WalkSpeed", {
    Title = L.speed,
    Default = 16, Min = 16, Max = 150, Rounding = 0,
    Callback = function(v)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end
})

UI.jump = Tabs.Main:AddSlider("JumpPower", {
    Title = L.jump,
    Default = 50, Min = 50, Max = 200, Rounding = 0,
    Callback = function(v)
        local hum = getHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = v
        end
    end
})

UI.reset = Tabs.Main:AddButton({
    Title = L.reset,
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end
})

UI.vision = Tabs.Main:AddSection(L.vision)
UI.fullbright = Tabs.Main:AddToggle("Fullbright", {
    Title = L.fullbright,
    Default = false,
    Callback = function(s)
        if s then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.FogEnd = 100000
        else
            Lighting.Ambient = Color3.fromRGB(70, 70, 70)
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            Lighting.FogEnd = 1000
        end
    end
})

UI.combat = Tabs.Combat:AddSection(L.combat)
local _autoClick = false
local _clickDelay = 0.1

UI.autoClick = Tabs.Combat:AddToggle("AutoClicker", {
    Title = L.autoClick,
    Description = L.clickDesc,
    Default = false,
    Callback = function(s) _autoClick = s end
})

UI.clickDelay = Tabs.Combat:AddSlider("ClickDelay", {
    Title = "Delay (ms)",
    Default = 100, Min = 10, Max = 1000, Rounding = 0,
    Callback = function(v) _clickDelay = v / 1000 end
})

UI.players = Tabs.Players:AddSection(L.players)
UI.espToggle = Tabs.Players:AddToggle("PlayerESP", {
    Title = L.esp,
    Default = false,
    Callback = function(s) notify("ESP", L.esp .. ": " .. (s and "ON" or "OFF")) end
})

UI.tpClosest = Tabs.Players:AddButton({
    Title = L.tpClosest,
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

local ScrapHighlights = {}
local PlayerESP = {}
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
    notify("Farm", "Found " .. count .. " scraps.")
end

UI.farm = Tabs.Farm:AddSection(L.farm)
UI.scan = Tabs.Farm:AddButton({ Title = L.scanScraps, Description = L.scanDesc, Callback = scanScraps })
UI.tpScrap = Tabs.Farm:AddButton({
    Title = L.tpScrap,
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

UI.autoFarm = Tabs.Farm:AddToggle("AutoFarm", {
    Title = L.autoFarm,
    Default = false,
    Callback = function(s) _autoFarmScraps = s end
})

UI.autoPrompt = Tabs.Farm:AddToggle("AutoPrompt", {
    Title = L.autoPrompt,
    Default = false,
    Callback = function(s) _autoPrompt = s end
})

UI.rev = Tabs.Revenant:AddSection(L.revenant)
UI.tpRev = Tabs.Revenant:AddButton({
    Title = L.tpRev,
    Callback = function()
        local npcs = Workspace:FindFirstChild("NPCs")
        local rev = npcs and npcs:FindFirstChild("Revenant")
        local hrp = rev and rev:FindFirstChild("HumanoidRootPart")
        if hrp then doTeleport(hrp.Position) end
    end
})

UI.tpSec = Tabs.Teleport:AddSection(L.teleport)
local locs = {
    ["Shop"] = Vector3.new(-287, -13, -454),
    ["Power Station"] = Vector3.new(-244, 21, 212),
    ["Scrap Building"] = Vector3.new(-458, -3, 23),
    ["Bunker Elevator"] = Vector3.new(-97, -61, 167),
    ["Bunker Inside"] = Vector3.new(-137, -112, 359),
    ["Church"] = Vector3.new(359, 16, 403),
    ["Cave"] = Vector3.new(110, 14, -209)
}

UI.locs = {}
for name, pos in pairs(locs) do
    UI.locs[name] = Tabs.Teleport:AddButton({
        Title = L.goTo .. name,
        Callback = function() doTeleport(pos) end
    })
end

UI.util = Tabs.Utilities:AddSection(L.utilities)
UI.antiRag = Tabs.Utilities:AddToggle("AntiRagdoll", {
    Title = L.antiRagdoll,
    Default = true,
    Callback = function(s) notify("Bypass", L.antiRagdoll .. ": " .. (s and "ON" or "OFF")) end
})

UI.settings = Tabs.Settings:AddSection(L.settings)
UI.lang = Tabs.Settings:AddDropdown("Language", {
    Title = L.language,
    Values = { "Español (Latinoamérica)", "English", "Español (España)" },
    Default = "Español (Latinoamérica)",
    Multi = false,
    Callback = function(v)
        if v == "English" then CurrentLang = "EN"
        elseif v == "Español (Latinoamérica)" then CurrentLang = "MX"
        elseif v == "Español (España)" then CurrentLang = "ES" end
        L = Translations[CurrentLang]
        UpdateLanguage()
    end
})

function UpdateLanguage()
    UI.MainPara.Title = L.welcome .. LocalPlayer.Name
    UI.MainPara:SetDesc(L.status)
    UI.abilities.Title = L.abilities
    UI.stamina:SetTitle(L.infStamina)
    UI.speed:SetTitle(L.speed)
    UI.jump:SetTitle(L.jump)
    UI.reset:SetTitle(L.reset)
    UI.vision.Title = L.vision
    UI.fullbright:SetTitle(L.fullbright)
    UI.combat.Title = L.combat
    UI.autoClick:SetTitle(L.autoClick)
    UI.autoClick:SetDesc(L.clickDesc)
    UI.players.Title = L.players
    UI.espToggle:SetTitle(L.esp)
    UI.tpClosest:SetTitle(L.tpClosest)
    UI.farm.Title = L.farm
    UI.scan:SetTitle(L.scanScraps)
    UI.scan:SetDesc(L.scanDesc)
    UI.tpScrap:SetTitle(L.tpScrap)
    UI.autoFarm:SetTitle(L.autoFarm)
    UI.autoPrompt:SetTitle(L.autoPrompt)
    UI.rev.Title = L.revenant
    UI.tpRev:SetTitle(L.tpRev)
    UI.tpSec.Title = L.teleport
    for name, btn in pairs(UI.locs) do btn:SetTitle(L.goTo .. name) end
    UI.util.Title = L.utilities
    UI.antiRag:SetTitle(L.antiRagdoll)
    UI.settings.Title = L.settings
    UI.lang:SetTitle(L.language)
end

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
    while task.wait(0.1) do
        if _autoPrompt then
            local myHRP = getHRP()
            if myHRP then
                for _, desc in ipairs(Workspace:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled then
                        local parent = desc.Parent
                        local pos
                        if parent:IsA("BasePart") then pos = parent.Position
                        elseif parent:IsA("Model") then
                            local p = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
                            if p then pos = p.Position end
                        end
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

task.spawn(function()
    while task.wait(0.5) do
        local espOn = Options.PlayerESP and Options.PlayerESP.Value
        if espOn then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if not PlayerESP[plr] or not PlayerESP[plr].Parent then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.FillTransparency = 0.5
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.Adornee = plr.Character
                        hl.Parent = plr.Character
                        PlayerESP[plr] = hl
                    end
                end
            end
        else
            for plr, hl in pairs(PlayerESP) do
                if hl and hl.Parent then hl:Destroy() end
                PlayerESP[plr] = nil
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

if SaveManager and InterfaceManager then
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("TRS_Panel")
    SaveManager:SetFolder("TRS_Panel/Configs")
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)
end

task.wait(0.1)
Window:SelectTab(1)
notify("TRS Panel", "Sistema Cargado.")

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if Options.WalkSpeed then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = Options.WalkSpeed.Value
            hum.UseJumpPower = true
            hum.JumpPower = Options.JumpPower.Value
        end
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    clearHighlights()
    _autoFarmScraps = false
end)

script.Destroying:Connect(function()
    disconnectAll()
    clearHighlights()
    for _, hl in pairs(PlayerESP) do if hl and hl.Parent then hl:Destroy() end end
end)
