local _, OBB = ...

local Bars = {}
OBB.Bars = Bars

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local ANCHOR_HEIGHT = 18
local ANCHOR_GAP = 4
local RETAIL_12_1_INTERFACE_VERSION = 120100
local _, _, _, interfaceVersion = GetBuildInfo()
local IS_RETAIL_12_1_OR_NEWER = interfaceVersion >= RETAIL_12_1_INTERFACE_VERSION

local function GetStatusBarTexture()
    if LSM then
        return LSM:Fetch("statusbar", "Blizzard", true) or [[Interface\TargetingFrame\UI-StatusBar]]
    end
    return [[Interface\TargetingFrame\UI-StatusBar]]
end

local function EnsureFontString(parent, layer, justify)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFontObject(GameFontHighlightSmall)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("MIDDLE")
    fs:SetWordWrap(false)
    return fs
end

local function ApplyFontSize(bar, settings)
    local size = settings.fontSize or 11
    local font = STANDARD_TEXT_FONT or [[Fonts\FRIZQT__.TTF]]
    bar.nameText:SetFont(font, size, "")
    bar.timeText:SetFont(font, size, "")
    bar.countText:SetFont(font, math.max(10, size - 1), "OUTLINE")
end

local function GetPlacementPoints(placement)
    if placement == "ABOVE" then
        return "BOTTOMLEFT", "TOPLEFT", 0, 8
    end
    if placement == "LEFT" then
        return "TOPRIGHT", "TOPLEFT", -8, 0
    end
    if placement == "RIGHT" then
        return "TOPLEFT", "TOPRIGHT", 8, 0
    end
    return "TOPLEFT", "BOTTOMLEFT", 0, -8
end

local function SaveScreenPosition(group, settings)
    local left = group:GetLeft()
    local top = group:GetTop()
    local parentTop = UIParent and UIParent:GetTop()
    if not left or not top or not parentTop then
        return false
    end
    settings.x = left
    settings.y = top - parentTop
    return true
end

local function DetachGroupToScreen(group, settings)
    if not SaveScreenPosition(group, settings) then
        return false
    end
    settings.anchorTo = nil
    settings.placement = "SCREEN"
    group:ClearAllPoints()
    group:SetPoint("TOPLEFT", UIParent, "TOPLEFT", settings.x, settings.y)
    return true
end

local function WouldCreateAnchorCycle(settings, targetID)
    if not targetID or not OBB.db then
        return false
    end
    if targetID == settings.id then
        return true
    end

    local seen = {}
    local currentID = targetID
    while currentID do
        if currentID == settings.id then
            return true
        end
        if seen[currentID] then
            return true
        end
        seen[currentID] = true

        local currentSettings = nil
        for _, groupSettings in ipairs(OBB.db.groups or {}) do
            if groupSettings.id == currentID then
                currentSettings = groupSettings
                break
            end
        end
        currentID = currentSettings and currentSettings.anchorTo or nil
    end
    return false
end

local function Bar_OnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.1 then
        return
    end
    self.elapsed = 0

    local data = self.data
    if data and data.expires and data.duration then
        self.timeText:SetText(OBB.Engine:FormatDuration(data.duration) or "?")
    elseif data and data.expires and data.type == "ENCHANTMENT" and data.expirationTime then
        local remaining = math.max(0, data.expirationTime - GetTime())
        self.timeText:SetText(OBB.Engine:FormatWeaponEnchantTime(remaining) or "?")
    end
end

local function Bar_OnEnter(self)
    local bar = self.bar or self
    if OBB.Bars then
        OBB.Bars:ShowTooltip(bar, self)
    end
end

local function Bar_OnLeave(self)
    local bar = self.bar or self
    if OBB.Bars then
        OBB.Bars:HideTooltip(bar, self)
    end
end

function Bars:IsCombatLocked()
    return InCombatLockdown and InCombatLockdown()
end

function Bars:ShowTooltip(bar, owner)
    local data = bar and bar.data
    if not data or not GameTooltip then
        return
    end

    owner = owner or bar
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if data.type == "ENCHANTMENT" and data.targetSlot and GameTooltip.SetInventoryItem then
        local ok = pcall(GameTooltip.SetInventoryItem, GameTooltip, "player", data.targetSlot)
        if ok then
            GameTooltip:Show()
        end
        return
    end

    -- Retail 12.1 forbids the legacy indexed aura tooltip path when aura data is secret.
    if IS_RETAIL_12_1_OR_NEWER then
        GameTooltip:Hide()
        return
    end

    if data.unit and data.index and data.index > 0 and GameTooltip.SetUnitAura then
        local filter = data.filter or (data.type == "DEBUFF" and "HARMFUL" or "HELPFUL")
        local ok = pcall(GameTooltip.SetUnitAura, GameTooltip, data.unit, data.index, filter)
        if ok then
            GameTooltip:Show()
        end
    end
end

function Bars:HideTooltip(bar, owner)
    if not GameTooltip then
        return
    end
    local tooltipOwner = GameTooltip:GetOwner()
    if tooltipOwner == owner or tooltipOwner == bar or (bar and tooltipOwner == bar.cancelButton) then
        GameTooltip:Hide()
    end
end

function Bars:IsCancelable(data)
    if not data or data.unit ~= "player" then
        return false
    end
    if data.type == "BUFF" and data.index and data.index > 0 then
        return true
    end
    if data.type == "ENCHANTMENT" and data.expires and data.targetSlot then
        return true
    end
    return false
end

function Bars:EnsureCancelButton(bar)
    if not bar or self:IsCombatLocked() then
        return false
    end
    if bar.cancelButton then
        return true
    end

    local button = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("RightButtonDown", "RightButtonUp")
    button:EnableMouse(false)
    button:SetFrameLevel(bar:GetFrameLevel() + 10)
    button.bar = bar
    button:SetScript("OnEnter", Bar_OnEnter)
    button:SetScript("OnLeave", Bar_OnLeave)
    bar.cancelButton = button
    return true
end

function Bars:ClearCancelButton(bar)
    if not bar or not bar.cancelButton or self:IsCombatLocked() then
        return
    end
    bar.cancelButton:EnableMouse(false)
    bar.cancelButton:ClearAllPoints()
    bar.cancelButton:Hide()
    bar.cancelButton:SetAttribute("*type2", nil)
    bar.cancelButton:SetAttribute("unit", nil)
    bar.cancelButton:SetAttribute("*index2", nil)
    bar.cancelButton:SetAttribute("*target-slot2", nil)
end

function Bars:UpdateCancelButton(bar, data)
    if not bar or self:IsCombatLocked() then
        return
    end
    if not self:EnsureCancelButton(bar) then
        return
    end

    local left = bar:GetLeft()
    local right = bar:GetRight()
    local top = bar:GetTop()
    local bottom = bar:GetBottom()
    if not left or not right or not top or not bottom then
        self:ClearCancelButton(bar)
        return
    end

    bar.cancelButton:ClearAllPoints()
    bar.cancelButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    bar.cancelButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", right, bottom)
    bar.cancelButton:SetFrameLevel(bar:GetFrameLevel() + 10)
    bar.cancelButton:Show()

    if not self:IsCancelable(data) then
        self:ClearCancelButton(bar)
        return
    end

    bar.cancelButton:SetAttribute("*type2", "cancelaura")
    bar.cancelButton:SetAttribute("unit", "player")
    if data.type == "ENCHANTMENT" then
        bar.cancelButton:SetAttribute("*index2", nil)
        bar.cancelButton:SetAttribute("*target-slot2", data.targetSlot)
    else
        bar.cancelButton:SetAttribute("*target-slot2", nil)
        bar.cancelButton:SetAttribute("*index2", data.index)
    end
    bar.cancelButton:EnableMouse(true)
end

function Bars:RefreshCancelButtons()
    if self:IsCombatLocked() then
        return
    end
    for _, group in pairs(OBB.groups) do
        for _, bar in ipairs(group.bars or {}) do
            if bar:IsShown() then
                self:UpdateCancelButton(bar, bar.data)
            else
                self:ClearCancelButton(bar)
            end
        end
    end
end

function Bars:Initialize()
    for _, groupSettings in ipairs(OBB.db.groups) do
        self:CreateGroup(groupSettings)
    end
end

function Bars:CreateGroup(settings)
    if OBB.groups[settings.id] then
        return OBB.groups[settings.id]
    end

    local group = CreateFrame("Frame", nil, UIParent)
    group:SetSize(settings.width, settings.height)
    self:SetGroupPosition(group, settings)
    group:SetScale(settings.scale or 1)
    group:SetAlpha(settings.alpha or 1)
    group.bars = {}

    local anchor = CreateFrame("Button", nil, group, BackdropTemplateMixin and "BackdropTemplate")
    anchor:SetPoint("BOTTOMLEFT", group, "TOPLEFT", 0, 4)
    anchor:SetSize(settings.width, ANCHOR_HEIGHT)
    anchor:SetMovable(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetBackdrop({
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    anchor:SetBackdropColor(0, 0, 0, 0.7)
    anchor.text = EnsureFontString(anchor, "OVERLAY", "CENTER")
    anchor.text:SetAllPoints(anchor)
    anchor.text:SetText(settings.name)
    anchor:SetShown(OBB.db.anchorsShown)
    anchor:SetScript("OnDragStart", function()
        if OBB.Config and OBB.Config:IsCombatLocked() then
            OBB.Config:WarnCombat()
            return
        end
        if OBB.db.locked then
            return
        end
        if settings.anchorTo then
            if OBB.Config then
                OBB.Config:WarnAnchoredDrag()
            end
            return
        end
        if not DetachGroupToScreen(group, settings) then
            return
        end
        group.isDraggingAnchor = true
        group:StartMoving()
    end)
    anchor:SetScript("OnDragStop", function()
        if OBB.Config and OBB.Config:IsCombatLocked() then
            return
        end
        if OBB.db.locked then
            return
        end
        if not group.isDraggingAnchor then
            return
        end
        group:StopMovingOrSizing()
        group.isDraggingAnchor = nil
        settings.anchorTo = nil
        settings.placement = "SCREEN"
        SaveScreenPosition(group, settings)
        self:UpdateAllGroupPositions()
    end)

    group:SetMovable(true)
    group.anchor = anchor
    OBB.groups[settings.id] = group
    return group
end

function Bars:SetGroupPosition(group, settings)
    if self:IsCombatLocked() then
        return
    end
    if group.isDraggingAnchor then
        return
    end
    group:ClearAllPoints()
    if settings.anchorTo and WouldCreateAnchorCycle(settings, settings.anchorTo) then
        settings.anchorTo = nil
        settings.placement = "SCREEN"
    end

    if settings.anchorTo then
        local parent = OBB.groups[settings.anchorTo]
        if parent then
            local point, relativePoint, defaultX, defaultY = GetPlacementPoints(settings.placement)
            local offsetX = settings.offsetX or defaultX
            local offsetY = settings.offsetY or defaultY
            if settings.placement == "BELOW" or not settings.placement then
                offsetY = offsetY - ANCHOR_HEIGHT - ANCHOR_GAP
            end
            group:SetPoint(
                point,
                parent,
                relativePoint,
                offsetX,
                offsetY
            )
            return
        end
    end
    group:SetPoint("TOPLEFT", UIParent, "TOPLEFT", settings.x or 420, settings.y or -180)
end

function Bars:UpdateAllGroupPositions()
    if not OBB.db then
        return
    end
    for _, settings in ipairs(OBB.db.groups) do
        local group = OBB.groups[settings.id]
        if group then
            self:SetGroupPosition(group, settings)
        end
    end
end

function Bars:CreateBar(group)
    local bar = CreateFrame("Frame", nil, group)
    bar:SetSize(1, 1)
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", Bar_OnEnter)
    bar:SetScript("OnLeave", Bar_OnLeave)

    bar.icon = bar:CreateTexture(nil, "ARTWORK")
    bar.icon:SetPoint("LEFT", bar, "LEFT")

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetColorTexture(0, 0, 0, 0.55)

    bar.status = CreateFrame("StatusBar", nil, bar)
    bar.status:SetStatusBarTexture(GetStatusBarTexture())
    bar.status:SetMinMaxValues(0, 1)
    bar.status:SetValue(1)

    bar.textLayer = CreateFrame("Frame", nil, bar)
    bar.textLayer:SetFrameLevel(bar.status:GetFrameLevel() + 1)

    bar.nameText = EnsureFontString(bar.textLayer, "OVERLAY", "LEFT")
    bar.timeText = EnsureFontString(bar.textLayer, "OVERLAY", "RIGHT")
    bar.countText = EnsureFontString(bar.textLayer, "OVERLAY", "RIGHT")
    bar.countText:SetFontObject(NumberFontNormalSmall)

    return bar
end

function Bars:LayoutBar(bar, settings, index)
    local height = settings.height
    local width = settings.width
    local spacing = settings.spacing or 0
    local y = (index - 1) * (height + spacing)

    bar:SetSize(width, height)
    bar:ClearAllPoints()
    if settings.growUp then
        bar:SetPoint("BOTTOMLEFT", bar:GetParent(), "BOTTOMLEFT", 0, y)
    else
        bar:SetPoint("TOPLEFT", bar:GetParent(), "TOPLEFT", 0, -y)
    end

    bar.icon:SetSize(height, height)
    bar.bg:ClearAllPoints()
    bar.status:ClearAllPoints()
    bar.textLayer:ClearAllPoints()
    bar.nameText:ClearAllPoints()
    bar.timeText:ClearAllPoints()
    bar.countText:ClearAllPoints()

    local iconOffset = height + 4
    if settings.iconSide == "RIGHT" then
        bar.icon:ClearAllPoints()
        bar.icon:SetPoint("RIGHT", bar, "RIGHT")
        bar.bg:SetPoint("TOPLEFT", bar, "TOPLEFT")
        bar.bg:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -iconOffset, 0)
    else
        bar.icon:ClearAllPoints()
        bar.icon:SetPoint("LEFT", bar, "LEFT")
        bar.bg:SetPoint("TOPLEFT", bar, "TOPLEFT", iconOffset, 0)
        bar.bg:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
    end

    bar.status:SetAllPoints(bar.bg)
    bar.textLayer:SetAllPoints(bar)
    bar.nameText:SetPoint("LEFT", bar.bg, "LEFT", 5, 0)
    bar.nameText:SetPoint("RIGHT", bar.timeText, "LEFT", -6, 0)
    bar.timeText:SetPoint("RIGHT", bar.bg, "RIGHT", -5, 0)
    bar.timeText:SetWidth(56)
    bar.countText:SetPoint("BOTTOMRIGHT", bar.icon, "BOTTOMRIGHT", -1, 1)
end

function Bars:ApplyData(bar, data, settings)
    bar.data = data
    ApplyFontSize(bar, settings)
    bar.icon:SetTexture(data.icon)
    bar.nameText:SetText(data.name or UNKNOWN)
    bar.countText:SetText((data.applications and data.applications > 1) and data.applications or "")

    local r, g, b, a = unpack(settings.barColor or { 0.2, 0.5, 0.9, 0.85 })
    bar.status:GetStatusBarTexture():SetVertexColor(r, g, b, a)
    local br, bg, bb, ba = unpack(settings.barBgColor or { 0, 0, 0, 0.55 })
    bar.bg:SetColorTexture(br, bg, bb, ba)

    if data.expires and data.duration then
        bar.status:Show()
        bar.status:SetTimerDuration(data.duration, nil, Enum.StatusBarTimerDirection.RemainingTime)
        bar.timeText:SetText(data.formattedTime or "?")
        bar.elapsed = 0
        bar:SetScript("OnUpdate", Bar_OnUpdate)
    elseif data.expires then
        bar.status:Show()
        bar.status:SetMinMaxValues(0, 1)
        bar.status:SetValue(1)
        bar.timeText:SetText(data.formattedTime or "?")
        if data.type == "ENCHANTMENT" and data.expirationTime then
            bar.elapsed = 0
            bar:SetScript("OnUpdate", Bar_OnUpdate)
        else
            bar:SetScript("OnUpdate", nil)
        end
    else
        bar.status:SetMinMaxValues(0, 1)
        bar.status:SetValue(1)
        bar.status:Hide()
        bar.timeText:SetText("")
        bar:SetScript("OnUpdate", nil)
    end

    self:UpdateCancelButton(bar, data)
end

function Bars:UpdateGroup(settings, auraData)
    local group = self:CreateGroup(settings)
    local maxBars = settings.maxBars or 40
    local count = 0

    group:SetScale(settings.scale or 1)
    group:SetAlpha(settings.alpha or 1)

    for _, data in ipairs(auraData or {}) do
        if (data.expires and settings.showTimed) or ((not data.expires) and settings.showTimeless) then
            count = count + 1
            if count > maxBars then
                break
            end
            if not group.bars[count] then
                group.bars[count] = self:CreateBar(group)
            end
            local bar = group.bars[count]
            self:LayoutBar(bar, settings, count)
            bar:Show()
            self:ApplyData(bar, data, settings)
        end
    end

    for i = count + 1, #group.bars do
        local bar = group.bars[i]
        bar:SetScript("OnUpdate", nil)
        self:HideTooltip(bar, bar)
        self:ClearCancelButton(bar)
        bar:Hide()
    end

    local totalHeight = math.max(settings.height, count * settings.height + math.max(0, count - 1) * (settings.spacing or 0))
    group:SetSize(settings.width, totalHeight)
    group.anchor:SetWidth(settings.width)
    group.anchor.text:SetText(settings.name)
    if not group.isDraggingAnchor then
        self:SetGroupPosition(group, settings)
    end
    group:Show()
end
