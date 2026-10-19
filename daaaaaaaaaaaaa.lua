--[[
    ZYROSCRIPT v2.0 — Anime Dice Trade Freeze
    UI Premium • Glassmorphism • Glow Effects
    Keybind : RightShift pour ouvrir/fermer
]]--

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- PALETTE
-- ============================================================
local C = {
    BG          = Color3.fromRGB(10, 14, 26),
    CARD        = Color3.fromRGB(18, 24, 42),
    CARD_HOVER  = Color3.fromRGB(24, 32, 56),
    BORDER      = Color3.fromRGB(40, 55, 90),
    ACCENT      = Color3.fromRGB(77, 159, 255),
    ACCENT_DIM  = Color3.fromRGB(50, 110, 200),
    TEXT        = Color3.fromRGB(255, 255, 255),
    TEXT_SEC    = Color3.fromRGB(107, 122, 153),
    TEXT_DIM    = Color3.fromRGB(70, 82, 110),
    GLOW        = Color3.fromRGB(77, 159, 255),
    GLOW_DIM    = Color3.fromRGB(40, 90, 180),
    SUCCESS     = Color3.fromRGB(80, 255, 140),
    DANGER      = Color3.fromRGB(255, 90, 90),
    INPUT_BG    = Color3.fromRGB(14, 18, 34),
    TOGGLE_OFF  = Color3.fromRGB(40, 50, 80),
    TOGGLE_ON   = Color3.fromRGB(77, 159, 255),
    HEADER_GRAD_TOP = Color3.fromRGB(30, 45, 90),
    HEADER_GRAD_BOT = Color3.fromRGB(18, 24, 50),
}

-- ============================================================
-- VARIABLES
-- ============================================================
local uiOpen = false
local targetPlayer = nil
local tradeRemotes = {}
local screenGui = nil
local mainFrame = nil
local headerGlow = nil

local function setFreeze(on)
    if on then
        for _, r in ipairs(tradeRemotes) do
            local n = r.Name:lower()
            if (n:find("add") or n:find("remove") or n:find("swap")) and r:IsA("RemoteEvent") then
                pcall(function()
                    r.OnClientEvent:Connect(function() end)
                end)
            end
        end
    end
end

local function setForceAccept(on)
    if on and targetPlayer then
        for _, r in ipairs(tradeRemotes) do
            local n = r.Name:lower()
            if n:find("accept") then
                if r:IsA("RemoteEvent") then
                    pcall(function() r:FireServer(targetPlayer.UserId, true) end)
                elseif r:IsA("RemoteFunction") then
                    pcall(function() r:InvokeServer(targetPlayer.UserId, true) end)
                end
            end
        end
    end
end

local function setAutoAdd(on)
    if on then
        for _, r in ipairs(tradeRemotes) do
            local n = r.Name:lower()
            if n:find("add") and r:IsA("RemoteEvent") then
                pcall(function() r:FireServer("all") end)
            end
        end
    end
end

local function findTradeRemotes()
    tradeRemotes = {}
    local function scan(container)
        for _, obj in ipairs(container:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                local n = obj.Name:lower()
                if n:find("trade") or n:find("accept") or n:find("swap") or n:find("exchange") then
                    table.insert(tradeRemotes, obj)
                end
            end
        end
    end
    pcall(function() scan(ReplicatedStorage) end)
    pcall(function() scan(workspace) end)
end

local function resolveTarget(text)
    text = (text or ""):trim()
    if text == "" then return nil end
    if tonumber(text) then
        return Players:GetPlayerFromUserId(tonumber(text))
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == text:lower() then
            return p
        end
    end
    return nil
end

-- ============================================================
-- HELPERS UI
-- ============================================================
local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makeGradient(parent, top, bottom, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, top),
        ColorSequenceKeypoint.new(1, bottom),
    })
    if rotation then g.Rotation = rotation end
    g.Parent = parent
    return g
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UguiStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.LineTransparency = 0
    s.Parent = parent
    return s
end

local function makeGlow(parent, color, size)
    local g = Instance.new("Frame")
    g.Name = "Glow"
    g.Size = UDim2.fromScale(1, 1)
    g.Position = UDim2.new(0, -(size or 4), 0, -(size or 4))
    g.BackgroundColor3 = color
    g.BackgroundTransparency = 0.65
    g.BorderSizePixel = 0
    g.ZIndex = -1
    g.Parent = parent
    makeCorner(g, 14)
    return g
end

local function makeLabel(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = props.font or Enum.Font.Gotham
    l.TextSize = props.size or 14
    l.TextColor3 = props.color or C.TEXT
    l.Text = props.text or ""
    l.TextXAlignment = props.xalign or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Size = props.size2d or UDim2.new(1, 0, 1, 0)
    l.Position = props.pos or UDim2.new(0, 0, 0, 0)
    l.Parent = parent
    return l
end

-- ============================================================
-- CREATE TOGGLE SWITCH (premium)
-- ============================================================
local function createToggle(parent, name, icon, order, onToggle)
    local row = Instance.new("Frame")
    row.Name = "Toggle_" .. name
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = C.CARD
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    makeCorner(row, 10)
    makeStroke(row, C.BORDER, 1)

    -- hover effect
    local hoverConn = row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = C.CARD_HOVER }):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = C.CARD }):Play()
    end)

    -- icon
    makeLabel(row, {
        text = icon,
        size = 18,
        pos = UDim2.new(0, 14, 0, 0),
        size2d = UDim2.new(0, 28, 1, 0),
        xalign = Enum.TextXAlignment.Center,
    })

    -- name
    makeLabel(row, {
        text = name,
        size = 14,
        color = C.TEXT,
        font = Enum.Font.GothamMedium,
        pos = UDim2.new(0, 48, 0, 0),
        size2d = UDim2.new(1, -160, 1, 0),
    })

    -- status text
    local statusLabel = Instance.new("TextLabel")
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "OFF"
    statusLabel.TextColor3 = C.TEXT_DIM
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Size = UDim2.new(0, 36, 1, 0)
    statusLabel.Position = UDim2.new(1, -110, 0, 0)
    statusLabel.Parent = row

    -- toggle track
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(48, 26)
    track.Position = UDim2.new(1, -66, 0.5, 0)
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.BackgroundColor3 = C.TOGGLE_OFF
    track.BorderSizePixel = 0
    track.Parent = row
    makeCorner(track, 13)

    -- glow behind track
    local trackGlow = Instance.new("Frame")
    trackGlow.Size = UDim2.fromOffset(56, 34)
    trackGlow.Position = UDim2.new(0, -4, 0, -4)
    trackGlow.BackgroundColor3 = C.GLOW
    trackGlow.BackgroundTransparency = 1
    trackGlow.BorderSizePixel = 0
    trackGlow.ZIndex = -1
    trackGlow.Parent = track
    makeCorner(trackGlow, 17)

    -- knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(20, 20)
    knob.Position = UDim2.new(0, 3, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    makeCorner(knob, 10)

    local enabled = false

    local function setEnabled(val)
        enabled = val
        local knobPos = val and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quartic, Enum.EasingDirection.Out), {
            Position = knobPos,
        }):Play()
        TweenService:Create(track, TweenInfo.new(0.2), {
            BackgroundColor3 = val and C.TOGGLE_ON or C.TOGGLE_OFF,
        }):Play()
        TweenService:Create(trackGlow, TweenInfo.new(0.3), {
            BackgroundTransparency = val and 0.55 or 1,
        }):Play()
        statusLabel.Text = val and "ON" or "OFF"
        statusLabel.TextColor3 = val and C.SUCCESS or C.TEXT_DIM
        if val then
            TweenService:Create(statusLabel, TweenInfo.new(0.15), { TextColor3 = C.SUCCESS }):Play()
        end
        if onToggle then onToggle(val) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            setEnabled(not enabled)
        end
    end)

    -- aussi cliquable sur toute la row
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            setEnabled(not enabled)
        end
    end)

    return {
        row = row,
        isEnabled = function() return enabled end,
        setEnabled = setEnabled,
    }
end

-- ============================================================
-- CREATE PREMIUM UI
-- ============================================================
local function createUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZYROScriptGUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayMode = Enum.DisplayMode.UIOnly
    screenGui.ResetOnInsert = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- === MAIN FRAME (glassmorphism card) ===
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.fromScale(0.34, 0.52)
    mainFrame.Position = UDim2.fromScale(0.65, 0.5)
    mainFrame.AnchorPoint = Vector2.new(0, 0.5)
    mainFrame.BackgroundColor3 = C.BG
    mainFrame.BackgroundTransparency = 0.08
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    makeCorner(mainFrame, 16)
    makeStroke(mainFrame, C.BORDER, 1.5)

    -- glow derrière le frame
    local frameGlow = Instance.new("Frame")
    frameGlow.Size = UDim2.fromScale(1, 1)
    frameGlow.Position = UDim2.new(0, -6, 0, -6)
    frameGlow.BackgroundColor3 = C.GLOW
    frameGlow.BackgroundTransparency = 0.8
    frameGlow.BorderSizePixel = 0
    frameGlow.ZIndex = -1
    frameGlow.Parent = mainFrame
    makeCorner(frameGlow, 20)

    -- dégradé subtil sur le fond
    makeGradient(mainFrame, Color3.fromRGB(14, 18, 34), Color3.fromRGB(8, 12, 24), 90)

    -- === LAYOUT PRINCIPAL ===
    local mainList = Instance.new("UIListLayout")
    mainList.Padding = UDim.new(0, 10)
    mainList.SortOrder = Enum.SortOrder.LayoutOrder
    mainList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainList.VerticalAlignment = Enum.VerticalAlignment.Top
    mainList.Parent = mainFrame

    local mainPad = Instance.new("UIPadding")
    mainPad.PaddingTop = UDim.new(0, 0)
    mainPad.PaddingBottom = UDim.new(0, 16)
    mainPad.PaddingLeft = UDim.new(0, 16)
    mainPad.PaddingRight = UDim.new(0, 16)
    mainPad.Parent = mainFrame

    -- ============================================================
    -- HEADER
    -- ============================================================
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 56)
    header.BackgroundColor3 = C.HEADER_GRAD_TOP
    header.BorderSizePixel = 0
    header.LayoutOrder = 1
    header.Parent = mainFrame
    makeCorner(header, 12)
    makeGradient(header, C.HEADER_GRAD_TOP, C.HEADER_GRAD_BOT, 90)
    makeStroke(header, C.BORDER, 1)

    -- glow header (pulse)
    headerGlow = Instance.new("Frame")
    headerGlow.Size = UDim2.fromScale(1, 1)
    headerGlow.Position = UDim2.new(0, -3, 0, -3)
    headerGlow.BackgroundColor3 = C.GLOW
    headerGlow.BackgroundTransparency = 0.85
    headerGlow.BorderSizePixel = 0
    headerGlow.ZIndex = -1
    headerGlow.Parent = header
    makeCorner(headerGlow, 15)

    -- logo
    local logo = Instance.new("TextLabel")
    logo.BackgroundTransparency = 1
    logo.Text = "🎲"
    logo.TextSize = 26
    logo.Size = UDim2.new(0, 36, 1, 0)
    logo.Position = UDim2.new(0, 14, 0, 0)
    logo.TextXAlignment = Enum.TextXAlignment.Center
    logo.TextYAlignment = Enum.TextYAlignment.Center
    logo.Parent = header

    -- titre
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Text = "ZYROSCRIPT"
    title.TextColor3 = C.TEXT
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 52, 0, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Parent = header

    -- sous-titre
    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Anime Dice Trade Freeze"
    subtitle.TextColor3 = C.TEXT_SEC
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.Size = UDim2.new(1, -120, 0, 14)
    subtitle.Position = UDim2.new(0, 52, 1, -16)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    -- version badge
    local versionBadge = Instance.new("Frame")
    versionBadge.Size = UDim2.fromOffset(42, 20)
    versionBadge.Position = UDim2.new(1, -56, 0.5, 0)
    versionBadge.AnchorPoint = Vector2.new(0, 0.5)
    versionBadge.BackgroundColor3 = C.ACCENT_DIM
    versionBadge.BackgroundTransparency = 0.3
    versionBadge.BorderSizePixel = 0
    versionBadge.Parent = header
    makeCorner(versionBadge, 10)

    local versionLabel = Instance.new("TextLabel")
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "v2.0"
    versionLabel.TextColor3 = C.TEXT
    versionLabel.Font = Enum.Font.GothamBold
    versionLabel.TextSize = 10
    versionLabel.Size = UDim2.fromScale(1, 1)
    versionLabel.TextXAlignment = Enum.TextXAlignment.Center
    versionLabel.TextYAlignment = Enum.TextYAlignment.Center
    versionLabel.Parent = versionBadge

    -- close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.new(1, -34, 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 70)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = C.TEXT_SEC
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    makeCorner(closeBtn, 8)

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(80, 40, 40),
            TextColor3 = C.DANGER,
        }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(30, 40, 70),
            TextColor3 = C.TEXT_SEC,
        }):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        toggleUI()
    end)

    -- ============================================================
    -- SECTION : TARGET
    -- ============================================================
    local targetSection = Instance.new("Frame")
    targetSection.Name = "TargetSection"
    targetSection.Size = UDim2.new(1, 0, 0, 100)
    targetSection.BackgroundTransparency = 1
    targetSection.LayoutOrder = 2
    targetSection.Parent = mainFrame

    -- section title
    makeLabel(targetSection, {
        text = "⚡  TARGET PLAYER",
        size = 12,
        color = C.ACCENT,
        font = Enum.Font.GothamBold,
        size2d = UDim2.new(1, 0, 0, 16),
    })

    -- search input row
    local inputRow = Instance.new("Frame")
    inputRow.Size = UDim2.new(1, 0, 0, 40)
    inputRow.Position = UDim2.new(0, 0, 0, 24)
    inputRow.BackgroundTransparency = 1
    inputRow.Parent = targetSection

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -100, 1, 0)
    searchBox.BackgroundColor3 = C.INPUT_BG
    searchBox.BackgroundTransparency = 0.1
    searchBox.PlaceholderText = "Nom ou UserId du joueur…"
    searchBox.PlaceholderColor3 = C.TEXT_DIM
    searchBox.TextColor3 = C.TEXT
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.BorderSizePixel = 0
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = inputRow
    makeCorner(searchBox, 8)
    makeStroke(searchBox, C.BORDER, 1)

    -- focus effect
    searchBox.FocusBegin:Connect(function()
        pcall(function()
            local stroke = searchBox:FindFirstChildOfClass("UguiStroke")
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(0.15), { Color = C.ACCENT }):Play()
            end
        end)
    end)
    searchBox.FocusEnd:Connect(function()
        pcall(function()
            local stroke = searchBox:FindFirstChildOfClass("UguiStroke")
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(0.15), { Color = C.BORDER }):Play()
            end
        end)
    end)

    local searchBtn = Instance.new("TextButton")
    searchBtn.Size = UDim2.new(0, 88, 1, 0)
    searchBtn.Position = UDim2.new(1, -88, 0, 0)
    searchBtn.BackgroundColor3 = C.ACCENT
    searchBtn.Text = "Search"
    searchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBtn.Font = Enum.Font.GothamBold
    searchBtn.TextSize = 13
    searchBtn.BorderSizePixel = 0
    searchBtn.Parent = inputRow
    makeCorner(searchBtn, 8)

    searchBtn.MouseEnter:Connect(function()
        TweenService:Create(searchBtn, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(100, 180, 255),
        }):Play()
    end)
    searchBtn.MouseLeave:Connect(function()
        TweenService:Create(searchBtn, TweenInfo.new(0.1), {
            BackgroundColor3 = C.ACCENT,
        }):Play()
    end)

    -- status line sous le search
    local targetStatus = Instance.new("TextLabel")
    targetStatus.BackgroundTransparency = 1
    targetStatus.Text = "En attente de cible…"
    targetStatus.TextColor3 = C.TEXT_DIM
    targetStatus.Font = Enum.Font.Gotham
    targetStatus.TextSize = 11
    targetStatus.Size = UDim2.new(1, 0, 0, 14)
    targetStatus.Position = UDim2.new(0, 0, 1, -18)
    targetStatus.TextXAlignment = Enum.TextXAlignment.Left
    targetStatus.Parent = targetSection

    searchBtn.MouseButton1Click:Connect(function()
        local found = resolveTarget(searchBox.Text)
        if found then
            targetPlayer = found
            searchBox.Text = found.Name
            targetStatus.Text = "✅  Cible : " .. found.Name
            targetStatus.TextColor3 = C.SUCCESS
            if ui.toggles and ui.toggles["Force Accept"] and ui.toggles["Force Accept"].isEnabled() then
                setForceAccept(true)
            end
            if ui.toggles and ui.toggles["Auto Add All"] and ui.toggles["Auto Add All"].isEnabled() then
                setAutoAdd(true)
            end
        else
            targetStatus.Text = "❌  Joueur non trouvé"
            targetStatus.TextColor3 = C.DANGER
        end
    end)

    -- ============================================================
    -- SECTION : OPTIONS
    -- ============================================================
    local optionsSection = Instance.new("Frame")
    optionsSection.Name = "OptionsSection"
    optionsSection.Size = UDim2.new(1, 0, 0, 190)
    optionsSection.BackgroundTransparency = 1
    optionsSection.LayoutOrder = 3
    optionsSection.Parent = mainFrame

    makeLabel(optionsSection, {
        text = "⚙️  OPTIONS",
        size = 12,
        color = C.ACCENT,
        font = Enum.Font.GothamBold,
        size2d = UDim2.new(1, 0, 0, 16),
    })

    local togglesContainer = Instance.new("Frame")
    togglesContainer.Size = UDim2.new(1, 0, 0, 160)
    togglesContainer.Position = UDim2.new(0, 0, 0, 24)
    togglesContainer.BackgroundTransparency = 1
    togglesContainer.Parent = optionsSection

    local toggleList = Instance.new("UIListLayout")
    toggleList.Padding = UDim.new(0, 6)
    toggleList.SortOrder = Enum.SortOrder.LayoutOrder
    toggleList.Parent = togglesContainer

    local toggleFreeze = createToggle(togglesContainer, "Freeze Trade", "❄️", 1, function(on)
        setFreeze(on)
    end)

    local toggleForce = createToggle(togglesContainer, "Force Accept", "✅", 2, function(on)
        setForceAccept(on)
    end)

    local toggleAuto = createToggle(togglesContainer, "Auto Add All", "📦", 3, function(on)
        setAutoAdd(on)
    end)

    -- ============================================================
    -- FOOTER
    -- ============================================================
    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 32)
    footer.BackgroundTransparency = 1
    footer.LayoutOrder = 4
    footer.Parent = mainFrame

    local keybindLabel = Instance.new("TextLabel")
    keybindLabel.BackgroundTransparency = 1
    keybindLabel.Text = "🔑  RightShift pour ouvrir / fermer"
    keybindLabel.TextColor3 = C.TEXT_DIM
    keybindLabel.Font = Enum.Font.Gotham
    keybindLabel.TextSize = 10
    keybindLabel.Size = UDim2.new(1, -80, 1, 0)
    keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
    keybindLabel.Parent = footer

    local onlineLabel = Instance.new("TextLabel")
    onlineLabel.BackgroundTransparency = 1
    onlineLabel.Text = "🟢  " .. #Players:GetPlayers() .. " en ligne"
    onlineLabel.TextColor3 = C.TEXT_DIM
    onlineLabel.Font = Enum.Font.Gotham
    onlineLabel.TextSize = 10
    onlineLabel.Size = UDim2.new(0, 90, 1, 0)
    onlineLabel.Position = UDim2.new(1, -90, 0, 0)
    onlineLabel.TextXAlignment = Enum.TextXAlignment.Right
    onlineLabel.Parent = footer

    -- ============================================================
    -- ANIMATION D'OUVERTURE / FERMETURE
    -- ============================================================
    local OPEN_POS  = UDim2.fromScale(0.65, 0.5)
    local CLOSED_POS = UDim2.fromScale(1.05, 0.5)

    mainFrame.Position = CLOSED_POS
    screenGui.Visible = true

    local function animateOpen()
        uiOpen = true
        mainFrame.Position = CLOSED_POS
        TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quartic, Enum.EasingDirection.Out), {
            Position = OPEN_POS,
        }):Play()
        TweenService:Create(frameGlow, TweenInfo.new(0.4), {
            BackgroundTransparency = 0.7,
        }):Play()
   

        -- pulse glow header
        task.spawn(function()
            local t = 0
            while uiOpen do
                t = t + 0.02
                local pulse = 0.85 + math.sin(t * 3) * 0.05
                headerGlow.BackgroundTransparency = pulse
                RunService.Heartbeat:Wait()
            end
        end)
    end

    local function animateClose()
        uiOpen = false
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quartic, Enum.EasingDirection.In), {
            Position = CLOSED_POS,
        }):Play()
        TweenService:Create(frameGlow, TweenInfo.new(0.3), {
            BackgroundTransparency = 0.9,
        }):Play()
        task.wait(0.35)
        screenGui.Visible = false
    end

    -- ============================================================
    -- KEYBIND : RIGHTSHIFT
    -- ============================================================
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input == Enum.KeyCode.RightShift then
            if uiOpen then
                animateClose()
            else
                animateOpen()
            end
        end
    end)

    -- ============================================================
    -- RETOURN
    -- ============================================================
    local ui = {
        screenGui = screenGui,
        mainFrame = mainFrame,
        searchBox = searchBox,
        searchBtn = searchBtn,
        targetStatus = targetStatus,
        toggles = {
            ["Freeze Trade"] = toggleFreeze,
            ["Force Accept"] = toggleForce,
            ["Auto Add All"] = toggleAuto,
        },
        toggle = function()
            if uiOpen then
                animateClose()
            else
                animateOpen()
            end
        end,
    }

    -- ouverture initiale
    task.wait(0.1)
    animateOpen()

    return ui
end

-- ============================================================
-- INITIALISATION
-- ============================================================
local ui = createUI()
findTradeRemotes()

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if #tradeRemotes == 0 then
            findTradeRemotes()
        end
    end
end)

print("✅  ZYROSCRIPT v2.0 chargé — Appuie sur RightShift pour ouvrir le menu")
