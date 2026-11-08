if _G.TRSPanelLoaded then
    pcall(function() _G.TRSPanelLoaded:Destroy() end)
end
_G.TRSPanelLoaded = Instance.new("Folder")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

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
local function track(conn)
    if conn then Connections[conn] = true end
    return conn
end

local function disconnectAll()
    for conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = setmetatable({}, { __mode = "k" })
end

if not isfolder("TRS_Panel") then makefolder("TRS_Panel") end
local CurrentLang = "MX"
if isfile("TRS_Panel/Lang.txt") then
    local read = readfile("TRS_Panel/Lang.txt")
    if read ~= "" then CurrentLang = read end
end

local Translations = {
    EN = { welcome = "Welcome, ", loading = "Loading preferences...", online = "System Online", stats = "Live Statistics", hp = "Health: ", speed = "Speed: ", rev = "Revenant Distance: ", fps = "FPS: ", abilities = "Abilities & Movement", infStamina = "Infinite Stamina", walk = "WalkSpeed", jump = "Jump Power", reset = "Reset Character", vision = "Vision", fullbright = "Fullbright", combat = "Combat", autoClick = "Auto Clicker", players = "Player Actions", tpClosest = "Teleport to Closest", esp = "Player ESP", farm = "Farming System", scan = "Scan Scraps", autoFarm = "Auto Farm", prompts = "Auto Prompts", revAct = "Revenant", tpRev = "Go to Revenant", teleport = "Teleport", goTo = "Go to ", util = "Utilities", antiRag = "Anti Ragdoll", settings = "Settings", lang = "Language (Requires Reload)" },
    MX = { welcome = "Bienvenido, ", loading = "Cargando preferencias...", online = "Sistema en Línea", stats = "Estadísticas en Vivo", hp = "Salud: ", speed = "Velocidad: ", rev = "Distancia al Revenant: ", fps = "FPS: ", abilities = "Habilidades y Movimiento", infStamina = "Stamina Infinita", walk = "Velocidad (Walk)", jump = "Fuerza de Salto", reset = "Reiniciar Personaje", vision = "Visión", fullbright = "Fullbright", combat = "Combate", autoClick = "Auto Clicker", players = "Acciones de Jugadores", tpClosest = "Ir al Más Cercano", esp = "ESP de Jugadores", farm = "Sistema de Farmeo", scan = "Escanear Scraps", autoFarm = "Auto Farmear", prompts = "Auto Interactuar", revAct = "Revenant", tpRev = "Ir al Revenant", teleport = "Teletransporte", goTo = "Ir a ", util = "Utilidades", antiRag = "Anti Ragdoll", settings = "Ajustes", lang = "Idioma (Requiere Reinicio)" },
    ES = { welcome = "Bienvenido, ", loading = "Cargando preferencias...", online = "Sistema en Línea", stats = "Estadísticas en Directo", hp = "Salud: ", speed = "Velocidad: ", rev = "Distancia al Revenant: ", fps = "FPS: ", abilities = "Habilidades y Movimiento", infStamina = "Estamina Infinita", walk = "Velocidad (Walk)", jump = "Fuerza de Salto", reset = "Reiniciar Personaje", vision = "Visión", fullbright = "Fullbright", combat = "Combate", autoClick = "Auto Clicker", players = "Acciones de Jugadores", tpClosest = "Ir al Más Cercano", esp = "ESP de Jugadores", farm = "Sistema de Farmeo", scan = "Escanear Scraps", autoFarm = "Auto Farmear", prompts = "Auto Interactuar", revAct = "Revenant", tpRev = "Ir al Revenant", teleport = "Teletransporte", goTo = "Ir a ", util = "Utilidades", antiRag = "Anti Ragdoll", settings = "Ajustes", lang = "Idioma (Requiere Reinicio)" }
}

local L = Translations[CurrentLang]

local Window = Fluent:CreateWindow({
    Title = "TRS Panel",
    SubTitle = "v13.0 Elite Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 500),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
    KeySystem = true,
    KeySettings = {
        Title = "TRS Panel",
        Subtitle = L.loading,
        Note = "Auto-bypass in 1 second",
        FileName = "TRS_Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = { "TRS_AUTO" }
    }
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

UI.HeaderPara = Tabs.Main:AddParagraph({ Title = "TRS Panel", Content = L.welcome .. LocalPlayer.Name .. " | " .. L.online })
UI.LiveStats = Tabs.Main:AddParagraph({ Title = L.stats, Content = "Cargando..." })

UI.abilities = Tabs.Main:AddSection(L.abilities)
UI.stamina = Tabs.Main:AddToggle("StaminaInf", { Title = L.infStamina, Default = false })
UI.speed = Tabs.Main:AddSlider("WalkSpeed", { Title = L.walk, Default = 16, Min = 16, Max = 150, Rounding = 0, Callback = function(v)
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = v end
end })
UI.jump = Tabs.Main:AddSlider("JumpPower", { Title = L.jump, Default = 50, Min = 50, Max = 200, Rounding = 0, Callback = function(v)
    local hum = getHumanoid()
    if hum then hum.UseJumpPower = true; hum.JumpPower = v end
end })
UI.reset = Tabs.Main:AddButton({ Title = L.reset, Callback = function() local h = getHumanoid(); if h then h.Health = 0 end end })

UI.vision = Tabs.Main:AddSection(L.vision)
UI.fullbright = Tabs.Main:AddToggle("Fullbright", { Title = L.fullbright, Default = false, Callback = function(s)
    if s then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.FogEnd = 100000
    else
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.FogEnd = 1000
    end
end })

UI.combat = Tabs.Combat:AddSection(L.combat)
local _autoClick = false
local _clickDelay = 0.1
UI.autoClick = Tabs.Combat:AddToggle("AutoClicker", { Title = L.autoClick, Default = false, Callback = function(s) _autoClick = s end })
UI.clickDelay = Tabs.Combat:AddSlider("ClickDelay", { Title = "Delay (ms)", Default = 100, Min = 10, Max = 1000, Rounding = 0, Callback = function(v) _clickDelay = v / 1000 end })

UI.players = Tabs.Players:AddSection(L.players)
UI.espToggle = Tabs.Players:AddToggle("PlayerESP", { Title = L.esp, Default = false })
UI.tpClosest = Tabs.Players:AddButton({ Title = L.tpClosest, Callback = function()
    local myHRP = getHRP(); if not myHRP then return end
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
end })

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
UI.scan = Tabs.Farm:AddButton({ Title = L.scan, Callback = scanScraps })
UI.tpScrap = Tabs.Farm:AddButton({ Title = "Ir al Scrap Cercano", Callback = function()
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
    if closest then
        local primary = closest.PrimaryPart or closest:FindFirstChildWhichIsA("BasePart")
        doTeleport(primary.Position)
    end
end })
UI.autoFarm = Tabs.Farm:AddToggle("AutoFarm", { Title = L.autoFarm, Default = false, Callback = function(s) _autoFarmScraps = s end })
UI.autoPrompt = Tabs.Farm:AddToggle("AutoPrompt", { Title = L.prompts, Default = false, Callback = function(s) _autoPrompt = s end })

UI.rev = Tabs.Revenant:AddSection(L.revAct)
UI.tpRev = Tabs.Revenant:AddButton({ Title = L.tpRev, Callback = function()
    local npcs = Workspace:FindFirstChild("NPCs")
    local rev = npcs and npcs:FindFirstChild("Revenant")
    local hrp = rev and rev:FindFirstChild("HumanoidRootPart")
    if hrp then doTeleport(hrp.Position) end
end })

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
for name, pos in pairs(locs) do
    Tabs.Teleport:AddButton({ Title = L.goTo .. name, Callback = function() doTeleport(pos) end })
end

UI.util = Tabs.Utilities:AddSection(L.util)
UI.antiRag = Tabs.Utilities:AddToggle("AntiRagdoll", { Title = L.antiRag, Default = true })

UI.settings = Tabs.Settings:AddSection(L.settings)
UI.lang = Tabs.Settings:AddDropdown("Language", {
    Title = L.lang,
    Values = { "Español (Latinoamérica)", "English", "Español (España)" },
    Default = (CurrentLang == "EN" and "English") or (CurrentLang == "ES" and "Español (España)") or "Español (Latinoamérica)",
    Multi = false,
    Callback = function(v)
        local newLang = "MX"
        if v == "English" then newLang = "EN"
        elseif v == "Español (España)" then newLang = "ES" end
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
    while task.wait(0.15) do
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
        if Options.PlayerESP.Value then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if not PlayerESP[plr] or not PlayerESP[plr].Parent then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 50, 50)
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

task.spawn(function()
    local lastFrame = tick()
    local frames = 0
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - lastFrame >= 1 then
            local fps = frames
            frames = 0
            lastFrame = tick()
            
            local hum = getHumanoid()
            local hrp = getHRP()
            local npcs = Workspace:FindFirstChild("NPCs")
            local rev = npcs and npcs:FindFirstChild("Revenant")
            local revHRP = rev and rev:FindFirstChild("HumanoidRootPart")
            
            local hpText = "0"
            local speedText = "0"
            local revText = "N/A"
            
            if hum and hrp then
                hpText = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                local vel = hrp.AssemblyLinearVelocity
                speedText = math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude)
                if revHRP then
                    revText = math.floor((revHRP.Position - hrp.Position).Magnitude) .. " studs"
                end
            end
            
            UI.LiveStats:SetDesc(string.format("%s%s\n%s%s\n%s%s\n%s%d", L.hp, hpText, L.speed, speedText, L.rev, revText, L.fps, fps))
        end
    end)
end)

if SaveManager and InterfaceManager then
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("TRS_Panel")
    SaveManager:SetFolder("TRS_Panel/Configs")
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)
end

task.spawn(function()
    task.wait(0.5)
    if Options.KeySystem then Options.KeySystem.Value = "TRS_AUTO" end
    task.wait(1)
    Window:SelectTab(1)
    notify("TRS Panel", "Sistema Iniciado.")
end)

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

_G.TRSPanelLoaded.Destroying:Connect(function()
    disconnectAll()
    clearHighlights()
    for _, hl in pairs(PlayerESP) do if hl and hl.Parent then hl:Destroy() end end
end)
