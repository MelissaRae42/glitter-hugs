local addonName = ...
local art = "Interface\\AddOns\\" .. addonName .. "\\Art\\"
local width, height = 164, 32
local hugMacro = "/cleartarget\n/targetfriendplayer\n/stopmacro [noexists][nohelp]\n/hug"
local db
local moving
local settingsCategory
local historyWindow
local historyPage = 0
local daysPerPage = 7

local function readable(value)
    return not issecretvalue or not issecretvalue(value)
end

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetSize(width, height)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("MEDIUM")
frame:SetPoint("TOP", UIParent, "TOP", 0, -74)

local left = frame:CreateTexture(nil, "BACKGROUND")
left:SetTexture(art .. "Pill")
left:SetTexCoord(0, 0.25, 0.25, 0.75)
left:SetPoint("TOPLEFT")
left:SetSize(16, height)

local right = frame:CreateTexture(nil, "BACKGROUND")
right:SetTexture(art .. "Pill")
right:SetTexCoord(0.75, 1, 0.25, 0.75)
right:SetPoint("TOPRIGHT")
right:SetSize(16, height)

local middle = frame:CreateTexture(nil, "BACKGROUND")
middle:SetTexture(art .. "Pill")
middle:SetTexCoord(0.25, 0.75, 0.25, 0.75)
middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")

local button = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
button:SetSize(32, 32)
button:SetPoint("LEFT", 5, 0)
button:SetNormalTexture(art .. "Heart")
button:SetHighlightTexture(art .. "Heart", "ADD")
button:GetHighlightTexture():SetAlpha(0.28)
button:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
button:SetAttribute("type", "macro")
button:SetAttribute("macrotext", hugMacro)

local grip = CreateFrame("Frame", nil, frame)
grip:SetPoint("TOPLEFT", button, "TOPRIGHT")
grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 0)
grip:EnableMouse(true)
grip:RegisterForDrag("LeftButton")
grip:SetScript("OnDragStart", function()
    if not db.lockBadge and not InCombatLockdown() then
        GameTooltip:Hide()
        moving = true
        frame:StartMoving()
    end
end)
grip:SetScript("OnDragStop", function()
    if moving then
        moving = false
        frame:StopMovingOrSizing()
        local x, y = frame:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        db.x, db.y = x - parentX, y - parentY
    end
end)

local counter = grip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
counter:SetPoint("LEFT", 4, 0)
counter:SetPoint("RIGHT", -2, 0)
counter:SetJustifyH("LEFT")
counter:SetTextColor(1, 0.86, 0.94)

local sparkle = button:CreateTexture(nil, "OVERLAY")
sparkle:SetTexture(art .. "Sparkle")
sparkle:SetBlendMode("ADD")
sparkle:SetSize(22, 22)
sparkle:SetPoint("CENTER", button, "TOPRIGHT", -5, -6)
sparkle:SetAlpha(0)

local twinkle = sparkle:CreateAnimationGroup()
local fade = twinkle:CreateAnimation("Alpha")
fade:SetFromAlpha(0)
fade:SetToAlpha(1)
fade:SetDuration(0.10)
fade:SetOrder(1)
local fadeOut = twinkle:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetDuration(0.36)
fadeOut:SetOrder(2)

local function showTooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Glitter Hugs", 1, 0.35, 0.70)
    GameTooltip:AddLine("Click the heart to hug a nearby friendly player.", 1, 1, 1, true)
    if not db.lockBadge then
        GameTooltip:AddLine("Drag the counter to move it.", 0.83, 0.74, 0.81, true)
    end
    GameTooltip:AddLine("Resets at local midnight.", 0.83, 0.74, 0.81, true)
    GameTooltip:Show()
end

for _, region in ipairs({button, grip}) do
    region:SetScript("OnEnter", showTooltip)
    region:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function rollOver()
    local today = date("%Y-%m-%d")
    if today < db.historyStart then
        db.historyStart = today
    end
    if db.day == today then
        return false
    end

    if db.day then
        db.history[db.day] = db.count
    end
    db.day, db.count = today, db.history[today] or 0
    return true
end

local function refreshHistory()
    local today = date("*t")
    today.hour, today.min, today.sec, today.isdst = 12, 0, 0, nil
    local noon = time(today)
    local maximum = 1
    local oldestDay
    for index, row in ipairs(historyWindow.rows) do
        local stamp = noon - (historyPage * daysPerPage + index - 1) * 86400
        local day = date("%Y-%m-%d", stamp)
        oldestDay = day
        row.date:SetText(day == db.day and "Today" or date("%b %d, %Y", stamp))
        row.hugs = nil
        if day >= db.historyStart then
            row.hugs = day == db.day and db.count or db.history[day] or 0
            maximum = math.max(maximum, row.hugs)
        end
    end

    for _, row in ipairs(historyWindow.rows) do
        row.total:SetText(row.hugs == nil and "–" or tostring(row.hugs))
        row.bar:SetShown(row.hugs ~= nil and row.hugs > 0)
        row.bar:SetWidth(math.max(1, (row.hugs or 0) / maximum * 156))
    end
    historyWindow.earlier:SetEnabled(oldestDay > db.historyStart)
    historyWindow.later:SetEnabled(historyPage > 0)
    historyWindow.note:SetText(oldestDay < db.historyStart and "– Before tracking began" or "")
end

local function createHistoryWindow()
    historyWindow = CreateFrame("Frame", "GlitterHugsHistoryWindow", UIParent, "BackdropTemplate")
    historyWindow:SetSize(336, 356)
    if db.historyX and db.historyY then
        historyWindow:SetPoint("CENTER", UIParent, "CENTER", db.historyX, db.historyY)
    else
        historyWindow:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -12)
    end
    historyWindow:SetFrameStrata("DIALOG")
    historyWindow:SetFrameLevel(24)
    historyWindow:SetClampedToScreen(true)
    historyWindow:SetMovable(true)
    historyWindow:EnableMouse(true)
    historyWindow:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    historyWindow:SetBackdropColor(0.10, 0.055, 0.09, 0.98)
    historyWindow:SetBackdropBorderColor(0.78, 0.28, 0.53, 1)
    historyWindow:Hide()
    historyWindow:SetScript("OnShow", refreshHistory)
    tinsert(UISpecialFrames, historyWindow:GetName())

    local close = CreateFrame("Button", nil, historyWindow, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function()
        historyWindow:Hide()
    end)
    local title = historyWindow:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 18, -18)
    title:SetTextColor(1, 0.48, 0.75)
    title:SetText("Daily Hug Log")

    local header = CreateFrame("Frame", nil, historyWindow)
    header:SetPoint("TOPLEFT", 8, -8)
    header:SetPoint("BOTTOMRIGHT", historyWindow, "TOPRIGHT", -36, -46)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    local dragging
    local function stopHistoryDrag()
        if not dragging then
            return
        end
        dragging = false
        historyWindow:StopMovingOrSizing()
        local x, y = historyWindow:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        if x and parentX then
            db.historyX, db.historyY = x - parentX, y - parentY
            historyWindow:ClearAllPoints()
            historyWindow:SetPoint("CENTER", UIParent, "CENTER", db.historyX, db.historyY)
        end
    end
    header:SetScript("OnDragStart", function()
        dragging = true
        historyWindow:StartMoving()
    end)
    header:SetScript("OnDragStop", stopHistoryDrag)
    historyWindow:SetScript("OnHide", stopHistoryDrag)

    historyWindow.rows = {}
    for index = 1, daysPerPage do
        local row = CreateFrame("Frame", nil, historyWindow)
        row:SetPoint("TOPLEFT", 18, -52 - (index - 1) * 34)
        row:SetSize(300, 27)

        row.date = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.date:SetPoint("LEFT")
        local track = row:CreateTexture(nil, "BACKGROUND")
        track:SetColorTexture(0.26, 0.14, 0.22, 0.85)
        track:SetPoint("LEFT", 105, 0)
        track:SetSize(156, 12)
        row.bar = row:CreateTexture(nil, "ARTWORK")
        row.bar:SetColorTexture(0.95, 0.27, 0.59, 1)
        row.bar:SetPoint("LEFT", track, "LEFT")
        row.bar:SetHeight(12)
        row.total = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.total:SetPoint("RIGHT", -2, 0)
        historyWindow.rows[index] = row
    end

    historyWindow.note = historyWindow:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    historyWindow.note:SetPoint("TOPLEFT", 18, -294)
    local function weekButton(label, point, offsetX, delta)
        local nav = CreateFrame("Button", nil, historyWindow, "UIPanelButtonTemplate")
        nav:SetSize(108, 24)
        nav:SetPoint(point, offsetX, 15)
        nav:SetText(label)
        nav:SetScript("OnClick", function()
            historyPage = historyPage + delta
            refreshHistory()
        end)
        return nav
    end
    historyWindow.earlier = weekButton("Earlier", "BOTTOMLEFT", 18, 1)
    historyWindow.later = weekButton("Later", "BOTTOMRIGHT", -18, -1)
end

local function toggleHistory()
    if not historyWindow then
        createHistoryWindow()
    end
    if historyWindow:IsShown() then
        historyWindow:Hide()
    else
        historyPage = 0
        historyWindow:Show()
    end
end

local function updateDisplay()
    counter:SetFormattedText("Hugs today: |cffff74bd%d|r", db.count)
    if historyWindow and historyWindow:IsShown() then
        refreshHistory()
    end
end

local function countEmote(message)
    if not readable(message) or type(message) ~= "string" then
        return
    end

    -- The native emote event uses first-person text for our own targeted hugs.
    -- The recipient can be displayed as a character name or a roleplay name.
    local text = message:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[%w_]+:", ""):gsub("|r", "")
    if not text:match("^%s*You hug%s+%S") then
        return
    end

    rollOver()
    db.count = db.count + 1
    updateDisplay()
    if not db.hideSparkle then
        twinkle:Stop()
        twinkle:Play()
    end
end

local function openSettings()
    Settings.OpenToCategory(settingsCategory:GetID())
end

-- Anchor to the map without inheriting its draw order or clipping.
local minimapButton = CreateFrame("Button", "GlitterHugsMinimapButton", UIParent)
minimapButton:SetSize(28, 28)
minimapButton:SetFrameStrata("DIALOG")
minimapButton:SetFrameLevel(12)
minimapButton:Hide()
minimapButton:SetNormalTexture(art .. "Heart")
minimapButton:SetHighlightTexture(art .. "Heart", "ADD")
minimapButton:GetHighlightTexture():SetAlpha(0.3)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then
        if historyWindow then
            historyWindow:Hide()
        end
        openSettings()
    else
        toggleHistory()
    end
end)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Glitter Hugs", 1, 0.35, 0.70)
    GameTooltip:AddLine("Hugs today: " .. db.count, 1, 1, 1)
    GameTooltip:AddLine("Left-click for hug history. Right-click for settings.", 0.83, 0.74, 0.81, true)
    GameTooltip:AddLine("Drag to move.", 0.83, 0.74, 0.81, true)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local function positionMinimapButton()
    local angle = db.minimapAngle or math.rad(225)
    local x, y = math.cos(angle), math.sin(angle)
    local scale = Minimap:GetEffectiveScale() / minimapButton:GetEffectiveScale()
    local radiusX = Minimap:GetWidth() * scale / 2 + 3
    local radiusY = Minimap:GetHeight() * scale / 2 + 3
    local shape = GetMinimapShape and GetMinimapShape()
    if shape == "SQUARE" then
        local edge = math.max(math.abs(x), math.abs(y))
        x, y = x / edge, y / edge
    end
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x * radiusX, y * radiusY)
end

minimapButton:SetScript("OnDragStart", function(self)
    GameTooltip:Hide()
    self:SetScript("OnUpdate", function()
        local centerX, centerY = Minimap:GetCenter()
        if not centerX then
            return
        end
        local cursorX, cursorY = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        db.minimapAngle = math.atan2(cursorY / scale - centerY, cursorX / scale - centerX)
        positionMinimapButton()
    end)
end)
local function stopMinimapDrag(self)
    self:SetScript("OnUpdate", nil)
end
minimapButton:SetScript("OnDragStop", stopMinimapDrag)
minimapButton:SetScript("OnHide", stopMinimapDrag)
Minimap:HookScript("OnSizeChanged", function()
    if db then
        positionMinimapButton()
    end
end)
hooksecurefunc(Minimap, "SetScale", function()
    if db then
        positionMinimapButton()
    end
end)

local function updateMinimapVisibility()
    if db then
        minimapButton:SetShown(Minimap:IsVisible() and not db.hideMinimap)
    end
end
Minimap:HookScript("OnShow", updateMinimapVisibility)
Minimap:HookScript("OnHide", updateMinimapVisibility)

local function updateBadgeVisibility()
    if InCombatLockdown() then
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        frame:SetShown(not db.hideBadge)
    end
end

local function resetBadgePosition()
    if InCombatLockdown() then
        print("|cffff74bdGlitter Hugs|r  The badge can be moved after combat.")
        return
    end

    db.x, db.y = nil, nil
    frame:ClearAllPoints()
    frame:SetPoint("TOP", UIParent, "TOP", 0, -74)
end

local function createSettings()
    local panel = CreateFrame("Frame")
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", 24, -24)
    title:SetText("Glitter Hugs")
    title:SetTextColor(1, 0.46, 0.74)

    local controls = {
        { label = "Show the hug badge", key = "hideBadge", inverted = true, apply = updateBadgeVisibility },
        { label = "Show the minimap button", key = "hideMinimap", inverted = true, apply = updateMinimapVisibility },
        { label = "Sparkle when a hug is counted", key = "hideSparkle", inverted = true },
        { label = "Lock the hug badge in place", key = "lockBadge" },
    }
    for index, control in ipairs(controls) do
        local checkbox = CreateFrame("CheckButton", nil, panel, "SettingsCheckBoxTemplate")
        checkbox:SetSize(21, 20)
        checkbox:SetPoint("TOPLEFT", 25, -62 - (index - 1) * 32)
        checkbox.HoverBackground = nil
        local label = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
        label:SetText(control.label)
        checkbox:SetHitRectInsets(0, -label:GetStringWidth() - 6, 0, 0)
        checkbox:SetChecked((db[control.key] == true) ~= (control.inverted == true))
        checkbox:SetScript("OnClick", function(self)
            db[control.key] = (self:GetChecked() == true) ~= (control.inverted == true)
            if control.apply then
                control.apply()
            end
        end)
    end

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(160, 24)
    reset:SetPoint("TOPLEFT", 24, -202)
    reset:SetText("Reset badge position")
    reset:SetScript("OnClick", resetBadgePosition)

    settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, "Glitter Hugs")
    Settings.RegisterAddOnCategory(settingsCategory)
end

SLASH_GLITTERHUGS1 = "/glitterhugs"
SLASH_GLITTERHUGS2 = "/gh"
SlashCmdList.GLITTERHUGS = function(text)
    if text == "hug" then
        local isPlayer, isFriend, isSelf = UnitIsPlayer("target"), UnitIsFriend("player", "target"),
            UnitIsUnit("player", "target")
        if readable(isPlayer) and readable(isFriend) and readable(isSelf)
            and isPlayer and isFriend and not isSelf then
            C_ChatInfo.PerformEmote("HUG")
        end
    elseif text == "resetpos" then
        resetBadgePosition()
    elseif text == "history" then
        toggleHistory()
    else
        openSettings()
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then
            return
        end

        GlitterHugsDB = GlitterHugsDB or {}
        db = GlitterHugsDB
        db.count = db.count or 0
        db.history = db.history or {}
        db.historyStart = db.historyStart or db.day or date("%Y-%m-%d")
        if db.x and db.y and not InCombatLockdown() then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
        end
        rollOver()
        updateDisplay()
        C_Timer.NewTicker(2, function()
            if rollOver() then
                updateDisplay()
            end
        end)
        self:UnregisterEvent("ADDON_LOADED")
        self:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
        createSettings()
        positionMinimapButton()
        updateMinimapVisibility()
        updateBadgeVisibility()
    elseif event == "CHAT_MSG_TEXT_EMOTE" then
        countEmote(...)
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent(event)
        updateBadgeVisibility()
    end
end)
