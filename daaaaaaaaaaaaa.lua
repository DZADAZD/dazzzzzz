--[[
    ZYROSCRIPT - Anime Dice Trade Freeze (FIXED v2)
    Exécuteur Lua (Synapse / Krnl / Solara / etc.)
]]--

local Players     = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------
-- 1. UI
------------------------------------------------------------
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ZYROScript"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- Barre du haut
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.fromScale(0.32, 0.04)
    topBar.Position = UDim2.fromScale(0.5, 0.05)
    topBar.AnchorPoint = Vector2.new(0.5, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(15, 20, 40)
    topBar.BorderSizePixel = 0
    topBar.Parent = screenGui
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.fromScale(1, 1)
    title.BackgroundTransparency = 1
    title.Text = "ZYROSCRIPT  •  Anime Dice Trade"
    title.TextColor3 = Color3.fromRGB(80, 160, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = topBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.new(1, -34, 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 70)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = topBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

    -- Corps principal
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.fromScale(0.32, 0.45)
    body.Position = UDim2.fromScale(0.5, 0.10)
    body.AnchorPoint = Vector2.new(0.5, 0)
    body.BackgroundColor3 = Color3.fromRGB(10, 14, 30)
    body.BorderSizePixel = 0
    body.Parent = screenGui
    Instance.new("UICorner", body).CornerRadius = UDim.new(0, 12)

    local uiList = Instance.new("UIListLayout")
    uiList.Padding = UDim.new(0, 10)
    uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiList.VerticalAlignment = Enum.VerticalAlignment.Top
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = body

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 14)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.Parent = body

    -- Section : TARGET PLAYER
    local targetSection = Instance.new("Frame")
    targetSection.Name = "TargetSection"
    targetSection.Size = UDim2.fromScale(1, 0.30)
    targetSection.BackgroundTransparency = 1
    targetSection.LayoutOrder = 1
    targetSection.Parent = body

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = "TARGET PLAYER"
    label.TextColor3 = Color3.fromRGB(80, 160, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = targetSection

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -110, 0, 36)
    searchBox.Position = UDim2.new(0, 0, 1, -46)
    searchBox.BackgroundColor3 = Color3.fromRGB(20, 26, 50)
    searchBox.PlaceholderText = "Nom ou UserId du joueur"
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 160)
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 14
    searchBox.BorderSizePixel = 0
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = targetSection
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 8)

    local searchBtn = Instance.new("TextButton")
    searchBtn.Name = "SearchBtn"
    searchBtn.Size = UDim2.new(0, 90, 0, 36)
    searchBtn.Position = UDim2.new(1, -90, 1, -46)
    searchBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
    searchBtn.Text = "Search"
    searchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBtn.Font = Enum.Font.GothamBold
    searchBtn.TextSize = 14
    searchBtn.BorderSizePixel = 0
    searchBtn.Parent = targetSection
    Instance.new("UICorner", searchBtn).CornerRadius = UDim.new(0, 8)

    -- Section : OPTIONS
    local optionsSection = Instance.new("Frame")
    optionsSection.Name = "OptionsSection"
    optionsSection.Size = UDim2.new(1, 0, 0, 130)
    optionsSection.BackgroundTransparency = 1
    optionsSection.LayoutOrder = 2
    optionsSection.Parent = body

    local optLabel = Instance.new("TextLabel")
    optLabel.Size = UDim2.new(1, 0, 0, 20)
    optLabel.BackgroundTransparency = 1
    optLabel.Text = "OPTIONS"
    optLabel.TextColor3 = Color3.fromRGB(80, 160, 255)
    optLabel.Font = Enum.Font.GothamBold
    optLabel.TextSize = 13
    optLabel.TextXAlignment = Enum.TextXAlignment.Left
    optLabel.Parent = optionsSection

    -- Toggles
    local toggleData = {
        { name = "Freeze Trade",    icon = "❄️", order = 2 },
        { name = "Force Accept",    icon = "✅", order = 3 },
        { name = "Auto Add All",    icon = "📦", order = 4 },
    }

    local toggles = {}
    for i, data in ipairs(toggleData) do
        local row = Instance.new("Frame")
        row.Name = data.name
        row.Size = UDim2.new(1, 0, 0, 34)
        row.Position = UDim2.new(0, 0, 1, -34 * i)
        row.BackgroundColor3 = Color3.fromRGB(18, 24, 46)
        row.BorderSizePixel = 0
        row.LayoutOrder = data.order
        row.Parent = optionsSection
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 30, 1, 0)
        icon.BackgroundTransparency = 1
        icon.Text = data.icon
        icon.TextSize = 16
        icon.Font = Enum.Font.Gotham
        icon.Parent = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -110, 1, 0)
        nameLabel.Position = UDim2.new(0, 34, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = data.name
        nameLabel.TextColor3 = Color3.fromRGB(230, 235, 255)
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextSize = 14
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "Status"
        statusLabel.Size = UDim2.new(0, 40, 1, 0)
        statusLabel.Position = UDim2.new(1, -110, 0, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "OFF"
        statusLabel.TextColor3 = Color3.fromRGB(120, 130, 160)
        statusLabel.Font = Enum.Font.GothamBold
        statusLabel.TextSize = 12
        statusLabel.TextXAlignment = Enum.TextXAlignment.Right
        statusLabel.Parent = row

        local switch = Instance.new("TextButton")
        switch.Name = "Switch"
        switch.Size = UDim2.new(0, 44, 0, 22)
        switch.Position = UDim2.new(1, -54, 0.5, 0)
        switch.AnchorPoint = Vector2.new(0, 0.5)
        switch.BackgroundColor3 = Color3.fromRGB(60, 70, 110)
        switch.Text = ""
        switch.BorderSizePixel = 0
        switch.Parent = row
        Instance.new("UICorner", switch).CornerRadius = UDim.new(0, 11)

        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.Size = UDim2.fromOffset(18, 18)
        knob.Position = UDim2.new(0, 2, 0.5, 0)
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = switch
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 9)

        local enabled = false
        switch.MouseButton1Click:Connect(function()
            enabled = not enabled
            local targetPos = enabled and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
            TweenService:Create(knob, TweenInfo.new(0.15), { Position = targetPos }):Play()
            switch.BackgroundColor3 = enabled and Color3.fromRGB(80, 160, 255) or Color3.fromRGB(60, 70, 110)
            statusLabel.Text = enabled and "ON" or "OFF"
            statusLabel.TextColor3 = enabled and Color3.fromRGB(80, 255, 140) or Color3.fromRGB(120, 130, 160)

            local opt = data.name
            if opt == "Freeze Trade" then
                setFreeze(enabled)
            elseif opt == "Force Accept" then
                setForceAccept(enabled)
            elseif opt == "Auto Add All" then
                setAutoAdd(enabled)
            end
        end)

        toggles[data.name] = { switch = switch, enabled = function() return enabled end }
    end

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    return {
        searchBox = searchBox,
        searchBtn = searchBtn,
        toggles = toggles,
    }
end

------------------------------------------------------------
-- 2. Recherche / ciblage du joueur
------------------------------------------------------------
local targetPlayer = nil

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

------------------------------------------------------------
-- 3. Logique Trade
------------------------------------------------------------
local tradeRemotes = {}
local freezeActive = false
local forceAcceptActive = false
local autoAddActive = false

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
    scan(ReplicatedStorage)
    scan(workspace)
    return tradeRemotes
end

local function setFreeze(on)
    freezeActive = on
    if on then
        for _, r in ipairs(tradeRemotes) do
            local n = r.Name:lower()
            if (n:find("add") or n:find("remove") or n:find("swap")) and r:IsA("RemoteEvent") then
                r.OnClientEvent:Connect(function(...)
                    -- fige la liste
                end)
            end
        end
    end
end

local function setForceAccept(on)
    forceAcceptActive = on
    if on and targetPlayer then
        for _, r in ipairs(tradeRemotes) do
            local n = r.Name:lower()
            if n:find("accept") then
                if r:IsA("RemoteEvent") then
                    r:FireServer(targetPlayer.UserId, true)
                elseif r:IsA("RemoteFunction") then
                    pcall(function() r:InvokeServer(targetPlayer.UserId, true) end)
                end
            end
        end
    end
end

local function setAutoAdd(on)
    autoAddActive = on
    if on then
        for _, r in ipairs(tradeRemotes) do
            local n = r.Name:lower()
            if n:find("add") and r:IsA("RemoteEvent") then
                r:FireServer("all")
            end
        end
    end
end

------------------------------------------------------------
-- 4. Initialisation
------------------------------------------------------------
local ui = createUI()

ui.searchBtn.MouseButton1Click:Connect(function()
    targetPlayer = resolveTarget(ui.searchBox.Text)
    if targetPlayer then
        ui.searchBox.Text = targetPlayer.Name
        if ui.toggles["Force Accept"].enabled() then setForceAccept(true) end
        if ui.toggles["Auto Add All"].enabled() then setAutoAdd(true) end
    else
        ui.searchBox.Text = "❌ Non trouvé"
    end
end)

findTradeRemotes()
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if #tradeRemotes == 0 then
            findTradeRemotes()
        end
    end
end)

print("✅ ZYROSCRIPT chargé — Anime Dice Trade Freeze")