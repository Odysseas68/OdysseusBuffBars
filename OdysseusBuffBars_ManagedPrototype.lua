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

local BUFF_BAR_SPACING = 3
local BUFF_BAR_STYLE = {
    width = 260,
    height = 18,
    fontSize = 11,
    countFontSize = 10,
    iconTexCoords = { 0, 1, 0, 1 },
    iconGap = 4,
    namePadding = 5,
    durationWidth = 56,
    durationRightPadding = 5,
    nameDurationGap = 6,
    fillColor = { 0.3, 0.5, 1.0, 0.8 },
    backgroundColor = { 0.0, 0.5, 1.0, 0.1 },
    countFontFlags = "OUTLINE",
    countOffsetX = -1,
    countOffsetY = 1,
}
local BUFF_HEADER_STYLE = {
    width = 260,
    height = 18,
    firstRowGap = 4,
    backdrop = {
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    },
    backgroundColor = { 0, 0, 0, 0.7 },
    fontObject = "GameFontHighlightSmall",
    text = "BUFFS",
}
local DEBUFF_BAR_SPACING = 3
local DEBUFF_BAR_STYLE = {
    width = 260,
    height = 18,
    fontSize = 11,
    countFontSize = 10,
    iconTexCoords = { 0, 1, 0, 1 },
    iconGap = 4,
    namePadding = 5,
    durationWidth = 56,
    durationRightPadding = 5,
    nameDurationGap = 6,
    fillColor = { 1.0, 0.0, 0.0, 0.8 },
    backgroundColor = { 1.0, 0.0, 0.0, 0.1 },
    countFontFlags = "OUTLINE",
    countOffsetX = -1,
    countOffsetY = 1,
}
local DEBUFF_HEADER_STYLE = {
    width = 260,
    height = 18,
    firstRowGap = 4,
    backdrop = {
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    },
    backgroundColor = { 0, 0, 0, 0.7 },
    fontObject = "GameFontHighlightSmall",
    text = "DEBUFFS",
}
local ENCHANTMENT_BAR_SPACING = 3
local ENCHANTMENT_BAR_STYLE = {
    width = 260,
    height = 18,
    fontSize = 11,
    countFontSize = 10,
    iconTexCoords = { 0, 1, 0, 1 },
    iconGap = 4,
    namePadding = 5,
    durationWidth = 56,
    durationRightPadding = 5,
    nameDurationGap = 6,
    fillColor = { 0.5, 0.0, 0.5, 0.8 },
    backgroundColor = { 0.5, 0.0, 0.5, 0.1 },
    countFontFlags = "OUTLINE",
    countOffsetX = -1,
    countOffsetY = 1,
}
local ENCHANTMENT_HEADER_STYLE = {
    width = 260,
    height = 18,
    firstRowGap = 4,
    backdrop = {
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    },
    backgroundColor = { 0, 0, 0, 0.7 },
    fontObject = "GameFontHighlightSmall",
    text = "ENCHANTMENTS",
}
local MAX_AURAS = 30
local HOST_PADDING = 4
local MANAGED_GROUP_GAP = 8
local AURA_GROUP_KEY = "Helpful"
local DEBUFF_AURA_GROUP_KEY = "Harmful"
local ENHANCEMENT_AURA_GROUP_KEY = "HelpfulEnhancements"
local FISHING_TOOL_SLOT_FALLBACK = 28
local FISHING_LURE_TIMER_INTERVAL = 0.1
local INITIAL_PROTOTYPE_SORT_MODE = "TIMELEFT"

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

local SAVED_SORT_MODES = {
    default = "DEFAULT",
    name = "NAME",
    timeleft = "TIMELEFT",
}

local MANAGED_GROUPS = {
    { key = "BUFFS", id = 1 },
    { key = "DEBUFFS", id = 2 },
    { key = "ENCHANTMENTS", id = 3 },
}

local function GetValidatedNumber(value, fallback, minimum, maximum)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    if minimum and value < minimum then
        return fallback
    end
    if maximum and value > maximum then
        return fallback
    end
    return value
end

local function GetValidatedInteger(value, fallback, minimum, maximum)
    value = GetValidatedNumber(value, fallback, minimum, maximum)
    value = math.floor(value + 0.5)
    if value < minimum or value > maximum then
        return fallback
    end
    return value
end

local function GetColorComponent(value, fallback)
    return GetValidatedNumber(value, fallback, 0, 1)
end

local function CopyColor(source, fallback)
    source = type(source) == "table" and source or nil
    return {
        GetColorComponent(source and source[1], fallback[1]),
        GetColorComponent(source and source[2], fallback[2]),
        GetColorComponent(source and source[3], fallback[3]),
        GetColorComponent(source and source[4], fallback[4]),
    }
end

local function CopyBackdrop(backdrop)
    return {
        bgFile = backdrop.bgFile,
        edgeFile = backdrop.edgeFile,
        edgeSize = backdrop.edgeSize,
        insets = {
            left = backdrop.insets.left,
            right = backdrop.insets.right,
            top = backdrop.insets.top,
            bottom = backdrop.insets.bottom,
        },
    }
end

local function GetGroupSettings(groupID)
    for _, settings in ipairs(OBB.db.groups or {}) do
        if type(settings) == "table" and settings.id == groupID then
            return settings
        end
    end
    return nil
end

local function BuildManagedBarStyle(settings, fallback)
    local width = GetValidatedNumber(settings and settings.width, fallback.width, 120, 500)
    local height = GetValidatedNumber(settings and settings.height, fallback.height, 12, 36)
    local fontSize = GetValidatedNumber(settings and settings.fontSize, fallback.fontSize, 8, 24)
    local iconSide = settings and settings.iconSide == "RIGHT" and "RIGHT" or "LEFT"

    return {
        width = width,
        height = height,
        fontSize = fontSize,
        countFontSize = math.max(10, fontSize - 1),
        iconSide = iconSide,
        iconTexCoords = {
            fallback.iconTexCoords[1],
            fallback.iconTexCoords[2],
            fallback.iconTexCoords[3],
            fallback.iconTexCoords[4],
        },
        iconGap = fallback.iconGap,
        namePadding = fallback.namePadding,
        durationWidth = fallback.durationWidth,
        durationRightPadding = fallback.durationRightPadding,
        nameDurationGap = fallback.nameDurationGap,
        fillColor = CopyColor(settings and settings.barColor, fallback.fillColor),
        backgroundColor = CopyColor(settings and settings.barBgColor, fallback.backgroundColor),
        countFontFlags = fallback.countFontFlags,
        countOffsetX = fallback.countOffsetX,
        countOffsetY = fallback.countOffsetY,
    }
end

local function CopyManagedBarStyle(style)
    return {
        width = style.width,
        height = style.height,
        fontSize = style.fontSize,
        countFontSize = style.countFontSize,
        iconSide = style.iconSide,
        iconTexCoords = {
            style.iconTexCoords[1],
            style.iconTexCoords[2],
            style.iconTexCoords[3],
            style.iconTexCoords[4],
        },
        iconGap = style.iconGap,
        namePadding = style.namePadding,
        durationWidth = style.durationWidth,
        durationRightPadding = style.durationRightPadding,
        nameDurationGap = style.nameDurationGap,
        fillColor = CopyColor(style.fillColor, style.fillColor),
        backgroundColor = CopyColor(style.backgroundColor, style.backgroundColor),
        countFontFlags = style.countFontFlags,
        countOffsetX = style.countOffsetX,
        countOffsetY = style.countOffsetY,
    }
end

local function BuildManagedHeaderStyle(settings, fallback, width, fallbackName)
    local name = settings and settings.name
    if type(name) ~= "string" or name == "" then
        name = fallbackName
    end

    return {
        width = width,
        height = fallback.height,
        firstRowGap = fallback.firstRowGap,
        backdrop = CopyBackdrop(fallback.backdrop),
        backgroundColor = CopyColor(fallback.backgroundColor, fallback.backgroundColor),
        fontObject = fallback.fontObject,
        text = name,
    }
end

local function BuildManagedGroupConfig(
    groupID,
    fallbackName,
    fallbackBarStyle,
    fallbackHeaderStyle,
    fallbackSpacing,
    fallbackMaxBars,
    consumeBehavior
)
    local settings = GetGroupSettings(groupID)
    local barStyle = BuildManagedBarStyle(settings, fallbackBarStyle)
    local savedSortMode = settings and SAVED_SORT_MODES[settings.sort] or nil

    return {
        barStyle = barStyle,
        headerStyle = BuildManagedHeaderStyle(settings, fallbackHeaderStyle, barStyle.width, fallbackName),
        spacing = GetValidatedNumber(settings and settings.spacing, fallbackSpacing, 0, 16),
        scale = GetValidatedNumber(settings and settings.scale, 1, 0.5, 2),
        alpha = GetValidatedNumber(settings and settings.alpha, 1, 0, 1),
        sortMode = consumeBehavior and (savedSortMode or INITIAL_PROTOTYPE_SORT_MODE) or INITIAL_PROTOTYPE_SORT_MODE,
        maxBars = consumeBehavior
            and GetValidatedInteger(settings and settings.maxBars, fallbackMaxBars, 1, 80)
            or MAX_AURAS,
    }
end

local function BuildManagedStartupConfig()
    if not OBB.db or type(OBB.db.groups) ~= "table" then
        return nil
    end

    return {
        BUFFS = BuildManagedGroupConfig(
            1,
            "BUFFS",
            BUFF_BAR_STYLE,
            BUFF_HEADER_STYLE,
            BUFF_BAR_SPACING,
            40,
            true
        ),
        DEBUFFS = BuildManagedGroupConfig(
            2,
            "DEBUFFS",
            DEBUFF_BAR_STYLE,
            DEBUFF_HEADER_STYLE,
            DEBUFF_BAR_SPACING,
            40,
            true
        ),
        -- ENCHANTMENTS keeps the validated prototype's separate TIMELEFT/30
        -- HelpfulEnhancements behavior; its saved sort/maxBars remain deferred.
        ENCHANTMENTS = BuildManagedGroupConfig(
            3,
            "ENCHANTMENTS",
            ENCHANTMENT_BAR_STYLE,
            ENCHANTMENT_HEADER_STYLE,
            ENCHANTMENT_BAR_SPACING,
            MAX_AURAS,
            false
        ),
    }
end

local function BuildCurrentBarStyles(startupConfig)
    -- Begin from the immutable startup snapshot; only explicitly supported
    -- fields advance during live apply.
    local currentStyles = {}

    for _, group in ipairs(MANAGED_GROUPS) do
        local startupGroup = startupConfig[group.key]
        local style = CopyManagedBarStyle(startupGroup.barStyle)
        style.spacing = startupGroup.spacing
        currentStyles[group.key] = style
    end

    return currentStyles
end

local function BuildLivePresentationStyle(settings, fallback, fallbackSpacing)
    local fontSize = GetValidatedNumber(settings and settings.fontSize, fallback.fontSize, 8, 24)
    return {
        width = GetValidatedNumber(settings and settings.width, fallback.width, 120, 500),
        height = GetValidatedNumber(settings and settings.height, fallback.height, 12, 36),
        spacing = GetValidatedNumber(settings and settings.spacing, fallbackSpacing, 0, 16),
        fontSize = fontSize,
        countFontSize = math.max(10, fontSize - 1),
        fillColor = CopyColor(settings and settings.barColor, fallback.fillColor),
        backgroundColor = CopyColor(settings and settings.barBgColor, fallback.backgroundColor),
    }
end

local function CopySpellIDSet(sourceSpellIDs)
    local spellIDs = {}

    for spellID, enabled in pairs(sourceSpellIDs or {}) do
        if enabled then
            spellIDs[spellID] = true
        end
    end

    return spellIDs
end

local function CompileManagedBuffCandidateFilters(filters, routedSpellIDs)
    local whitelist = filters and filters.whitelist
    local blacklist = filters and filters.blacklist
    local includeSpellIDs = {}
    local excludeSpellIDs = CopySpellIDSet(routedSpellIDs)
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

local function CompileManagedEnhancementCandidateFilters(routedSpellIDs)
    return {
        includeSpellIDs = CopySpellIDSet(routedSpellIDs),
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

function ManagedPrototype:RefreshCandidateFilters(routedSpellIDs)
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    if not self.container or not self.container.SetAuraGroupCandidateFilters then
        return false
    end
    if not self.enchantmentContainer or not self.enchantmentContainer.SetAuraGroupCandidateFilters then
        return false
    end

    local buffCandidateFilters = CompileManagedBuffCandidateFilters(GetLegacyBuffFilters(), routedSpellIDs)
    local enhancementCandidateFilters = CompileManagedEnhancementCandidateFilters(routedSpellIDs)
    self.container:SetAuraGroupCandidateFilters(AURA_GROUP_KEY, buffCandidateFilters)
    self.enchantmentContainer:SetAuraGroupCandidateFilters(
        ENHANCEMENT_AURA_GROUP_KEY,
        enhancementCandidateFilters
    )
    return true
end

local function IsReadableDiagnosticValue(value)
    local isSecretValue = _G.issecretvalue
    if isSecretValue then
        local success, secret = pcall(isSecretValue, value)
        if not success or secret then
            return false
        end
    end

    local canAccessValue = _G.canaccessvalue
    if canAccessValue then
        local success, canAccess = pcall(canAccessValue, value)
        if not success or not canAccess then
            return false
        end
    end

    return value ~= nil
end

local function FormatDiagnosticValue(value)
    if not IsReadableDiagnosticValue(value) then
        return "<unavailable>"
    end

    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then
        return tostring(value)
    end

    return "<" .. valueType .. ">"
end

local function PrintDiagnostic(message)
    print("|cff66ccffOBB managed tooltip|r: " .. message)
end

local MANAGED_DEBUG = false

local function DebugPrint(message)
    if not MANAGED_DEBUG then
        return
    end
    PrintDiagnostic(message)
end

local function CallDiagnosticAPI(apiTable, apiName, ...)
    if type(apiTable) ~= "table" or type(apiTable[apiName]) ~= "function" then
        return false
    end

    return pcall(apiTable[apiName], ...)
end

local function GetNormalizedSpellMetadataText(spellAPI, apiName, spellID)
    local success, value = CallDiagnosticAPI(spellAPI, apiName, spellID)
    if not success or not IsReadableDiagnosticValue(value) or type(value) ~= "string" then
        return nil
    end

    local normalizeSuccess, normalizedValue = pcall(string.lower, value)
    if not normalizeSuccess
        or not IsReadableDiagnosticValue(normalizedValue)
        or type(normalizedValue) ~= "string"
    then
        return nil
    end

    return normalizedValue
end

local function HasSemanticMarker(nameText, descriptionText, marker)
    if nameText and string.find(nameText, marker, 1, true) then
        return true
    end
    if descriptionText and string.find(descriptionText, marker, 1, true) then
        return true
    end

    return false
end

function ManagedPrototype.ClassifyHelpfulEnhancement(spellID)
    if not IsReadableDiagnosticValue(spellID) or type(spellID) ~= "number" then
        return nil
    end

    local spellAPI = _G.C_Spell
    if type(spellAPI) ~= "table" then
        return nil
    end

    local nameText = GetNormalizedSpellMetadataText(spellAPI, "GetSpellName", spellID)
    local descriptionText = GetNormalizedSpellMetadataText(spellAPI, "GetSpellDescription", spellID)

    if HasSemanticMarker(nameText, descriptionText, "well fed") then
        return "FOOD"
    end
    if HasSemanticMarker(nameText, descriptionText, "flask")
        or HasSemanticMarker(nameText, descriptionText, "phial")
    then
        return "FLASK_PHIAL"
    end
    if HasSemanticMarker(nameText, descriptionText, "augment rune") then
        return "AUGMENT_RUNE"
    end
    if HasSemanticMarker(nameText, descriptionText, "bobber") then
        return "FISHING_BOBBER"
    end

    return nil
end

function ManagedPrototype.DumpHelpfulEnhancementClassifications()
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        PrintDiagnostic("run this classification diagnostic out of combat")
        return
    end

    local auraSuccess, auras = CallDiagnosticAPI(
        _G.C_UnitAuras,
        "GetUnitAuras",
        "player",
        "HELPFUL"
    )
    if not auraSuccess or not IsReadableDiagnosticValue(auras) or type(auras) ~= "table" then
        PrintDiagnostic("readable player HELPFUL auras are unavailable")
        return
    end

    for _, auraData in ipairs(auras) do
        local spellID
        local auraName
        local classification

        if IsReadableDiagnosticValue(auraData) and type(auraData) == "table" then
            spellID = auraData.spellId
            auraName = auraData.name

            if IsReadableDiagnosticValue(spellID) and type(spellID) == "number" then
                local classificationSuccess
                classificationSuccess, classification = pcall(
                    ManagedPrototype.ClassifyHelpfulEnhancement,
                    spellID
                )
                if not classificationSuccess
                    or not IsReadableDiagnosticValue(classification)
                    or type(classification) ~= "string"
                then
                    classification = nil
                end
            end
        end

        PrintDiagnostic(
            "HELPFUL aura spellID=" .. FormatDiagnosticValue(spellID)
                .. " auraName=" .. FormatDiagnosticValue(auraName)
                .. " classification=" .. (classification or "nil")
        )
    end
end

local function IsRoutedHelpfulEnhancementClassification(classification)
    return classification == "FOOD"
        or classification == "FLASK_PHIAL"
        or classification == "AUGMENT_RUNE"
        or classification == "FISHING_BOBBER"
end

local function CollectDiscoveredHelpfulEnhancements(auras, printDetails)
    local discoveredSpellIDs = {}
    local discoveredSpellIDList = {}

    for _, auraData in ipairs(auras) do
        if IsReadableDiagnosticValue(auraData) and type(auraData) == "table" then
            local spellID = auraData.spellId
            if IsReadableDiagnosticValue(spellID) and type(spellID) == "number" then
                local classificationSuccess, classification = pcall(
                    ManagedPrototype.ClassifyHelpfulEnhancement,
                    spellID
                )
                if not classificationSuccess then
                    PrintDiagnostic("classification failed for spellID=" .. spellID)
                    return nil, nil
                end

                if IsReadableDiagnosticValue(classification)
                    and IsRoutedHelpfulEnhancementClassification(classification)
                then
                    if printDetails then
                        PrintDiagnostic(
                            "classified HELPFUL aura spellID=" .. spellID
                                .. " auraName=" .. FormatDiagnosticValue(auraData.name)
                                .. " classification=" .. classification
                        )
                    end
                    if not discoveredSpellIDs[spellID] then
                        discoveredSpellIDs[spellID] = true
                        discoveredSpellIDList[#discoveredSpellIDList + 1] = spellID
                    end
                end
            end
        end
    end

    return discoveredSpellIDs, discoveredSpellIDList
end

local automaticDiscoveryFrame
local automaticDiscoveryPending
local lastAppliedHelpfulEnhancementSpellIDs

local function AreSpellIDSetsEqual(leftSpellIDs, rightSpellIDs)
    if leftSpellIDs == nil or rightSpellIDs == nil then
        return false
    end

    for spellID, enabled in pairs(leftSpellIDs) do
        if enabled and not rightSpellIDs[spellID] then
            return false
        end
    end

    for spellID, enabled in pairs(rightSpellIDs) do
        if enabled and not leftSpellIDs[spellID] then
            return false
        end
    end

    return true
end

local function SetAutomaticHelpfulEnhancementDiscoveryPending(pending)
    automaticDiscoveryPending = pending or nil
    if not automaticDiscoveryFrame then
        return
    end

    if automaticDiscoveryPending then
        automaticDiscoveryFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        automaticDiscoveryFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end

local function RunHelpfulEnhancementDiscovery(printDetails)
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        return false, nil, "combat lockdown"
    end

    local auraSuccess, auras = CallDiagnosticAPI(
        _G.C_UnitAuras,
        "GetUnitAuras",
        "player",
        "HELPFUL"
    )
    if not auraSuccess or not IsReadableDiagnosticValue(auras) or type(auras) ~= "table" then
        return false, nil, "readable player HELPFUL auras are unavailable"
    end

    local discoverySuccess, discoveredSpellIDs, discoveredSpellIDList = pcall(
        CollectDiscoveredHelpfulEnhancements,
        auras,
        printDetails
    )
    if not discoverySuccess
        or type(discoveredSpellIDs) ~= "table"
        or type(discoveredSpellIDList) ~= "table"
    then
        return false, nil, "HELPFUL aura discovery failed"
    end

    if printDetails then
        PrintDiagnostic("final discovered routing set count=" .. #discoveredSpellIDList)
        for index, spellID in ipairs(discoveredSpellIDList) do
            PrintDiagnostic("routing set line=" .. index .. " spellID=" .. spellID)
        end
    end

    if AreSpellIDSetsEqual(lastAppliedHelpfulEnhancementSpellIDs, discoveredSpellIDs) then
        return true, #discoveredSpellIDList, nil, false
    end

    local applySuccess, applied = pcall(
        ManagedPrototype.RefreshCandidateFilters,
        ManagedPrototype,
        discoveredSpellIDs
    )
    if not applySuccess or not applied then
        return false, nil, "managed filter application failed"
    end

    lastAppliedHelpfulEnhancementSpellIDs = CopySpellIDSet(discoveredSpellIDs)
    return true, #discoveredSpellIDList, nil, true
end

function ManagedPrototype.DiscoverAndApplyHelpfulEnhancementRouting()
    local success, discoveredCount, failureReason, routingChanged = RunHelpfulEnhancementDiscovery(true)
    if not success then
        SetAutomaticHelpfulEnhancementDiscoveryPending(true)
        PrintDiagnostic("routing not applied: " .. failureReason)
        return false
    end

    SetAutomaticHelpfulEnhancementDiscoveryPending(false)
    if routingChanged then
        PrintDiagnostic(
            "routing application succeeded for " .. discoveredCount
                .. " discovered HELPFUL enhancement spell IDs"
        )
    else
        PrintDiagnostic(
            "routing already synchronized for " .. discoveredCount
                .. " discovered HELPFUL enhancement spell IDs"
        )
    end
    return true
end

local function AttemptAutomaticHelpfulEnhancementDiscovery(reason, reportUnchangedSynchronization)
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        if not automaticDiscoveryPending then
            DebugPrint("automatic routing deferred reason=" .. reason .. " combat lockdown")
        end
        SetAutomaticHelpfulEnhancementDiscoveryPending(true)
        return
    end

    local success, discoveredCount, failureReason, routingChanged = RunHelpfulEnhancementDiscovery(false)
    if not success then
        SetAutomaticHelpfulEnhancementDiscoveryPending(true)
        local message = "automatic routing deferred reason=" .. reason .. " " .. failureReason
        if failureReason == "readable player HELPFUL auras are unavailable" then
            DebugPrint(message)
        else
            PrintDiagnostic(message)
        end
        return
    end

    SetAutomaticHelpfulEnhancementDiscoveryPending(false)
    if not routingChanged then
        if reportUnchangedSynchronization then
            DebugPrint(
                "automatic routing synchronized reason=" .. reason
                    .. " discoveredSpellIDs=" .. discoveredCount
            )
        end
        return
    end

    DebugPrint(
        "automatic routing succeeded reason=" .. reason
            .. " discoveredSpellIDs=" .. discoveredCount
    )
end

local fishingLureEventFrame
local fishingLureRefreshPending
local RefreshFishingLureRow

local function SetFishingLureRefreshPending(pending)
    fishingLureRefreshPending = pending or nil
    if not fishingLureEventFrame then
        return
    end

    if fishingLureRefreshPending then
        fishingLureEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        fishingLureEventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end

local function ResolveFishingToolSlot()
    local tradeSkillAPI = _G.C_TradeSkillUI
    local enum = _G.Enum
    if type(tradeSkillAPI) ~= "table"
        or type(enum) ~= "table"
        or type(enum.Profession) ~= "table"
        or enum.Profession.Fishing == nil
    then
        return nil, "fishing profession API unavailable"
    end

    local slotsSuccess, fishingSlots = CallDiagnosticAPI(
        tradeSkillAPI,
        "GetProfessionSlots",
        enum.Profession.Fishing
    )
    if not slotsSuccess or not IsReadableDiagnosticValue(fishingSlots) or type(fishingSlots) ~= "table" then
        return nil, "fishing profession slots unavailable"
    end

    local fallbackAvailable
    local professionToolInventoryType = enum.InventoryType and enum.InventoryType.IndexProfessionToolType
    local itemAPI = _G.C_Item
    local getInventoryItemID = _G.GetInventoryItemID

    for _, inventorySlot in ipairs(fishingSlots) do
        if IsReadableDiagnosticValue(inventorySlot) and type(inventorySlot) == "number" then
            if inventorySlot == FISHING_TOOL_SLOT_FALLBACK then
                fallbackAvailable = true
            end

            if professionToolInventoryType ~= nil
                and type(itemAPI) == "table"
                and type(getInventoryItemID) == "function"
            then
                local itemSuccess, itemID = pcall(getInventoryItemID, "player", inventorySlot)
                if itemSuccess and IsReadableDiagnosticValue(itemID) then
                    local inventoryTypeSuccess, inventoryType = CallDiagnosticAPI(
                        itemAPI,
                        "GetItemInventoryTypeByID",
                        itemID
                    )
                    if inventoryTypeSuccess
                        and IsReadableDiagnosticValue(inventoryType)
                        and inventoryType == professionToolInventoryType
                    then
                        return inventorySlot, "profession-tool inventory type"
                    end
                end
            end
        end
    end

    -- Blizzard_ProfessionsCrafting.xml names slot 28 FishingToolSlot. Only use
    -- that source-backed fallback when the public fishing-slot API also returns it.
    if fallbackAvailable then
        return FISHING_TOOL_SLOT_FALLBACK, "source-backed fishing-tool fallback"
    end

    return nil, "fishing tool slot not found"
end

local function FormatFishingLureRemainingTime(remainingSeconds)
    local engine = OBB.Engine
    if not engine or type(engine.FormatWeaponEnchantTime) ~= "function" then
        return ""
    end

    local success, text = pcall(engine.FormatWeaponEnchantTime, engine, remainingSeconds)
    if success and IsReadableDiagnosticValue(text) and type(text) == "string" then
        return text
    end

    return ""
end

local function HideFishingLureRow(row)
    row.expirationRefreshGeneration = (row.expirationRefreshGeneration or 0) + 1
    row:SetScript("OnUpdate", nil)
    row.timerElapsed = nil
    row.inventorySlot = nil
    row.enchantID = nil
    row.remainingTimeMs = nil
    row.chargesRemaining = nil
    row.hasExpirationTime = nil
    row.expirationTime = nil
    row.durationSeconds = nil
    row:Hide()
end

local function ScheduleFishingLureExpirationRefresh(row, remainingSeconds)
    row.expirationRefreshGeneration = (row.expirationRefreshGeneration or 0) + 1
    local generation = row.expirationRefreshGeneration
    local timerAPI = _G.C_Timer
    if type(timerAPI) ~= "table" or type(timerAPI.After) ~= "function" then
        return
    end

    timerAPI.After(remainingSeconds + FISHING_LURE_TIMER_INTERVAL, function()
        if row.expirationRefreshGeneration ~= generation or not row:IsShown() then
            return
        end
        RefreshFishingLureRow("expected expiration")
    end)
end

local function UpdateFishingLureTimer(row, elapsed)
    row.timerElapsed = (row.timerElapsed or 0) + elapsed
    if row.timerElapsed < FISHING_LURE_TIMER_INTERVAL then
        return
    end
    row.timerElapsed = 0

    if not row.expirationTime then
        return
    end

    local getTime = _G.GetTime
    if type(getTime) ~= "function" then
        return
    end

    local remainingSeconds = math.max(0, row.expirationTime - getTime())
    row.durationBar:SetValue(remainingSeconds)
    row.durationText:SetText(FormatFishingLureRemainingTime(remainingSeconds))
end

local function ShowFishingLureRow(row, inventorySlot, enchantInfo, iconTexture)
    local getTime = _G.GetTime
    if type(getTime) ~= "function" then
        return false
    end

    local enchantID = enchantInfo.enchantID
    local remainingTimeMs = enchantInfo.remainingTimeMs
    local chargesRemaining = enchantInfo.chargesRemaining
    local hasExpirationTime = enchantInfo.hasExpirationTime
    if not IsReadableDiagnosticValue(enchantID)
        or type(enchantID) ~= "number"
        or not IsReadableDiagnosticValue(remainingTimeMs)
        or type(remainingTimeMs) ~= "number"
        or remainingTimeMs < 0
        or not IsReadableDiagnosticValue(chargesRemaining)
        or type(chargesRemaining) ~= "number"
        or not IsReadableDiagnosticValue(hasExpirationTime)
        or type(hasExpirationTime) ~= "boolean"
    then
        return false
    end

    local remainingSeconds = remainingTimeMs / 1000
    local expirationTime = hasExpirationTime and (getTime() + remainingSeconds) or nil
    local enchantChanged = row.enchantID ~= enchantID
    local expirationKindChanged = row.hasExpirationTime ~= nil
        and row.hasExpirationTime ~= hasExpirationTime
    local remainingIncreased = row.remainingTimeMs ~= nil
        and remainingTimeMs > row.remainingTimeMs
    local expirationExtended = expirationTime
        and row.expirationTime
        and expirationTime > row.expirationTime + 1

    if enchantChanged
        or not row.durationSeconds
        or expirationKindChanged
        or remainingIncreased
        or expirationExtended
    then
        row.durationSeconds = remainingSeconds
    end

    row.inventorySlot = inventorySlot
    row.enchantID = enchantID
    row.remainingTimeMs = remainingTimeMs
    row.chargesRemaining = chargesRemaining
    row.hasExpirationTime = hasExpirationTime
    row.expirationTime = expirationTime
    row.icon:SetTexture(iconTexture or _G.QUESTION_MARK_ICON)
    row.countText:SetText(chargesRemaining > 0 and tostring(chargesRemaining) or "")

    if expirationTime and remainingSeconds > 0 then
        row.durationBar:SetMinMaxValues(0, math.max(row.durationSeconds, 1))
        row.durationBar:SetValue(remainingSeconds)
        row.durationText:SetText(FormatFishingLureRemainingTime(remainingSeconds))
        row.timerElapsed = 0
        row:SetScript("OnUpdate", UpdateFishingLureTimer)
        ScheduleFishingLureExpirationRefresh(row, remainingSeconds)
    else
        row.expirationRefreshGeneration = (row.expirationRefreshGeneration or 0) + 1
        row.durationBar:SetMinMaxValues(0, 1)
        row.durationBar:SetValue(0)
        row.durationText:SetText("")
        row:SetScript("OnUpdate", nil)
    end

    row:Show()
    return true
end

RefreshFishingLureRow = function(_reason)
    local row = ManagedPrototype.fishingLureRow
    if not row then
        return false
    end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        SetFishingLureRefreshPending(true)
        return false
    end

    local inventorySlot, resolution = ResolveFishingToolSlot()
    ManagedPrototype.fishingToolSlot = inventorySlot
    ManagedPrototype.fishingToolSlotResolution = resolution
    if not inventorySlot then
        HideFishingLureRow(row)
        SetFishingLureRefreshPending(false)
        return true
    end

    local enchantSuccess, enchantInfo = CallDiagnosticAPI(
        _G.C_PaperDollInfo,
        "GetTemporaryEnchantmentInfo",
        inventorySlot
    )
    if not enchantSuccess then
        return false
    end
    if enchantInfo == nil then
        HideFishingLureRow(row)
        SetFishingLureRefreshPending(false)
        return true
    end
    if not IsReadableDiagnosticValue(enchantInfo) or type(enchantInfo) ~= "table" then
        return false
    end

    local iconTexture
    local getInventoryItemTexture = _G.GetInventoryItemTexture
    if type(getInventoryItemTexture) == "function" then
        local iconSuccess, resolvedIcon = pcall(getInventoryItemTexture, "player", inventorySlot)
        if iconSuccess then
            iconTexture = resolvedIcon
        end
    end

    local shown = ShowFishingLureRow(row, inventorySlot, enchantInfo, iconTexture)
    if shown then
        SetFishingLureRefreshPending(false)
    end
    return shown
end

function ManagedPrototype.DumpFishingLureState()
    local refreshState
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        SetFishingLureRefreshPending(true)
        refreshState = "deferred-combat"
    else
        refreshState = RefreshFishingLureRow("manual diagnostic") and "refreshed" or "refresh-failed"
    end

    local row = ManagedPrototype.fishingLureRow
    PrintDiagnostic(
        "fishing lure refresh=" .. refreshState
            .. " toolSlot=" .. FormatDiagnosticValue(ManagedPrototype.fishingToolSlot)
            .. " slotResolution=" .. FormatDiagnosticValue(ManagedPrototype.fishingToolSlotResolution)
            .. " enchantID=" .. FormatDiagnosticValue(row and row.enchantID)
            .. " remainingTimeMs=" .. FormatDiagnosticValue(row and row.remainingTimeMs)
            .. " chargesRemaining=" .. FormatDiagnosticValue(row and row.chargesRemaining)
            .. " hasExpirationTime=" .. FormatDiagnosticValue(row and row.hasExpirationTime)
            .. " rowState=" .. ((row and row:IsShown()) and "visible" or "hidden")
    )
end

local function PrintSpellScalar(spellAPI, apiName, fieldName, spellID)
    local success, value = CallDiagnosticAPI(spellAPI, apiName, spellID)
    if not success then
        PrintDiagnostic(fieldName .. "=<unavailable>")
        return
    end

    PrintDiagnostic(fieldName .. "=" .. FormatDiagnosticValue(value))
end

local function PrintAuraStatChanges(spellAPI, spellID)
    local success, healthChange, powerTypeChanges = CallDiagnosticAPI(
        spellAPI,
        "GetAuraStatChanges",
        spellID
    )
    if not success then
        PrintDiagnostic("auraStatChanges=<unavailable>")
        return
    end

    PrintDiagnostic("auraStatHealthChange=" .. FormatDiagnosticValue(healthChange))
    if not IsReadableDiagnosticValue(powerTypeChanges) or type(powerTypeChanges) ~= "table" then
        PrintDiagnostic("auraStatPowerTypeChanges=<unavailable>")
        return
    end

    if #powerTypeChanges == 0 then
        PrintDiagnostic("auraStatPowerTypeChanges=<none>")
        return
    end

    for index, powerTypeChange in ipairs(powerTypeChanges) do
        if IsReadableDiagnosticValue(powerTypeChange) and type(powerTypeChange) == "table" then
            PrintDiagnostic(
                "auraStatPowerTypeChange=" .. index
                    .. " powerType=" .. FormatDiagnosticValue(powerTypeChange.powerType)
                    .. " amount=" .. FormatDiagnosticValue(powerTypeChange.amount)
            )
        else
            PrintDiagnostic("auraStatPowerTypeChange=" .. index .. " data=<unavailable>")
        end
    end
end

local function InspectKnownSpellMetadata(spellID)
    local spellAPI = _G.C_Spell
    PrintDiagnostic("===== spell metadata spellID=" .. spellID .. " =====")
    if type(spellAPI) ~= "table" then
        PrintDiagnostic("C_Spell=<unavailable>")
        return
    end

    PrintSpellScalar(spellAPI, "DoesSpellExist", "exists", spellID)
    PrintSpellScalar(spellAPI, "IsSpellDataCached", "dataCached", spellID)
    PrintSpellScalar(spellAPI, "GetSpellName", "name", spellID)
    PrintSpellScalar(spellAPI, "GetSpellDescription", "description", spellID)
    PrintSpellScalar(spellAPI, "GetSpellSubtext", "subtext", spellID)
    PrintSpellScalar(spellAPI, "GetBaseSpell", "baseSpellID", spellID)
    PrintSpellScalar(spellAPI, "GetOverrideSpell", "overrideSpellID", spellID)

    local infoSuccess, spellInfo = CallDiagnosticAPI(spellAPI, "GetSpellInfo", spellID)
    if infoSuccess and IsReadableDiagnosticValue(spellInfo) and type(spellInfo) == "table" then
        PrintDiagnostic(
            "spellInfo"
                .. " name=" .. FormatDiagnosticValue(spellInfo.name)
                .. " spellID=" .. FormatDiagnosticValue(spellInfo.spellID)
                .. " iconID=" .. FormatDiagnosticValue(spellInfo.iconID)
                .. " originalIconID=" .. FormatDiagnosticValue(spellInfo.originalIconID)
                .. " castTime=" .. FormatDiagnosticValue(spellInfo.castTime)
                .. " minRange=" .. FormatDiagnosticValue(spellInfo.minRange)
                .. " maxRange=" .. FormatDiagnosticValue(spellInfo.maxRange)
        )
    else
        PrintDiagnostic("spellInfo=<unavailable>")
    end

    local textureSuccess, iconID, originalIconID, conditionalIconID = CallDiagnosticAPI(
        spellAPI,
        "GetSpellTexture",
        spellID
    )
    if textureSuccess then
        PrintDiagnostic(
            "spellTexture"
                .. " iconID=" .. FormatDiagnosticValue(iconID)
                .. " originalIconID=" .. FormatDiagnosticValue(originalIconID)
                .. " conditionalIconID=" .. FormatDiagnosticValue(conditionalIconID)
        )
    else
        PrintDiagnostic("spellTexture=<unavailable>")
    end

    PrintAuraStatChanges(spellAPI, spellID)
    PrintSpellScalar(spellAPI, "GetSpellLevelLearned", "levelLearned", spellID)
    PrintSpellScalar(spellAPI, "GetSpellSkillLineAbilityRank", "skillLineRank", spellID)
    PrintSpellScalar(
        spellAPI,
        "GetSpellMaxCumulativeAuraApplications",
        "maxCumulativeAuraApplications",
        spellID
    )
    PrintSpellScalar(spellAPI, "IsConsumableSpell", "isConsumableSpell", spellID)
    PrintSpellScalar(spellAPI, "IsClassTalentSpell", "isClassTalentSpell", spellID)
    PrintSpellScalar(spellAPI, "IsPvPTalentSpell", "isPvPTalentSpell", spellID)
    PrintSpellScalar(spellAPI, "IsExternalDefensive", "isExternalDefensive", spellID)
    PrintSpellScalar(spellAPI, "IsPriorityAura", "isPriorityAura", spellID)
    PrintSpellScalar(spellAPI, "IsSelfBuff", "isSelfBuff", spellID)
    PrintSpellScalar(spellAPI, "IsSpellCrowdControl", "isCrowdControl", spellID)
    PrintSpellScalar(spellAPI, "IsSpellDisabled", "isSpellDisabled", spellID)
    PrintSpellScalar(spellAPI, "IsSpellHarmful", "isSpellHarmful", spellID)
    PrintSpellScalar(spellAPI, "IsSpellHelpful", "isSpellHelpful", spellID)
    PrintSpellScalar(spellAPI, "IsSpellImportant", "isSpellImportant", spellID)
    PrintSpellScalar(spellAPI, "IsSpellPassive", "isSpellPassive", spellID)
end

local function InspectKnownAuraTooltip(spellID)
    local unitAuras = _G.C_UnitAuras
    local tooltipInfo = _G.C_TooltipInfo
    if not unitAuras or not unitAuras.GetUnitAuraBySpellID then
        PrintDiagnostic("C_UnitAuras.GetUnitAuraBySpellID is unavailable")
        return
    end
    if not tooltipInfo or not tooltipInfo.GetUnitAuraByAuraInstanceID then
        PrintDiagnostic("C_TooltipInfo.GetUnitAuraByAuraInstanceID is unavailable")
        return
    end

    local auraSuccess, auraData = pcall(unitAuras.GetUnitAuraBySpellID, "player", spellID)
    if not auraSuccess or not IsReadableDiagnosticValue(auraData) or type(auraData) ~= "table" then
        PrintDiagnostic("spellID=" .. spellID .. " is not active or its aura data is unavailable")
        return
    end

    local isHelpful = auraData.isHelpful
    if not IsReadableDiagnosticValue(isHelpful) or not isHelpful then
        PrintDiagnostic("spellID=" .. spellID .. " is not a readable active HELPFUL aura")
        return
    end

    local auraInstanceID = auraData.auraInstanceID
    local auraName = FormatDiagnosticValue(auraData.name)
    local auraInstanceText = FormatDiagnosticValue(auraInstanceID)
    PrintDiagnostic(
        "spellID=" .. spellID .. " auraName=" .. auraName .. " auraInstanceID=" .. auraInstanceText
    )

    if not IsReadableDiagnosticValue(auraInstanceID) or type(auraInstanceID) ~= "number" then
        PrintDiagnostic("tooltip unavailable because the aura instance ID is unreadable")
        return
    end

    local tooltipSuccess, tooltipData = pcall(
        tooltipInfo.GetUnitAuraByAuraInstanceID,
        "player",
        auraInstanceID,
        "HELPFUL"
    )
    if not tooltipSuccess or not IsReadableDiagnosticValue(tooltipData) or type(tooltipData) ~= "table" then
        PrintDiagnostic("tooltip data is unavailable for spellID=" .. spellID)
        return
    end

    local lines = tooltipData.lines
    if not IsReadableDiagnosticValue(lines) or type(lines) ~= "table" then
        PrintDiagnostic("tooltip lines are unavailable for spellID=" .. spellID)
        return
    end

    for lineNumber, lineData in ipairs(lines) do
        if IsReadableDiagnosticValue(lineData) and type(lineData) == "table" then
            PrintDiagnostic(
                "line=" .. lineNumber
                    .. " type=" .. FormatDiagnosticValue(lineData.type)
                    .. " leftText=" .. FormatDiagnosticValue(lineData.leftText)
                    .. " rightText=" .. FormatDiagnosticValue(lineData.rightText)
            )
        else
            PrintDiagnostic("line=" .. lineNumber .. " data=<unavailable>")
        end
    end
end

function ManagedPrototype.DumpKnownAuraTooltips()
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        PrintDiagnostic("run this diagnostic out of combat")
        return
    end

    for _, spellID in ipairs({ 1232325, 1234969, 432021 }) do
        local metadataSuccess, metadataError = pcall(InspectKnownSpellMetadata, spellID)
        if not metadataSuccess then
            PrintDiagnostic(
                "spellID=" .. spellID
                    .. " spell metadata diagnostic failed: " .. FormatDiagnosticValue(metadataError)
            )
        end

        PrintDiagnostic("----- active aura tooltip spellID=" .. spellID .. " -----")
        local tooltipSuccess, tooltipError = pcall(InspectKnownAuraTooltip, spellID)
        if not tooltipSuccess then
            PrintDiagnostic("spellID=" .. spellID .. " diagnostic failed: " .. FormatDiagnosticValue(tooltipError))
        end
    end
end

local function TrackManagedPresentation(groupKey, owner, presentation)
    local owners = ManagedPrototype.presentationOwners
        and ManagedPrototype.presentationOwners[groupKey]
    if not owners then
        return
    end

    -- Track only descendants created while the provider initializes this row;
    -- live styling never needs managed-child or aura-identity enumeration.
    owners[owner] = presentation
end

local function SetManagedFontSize(fontString, fontSize, fallbackFlags)
    local fontFace, _, fontFlags = fontString:GetFont()
    fontString:SetFont(
        fontFace or _G.STANDARD_TEXT_FONT or [[Fonts\FRIZQT__.TTF]],
        fontSize,
        fontFlags or fallbackFlags
    )
end

local function ApplyManagedPresentationStyle(presentation, style)
    SetManagedFontSize(presentation.nameText, style.fontSize, "")
    SetManagedFontSize(presentation.durationText, style.fontSize, "")
    SetManagedFontSize(presentation.countText, style.countFontSize, style.countFontFlags)
    presentation.durationBar:SetStatusBarColor(
        style.fillColor[1],
        style.fillColor[2],
        style.fillColor[3],
        style.fillColor[4]
    )
    presentation.background:SetColorTexture(
        style.backgroundColor[1],
        style.backgroundColor[2],
        style.backgroundColor[3],
        style.backgroundColor[4]
    )
end

local function ApplyManagedRowHeight(owner, presentation, style)
    local iconOffset = style.height + style.iconGap

    owner:SetHeight(style.height)
    presentation.icon:SetSize(style.height, style.height)
    if style.iconSide == "RIGHT" then
        presentation.background:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", -iconOffset, 0)
    else
        presentation.background:SetPoint("TOPLEFT", owner, "TOPLEFT", iconOffset, 0)
    end
end

local function ApplyManagedLayoutState(prototype, groupKey, style, widthChanged)
    local layout = {
        elementWidth = style.width,
        elementHeight = style.height,
        elementSpacing = style.spacing,
    }

    if groupKey == "BUFFS" then
        prototype.container:SetAuraGroupLayout(AURA_GROUP_KEY, layout)
    elseif groupKey == "DEBUFFS" then
        prototype.debuffContainer:SetAuraGroupLayout(DEBUFF_AURA_GROUP_KEY, layout)
    else
        prototype.enchantmentContainer:SetAuraGroupLayout(ENHANCEMENT_AURA_GROUP_KEY, layout)
        prototype.enchantmentContainer:SetItemEnchantmentLayout(layout)
    end

    if widthChanged then
        prototype.groupHeaders[groupKey]:SetWidth(style.width)
    end
end

function ManagedPrototype:ApplyConfiguration(_reason)
    if not self.initialized
        or not self.startupConfig
        or not self.currentBarStyles
        or not self.presentationOwners
    then
        return false, "not initialized"
    end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        return false, "combat lockdown"
    end
    if not OBB.db or type(OBB.db.groups) ~= "table" then
        return false, "database unavailable"
    end

    for _, group in ipairs(MANAGED_GROUPS) do
        local currentStyle = self.currentBarStyles[group.key]
        local startupGroup = self.startupConfig[group.key]
        local liveStyle = BuildLivePresentationStyle(
            GetGroupSettings(group.id),
            startupGroup.barStyle,
            startupGroup.spacing
        )
        local widthChanged = currentStyle.width ~= liveStyle.width
        local heightChanged = currentStyle.height ~= liveStyle.height
        local spacingChanged = currentStyle.spacing ~= liveStyle.spacing

        currentStyle.width = liveStyle.width
        currentStyle.height = liveStyle.height
        currentStyle.spacing = liveStyle.spacing
        currentStyle.fontSize = liveStyle.fontSize
        currentStyle.countFontSize = liveStyle.countFontSize
        currentStyle.fillColor = liveStyle.fillColor
        currentStyle.backgroundColor = liveStyle.backgroundColor

        for owner, presentation in pairs(self.presentationOwners[group.key]) do
            if widthChanged then
                owner:SetWidth(currentStyle.width)
            end
            if heightChanged then
                ApplyManagedRowHeight(owner, presentation, currentStyle)
            end
            ApplyManagedPresentationStyle(presentation, currentStyle)
        end
        if widthChanged or heightChanged or spacingChanged then
            ApplyManagedLayoutState(self, group.key, currentStyle, widthChanged)
        end
        if group.key == "ENCHANTMENTS" and spacingChanged then
            self.fishingLureRow:SetPoint(
                "TOPLEFT",
                self.enchantmentContainer,
                "BOTTOMLEFT",
                0,
                -currentStyle.spacing
            )
        end
    end

    return true
end

local function ApplyManagedBarGeometry(row, background, durationBar, icon, style)
    local iconOffset = style.height + style.iconGap
    if style.iconSide == "RIGHT" then
        icon:SetPoint("RIGHT", row, "RIGHT")
        background:SetPoint("TOPLEFT", row, "TOPLEFT")
        background:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -iconOffset, 0)
    else
        icon:SetPoint("LEFT", row, "LEFT")
        background:SetPoint("TOPLEFT", row, "TOPLEFT", iconOffset, 0)
        background:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT")
    end
    durationBar:SetPoint("TOPLEFT", background, "TOPLEFT")
    durationBar:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT")
end

local function InitializeManagedBarPresentation(auraButton, style, groupKey)
    auraButton:SetSize(style.width, style.height)

    local background = auraButton:CreateTexture(nil, "BACKGROUND")
    background:SetColorTexture(
        style.backgroundColor[1],
        style.backgroundColor[2],
        style.backgroundColor[3],
        style.backgroundColor[4]
    )

    local durationBar = CreateFrame("StatusBar", nil, auraButton)
    durationBar:SetFrameLevel(auraButton:GetFrameLevel() + 1)
    durationBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    durationBar:SetStatusBarColor(
        style.fillColor[1],
        style.fillColor[2],
        style.fillColor[3],
        style.fillColor[4]
    )

    local icon = auraButton:CreateTexture(nil, "ARTWORK")
    icon:SetSize(style.height, style.height)
    icon:SetTexCoord(
        style.iconTexCoords[1],
        style.iconTexCoords[2],
        style.iconTexCoords[3],
        style.iconTexCoords[4]
    )
    ApplyManagedBarGeometry(auraButton, background, durationBar, icon, style)

    local textLayer = CreateFrame("Frame", nil, auraButton)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(durationBar:GetFrameLevel() + 1)

    local font = _G.STANDARD_TEXT_FONT or [[Fonts\FRIZQT__.TTF]]
    local nameText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetFont(font, style.fontSize, "")
    nameText:SetPoint("LEFT", background, "LEFT", style.namePadding, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetWordWrap(false)

    local durationText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    durationText:SetFont(font, style.fontSize, "")
    durationText:SetPoint("RIGHT", background, "RIGHT", -style.durationRightPadding, 0)
    durationText:SetWidth(style.durationWidth)
    durationText:SetJustifyH("RIGHT")
    durationText:SetJustifyV("MIDDLE")
    durationText:SetWordWrap(false)

    nameText:SetPoint("RIGHT", durationText, "LEFT", -style.nameDurationGap, 0)

    local countText = textLayer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    countText:SetFont(font, style.countFontSize, style.countFontFlags)
    countText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", style.countOffsetX, style.countOffsetY)
    countText:SetJustifyH("RIGHT")
    countText:SetJustifyV("BOTTOM")

    auraButton:SetIcon(icon)
    auraButton:SetSpellName(nameText)
    auraButton:SetApplicationCount(countText)
    auraButton:SetDurationText(durationText)
    auraButton:SetDurationBar(durationBar, {
        direction = Enum.StatusBarTimerDirection.RemainingTime,
    })
    TrackManagedPresentation(groupKey, auraButton, {
        background = background,
        durationBar = durationBar,
        icon = icon,
        nameText = nameText,
        durationText = durationText,
        countText = countText,
    })
end

local function InitializeAuraButton(auraButton)
    InitializeManagedBarPresentation(auraButton, ManagedPrototype.currentBarStyles.BUFFS, "BUFFS")
    auraButton:SetCancelAuraButtons("RightButtonDown")
end

local function CreateFishingLureRow(host, container)
    local style = ManagedPrototype.currentBarStyles.ENCHANTMENTS
    local row = _G.CreateFrame("Button", "OdysseusBuffBarsManagedFishingLureRow", host)
    row:SetSize(style.width, style.height)
    row:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -style.spacing)
    row:Hide()

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetColorTexture(
        style.backgroundColor[1],
        style.backgroundColor[2],
        style.backgroundColor[3],
        style.backgroundColor[4]
    )

    local durationBar = _G.CreateFrame("StatusBar", nil, row)
    durationBar:SetFrameLevel(row:GetFrameLevel() + 1)
    durationBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    durationBar:SetStatusBarColor(
        style.fillColor[1],
        style.fillColor[2],
        style.fillColor[3],
        style.fillColor[4]
    )

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(style.height, style.height)
    icon:SetTexCoord(
        style.iconTexCoords[1],
        style.iconTexCoords[2],
        style.iconTexCoords[3],
        style.iconTexCoords[4]
    )
    ApplyManagedBarGeometry(row, background, durationBar, icon, style)

    local textLayer = _G.CreateFrame("Frame", nil, row)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(durationBar:GetFrameLevel() + 1)

    local font = _G.STANDARD_TEXT_FONT or [[Fonts\FRIZQT__.TTF]]
    local nameText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetFont(font, style.fontSize, "")
    nameText:SetPoint("LEFT", background, "LEFT", style.namePadding, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetWordWrap(false)
    nameText:SetText("Fishing Lure")

    local durationText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    durationText:SetFont(font, style.fontSize, "")
    durationText:SetPoint("RIGHT", background, "RIGHT", -style.durationRightPadding, 0)
    durationText:SetWidth(style.durationWidth)
    durationText:SetJustifyH("RIGHT")
    durationText:SetJustifyV("MIDDLE")
    durationText:SetWordWrap(false)

    nameText:SetPoint("RIGHT", durationText, "LEFT", -style.nameDurationGap, 0)

    local countText = textLayer:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    countText:SetFont(font, style.countFontSize, style.countFontFlags)
    countText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", style.countOffsetX, style.countOffsetY)
    countText:SetJustifyH("RIGHT")
    countText:SetJustifyV("BOTTOM")

    row.icon = icon
    row.durationBar = durationBar
    row.durationText = durationText
    row.countText = countText
    TrackManagedPresentation("ENCHANTMENTS", row, {
        background = background,
        durationBar = durationBar,
        icon = icon,
        nameText = nameText,
        durationText = durationText,
        countText = countText,
    })
    row:SetScript("OnEnter", function(self)
        local tooltip = _G.GameTooltip
        if not self.inventorySlot or not tooltip or type(tooltip.SetInventoryItem) ~= "function" then
            return
        end

        tooltip:SetOwner(_G.UIParent, "ANCHOR_CURSOR")
        local success = pcall(tooltip.SetInventoryItem, tooltip, "player", self.inventorySlot)
        if not success then
            tooltip:Hide()
        end
    end)
    row:SetScript("OnLeave", function()
        if _G.GameTooltip then
            _G.GameTooltip:Hide()
        end
    end)

    return row
end

local function CreateFishingLureEventFrame()
    local eventFrame = _G.CreateFrame("Frame")
    local inventoryGeneration = 0
    local inventoryCheckPending

    local function ScheduleInventoryQuietTurn()
        if inventoryCheckPending then
            return
        end

        inventoryCheckPending = true
        local scheduledGeneration = inventoryGeneration
        _G.C_Timer.After(0, function()
            inventoryCheckPending = nil
            if inventoryGeneration ~= scheduledGeneration then
                ScheduleInventoryQuietTurn()
                return
            end
            RefreshFishingLureRow("UNIT_INVENTORY_CHANGED player quiet turn")
        end)
    end

    fishingLureEventFrame = eventFrame
    ManagedPrototype.fishingLureEventFrame = eventFrame
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
    eventFrame:RegisterEvent("PROFESSION_EQUIPMENT_CHANGED")
    eventFrame:SetScript("OnEvent", function(_, event, eventArg1, eventArg2)
        if event == "PLAYER_ENTERING_WORLD" then
            RefreshFishingLureRow("PLAYER_ENTERING_WORLD")
        elseif event == "UNIT_INVENTORY_CHANGED" and eventArg1 == "player" then
            inventoryGeneration = inventoryGeneration + 1
            ScheduleInventoryQuietTurn()
        elseif event == "PROFESSION_EQUIPMENT_CHANGED" and eventArg2 then
            RefreshFishingLureRow("PROFESSION_EQUIPMENT_CHANGED tool")
        elseif event == "PLAYER_REGEN_ENABLED" and fishingLureRefreshPending then
            RefreshFishingLureRow("PLAYER_REGEN_ENABLED")
        end
    end)
end

local function StyleManagedGroupHeader(header, style)
    header:SetSize(style.width, style.height)
    header:SetBackdrop(style.backdrop)
    header:SetBackdropColor(
        style.backgroundColor[1],
        style.backgroundColor[2],
        style.backgroundColor[3],
        style.backgroundColor[4]
    )

    local label = header:CreateFontString(nil, "OVERLAY", style.fontObject)
    label:SetAllPoints(header)
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    label:SetText(style.text)
end

local function CreateManagedAuraPrototype()
    local groupConfig = ManagedPrototype.startupConfig.BUFFS
    local barStyle = groupConfig.barStyle
    local headerStyle = groupConfig.headerStyle
    local host = CreateFrame("Frame", "OdysseusBuffBarsManagedPrototypeHost", UIParent)
    host:SetSize(
        headerStyle.width + (HOST_PADDING * 2),
        headerStyle.height + headerStyle.firstRowGap
    )
    host:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 24, -180)
    host:SetFrameStrata("MEDIUM")
    host:SetScale(groupConfig.scale)
    host:SetAlpha(groupConfig.alpha)
    host:SetMovable(true)
    host:SetClampedToScreen(true)
    host:Hide()

    local dragHandle = CreateFrame(
        "Button",
        nil,
        host,
        _G.BackdropTemplateMixin and "BackdropTemplate"
    )
    dragHandle:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, 0)
    StyleManagedGroupHeader(dragHandle, headerStyle)
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
    container:SetPoint(
        "TOPLEFT",
        host,
        "TOPLEFT",
        HOST_PADDING,
        -(headerStyle.height + headerStyle.firstRowGap)
    )
    container:SetSize(1, 1)
    container:SetEnabled(false)
    container:SetUnit("player")
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
    local activeSortMode = groupConfig.sortMode
    local activeSort = SORT_MODES[activeSortMode]
    container:AddAuraGroup(AURA_GROUP_KEY, "HELPFUL", {
        candidateFilters = CompileManagedBuffCandidateFilters(GetLegacyBuffFilters()),
        maxFrameCount = groupConfig.maxBars,
        initializeFrame = InitializeAuraButton,
        sortMethod = activeSort.method,
        sortDirection = activeSort.direction,
        layout = {
            elementWidth = barStyle.width,
            elementHeight = barStyle.height,
            elementSpacing = groupConfig.spacing,
        },
    })

    local sortButton = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    sortButton:SetSize(94, 18)
    sortButton:SetPoint("TOPRIGHT", dragHandle, "TOPRIGHT", -2, -2)
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
    ManagedPrototype.groupHeaders.BUFFS = dragHandle

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

    automaticDiscoveryFrame = filterInitFrame
    filterInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    filterInitFrame:RegisterUnitEvent("UNIT_AURA", "player")
    filterInitFrame:SetScript("OnEvent", function(_, event, eventArg1)
        if event == "PLAYER_ENTERING_WORLD" then
            local initialLogin = eventArg1
            ManagedPrototype.enchantmentContainer:UpdateAllAuras()
            AttemptAutomaticHelpfulEnhancementDiscovery("PLAYER_ENTERING_WORLD")
            if initialLogin then
                startupInventoryGeneration = 0
                startupInventoryCheckPending = nil
                filterInitFrame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
            end
        elseif event == "UNIT_AURA" then
            AttemptAutomaticHelpfulEnhancementDiscovery("UNIT_AURA player")
        elseif event == "PLAYER_REGEN_ENABLED" then
            if automaticDiscoveryPending then
                AttemptAutomaticHelpfulEnhancementDiscovery("PLAYER_REGEN_ENABLED", true)
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
    InitializeManagedBarPresentation(auraButton, ManagedPrototype.currentBarStyles.DEBUFFS, "DEBUFFS")
end

local function CreateManagedDebuffPrototype(buffContainer)
    local groupConfig = ManagedPrototype.startupConfig.DEBUFFS
    local barStyle = groupConfig.barStyle
    local headerStyle = groupConfig.headerStyle
    local host = CreateFrame(
        "Frame",
        "OdysseusBuffBarsManagedDebuffPrototypeHost",
        UIParent,
        "DisableUntrustedLayoutScriptsTemplate"
    )
    host:SetSize(
        headerStyle.width + (HOST_PADDING * 2),
        headerStyle.height + headerStyle.firstRowGap
    )
    host:SetPoint("TOPLEFT", buffContainer, "BOTTOMLEFT", -HOST_PADDING, -MANAGED_GROUP_GAP)
    host:SetFrameStrata("MEDIUM")
    host:SetScale(groupConfig.scale)
    host:SetAlpha(groupConfig.alpha)
    host:Hide()

    local header = CreateFrame(
        "Frame",
        nil,
        host,
        _G.BackdropTemplateMixin and "BackdropTemplate"
    )
    header:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, 0)
    StyleManagedGroupHeader(header, headerStyle)

    local container = CreateFrame(
        "AuraContainer",
        "OdysseusBuffBarsManagedDebuffPrototypeContainer",
        host,
        "CustomAuraContainerTemplate"
    )
    container:Hide()
    container:SetPoint(
        "TOPLEFT",
        host,
        "TOPLEFT",
        HOST_PADDING,
        -(headerStyle.height + headerStyle.firstRowGap)
    )
    container:SetSize(1, 1)
    container:SetEnabled(false)
    container:SetUnit("player")
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
    local activeSortMode = groupConfig.sortMode
    local activeSort = SORT_MODES[activeSortMode]
    container:AddAuraGroup(DEBUFF_AURA_GROUP_KEY, "HARMFUL", {
        maxFrameCount = groupConfig.maxBars,
        initializeFrame = InitializeDebuffAuraButton,
        sortMethod = activeSort.method,
        sortDirection = activeSort.direction,
        layout = {
            elementWidth = barStyle.width,
            elementHeight = barStyle.height,
            elementSpacing = groupConfig.spacing,
        },
    })

    local sortButton = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    sortButton:SetSize(94, 18)
    sortButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -2, -2)
    sortButton:SetFrameLevel(header:GetFrameLevel() + 1)
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
    ManagedPrototype.groupHeaders.DEBUFFS = header

    host:Show()
    container:Show()
    container:SetEnabled(true)
end

local function InitializeEnchantmentAuraButton(auraButton)
    InitializeManagedBarPresentation(
        auraButton,
        ManagedPrototype.currentBarStyles.ENCHANTMENTS,
        "ENCHANTMENTS"
    )
    auraButton:SetCancelAuraButtons("RightButtonDown")
end

local function CreateManagedEnchantmentPrototype(debuffContainer)
    local groupConfig = ManagedPrototype.startupConfig.ENCHANTMENTS
    local barStyle = groupConfig.barStyle
    local headerStyle = groupConfig.headerStyle
    local host = CreateFrame(
        "Frame",
        "OdysseusBuffBarsManagedEnchantmentPrototypeHost",
        UIParent,
        "DisableUntrustedLayoutScriptsTemplate"
    )
    host:SetSize(
        headerStyle.width + (HOST_PADDING * 2),
        headerStyle.height + headerStyle.firstRowGap
    )
    host:SetPoint("TOPLEFT", debuffContainer, "BOTTOMLEFT", -HOST_PADDING, -MANAGED_GROUP_GAP)
    host:SetFrameStrata("MEDIUM")
    host:SetScale(groupConfig.scale)
    host:SetAlpha(groupConfig.alpha)
    host:Hide()

    local header = CreateFrame(
        "Frame",
        nil,
        host,
        _G.BackdropTemplateMixin and "BackdropTemplate"
    )
    header:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, 0)
    StyleManagedGroupHeader(header, headerStyle)

    local container = CreateFrame(
        "AuraContainer",
        "OdysseusBuffBarsManagedEnchantmentPrototypeContainer",
        host,
        "CustomAuraContainerTemplate"
    )
    container:Hide()
    container:SetPoint(
        "TOPLEFT",
        host,
        "TOPLEFT",
        HOST_PADDING,
        -(headerStyle.height + headerStyle.firstRowGap)
    )
    container:SetSize(1, 1)
    container:SetEnabled(false)
    container:SetUnit("player")
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
    container:SetItemEnchantmentLayout({
        elementWidth = barStyle.width,
        elementHeight = barStyle.height,
        elementSpacing = groupConfig.spacing,
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
    local activeSort = SORT_MODES[groupConfig.sortMode]
    container:AddAuraGroup(ENHANCEMENT_AURA_GROUP_KEY, "HELPFUL", {
        candidateFilters = CompileManagedEnhancementCandidateFilters(),
        maxFrameCount = groupConfig.maxBars,
        initializeFrame = InitializeEnchantmentAuraButton,
        sortMethod = activeSort.method,
        sortDirection = activeSort.direction,
        layout = {
            elementWidth = barStyle.width,
            elementHeight = barStyle.height,
            elementSpacing = groupConfig.spacing,
        },
    })

    ManagedPrototype.enchantmentHost = host
    ManagedPrototype.enchantmentContainer = container
    ManagedPrototype.fishingLureRow = CreateFishingLureRow(host, container)
    ManagedPrototype.groupHeaders.ENCHANTMENTS = header

    host:Show()
    container:Show()
    container:SetEnabled(true)
    CreateFishingLureEventFrame()
    RefreshFishingLureRow("prototype initialization")
end

function ManagedPrototype:Initialize()
    if self.initialized or self.initializing then
        return self.initialized == true
    end

    local startupConfig = BuildManagedStartupConfig()
    if not startupConfig then
        return false
    end

    self.initializing = true
    self.startupConfig = startupConfig
    self.currentBarStyles = BuildCurrentBarStyles(startupConfig)
    self.groupHeaders = {}
    self.presentationOwners = {
        BUFFS = setmetatable({}, { __mode = "k" }),
        DEBUFFS = setmetatable({}, { __mode = "k" }),
        ENCHANTMENTS = setmetatable({}, { __mode = "k" }),
    }
    CreateManagedAuraPrototype()
    CreateManagedDebuffPrototype(self.container)
    CreateManagedEnchantmentPrototype(self.debuffContainer)
    self:RefreshCandidateFilters()
    self.initializing = nil
    self.initialized = true
    return true
end
