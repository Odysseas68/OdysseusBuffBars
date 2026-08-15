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
            PrintDiagnostic("automatic routing deferred reason=" .. reason .. " combat lockdown")
        end
        SetAutomaticHelpfulEnhancementDiscoveryPending(true)
        return
    end

    local success, discoveredCount, failureReason, routingChanged = RunHelpfulEnhancementDiscovery(false)
    if not success then
        SetAutomaticHelpfulEnhancementDiscoveryPending(true)
        PrintDiagnostic("automatic routing deferred reason=" .. reason .. " " .. failureReason)
        return
    end

    SetAutomaticHelpfulEnhancementDiscoveryPending(false)
    if not routingChanged then
        if reportUnchangedSynchronization then
            PrintDiagnostic(
                "automatic routing synchronized reason=" .. reason
                    .. " discoveredSpellIDs=" .. discoveredCount
            )
        end
        return
    end

    PrintDiagnostic(
        "automatic routing succeeded reason=" .. reason
            .. " discoveredSpellIDs=" .. discoveredCount
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

    automaticDiscoveryFrame = filterInitFrame
    filterInitFrame:RegisterEvent("ADDON_LOADED")
    filterInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    filterInitFrame:RegisterUnitEvent("UNIT_AURA", "player")
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
