local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

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

local Tabs = {
    Main = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Players = Window:AddTab({ Title = "Players", Icon = "users" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "pickaxe" }),
    Revenant = Window:AddTab({ Title = "Revenant", Icon = "skull" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

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
                    oldTakeStamina = hookfunction(object, function(...)
                        if Options.StaminaInf.Value then
                            local hum = getHumanoid()
                            if hum and hum.Health > 0 then return end
                        end
                        return oldTakeStamina(...)
                    end)
                    foundAny = true
                elseif info.name == "CheckStamina" and not oldCheckStamina then
                    oldCheckStamina = hookfunction(object, function(...)
                        if Options.StaminaInf.Value then
                            local hum = getHumanoid()
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
        if state and not hooksInitialized then InitStaminaHooks() end
        notify("Habilidades", "Stamina: " .. (state and "ON" or "OFF"))
    end
})

Tabs.Main:AddButton({
    Title = "Reiniciar Personaje",
    Description = "Respawn rápido",
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end
})

Tabs.Combat:AddSection("Automatización")
local _autoClick = false
local _clickDelay = 0.1

Tabs.Combat:AddToggle("AutoClicker", {
    Title = "Auto Clicker",
    Default = false,
    Callback = function(state) _autoClick = state end
})

Tabs.Combat:AddSlider("ClickDelay", {
    Title = "Delay (ms)",
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
                
                local char = LocalPlayer.Character
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool and tool.Parent == char then 
                    pcall(function() tool:Activate() end) 
                end
            end
        end
    end
end)

Tabs.Utilities:AddSection("Bypasses")
Tabs.Utilities:AddToggle("AntiRagdoll", {
    Title = "Anti Ragdoll",
    Default = true,
    Callback = function(state)
        notify("Utility", "Anti Ragdoll: " .. (state and "ON" or "OFF"))
    end
})

local _antiRagdoll = true
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
        notify("Farm", "Carpeta de Scraps no encontrada.", 4)
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
    notify("Farm", "Se detectaron " .. count .. " scraps.", 3)
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
        if not myHRP then return end
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
            notify("Farm", "Teletransportado a Scrap.", 2)
        else
            notify("Farm", "No hay scraps escaneados.", 3)
        end
    end
})

Tabs.Farm:AddToggle("AutoFarm", {
    Title = "Auto Farm (Teletransporte)",
    Default = false,
    Callback = function(state) _autoFarmScraps = state end
})

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
Tabs.Revenant:AddButton({
    Title = "Ir al Revenant",
    Callback = function()
        local npcs = Workspace:FindFirstChild("NPCs")
        local rev = npcs and npcs:FindFirstChild("Revenant")
        local hrp = rev and rev:FindFirstChild("HumanoidRootPart")
        if hrp then
            doTeleport(hrp.Position)
        else
            notify("Revenant", "No se encontró.", 3)
        end
    end
})

Tabs.Players:AddSection("Acciones Rápidas")
Tabs.Players:AddButton({
    Title = "Ir al Jugador Más Cercano",
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
        if closest then
            doTeleport(closest.Position)
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
                notify("Teleport", "Viajando a " .. name, 2)
            end
        end
    })
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("TRS_Panel")
SaveManager:SetFolder("TRS_Panel/Configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

task.spawn(function()
    task.wait(1.5)
    Window:SelectTab(1)
    notify("TRS Panel", "Sistema inicializado correctamente.", 4)
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
