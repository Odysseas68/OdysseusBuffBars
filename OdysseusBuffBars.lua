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

function OBB:RefreshAll()
    if not self.db then
        return
    end

    for _, groupSettings in ipairs(self.db.groups) do
        self.auraData[groupSettings.id] = self.Engine:Scan(
            groupSettings.unit,
            groupSettings.filter,
            groupSettings.sort,
            groupSettings
        )
        self.Bars:UpdateGroup(groupSettings, self.auraData[groupSettings.id])
    end
    self.Bars:UpdateAllGroupPositions()
end

function OBB:OnAddonLoaded(name)
    if name ~= addonName then
        return
    end

    -- Preserve settings from installs using the former addon name.
    if OdysseusBuffBarsDB == nil and OdysseusBuffBarsTestDB ~= nil then
        OdysseusBuffBarsDB = OdysseusBuffBarsTestDB
    end

    OdysseusBuffBarsDB = CopyDefaults(defaults, OdysseusBuffBarsDB)
    self.db = OdysseusBuffBarsDB
    self.db.overrides = self.db.overrides or {}

    for _, groupSettings in ipairs(self.db.groups) do
        groupSettings.id = groupSettings.id or _
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
            groupSettings.anchorTo = groupSettings.anchorTo == nil and 1 or groupSettings.anchorTo
            groupSettings.placement = groupSettings.placement or "BELOW"
            groupSettings.offsetX = groupSettings.offsetX or 0
            groupSettings.offsetY = groupSettings.offsetY or -8
        elseif groupSettings.id == 3 then
            groupSettings.kind = groupSettings.kind or "ENCHANTMENTS"
            groupSettings.anchorTo = groupSettings.anchorTo == nil and 2 or groupSettings.anchorTo
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

    if self.ManagedPrototype and self.ManagedPrototype.Initialize then
        self.ManagedPrototype:Initialize()
    end

    if self.Config then
        self.Config:Initialize()
    end
    self:HookEditModeVisibilityRefresh()
    self.Bars:Initialize()
    self:RefreshAll()
    self:ApplyDefaultBlizzardFrameVisibility()
    self:Print("loaded. /obb config opens settings, /obb anchors toggles anchors.")
end

function OBB:ToggleAnchors()
    if self.Config and self.Config:IsCombatLocked() then
        self.Config:WarnCombat()
        return
    end
    self.db.anchorsShown = not self.db.anchorsShown
    if self.Bars then
        self.Bars:ApplyLegacyBarsVisibility()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("WEAPON_ENCHANT_CHANGED")
eventFrame:RegisterEvent("WEAPON_SLOT_CHANGED")
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
        OBB:RefreshAll()
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
        if OBB.Bars then
            OBB.Bars:RefreshCancelButtons()
        end
        OBB:ApplyDefaultBlizzardFrameVisibility()
        return
    end

    if event == "WEAPON_ENCHANT_CHANGED" or event == "WEAPON_SLOT_CHANGED" then
        OBB:RefreshAll()
        return
    end

    if event == "UNIT_AURA" then
        local unit = ...
        if unit ~= "player" and unit ~= "target" and unit ~= "focus" and unit ~= "pet" then
            return
        end

        for _, groupSettings in ipairs(OBB.db.groups) do
            if groupSettings.unit == unit then
                OBB.auraData[groupSettings.id] = OBB.Engine:Scan(groupSettings.unit, groupSettings.filter, groupSettings.sort, groupSettings)
                OBB.Bars:UpdateGroup(groupSettings, OBB.auraData[groupSettings.id])
            end
        end
        OBB.Bars:UpdateAllGroupPositions()
    end
end)

SLASH_ODYSSEUSBUFFBARS1 = "/obb"
SLASH_ODYSSEUSBUFFBARS2 = "/buffbars"
SLASH_ODYSSEUSBUFFBARS3 = "/obbtest"
SlashCmdList.ODYSSEUSBUFFBARS = function(msg)
    msg = msg and msg:lower() or ""
    if msg == "refresh" then
        OBB:RefreshAll()
    elseif msg == "config" or msg == "options" or msg == "open" then
        OBB.Config:Toggle()
    elseif msg == "anchors" then
        OBB:ToggleAnchors()
    else
        OBB.Config:Toggle()
    end
end
