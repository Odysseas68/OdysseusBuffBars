local _, OBB = ...

local Config = {}
OBB.Config = Config

local FRAME_NAME = "OdysseusBuffBarsConfigFrame"
local PANEL_WIDTH = 150
local PADDING = 14
local TEXTURE_PICKER_WIDTH = 360
local TEXTURE_PICKER_VISIBLE_ROWS = 15
local TEXTURE_PICKER_ROW_HEIGHT = 22
local TEXTURE_PICKER_PADDING = 8
local TEXTURE_PICKER_PREVIEW_WIDTH = 100
local TEXTURE_PICKER_PREVIEW_HEIGHT = 12
local FONT_PICKER_WIDTH = 360
local FONT_PICKER_VISIBLE_ROWS = 15
local FONT_PICKER_ROW_HEIGHT = 24
local FONT_PICKER_PADDING = 8
local FONT_PICKER_PREVIEW_SIZE = 14

local function Round(value, step)
    step = step or 1
    return math.floor((value / step) + 0.5) * step
end

local function Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function CreateLabel(parent, text, size)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFontObject(size == "large" and GameFontNormalLarge or GameFontNormal)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function CreateButton(parent, text)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetHeight(24)
    button:SetText(text)
    return button
end

local function CreateDropdown(parent, width, itemsProvider, onSelect)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, width or 160)
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for _, item in ipairs(itemsProvider() or {}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.arg1 = item.value
            info.checked = item.checked
            info.disabled = item.disabled
            info.func = function(_, value)
                onSelect(value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    dropdown.SetEnabled = function(self, enabled)
        if enabled then
            UIDropDownMenu_EnableDropDown(self)
        else
            UIDropDownMenu_DisableDropDown(self)
        end
    end
    dropdown.RefreshText = function(self, text)
        UIDropDownMenu_SetText(self, text)
    end
    return dropdown
end

local function CreateStatusBarTexturePicker(parent, ownerFrame, onSelect)
    local picker = CreateButton(parent, "")
    picker:SetWidth(220)

    local popup = _G.CreateFrame(
        "Frame",
        nil,
        parent,
        _G.BackdropTemplateMixin and "BackdropTemplate"
    )
    popup:SetSize(
        TEXTURE_PICKER_WIDTH,
        (TEXTURE_PICKER_VISIBLE_ROWS * TEXTURE_PICKER_ROW_HEIGHT)
            + (TEXTURE_PICKER_PADDING * 2)
    )
    popup:SetFrameStrata(ownerFrame:GetFrameStrata())
    popup:SetFrameLevel(ownerFrame:GetFrameLevel() + 100)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    popup:Hide()

    local scrollBox = _G.CreateFrame("Frame", nil, popup, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", popup, "TOPLEFT", TEXTURE_PICKER_PADDING, -TEXTURE_PICKER_PADDING)
    scrollBox:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -28, TEXTURE_PICKER_PADDING)
    scrollBox:SetFrameLevel(popup:GetFrameLevel() + 1)
    scrollBox:EnableMouseWheel(true)

    local scrollBar = _G.CreateFrame("EventFrame", nil, popup, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)
    scrollBar:SetFrameLevel(popup:GetFrameLevel() + 1)

    local view = _G.CreateScrollBoxListLinearView()
    view:SetElementExtent(TEXTURE_PICKER_ROW_HEIGHT)
    view:SetElementInitializer("Button", function(row, elementData)
        if not row.texturePickerInitialized then
            row.texturePickerInitialized = true
            row:RegisterForClicks("LeftButtonUp")

            row.selectionIcon = row:CreateTexture(nil, "ARTWORK")
            row.selectionIcon:SetSize(18, 18)
            row.selectionIcon:SetPoint("LEFT", row, "LEFT", 2, 0)
            row.selectionIcon:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])

            row.texturePreview = row:CreateTexture(nil, "ARTWORK")
            row.texturePreview:SetSize(TEXTURE_PICKER_PREVIEW_WIDTH, TEXTURE_PICKER_PREVIEW_HEIGHT)
            row.texturePreview:SetPoint("LEFT", row, "LEFT", 24, 0)

            row.mediaNameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.mediaNameText:SetPoint("LEFT", row.texturePreview, "RIGHT", 6, 0)
            row.mediaNameText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            row.mediaNameText:SetJustifyH("LEFT")
            row.mediaNameText:SetWordWrap(false)
            row.mediaNameText:SetMaxLines(1)

            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.12)

            row:SetScript("OnClick", function(clickedRow)
                popup:Hide()
                onSelect(clickedRow.mediaName)
            end)
        end

        row.mediaName = elementData.name
        row.selectionIcon:SetShown(elementData.name == popup.selectedMediaName)
        row.texturePreview:SetTexture(elementData.texture)
        row.mediaNameText:SetText(elementData.name)
    end)
    _G.ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    function popup:RefreshMedia()
        local libSharedMedia = _G.LibStub
            and _G.LibStub:GetLibrary("LibSharedMedia-3.0", true)
        local mediaType = libSharedMedia
            and libSharedMedia.MediaType
            and libSharedMedia.MediaType.STATUSBAR
        local mediaNames = mediaType and libSharedMedia:List(mediaType) or {}
        local entries = {}
        local selectedIndex
        local fallbackIndex

        for _, mediaName in ipairs(mediaNames) do
            local texture = libSharedMedia:Fetch(mediaType, mediaName, true)
            if texture then
                entries[#entries + 1] = {
                    name = mediaName,
                    texture = texture,
                }
                local entryIndex = #entries
                if mediaName == OBB.db.statusBarTexture then
                    selectedIndex = entryIndex
                elseif mediaName == "Blizzard" then
                    fallbackIndex = entryIndex
                end
            end
        end

        local visibleSelectionIndex = selectedIndex or fallbackIndex
        self.selectedMediaName = visibleSelectionIndex
            and entries[visibleSelectionIndex].name
            or nil
        scrollBox:SetDataProvider(_G.CreateDataProvider(entries))
        if visibleSelectionIndex then
            scrollBox:ScrollToElementDataIndex(
                visibleSelectionIndex,
                _G.ScrollBoxConstants.AlignCenter
            )
        end
    end

    function popup:AnchorToPicker()
        self:ClearAllPoints()
        local pickerBottom = picker:GetBottom()
        if pickerBottom and pickerBottom >= self:GetHeight() + TEXTURE_PICKER_PADDING then
            self:SetPoint("TOPLEFT", picker, "BOTTOMLEFT", 0, -4)
        else
            self:SetPoint("BOTTOMLEFT", picker, "TOPLEFT", 0, 4)
        end
    end

    picker:SetScript("OnClick", function()
        if popup:IsShown() then
            popup:Hide()
            return
        end
        popup:RefreshMedia()
        popup:AnchorToPicker()
        popup:Show()
    end)
    parent:HookScript("OnHide", function()
        popup:Hide()
    end)
    picker.popup = popup
    return picker
end

local function SetFontFaceSafely(fontString, fontFace, fontSize, fontFlags, fallbackFace)
    if type(fontFace) == "string" then
        local callSucceeded, fontApplied = pcall(
            fontString.SetFont,
            fontString,
            fontFace,
            fontSize,
            fontFlags
        )
        if callSucceeded and fontApplied ~= false then
            return
        end
    end

    fontString:SetFont(
        fallbackFace or _G.STANDARD_TEXT_FONT or [[Fonts\FRIZQT__.TTF]],
        fontSize,
        fontFlags
    )
end

local function CreateFontPicker(parent, ownerFrame, onSelect)
    local picker = CreateButton(parent, "")
    picker:SetWidth(220)
    local pickerFontString = picker:GetFontString()
    local pickerDefaultFont, pickerFontSize, pickerFontFlags = pickerFontString:GetFont()

    local popup = _G.CreateFrame(
        "Frame",
        nil,
        parent,
        _G.BackdropTemplateMixin and "BackdropTemplate"
    )
    popup:SetSize(
        FONT_PICKER_WIDTH,
        (FONT_PICKER_VISIBLE_ROWS * FONT_PICKER_ROW_HEIGHT)
            + (FONT_PICKER_PADDING * 2)
    )
    popup:SetFrameStrata(ownerFrame:GetFrameStrata())
    popup:SetFrameLevel(ownerFrame:GetFrameLevel() + 100)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    popup:Hide()

    local scrollBox = _G.CreateFrame("Frame", nil, popup, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", popup, "TOPLEFT", FONT_PICKER_PADDING, -FONT_PICKER_PADDING)
    scrollBox:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -28, FONT_PICKER_PADDING)
    scrollBox:SetFrameLevel(popup:GetFrameLevel() + 1)
    scrollBox:EnableMouseWheel(true)

    local scrollBar = _G.CreateFrame("EventFrame", nil, popup, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)
    scrollBar:SetFrameLevel(popup:GetFrameLevel() + 1)

    local view = _G.CreateScrollBoxListLinearView()
    view:SetElementExtent(FONT_PICKER_ROW_HEIGHT)
    view:SetElementInitializer("Button", function(row, elementData)
        if not row.fontPickerInitialized then
            row.fontPickerInitialized = true
            row:RegisterForClicks("LeftButtonUp")

            row.selectionIcon = row:CreateTexture(nil, "ARTWORK")
            row.selectionIcon:SetSize(18, 18)
            row.selectionIcon:SetPoint("LEFT", row, "LEFT", 2, 0)
            row.selectionIcon:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])

            row.mediaNameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.mediaNameText:SetPoint("LEFT", row, "LEFT", 24, 0)
            row.mediaNameText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            row.mediaNameText:SetJustifyH("LEFT")
            row.mediaNameText:SetWordWrap(false)
            row.mediaNameText:SetMaxLines(1)
            row.defaultFontFace = row.mediaNameText:GetFont()

            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.12)

            row:SetScript("OnClick", function(clickedRow)
                popup:Hide()
                onSelect(clickedRow.mediaName)
            end)
        end

        row.mediaName = elementData.name
        row.selectionIcon:SetShown(elementData.name == popup.selectedMediaName)
        row.mediaNameText:SetText(elementData.name)
        SetFontFaceSafely(
            row.mediaNameText,
            elementData.font,
            FONT_PICKER_PREVIEW_SIZE,
            "",
            row.defaultFontFace
        )
    end)
    _G.ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    function popup:RefreshMedia()
        local libSharedMedia = _G.LibStub
            and _G.LibStub:GetLibrary("LibSharedMedia-3.0", true)
        local mediaType = libSharedMedia
            and libSharedMedia.MediaType
            and libSharedMedia.MediaType.FONT
        local mediaNames = mediaType and libSharedMedia:List(mediaType) or {}
        local defaultMediaName = libSharedMedia
            and libSharedMedia.DefaultMedia
            and libSharedMedia.DefaultMedia.font
            or "Friz Quadrata TT"
        local entries = {}
        local selectedIndex
        local fallbackIndex

        for _, mediaName in ipairs(mediaNames) do
            entries[#entries + 1] = {
                name = mediaName,
                font = libSharedMedia:Fetch(mediaType, mediaName, true),
            }
            local entryIndex = #entries
            if mediaName == OBB.db.font then
                selectedIndex = entryIndex
            elseif mediaName == defaultMediaName then
                fallbackIndex = entryIndex
            end
        end

        local visibleSelectionIndex = selectedIndex or fallbackIndex
        self.selectedMediaName = visibleSelectionIndex
            and entries[visibleSelectionIndex].name
            or nil
        scrollBox:SetDataProvider(_G.CreateDataProvider(entries))
        if visibleSelectionIndex then
            scrollBox:ScrollToElementDataIndex(
                visibleSelectionIndex,
                _G.ScrollBoxConstants.AlignCenter
            )
        end
    end

    function popup:AnchorToPicker()
        self:ClearAllPoints()
        local pickerBottom = picker:GetBottom()
        if pickerBottom and pickerBottom >= self:GetHeight() + FONT_PICKER_PADDING then
            self:SetPoint("TOPLEFT", picker, "BOTTOMLEFT", 0, -4)
        else
            self:SetPoint("BOTTOMLEFT", picker, "TOPLEFT", 0, 4)
        end
    end

    function picker:RefreshSelection(mediaName)
        self:SetText(mediaName)
        local libSharedMedia = _G.LibStub
            and _G.LibStub:GetLibrary("LibSharedMedia-3.0", true)
        local mediaType = libSharedMedia
            and libSharedMedia.MediaType
            and libSharedMedia.MediaType.FONT
        local resolvedFont = mediaType
            and libSharedMedia:Fetch(mediaType, mediaName, true)
        if not resolvedFont then
            local defaultMediaName = libSharedMedia
                and libSharedMedia.DefaultMedia
                and libSharedMedia.DefaultMedia.font
                or "Friz Quadrata TT"
            resolvedFont = mediaType
                and libSharedMedia:Fetch(mediaType, defaultMediaName, true)
        end
        SetFontFaceSafely(
            pickerFontString,
            resolvedFont,
            pickerFontSize,
            pickerFontFlags,
            pickerDefaultFont
        )
    end

    picker:SetScript("OnClick", function()
        if popup:IsShown() then
            popup:Hide()
            return
        end
        popup:RefreshMedia()
        popup:AnchorToPicker()
        popup:Show()
    end)
    parent:HookScript("OnHide", function()
        popup:Hide()
    end)
    picker.popup = popup
    return picker
end

local function CreateEditBox(parent)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetHeight(20)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    return editBox
end

local function CreateCheck(parent, text, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    local label = check.Text or check.text or check:CreateFontString(nil, "OVERLAY")
    label:SetFontObject(GameFontHighlight)
    label:ClearAllPoints()
    label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    label:SetText(text)
    check.label = label
    check:SetScript("OnClick", function(self)
        if Config:IsCombatLocked() then
            Config:WarnCombat()
            Config:RefreshActivePage()
            return
        end
        onClick(self:GetChecked() and true or false)
    end)
    return check
end

local function CreateFilterCheck(parent)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(22, 22)
    check.icon = check:CreateTexture(nil, "ARTWORK")
    check.icon:SetSize(18, 18)
    check.icon:SetPoint("LEFT", check, "RIGHT", 2, 0)
    check.icon:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
    check.label = check:CreateFontString(nil, "OVERLAY")
    check.label:SetFontObject(GameFontHighlightSmall)
    check.label:SetJustifyH("LEFT")
    check.label:SetPoint("LEFT", check.icon, "RIGHT", 6, 0)
    check.label:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    return check
end

local function CreateSlider(parent, labelText, minValue, maxValue, step, onValueChanged)
    local box = CreateFrame("Frame", nil, parent)
    box:SetHeight(46)

    local label = CreateLabel(box, labelText)
    label:SetPoint("TOPLEFT", box, "TOPLEFT", 0, 0)

    local valueBox = CreateFrame("EditBox", nil, box, "InputBoxTemplate")
    valueBox:SetSize(54, 20)
    valueBox:SetPoint("TOPRIGHT", box, "TOPRIGHT", 0, 2)
    valueBox:SetAutoFocus(false)

    local slider = CreateFrame("Slider", nil, box, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 4, -8)
    slider:SetPoint("RIGHT", box, "RIGHT", -4, 0)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText(tostring(minValue))
    slider.High:SetText(tostring(maxValue))
    slider.Text:SetText("")

    slider:SetScript("OnValueChanged", function(self, value)
        if self.suppress then
            return
        end
        if Config:IsCombatLocked() then
            Config:WarnCombat()
            Config:RefreshActivePage()
            return
        end
        value = Clamp(Round(value, step), minValue, maxValue)
        valueBox:SetText(tostring(value))
        onValueChanged(value)
    end)

    valueBox:SetScript("OnEnterPressed", function(self)
        if Config:IsCombatLocked() then
            Config:WarnCombat()
            Config:RefreshActivePage()
            return
        end
        local value = tonumber(self:GetText())
        if value then
            value = Clamp(Round(value, step), minValue, maxValue)
            slider:SetValue(value)
            self:SetText(tostring(value))
        else
            self:SetText(tostring(Clamp(Round(slider:GetValue(), step), minValue, maxValue)))
        end
        self:ClearFocus()
    end)
    valueBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(Clamp(Round(slider:GetValue(), step), minValue, maxValue)))
        self:ClearFocus()
    end)
    valueBox:SetScript("OnEditFocusLost", function(self)
        self:SetText(tostring(Clamp(Round(slider:GetValue(), step), minValue, maxValue)))
    end)

    box.slider = slider
    box.valueBox = valueBox
    return box
end

local function SetSliderValue(sliderBox, value)
    sliderBox.slider.suppress = true
    sliderBox.slider:SetValue(value)
    sliderBox.slider.suppress = false
    sliderBox.valueBox:SetText(tostring(value))
end

local function GetGroupName(groupSettings)
    if groupSettings.name and groupSettings.name ~= "" then
        return groupSettings.name
    end
    return groupSettings.filter == "HARMFUL" and "DEBUFFS" or "BUFFS"
end

local function GetGroupByID(id)
    if not OBB.db then
        return nil
    end
    for _, groupSettings in ipairs(OBB.db.groups) do
        if groupSettings.id == id then
            return groupSettings
        end
    end
    return nil
end

local function GetManagedCompatibilityState()
    local managed = OBB.Managed
    if managed and managed.GetCompatibilityState then
        return managed:GetCompatibilityState()
    end
    return {
        active = false,
        groups = {},
    }
end

local function GetManagedCompatibilityIssue(groupID, kind)
    local state = GetManagedCompatibilityState()
    local groupState = state.groups and state.groups[groupID]
    for _, issue in ipairs(groupState and groupState.issues or {}) do
        if issue.kind == kind then
            return issue
        end
    end
    return nil
end

local function GetSupportedManagedParentID(groupID)
    if groupID == 2 then
        return 1
    end
    if groupID == 3 then
        return 2
    end
    return nil
end

local function GetRawManagedBuffDurationLabel(settings)
    if settings.showTimed == true and settings.showTimeless == true then
        return "ALL"
    end
    if settings.showTimed == true and settings.showTimeless == false then
        return "TIMED_ONLY"
    end
    if settings.showTimed == false and settings.showTimeless == true then
        return "TIMELESS_ONLY"
    end
    if settings.showTimed == false and settings.showTimeless == false then
        return "NONE"
    end
    return "UNSUPPORTED"
end

local function GetAnchorLabel(id)
    if not id then
        return "Screen"
    end
    local groupSettings = GetGroupByID(id)
    return groupSettings and GetGroupName(groupSettings) or "Screen"
end

local function ApplyGroupBarSetting(settings, callback)
    if OBB.db and OBB.db.syncGroupBars then
        for _, groupSettings in ipairs(OBB.db.groups) do
            callback(groupSettings)
        end
    else
        callback(settings)
    end
end

local function EnsureGroupFilters(settings)
    settings.filters = settings.filters or {}
    settings.filters.whitelist = settings.filters.whitelist or {}
    settings.filters.blacklist = settings.filters.blacklist or {}
    return settings.filters
end

local function RefreshManagedHelpfulCandidateFilters()
    local managed = OBB.Managed
    if managed and managed.RefreshCandidateFilters then
        managed:RefreshCandidateFilters()
    end
end

local function RefreshManagedHelpfulGroupFilters(settings)
    if settings and (settings.id == 1 or settings.id == 3) then
        RefreshManagedHelpfulCandidateFilters()
    end
end

local function EnsureOverrides()
    OBB.db.overrides = OBB.db.overrides or {}
    return OBB.db.overrides
end

local function GetOverrideGroupLabel(group)
    if group == "BUFFS" then
        return "BUFFS"
    end
    if group == "ENCHANTMENTS" then
        return "ENCHANTMENTS"
    end
    return "Default"
end

local function BuildOverrideListText()
    local overrides = EnsureOverrides()
    local spellIDs = {}
    for spellID in pairs(overrides) do
        if type(spellID) == "number" then
            table.insert(spellIDs, spellID)
        end
    end
    table.sort(spellIDs)

    if #spellIDs == 0 then
        return "No overrides."
    end

    local lines = {}
    for _, spellID in ipairs(spellIDs) do
        local override = overrides[spellID]
        local group = GetOverrideGroupLabel(override and override.group)
        local hidden = override and override.hidden and "hidden" or "shown"
        lines[#lines + 1] = tostring(spellID) .. " - " .. group .. " - " .. hidden
    end
    return table.concat(lines, "\n")
end

local function GetCurrentAuraFilterRows(settings)
    if settings.id == 1 or settings.id == 3 then
        local managed = OBB.Managed
        if managed and managed.GetCurrentHelpfulAuraFilterRows then
            local rows = managed.GetCurrentHelpfulAuraFilterRows(settings.id)
            if type(rows) == "table" then
                return rows
            end
        end
        return {}
    end
    return {}
end

function Config:Initialize()
    if self.initialized then
        return
    end
    self.initialized = true

    OBB.db.config = OBB.db.config or {}
    OBB.db.config.width = OBB.db.config.width or 700
    OBB.db.config.height = OBB.db.config.height or 500
    OBB.db.config.width = Clamp(OBB.db.config.width, 660, 900)
    OBB.db.config.height = Clamp(OBB.db.config.height, 420, 720)
    OBB.db.config.x = OBB.db.config.x or 0
    OBB.db.config.y = OBB.db.config.y or 0
    OBB.db.config.page = OBB.db.config.page or "general"

    self:CreateFrame()
    self:BuildPages()
    self:SelectPage(OBB.db.config.page)
end

function Config:CreateFrame()
    local frame = CreateFrame("Frame", FRAME_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    _G[FRAME_NAME] = frame
    frame:SetSize(OBB.db.config.width, OBB.db.config.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", OBB.db.config.x, OBB.db.config.y)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(660, 420, 900, 720)
    else
        frame:SetMinResize(660, 420)
        frame:SetMaxResize(900, 720)
    end
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
        edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:Hide()
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    table.insert(UISpecialFrames, FRAME_NAME)

    frame.title = CreateLabel(frame, "Odysseus Buff Bars", "large")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)

    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -8)
    frame.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -34, -8)
    frame.titleBar:SetHeight(34)
    frame.titleBar:EnableMouse(true)
    frame.titleBar:SetScript("OnMouseDown", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        frame:StartMoving()
    end)
    frame.titleBar:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        self:SaveFramePlacement()
    end)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    frame.sidebar = CreateFrame("Frame", nil, frame)
    frame.sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -54)
    frame.sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PADDING, PADDING)
    frame.sidebar:SetWidth(PANEL_WIDTH)

    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", frame.sidebar, "TOPRIGHT", 14, 0)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, PADDING)

    frame.resize = CreateFrame("Button", nil, frame)
    frame.resize:SetSize(18, 18)
    frame.resize:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    frame.resize:SetNormalTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
    frame.resize:SetHighlightTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]])
    frame.resize:SetPushedTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]])
    frame.resize:SetScript("OnMouseDown", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        frame:StartSizing("BOTTOMRIGHT")
    end)
    frame.resize:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        self:SaveFramePlacement()
    end)

    frame:SetScript("OnSizeChanged", function()
        self:SaveFrameSize()
    end)
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            self:EnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            self:LeaveCombat()
        else
            self:RefreshCombatState()
        end
    end)

    self.frame = frame
    self.navButtons = {}
    self.pages = {}
end

function Config:IsCombatLocked()
    return InCombatLockdown and InCombatLockdown()
end

function Config:WarnCombat()
    print("|cff66ccffOdysseusBuffBars:|r |cffff3333WARNING:|r settings are locked during combat.")
end

function Config:WarnAnchoredDrag()
    print("|cff66ccffOdysseusBuffBars:|r move the parent anchor or set this group anchor to Screen first.")
end

function Config:WarnCompatibilityDrag()
    print(
        "|cff66ccffOdysseusBuffBars:|r historical placement is being interpreted temporarily;"
            .. " choose a supported placement in /obb config before dragging."
    )
end

function Config:WouldCreateAnchorCycle(settings, targetID)
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

        local currentSettings = GetGroupByID(currentID)
        currentID = currentSettings and currentSettings.anchorTo or nil
    end
    return false
end

function Config:BreakAnchorCycleForTarget(settings, targetID)
    if not targetID or not OBB.db then
        return
    end

    local seen = {}
    local currentID = targetID
    while currentID do
        if seen[currentID] then
            return
        end
        seen[currentID] = true

        local currentSettings = GetGroupByID(currentID)
        if not currentSettings then
            return
        end
        if currentSettings.anchorTo == settings.id then
            currentSettings.anchorTo = nil
            currentSettings.placement = "SCREEN"
            currentSettings.offsetX = 0
            currentSettings.offsetY = 0
            return
        end
        currentID = currentSettings.anchorTo
    end
end

function Config:ResetGroupPositions()
    if self:IsCombatLocked() then
        self:WarnCombat()
        return
    end
    if not OBB.db then
        return
    end

    local screenWidth = UIParent and UIParent:GetWidth() or 1920
    local screenHeight = UIParent and UIParent:GetHeight() or 1080

    for _, settings in ipairs(OBB.db.groups) do
        settings.offsetX = 0
        settings.offsetY = 0
        if settings.id == 1 then
            settings.anchorTo = nil
            settings.placement = "SCREEN"
            settings.x = math.floor((screenWidth - (settings.width or 260)) / 2 + 0.5)
            settings.y = math.floor((-screenHeight / 2) + 120 + 0.5)
        elseif settings.id == 2 then
            settings.anchorTo = 1
            settings.placement = "BELOW"
            settings.offsetY = -8
        elseif settings.id == 3 then
            settings.anchorTo = 2
            settings.placement = "BELOW"
            settings.offsetY = -8
        end
    end

    self:Apply()
end

function Config:RefreshActivePage()
    if not self.frame or not self.frame:IsShown() or not OBB.db or not OBB.db.config then
        return
    end
    local page = self.pages[OBB.db.config.page]
    if page and page.Refresh then
        page:Refresh()
    end
end

function Config:SetControlEnabled(control, enabled)
    if not control then
        return
    end
    if control.SetEnabled then
        control:SetEnabled(enabled)
    elseif control.Enable then
        if enabled then
            control:Enable()
        else
            control:Disable()
        end
    end
end

function Config:RefreshCombatState()
    local enabled = not self:IsCombatLocked()
    if self.frame then
        if self.frame.titleBar then
            self.frame.titleBar:EnableMouse(enabled)
        end
        if self.frame.resize then
            self.frame.resize:EnableMouse(enabled)
        end
    end
    for id, button in pairs(self.navButtons or {}) do
        button:SetEnabled(enabled and OBB.db and OBB.db.config and id ~= OBB.db.config.page)
    end
    self:RefreshActivePage()
end

function Config:EnterCombat()
    self.combatWarningShown = true
    if self.frame and self.frame:IsShown() then
        self:WarnCombat()
        self.hiddenByCombat = true
        self.frame:Hide()
    end
    if self.filtersFrame and self.filtersFrame:IsShown() then
        self.hiddenFiltersByCombat = true
        self.filtersFrame:Hide()
    end
    if self.overridesFrame and self.overridesFrame:IsShown() then
        self.hiddenOverridesByCombat = true
        self.overridesFrame:Hide()
    end
    self:RefreshCombatState()
end

function Config:LeaveCombat()
    self.combatWarningShown = nil
    if self.frame and self.hiddenByCombat then
        self.hiddenByCombat = nil
        self.frame:Show()
        self:SelectPage(OBB.db.config.page or "general")
    end
    if self.filtersFrame and self.hiddenFiltersByCombat then
        self.hiddenFiltersByCombat = nil
        self.filtersFrame:Show()
        self:RefreshFiltersFrame()
    end
    if self.overridesFrame and self.hiddenOverridesByCombat then
        self.hiddenOverridesByCombat = nil
        self.overridesFrame:Show()
        self:RefreshOverridesFrame()
    end
    self:RefreshCombatState()
end

function Config:SaveFrameSize()
    if not OBB.db or not OBB.db.config or not self.frame then
        return
    end
    if self:IsCombatLocked() then
        return
    end
    OBB.db.config.width = Round(self.frame:GetWidth(), 1)
    OBB.db.config.height = Round(self.frame:GetHeight(), 1)
end

function Config:SaveFramePlacement()
    if not OBB.db or not OBB.db.config or not self.frame then
        return
    end
    if self:IsCombatLocked() then
        return
    end
    OBB.db.config.x = Round(self.frame:GetLeft() + self.frame:GetWidth() / 2 - UIParent:GetWidth() / 2, 1)
    OBB.db.config.y = Round(self.frame:GetBottom() + self.frame:GetHeight() / 2 - UIParent:GetHeight() / 2, 1)
end

function Config:CreateNavButton(pageID, text, index)
    local button = CreateButton(self.frame.sidebar, text)
    button:SetPoint("TOPLEFT", self.frame.sidebar, "TOPLEFT", 0, -((index - 1) * 30))
    button:SetPoint("RIGHT", self.frame.sidebar, "RIGHT", 0, 0)
    button:SetScript("OnClick", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        self:SelectPage(pageID)
    end)
    self.navButtons[pageID] = button
    return button
end

function Config:CreatePage(pageID)
    local page = CreateFrame("Frame", nil, self.frame.content)
    page:SetAllPoints(self.frame.content)
    page:Hide()
    self.pages[pageID] = page
    return page
end

function Config:BuildPages()
    local navIndex = 1
    self:CreateNavButton("general", "General", navIndex)
    self:BuildGeneralPage(self:CreatePage("general"))

    for index, groupSettings in ipairs(OBB.db.groups) do
        navIndex = navIndex + 1
        local pageID = "group" .. tostring(index)
        self:CreateNavButton(pageID, GetGroupName(groupSettings), navIndex)
        self:BuildGroupPage(self:CreatePage(pageID), groupSettings)
    end
end

function Config:SelectPage(pageID)
    if not self.pages[pageID] then
        pageID = "general"
    end
    OBB.db.config.page = pageID
    local enabled = not self:IsCombatLocked()
    for id, page in pairs(self.pages) do
        page:SetShown(id == pageID)
        if self.navButtons[id] then
            self.navButtons[id]:SetEnabled(enabled and id ~= pageID)
        end
    end
    if self.pages[pageID].Refresh then
        self.pages[pageID]:Refresh()
    end
end

function Config:Apply()
    if self:IsCombatLocked() then
        self:WarnCombat()
        self:RefreshActivePage()
        return
    end
    local refreshSuccess = OBB:RefreshAll()
    if not refreshSuccess
        and OBB.Managed
        and OBB.Managed.ApplyConfiguration
    then
        OBB.Managed:ApplyConfiguration("config apply")
    end
    if self.frame and self.frame:IsShown() then
        local page = self.pages[OBB.db.config.page]
        if page and page.Refresh then
            page:Refresh()
        end
    end
end

function Config:ToggleFiltersFrame(settings)
    if self:IsCombatLocked() then
        self:WarnCombat()
        return
    end

    self:CreateFiltersFrame()
    self.filtersFrame.settings = settings
    self.filtersFrame.activeList = self.filtersFrame.activeList or "whitelist"
    self.filtersFrame:SetShown(not self.filtersFrame:IsShown())
    if self.filtersFrame:IsShown() then
        self:RefreshFiltersFrame()
    end
end

function Config:CreateFiltersFrame()
    if self.filtersFrame then
        return
    end

    local frame = CreateFrame(
        "Frame",
        "OdysseusBuffBarsFiltersFrame",
        UIParent,
        BackdropTemplateMixin and "BackdropTemplate"
    )
    frame:SetSize(420, 420)
    frame:SetPoint("CENTER", UIParent, "CENTER", 70, 20)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
        edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:Hide()
    table.insert(UISpecialFrames, "OdysseusBuffBarsFiltersFrame")

    frame.title = CreateLabel(frame, "Filters", "large")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)

    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -8)
    frame.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -34, -8)
    frame.titleBar:SetHeight(34)
    frame.titleBar:EnableMouse(true)
    frame.titleBar:SetScript("OnMouseDown", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        frame:StartMoving()
    end)
    frame.titleBar:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    frame.whitelist = CreateButton(frame, "Whitelist")
    frame.whitelist:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -52)
    frame.whitelist:SetWidth(100)
    frame.whitelist:SetScript("OnClick", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        frame.activeList = "whitelist"
        self:RefreshFiltersFrame()
    end)

    frame.blacklist = CreateButton(frame, "Blacklist")
    frame.blacklist:SetPoint("LEFT", frame.whitelist, "RIGHT", 8, 0)
    frame.blacklist:SetWidth(100)
    frame.blacklist:SetScript("OnClick", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        frame.activeList = "blacklist"
        self:RefreshFiltersFrame()
    end)

    frame.inputLabel = CreateLabel(frame, "Spell ID")
    frame.inputLabel:SetPoint("TOPLEFT", frame.whitelist, "BOTTOMLEFT", 0, -18)

    frame.input = CreateEditBox(frame)
    frame.input:SetPoint("LEFT", frame.inputLabel, "RIGHT", 10, 0)
    frame.input:SetWidth(110)

    frame.add = CreateButton(frame, "Add")
    frame.add:SetPoint("LEFT", frame.input, "RIGHT", 10, 0)
    frame.add:SetWidth(70)
    frame.add:SetScript("OnClick", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        local spellID = tonumber(frame.input:GetText())
        if not spellID then
            return
        end
        local filters = EnsureGroupFilters(frame.settings)
        filters[frame.activeList or "whitelist"][spellID] = true
        frame.input:SetText("")
        frame.input:ClearFocus()
        local refreshSuccess = OBB:RefreshAll()
        if not refreshSuccess then
            RefreshManagedHelpfulGroupFilters(frame.settings)
        end
        self:RefreshFiltersFrame()
    end)

    frame.remove = CreateButton(frame, "Remove")
    frame.remove:SetPoint("LEFT", frame.add, "RIGHT", 8, 0)
    frame.remove:SetWidth(80)
    frame.remove:SetScript("OnClick", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        local spellID = tonumber(frame.input:GetText())
        if not spellID then
            return
        end
        local filters = EnsureGroupFilters(frame.settings)
        filters[frame.activeList or "whitelist"][spellID] = nil
        frame.input:SetText("")
        frame.input:ClearFocus()
        local refreshSuccess = OBB:RefreshAll()
        if not refreshSuccess then
            RefreshManagedHelpfulGroupFilters(frame.settings)
        end
        self:RefreshFiltersFrame()
    end)

    frame.listHeader = CreateLabel(frame, "Current group auras")
    frame.listHeader:SetPoint("TOPLEFT", frame.inputLabel, "BOTTOMLEFT", 0, -18)

    frame.listBox = CreateFrame("Frame", nil, frame)
    frame.listBox:SetPoint("TOPLEFT", frame.listHeader, "BOTTOMLEFT", 0, -6)
    frame.listBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 18)
    frame.listBox:EnableMouseWheel(true)
    frame.listBox:SetScript("OnMouseWheel", function(_, delta)
        local _, maxValue = frame.scrollBar:GetMinMaxValues()
        local value = frame.scrollBar:GetValue()
        if delta < 0 then
            frame.scrollBar:SetValue(math.min(maxValue, value + 1))
        else
            frame.scrollBar:SetValue(math.max(0, value - 1))
        end
    end)

    frame.scrollBar = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
    frame.scrollBar:SetPoint("TOPLEFT", frame.listBox, "TOPRIGHT", 6, -16)
    frame.scrollBar:SetPoint("BOTTOMLEFT", frame.listBox, "BOTTOMRIGHT", 6, 16)
    frame.scrollBar:SetMinMaxValues(0, 0)
    frame.scrollBar:SetValueStep(1)
    frame.scrollBar:SetObeyStepOnDrag(true)
    frame.scrollBar:SetScript("OnValueChanged", function(_, value)
        frame.filterOffset = math.floor((value or 0) + 0.5)
        Config:RefreshFiltersFrame()
    end)

    frame.emptyText = frame:CreateFontString(nil, "OVERLAY")
    frame.emptyText:SetFontObject(GameFontHighlight)
    frame.emptyText:SetJustifyH("LEFT")
    frame.emptyText:SetPoint("TOPLEFT", frame.listBox, "TOPLEFT", 4, -4)
    frame.emptyText:SetText("No current readable spell IDs. Use manual entry.")

    frame.rows = {}
    for index = 1, 12 do
        local row = CreateFilterCheck(frame.listBox)
        if index == 1 then
            row:SetPoint("TOPLEFT", frame.listBox, "TOPLEFT", -4, 0)
        else
            row:SetPoint("TOPLEFT", frame.rows[index - 1], "BOTTOMLEFT", 0, -4)
        end
        row:SetScript("OnClick", function(rowButton)
            if Config:IsCombatLocked() then
                Config:WarnCombat()
                Config:RefreshFiltersFrame()
                return
            end
            local spellID = rowButton.spellID
            if type(spellID) ~= "number" then
                return
            end
            local filters = EnsureGroupFilters(frame.settings)
            local activeList = frame.activeList or "whitelist"
            filters[activeList][spellID] = rowButton:GetChecked() and true or nil
            local refreshSuccess = OBB:RefreshAll()
            if not refreshSuccess then
                RefreshManagedHelpfulGroupFilters(frame.settings)
            end
            Config:RefreshFiltersFrame()
        end)
        frame.rows[index] = row
    end

    self.filtersFrame = frame
end

function Config:RefreshFiltersFrame()
    local frame = self.filtersFrame
    if not frame or not frame.settings then
        return
    end

    local filters = EnsureGroupFilters(frame.settings)
    local activeList = frame.activeList or "whitelist"
    frame.activeList = activeList
    frame.title:SetText(GetGroupName(frame.settings) .. " Filters")
    frame.whitelist:SetEnabled(activeList ~= "whitelist")
    frame.blacklist:SetEnabled(activeList ~= "blacklist")
    local rows = GetCurrentAuraFilterRows(frame.settings)
    local maxOffset = math.max(0, #rows - #frame.rows)
    local offset = math.min(frame.filterOffset or 0, maxOffset)
    frame.filterOffset = offset
    frame.scrollBar:SetMinMaxValues(0, maxOffset)
    frame.scrollBar:SetValueStep(1)
    frame.scrollBar:SetShown(maxOffset > 0)
    if math.floor((frame.scrollBar:GetValue() or 0) + 0.5) ~= offset then
        frame.scrollBar:SetValue(offset)
    end
    frame.emptyText:SetShown(#rows == 0)
    for index, row in ipairs(frame.rows) do
        local data = rows[index + offset]
        row.spellID = data and data.spellID or nil
        row:SetShown(data ~= nil)
        if data then
            row:SetChecked(filters[activeList][data.spellID] and true or false)
            if data.icon ~= nil then
                row.icon:SetTexture(data.icon)
            else
                row.icon:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
            end
            row.label:SetText(data.name .. " (" .. tostring(data.spellID) .. ")")
        end
    end
end

function Config:RefreshManagedHelpfulFilterEditor()
    local frame = self.filtersFrame
    if not frame or not frame:IsShown() or not frame.settings then
        return
    end
    if frame.settings.id == 1 or frame.settings.id == 3 then
        self:RefreshFiltersFrame()
    end
end

function Config:Toggle()
    self:Initialize()
    if self:IsCombatLocked() then
        self:WarnCombat()
        return
    end
    self.frame:SetShown(not self.frame:IsShown())
    if self.frame:IsShown() then
        self:SelectPage(OBB.db.config.page or "general")
    end
end

function Config:ToggleOverridesFrame()
    if self:IsCombatLocked() then
        self:WarnCombat()
        return
    end

    self:CreateOverridesFrame()
    self.overridesFrame:SetShown(not self.overridesFrame:IsShown())
    if self.overridesFrame:IsShown() then
        self:RefreshOverridesFrame()
    end
end

function Config:CreateOverridesFrame()
    if self.overridesFrame then
        return
    end

    local frame = CreateFrame("Frame", "OdysseusBuffBarsOverridesFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(420, 340)
    frame:SetPoint("CENTER", UIParent, "CENTER", 100, 40)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
        edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:Hide()
    table.insert(UISpecialFrames, "OdysseusBuffBarsOverridesFrame")

    frame.title = CreateLabel(frame, "Override Settings", "large")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)

    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -8)
    frame.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -34, -8)
    frame.titleBar:SetHeight(34)
    frame.titleBar:EnableMouse(true)
    frame.titleBar:SetScript("OnMouseDown", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        frame:StartMoving()
    end)
    frame.titleBar:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    frame.inputLabel = CreateLabel(frame, "Spell ID")
    frame.inputLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -58)

    frame.input = CreateEditBox(frame)
    frame.input:SetPoint("LEFT", frame.inputLabel, "RIGHT", 10, 0)
    frame.input:SetWidth(110)

    frame.group = CreateDropdown(frame, 150, function()
        local group = frame.selectedGroup
        return {
            { text = "Default", value = nil, checked = group == nil },
            { text = "BUFFS", value = "BUFFS", checked = group == "BUFFS" },
            { text = "ENCHANTMENTS", value = "ENCHANTMENTS", checked = group == "ENCHANTMENTS" },
        }
    end, function(value)
        if self:IsCombatLocked() then
            self:WarnCombat()
            self:RefreshOverridesFrame()
            return
        end
        frame.selectedGroup = value
        self:RefreshOverridesFrame()
    end)
    frame.group:SetPoint("TOPLEFT", frame.inputLabel, "BOTTOMLEFT", -16, -14)

    frame.hidden = CreateCheck(frame, "Hidden", function(value)
        frame.hiddenValue = value
    end)
    frame.hidden:SetPoint("LEFT", frame.group, "RIGHT", 10, 2)

    frame.save = CreateButton(frame, "Save")
    frame.save:SetPoint("TOPLEFT", frame.group, "BOTTOMLEFT", 16, -12)
    frame.save:SetWidth(80)
    frame.save:SetScript("OnClick", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        local spellID = tonumber(frame.input:GetText())
        if not spellID then
            return
        end
        local overrides = EnsureOverrides()
        local group = frame.selectedGroup
        local hidden = frame.hidden:GetChecked() and true or false
        if not group and not hidden then
            overrides[spellID] = nil
        else
            overrides[spellID] = {
                group = group,
                hidden = hidden,
            }
        end
        local refreshSuccess = OBB:RefreshAll()
        if not refreshSuccess then
            RefreshManagedHelpfulCandidateFilters()
        end
        self:RefreshManagedHelpfulFilterEditor()
        self:RefreshOverridesFrame()
    end)

    frame.remove = CreateButton(frame, "Remove")
    frame.remove:SetPoint("LEFT", frame.save, "RIGHT", 10, 0)
    frame.remove:SetWidth(90)
    frame.remove:SetScript("OnClick", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        local spellID = tonumber(frame.input:GetText())
        if not spellID then
            return
        end
        EnsureOverrides()[spellID] = nil
        frame.selectedGroup = nil
        frame.hiddenValue = false
        local refreshSuccess = OBB:RefreshAll()
        if not refreshSuccess then
            RefreshManagedHelpfulCandidateFilters()
        end
        self:RefreshManagedHelpfulFilterEditor()
        self:RefreshOverridesFrame()
    end)

    frame.list = frame:CreateFontString(nil, "OVERLAY")
    frame.list:SetFontObject(GameFontHighlight)
    frame.list:SetJustifyH("LEFT")
    frame.list:SetJustifyV("TOP")
    frame.list:SetPoint("TOPLEFT", frame.save, "BOTTOMLEFT", 0, -18)
    frame.list:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)

    frame.input:SetScript("OnEnterPressed", function(editBox)
        local spellID = tonumber(editBox:GetText())
        local override = spellID and EnsureOverrides()[spellID] or nil
        frame.selectedGroup = override and override.group or nil
        frame.hiddenValue = override and override.hidden or false
        editBox:ClearFocus()
        self:RefreshOverridesFrame()
    end)

    self.overridesFrame = frame
end

function Config:RefreshOverridesFrame()
    local frame = self.overridesFrame
    if not frame then
        return
    end
    frame.group:RefreshText("Group: " .. GetOverrideGroupLabel(frame.selectedGroup))
    frame.hidden:SetChecked(frame.hiddenValue and true or false)
    frame.list:SetText(BuildOverrideListText())
end

function Config:BuildGeneralPage(page)
    local title = CreateLabel(page, "General", "large")
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)

    local lock = CreateCheck(page, "Lock anchors", function(value)
        OBB.db.locked = value
    end)
    lock:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -4, -18)

    local syncBars = CreateCheck(page, "Sync Group Bars", function(value)
        OBB.db.syncGroupBars = value
    end)
    syncBars:SetPoint("TOPLEFT", lock, "BOTTOMLEFT", 0, -4)

    local hideBlizzard = CreateCheck(page, "Hide default Blizzard frames", function(value)
        OBB.db.hideBlizzardFrames = value
        OBB:ApplyDefaultBlizzardFrameVisibility()
    end)
    hideBlizzard:SetPoint("TOPLEFT", syncBars, "BOTTOMLEFT", 0, -4)

    local textureLabel = CreateLabel(page, "Status-bar texture")
    textureLabel:SetPoint("TOPLEFT", hideBlizzard, "BOTTOMLEFT", 4, -14)

    local texturePicker = CreateStatusBarTexturePicker(page, self.frame, function(value)
        if self:IsCombatLocked() then
            self:WarnCombat()
            self:RefreshActivePage()
            return
        end
        OBB.db.statusBarTexture = value
        self:Apply()
    end)
    texturePicker:SetPoint("LEFT", textureLabel, "RIGHT", 4, 0)

    local fontLabel = CreateLabel(page, "Font")
    fontLabel:SetPoint("TOPLEFT", textureLabel, "BOTTOMLEFT", 0, -18)
    fontLabel:SetWidth(textureLabel:GetStringWidth())

    local fontPicker = CreateFontPicker(page, self.frame, function(value)
        if self:IsCombatLocked() then
            self:WarnCombat()
            self:RefreshActivePage()
            return
        end
        OBB.db.font = value
        self:Apply()
    end)
    fontPicker:SetPoint("LEFT", fontLabel, "RIGHT", 4, 0)

    local refresh = CreateButton(page, "Refresh Auras")
    refresh:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", -4, -18)
    refresh:SetWidth(130)
    refresh:SetScript("OnClick", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        OBB:RefreshAll("config Refresh Auras")
    end)

    local anchors = CreateButton(page, "Toggle Anchors")
    anchors:SetPoint("LEFT", refresh, "RIGHT", 10, 0)
    anchors:SetWidth(130)
    anchors:SetScript("OnClick", function()
        if self:IsCombatLocked() then
            self:WarnCombat()
            return
        end
        OBB:ToggleAnchors()
        lock:SetChecked(OBB.db.locked)
    end)

    local resetPositions = CreateButton(page, "Reset Positions")
    resetPositions:SetPoint("LEFT", anchors, "RIGHT", 10, 0)
    resetPositions:SetWidth(130)
    resetPositions:SetScript("OnClick", function()
        self:ResetGroupPositions()
    end)

    local overrides = CreateButton(page, "Override Settings")
    overrides:SetPoint("TOPLEFT", refresh, "BOTTOMLEFT", 0, -12)
    overrides:SetWidth(150)
    overrides:SetScript("OnClick", function()
        self:ToggleOverridesFrame()
    end)

    local hint = page:CreateFontString(nil, "OVERLAY")
    hint:SetFontObject(GameFontHighlightSmall)
    hint:SetJustifyH("LEFT")
    hint:SetPoint("TOPLEFT", overrides, "BOTTOMLEFT", 0, -18)
    hint:SetText("/obb config opens this frame. /obb anchors toggles anchors.")

    local compatibilityStatus = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    compatibilityStatus:SetJustifyH("LEFT")
    compatibilityStatus:SetJustifyV("TOP")
    compatibilityStatus:SetWordWrap(true)
    compatibilityStatus:SetWidth(440)
    compatibilityStatus:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -16)
    compatibilityStatus:SetTextColor(1, 0.65, 0.2)
    compatibilityStatus:Hide()

    function page:Refresh()
        local enabled = not Config:IsCombatLocked()
        local compatibilityState = GetManagedCompatibilityState()
        lock:SetChecked(OBB.db.locked)
        syncBars:SetChecked(OBB.db.syncGroupBars)
        hideBlizzard:SetChecked(OBB.db.hideBlizzardFrames)
        texturePicker:SetText(OBB.db.statusBarTexture)
        fontPicker:RefreshSelection(OBB.db.font)
        if compatibilityState.active then
            local summary = OBB.Managed
                and OBB.Managed.GetCompatibilitySummary
                and OBB.Managed:GetCompatibilitySummary()
                or ""
            compatibilityStatus:SetText(
                "Compatibility action required: historical settings are being interpreted temporarily."
                    .. " Saved settings have not been changed. " .. summary
            )
            compatibilityStatus:Show()
        else
            compatibilityStatus:Hide()
        end
        Config:SetControlEnabled(lock, enabled)
        Config:SetControlEnabled(syncBars, enabled)
        Config:SetControlEnabled(hideBlizzard, enabled)
        Config:SetControlEnabled(texturePicker, enabled)
        Config:SetControlEnabled(fontPicker, enabled)
        Config:SetControlEnabled(refresh, enabled)
        Config:SetControlEnabled(anchors, enabled)
        Config:SetControlEnabled(resetPositions, enabled)
        Config:SetControlEnabled(overrides, enabled)
    end
end

function Config:BuildGroupPage(page, settings)
    page.controls = {}

    local title = CreateLabel(page, GetGroupName(settings), "large")
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)

    local barsHeader = CreateLabel(page, "Bars")
    barsHeader:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)

    local width = CreateSlider(page, "Width", 120, 500, 1, function(value)
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.width = value
        end)
        self:Apply()
    end)
    width:SetPoint("TOPLEFT", barsHeader, "BOTTOMLEFT", 0, -8)
    width:SetWidth(200)
    page.controls.width = width

    local height = CreateSlider(page, "Height", 12, 36, 1, function(value)
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.height = value
        end)
        self:Apply()
    end)
    height:SetPoint("TOPLEFT", width, "BOTTOMLEFT", 0, -8)
    height:SetWidth(200)
    page.controls.height = height

    local spacing = CreateSlider(page, "Spacing", 0, 16, 1, function(value)
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.spacing = value
        end)
        self:Apply()
    end)
    spacing:SetPoint("TOPLEFT", height, "BOTTOMLEFT", 0, -8)
    spacing:SetWidth(200)
    page.controls.spacing = spacing

    local fontSize = CreateSlider(page, "Font Size", 8, 24, 1, function(value)
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.fontSize = value
        end)
        self:Apply()
    end)
    fontSize:SetPoint("TOPLEFT", spacing, "BOTTOMLEFT", 0, -8)
    fontSize:SetWidth(200)
    page.controls.fontSize = fontSize

    local scale = CreateSlider(page, "Scale", 0.5, 2, 0.05, function(value)
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.scale = value
        end)
        self:Apply()
    end)
    scale:SetPoint("TOPLEFT", page, "TOPLEFT", 230, -44)
    scale:SetWidth(200)
    page.controls.scale = scale

    local maxBars = CreateSlider(page, "Max Bars", 1, 80, 1, function(value)
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.maxBars = value
        end)
        self:Apply()
    end)
    maxBars:SetPoint("TOPLEFT", fontSize, "BOTTOMLEFT", 0, -8)
    maxBars:SetWidth(200)
    page.controls.maxBars = maxBars

    local barAlpha = CreateSlider(page, "Bar Alpha", 0, 1, 0.05, function(value)
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.barColor = groupSettings.barColor or { 0.2, 0.5, 0.9, 0.8 }
            groupSettings.barColor[4] = value
        end)
        self:Apply()
    end)
    barAlpha:SetPoint("TOPLEFT", scale, "BOTTOMLEFT", 0, -8)
    barAlpha:SetWidth(200)
    page.controls.barAlpha = barAlpha

    local bgAlpha = CreateSlider(page, "Background Alpha", 0, 1, 0.05, function(value)
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.barBgColor = groupSettings.barBgColor or { 0, 0, 0, 0.1 }
            groupSettings.barBgColor[4] = value
        end)
        self:Apply()
    end)
    bgAlpha:SetPoint("TOPLEFT", barAlpha, "BOTTOMLEFT", 0, -8)
    bgAlpha:SetWidth(200)
    page.controls.bgAlpha = bgAlpha

    local positionHeader = CreateLabel(page, "Position")
    positionHeader:SetPoint("TOPLEFT", bgAlpha, "BOTTOMLEFT", 0, -14)

    local anchorDropdown = CreateDropdown(page, 170, function()
        local items = {
            {
                text = "Screen",
                value = nil,
                checked = settings.anchorTo == nil and settings.placement == "SCREEN",
            },
        }
        local parentID = GetSupportedManagedParentID(settings.id)
        local parentSettings = parentID and GetGroupByID(parentID)
        if parentSettings then
            items[#items + 1] = {
                text = GetGroupName(parentSettings),
                value = parentID,
                checked = settings.anchorTo == parentID and settings.placement ~= "SCREEN",
            }
        end
        return items
    end, function(value)
        if self:IsCombatLocked() then
            self:WarnCombat()
            self:RefreshActivePage()
            return
        end
        settings.anchorTo = value
        if settings.anchorTo then
            if settings.placement ~= "BELOW"
                and settings.placement ~= "LEFT"
                and settings.placement ~= "RIGHT"
            then
                settings.placement = "BELOW"
            end
        else
            settings.placement = "SCREEN"
        end
        self:Apply()
    end)
    anchorDropdown:SetPoint("TOPLEFT", positionHeader, "BOTTOMLEFT", -16, -4)
    page.controls.anchorDropdown = anchorDropdown

    local placementDropdown = CreateDropdown(page, 170, function()
        local parentID = GetSupportedManagedParentID(settings.id)
        local disabled = not parentID or settings.anchorTo ~= parentID
        return {
            { text = "Below", value = "BELOW", checked = settings.placement == "BELOW", disabled = disabled },
            { text = "Left", value = "LEFT", checked = settings.placement == "LEFT", disabled = disabled },
            { text = "Right", value = "RIGHT", checked = settings.placement == "RIGHT", disabled = disabled },
        }
    end, function(value)
        if self:IsCombatLocked() then
            self:WarnCombat()
            self:RefreshActivePage()
            return
        end
        if settings.anchorTo and value then
            settings.placement = value
        end
        self:Apply()
    end)
    placementDropdown:SetPoint("TOPLEFT", anchorDropdown, "BOTTOMLEFT", 0, -4)
    page.controls.placementDropdown = placementDropdown

    local offsetX = CreateSlider(page, "Offset X", -100, 100, 1, function(value)
        settings.offsetX = value
        self:Apply()
    end)
    offsetX:SetPoint("TOPLEFT", placementDropdown, "BOTTOMLEFT", 16, -8)
    offsetX:SetWidth(200)
    page.controls.offsetX = offsetX

    local offsetY = CreateSlider(page, "Offset Y", -100, 100, 1, function(value)
        settings.offsetY = value
        self:Apply()
    end)
    offsetY:SetPoint("TOPLEFT", offsetX, "BOTTOMLEFT", 0, -8)
    offsetY:SetWidth(200)
    page.controls.offsetY = offsetY

    local placementWarning = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placementWarning:SetJustifyH("LEFT")
    placementWarning:SetJustifyV("TOP")
    placementWarning:SetWordWrap(true)
    placementWarning:SetWidth(210)
    placementWarning:SetPoint("TOPLEFT", offsetY, "BOTTOMLEFT", 0, -4)
    placementWarning:SetTextColor(1, 0.65, 0.2)
    placementWarning:Hide()
    page.controls.placementWarning = placementWarning

    local behaviorAnchor = maxBars
    local behaviorOffsetX = -4
    local behaviorOffsetY = -14
    if settings.id == 1 then
        local filterHeader = CreateLabel(page, "Filters")
        filterHeader:SetPoint("TOPLEFT", maxBars, "BOTTOMLEFT", 0, -14)

        local filterButton = CreateButton(page, "Whitelist / Blacklist")
        filterButton:SetPoint("TOPLEFT", filterHeader, "BOTTOMLEFT", 0, -8)
        filterButton:SetWidth(170)
        filterButton:SetScript("OnClick", function()
            self:ToggleFiltersFrame(settings)
        end)
        page.controls.filterButton = filterButton

        local durationDropdown = CreateDropdown(page, 170, function()
            local durationMode = GetRawManagedBuffDurationLabel(settings)
            return {
                { text = "All", value = "ALL", checked = durationMode == "ALL" },
                { text = "Timed only", value = "TIMED_ONLY", checked = durationMode == "TIMED_ONLY" },
            }
        end, function(value)
            if self:IsCombatLocked() then
                self:WarnCombat()
                self:RefreshActivePage()
                return
            end
            if value == "ALL" or value == "TIMED_ONLY" then
                settings.showTimed = true
                settings.showTimeless = value == "ALL"
                self:Apply()
            end
        end)
        durationDropdown:SetPoint("TOPLEFT", filterButton, "BOTTOMLEFT", -16, -8)
        page.controls.durationDropdown = durationDropdown

        local durationWarning = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        durationWarning:SetJustifyH("LEFT")
        durationWarning:SetJustifyV("TOP")
        durationWarning:SetWordWrap(true)
        durationWarning:SetWidth(210)
        durationWarning:SetPoint("LEFT", durationDropdown, "RIGHT", 8, 0)
        durationWarning:SetTextColor(1, 0.65, 0.2)
        durationWarning:Hide()
        page.controls.durationWarning = durationWarning

        behaviorAnchor = durationDropdown
        behaviorOffsetX = 16
        behaviorOffsetY = -4
    end

    local growUp = CreateCheck(page, "Grow upward", function(value)
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.growUp = value
        end)
        self:Apply()
    end)
    growUp:SetPoint("TOPLEFT", behaviorAnchor, "BOTTOMLEFT", behaviorOffsetX, behaviorOffsetY)
    page.controls.growUp = growUp

    local sortingHeader = CreateLabel(page, "Sorting")
    sortingHeader:SetPoint("TOPLEFT", growUp, "BOTTOMLEFT", 4, -12)

    local sortDropdown = CreateDropdown(page, 140, function()
        local sort = settings.sort or "default"
        return {
            { text = "Time left", value = "timeleft", checked = sort == "timeleft" },
            { text = "Name", value = "name", checked = sort == "name" },
            { text = "Default", value = "default", checked = sort == "default" },
        }
    end, function(value)
        if self:IsCombatLocked() then
            self:WarnCombat()
            self:RefreshActivePage()
            return
        end
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.sort = value or "default"
        end)
        self:Apply()
    end)
    sortDropdown:SetPoint("TOPLEFT", sortingHeader, "BOTTOMLEFT", -16, -4)
    page.controls.sortDropdown = sortDropdown

    local iconDropdown = CreateDropdown(page, 140, function()
        local iconSide = settings.iconSide or "LEFT"
        return {
            { text = "Left", value = "LEFT", checked = iconSide == "LEFT" },
            { text = "Right", value = "RIGHT", checked = iconSide == "RIGHT" },
        }
    end, function(value)
        if self:IsCombatLocked() then
            self:WarnCombat()
            self:RefreshActivePage()
            return
        end
        ApplyGroupBarSetting(settings, function(groupSettings)
            groupSettings.iconSide = value or "LEFT"
        end)
        self:Apply()
    end)
    if settings.id == 1 then
        iconDropdown:SetPoint("LEFT", sortDropdown, "RIGHT", 8, 0)
    else
        iconDropdown:SetPoint("TOPLEFT", sortDropdown, "BOTTOMRIGHT", 8, -4)
    end
    page.controls.iconDropdown = iconDropdown

    function page:Refresh()
        local enabled = not Config:IsCombatLocked()
        local managedEnchantments = settings.id == 3
        SetSliderValue(page.controls.width, settings.width or 260)
        SetSliderValue(page.controls.height, settings.height or 18)
        SetSliderValue(page.controls.spacing, settings.spacing or 3)
        SetSliderValue(page.controls.fontSize, settings.fontSize or 11)
        SetSliderValue(page.controls.scale, settings.scale or 1)
        SetSliderValue(page.controls.maxBars, settings.maxBars or 40)
        SetSliderValue(page.controls.barAlpha, settings.barColor and settings.barColor[4] or 0.8)
        SetSliderValue(page.controls.bgAlpha, settings.barBgColor and settings.barBgColor[4] or 0.1)
        SetSliderValue(page.controls.offsetX, settings.offsetX or 0)
        SetSliderValue(page.controls.offsetY, settings.offsetY or 0)
        if page.controls.durationDropdown then
            local durationMode = GetRawManagedBuffDurationLabel(settings)
            local durationIssue = GetManagedCompatibilityIssue(settings.id, "DURATION")
            if durationIssue then
                page.controls.durationDropdown:RefreshText("Duration: Unsupported (" .. durationIssue.raw .. ")")
                page.controls.durationWarning:SetText(
                    "Saved " .. durationIssue.raw .. "; temporarily using " .. durationIssue.effective
                        .. ". Choose a supported value to save."
                )
                page.controls.durationWarning:Show()
            else
                page.controls.durationDropdown:RefreshText("Duration: " .. durationMode)
                page.controls.durationWarning:Hide()
            end
        end
        page.controls.growUp:SetChecked(settings.growUp)
        if managedEnchantments then
            page.controls.sortDropdown:RefreshText("Sort: Fixed (Managed)")
        else
            page.controls.sortDropdown:RefreshText("Sort: " .. (settings.sort or "default"))
        end
        page.controls.iconDropdown:RefreshText("Icon: " .. (settings.iconSide or "LEFT"))
        local placementIssue = GetManagedCompatibilityIssue(settings.id, "PLACEMENT")
        local parentID = GetSupportedManagedParentID(settings.id)
        local anchorSupported = settings.anchorTo == nil or settings.anchorTo == parentID
        local anchorText = GetAnchorLabel(settings.anchorTo)
        if placementIssue and not anchorSupported then
            anchorText = "Unsupported (" .. anchorText .. ")"
        end
        page.controls.anchorDropdown:RefreshText("Anchor: " .. anchorText)
        if placementIssue then
            page.controls.placementDropdown:RefreshText("Place: Unsupported (" .. tostring(settings.placement) .. ")")
            page.controls.placementWarning:SetText(
                "Saved " .. placementIssue.raw .. "; temporarily using " .. placementIssue.effective
                    .. ". Choose a supported placement to save."
            )
            page.controls.placementWarning:Show()
        else
            page.controls.placementDropdown:RefreshText(
                "Place: " .. (settings.anchorTo and (settings.placement or "BELOW") or "SCREEN")
            )
            page.controls.placementWarning:Hide()
        end
        Config:SetControlEnabled(page.controls.width.slider, enabled)
        Config:SetControlEnabled(page.controls.width.valueBox, enabled)
        Config:SetControlEnabled(page.controls.height.slider, enabled)
        Config:SetControlEnabled(page.controls.height.valueBox, enabled)
        Config:SetControlEnabled(page.controls.spacing.slider, enabled)
        Config:SetControlEnabled(page.controls.spacing.valueBox, enabled)
        Config:SetControlEnabled(page.controls.fontSize.slider, enabled)
        Config:SetControlEnabled(page.controls.fontSize.valueBox, enabled)
        Config:SetControlEnabled(page.controls.scale.slider, enabled)
        Config:SetControlEnabled(page.controls.scale.valueBox, enabled)
        Config:SetControlEnabled(page.controls.maxBars.slider, enabled and not managedEnchantments)
        Config:SetControlEnabled(page.controls.maxBars.valueBox, enabled and not managedEnchantments)
        Config:SetControlEnabled(page.controls.barAlpha.slider, enabled)
        Config:SetControlEnabled(page.controls.barAlpha.valueBox, enabled)
        Config:SetControlEnabled(page.controls.bgAlpha.slider, enabled)
        Config:SetControlEnabled(page.controls.bgAlpha.valueBox, enabled)
        Config:SetControlEnabled(page.controls.offsetX.slider, enabled)
        Config:SetControlEnabled(page.controls.offsetX.valueBox, enabled)
        Config:SetControlEnabled(page.controls.offsetY.slider, enabled)
        Config:SetControlEnabled(page.controls.offsetY.valueBox, enabled)
        if page.controls.durationDropdown then
            Config:SetControlEnabled(page.controls.durationDropdown, enabled)
        end
        Config:SetControlEnabled(page.controls.growUp, enabled)
        if page.controls.filterButton then
            Config:SetControlEnabled(page.controls.filterButton, enabled)
        end
        Config:SetControlEnabled(page.controls.sortDropdown, enabled and not managedEnchantments)
        Config:SetControlEnabled(page.controls.iconDropdown, enabled)
        Config:SetControlEnabled(page.controls.anchorDropdown, enabled)
        Config:SetControlEnabled(
            page.controls.placementDropdown,
            enabled
                and GetSupportedManagedParentID(settings.id) ~= nil
                and settings.anchorTo == GetSupportedManagedParentID(settings.id)
        )
    end
end
