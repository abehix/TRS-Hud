local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Connections = setmetatable({}, { __mode = "k" })
local function track(conn)
    if conn then Connections[conn] = true end
    return conn
end

local function disconnectAll()
    for conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = setmetatable({}, { __mode = "k" })
end

local function getExecutor()
    local execs = {
        { "Synapse X", syn }, { "Script-Ware", is_sirhurt_closure }, { "Krunker", KRNL_LOADED },
        { "Fluxus", fluxus }, { "Electron", electron }, { "Wave", wave }, { "Delta", delta },
        { "AWP", AWP }, { "Solara", Solara }, { "Xeno", xeno }, { "Codex", codex }
    }
    for _, exec in ipairs(execs) do
        if exec[2] then return exec[1] end
    end
    if identifyexecutor then
        local ok, name = pcall(identifyexecutor)
        if ok and name then return name end
    end
    return "Unknown / Mobile"
end

local Window = Fluent:CreateWindow({
    Title = "TRS Panel",
    SubTitle = "v10.0 Professional",
    TabWidth = 160,
    Size = UDim2.fromOffset(600, 480),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
    KeySystem = true,
    KeySettings = {
        Title = "Cargando TRS Panel...",
        Subtitle = "Iniciando preferencias y módulos",
        Note = "Bypass automático en 1.5 segundos...",
        FileName = "TRS_Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = { "AUTO_BYPASS" }
    }
})

local Tabs = {
    Main = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Players = Window:AddTab({ Title = "Players", Icon = "users" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "pickaxe" }),
    Revenant = Window:AddTab({ Title = "Revenant", Icon = "skull" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Utilities = Window:AddTab({ Title = "Utilities", Icon = "shield" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

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
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3
    })
end

-- DASHBOARD
Tabs.Main:AddSection("Información del Sistema")
Tabs.Main:AddParagraph({
    Title = "Bienvenido, " .. LocalPlayer.Name,
    Content = "Executor Detectado: " .. getExecutor() .. "\nEstado: Conectado y Protegido."
})

local StatsParagraph = Tabs.Main:AddParagraph({
    Title = "Estadísticas en Vivo",
    Content = "Cargando..."
})

Tabs.Main:AddSection("Habilidades del Jugador")
Tabs.Main:AddToggle("StaminaInf", {
    Title = "Stamina Infinita",
    Description = "Evita el cansancio al correr o atacar.",
    Default = false,
    Callback = function(state)
        notify("Habilidades", "Stamina Infinita: " .. (state and "ON" or "OFF"))
    end
})

task.spawn(function()
    local hooked = false
    while task.wait(2) do
        if Options.StaminaInf.Value and not hooked then
            local ok, err = pcall(function()
                for _, obj in pairs(getgc(true)) do
                    if type(obj) == "function" then
                        local info = debug.getinfo(obj)
                        if info.name == "TakeStamina" then
                            hookfunction(obj, function() return end)
                        elseif info.name == "CheckStamina" then
                            hookfunction(obj, function() return true end)
                        end
                    end
                end
            end)
            if ok then hooked = true end
        end
    end
end)

Tabs.Main:AddButton({
    Title = "Reiniciar Personaje",
    Description = "Fuerza tu respawn inmediato.",
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end
})

-- COMBAT
Tabs.Combat:AddSection("Automatización de Combate")
local _autoClick = false
local _clickDelay = 0.1

Tabs.Combat:AddToggle("AutoClicker", {
    Title = "Auto Clicker",
    Description = "Clic automático y activación de herramientas.",
    Default = false,
    Callback = function(state) _autoClick = state end
})

Tabs.Combat:AddSlider("ClickDelay", {
    Title = "Retardo (ms)",
    Default = 100,
    Min = 10,
    Max = 1000,
    Rounding = 0,
    Callback = function(value) _clickDelay = value / 1000 end
})

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
                if tool and tool.Parent == LocalPlayer.Character then
                    pcall(function() tool:Activate() end)
                end
            end
        end
    end
end)

-- PLAYERS
Tabs.Players:AddSection("Acciones de Jugadores")
Tabs.Players:AddButton({
    Title = "Ir al Jugador Más Cercano",
    Description = "Teletranspórtate al jugador más cercano a ti.",
    Callback = function()
        local myHRP = getHRP()
        if not myHRP then return end
        local closest, dist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local target = plr.Character:FindFirstChild("HumanoidRootPart")
                if target then
                    local d = (target.Position - myHRP.Position).Magnitude
                    if d < dist then
                        dist = d
                        closest = target
                    end
                end
            end
        end
        if closest then doTeleport(closest.Position) end
    end
})

-- FARM (Arreglado)
Tabs.Farm:AddSection("Sistema de Farmeo")
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
    if not folder then
        notify("Farm", "No se encontró la carpeta de Scraps.", 4)
        return
    end
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
    notify("Farm", "Se encontraron " .. count .. " scraps.", 3)
end

Tabs.Farm:AddButton({
    Title = "Escanear Scraps",
    Description = "Resalta los scraps en el mapa.",
    Callback = function() scanScraps() end
})

Tabs.Farm:AddButton({
    Title = "Ir al Scrap Más Cercano",
    Description = "Teletranspórtate al scrap más cercano escaneado.",
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
            notify("Farm", "Teletransportado.", 2)
        else
            notify("Farm", "No hay scraps escaneados.", 3)
        end
    end
})

Tabs.Farm:AddToggle("AutoFarm", {
    Title = "Auto Farm",
    Description = "Teletransporte automático al scrap más cercano.",
    Default = false,
    Callback = function(state) _autoFarmScraps = state end
})

task.spawn(function()
    while task.wait(1.5) do
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

-- REVENANT
Tabs.Revenant:AddSection("Acciones del Revenant")
Tabs.Revenant:AddButton({
    Title = "Ir al Revenant",
    Description = "Teletranspórtate hacia el NPC Revenant.",
    Callback = function()
        local npcs = Workspace:FindFirstChild("NPCs")
        local rev = npcs and npcs:FindFirstChild("Revenant")
        local hrp = rev and rev:FindFirstChild("HumanoidRootPart")
        if hrp then
            doTeleport(hrp.Position)
            notify("Revenant", "Viajando al NPC...", 2)
        else
            notify("Revenant", "No se encontró al Revenant.", 3)
        end
    end
})

-- TELEPORT
Tabs.Teleport:AddSection("Puntos de Interés")
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
        Title = "Ir a " .. name,
        Callback = function()
            if doTeleport(pos) then
                notify("Teleport", "Viajando a " .. name, 2)
            end
        end
    })
end

-- UTILITIES (El tab que faltaba)
Tabs.Utilities:AddSection("Bypasses del Servidor")
Tabs.Utilities:AddToggle("AntiRagdoll", {
    Title = "Anti Ragdoll",
    Description = "Evita que tu personaje se caiga o quede tirado.",
    Default = true,
    Callback = function(state)
        notify("Utility", "Anti Ragdoll: " .. (state and "ON" or "OFF"))
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if Options.AntiRagdoll.Value and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                end)
            end
        end
    end
end)

-- SETTINGS & SAVES
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("TRS_Panel")
SaveManager:SetFolder("TRS_Panel/Configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- AUTO-BYPASS PARA EL FAKE KEY SYSTEM
task.spawn(function()
    task.wait(1)
    if Options and Options.KeySystem then
        Options.KeySystem.Value = "AUTO_BYPASS"
    end
end)

task.spawn(function()
    while task.wait(1) do
        local hum = getHumanoid()
        local hrp = getHRP()
        if hum and hrp then
            local vel = hrp.AssemblyLinearVelocity
            local speed = math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude)
            local hp = math.floor(hum.Health)
            local maxhp = math.floor(hum.MaxHealth)
            StatsParagraph:SetDesc(string.format("Velocidad: %d | Salud: %d/%d", speed, hp, maxhp))
        else
            StatsParagraph:SetDesc("Esperando personaje...")
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
end)
