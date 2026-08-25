local addonName, OBB = ...

_G.OdysseusBuffBars = OBB

OBB.addonName = addonName
OBB.version = "0.1.0"
OBB.groups = {}
OBB.bars = {}
OBB.auraData = {}

local defaults = {
    locked = false,
    anchorsShown = true,
    syncGroupBars = false,
    hideBlizzardFrames = false,
    showLegacyBars = true,
    legacyComparisonMode = false,
    overrides = {},
    groups = {
        {
            id = 1,
            name = "BUFFS",
            unit = "player",
            filter = "HELPFUL",
            x = 420,
            y = -180,
            width = 260,
            height = 18,
            fontSize = 11,
            spacing = 3,
            scale = 1,
            alpha = 1,
            iconSide = "LEFT",
            sort = "timeleft",
            growUp = false,
            maxBars = 40,
            showTimed = true,
            showTimeless = true,
            filters = {
                whitelist = {},
                blacklist = {},
            },
            barColor = { 0.3, 0.5, 1, 0.8 },
            barBgColor = { 0, 0.5, 1, 0.1 },
            anchorTo = nil,
            placement = "SCREEN",
            offsetX = 0,
            offsetY = 0,
        },
        {
            id = 2,
            name = "DEBUFFS",
            unit = "player",
            filter = "HARMFUL",
            x = 420,
            y = -430,
            width = 260,
            height = 18,
            fontSize = 11,
            spacing = 3,
            scale = 1,
            alpha = 1,
            iconSide = "LEFT",
            sort = "timeleft",
            growUp = false,
            maxBars = 40,
            showTimed = true,
            showTimeless = true,
            filters = {
                whitelist = {},
                blacklist = {},
            },
            barColor = { 1, 0, 0, 0.8 },
            barBgColor = { 1, 0, 0, 0.1 },
            anchorTo = 1,
            placement = "BELOW",
            offsetX = 0,
            offsetY = -8,
        },
        {
            id = 3,
            name = "ENCHANTMENTS",
            unit = "player",
            filter = "HELPFUL",
            kind = "ENCHANTMENTS",
            x = 420,
            y = -680,
            width = 260,
            height = 18,
            fontSize = 11,
            spacing = 3,
            scale = 1,
            alpha = 1,
            iconSide = "LEFT",
            sort = "timeleft",
            growUp = false,
            maxBars = 20,
            showTimed = true,
            showTimeless = true,
            filters = {
                whitelist = {},
                blacklist = {},
            },
            barColor = { 0.5, 0, 0.5, 0.8 },
            barBgColor = { 0.5, 0, 0.5, 0.1 },
            anchorTo = 2,
            placement = "BELOW",
            offsetX = 0,
            offsetY = -8,
        },
    },
}

local function CopyDefaults(src, dst)
    if type(dst) ~= "table" then
        dst = {}
    end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function OBB:Print(...)
    print("|cff66ccffOdysseusBuffBars|r", ...)
end

function OBB:GetSettings()
    return self.db
end

function OBB:GetRendererAuthorityMode()
    return "MANAGED"
end

function OBB:ReportManagedRendererFailure(reason)
    if self.managedRendererFailureReported then
        return
    end
    self.managedRendererFailureReported = true

    self:Print(
        "|cffff3333ERROR:|r managed renderer unavailable: " .. tostring(reason) .. ". "
            .. "Aura presentation is disabled for this session."
            .. " Update the addon/client and /reload. SavedVariables were not changed."
    )
end

local defaultBlizzardFrameNames = {
    "BuffFrame",
    "DebuffFrame",
    "TemporaryEnchantFrame",
}

local function ScheduleDefaultBlizzardFrameVisibility()
    if not OBB.db or not OBB.db.hideBlizzardFrames then
        return
    end
    OBB:ApplyDefaultBlizzardFrameVisibility()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            OBB:ApplyDefaultBlizzardFrameVisibility()
        end)
        C_Timer.After(0.25, function()
            OBB:ApplyDefaultBlizzardFrameVisibility()
        end)
    end
end

function OBB:ApplyDefaultBlizzardFrameVisibility()
    if not self.db or (InCombatLockdown and InCombatLockdown()) then
        return
    end

    self.hiddenDefaultBlizzardFrames = self.hiddenDefaultBlizzardFrames or {}
    for _, frameName in ipairs(defaultBlizzardFrameNames) do
        local frame = _G[frameName]
        if frame then
            if self.db.hideBlizzardFrames then
                if frame.Hide then
                    pcall(frame.Hide, frame)
                    self.hiddenDefaultBlizzardFrames[frameName] = true
                end
            elseif self.hiddenDefaultBlizzardFrames[frameName] then
                if frame.Show then
                    pcall(frame.Show, frame)
                end
                self.hiddenDefaultBlizzardFrames[frameName] = nil
            end
        end
    end
end

function OBB:HookEditModeVisibilityRefresh()
    if self.editModeVisibilityHooked then
        return
    end
    local editModeFrame = _G.EditModeManagerFrame
    if not editModeFrame or not editModeFrame.HookScript then
        return
    end
    editModeFrame:HookScript("OnHide", ScheduleDefaultBlizzardFrameVisibility)
    self.editModeVisibilityHooked = true
end

function OBB:RefreshAll(reason)
    if not self.db then
        return false, "database unavailable"
    end
    local managedPrototype = self.ManagedPrototype
    if not managedPrototype or not managedPrototype.IsReady then
        return false, "managed renderer unavailable"
    end
    local ready, readinessReason = managedPrototype:IsReady()
    if not ready then
        return false, readinessReason
    end
    if _G.InCombatLockdown and _G.InCombatLockdown() then
        return true, "managed lifecycle remains framework-owned in combat"
    end

    if not managedPrototype.ApplyConfiguration then
        return false, "managed configuration refresh unavailable"
    end
    local applySuccess, applyReason = managedPrototype:ApplyConfiguration(reason or "managed refresh")
    if not applySuccess then
        return false, applyReason or "managed configuration refresh failed"
    end
    if managedPrototype.RefreshManagedState then
        return managedPrototype:RefreshManagedState(reason or "managed refresh")
    end
    return true
end

function OBB:RefreshAuras(reason)
    return self:RefreshAll(reason or "explicit refresh")
end

function OBB:OnAddonLoaded(name)
    if name ~= addonName then
        return
    end

    -- Preserve settings from installs using the former addon name.
    if OdysseusBuffBarsDB == nil and OdysseusBuffBarsTestDB ~= nil then
        OdysseusBuffBarsDB = OdysseusBuffBarsTestDB
    end

    local savedDB = OdysseusBuffBarsDB
    local explicitUnparentedPlacements = {}
    local savedGroups = type(savedDB) == "table" and savedDB.groups
    if type(savedGroups) == "table" then
        for index, groupSettings in ipairs(savedGroups) do
            if type(groupSettings) == "table"
                and groupSettings.placement ~= nil
                and groupSettings.anchorTo == nil
            then
                local groupID = type(groupSettings.id) == "number" and groupSettings.id or index
                explicitUnparentedPlacements[groupID] = true
            end
        end
    end

    OdysseusBuffBarsDB = CopyDefaults(defaults, savedDB)
    self.db = OdysseusBuffBarsDB
    self.db.overrides = self.db.overrides or {}

    for _, groupSettings in ipairs(self.db.groups) do
        groupSettings.id = groupSettings.id or _
        local hadExplicitUnparentedPlacement = explicitUnparentedPlacements[groupSettings.id] == true
        groupSettings.filters = groupSettings.filters or {}
        groupSettings.filters.whitelist = groupSettings.filters.whitelist or {}
        groupSettings.filters.blacklist = groupSettings.filters.blacklist or {}
        if groupSettings.height == 22 then
            groupSettings.height = 20
        end
        groupSettings.fontSize = groupSettings.fontSize or 11
        if groupSettings.id == 1 then
            groupSettings.placement = groupSettings.placement or "SCREEN"
            groupSettings.offsetX = groupSettings.offsetX or 0
            groupSettings.offsetY = groupSettings.offsetY or 0
        elseif groupSettings.id == 2 then
            if hadExplicitUnparentedPlacement then
                groupSettings.anchorTo = nil
            else
                groupSettings.anchorTo = groupSettings.anchorTo == nil and 1 or groupSettings.anchorTo
            end
            groupSettings.placement = groupSettings.placement or "BELOW"
            groupSettings.offsetX = groupSettings.offsetX or 0
            groupSettings.offsetY = groupSettings.offsetY or -8
        elseif groupSettings.id == 3 then
            groupSettings.kind = groupSettings.kind or "ENCHANTMENTS"
            if hadExplicitUnparentedPlacement then
                groupSettings.anchorTo = nil
            else
                groupSettings.anchorTo = groupSettings.anchorTo == nil and 2 or groupSettings.anchorTo
            end
            groupSettings.placement = groupSettings.placement or "BELOW"
            groupSettings.offsetX = groupSettings.offsetX or 0
            groupSettings.offsetY = groupSettings.offsetY or -8
        end

        if groupSettings.kind == "ENCHANTMENTS" then
            groupSettings.barColor = groupSettings.barColor or { 0.5, 0, 0.5, 0.8 }
            groupSettings.barBgColor = groupSettings.barBgColor or { 0.5, 0, 0.5, 0.1 }
        elseif groupSettings.filter == "HELPFUL" then
            groupSettings.barColor = groupSettings.barColor or { 0.3, 0.5, 1, 0.8 }
            groupSettings.barBgColor = groupSettings.barBgColor or { 0, 0.5, 1, 0.1 }
        elseif groupSettings.filter == "HARMFUL" then
            groupSettings.barColor = groupSettings.barColor or { 1, 0, 0, 0.8 }
            groupSettings.barBgColor = groupSettings.barBgColor or { 1, 0, 0, 0.1 }
        end
    end

    local managedStartupReady = false
    local managedStartupReason = "managed renderer module unavailable"
    local managedPrototype = self.ManagedPrototype
    if managedPrototype and managedPrototype.Initialize and managedPrototype.IsReady then
        local initializeCallSuccess, initializeSuccess, initializeReason = pcall(
            managedPrototype.Initialize,
            managedPrototype
        )
        if initializeCallSuccess and initializeSuccess then
            local readinessCallSuccess, ready, readinessReason = pcall(
                managedPrototype.IsReady,
                managedPrototype
            )
            managedStartupReady = readinessCallSuccess and ready == true
            managedStartupReason = readinessCallSuccess
                and (readinessReason or managedStartupReason)
                or ready
        else
            managedStartupReason = initializeCallSuccess and initializeReason or initializeSuccess
        end
    end
    if self.Config then
        self.Config:Initialize()
    end
    self:HookEditModeVisibilityRefresh()
    if not managedStartupReady then
        self:ReportManagedRendererFailure(
            managedStartupReason or "unknown managed initialization failure"
        )
    end
    self:ApplyDefaultBlizzardFrameVisibility()
    self:Print("loaded. /obb config opens settings, /obb anchors toggles anchors.")
end

function OBB:ToggleAnchors()
    if self.Config and self.Config:IsCombatLocked() then
        self.Config:WarnCombat()
        return
    end
    self.db.anchorsShown = not self.db.anchorsShown
    if self.ManagedPrototype and self.ManagedPrototype.ApplyHeaderVisibility then
        self.ManagedPrototype:ApplyHeaderVisibility()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        OBB:OnAddonLoaded(...)
        return
    end

    if not OBB.db then
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        OBB:HookEditModeVisibilityRefresh()
        ScheduleDefaultBlizzardFrameVisibility()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        if OBB.Config then
            OBB.Config:EnterCombat()
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if OBB.Config then
            OBB.Config:LeaveCombat()
        end
        OBB:ApplyDefaultBlizzardFrameVisibility()
        return
    end
end)

SLASH_ODYSSEUSBUFFBARS1 = "/obb"
SLASH_ODYSSEUSBUFFBARS2 = "/buffbars"
SLASH_ODYSSEUSBUFFBARS3 = "/obbtest"
SlashCmdList.ODYSSEUSBUFFBARS = function(msg)
    msg = msg and msg:lower() or ""
    if msg == "refresh" then
        OBB:RefreshAuras("slash command")
    elseif msg == "config" or msg == "options" or msg == "open" then
        OBB.Config:Toggle()
    elseif msg == "anchors" then
        OBB:ToggleAnchors()
    else
        OBB.Config:Toggle()
    end
end
