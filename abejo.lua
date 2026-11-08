pcall(function()
    if _G.__TRS_WINDOW then
        _G.__TRS_WINDOW:Destroy()
        _G.__TRS_WINDOW = nil
    end
end)
pcall(function()
    local cg = game:GetService("CoreGui")
    local old = cg:FindFirstChild("Fluent")
    if old then old:Destroy() end
end)
pcall(function()
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    local old = pg and pg:FindFirstChild("Fluent")
    if old then old:Destroy() end
end)
pcall(function()
    if getgenv and getgenv().TRS_OLD_TAKE_STAMINA and getgenv().TRS_TAKE_STAMINA_FUNC then
        hookfunction(getgenv().TRS_TAKE_STAMINA_FUNC, getgenv().TRS_OLD_TAKE_STAMINA)
        getgenv().TRS_OLD_TAKE_STAMINA = nil
        getgenv().TRS_TAKE_STAMINA_FUNC = nil
    end
end)
pcall(function()
    if getgenv and getgenv().TRS_OLD_CHECK_STAMINA and getgenv().TRS_CHECK_STAMINA_FUNC then
        hookfunction(getgenv().TRS_CHECK_STAMINA_FUNC, getgenv().TRS_OLD_CHECK_STAMINA)
        getgenv().TRS_OLD_CHECK_STAMINA = nil
        getgenv().TRS_CHECK_STAMINA_FUNC = nil
    end
end)
pcall(function()
    if getgenv and getgenv().TRS_HOOKS then
        for _, h in pairs(getgenv().TRS_HOOKS) do
            pcall(function() h:Disconnect() end)
        end
        getgenv().TRS_HOOKS = nil
    end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local okFluent, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not okFluent or not Fluent then
    return
end

local okSM, SaveManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)

local okIM, InterfaceManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not okSM then SaveManager = nil end
if not okIM then InterfaceManager = nil end

local Options = Fluent.Options

local Connections = setmetatable({}, { __mode = "k" })
local function track(conn)
    if conn then Connections[conn] = true end
    return conn
end

local function disconnectAll()
    for conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(Connections)
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
    LoadingSubtitle = "Cargando preferencias y módulos..."
})

_G.__TRS_WINDOW = Window

local Tabs = {
    Main = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Players = Window:AddTab({ Title = "Players", Icon = "users" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "pickaxe" }),
    Revenant = Window:AddTab({ Title = "Revenant", Icon = "skull" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Utilities = Window:AddTab({ Title = "Utilities", Icon = "wrench" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Notify = {}

function Notify.Success(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3,
        Icon = "check-circle"
    })
end

function Notify.Info(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3,
        Icon = "info"
    })
end

function Notify.Warning(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 4,
        Icon = "alert-triangle"
    })
end

function Notify.Error(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 5,
        Icon = "x-circle"
    })
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

Tabs.Main:AddParagraph({
    Title = "Estado del Sistema",
    Content = "Todos los módulos cargados correctamente."
})

local StatsParagraph = Tabs.Main:AddParagraph({
    Title = "Información",
    Content = "Esperando datos..."
})

Tabs.Main:AddSection("Habilidades")

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
                    local ok, result = pcall(hookfunction, object, function(...)
                        if Options.StaminaInf and Options.StaminaInf.Value then
                            local hum = getHumanoid()
                            if hum and hum.Health > 0 then return end
                        end
                        return oldTakeStamina(...)
                    end)
                    if ok then
                        oldTakeStamina = result
                        getgenv().TRS_OLD_TAKE_STAMINA = result
                        getgenv().TRS_TAKE_STAMINA_FUNC = object
                        foundAny = true
                    end
                elseif info.name == "CheckStamina" and not oldCheckStamina then
                    local ok, result = pcall(hookfunction, object, function(...)
                        if Options.StaminaInf and Options.StaminaInf.Value then
                            local hum = getHumanoid()
                            if hum and hum.Health > 0 then return true end
                        end
                        return oldCheckStamina(...)
                    end)
                    if ok then
                        oldCheckStamina = result
                        getgenv().TRS_OLD_CHECK_STAMINA = result
                        getgenv().TRS_CHECK_STAMINA_FUNC = object
                        foundAny = true
                    end
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
        if state and not hooksInitialized then InitStaminaHooks() end
        if state then
            Notify.Success("Habilidades", "Stamina Infinita: ON")
        else
            Notify.Info("Habilidades", "Stamina Infinita: OFF")
        end
    end
})

Tabs.Main:AddButton({
    Title = "Reiniciar Personaje",
    Description = "Respawn rápido",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            Notify.Info("Personaje", "Reiniciando personaje...")
            hum.Health = 0
        else
            Notify.Error("Personaje", "No se encontró el Humanoid.")
        end
    end
})

Tabs.Combat:AddSection("Automatización")

local _autoClick = false
local _clickDelay = 0.1

Tabs.Combat:AddToggle("AutoClicker", {
    Title = "Auto Clicker",
    Default = false,
    Callback = function(state)
        _autoClick = state
        if state then
            Notify.Success("Combat", "Auto Clicker: ON")
        else
            Notify.Info("Combat", "Auto Clicker: OFF")
        end
    end
})

Tabs.Combat:AddSlider("ClickDelay", {
    Title = "Delay (ms)",
    Default = 100,
    Min = 10,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        _clickDelay = value / 1000
    end
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
                if tool and tool.Parent == char then
                    pcall(function() tool:Activate() end)
                end
            end
            task.wait(_clickDelay)
        end
    end
end)

Tabs.Utilities:AddSection("Bypasses")

local _antiRagdoll = true

Tabs.Utilities:AddToggle("AntiRagdoll", {
    Title = "Anti Ragdoll",
    Default = true,
    Callback = function(state)
        _antiRagdoll = state
        if state then
            Notify.Success("Utility", "Anti Ragdoll: ON")
        else
            Notify.Info("Utility", "Anti Ragdoll: OFF")
        end
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if _antiRagdoll and LocalPlayer.Character then
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

local ScrapHighlights = {}
local _autoFarmScraps = false

local function clearHighlights()
    for _, hl in pairs(ScrapHighlights) do
        if hl then hl:Destroy() end
    end
    table.clear(ScrapHighlights)
end

local function scanScraps()
    clearHighlights()
    local map = Workspace:FindFirstChild("MAP") or Workspace:FindFirstChild("Map")
    local folder = map and map:FindFirstChild("Scraps")
    if not folder then
        Notify.Error("Farm", "Carpeta de Scraps no encontrada.")
        return 0
    end
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
    if count > 0 then
        Notify.Success("Farm", "Se detectaron " .. count .. " scraps.")
    else
        Notify.Warning("Farm", "No se encontraron scraps en el mapa.")
    end
    return count
end

Tabs.Farm:AddButton({
    Title = "Escanear Scraps",
    Description = "Resalta todos los scraps del mapa",
    Callback = function() scanScraps() end
})

Tabs.Farm:AddButton({
    Title = "Ir al Scrap Más Cercano",
    Callback = function()
        local myHRP = getHRP()
        if not myHRP then
            Notify.Error("Farm", "Personaje no disponible.")
            return
        end
        local closest, dist = nil, math.huge
        for scrap, _ in pairs(ScrapHighlights) do
            if scrap.Parent then
                local primary = scrap.PrimaryPart or scrap:FindFirstChildWhichIsA("BasePart")
                if primary then
                    local d = (primary.Position - myHRP.Position).Magnitude
                    if d < dist then
                        dist = d
                        closest = scrap
                    end
                end
            end
        end
        if closest then
            local primary = closest.PrimaryPart or closest:FindFirstChildWhichIsA("BasePart")
            doTeleport(primary.Position)
            Notify.Success("Farm", "Teletransportado a Scrap.")
        else
            Notify.Warning("Farm", "No hay scraps escaneados.")
        end
    end
})

Tabs.Farm:AddToggle("AutoFarm", {
    Title = "Auto Farm (Teletransporte)",
    Default = false,
    Callback = function(state)
        _autoFarmScraps = state
        if state then
            Notify.Success("Farm", "Auto Farm: ON")
        else
            Notify.Info("Farm", "Auto Farm: OFF")
        end
    end
})

task.spawn(function()
    while task.wait(1) do
        if _autoFarmScraps then
            if next(ScrapHighlights) == nil then
                scanScraps()
            end
            local myHRP = getHRP()
            if myHRP then
                local closest, dist = nil, math.huge
                for scrap, _ in pairs(ScrapHighlights) do
                    if scrap.Parent then
                        local primary = scrap.PrimaryPart or scrap:FindFirstChildWhichIsA("BasePart")
                        if primary then
                            local d = (primary.Position - myHRP.Position).Magnitude
                            if d < dist then
                                dist = d
                                closest = scrap
                            end
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

Tabs.Revenant:AddSection("NPC")

local _revenantTracking = false
local _revenantPresent = false
local _revenantConnection = nil
local _revenantRemovedConnection = nil

local function getRevenant()
    local npcs = Workspace:FindFirstChild("NPCs")
    return npcs and npcs:FindFirstChild("Revenant")
end

local function startRevenantTracking()
    if _revenantConnection then return end
    _revenantPresent = getRevenant() ~= nil
    if _revenantPresent then
        Notify.Success("Revenant", "Revenant detectado en el mapa.")
    else
        Notify.Info("Revenant", "Esperando aparición del Revenant...")
    end
    _revenantConnection = Workspace.DescendantAdded:Connect(function(desc)
        if desc.Name == "Revenant" and desc:IsA("Model") then
            if not _revenantPresent then
                _revenantPresent = true
                Notify.Success("Revenant", "Revenant ha aparecido.")
            end
        end
    end)
    track(_revenantConnection)
    _revenantRemovedConnection = Workspace.DescendantRemoving:Connect(function(desc)
        if desc.Name == "Revenant" and desc:IsA("Model") then
            if _revenantPresent then
                _revenantPresent = false
                Notify.Warning("Revenant", "Revenant ha desaparecido.")
            end
        end
    end)
    track(_revenantRemovedConnection)
end

local function stopRevenantTracking()
    if _revenantConnection then
        _revenantConnection:Disconnect()
        _revenantConnection = nil
    end
    if _revenantRemovedConnection then
        _revenantRemovedConnection:Disconnect()
        _revenantRemovedConnection = nil
    end
    _revenantPresent = false
    Notify.Info("Revenant", "Tracking desactivado.")
end

Tabs.Revenant:AddToggle("RevenantTrack", {
    Title = "Trackear Revenant",
    Default = false,
    Callback = function(state)
        _revenantTracking = state
        if state then
            startRevenantTracking()
        else
            stopRevenantTracking()
        end
    end
})

Tabs.Revenant:AddButton({
    Title = "Ir al Revenant",
    Callback = function()
        local rev = getRevenant()
        local hrp = rev and rev:FindFirstChild("HumanoidRootPart")
        if hrp then
            doTeleport(hrp.Position)
            Notify.Success("Revenant", "Teletransportado al Revenant.")
        else
            Notify.Error("Revenant", "No se encontró el Revenant.")
        end
    end
})

Tabs.Players:AddSection("Acciones Rápidas")

Tabs.Players:AddButton({
    Title = "Ir al Jugador Más Cercano",
    Callback = function()
        local myHRP = getHRP()
        if not myHRP then
            Notify.Error("Players", "Personaje no disponible.")
            return
        end
        local closest, dist, closestName = nil, math.huge, nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local target = plr.Character:FindFirstChild("HumanoidRootPart")
                if target then
                    local d = (target.Position - myHRP.Position).Magnitude
                    if d < dist then
                        dist = d
                        closest = target
                        closestName = plr.Name
                    end
                end
            end
        end
        if closest and dist <= 500 then
            doTeleport(closest.Position)
            Notify.Success("Players", "Teletransportado a " .. closestName)
        elseif closest then
            Notify.Warning("Players", "Jugador más cercano fuera de rango (500 studs).")
        else
            Notify.Warning("Players", "No hay jugadores cercanos.")
        end
    end
})

Tabs.Teleport:AddSection("Ubicaciones")

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
            if doTeleport(pos) then
                Notify.Success("Teleport", "Viajando a " .. name)
            else
                Notify.Error("Teleport", "No se pudo teletransportar.")
            end
        end
    })
end

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
    Notify.Success("TRS Panel", "Sistema inicializado correctamente.", 4)
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
            StatsParagraph:SetDesc(string.format("Velocidad: %d | Salud: %d/%d", speed, hp, maxhp))
        else
            StatsParagraph:SetDesc("Esperando personaje...")
        end
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
