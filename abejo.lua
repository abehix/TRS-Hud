-- The Revenant: Sunrisen [HALLOWS] - TRS Panel v23 (Fluent)
-- debugMode = true prints debug messages, false prints nothing
local debugMode = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local function log(...)
    if debugMode then
        print("[TRS]", ...)
    end
end

-- clean up older runs (this version and the old one)
if _G.trsUnload then
    pcall(_G.trsUnload)
end
if _G.TRSPanelLoaded then
    pcall(function()
        _G.TRSPanelLoaded:Destroy()
    end)
    _G.TRSPanelLoaded = nil
end

----------------------------------------------------------------------
-- loading the libraries (every step is guarded, nothing can kill the script)
----------------------------------------------------------------------

local function fetch(url)
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and #body > 0 then
        return body
    end
    log("HttpGet failed:", url, ok and "empty response" or body)

    local req = request or http_request or (syn and syn.request)
    if req then
        local ok2, res = pcall(req, { Url = url, Method = "GET" })
        if ok2 and res and type(res.Body) == "string" and #res.Body > 0 then
            return res.Body
        end
        log("request failed:", url)
    end
    return nil
end

local function loadChunk(url)
    local body = fetch(url)
    if not body then
        return nil
    end
    local chunk, err = loadstring(body)
    if not chunk then
        log("compile failed:", url, err)
        return nil
    end
    return chunk
end

local fluentChunk = loadChunk("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
local saveChunk = loadChunk("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua")
local interfaceChunk = loadChunk("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua")

if not fluentChunk then
    log("Fluent could not be downloaded, aborting")
    return
end

local canFile = isfolder ~= nil and makefolder ~= nil and isfile ~= nil and readfile ~= nil and writefile ~= nil

local savedLang = "EN"
if canFile then
    pcall(function()
        if not isfolder("TRS_Panel") then
            makefolder("TRS_Panel")
        end
        if isfile("TRS_Panel/Lang.txt") then
            local saved = string.gsub(readfile("TRS_Panel/Lang.txt"), "%s", "")
            if saved == "EN" or saved == "MX" then
                savedLang = saved
            end
        end
    end)
else
    log("no file functions in this executor, settings will not be saved")
end

----------------------------------------------------------------------
-- translations
----------------------------------------------------------------------

local translations = {
    EN = {
        welcome = "Welcome, ", connected = "Connected", executor = "Executor: ",
        account = "Account Information", status = "System Status", stats = "Live Stats",
        abilities = "Player Abilities", reset = "Reset Character",
        vision = "Environment", fullbright = "Fullbright", fullDesc = "Removes fog and darkness",
        combat = "Combat System", autoClick = "Auto Clicker", clickDesc = "Activates tools automatically",
        delay = "Delay (ms)", stamina = "Infinite Stamina", staminaDesc = "Needs getgc and hookfunction support",
        players = "Player Actions", tpClosest = "Teleport to Closest", selectPlayer = "Select player",
        tpSelected = "Teleport to Selected", esp = "Player ESP", espDesc = "Highlights other players",
        revAct = "Revenant Tracker", revEsp = "Revenant ESP", revEspDesc = "Highlights the boss",
        tpRev = "Go to Revenant", revStatus = "Revenant Status", limbs = "Limb Health",
        farm = "Scrap Farming", scrapEsp = "Scrap ESP", scrapEspDesc = "Highlights every scrap by type",
        scrapType = "Scrap type filter", scan = "Rescan Scraps", scanDesc = "Forces a new scan now",
        tpScrap = "Go to Closest Scrap", autoFarm = "Auto Farm", autoFarmDesc = "Teleports to the closest scrap",
        seerEsp = "Seer Orb ESP", seerEspDesc = "Highlights Seer orbs", tpSeer = "Go to Closest Seer Orb",
        prompts = "Auto Interact", promptsDesc = "Fires the prompts the game is showing you",
        teleport = "Teleport Locations", goTo = "Go to ", util = "Utilities", antiRag = "Anti Ragdoll",
        antiBarrier = "Anti Barrier", antiBarrierDesc = "Moves the barbed wire away",
        fastRepair = "Fast Power Repair", fastRepairDesc = "Shortens the power core hold time",
        antiAfk = "Anti-AFK", opti = "Optimization", optiTerrain = "Remove Terrain Details",
        optiTerrainDesc = "Removes grass and decoration", optiMat = "Simplify Materials",
        optiMatDesc = "SmoothPlastic on the map", optiShadow = "Disable Shadows", optiShadowDesc = "Turns off shadows",
        hop = "Server Hop", hopDesc = "Joins a different server", settings = "Settings",
        lang = "Language (Reloads UI)", unload = "Unload Panel", unloadDesc = "Removes the panel and restores everything",
        logs = "Server Logs", hourLog = "Hour Activations", roundLog = "Round Activations",
        worldLog = "World Events", none = "None yet.", waiting = "Waiting for events...",
    },
    MX = {
        welcome = "Bienvenido, ", connected = "Conectado", executor = "Executor: ",
        account = "Información de la Cuenta", status = "Estado del Sistema", stats = "Stats en Vivo",
        abilities = "Habilidades", reset = "Reiniciar Personaje",
        vision = "Entorno", fullbright = "Fullbright", fullDesc = "Quita la niebla y la oscuridad",
        combat = "Sistema de Combate", autoClick = "Auto Clicker", clickDesc = "Activa herramientas automáticamente",
        delay = "Retardo (ms)", stamina = "Stamina Infinita", staminaDesc = "Necesita soporte de getgc y hookfunction",
        players = "Acciones de Jugadores", tpClosest = "Ir al Más Cercano", selectPlayer = "Elegir jugador",
        tpSelected = "Ir al Elegido", esp = "ESP de Jugadores", espDesc = "Resalta a otros jugadores",
        revAct = "Rastreador Revenant", revEsp = "ESP del Revenant", revEspDesc = "Resalta al jefe",
        tpRev = "Ir al Revenant", revStatus = "Estado del Revenant", limbs = "Salud de Extremidades",
        farm = "Farmeo de Scraps", scrapEsp = "ESP de Scraps", scrapEspDesc = "Resalta cada scrap por tipo",
        scrapType = "Filtro de tipo de scrap", scan = "Reescanear Scraps", scanDesc = "Fuerza un escaneo ahora",
        tpScrap = "Ir al Scrap Más Cercano", autoFarm = "Auto Farmear", autoFarmDesc = "Teletransporta al scrap más cercano",
        seerEsp = "ESP de Orbes Seer", seerEspDesc = "Resalta los orbes Seer", tpSeer = "Ir al Orbe Seer Más Cercano",
        prompts = "Auto Interactuar", promptsDesc = "Activa los prompts que el juego te muestra",
        teleport = "Puntos de Teletransporte", goTo = "Ir a ", util = "Utilidades", antiRag = "Anti Ragdoll",
        antiBarrier = "Anti Barrera", antiBarrierDesc = "Aleja el alambre de púas",
        fastRepair = "Reparación Rápida de Energía", fastRepairDesc = "Acorta el tiempo de mantener en el núcleo",
        antiAfk = "Anti-AFK", opti = "Optimización", optiTerrain = "Quitar Detalles del Terreno",
        optiTerrainDesc = "Quita pasto y decoración", optiMat = "Simplificar Materiales",
        optiMatDesc = "SmoothPlastic en el mapa", optiShadow = "Apagar Sombras", optiShadowDesc = "Desactiva las sombras",
        hop = "Server Hop", hopDesc = "Salta a otro servidor", settings = "Ajustes",
        lang = "Idioma (Recarga la UI)", unload = "Descargar Panel", unloadDesc = "Quita el panel y restaura todo",
        logs = "Registros del Servidor", hourLog = "Horas Activadas", roundLog = "Rondas Activadas",
        worldLog = "Eventos del Mundo", none = "Nada todavía.", waiting = "Esperando eventos...",
    },
}

----------------------------------------------------------------------
-- the panel
----------------------------------------------------------------------

local launch

launch = function(lang)
    local text = translations[lang] or translations.EN
    local function t(key)
        return text[key] or translations.EN[key] or key
    end

    local alive = true
    local ready = false
    local connections = {}

    local function bind(signal, fn)
        local conn = signal:Connect(fn)
        table.insert(connections, conn)
        return conn
    end

    local function build(name, fn)
        local ok, err = xpcall(fn, debug.traceback)
        if not ok then
            log("section failed:", name, err)
        end
    end

    local function make(class, props, parent)
        local obj = Instance.new(class)
        for key, value in pairs(props) do
            obj[key] = value
        end
        obj.Parent = parent
        return obj
    end

    ------------------------------------------------------------------
    -- fluent window
    ------------------------------------------------------------------

    local okFluent, Fluent = pcall(fluentChunk)
    if not okFluent or type(Fluent) ~= "table" then
        log("Fluent failed to start:", Fluent)
        return
    end

    local SaveManager = nil
    local InterfaceManager = nil
    if saveChunk then
        local ok, result = pcall(saveChunk)
        SaveManager = ok and result or nil
    end
    if interfaceChunk then
        local ok, result = pcall(interfaceChunk)
        InterfaceManager = ok and result or nil
    end

    local okWindow, Window = pcall(function()
        return Fluent:CreateWindow({
            Title = "The Revenant: Sunrisen [HALLOWS] - HUD Made By @kyyabe08",
            SubTitle = "v23.0",
            TabWidth = 180,
            Size = UDim2.fromOffset(650, 520),
            Acrylic = false,
            Theme = "Dark",
            MinimizeKey = Enum.KeyCode.LeftControl,
        })
    end)
    if not okWindow or not Window then
        log("CreateWindow failed:", Window)
        return
    end
    log("window created")

    local tabs = {}
    local tabList = {
        { "Main", "Dashboard", "layout-dashboard" },
        { "Combat", "Combat", "swords" },
        { "Players", "Players", "users" },
        { "Revenant", "Revenant", "skull" },
        { "Farm", "Farm", "shovel" },
        { "Teleport", "Teleport", "map" },
        { "Utilities", "Utilities", "shield" },
        { "Logs", "Server Logs", "scroll-text" },
        { "Settings", "Settings", "settings" },
    }
    for _, entry in ipairs(tabList) do
        local ok, tab = pcall(function()
            return Window:AddTab({ Title = entry[2], Icon = entry[3] })
        end)
        if ok and tab then
            tabs[entry[1]] = tab
        else
            log("AddTab failed:", entry[2], tab)
        end
    end

    local function notify(title, content)
        pcall(function()
            Fluent:Notify({ Title = title, Content = content, Duration = 4 })
        end)
    end

    -- toasts for world events
    local toastParent = CoreGui
    if gethui then
        local ok, holder = pcall(gethui)
        if ok and holder then
            toastParent = holder
        end
    end

    local toastGui = make("ScreenGui", { Name = "TRS_Toasts", ResetOnSpawn = false, DisplayOrder = 999 }, toastParent)
    local toastHolder = make("Frame", {
        Size = UDim2.new(0, 260, 1, -40),
        Position = UDim2.new(1, -280, 0, 20),
        BackgroundTransparency = 1,
    }, toastGui)
    make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, toastHolder)

    local function showToast(message, color)
        local frame = make("Frame", {
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderSizePixel = 0,
            LayoutOrder = math.floor(os.clock() * 1000),
        }, toastHolder)
        make("UICorner", { CornerRadius = UDim.new(0, 6) }, frame)
        make("UIStroke", { Color = color, Thickness = 1 }, frame)
        local label = make("TextLabel", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = message,
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextWrapped = true,
        }, frame)
        task.delay(4, function()
            if frame.Parent then
                TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
                TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
                task.wait(0.45)
                if frame.Parent then
                    frame:Destroy()
                end
            end
        end)
    end

    ------------------------------------------------------------------
    -- shared helpers
    ------------------------------------------------------------------

    local function getRoot()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function getHumanoid()
        local char = LocalPlayer.Character
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    local function teleportCFrame(cframe)
        local root = getRoot()
        if root and cframe then
            root.CFrame = cframe
            return true
        end
        return false
    end

    local function teleportPos(position)
        if position then
            return teleportCFrame(CFrame.new(position + Vector3.new(0, 4, 0)))
        end
        return false
    end

    local function positionOf(model)
        if not model or not model.Parent then
            return nil
        end
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position
    end

    local function closestIn(models)
        local root = getRoot()
        if not root then
            return nil
        end
        local best = nil
        local bestDist = nil
        for _, model in ipairs(models) do
            local pos = positionOf(model)
            if pos then
                local dist = (pos - root.Position).Magnitude
                if not bestDist or dist < bestDist then
                    best = model
                    bestDist = dist
                end
            end
        end
        return best, bestDist
    end

    local function getExecutor()
        if identifyexecutor then
            local ok, name = pcall(identifyexecutor)
            if ok and name then
                return tostring(name)
            end
        end
        return "Unknown"
    end

    local function healthPct(hum)
        return math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    end

    -- state
    local autoClickOn = false
    local clickDelay = 0.1
    local staminaOn = false
    local autoInteractOn = false
    local antiRagdollOn = true
    local antiBarrierOn = false
    local fastRepairOn = false
    local antiAfkOn = true
    local fullbrightOn = false
    local noShadowsOn = false
    local materialsOn = false
    local playerEspOn = false
    local revEspOn = false
    local scrapEspOn = true
    local seerEspOn = true
    local autoFarmOn = false
    local scrapFilter = "All"
    local selectedPlayer = nil

    -- paragraphs that get live updates
    local liveStats = nil
    local revPara = nil
    local limbPara = nil
    local scrapPara = nil
    local seerPara = nil
    local hourPara = nil
    local roundPara = nil
    local worldPara = nil

    ------------------------------------------------------------------
    -- lighting (remembers what the game had before we touched it)
    ------------------------------------------------------------------

    local lightingBackup = nil
    local terrainBackup = nil

    local function applyLighting()
        local wantBright = fullbrightOn
        local wantNoShadows = fullbrightOn or noShadowsOn
        if (wantBright or wantNoShadows) and not lightingBackup then
            lightingBackup = {
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
            }
        end
        if lightingBackup then
            if wantBright then
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Lighting.FogEnd = 100000
            else
                Lighting.Ambient = lightingBackup.Ambient
                Lighting.OutdoorAmbient = lightingBackup.OutdoorAmbient
                Lighting.FogEnd = lightingBackup.FogEnd
            end
            Lighting.GlobalShadows = (not wantNoShadows) and lightingBackup.GlobalShadows
            if not wantBright and not wantNoShadows then
                lightingBackup = nil
            end
        end
    end

    ------------------------------------------------------------------
    -- esp (scraps, orbs, players, revenant)
    ------------------------------------------------------------------

    local espItems = {}

    local function groupEnabled(group)
        if group == "scrap" then
            return scrapEspOn
        end
        return seerEspOn
    end

    local function attachEsp(model, group, color, text)
        if espItems[model] then
            return
        end
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        if not part then
            return
        end
        local highlight = make("Highlight", {
            Name = "TRS_Esp",
            FillColor = color,
            OutlineColor = Color3.new(1, 1, 1),
            FillTransparency = 0.5,
            OutlineTransparency = 0.1,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
            Adornee = model,
            Enabled = groupEnabled(group),
        }, model)
        local tag = make("BillboardGui", {
            Name = "TRS_EspTag",
            Size = UDim2.fromOffset(170, 26),
            StudsOffset = Vector3.new(0, 3, 0),
            AlwaysOnTop = true,
            MaxDistance = 400,
            Adornee = part,
            Enabled = groupEnabled(group),
        }, part)
        make("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = color,
            TextStrokeColor3 = Color3.new(0, 0, 0),
            TextStrokeTransparency = 0.3,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
        }, tag)
        espItems[model] = { highlight = highlight, tag = tag, group = group }
    end

    local function refreshEsp()
        for model, item in pairs(espItems) do
            local on = groupEnabled(item.group)
            item.highlight.Enabled = on
            item.tag.Enabled = on
        end
    end

    local function cleanEsp()
        for model, item in pairs(espItems) do
            if not model:IsDescendantOf(Workspace) then
                item.highlight:Destroy()
                item.tag:Destroy()
                espItems[model] = nil
            end
        end
    end

    local playerEsp = {}

    local function clearPlayerEsp()
        for plr, highlight in pairs(playerEsp) do
            highlight:Destroy()
            playerEsp[plr] = nil
        end
    end

    local function updatePlayerEsp()
        if not playerEspOn then
            if next(playerEsp) then
                clearPlayerEsp()
            end
            return
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if plr ~= LocalPlayer and char then
                local highlight = playerEsp[plr]
                if not highlight or not highlight.Parent or highlight.Adornee ~= char then
                    if highlight then
                        highlight:Destroy()
                    end
                    playerEsp[plr] = make("Highlight", {
                        Name = "TRS_PlayerEsp",
                        FillColor = Color3.fromRGB(255, 50, 50),
                        FillTransparency = 0.5,
                        OutlineColor = Color3.new(1, 1, 1),
                        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                        Adornee = char,
                    }, char)
                end
            end
        end
        for plr, highlight in pairs(playerEsp) do
            if not plr.Parent then
                highlight:Destroy()
                playerEsp[plr] = nil
            end
        end
    end

    local revHighlight = nil

    local function updateRevEsp(rev)
        if revEspOn and rev then
            if not revHighlight or not revHighlight.Parent or revHighlight.Adornee ~= rev then
                if revHighlight then
                    revHighlight:Destroy()
                end
                revHighlight = make("Highlight", {
                    Name = "TRS_RevEsp",
                    FillColor = Color3.fromRGB(255, 0, 100),
                    FillTransparency = 0.4,
                    OutlineColor = Color3.new(1, 1, 1),
                    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                    Adornee = rev,
                }, rev)
            end
        elseif revHighlight then
            revHighlight:Destroy()
            revHighlight = nil
        end
    end

    ------------------------------------------------------------------
    -- world logs
    ------------------------------------------------------------------

    local hourHistory = {}
    local roundHistory = {}
    local worldHistory = {}

    local function formatCounts(history)
        local sorted = {}
        for name, count in pairs(history) do
            table.insert(sorted, { name = name, count = count })
        end
        if #sorted == 0 then
            return t("none")
        end
        table.sort(sorted, function(a, b)
            if a.count == b.count then
                return a.name < b.name
            end
            return a.count > b.count
        end)
        local lines = {}
        for _, entry in ipairs(sorted) do
            table.insert(lines, entry.name .. " (x" .. entry.count .. ")")
        end
        return table.concat(lines, "\n")
    end

    local function updateLogs()
        if hourPara then
            hourPara:SetDesc(formatCounts(hourHistory))
        end
        if roundPara then
            roundPara:SetDesc(formatCounts(roundHistory))
        end
        if worldPara then
            worldPara:SetDesc(#worldHistory > 0 and table.concat(worldHistory, "\n") or t("waiting"))
        end
    end

    local function addWorldLog(message, color)
        table.insert(worldHistory, 1, "[" .. os.date("%X") .. "] " .. message)
        while #worldHistory > 10 do
            table.remove(worldHistory)
        end
        updateLogs()
        if color then
            showToast(message, color)
        end
    end

    ------------------------------------------------------------------
    -- features: stamina, interact, ragdoll, barriers, repair
    ------------------------------------------------------------------

    local hookedTake = nil
    local hookedCheck = nil
    local hooksReady = false

    local function installStaminaHooks()
        if hooksReady or not getgc or not hookfunction then
            return
        end
        for _, fn in pairs(getgc(true)) do
            if typeof(fn) == "function" then
                local okInfo, info = pcall(debug.getinfo, fn)
                if okInfo and info then
                    if info.name == "TakeStamina" and not hookedTake then
                        hookedTake = hookfunction(fn, function(...)
                            if staminaOn then
                                return
                            end
                            return hookedTake(...)
                        end)
                    elseif info.name == "CheckStamina" and not hookedCheck then
                        hookedCheck = hookfunction(fn, function(...)
                            if staminaOn then
                                return true
                            end
                            return hookedCheck(...)
                        end)
                    end
                end
            end
        end
        hooksReady = hookedTake ~= nil or hookedCheck ~= nil
        log("stamina hooks ready:", hooksReady)
    end

    local shownPrompts = {}
    bind(ProximityPromptService.PromptShown, function(prompt)
        shownPrompts[prompt] = true
    end)
    bind(ProximityPromptService.PromptHidden, function(prompt)
        shownPrompts[prompt] = nil
    end)

    local stash = nil
    local ragdollMoved = {}
    local barrierMoved = {}

    local function getStash()
        if not stash or not stash.Parent then
            stash = make("Folder", { Name = "TRS_Stash" }, Lighting)
        end
        return stash
    end

    local function moveParts(source, record, skip)
        if not source then
            return
        end
        for _, part in ipairs(source:GetChildren()) do
            if not (skip and skip(part)) then
                record[part] = source
                part.Parent = getStash()
            end
        end
    end

    local function putBack(record)
        for part, originalParent in pairs(record) do
            if part.Parent and originalParent.Parent then
                part.Parent = originalParent
            end
            record[part] = nil
        end
    end

    local function belongsToCharacter(part)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and part:IsDescendantOf(plr.Character) then
                return true
            end
        end
        return false
    end

    local function applyHumanoidAntiRagdoll(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then
            return
        end
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            hum.PlatformStand = false
        end)
    end

    local function runAntiRagdoll()
        local filter = Workspace:FindFirstChild("Filter")
        local parts = filter and filter:FindFirstChild("RagdollParts")
        moveParts(parts, ragdollMoved, belongsToCharacter)
        applyHumanoidAntiRagdoll(LocalPlayer.Character)
    end

    local function runAntiBarrier()
        local filter = Workspace:FindFirstChild("Filter")
        local wire = filter and filter:FindFirstChild("BarbedWire")
        moveParts(wire, barrierMoved)
    end

    bind(LocalPlayer.CharacterAdded, function(char)
        task.wait(0.5)
        if antiRagdollOn then
            applyHumanoidAntiRagdoll(char)
        end
    end)

    local repairPrompt = nil
    local originalHold = nil

    local function setFastRepair(on)
        local map = Workspace:FindFirstChild("MAP")
        local main = map and map:FindFirstChild("MAIN")
        local structures = main and main:FindFirstChild("Structures")
        local station = structures and structures:FindFirstChild("PowerStation")
        local core = station and station:FindFirstChild("Core")
        local prompt = core and core:FindFirstChildWhichIsA("ProximityPrompt")
        if on then
            if not prompt then
                return
            end
            if prompt ~= repairPrompt then
                repairPrompt = prompt
                originalHold = prompt.HoldDuration
            end
            prompt.HoldDuration = 0.1
        elseif repairPrompt and repairPrompt.Parent then
            repairPrompt.HoldDuration = originalHold or 30
        end
    end

    bind(LocalPlayer.Idled, function()
        if antiAfkOn then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)

    local originalMaterials = {}

    local function simplifyMaterials(on)
        materialsOn = on
        if on then
            local map = Workspace:FindFirstChild("MAP") or Workspace:FindFirstChild("Map")
            if not map then
                return
            end
            task.spawn(function()
                local count = 0
                for _, part in ipairs(map:GetDescendants()) do
                    if not materialsOn or not alive then
                        break
                    end
                    if part:IsA("BasePart") and part.Material ~= Enum.Material.SmoothPlastic then
                        originalMaterials[part] = part.Material
                        part.Material = Enum.Material.SmoothPlastic
                    end
                    count = count + 1
                    if count % 400 == 0 then
                        task.wait()
                    end
                end
            end)
        else
            for part, material in pairs(originalMaterials) do
                if part.Parent then
                    part.Material = material
                end
                originalMaterials[part] = nil
            end
        end
    end

    local function setTerrainDetails(remove)
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if not terrain then
            return
        end
        pcall(function()
            if remove then
                if terrainBackup == nil then
                    terrainBackup = terrain.Decoration
                end
                terrain.Decoration = false
            elseif terrainBackup ~= nil then
                terrain.Decoration = terrainBackup
                terrainBackup = nil
            end
        end)
    end

    local function serverHop()
        notify("Server Hop", "...")
        task.spawn(function()
            local ok, err = pcall(function()
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                local body = fetch(url)
                if not body then
                    error("could not fetch the server list")
                end
                local data = HttpService:JSONDecode(body)
                local options = {}
                for _, server in ipairs(data.data or {}) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        table.insert(options, server.id)
                    end
                end
                if #options == 0 then
                    error("no free servers found")
                end
                TeleportService:TeleportToPlaceInstance(game.PlaceId, options[math.random(1, #options)], LocalPlayer)
            end)
            if not ok then
                log("server hop failed:", err)
                notify("Server Hop", "No server found, try again.")
            end
        end)
    end

    ------------------------------------------------------------------
    -- scraps and seer orbs
    ------------------------------------------------------------------

    local scrapKinds = {
        { name = "Golden", color = Color3.fromRGB(240, 190, 80), match = Color3.fromRGB(248, 186, 0) },
        { name = "Cursed", color = Color3.fromRGB(230, 80, 100), match = Color3.fromRGB(255, 0, 0) },
        { name = "Metal", color = Color3.fromRGB(150, 160, 175), match = Color3.fromRGB(66, 63, 65) },
        { name = "Rusty", color = Color3.fromRGB(180, 120, 90), match = Color3.fromRGB(98, 98, 98) },
    }
    local diamondKind = { name = "Diamond", color = Color3.fromRGB(130, 220, 240) }
    local seerColor = Color3.fromRGB(184, 144, 244)

    local function colorClose(a, b)
        return math.abs(a.R - b.R) * 255 <= 5 and math.abs(a.G - b.G) * 255 <= 5 and math.abs(a.B - b.B) * 255 <= 5
    end

    local function kindOf(scrap)
        local part = scrap.PrimaryPart or scrap:FindFirstChildWhichIsA("BasePart", true)
        if not part then
            return diamondKind
        end
        for _, kind in ipairs(scrapKinds) do
            if colorClose(part.Color, kind.match) then
                return kind
            end
        end
        return diamondKind
    end

    local function isScrapName(name)
        return string.sub(name, 1, 5) == "Scrap"
    end

    local function findScraps(folder)
        local found = {}
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") and isScrapName(child.Name) then
                table.insert(found, child)
            elseif child:IsA("BasePart") then
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA("Model") and isScrapName(sub.Name) then
                        table.insert(found, sub)
                    end
                end
            end
        end
        return found
    end

    local scrapList = {}
    local lastScrapTotal = -1

    local function filteredScraps()
        if scrapFilter == "All" then
            local all = {}
            for _, entry in ipairs(scrapList) do
                table.insert(all, entry.model)
            end
            return all
        end
        local filtered = {}
        for _, entry in ipairs(scrapList) do
            if entry.kind.name == scrapFilter then
                table.insert(filtered, entry.model)
            end
        end
        return filtered
    end

    local function scanScraps()
        local map = Workspace:FindFirstChild("MAP") or Workspace:FindFirstChild("Map")
        local root = map and map:FindFirstChild("Scraps")
        local list = {}
        local counts = {}

        if root then
            for _, folder in ipairs(root:GetChildren()) do
                if folder:IsA("Folder") then
                    for _, scrap in ipairs(findScraps(folder)) do
                        local kind = kindOf(scrap)
                        table.insert(list, { model = scrap, kind = kind })
                        counts[kind.name] = (counts[kind.name] or 0) + 1
                        attachEsp(scrap, "scrap", kind.color, kind.name .. " Scrap")
                    end
                end
            end
        end

        scrapList = list

        if scrapPara then
            local lines = { "Total: " .. #list }
            for _, kind in ipairs(scrapKinds) do
                table.insert(lines, kind.name .. ": " .. (counts[kind.name] or 0))
            end
            table.insert(lines, diamondKind.name .. ": " .. (counts[diamondKind.name] or 0))
            scrapPara:SetDesc(table.concat(lines, "\n"))
        end

        if ready and lastScrapTotal >= 0 and #list > lastScrapTotal then
            notify("Farm", (#list - lastScrapTotal) .. " new scrap(s)")
        end
        lastScrapTotal = #list
    end

    local seerList = {}
    local lastSeerCount = -1

    local function scanSeerOrbs()
        local debris = Workspace:FindFirstChild("Debris")
        local folder = debris and debris:FindFirstChild("SeerOrbs")
        local list = {}
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") and string.sub(child.Name, 1, 8) == "Seer Orb" then
                    table.insert(list, child)
                    attachEsp(child, "seer", seerColor, "Seer Orb")
                end
            end
        end
        seerList = list
        if seerPara then
            seerPara:SetDesc(folder and (#list .. " active") or "Waiting for the SeerOrbs folder...")
        end
        if lastSeerCount >= 0 and #list > lastSeerCount then
            addWorldLog("A Seer orb appeared!", seerColor)
        end
        lastSeerCount = #list
    end

    ------------------------------------------------------------------
    -- revenant status
    ------------------------------------------------------------------

    local limbNames = { "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
    local limbMax = {}

    local function readLimb(name)
        local data = ReplicatedStorage:FindFirstChild("CharacterData")
        local rev = data and data:FindFirstChild("Revenant")
        local stuff = rev and rev:FindFirstChild("PlayerStuff")
        local health = stuff and stuff:FindFirstChild("LimbHealth")
        local limb = health and health:FindFirstChild(name)
        if not limb then
            return nil
        end
        local current = limb.Value
        local max = limb:GetAttribute("Max")
        if not max then
            local maxObj = health:FindFirstChild(name .. "Max") or limb:FindFirstChild("Max")
            max = maxObj and maxObj.Value
        end
        if not max then
            limbMax[name] = math.max(limbMax[name] or 0, current)
            max = limbMax[name]
        end
        return current, max
    end

    local revAlive = false
    local revLastHealth = 0
    local shedExisted = false

    local function updateRevenant()
        local npcs = Workspace:FindFirstChild("NPCs")
        local rev = npcs and npcs:FindFirstChild("Revenant")
        local hum = rev and (rev:FindFirstChildOfClass("Humanoid") or rev:FindFirstChild("NPC"))

        if rev and hum then
            if not revAlive then
                revAlive = true
                addWorldLog("The Revenant has spawned!", Color3.fromRGB(255, 50, 50))
            end
            if hum.Health <= 0 and revLastHealth > 0 then
                revAlive = false
                addWorldLog("The Revenant has died!", Color3.fromRGB(255, 50, 50))
            end
            revLastHealth = hum.Health
        elseif revAlive then
            revAlive = false
            revLastHealth = 0
            addWorldLog("The Revenant despawned.", Color3.fromRGB(150, 150, 150))
        end

        if revPara then
            if rev and hum then
                local root = rev:FindFirstChild("HumanoidRootPart") or rev:FindFirstChild("Head")
                local mine = getRoot()
                local dist = root and mine and math.floor((root.Position - mine.Position).Magnitude)
                local shield = rev:FindFirstChild("SpawnFF") or rev:FindFirstChildOfClass("ForceField")
                revPara:SetDesc(string.format(
                    "Health: %d / %d\nDistance: %s\nForceField: %s\nState: %s",
                    math.floor(hum.Health), math.floor(hum.MaxHealth),
                    dist and (dist .. " studs") or "-",
                    shield and "Active" or "None",
                    hum.Health > 0 and "Alive" or "Dead"
                ))
            else
                revPara:SetDesc("Not spawned")
            end
        end

        if limbPara then
            local lines = {}
            for _, name in ipairs(limbNames) do
                local current, max = readLimb(name)
                if current and max and max > 0 then
                    table.insert(lines, name .. ": " .. math.floor(current) .. " / " .. math.floor(max))
                else
                    table.insert(lines, name .. ": - / -")
                end
            end
            limbPara:SetDesc(table.concat(lines, "\n"))
        end

        return rev
    end

    ------------------------------------------------------------------
    -- dashboard text
    ------------------------------------------------------------------

    local fps = 0

    local function statValue(stats, name)
        local obj = stats and stats:FindFirstChild(name)
        return tostring(obj and obj.Value or 0)
    end

    local function updateLiveStats()
        if not liveStats then
            return
        end
        local hum = getHumanoid()
        local root = getRoot()
        local hpText = "-"
        local speedText = "0"
        if hum then
            hpText = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
        end
        if root then
            local vel = root.AssemblyLinearVelocity
            speedText = tostring(math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude))
        end
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        local stats = LocalPlayer:FindFirstChild("leaderstats")
        liveStats:SetDesc(string.format(
            "Health: %s\nSpeed: %s\nFPS: %d | Ping: %d ms\nKills: %s | Points: %s | S-Kills: %s | DDT: %s",
            hpText, speedText, fps, ping,
            statValue(stats, "Kills"), statValue(stats, "Points"), statValue(stats, "S-Kills"), statValue(stats, "DDT")
        ))
    end

    ------------------------------------------------------------------
    -- tab: dashboard
    ------------------------------------------------------------------

    build("Dashboard", function()
        local tab = tabs.Main
        tab:AddSection(t("account"))
        tab:AddParagraph({
            Title = "The Revenant: Sunrisen [HALLOWS]",
            Content = "HUD Made By @kyyabe08\n" .. t("welcome") .. LocalPlayer.Name,
        })
        tab:AddParagraph({
            Title = t("status"),
            Content = string.format("%s: %s\n%s%s", "Status", t("connected"), t("executor"), getExecutor()),
        })
        liveStats = tab:AddParagraph({ Title = t("stats"), Content = "..." })

        tab:AddSection(t("abilities"))
        tab:AddButton({
            Title = t("reset"),
            Callback = function()
                local hum = getHumanoid()
                if hum then
                    hum.Health = 0
                end
            end,
        })

        tab:AddSection(t("vision"))
        tab:AddToggle("Fullbright", {
            Title = t("fullbright"),
            Description = t("fullDesc"),
            Default = false,
            Callback = function(on)
                fullbrightOn = on
                applyLighting()
            end,
        })
    end)

    ------------------------------------------------------------------
    -- tab: combat
    ------------------------------------------------------------------

    build("Combat", function()
        local tab = tabs.Combat
        tab:AddSection(t("combat"))
        tab:AddToggle("AutoClicker", {
            Title = t("autoClick"),
            Description = t("clickDesc"),
            Default = false,
            Callback = function(on)
                autoClickOn = on
            end,
        })
        tab:AddSlider("ClickDelay", {
            Title = t("delay"),
            Default = 100,
            Min = 10,
            Max = 1000,
            Rounding = 0,
            Callback = function(value)
                clickDelay = value / 1000
            end,
        })
        tab:AddToggle("InfiniteStamina", {
            Title = t("stamina"),
            Description = t("staminaDesc"),
            Default = false,
            Callback = function(on)
                staminaOn = on
                if on and not hooksReady then
                    task.spawn(installStaminaHooks)
                end
            end,
        })
    end)

    ------------------------------------------------------------------
    -- tab: players
    ------------------------------------------------------------------

    local playerDropdown = nil

    local function playerNames()
        local names = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                table.insert(names, plr.Name)
            end
        end
        table.sort(names)
        return names
    end

    build("Players", function()
        local tab = tabs.Players
        tab:AddSection(t("players"))
        tab:AddToggle("PlayerESP", {
            Title = t("esp"),
            Description = t("espDesc"),
            Default = false,
            Callback = function(on)
                playerEspOn = on
                if not on then
                    clearPlayerEsp()
                end
            end,
        })
        tab:AddButton({
            Title = t("tpClosest"),
            Callback = function()
                local models = {}
                for _, plr in ipairs(Players:GetPlayers()) do
                    local char = plr.Character
                    if plr ~= LocalPlayer and char then
                        table.insert(models, char)
                    end
                end
                local target = closestIn(models)
                if target and teleportPos(positionOf(target)) then
                    notify("Players", "Teleported to " .. target.Name)
                end
            end,
        })
        playerDropdown = tab:AddDropdown("PlayerTarget", {
            Title = t("selectPlayer"),
            Values = playerNames(),
            Multi = false,
            Callback = function(value)
                selectedPlayer = value
            end,
        })
        tab:AddButton({
            Title = t("tpSelected"),
            Callback = function()
                local plr = selectedPlayer and Players:FindFirstChild(selectedPlayer)
                local char = plr and plr.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root and teleportPos(root.Position) then
                    notify("Players", "Teleported to " .. plr.Name)
                else
                    notify("Players", "That player has no character.")
                end
            end,
        })
    end)

    local function refreshPlayerDropdown()
        if playerDropdown then
            pcall(function()
                playerDropdown:SetValues(playerNames())
            end)
        end
    end

    bind(Players.PlayerAdded, function()
        task.delay(0.5, refreshPlayerDropdown)
    end)
    bind(Players.PlayerRemoving, function()
        task.delay(0.5, refreshPlayerDropdown)
    end)

    ------------------------------------------------------------------
    -- tab: revenant
    ------------------------------------------------------------------

    build("Revenant", function()
        local tab = tabs.Revenant
        tab:AddSection(t("revAct"))
        tab:AddToggle("RevESP", {
            Title = t("revEsp"),
            Description = t("revEspDesc"),
            Default = false,
            Callback = function(on)
                revEspOn = on
            end,
        })
        tab:AddButton({
            Title = t("tpRev"),
            Callback = function()
                local npcs = Workspace:FindFirstChild("NPCs")
                local rev = npcs and npcs:FindFirstChild("Revenant")
                local root = rev and rev:FindFirstChild("HumanoidRootPart")
                if root and teleportPos(root.Position) then
                    notify("Revenant", "Teleported to the Revenant")
                else
                    notify("Revenant", "The Revenant is not around.")
                end
            end,
        })
        revPara = tab:AddParagraph({ Title = t("revStatus"), Content = "..." })
        limbPara = tab:AddParagraph({ Title = t("limbs"), Content = "..." })
    end)

    ------------------------------------------------------------------
    -- tab: farm
    ------------------------------------------------------------------

    build("Farm", function()
        local tab = tabs.Farm
        tab:AddSection(t("farm"))
        scrapPara = tab:AddParagraph({ Title = "Scraps", Content = "..." })
        tab:AddToggle("ScrapESP", {
            Title = t("scrapEsp"),
            Description = t("scrapEspDesc"),
            Default = true,
            Callback = function(on)
                scrapEspOn = on
                refreshEsp()
            end,
        })
        tab:AddDropdown("ScrapFilter", {
            Title = t("scrapType"),
            Values = { "All", "Golden", "Cursed", "Metal", "Rusty", "Diamond" },
            Multi = false,
            Default = "All",
            Callback = function(value)
                scrapFilter = value or "All"
            end,
        })
        tab:AddButton({
            Title = t("scan"),
            Description = t("scanDesc"),
            Callback = function()
                scanScraps()
                notify("Farm", "Found " .. #scrapList .. " scraps.")
            end,
        })
        tab:AddButton({
            Title = t("tpScrap"),
            Callback = function()
                local target = closestIn(filteredScraps())
                if target and teleportPos(positionOf(target)) then
                    notify("Farm", "Teleported to a " .. kindOf(target).name .. " scrap")
                else
                    notify("Farm", "No scrap found.")
                end
            end,
        })
        tab:AddToggle("AutoFarm", {
            Title = t("autoFarm"),
            Description = t("autoFarmDesc"),
            Default = false,
            Callback = function(on)
                autoFarmOn = on
            end,
        })
        tab:AddToggle("AutoPrompt", {
            Title = t("prompts"),
            Description = t("promptsDesc"),
            Default = false,
            Callback = function(on)
                autoInteractOn = on
            end,
        })

        tab:AddSection("Seer")
        seerPara = tab:AddParagraph({ Title = "Seer Orbs", Content = "..." })
        tab:AddToggle("SeerESP", {
            Title = t("seerEsp"),
            Description = t("seerEspDesc"),
            Default = true,
            Callback = function(on)
                seerEspOn = on
                refreshEsp()
            end,
        })
        tab:AddButton({
            Title = t("tpSeer"),
            Callback = function()
                local target = closestIn(seerList)
                if target and teleportPos(positionOf(target)) then
                    notify("Farm", "Teleported to a Seer orb")
                else
                    notify("Farm", "No Seer orb found.")
                end
            end,
        })
    end)

    ------------------------------------------------------------------
    -- tab: teleport
    ------------------------------------------------------------------

    build("Teleport", function()
        local tab = tabs.Teleport
        tab:AddSection(t("teleport"))

        local locations = {
            { "Bunker Elevator", CFrame.new(-97.3507233, -61.6877441, 167.447845, -0.867502749, 5.45476464e-09, 0.497432351, 3.02724033e-08, 1, 4.18280592e-08, -0.497432351, 5.13444292e-08, -0.867502749) },
            { "Bunker Inside", CFrame.new(-137.785004, -112.900253, 359.073578, -0.983092606, 1.47594141e-08, 0.18310903, 2.8739187e-08, 1, 7.3693073e-08, -0.18310903, 7.77095224e-08, -0.983092606) },
            { "Cave", CFrame.new(110.269135, 14.3999996, -209.216293, 0.0615922473, 1.01011416e-07, -0.998101413, -2.95501779e-09, 1, 1.01021207e-07, 0.998101413, -3.27271588e-09, 0.0615922473) },
            { "Church", CFrame.new(359.619049, 16.1122551, 403.016052, -0.500098109, -3.9637829e-08, -0.865968764, -2.02284003e-08, 1, -3.40908883e-08, 0.865968764, 4.68374894e-10, -0.500098109) },
            { "Power Station", CFrame.new(-244.704498, 21.5832672, 212.771057, 0.445394725, 5.09012139e-08, -0.895334303, -5.72926702e-08, 1, 2.83507067e-08, 0.895334303, 3.86688406e-08, 0.445394725) },
            { "Scrap Building", CFrame.new(-458.86499, -3.20000076, 23.5130329, -0.466499627, -3.04420489e-09, 0.884521365, 9.10452047e-10, 1, 3.92181621e-09, -0.884521365, 2.63484035e-09, -0.466499627) },
            { "Shop", CFrame.new(-287.998016, -13.7416973, -454.909027, 0.857612252, -5.73287773e-09, 0.51429683, -1.40598155e-08, 1, 3.45923716e-08, -0.51429683, -3.68977631e-08, 0.857612252) },
            { "Small Building", CFrame.new(29.1171055, 21.6652622, -327.872223, -0.422592998, 0, 0.906319618, 0, 1, 0, -0.906319618, 0, -0.422592998) },
            { "Underground Bunker", CFrame.new(-333, -3, 30, 0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, 0.499959469) },
        }

        for _, location in ipairs(locations) do
            tab:AddButton({
                Title = t("goTo") .. location[1],
                Callback = function()
                    if teleportCFrame(location[2]) then
                        notify("Teleport", t("goTo") .. location[1])
                    end
                end,
            })
        end
    end)

    ------------------------------------------------------------------
    -- tab: utilities
    ------------------------------------------------------------------

    build("Utilities", function()
        local tab = tabs.Utilities
        tab:AddSection(t("util"))
        tab:AddToggle("AntiRagdoll", {
            Title = t("antiRag"),
            Default = true,
            Callback = function(on)
                antiRagdollOn = on
                if not on then
                    putBack(ragdollMoved)
                end
            end,
        })
        tab:AddToggle("AntiBarrier", {
            Title = t("antiBarrier"),
            Description = t("antiBarrierDesc"),
            Default = false,
            Callback = function(on)
                antiBarrierOn = on
                if not on then
                    putBack(barrierMoved)
                end
            end,
        })
        tab:AddToggle("FastRepair", {
            Title = t("fastRepair"),
            Description = t("fastRepairDesc"),
            Default = false,
            Callback = function(on)
                fastRepairOn = on
                pcall(setFastRepair, on)
            end,
        })
        tab:AddToggle("AntiAFK", {
            Title = t("antiAfk"),
            Default = true,
            Callback = function(on)
                antiAfkOn = on
            end,
        })
        tab:AddButton({
            Title = t("hop"),
            Description = t("hopDesc"),
            Callback = serverHop,
        })

        tab:AddSection(t("opti"))
        tab:AddToggle("OptiTerrain", {
            Title = t("optiTerrain"),
            Description = t("optiTerrainDesc"),
            Default = false,
            Callback = function(on)
                setTerrainDetails(on)
            end,
        })
        tab:AddToggle("OptiMat", {
            Title = t("optiMat"),
            Description = t("optiMatDesc"),
            Default = false,
            Callback = function(on)
                simplifyMaterials(on)
            end,
        })
        tab:AddToggle("OptiShadow", {
            Title = t("optiShadow"),
            Description = t("optiShadowDesc"),
            Default = false,
            Callback = function(on)
                noShadowsOn = on
                applyLighting()
            end,
        })
    end)

    ------------------------------------------------------------------
    -- tab: logs
    ------------------------------------------------------------------

    build("Logs", function()
        local tab = tabs.Logs
        tab:AddSection(t("logs"))
        hourPara = tab:AddParagraph({ Title = t("hourLog"), Content = t("none") })
        roundPara = tab:AddParagraph({ Title = t("roundLog"), Content = t("none") })
        worldPara = tab:AddParagraph({ Title = t("worldLog"), Content = t("waiting") })
    end)

    task.spawn(function()
        local values = ReplicatedStorage:WaitForChild("Values", 10)
        if not values or not alive then
            log("Values folder not found")
            return
        end

        local hourActive = values:WaitForChild("HourActive", 10)
        local hourName = hourActive and hourActive:WaitForChild("HourName", 10)
        if hourName then
            local function recordHour(value, silent)
                if value and value ~= "" and value ~= "None" then
                    hourHistory[value] = (hourHistory[value] or 0) + 1
                    if silent then
                        updateLogs()
                    else
                        addWorldLog("Hour activated: " .. value, Color3.fromRGB(255, 200, 0))
                    end
                end
            end
            bind(hourName.Changed, function(value)
                recordHour(value, false)
            end)
            recordHour(hourName.Value, true)
        else
            log("HourName not found")
        end

        local roundActive = values:WaitForChild("SRoundActive", 10)
        local roundName = roundActive and roundActive:WaitForChild("RoundName", 10)
        if roundName then
            bind(roundName.Changed, function(value)
                if value and value ~= "" and value ~= "None" then
                    roundHistory[value] = (roundHistory[value] or 0) + 1
                    addWorldLog("Round activated: " .. value, Color3.fromRGB(200, 50, 200))
                end
            end)
        else
            log("RoundName not found")
        end

        local market = values:FindFirstChild("BlackMarketActive")
        if market then
            bind(market.Changed, function(value)
                if value then
                    addWorldLog("Black Market is OPEN", Color3.fromRGB(0, 255, 0))
                else
                    addWorldLog("Black Market closed", Color3.fromRGB(255, 0, 0))
                end
            end)
        end
    end)

    ------------------------------------------------------------------
    -- unload (also used by the language switch)
    ------------------------------------------------------------------

    local function unload()
        if not alive then
            return
        end
        alive = false
        autoClickOn = false
        staminaOn = false
        autoInteractOn = false
        autoFarmOn = false
        fastRepairOn = false
        playerEspOn = false
        revEspOn = false
        fullbrightOn = false
        noShadowsOn = false

        pcall(setFastRepair, false)
        putBack(ragdollMoved)
        putBack(barrierMoved)
        simplifyMaterials(false)
        setTerrainDetails(false)
        applyLighting()

        for model, item in pairs(espItems) do
            item.highlight:Destroy()
            item.tag:Destroy()
            espItems[model] = nil
        end
        clearPlayerEsp()
        if revHighlight then
            revHighlight:Destroy()
            revHighlight = nil
        end

        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
        connections = {}

        if stash then
            stash:Destroy()
        end
        toastGui:Destroy()
        pcall(function()
            Fluent:Destroy()
        end)
        _G.trsUnload = nil
        log("unloaded")
    end

    _G.trsUnload = unload

    ------------------------------------------------------------------
    -- tab: settings
    ------------------------------------------------------------------

    build("Settings", function()
        local tab = tabs.Settings
        tab:AddSection(t("settings"))
        tab:AddDropdown("Language", {
            Title = t("lang"),
            Values = { "English", "Español" },
            Multi = false,
            Default = lang == "EN" and "English" or "Español",
            Callback = function(value)
                local newLang = value == "English" and "EN" or "MX"
                if not ready or newLang == lang then
                    return
                end
                if canFile then
                    pcall(writefile, "TRS_Panel/Lang.txt", newLang)
                end
                task.defer(function()
                    unload()
                    launch(newLang)
                end)
            end,
        })
        tab:AddButton({
            Title = t("unload"),
            Description = t("unloadDesc"),
            Callback = function()
                task.defer(unload)
            end,
        })

        if SaveManager and InterfaceManager and canFile then
            local ok, err = pcall(function()
                SaveManager:SetLibrary(Fluent)
                InterfaceManager:SetLibrary(Fluent)
                SaveManager:IgnoreThemeSettings()
                SaveManager:SetIgnoreIndexes({ "Language", "PlayerTarget" })
                InterfaceManager:SetFolder("TRS_Panel")
                SaveManager:SetFolder("TRS_Panel/Configs")
                InterfaceManager:BuildInterfaceSection(tab)
                SaveManager:BuildConfigSection(tab)
            end)
            if not ok then
                log("save manager setup failed:", err)
            end
        else
            log("SaveManager or InterfaceManager unavailable, skipping config section")
        end
    end)

    ------------------------------------------------------------------
    -- main loop (one connection, three speeds)
    ------------------------------------------------------------------

    local frames = 0
    local fastTimer = 0
    local midTimer = 0
    local slowTimer = 0

    bind(RunService.Heartbeat, function(dt)
        if not alive then
            return
        end
        frames = frames + 1
        fastTimer = fastTimer + dt
        midTimer = midTimer + dt
        slowTimer = slowTimer + dt

        if fastTimer >= 0.1 then
            fastTimer = 0
            if antiRagdollOn then
                pcall(runAntiRagdoll)
            end
            if antiBarrierOn then
                pcall(runAntiBarrier)
            end
        end

        if midTimer >= 0.5 then
            fps = math.floor(frames / midTimer + 0.5)
            frames = 0
            midTimer = 0
            pcall(updateLiveStats)
            local ok, rev = pcall(updateRevenant)
            pcall(updateRevEsp, ok and rev or nil)
        end

        if slowTimer >= 1 then
            slowTimer = 0
            cleanEsp()
            pcall(scanScraps)
            pcall(scanSeerOrbs)
            pcall(updatePlayerEsp)

            local shed = Workspace:FindFirstChild("Shed")
            if shed and not shedExisted then
                shedExisted = true
                addWorldLog("The Shed has spawned!", Color3.fromRGB(150, 0, 255))
            elseif not shed and shedExisted then
                shedExisted = false
                addWorldLog("The Shed despawned.", Color3.fromRGB(150, 150, 150))
            end

            if fastRepairOn then
                pcall(setFastRepair, true)
            end

            if autoFarmOn then
                local target = closestIn(filteredScraps())
                if target then
                    teleportPos(positionOf(target))
                end
            end
        end
    end)

    task.spawn(function()
        while alive do
            task.wait(clickDelay)
            if autoClickOn and LocalPlayer.Character then
                local cam = Workspace.CurrentCamera
                if cam then
                    local middle = cam.ViewportSize / 2
                    pcall(function()
                        VirtualUser:Button1Down(middle, cam.CFrame)
                        task.wait(0.01)
                        VirtualUser:Button1Up(middle, cam.CFrame)
                    end)
                    local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                    if tool and tool.Parent == LocalPlayer.Character then
                        pcall(function()
                            tool:Activate()
                        end)
                    end
                end
            end
        end
    end)

    task.spawn(function()
        while alive do
            task.wait(0.15)
            if autoInteractOn then
                for prompt in pairs(shownPrompts) do
                    if prompt.Parent and prompt.Enabled then
                        pcall(function()
                            prompt.HoldDuration = 0
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            else
                                prompt:InputHoldBegin()
                                task.wait()
                                prompt:InputHoldEnd()
                            end
                        end)
                    else
                        shownPrompts[prompt] = nil
                    end
                end
            end
        end
    end)

    bind(LocalPlayer.CharacterRemoving, function()
        if autoFarmOn then
            autoFarmOn = false
            pcall(function()
                Fluent.Options.AutoFarm:SetValue(false)
            end)
        end
    end)

    ------------------------------------------------------------------
    -- finish
    ------------------------------------------------------------------

    pcall(function()
        Window:SelectTab(1)
    end)

    if SaveManager and canFile then
        pcall(function()
            SaveManager:LoadAutoloadConfig()
        end)
    end

    ready = true
    updateLogs()
    addWorldLog("HUD loaded and monitoring.", Color3.fromRGB(0, 150, 255))
    notify("TRS Panel", "System initialized. Press LeftControl to hide or show.")
    log("panel ready")
end

launch(savedLang)
