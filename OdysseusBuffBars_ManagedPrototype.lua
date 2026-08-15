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

local function InitializeManagedBarPresentation(auraButton, style)
    auraButton:SetSize(style.width, style.height)

    local background = auraButton:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", auraButton, "TOPLEFT", style.height + style.iconGap, 0)
    background:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT")
    background:SetColorTexture(
        style.backgroundColor[1],
        style.backgroundColor[2],
        style.backgroundColor[3],
        style.backgroundColor[4]
    )

    local durationBar = CreateFrame("StatusBar", nil, auraButton)
    durationBar:SetPoint("TOPLEFT", auraButton, "TOPLEFT", style.height + style.iconGap, 0)
    durationBar:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT")
    durationBar:SetFrameLevel(auraButton:GetFrameLevel() + 1)
    durationBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    durationBar:SetStatusBarColor(
        style.fillColor[1],
        style.fillColor[2],
        style.fillColor[3],
        style.fillColor[4]
    )

    local icon = auraButton:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", auraButton, "LEFT")
    icon:SetSize(style.height, style.height)
    icon:SetTexCoord(
        style.iconTexCoords[1],
        style.iconTexCoords[2],
        style.iconTexCoords[3],
        style.iconTexCoords[4]
    )

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
    durationText:SetPoint("RIGHT", auraButton, "RIGHT", -style.durationRightPadding, 0)
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
end

local function InitializeAuraButton(auraButton)
    InitializeManagedBarPresentation(auraButton, BUFF_BAR_STYLE)
    auraButton:SetCancelAuraButtons("RightButtonDown")
end

local function CreateFishingLureRow(host, container)
    local style = ENCHANTMENT_BAR_STYLE
    local row = _G.CreateFrame("Button", "OdysseusBuffBarsManagedFishingLureRow", host)
    row:SetSize(style.width, style.height)
    row:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -ENCHANTMENT_BAR_SPACING)
    row:Hide()

    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", row, "TOPLEFT", style.height + style.iconGap, 0)
    background:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT")
    background:SetColorTexture(
        style.backgroundColor[1],
        style.backgroundColor[2],
        style.backgroundColor[3],
        style.backgroundColor[4]
    )

    local durationBar = _G.CreateFrame("StatusBar", nil, row)
    durationBar:SetPoint("TOPLEFT", row, "TOPLEFT", style.height + style.iconGap, 0)
    durationBar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT")
    durationBar:SetFrameLevel(row:GetFrameLevel() + 1)
    durationBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    durationBar:SetStatusBarColor(
        style.fillColor[1],
        style.fillColor[2],
        style.fillColor[3],
        style.fillColor[4]
    )

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", row, "LEFT")
    icon:SetSize(style.height, style.height)
    icon:SetTexCoord(
        style.iconTexCoords[1],
        style.iconTexCoords[2],
        style.iconTexCoords[3],
        style.iconTexCoords[4]
    )

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
    durationText:SetPoint("RIGHT", row, "RIGHT", -style.durationRightPadding, 0)
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
    local host = CreateFrame("Frame", "OdysseusBuffBarsManagedPrototypeHost", UIParent)
    host:SetSize(
        BUFF_HEADER_STYLE.width + (HOST_PADDING * 2),
        BUFF_HEADER_STYLE.height + BUFF_HEADER_STYLE.firstRowGap
    )
    host:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 24, -180)
    host:SetFrameStrata("MEDIUM")
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
    StyleManagedGroupHeader(dragHandle, BUFF_HEADER_STYLE)
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
        -(BUFF_HEADER_STYLE.height + BUFF_HEADER_STYLE.firstRowGap)
    )
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
            elementWidth = BUFF_BAR_STYLE.width,
            elementHeight = BUFF_BAR_STYLE.height,
            elementSpacing = BUFF_BAR_SPACING,
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
    InitializeManagedBarPresentation(auraButton, DEBUFF_BAR_STYLE)
end

local function CreateManagedDebuffPrototype(buffContainer)
    local host = CreateFrame(
        "Frame",
        "OdysseusBuffBarsManagedDebuffPrototypeHost",
        UIParent,
        "DisableUntrustedLayoutScriptsTemplate"
    )
    host:SetSize(
        DEBUFF_HEADER_STYLE.width + (HOST_PADDING * 2),
        DEBUFF_HEADER_STYLE.height + DEBUFF_HEADER_STYLE.firstRowGap
    )
    host:SetPoint("TOPLEFT", buffContainer, "BOTTOMLEFT", -HOST_PADDING, -MANAGED_GROUP_GAP)
    host:SetFrameStrata("MEDIUM")
    host:Hide()

    local header = CreateFrame(
        "Frame",
        nil,
        host,
        _G.BackdropTemplateMixin and "BackdropTemplate"
    )
    header:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, 0)
    StyleManagedGroupHeader(header, DEBUFF_HEADER_STYLE)

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
        -(DEBUFF_HEADER_STYLE.height + DEBUFF_HEADER_STYLE.firstRowGap)
    )
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
            elementWidth = DEBUFF_BAR_STYLE.width,
            elementHeight = DEBUFF_BAR_STYLE.height,
            elementSpacing = DEBUFF_BAR_SPACING,
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

    host:Show()
    container:Show()
    container:SetEnabled(true)
end

local function InitializeEnchantmentAuraButton(auraButton)
    InitializeManagedBarPresentation(auraButton, ENCHANTMENT_BAR_STYLE)
    auraButton:SetCancelAuraButtons("RightButtonDown")
end

local function CreateManagedEnchantmentPrototype(debuffContainer)
    local host = CreateFrame(
        "Frame",
        "OdysseusBuffBarsManagedEnchantmentPrototypeHost",
        UIParent,
        "DisableUntrustedLayoutScriptsTemplate"
    )
    host:SetSize(
        ENCHANTMENT_HEADER_STYLE.width + (HOST_PADDING * 2),
        ENCHANTMENT_HEADER_STYLE.height + ENCHANTMENT_HEADER_STYLE.firstRowGap
    )
    host:SetPoint("TOPLEFT", debuffContainer, "BOTTOMLEFT", -HOST_PADDING, -MANAGED_GROUP_GAP)
    host:SetFrameStrata("MEDIUM")
    host:Hide()

    local header = CreateFrame(
        "Frame",
        nil,
        host,
        _G.BackdropTemplateMixin and "BackdropTemplate"
    )
    header:SetPoint("TOPLEFT", host, "TOPLEFT", HOST_PADDING, 0)
    StyleManagedGroupHeader(header, ENCHANTMENT_HEADER_STYLE)

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
        -(ENCHANTMENT_HEADER_STYLE.height + ENCHANTMENT_HEADER_STYLE.firstRowGap)
    )
    container:SetSize(1, 1)
    container:SetEnabled(false)
    container:SetUnit("player")
    container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)
    container:SetFlowLayoutAnchorPoint("TOPLEFT")
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
    container:SetItemEnchantmentLayout({
        elementWidth = ENCHANTMENT_BAR_STYLE.width,
        elementHeight = ENCHANTMENT_BAR_STYLE.height,
        elementSpacing = ENCHANTMENT_BAR_SPACING,
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
            elementWidth = ENCHANTMENT_BAR_STYLE.width,
            elementHeight = ENCHANTMENT_BAR_STYLE.height,
            elementSpacing = ENCHANTMENT_BAR_SPACING,
        },
    })

    ManagedPrototype.enchantmentHost = host
    ManagedPrototype.enchantmentContainer = container
    ManagedPrototype.fishingLureRow = CreateFishingLureRow(host, container)

    host:Show()
    container:Show()
    container:SetEnabled(true)
    CreateFishingLureEventFrame()
    RefreshFishingLureRow("prototype initialization")
end

CreateManagedAuraPrototype()
CreateManagedDebuffPrototype(ManagedPrototype.container)
CreateManagedEnchantmentPrototype(ManagedPrototype.debuffContainer)
