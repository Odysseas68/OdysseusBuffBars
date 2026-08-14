local OBB = _G.OdysseusBuffBars

if not OBB then
    return
end

OBB.ENABLE_MANAGED_AURA_PROTOTYPE = true

if not OBB.ENABLE_MANAGED_AURA_PROTOTYPE then
    return
end

-- Keep the PTR-only prototype inert when the 12.1 AuraContainer surface is unavailable.
if not AuraContainerSortMethod
    or not AuraContainerSortDirection
    or not AnchorUtil
    or not Enum
    or not Enum.StatusBarTimerDirection
then
    return
end

local ManagedPrototype = {}
OBB.ManagedPrototype = ManagedPrototype
OBB.managedAuraPrototype = ManagedPrototype

local BAR_WIDTH = 250
local BAR_HEIGHT = 16
local BAR_SPACING = 2
local MAX_AURAS = 30
local HOST_PADDING = 4
local HOST_HEADER_HEIGHT = 22
local MANAGED_GROUP_GAP = 8
local AURA_GROUP_KEY = "Helpful"
local DEBUFF_AURA_GROUP_KEY = "Harmful"
local ENHANCEMENT_AURA_GROUP_KEY = "HelpfulEnhancements"
local INITIAL_PROTOTYPE_SORT_MODE = "TIMELEFT"
local ROUTED_ENHANCEMENT_SPELL_IDS = {
    [1232325] = true,
}

local SORT_MODES = {
    DEFAULT = {
        label = "Default",
        method = AuraContainerSortMethod.Default,
        direction = AuraContainerSortDirection.Normal,
    },
    NAME = {
        label = "Name",
        method = AuraContainerSortMethod.NameOnly,
        direction = AuraContainerSortDirection.Normal,
    },
    TIMELEFT = {
        label = "Time Left",
        method = AuraContainerSortMethod.ExpirationOnly,
        direction = AuraContainerSortDirection.Reverse,
    },
}

local NEXT_SORT_MODE = {
    DEFAULT = "NAME",
    NAME = "TIMELEFT",
    TIMELEFT = "DEFAULT",
}

local function CopyRoutedEnhancementSpellIDs()
    local spellIDs = {}

    for spellID, enabled in pairs(ROUTED_ENHANCEMENT_SPELL_IDS) do
        if enabled then
            spellIDs[spellID] = true
        end
    end

    return spellIDs
end

local function CompileManagedBuffCandidateFilters(filters)
    local whitelist = filters and filters.whitelist
    local blacklist = filters and filters.blacklist
    local includeSpellIDs = {}
    local excludeSpellIDs = CopyRoutedEnhancementSpellIDs()
    local hasWhitelist = false

    if type(whitelist) == "table" then
        for spellID, enabled in pairs(whitelist) do
            if enabled and type(spellID) == "number" then
                includeSpellIDs[spellID] = true
                hasWhitelist = true
            end
        end
    end

    if hasWhitelist then
        return {
            includeSpellIDs = includeSpellIDs,
            excludeSpellIDs = excludeSpellIDs,
        }
    end

    if type(blacklist) == "table" then
        for spellID, enabled in pairs(blacklist) do
            if enabled and type(spellID) == "number" then
                excludeSpellIDs[spellID] = true
            end
        end
    end

    return {
        excludeSpellIDs = excludeSpellIDs,
    }
end

local function CompileManagedEnhancementCandidateFilters()
    return {
        includeSpellIDs = CopyRoutedEnhancementSpellIDs(),
    }
end

local function GetLegacyBuffFilters()
    if not OBB.db or type(OBB.db.groups) ~= "table" then
        return nil
    end

    for _, groupSettings in ipairs(OBB.db.groups) do
        if groupSettings.id == 1 then
            return groupSettings.filters
        end
    end

    return nil
end

function ManagedPrototype:RefreshCandidateFilters()
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    if not self.container or not self.container.SetAuraGroupCandidateFilters then
        return false
    end
    if not self.enchantmentContainer or not self.enchantmentContainer.SetAuraGroupCandidateFilters then
        return false
    end

    local buffCandidateFilters = CompileManagedBuffCandidateFilters(GetLegacyBuffFilters())
    local enhancementCandidateFilters = CompileManagedEnhancementCandidateFilters()
    self.container:SetAuraGroupCandidateFilters(AURA_GROUP_KEY, buffCandidateFilters)
    self.enchantmentContainer:SetAuraGroupCandidateFilters(
        ENHANCEMENT_AURA_GROUP_KEY,
        enhancementCandidateFilters
    )
    return true
end

local function InitializeAuraButton(auraButton)
    auraButton:SetSize(BAR_WIDTH, BAR_HEIGHT)

    local background = auraButton:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.02, 0.05, 0.10, 0.85)

    local durationBar = CreateFrame("StatusBar", nil, auraButton)
    durationBar:SetPoint("TOPLEFT", auraButton, "TOPLEFT", BAR_HEIGHT + 2, 0)
    durationBar:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT")
    durationBar:SetFrameLevel(auraButton:GetFrameLevel() + 1)
    durationBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    durationBar:SetStatusBarColor(0.18, 0.42, 0.72, 0.8)

    local icon = auraButton:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", auraButton, "LEFT")
    icon:SetSize(BAR_HEIGHT, BAR_HEIGHT)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local textLayer = CreateFrame("Frame", nil, auraButton)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(durationBar:GetFrameLevel() + 1)

    local nameText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", auraButton, "LEFT", BAR_HEIGHT + 6, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetWordWrap(false)

    local durationText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    durationText:SetPoint("RIGHT", auraButton, "RIGHT", -5, 0)
    durationText:SetWidth(52)
    durationText:SetJustifyH("RIGHT")
    durationText:SetJustifyV("MIDDLE")
    durationText:SetWordWrap(false)

    nameText:SetPoint("RIGHT", durationText, "LEFT", -5, 0)

    local countText = textLayer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    countText:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMLEFT", BAR_HEIGHT - 1, 1)
    countText:SetJustifyH("RIGHT")
    countText:SetJustifyV("BOTTOM")

    auraButton:SetIcon(icon)
    auraButton:SetSpellName(nameText)
    auraButton:SetApplicationCount(countText)
    auraButton:SetDurationText(durationText)
    auraButton:SetDurationBar(durationBar, {
        direction = Enum.StatusBarTimerDirection.RemainingTime,
    })
    auraButton:SetCancelAuraButtons("RightButtonDown")
end

local function CreateManagedAuraPrototype()
    local host = CreateFrame("Frame", "OdysseusBuffBarsManagedPrototypeHost", UIParent)
    host:SetSize(BAR_WIDTH + (HOST_PADDING * 2), HOST_HEADER_HEIGHT)
    host:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 24, -180)
    host:SetFrameStrata("MEDIUM")
    host:SetMovable(true)
    host:SetClampedToScreen(true)
    host:Hide()

    local background = host:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.7)

    local label = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, -4)
    label:SetText("OBB Managed Bars")

    local dragHandle = CreateFrame("Button", nil, host)
    dragHandle:SetPoint("TOPLEFT", host, "TOPLEFT")
    dragHandle:SetPoint("TOPRIGHT", host, "TOPRIGHT")
    dragHandle:SetHeight(HOST_HEADER_HEIGHT)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function()
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        host:StartMoving()
    end)
    dragHandle:SetScript("OnDragStop", function()
        host:StopMovingOrSizing()
    end)

    local container = CreateFrame(
        "AuraContainer",
        "OdysseusBuffBarsManagedPrototypeContainer",
        host,
        "CustomAuraContainerTemplate"
    )
    container:Hide()
    container:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, -HOST_HEADER_HEIGHT)
    container:SetSize(1, 1)
    container:SetEnabled(false)
    container:SetUnit("player")
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
    local activeSortMode = INITIAL_PROTOTYPE_SORT_MODE
    local activeSort = SORT_MODES[activeSortMode]
    container:AddAuraGroup(AURA_GROUP_KEY, "HELPFUL", {
        candidateFilters = CompileManagedBuffCandidateFilters(GetLegacyBuffFilters()),
        maxFrameCount = MAX_AURAS,
        initializeFrame = InitializeAuraButton,
        sortMethod = activeSort.method,
        sortDirection = activeSort.direction,
        layout = {
            elementWidth = BAR_WIDTH,
            elementHeight = BAR_HEIGHT,
            elementSpacing = BAR_SPACING,
        },
    })

    local sortButton = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    sortButton:SetSize(94, 18)
    sortButton:SetPoint("TOPRIGHT", host, "TOPRIGHT", -2, -2)
    sortButton:SetFrameLevel(dragHandle:GetFrameLevel() + 1)
    sortButton:SetText("Sort: " .. activeSort.label)
    sortButton:SetScript("OnClick", function()
        if InCombatLockdown and InCombatLockdown() then
            return
        end

        activeSortMode = NEXT_SORT_MODE[activeSortMode]
        activeSort = SORT_MODES[activeSortMode]
        container:SetAuraGroupSortMethod(AURA_GROUP_KEY, activeSort.method, activeSort.direction)
        sortButton:SetText("Sort: " .. activeSort.label)
    end)

    ManagedPrototype.host = host
    ManagedPrototype.container = container
    ManagedPrototype.sortButton = sortButton

    host:Show()
    container:Show()
    container:SetEnabled(true)

    local filterInitFrame = CreateFrame("Frame")
    local startupInventoryGeneration
    local startupInventoryCheckPending

    local function ScheduleStartupInventoryQuietTurn()
        if startupInventoryGeneration == nil or startupInventoryCheckPending then
            return
        end

        startupInventoryCheckPending = true
        local scheduledGeneration = startupInventoryGeneration
        C_Timer.After(0, function()
            startupInventoryCheckPending = nil
            if startupInventoryGeneration == nil then
                return
            end

            if startupInventoryGeneration ~= scheduledGeneration then
                ScheduleStartupInventoryQuietTurn()
                return
            end

            filterInitFrame:UnregisterEvent("UNIT_INVENTORY_CHANGED")
            startupInventoryGeneration = nil
            ManagedPrototype.enchantmentContainer:UpdateAllAuras()
        end)
    end

    filterInitFrame:RegisterEvent("ADDON_LOADED")
    filterInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    filterInitFrame:SetScript("OnEvent", function(_, event, eventArg1)
        if event == "ADDON_LOADED" then
            if eventArg1 ~= OBB.addonName then
                return
            end
            filterInitFrame:UnregisterEvent("ADDON_LOADED")
            ManagedPrototype:RefreshCandidateFilters()
        elseif event == "PLAYER_ENTERING_WORLD" then
            local initialLogin = eventArg1
            ManagedPrototype.enchantmentContainer:UpdateAllAuras()
            if initialLogin then
                startupInventoryGeneration = 0
                startupInventoryCheckPending = nil
                filterInitFrame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
            end
        elseif event == "UNIT_INVENTORY_CHANGED" then
            if startupInventoryGeneration ~= nil then
                startupInventoryGeneration = startupInventoryGeneration + 1
                ScheduleStartupInventoryQuietTurn()
            end
        end
    end)
end

local function InitializeDebuffAuraButton(auraButton)
    auraButton:SetSize(BAR_WIDTH, BAR_HEIGHT)

    local background = auraButton:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.10, 0.02, 0.02, 0.85)

    local durationBar = CreateFrame("StatusBar", nil, auraButton)
    durationBar:SetPoint("TOPLEFT", auraButton, "TOPLEFT", BAR_HEIGHT + 2, 0)
    durationBar:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT")
    durationBar:SetFrameLevel(auraButton:GetFrameLevel() + 1)
    durationBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    durationBar:SetStatusBarColor(0.72, 0.18, 0.18, 0.8)

    local icon = auraButton:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", auraButton, "LEFT")
    icon:SetSize(BAR_HEIGHT, BAR_HEIGHT)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local textLayer = CreateFrame("Frame", nil, auraButton)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(durationBar:GetFrameLevel() + 1)

    local nameText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", auraButton, "LEFT", BAR_HEIGHT + 6, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetWordWrap(false)

    local durationText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    durationText:SetPoint("RIGHT", auraButton, "RIGHT", -5, 0)
    durationText:SetWidth(52)
    durationText:SetJustifyH("RIGHT")
    durationText:SetJustifyV("MIDDLE")
    durationText:SetWordWrap(false)

    nameText:SetPoint("RIGHT", durationText, "LEFT", -5, 0)

    local countText = textLayer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    countText:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMLEFT", BAR_HEIGHT - 1, 1)
    countText:SetJustifyH("RIGHT")
    countText:SetJustifyV("BOTTOM")

    auraButton:SetIcon(icon)
    auraButton:SetSpellName(nameText)
    auraButton:SetApplicationCount(countText)
    auraButton:SetDurationText(durationText)
    auraButton:SetDurationBar(durationBar, {
        direction = Enum.StatusBarTimerDirection.RemainingTime,
    })
end

local function CreateManagedDebuffPrototype(buffContainer)
    local host = CreateFrame(
        "Frame",
        "OdysseusBuffBarsManagedDebuffPrototypeHost",
        UIParent,
        "DisableUntrustedLayoutScriptsTemplate"
    )
    host:SetSize(BAR_WIDTH + (HOST_PADDING * 2), HOST_HEADER_HEIGHT)
    host:SetPoint("TOPLEFT", buffContainer, "BOTTOMLEFT", -HOST_PADDING, -MANAGED_GROUP_GAP)
    host:SetFrameStrata("MEDIUM")
    host:Hide()

    local background = host:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.12, 0, 0, 0.75)

    local label = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, -4)
    label:SetText("OBB Managed DEBUFFS")

    local container = CreateFrame(
        "AuraContainer",
        "OdysseusBuffBarsManagedDebuffPrototypeContainer",
        host,
        "CustomAuraContainerTemplate"
    )
    container:Hide()
    container:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, -HOST_HEADER_HEIGHT)
    container:SetSize(1, 1)
    container:SetEnabled(false)
    container:SetUnit("player")
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
    local activeSortMode = INITIAL_PROTOTYPE_SORT_MODE
    local activeSort = SORT_MODES[activeSortMode]
    container:AddAuraGroup(DEBUFF_AURA_GROUP_KEY, "HARMFUL", {
        maxFrameCount = MAX_AURAS,
        initializeFrame = InitializeDebuffAuraButton,
        sortMethod = activeSort.method,
        sortDirection = activeSort.direction,
        layout = {
            elementWidth = BAR_WIDTH,
            elementHeight = BAR_HEIGHT,
            elementSpacing = BAR_SPACING,
        },
    })

    local sortButton = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    sortButton:SetSize(94, 18)
    sortButton:SetPoint("TOPRIGHT", host, "TOPRIGHT", -2, -2)
    sortButton:SetFrameLevel(host:GetFrameLevel() + 1)
    sortButton:SetText("Sort: " .. activeSort.label)
    sortButton:SetScript("OnClick", function()
        if InCombatLockdown and InCombatLockdown() then
            return
        end

        activeSortMode = NEXT_SORT_MODE[activeSortMode]
        activeSort = SORT_MODES[activeSortMode]
        container:SetAuraGroupSortMethod(DEBUFF_AURA_GROUP_KEY, activeSort.method, activeSort.direction)
        sortButton:SetText("Sort: " .. activeSort.label)
    end)

    ManagedPrototype.debuffHost = host
    ManagedPrototype.debuffContainer = container
    ManagedPrototype.debuffSortButton = sortButton

    host:Show()
    container:Show()
    container:SetEnabled(true)
end

local function InitializeEnchantmentAuraButton(auraButton)
    auraButton:SetSize(BAR_WIDTH, BAR_HEIGHT)

    local background = auraButton:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.08, 0.02, 0.10, 0.85)

    local durationBar = CreateFrame("StatusBar", nil, auraButton)
    durationBar:SetPoint("TOPLEFT", auraButton, "TOPLEFT", BAR_HEIGHT + 2, 0)
    durationBar:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT")
    durationBar:SetFrameLevel(auraButton:GetFrameLevel() + 1)
    durationBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    durationBar:SetStatusBarColor(0.48, 0.20, 0.62, 0.8)

    local icon = auraButton:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", auraButton, "LEFT")
    icon:SetSize(BAR_HEIGHT, BAR_HEIGHT)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local textLayer = CreateFrame("Frame", nil, auraButton)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(durationBar:GetFrameLevel() + 1)

    local nameText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", auraButton, "LEFT", BAR_HEIGHT + 6, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetWordWrap(false)

    local durationText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    durationText:SetPoint("RIGHT", auraButton, "RIGHT", -5, 0)
    durationText:SetWidth(52)
    durationText:SetJustifyH("RIGHT")
    durationText:SetJustifyV("MIDDLE")
    durationText:SetWordWrap(false)

    nameText:SetPoint("RIGHT", durationText, "LEFT", -5, 0)

    local countText = textLayer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    countText:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMLEFT", BAR_HEIGHT - 1, 1)
    countText:SetJustifyH("RIGHT")
    countText:SetJustifyV("BOTTOM")

    auraButton:SetIcon(icon)
    auraButton:SetSpellName(nameText)
    auraButton:SetApplicationCount(countText)
    auraButton:SetDurationText(durationText)
    auraButton:SetDurationBar(durationBar, {
        direction = Enum.StatusBarTimerDirection.RemainingTime,
    })
    auraButton:SetCancelAuraButtons("RightButtonDown")
end

local function CreateManagedEnchantmentPrototype(debuffContainer)
    local host = CreateFrame(
        "Frame",
        "OdysseusBuffBarsManagedEnchantmentPrototypeHost",
        UIParent,
        "DisableUntrustedLayoutScriptsTemplate"
    )
    host:SetSize(BAR_WIDTH + (HOST_PADDING * 2), HOST_HEADER_HEIGHT)
    host:SetPoint("TOPLEFT", debuffContainer, "BOTTOMLEFT", -HOST_PADDING, -MANAGED_GROUP_GAP)
    host:SetFrameStrata("MEDIUM")
    host:Hide()

    local background = host:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.10, 0.02, 0.12, 0.75)

    local label = host:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, -4)
    label:SetText("OBB Managed ENCHANTMENTS")

    local container = CreateFrame(
        "AuraContainer",
        "OdysseusBuffBarsManagedEnchantmentPrototypeContainer",
        host,
        "CustomAuraContainerTemplate"
    )
    container:Hide()
    container:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, -HOST_HEADER_HEIGHT)
    container:SetSize(1, 1)
    container:SetEnabled(false)
    container:SetUnit("player")
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
    container:SetItemEnchantmentLayout({
        elementWidth = BAR_WIDTH,
        elementHeight = BAR_HEIGHT,
        elementSpacing = BAR_SPACING,
    })
    container:SetItemEnchantmentSortMethod(
        AuraContainerItemEnchantmentSortMethod.Duration,
        AuraContainerSortDirection.Reverse
    )
    container:AddItemEnchantment(AuraContainerItemEnchantmentSlot.MainHand, {
        initializeFrame = InitializeEnchantmentAuraButton,
        hidePermanent = false,
    })
    container:AddItemEnchantment(AuraContainerItemEnchantmentSlot.OffHand, {
        initializeFrame = InitializeEnchantmentAuraButton,
        hidePermanent = false,
    })
    local activeSort = SORT_MODES[INITIAL_PROTOTYPE_SORT_MODE]
    container:AddAuraGroup(ENHANCEMENT_AURA_GROUP_KEY, "HELPFUL", {
        candidateFilters = CompileManagedEnhancementCandidateFilters(),
        maxFrameCount = MAX_AURAS,
        initializeFrame = InitializeEnchantmentAuraButton,
        sortMethod = activeSort.method,
        sortDirection = activeSort.direction,
        layout = {
            elementWidth = BAR_WIDTH,
            elementHeight = BAR_HEIGHT,
            elementSpacing = BAR_SPACING,
        },
    })

    ManagedPrototype.enchantmentHost = host
    ManagedPrototype.enchantmentContainer = container

    host:Show()
    container:Show()
    container:SetEnabled(true)
end

CreateManagedAuraPrototype()
CreateManagedDebuffPrototype(ManagedPrototype.container)
CreateManagedEnchantmentPrototype(ManagedPrototype.debuffContainer)
