--[[
    Abejo HUD v8 - Fluent UI Edition
    Loader: loadstring(game:HttpGet("https://raw.githubusercontent.com/TU_USER/TU_REPO/main/abejo.lua"))()
]]

-- Servicios
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Lighting = game:GetService("Lighting")

-- Cargar Fluent (UI Library)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Crear Ventana (estilo como la captura)
local Window = Fluent:CreateWindow({
    Title = "Abejo HUD",
    SubTitle = "Advanced Panel · v8",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Tabs (Pestañas laterales)
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Players = Window:AddTab({ Title = "Players", Icon = "users" }),
    Revenant = Window:AddTab({ Title = "Revenant", Icon = "skull" }),
    Utilities = Window:AddTab({ Title = "Utilities", Icon = "settings" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "pickaxe" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- ==========================================
-- FUNCIONES AUXILIARES (Igual que tu script)
-- ==========================================
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function doTeleport(cframe)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = cframe
        return true
    end
    return false
end

-- Notificación de Fluent (reemplaza tu función notify custom)
local function notify(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 4
    })
end

-- ==========================================
-- TAB: MAIN (Dashboard)
-- ==========================================
Tabs.Main:AddParagraph({
    Title = "Resumen de Sesión",
    Content = "Estado actual de tu personaje y estadísticas."
})

-- Aquí irían los toggles/botones principales de tu Dashboard
-- Ejemplo: Speed / DDT (requiere loop para actualizar labels, Fluent no tiene stat cards nativos, usamos Paragraph o Toggles)

Tabs.Main:AddToggle("ToggleSpeed", {
    Title = "Mostrar Velocidad",
    Default = false,
    Callback = function(state)
        -- Lógica para mostrar velocidad si es necesario
    end
})

-- ==========================================
-- TAB: YOU (Habilidades / Player)
-- ==========================================
Tabs.Main:AddSection("Habilidades")

-- Stamina Infinita (Lógica original)
_G.Abejo_StaminaEnabled = false
local hooksInitialized = false
local oldTakeStamina, oldCheckStamina
local lastHookAttempt = 0

local function InitStaminaHooks()
    if hooksInitialized then return end
    if tick() - lastHookAttempt < 5 then return end
    lastHookAttempt = tick()
    local foundAny = false
    for _, object in pairs(getgc(true)) do
        if typeof(object) == "function" then
            local okInfo, info = pcall(debug.getinfo, object)
            if okInfo and info then
                if info.name == "TakeStamina" and not oldTakeStamina then
                    oldTakeStamina = hookfunction(object, function(...)
                        if _G.Abejo_StaminaEnabled then
                            local char = LocalPlayer.Character
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then return end
                        end
                        return oldTakeStamina(...)
                    end)
                    foundAny = true
                elseif info.name == "CheckStamina" and not oldCheckStamina then
                    oldCheckStamina = hookfunction(object, function(...)
                        if _G.Abejo_StaminaEnabled then
                            local char = LocalPlayer.Character
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then return true end
                        end
                        return oldCheckStamina(...)
                    end)
                    foundAny = true
                end
            end
        end
    end
    if foundAny then hooksInitialized = true end
end

Tabs.Main:AddToggle("StaminaInf", {
    Title = "Stamina Infinita",
    Default = false,
    Callback = function(state)
        _G.Abejo_StaminaEnabled = state
        if state and not hooksInitialized then InitStaminaHooks() end
        notify("Stamina Infinita", state and "ON" or "OFF")
    end
})

-- Auto Clicker
_G.Abejo_AutoClicker = false
_G.Abejo_AutoClickerDelay = 0.1

Tabs.Main:AddToggle("AutoClicker", {
    Title = "Auto Clicker",
    Default = false,
    Callback = function(state)
        _G.Abejo_AutoClicker = state
        notify("Auto Clicker", state and "ON" or "OFF")
    end
})

Tabs.Main:AddSlider("AutoClickerDelay", {
    Title = "Retardo Auto Clicker (ms)",
    Default = 100,
    Min = 10,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        _G.Abejo_AutoClickerDelay = value / 1000
    end
})

-- Loop Auto Clicker
task.spawn(function()
    while true do
        local delay = _G.Abejo_AutoClickerDelay or 0.1
        task.wait(delay)
        if _G.Abejo_AutoClicker then
            local cam = workspace.CurrentCamera
            if cam then
                local center = cam.ViewportSize / 2
                pcall(function()
                    VirtualUser:Button1Down(Vector2.new(center.X, center.Y), cam.CFrame)
                    task.wait(0.02)
                    VirtualUser:Button1Up(Vector2.new(center.X, center.Y), cam.CFrame)
                end)
            end
        end
    end
end)

Tabs.Main:AddButton({
    Title = "Reiniciar Personaje",
    Description = "Mata a tu personaje para respawnear",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            hum.Health = 0
            notify("Personaje", "Reiniciado")
        end
    end
})

-- ==========================================
-- TAB: UTILITIES
-- ==========================================
Tabs.Utilities:AddSection("Bypasses")

-- Anti Ragdoll
_G.Abejo_AntiRagdoll = true
Tabs.Utilities:AddToggle("AntiRagdoll", {
    Title = "Anti Ragdoll",
    Default = true,
    Callback = function(state)
        _G.Abejo_AntiRagdoll = state
        notify("Anti Ragdoll", state and "ON" or "OFF")
    end
})

-- Anti Barrera (Alambre)
_G.Abejo_AntiBarrier = false
Tabs.Utilities:AddToggle("AntiBarrier", {
    Title = "Anti Barrera (Alambre)",
    Default = false,
    Callback = function(state)
        _G.Abejo_AntiBarrier = state
        notify("Anti Barrera", state and "ON" or "OFF")
    end
})

-- ==========================================
-- TAB: TELEPORT
-- ==========================================
Tabs.Teleport:AddSection("Viaje Rápido")

local locations = {
    ["Shop"] = CFrame.new(-287.998016, -13.7416973, -454.909027),
    ["Power Station"] = CFrame.new(-244.704498, 21.5832672, 212.771057),
    ["Scrap Building"] = CFrame.new(-458.86499, -3.20000076, 23.5130329),
    ["Bunker Elevator"] = CFrame.new(-97.3507233, -61.6877441, 167.447845),
    ["Bunker Inside"] = CFrame.new(-137.785004, -112.900253, 359.073578),
    ["Church"] = CFrame.new(359.619049, 16.1122551, 403.016052),
    ["Cave"] = CFrame.new(110.269135, 14.3999996, -209.216293),
}

for name, cframe in pairs(locations) do
    Tabs.Teleport:AddButton({
        Title = name,
        Callback = function()
            if doTeleport(cframe) then
                notify("Teleport", "Teletransportado a " .. name)
            else
                notify("Teleport", "Error: Sin personaje")
            end
        end
    })
end

-- ==========================================
-- TAB: REVENANT
-- ==========================================
Tabs.Revenant:AddSection("Acciones")

Tabs.Revenant:AddButton({
    Title = "Teletransportar al Revenant",
    Callback = function()
        local npcsFolder = Workspace:FindFirstChild("NPCs")
        local rev = npcsFolder and npcsFolder:FindFirstChild("Revenant")
        if rev then
            local target = rev:FindFirstChild("HumanoidRootPart")
            if target and doTeleport(target.CFrame + Vector3.new(0, 5, 0)) then
                notify("Revenant", "Teletransportado")
            else
                notify("Revenant", "Sin HumanoidRootPart")
            end
        else
            notify("Revenant", "No encontrado")
        end
    end
})

-- ==========================================
-- TAB: PLAYERS (Simplificado para Fluent)
-- ==========================================
-- Fluent no tiene listas dinámicas fáciles, así que usamos un botón que teletransporta al más cercano o un dropdown.
-- Para mantenerlo simple, creamos un botón de "Ir al jugador más cercano".

Tabs.Players:AddSection("Jugadores")

Tabs.Players:AddButton({
    Title = "Teletransportarse al Jugador Más Cercano",
    Callback = function()
        local myHRP = getHRP()
        if not myHRP then return end
        
        local closestPlr, closestDist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local target = plr.Character:FindFirstChild("HumanoidRootPart")
                if target then
                    local dist = (target.Position - myHRP.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlr = plr
                    end
                end
            end
        end
        
        if closestPlr and closestPlr.Character then
            local target = closestPlr.Character:FindFirstChild("HumanoidRootPart")
            if target then
                doTeleport(target.CFrame + Vector3.new(0, 3, 0))
                notify("Players", "Teletransportado a " .. closestPlr.Name)
            end
        else
            notify("Players", "No hay jugadores cercanos")
        end
    end
})

-- ==========================================
-- TAB: FARM (Lógica simplificada)
-- ==========================================
Tabs.Farm:AddSection("Scraps")

Tabs.Farm:AddButton({
    Title = "Escanear Scraps Cercanos",
    Callback = function()
        local map = Workspace:FindFirstChild("MAP") or Workspace:FindFirstChild("Map")
        local scrapsFolder = map and map:FindFirstChild("Scraps")
        if not scrapsFolder then
            notify("Farm", "Carpeta Scraps no encontrada")
            return
        end
        
        local count = 0
        for _, folder in ipairs(scrapsFolder:GetChildren()) do
            if folder:IsA("Folder") then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("Model") and child.Name:match("^Scrap") then
                        count = count + 1
                        -- Crear Highlight simple
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 255, 0)
                        hl.Adornee = child
                        hl.Parent = child
                    end
                end
            end
        end
        notify("Farm", "Encontrados " .. count .. " scraps")
    end
})

-- ==========================================
-- SETTINGS & SAVE MANAGER
-- ==========================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("AbejoHUD")
SaveManager:SetFolder("AbejoHUD/Configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Notificación de carga
Window:SelectTab(1)
notify("Abejo HUD", "Cargado correctamente. Presiona LeftControl para minimizar.")

-- Iniciar watchers de Anti Ragdoll (Lógica original)
task.spawn(function()
    while task.wait(0.5) do
        if _G.Abejo_AntiRagdoll and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                end)
            end
        end
    end
end)
