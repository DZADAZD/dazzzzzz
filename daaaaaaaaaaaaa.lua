--[[
    ZYROSCRIPT v3.1 — Anime Dice Trade Freeze (EXECUTOR-READY)
    • RightShift = ouvrir/fermer
    • Capture args via __namecall (pas de hookfunction)
    • UI Glassmorphism + Dump Remotes
    • Copie-colle DIRECT dans ton exécuteur (pas de loadstring GitHub)
]]--

-- ============================================================
-- POLYFILLS & UTILS
-- ============================================================
local function str_trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function serialize(t)
    if type(t) ~= "table" then return tostring(t) end
    local out = {}
    for i, v in ipairs(t) do
        if type(v) == "table" then out[i] = "<table>"
        elseif typeof(v) == "Instance" then out[i] = v:GetFullName()
        else out[i] = tostring(v) end
    end
    return "{ " .. table.concat(out, ", ") .. " }"
end

local function log(msg)
    print("[" .. os.date("%H:%M:%S") .. "] ZYRO :: " .. msg)
end

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- CONFIG (noms probables Anime Dice — ajustables via bouton Dump)
-- ============================================================
local CONFIG = {
    acceptRemote   = "TradeAccept",      -- RemoteEvent/Function acceptation
    addRemote      = "TradeAddItem",     -- RemoteEvent ajout item
    setListRemote  = "TradeUpdate",      -- RemoteEvent maj liste (freeze)

    -- "AUTO" = réutilise les vrais args capturés
    acceptArgs   = "AUTO",
    addArgs      = "AUTO",
    setListArgs  = "AUTO",

    freezeInterval = 0.35,
}

-- ============================================================
-- CAPTURE UNIVERSELLE VIA __NAMECALL (marche partout)
-- ============================================================
local allRemotes = {}
local capturedArgs = {}   -- [remoteName] = {args...} (dernier appel sortant)
local incomingArgs = {}   -- [remoteName] = {args...} (dernier appel entrant)

local function scanRemotes()
    allRemotes = {}
    local function add(obj)
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            table.insert(allRemotes, obj)
            -- Hook entrant
            if obj:IsA("RemoteEvent") then
                pcall(function()
                    obj.OnClientEvent:Connect(function(...)
                        incomingArgs[obj.Name] = {...}
                    end)
                end)
            end
        end
    end
    pcall(function() for _, o in ipairs(ReplicatedStorage:GetDescendants()) do add(o) end end)
    pcall(function() for _, o in ipairs(workspace:GetDescendants()) do add(o) end end)
end

local function getRemote(name)
    for _, r in ipairs(allRemotes) do
        if r.Name == name then return r end
    end
    return nil
end

-- --- Hook __namecall (capture FireServer / InvokeServer) ---
local hookActive = false
local function enableNamecallHook()
    if hookActive then return end
    local mt = getrawmetatable(game)
    if not mt then log("⚠️ getrawmetatable non dispo — capture désactivée"); return end
    local oldNamecall = mt.__namecall
    local setreadonly = make_writeable or setreadonly
    if not setreadonly then log("⚠️ make_writeable/setreadonly non dispo — capture désactivée"); return end

    local success = pcall(function()
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                capturedArgs[self.Name] = args
                log("📥 Capturé '" .. self.Name .. "' (" .. method .. ") : " .. serialize(args))
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        hookActive = true
        log("✅ Hook __namecall activé — fais tes actions manuelles dans le trade")
    end)
    if not success then
        log("❌ Échec hook __namecall (exécuteur protégé) — fallback : args manuels dans CONFIG")
    end
end

-- ============================================================
-- ACTIONS
-- ============================================================
local targetPlayer = nil
local freezeRunning = false

local function getArgs(key)
    local v = CONFIG[key]
    if v == "AUTO" then
        local name = key == "acceptArgs" and CONFIG.acceptRemote
                   or key == "addArgs"    and CONFIG.addRemote
                   or key == "setListArgs" and CONFIG.setListRemote
        return capturedArgs[name] or incomingArgs[name] or {}
    end
    return v
end

local function setFreeze(on)
    freezeRunning = on
    if not on then return end
    local r = getRemote(CONFIG.setListRemote)
    if not r then log("❌ Freeze : remote '" .. CONFIG.setListRemote .. "' introuvable → clique 🔍 Dump"); return end
    local args = getArgs("setListArgs")
    if #args == 0 then log("⚠️ Freeze : args AUTO vides — fais 1 ajout manuel dans le trade pour capturer"); end
    log("❄️ Freeze ON — re-fire '" .. r.Name .. "' toutes les " .. CONFIG.freezeInterval .. "s")
    task.spawn(function()
        local last = 0
        while freezeRunning do
            local now = os.clock()
            if now - last >= CONFIG.freezeInterval then
                last = now
                if r:IsA("RemoteEvent") then
                    pcall(function() r:FireServer(unpack(args)) end)
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

local function setForceAccept(on)
    if not on then return end
    local r = getRemote(CONFIG.acceptRemote)
    if not r then log("❌ Force Accept : remote '" .. CONFIG.acceptRemote .. "' introuvable → clique 🔍 Dump"); return end
    local args = getArgs("acceptArgs")
    if #args == 0 then log("⚠️ Force Accept : args AUTO vides — fais 1 accept manuel pour capturer"); end
    log("✅ Force Accept → fire '" .. r.Name .. "' : " .. serialize(args))
    if r:IsA("RemoteEvent") then pcall(function() r:FireServer(unpack(args)) end)
    else pcall(function() r:InvokeServer(unpack(args)) end) end
end

local function setAutoAdd(on)
    if not on then return end
    local r = getRemote(CONFIG.addRemote)
    if not r then log("❌ Auto Add : remote '" .. CONFIG.addRemote .. "' introuvable → clique 🔍 Dump"); return end
    local args = getArgs("addArgs")
    if #args == 0 then log("⚠️ Auto Add : args AUTO vides — fais 1 ajout manuel pour capturer"); end
    log("📦 Auto Add → fire '" .. r.Name .. "' : " .. serialize(args))
    if r:IsA("RemoteEvent") then pcall(function() r:FireServer(unpack(args)) end) end
end

local function resolveTarget(text)
    text = str_trim(text or "")
    if text == "" then return nil end
    if tonumber(text) then return Players:GetPlayerFromUserId(tonumber(text)) end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == text:lower() then return p end
    end
    return nil
end

local function dumpRemotes()
    scanRemotes()
    log("🔍 === DUMP (" .. #allRemotes .. " remotes) — cherche trade/accept/add ===")
    for _, r in ipairs(allRemotes) do
        log(string.format("  %-4s  %s", (r:IsA("RemoteFunction") and "RF" or "RE"), r:GetFullName()))
    end
    log("🔍 === FIN — copie les noms dans le CONFIG en haut du script ===")
end

-- ============================================================
-- UI HELPERS
-- ============================================================
local C = {
    BG = Color3.fromRGB(10,14,26), CARD = Color3.fromRGB(18,24,42),
    CARD_HOVER = Color3.fromRGB(24,32,56), BORDER = Color3.fromRGB(40,55,90),
    ACCENT = Color3.fromRGB(77,159,255), ACCENT_DIM = Color3.fromRGB(50,110,200),
    TEXT = Color3.fromRGB(255,255,255), TEXT_SEC = Color3.fromRGB(107,122,153),
    TEXT_DIM = Color3.fromRGB(70,82,110), GLOW = Color3.fromRGB(77,159,255),
    SUCCESS = Color3.fromRGB(80,255,140), DANGER = Color3.fromRGB(255,90,90),
    INPUT_BG = Color3.fromRGB(14,18,34), TOGGLE_OFF = Color3.fromRGB(40,50,80),
    TOGGLE_ON = Color3.fromRGB(77,159,255),
    HEADER_TOP = Color3.fromRGB(30,45,90), HEADER_BOT = Color3.fromRGB(18,24,50),
}

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c end
local function grad(p, t, b, rot) local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,t),ColorSequenceKeypoint.new(1,b)}); if rot then g.Rotation = rot end; g.Parent = p; return g end
local function stroke(p, col, th) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th or 1; s.Parent = p; return s end
local function lbl(p, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.Font = props.font or Enum.Font.Gotham
    l.TextSize = props.size or 14; l.TextColor3 = props.color or C.TEXT
    l.Text = props.text or ""; l.TextXAlignment = props.xalign or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Size = props.size2d or UDim2.new(1,0,1,0); l.Position = props.pos or UDim2.new(0,0,0,0)
    l.Parent = p; return l
end

local function createToggle(parent, name, icon, order, callback)
    local row = Instance.new("Frame")
    row.Name = "T_"..name; row.Size = UDim2.new(1,0,0,44); row.BackgroundColor3 = C.CARD; row.BorderSizePixel = 0; row.LayoutOrder = order; row.Parent = parent
    corner(row, 10); stroke(row, C.BORDER, 1)
    row.MouseEnter:Connect(function() TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3=C.CARD_HOVER}):Play() end)
    row.MouseLeave:Connect(function() TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3=C.CARD}):Play() end)

    lbl(row, {text=icon, size=18, pos=UDim2.new(0,14,0,0), size2d=UDim2.new(0,28,1,0), xalign=Enum.TextXAlignment.Center})
    lbl(row, {text=name, size=14, color=C.TEXT, font=Enum.Font.GothamMedium, pos=UDim2.new(0,48,0,0), size2d=UDim2.new(1,-160,1,0)})

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency=1; status.Text="OFF"; status.TextColor3=C.TEXT_DIM; status.Font=Enum.Font.GothamBold; status.TextSize=11
    status.TextXAlignment=Enum.TextXAlignment.Right; status.Size=UDim2.new(0,36,1,0); status.Position=UDim2.new(1,-110,0,0); status.Parent=row

    local track = Instance.new("Frame")
    track.Size=UDim2.fromOffset(48,26); track.Position=UDim2.new(1,-66,0.5,0); track.AnchorPoint=Vector2.new(0,0.5)
    track.BackgroundColor3=C.TOGGLE_OFF; track.BorderSizePixel=0; track.Parent=row; corner(track,13)

    local tGlow = Instance.new("Frame")
    tGlow.Size=UDim2.fromOffset(56,34); tGlow.Position=UDim2.new(0,-4,0,-4); tGlow.BackgroundColor3=C.GLOW; tGlow.BackgroundTransparency=1; tGlow.BorderSizePixel=0; tGlow.ZIndex=-1; tGlow.Parent=track; corner(tGlow,17)

    local knob = Instance.new("Frame")
    knob.Size=UDim2.fromOffset(20,20); knob.Position=UDim2.new(0,3,0.5,0); knob.AnchorPoint=Vector2.new(0,0.5)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0; knob.Parent=track; corner(knob,10)

    local enabled = false
    local function set(val)
        enabled = val
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quartic, Enum.EasingDirection.Out), {Position=val and UDim2.new(1,-23,0.5,0) or UDim2.new(0,3,0.5,0)}):Play()
        TweenService:Create(track, TweenInfo.new(0.2), {BackgroundColor3=val and C.TOGGLE_ON or C.TOGGLE_OFF}):Play()
        TweenService:Create(tGlow, TweenInfo.new(0.3), {BackgroundTransparency=val and 0.55 or 1}):Play()
        status.Text = val and "ON" or "OFF"; status.TextColor3 = val and C.SUCCESS or C.TEXT_DIM
        if callback then callback(val) end
    end
    row.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then set(not enabled) end end)
    return {row=row, isEnabled=function() return enabled end, setEnabled=set}
end

-- ============================================================
-- UI BUILD
-- ============================================================
local screenGui, mainFrame, headerGlow, frameGlow
local uiOpen = false
local OPEN_POS = UDim2.fromScale(0.65, 0.5)
local CLOSED_POS = UDim2.fromScale(1.05, 0.5)

local function animateOpen()
    uiOpen = true
    mainFrame.Position = CLOSED_POS
    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quartic, Enum.EasingDirection.Out), {Position=OPEN_POS}):Play()
    TweenService:Create(frameGlow, TweenInfo.new(0.4), {BackgroundTransparency=0.7}):Play()
    task.spawn(function()
        local t=0
        while uiOpen do t=t+0.02; headerGlow.BackgroundTransparency=0.85+math.sin(t*3)*0.05; RunService.Heartbeat:Wait() end
    end)
end
local function animateClose()
    uiOpen = false
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quartic, Enum.EasingDirection.In), {Position=CLOSED_POS}):Play()
    TweenService:Create(frameGlow, TweenInfo.new(0.3), {BackgroundTransparency=0.9}):Play()
    task.wait(0.35); screenGui.Visible=false
end
local function toggleUI() if uiOpen then animateClose() else animateOpen() end end

local function createUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZYROScriptGUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayMode = Enum.DisplayMode.UIOnly
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.fromScale(0.34, 0.56)
    mainFrame.Position = CLOSED_POS
    mainFrame.AnchorPoint = Vector2.new(0, 0.5)
    mainFrame.BackgroundColor3 = C.BG
    mainFrame.BackgroundTransparency = 0.08
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    corner(mainFrame, 16); stroke(mainFrame, C.BORDER, 1.5)

    frameGlow = Instance.new("Frame")
    frameGlow.Size = UDim2.fromScale(1,1); frameGlow.Position = UDim2.new(0,-6,0,-6)
    frameGlow.BackgroundColor3 = C.GLOW; frameGlow.BackgroundTransparency = 0.8; frameGlow.BorderSizePixel = 0; frameGlow.ZIndex = -1
    frameGlow.Parent = mainFrame; corner(frameGlow, 20)
    grad(mainFrame, Color3.fromRGB(14,18,34), Color3.fromRGB(8,12,24), 90)

    local mainList = Instance.new("UIListLayout")
    mainList.Padding = UDim.new(0,10); mainList.SortOrder = Enum.SortOrder.LayoutOrder
    mainList.HorizontalAlignment = Enum.HorizontalAlignment.Center; mainList.VerticalAlignment = Enum.VerticalAlignment.Top
    mainList.Parent = mainFrame

    local mainPad = Instance.new("UIPadding")
    mainPad.PaddingTop = UDim.new(0,0); mainPad.PaddingBottom = UDim.new(0,16)
    mainPad.PaddingLeft = UDim.new(0,16); mainPad.PaddingRight = UDim.new(0,16)
    mainPad.Parent = mainFrame

    -- HEADER
    local header = Instance.new("Frame")
    header.Name="Header"; header.Size=UDim2.new(1,0,0,56); header.BackgroundColor3=C.HEADER_TOP; header.BorderSizePixel=0; header.LayoutOrder=1; header.Parent=mainFrame
    corner(header,12); grad(header, C.HEADER_TOP, C.HEADER_BOT, 90); stroke(header, C.BORDER, 1)

    headerGlow = Instance.new("Frame")
    headerGlow.Size=UDim2.fromScale(1,1); headerGlow.Position=UDim2.new(0,-3,0,-3)
    headerGlow.BackgroundColor3=C.GLOW; headerGlow.BackgroundTransparency=0.85; headerGlow.BorderSizePixel=0; headerGlow.ZIndex=-1
    headerGlow.Parent=header; corner(headerGlow,15)

    lbl(header, {text="🎲", size=26, pos=UDim2.new(0,14,0,0), size2d=UDim2.new(0,36,1,0), xalign=Enum.TextXAlignment.Center})
    lbl(header, {text="ZYROSCRIPT", size=18, color=C.TEXT, font=Enum.Font.GothamBold, pos=UDim2.new(0,52,0,0), size2d=UDim2.new(1,-120,0.5,0)})
    lbl(header, {text="Anime Dice Trade Freeze", size=11, color=C.TEXT_SEC, pos=UDim2.new(0,52,0.5,0), size2d=UDim2.new(1,-120,0.5,0)})

    local vBadge = Instance.new("Frame")
    vBadge.Size=UDim2.fromOffset(42,20); vBadge.Position=UDim2.new(1,-56,0.5,0); vBadge.AnchorPoint=Vector2.new(0,0.5)
    vBadge.BackgroundColor3=C.ACCENT_DIM; vBadge.BackgroundTransparency=0.3; vBadge.BorderSizePixel=0; vBadge.Parent=header; corner(vBadge,10)
    lbl(vBadge, {text="v3.1", size=10, color=C.TEXT, font=Enum.Font.GothamBold, size2d=UDim2.fromScale(1,1), xalign=Enum.TextXAlignment.Center})

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size=UDim2.fromOffset(28,28); closeBtn.Position=UDim2.new(1,-34,0.5,0); closeBtn.AnchorPoint=Vector2.new(0,0.5)
    closeBtn.BackgroundColor3=Color3.fromRGB(30,40,70); closeBtn.Text="✕"; closeBtn.TextColor3=C.TEXT_SEC; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=14; closeBtn.BorderSizePixel=0; closeBtn.Parent=header; corner(closeBtn,8)
    closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(80,40,40), TextColor3=C.DANGER}):Play() end)
    closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(30,40,70), TextColor3=C.TEXT_SEC}):Play() end)
    closeBtn.MouseButton1Click:Connect(toggleUI)

    -- TARGET
    local targetSec = Instance.new("Frame")
    targetSec.Name="TargetSec"; targetSec.Size=UDim2.new(1,0,0,100); targetSec.BackgroundTransparency=1; targetSec.LayoutOrder=2; targetSec.Parent=mainFrame
    lbl(targetSec, {text="⚡  TARGET PLAYER", size=12, color=C.ACCENT, font=Enum.Font.GothamBold, size2d=UDim2.new(1,0,0,16)})

    local inputRow = Instance.new("Frame")
    inputRow.Size=UDim2.new(1,0,0,40); inputRow.Position=UDim2.new(0,0,0,24); inputRow.BackgroundTransparency=1; inputRow.Parent=targetSec

    local searchBox = Instance.new("TextBox")
    searchBox.Size=UDim2.new(1,-100,1,0); searchBox.BackgroundColor3=C.INPUT_BG; searchBox.BackgroundTransparency=0.1
    searchBox.PlaceholderText="Nom ou UserId du joueur…"; searchBox.PlaceholderColor3=C.TEXT_DIM; searchBox.TextColor3=C.TEXT
    searchBox.Font=Enum.Font.Gotham; searchBox.TextSize=13; searchBox.BorderSizePixel=0; searchBox.ClearTextOnFocus=false; searchBox.Parent=inputRow
    corner(searchBox,8); local sStroke = stroke(searchBox, C.BORDER, 1)
    searchBox.FocusBegin:Connect(function() TweenService:Create(sStroke, TweenInfo.new(0.15), {Color=C.ACCENT}):Play() end)
    searchBox.FocusEnd:Connect(function() TweenService:Create(sStroke, TweenInfo.new(0.15), {Color=C.BORDER}):Play() end)

    local searchBtn = Instance.new("TextButton")
    searchBtn.Size=UDim2.new(0,88,1,0); searchBtn.Position=UDim2.new(1,-88,0,0)
    searchBtn.BackgroundColor3=C.ACCENT; searchBtn.Text="Search"; searchBtn.TextColor3=Color3.fromRGB(255,255,255); searchBtn.Font=Enum.Font.GothamBold; searchBtn.TextSize=13; searchBtn.BorderSizePixel=0; searchBtn.Parent=inputRow; corner(searchBtn,8)
    searchBtn.MouseEnter:Connect(function() TweenService:Create(searchBtn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(100,180,255)}):Play() end)
    searchBtn.MouseLeave:Connect(function() TweenService:Create(searchBtn, TweenInfo.new(0.1), {BackgroundColor3=C.ACCENT}):Play() end)

    local targetStatus = Instance.new("TextLabel")
    targetStatus.BackgroundTransparency=1; targetStatus.Text="En attente de cible…"; targetStatus.TextColor3=C.TEXT_DIM; targetStatus.Font=Enum.Font.Gotham; targetStatus.TextSize=11
    targetStatus.Size=UDim2.new(1,0,0,14); targetStatus.Position=UDim2.new(0,0,1,-18); targetStatus.TextXAlignment=Enum.TextXAlignment.Left; targetStatus.Parent=targetSec

    -- OPTIONS
    local optSec = Instance.new("Frame")
    optSec.Name="OptSec"; optSec.Size=UDim2.new(1,0,0,190); optSec.BackgroundTransparency=1; optSec.LayoutOrder=3; optSec.Parent=mainFrame
    lbl(optSec, {text="⚙️  OPTIONS", size=12, color=C.ACCENT, font=Enum.Font.GothamBold, size2d=UDim2.new(1,0,0,16)})

    local togglesCont = Instance.new("Frame")
    togglesCont.Size=UDim2.new(1,0,0,160); togglesCont.Position=UDim2.new(0,0,0,24); togglesCont.BackgroundTransparency=1; togglesCont.Parent=optSec
    local tList = Instance.new("UIListLayout"); tList.Padding=UDim.new(0,6); tList.SortOrder=Enum.SortOrder.LayoutOrder; tList.Parent=togglesCont

    local tFreeze = createToggle(togglesCont, "Freeze Trade", "❄️", 1, setFreeze)
    local tForce  = createToggle(togglesCont, "Force Accept", "✅", 2, setForceAccept)
    local tAuto   = createToggle(togglesCont, "Auto Add All", "📦", 3, setAutoAdd)

    -- FOOTER
    local footer = Instance.new("Frame")
    footer.Name="Footer"; footer.Size=UDim2.new(1,0,0,32); footer.BackgroundTransparency=1; footer.LayoutOrder=4; footer.Parent=mainFrame

    lbl(footer, {text="🔑  RightShift = ouvrir / fermer", size=10, color=C.TEXT_DIM, font=Enum.Font.Gotham, size2d=UDim2.new(1,-130,1,0), xalign=Enum.TextXAlignment.Left})

    local dumpBtn = Instance.new("TextButton")
    dumpBtn.Size=UDim2.new(0,110,0,24); dumpBtn.Position=UDim2.new(1,-110,0.5,0); dumpBtn.AnchorPoint=Vector2.new(0,0.5)
    dumpBtn.BackgroundColor3=C.CARD; dumpBtn.Text="🔍 Dump Remotes"; dumpBtn.TextColor3=C.ACCENT; dumpBtn.Font=Enum.Font.GothamBold; dumpBtn.TextSize=11; dumpBtn.BorderSizePixel=0; dumpBtn.Parent=footer
    corner(dumpBtn,8); stroke(dumpBtn, C.BORDER, 1)
    dumpBtn.MouseEnter:Connect(function() TweenService:Create(dumpBtn, TweenInfo.new(0.1), {BackgroundColor3=C.CARD_HOVER}):Play() end)
    dumpBtn.MouseLeave:Connect(function() TweenService:Create(dumpBtn, TweenInfo.new(0.1), {BackgroundColor3=C.CARD}):Play() end)
    dumpBtn.MouseButton1Click:Connect(dumpRemotes)

    -- KEYBIND
    UserInputService.InputBegan:Connect(function(inp, gp) if not gp and inp.KeyCode==Enum.KeyCode.RightShift then toggleUI() end end)

    -- SEARCH
    searchBtn.MouseButton1Click:Connect(function()
        local found = resolveTarget(searchBox.Text)
        if found then
            targetPlayer = found; searchBox.Text = found.Name
            targetStatus.Text = "✅  Cible : " .. found.Name; targetStatus.TextColor3 = C.SUCCESS
            if tForce.isEnabled() then setForceAccept(true) end
            if tAuto.isEnabled() then setAutoAdd(true) end
        else
            targetStatus.Text = "❌  Joueur non trouvé"; targetStatus.TextColor3 = C.DANGER
        end
    end)

    task.wait(0.1); animateOpen()
    return {toggles={["Freeze Trade"]=tFreeze, ["Force Accept"]=tForce, ["Auto Add All"]=tAuto}}
end

-- ============================================================
-- START
-- ============================================================
local ui = createUI()
scanRemotes()
enableNamecallHook()  -- <-- LE HOOK QUI FAIT TOUT MARCHER

log("✅ ZYROSCRIPT v3.1 prêt — RightShift pour ouvrir")
log("💡 Ouvre un trade, fais 1 ajout + 1 accept MANUEL → les args apparaissent en console")
log("💡 Puis clique 🔍 Dump Remotes, mets les noms dans CONFIG (en haut), et active les toggles")
