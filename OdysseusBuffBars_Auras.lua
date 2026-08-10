local _, OBB = ...

local Engine = {}
OBB.Engine = Engine

local issecretvalue = issecretvalue or function() return false end
local canaccessvalue = canaccessvalue or function() return true end

local durationFormatters = {}
local enchantSlotNames = {
    "MainHandSlot",
    "SecondaryHandSlot",
}

local enhancementNamePatterns = {
    "well fed",
    "flask",
    "phial",
    "food",
    "augment rune",
    "rune",
    "weapon oil",
    "sharpening",
    "weightstone",
}

local enhancementSpellIDs = {
    [1232585] = true, -- Blooming Feast Well Fed
}

local function FormatWeaponEnchantTime(seconds)
    if type(seconds) ~= "number" or seconds <= 0 then
        return ""
    end
    if seconds >= SECONDS_PER_DAY * 1.5 then
        return string.format("%d d", math.ceil(seconds / SECONDS_PER_DAY))
    end
    if seconds >= SECONDS_PER_HOUR * 1.5 then
        return string.format("%d h", math.ceil(seconds / SECONDS_PER_HOUR))
    end
    if seconds >= SECONDS_PER_MIN * 1.5 then
        return string.format("%d m", math.ceil(seconds / SECONDS_PER_MIN))
    end
    return string.format("%d s", math.ceil(seconds))
end

function Engine:CanReadValue(value)
    if value == nil then
        return false
    end
    if issecretvalue(value) then
        return canaccessvalue(value)
    end
    return true
end

function Engine:CanReadNumber(value)
    return self:CanReadValue(value) and type(value) == "number"
end

function Engine:FormatWeaponEnchantTime(seconds)
    return FormatWeaponEnchantTime(seconds)
end

function Engine:IsSecret(value)
    return issecretvalue(value)
end

function Engine:IsEnhancementName(name)
    if not self:CanReadValue(name) or type(name) ~= "string" then
        return false
    end

    name = name:lower()
    for _, pattern in ipairs(enhancementNamePatterns) do
        if name:find(pattern, 1, true) then
            return true
        end
    end
    return false
end

function Engine:IsEnhancementSpellID(spellID)
    if not self:CanReadValue(spellID) or type(spellID) ~= "number" then
        return false
    end
    return enhancementSpellIDs[spellID] and true or false
end

function Engine:IsEnhancementAura(data)
    if not data or data.filter ~= "HELPFUL" then
        return false
    end
    return (data.isEnhancement or self:IsEnhancementSpellID(data.spellID)) and true or false
end

function Engine:GetOverride(data)
    local spellID = data and data.spellID
    if type(spellID) ~= "number" or not OBB.db or type(OBB.db.overrides) ~= "table" then
        return nil
    end
    return OBB.db.overrides[spellID]
end

function Engine:IsHiddenByOverride(data)
    local override = self:GetOverride(data)
    return override and override.hidden and true or false
end

function Engine:ShouldIncludeAuraForGroup(data, groupSettings)
    local override = self:GetOverride(data)
    if self:IsHiddenByOverride(data) then
        return false
    end
    if override and override.group and data.filter == "HELPFUL" then
        if override.group == "ENCHANTMENTS" then
            return groupSettings and groupSettings.kind == "ENCHANTMENTS"
        end
        if override.group == "BUFFS" then
            return groupSettings and groupSettings.kind ~= "ENCHANTMENTS" and groupSettings.filter == "HELPFUL"
        end
    end

    local isEnhancement = self:IsEnhancementAura(data)
    if groupSettings and groupSettings.kind == "ENCHANTMENTS" then
        return isEnhancement
    end
    return not isEnhancement
end

function Engine:HasFilterEntries(filterTable)
    if type(filterTable) ~= "table" then
        return false
    end
    for spellID, enabled in pairs(filterTable) do
        if enabled and type(spellID) == "number" then
            return true
        end
    end
    return false
end

function Engine:ShouldPassGroupFilters(data, groupSettings)
    if not groupSettings or type(groupSettings.filters) ~= "table" then
        return true
    end
    local spellID = data and data.spellID
    if type(spellID) ~= "number" then
        return true
    end

    local whitelist = groupSettings.filters.whitelist
    if self:HasFilterEntries(whitelist) then
        return whitelist[spellID] and true or false
    end

    local blacklist = groupSettings.filters.blacklist
    if type(blacklist) == "table" and blacklist[spellID] then
        return false
    end
    return true
end

function Engine:RememberFilterAura(data, groupSettings)
    local spellID = data and data.spellID
    if not groupSettings or type(spellID) ~= "number" then
        return
    end

    OBB.filterAuraRows = OBB.filterAuraRows or {}
    local rows = OBB.filterAuraRows[groupSettings.id]
    if not rows then
        rows = {}
        OBB.filterAuraRows[groupSettings.id] = rows
    end

    local name = nil
    if self:CanReadValue(data.name) and type(data.name) == "string" then
        name = data.name
    end
    rows[spellID] = {
        spellID = spellID,
        name = name or (rows[spellID] and rows[spellID].name) or ("Spell " .. tostring(spellID)),
        icon = data.icon or (rows[spellID] and rows[spellID].icon),
    }
end

function Engine:GetAuraDuration(unit, auraInstanceID)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDuration or not auraInstanceID then
        return nil
    end
    local ok, duration = pcall(C_UnitAuras.GetAuraDuration, unit, auraInstanceID)
    if ok then
        return duration
    end
    return nil
end

function Engine:DoesAuraExpire(unit, auraInstanceID, expirationTime, previous)
    if self:CanReadNumber(expirationTime) then
        return expirationTime > 0
    end
    if previous and previous.expires ~= nil then
        return previous.expires
    end
    if C_UnitAuras and C_UnitAuras.DoesAuraHaveExpirationTime then
        local ok, expires = pcall(C_UnitAuras.DoesAuraHaveExpirationTime, unit, auraInstanceID)
        if ok and self:CanReadValue(expires) then
            return expires and true or false
        end
    end
    return true
end

function Engine:GetIcon(texture, spellID, previous)
    if texture ~= nil then
        return texture
    end
    if previous and previous.icon then
        return previous.icon
    end
    if self:CanReadValue(spellID) and C_Spell and C_Spell.GetSpellTexture then
        local ok, icon = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and self:CanReadValue(icon) then
            return icon
        end
    end
    return [[Interface\Icons\INV_Misc_QuestionMark]]
end

function Engine:GetFormatter(kind)
    kind = kind or "default"
    if durationFormatters[kind] then
        return durationFormatters[kind]
    end
    if not C_StringUtil or not C_StringUtil.CreateNumericRuleFormatter then
        return nil
    end

    local formatter = C_StringUtil.CreateNumericRuleFormatter()
    formatter:SetBreakpoints({
        { threshold = 0, format = SECOND_ONELETTER_ABBR },
        {
            threshold = SECONDS_PER_MIN * 1.5,
            format = MINUTE_ONELETTER_ABBR,
            step = SECONDS_PER_MIN,
            rounding = Enum.NumericRuleFormatRounding.Up,
            components = { { div = SECONDS_PER_MIN } },
        },
        {
            threshold = SECONDS_PER_HOUR * 1.5,
            format = HOUR_ONELETTER_ABBR,
            step = SECONDS_PER_HOUR,
            rounding = Enum.NumericRuleFormatRounding.Up,
            components = { { div = SECONDS_PER_HOUR } },
        },
        {
            threshold = SECONDS_PER_DAY * 1.5,
            format = DAY_ONELETTER_ABBR,
            step = SECONDS_PER_DAY,
            rounding = Enum.NumericRuleFormatRounding.Up,
            components = { { div = SECONDS_PER_DAY } },
        },
    })
    durationFormatters[kind] = formatter
    return formatter
end

function Engine:FormatDuration(duration)
    if not duration or not duration.FormatRemainingDuration then
        return nil
    end
    local formatter = self:GetFormatter("default")
    if not formatter then
        return nil
    end
    local ok, text = pcall(duration.FormatRemainingDuration, duration, formatter)
    if ok and text ~= nil then
        return text
    end
    return nil
end

function Engine:GetSortRule(sort)
    if sort == "name" then
        return Enum.UnitAuraSortRule.NameOnly, Enum.UnitAuraSortDirection.Normal
    end
    if sort == "timeleft" then
        return Enum.UnitAuraSortRule.ExpirationOnly, Enum.UnitAuraSortDirection.Reverse
    end
    return Enum.UnitAuraSortRule.Default, Enum.UnitAuraSortDirection.Normal
end

function Engine:GetSortedAuraIDs(unit, filter, sort)
    if not C_UnitAuras or not C_UnitAuras.GetUnitAuraInstanceIDs then
        return nil
    end
    local sortRule, sortDirection = self:GetSortRule(sort)
    local ok, auraIDs = pcall(C_UnitAuras.GetUnitAuraInstanceIDs, unit, filter, nil, sortRule, sortDirection)
    if ok then
        return auraIDs
    end
    return nil
end

function Engine:CreateWeaponEnchantData(itemIndex, hasEnchant, expirationMS, charges, enchantID)
    if not hasEnchant then
        return nil
    end

    local slotName = enchantSlotNames[itemIndex]
    local slotID = slotName and GetInventorySlotInfo(slotName)
    local durationSeconds = expirationMS and (expirationMS / 1000) or 0
    local name = itemIndex == 2 and "Off-hand Enchant" or "Main-hand Enchant"
    local icon = nil

    if slotID then
        icon = GetInventoryItemTexture("player", slotID)
    end

    return {
        index = -itemIndex,
        auraid = "weapon:" .. tostring(itemIndex) .. ":" .. tostring(enchantID or 0),
        unit = "player",
        filter = "ENCHANTMENTS",
        type = "ENCHANTMENT",
        targetSlot = slotID,
        name = name,
        spellID = enchantID,
        icon = icon or [[Interface\Icons\INV_Misc_QuestionMark]],
        applications = charges or 0,
        expirationTime = durationSeconds > 0 and (GetTime() + durationSeconds) or nil,
        durationSeconds = durationSeconds,
        expires = durationSeconds > 0,
        duration = nil,
        formattedTime = FormatWeaponEnchantTime(durationSeconds),
        raw = nil,
    }
end

function Engine:ScanWeaponEnchantments()
    local result = {}
    if not GetWeaponEnchantInfo then
        return result
    end

    local values = { GetWeaponEnchantInfo() }
    local returnsPerItem = 4
    local numItems = math.floor(#values / returnsPerItem)
    for itemIndex = 1, numItems do
        local offset = returnsPerItem * (itemIndex - 1)
        local data = self:CreateWeaponEnchantData(
            itemIndex,
            values[offset + 1],
            values[offset + 2],
            values[offset + 3],
            values[offset + 4]
        )
        if data then
            table.insert(result, data)
        end
    end
    return result
end

local previousByAuraID = {}

function Engine:Scan(unit, filter, sort, groupSettings)
    local result = {}
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
        return result
    end

    local cacheKey = unit .. ":" .. filter
    local previousForFilter = previousByAuraID[cacheKey]
    if not previousForFilter then
        previousForFilter = {}
        previousByAuraID[cacheKey] = previousForFilter
    end

    local auraByID = {}
    local index = 1
    while true do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if not ok then
            -- Temporary Retail 12.1 containment until migration to Blizzard-managed AuraContainer architecture.
            if type(aura) == "string" and aura:find("Auras cannot be accessed when secret while tainted", 1, true) then
                return (groupSettings and OBB.auraData[groupSettings.id]) or result
            end
            error(aura, 0)
        end
        if not aura then
            break
        end

        local auraID = aura.auraInstanceID
        local previous = auraID and previousForFilter[auraID] or nil
        local expirationTime = aura.expirationTime
        local include = not (self:CanReadNumber(expirationTime) and expirationTime > 0 and expirationTime <= GetTime())

        if include then
            local duration = self:GetAuraDuration(unit, auraID)
            local expires = self:DoesAuraExpire(unit, auraID, expirationTime, previous)
            local data = {
                index = index,
                auraid = auraID,
                unit = unit,
                filter = filter,
                type = filter == "HARMFUL" and "DEBUFF" or "BUFF",
                name = aura.name or (previous and previous.name) or UNKNOWN,
                spellID = self:CanReadValue(aura.spellId) and aura.spellId or (previous and previous.spellID),
                icon = self:GetIcon(aura.icon, aura.spellId, previous),
                applications = self:CanReadValue(aura.applications) and aura.applications or (previous and previous.applications) or 0,
                expirationTime = self:CanReadValue(expirationTime) and expirationTime or (previous and previous.expirationTime),
                durationSeconds = self:CanReadValue(aura.duration) and aura.duration or (previous and previous.durationSeconds) or 0,
                expires = expires,
                duration = duration,
                formattedTime = expires and self:FormatDuration(duration) or "",
                isEnhancement = self:IsEnhancementSpellID(aura.spellId)
                    or self:IsEnhancementName(aura.name)
                    or (previous and previous.isEnhancement)
                    or false,
                raw = aura,
            }

            if self:ShouldIncludeAuraForGroup(data, groupSettings) then
                self:RememberFilterAura(data, groupSettings)
            end

            if self:ShouldIncludeAuraForGroup(data, groupSettings) and self:ShouldPassGroupFilters(data, groupSettings) then
                table.insert(result, data)
            end
            if auraID then
                auraByID[auraID] = data
            end
        end

        index = index + 1
    end

    local sortedIDs = self:GetSortedAuraIDs(unit, filter, sort)
    if sortedIDs then
        local sorted = {}
        for _, auraID in ipairs(sortedIDs) do
            local data = auraByID[auraID]
            if data and self:ShouldIncludeAuraForGroup(data, groupSettings) and self:ShouldPassGroupFilters(data, groupSettings) then
                table.insert(sorted, data)
            end
        end
        result = sorted
    end

    if groupSettings and groupSettings.kind == "ENCHANTMENTS" then
        local weaponEnchantments = self:ScanWeaponEnchantments()
        for _, data in ipairs(weaponEnchantments) do
            self:RememberFilterAura(data, groupSettings)
            if not self:IsHiddenByOverride(data) and self:ShouldPassGroupFilters(data, groupSettings) then
                table.insert(result, data)
            end
        end
    end

    previousByAuraID[cacheKey] = auraByID
    return result
end
