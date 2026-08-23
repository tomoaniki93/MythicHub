-- =====================================================================
-- MythicHubScoreData.lua — Data collection via C_DamageMeter API + preview
-- =====================================================================

local L  = MythicHub_L
local TS = MythicHub_MythicHubScore or MythicHub_TomoScore
local DK = MythicHub_DataKeys

local openRaidLib = MythicHub_KeySync

local SOURCE_DAMAGE  = Enum.DamageMeterType and Enum.DamageMeterType.DamageDone  or 0
local SOURCE_HEALING = Enum.DamageMeterType and Enum.DamageMeterType.HealingDone or 1

-- ─────────────────────────────────────────────────────────────────────────────
--  Build a snapshot of group data at the current moment
-- ─────────────────────────────────────────────────────────────────────────────
function TS:CollectRunData()
    local data = {
        dungeonName = "",
        keyLevel    = 0,
        isMPlus     = false,
        onTime      = false,
        duration    = 0,
        mapID       = nil,
        scoreBefore = 0,
        scoreAfter  = 0,
        scoreDelta  = 0,
        upgradeLevels = 0,
        deathCount  = 0,
        timeLost    = 0,
        completedAt = time(),
        players     = {},
    }

    local instanceName, _, difficultyID = GetInstanceInfo()
    data.dungeonName = instanceName or "?"
    data.isMPlus = (difficultyID == 8)

    if data.isMPlus then
        local info = C_ChallengeMode.GetChallengeCompletionInfo()
        if info then
            data.keyLevel = info.level or 0
            data.onTime   = info.onTime or false
            data.duration = (info.time or 0) / 1000
            data.mapID    = info.mapChallengeModeID or nil
            data.scoreBefore = tonumber(info.oldOverallDungeonScore) or 0
            data.scoreAfter  = tonumber(info.newOverallDungeonScore) or data.scoreBefore
            data.scoreDelta  = data.scoreAfter - data.scoreBefore
            data.upgradeLevels = tonumber(info.keystoneUpgradeLevels) or 0

            local mapName = C_ChallengeMode.GetMapUIInfo(info.mapChallengeModeID or 0)
            if mapName then data.dungeonName = mapName end
        end
        if C_ChallengeMode and C_ChallengeMode.GetDeathCount then
            local ok, deaths, lost = pcall(C_ChallengeMode.GetDeathCount)
            if ok then
                data.deathCount = tonumber(deaths) or 0
                data.timeLost = tonumber(lost) or 0
            end
        end
    else
        data.keyLevel = 0
    end

    -- Gather group unit IDs
    local units = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. i
        end
    elseif IsInGroup() then
        units[#units + 1] = "player"
        for i = 1, GetNumGroupMembers() - 1 do
            units[#units + 1] = "party" .. i
        end
    else
        units[#units + 1] = "player"
    end

    -- Build per-player info
    local playersByName = {}
    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitIsPlayer(unit) then
            local name, realm = UnitName(unit)
            if name then
                local fullName = realm and realm ~= "" and (name .. "-" .. realm) or name
                -- [12.1] nil when the client will not say; consumers colour by
                -- class only when they have one.
                local classFile = MythicHub_Utils and MythicHub_Utils.UnitClassToken(unit)
                local role = MythicHub_Utils.SafeGroupRole(unit)

                -- GetInspectSpecialization only answers for units whose
                -- inspect data is cached, and it returns 0 for the player
                -- themselves. At the end of a run everyone has been inspected;
                -- opening the board from town (/tm keys) is the case where that
                -- is not true, so read the player's own spec directly.
                local specID
                if UnitIsUnit(unit, "player") then
                    local idx = GetSpecialization and GetSpecialization()
                    if idx then specID = GetSpecializationInfo(idx) end
                end
                if not specID or specID == 0 then
                    specID = GetInspectSpecialization(unit)
                end
                local specIcon
                if specID and specID > 0 then
                    _, _, _, specIcon = GetSpecializationInfoByID(specID)
                end

                local rating = 0
                local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
                if ratingSummary then
                    rating = ratingSummary.currentSeasonScore or 0
                end

                playersByName[fullName] = {
                    name       = name,
                    fullName   = fullName,
                    unit       = unit,
                    class      = classFile,
                    role       = role,
                    specID     = specID or 0,
                    specIcon   = specIcon or nil,
                    rating     = rating,
                    keyLevel   = 0,
                    keyMapID   = nil,
                    keyName    = nil,
                    keySpellID = nil,
                    damage     = 0,
                    healing    = 0,
                    interrupts = 0,
                }
            end
        end
    end

    -- Pull keystone info from the keystone sync module
    if openRaidLib then
        local allKeys = openRaidLib.GetAllKeystonesInfo and openRaidLib.GetAllKeystonesInfo() or {}
        for pName, pData in pairs(playersByName) do
            local info = allKeys[pName] or allKeys[pData.name]
            if not info and pData.unit then
                info = openRaidLib.GetKeystoneInfo and openRaidLib.GetKeystoneInfo(pData.unit)
            end
            if info and info.level and info.level > 0 then
                local mapID = info.challengeMapID or info.mythicPlusMapID
                pData.keyLevel = info.level
                pData.keyMapID = mapID
                if mapID and DK then
                    pData.keyName    = DK.GetShortName(mapID) or DK.GetDungeonName(mapID)
                    pData.keySpellID = DK.GetTeleportSpellID(mapID)
                end
            end
        end
    end

    -- Pull totals from C_DamageMeter
    local SESSION_CURRENT = 0
    if C_DamageMeter and C_DamageMeter.GetCombatSessionSourceFromType then
        local damageSources = C_DamageMeter.GetCombatSessionSourceFromType(SESSION_CURRENT, SOURCE_DAMAGE)
        if damageSources then
            for _, src in ipairs(damageSources) do
                local pName = src.name or src.unitName
                if pName and playersByName[pName] then
                    local total = src.totalAmount or 0
                    if not issecurevariable or not issecretvalue or not issecretvalue(total) then
                        playersByName[pName].damage = total
                    end
                end
            end
        end

        local healSources = C_DamageMeter.GetCombatSessionSourceFromType(SESSION_CURRENT, SOURCE_HEALING)
        if healSources then
            for _, src in ipairs(healSources) do
                local pName = src.name or src.unitName
                if pName and playersByName[pName] then
                    local total = src.totalAmount or 0
                    if not issecurevariable or not issecretvalue or not issecretvalue(total) then
                        playersByName[pName].healing = total
                    end
                end
            end
        end

        local interruptType = Enum.DamageMeterType and Enum.DamageMeterType.Actions or 2
        local ok, intSources = pcall(C_DamageMeter.GetCombatSessionSourceFromType, SESSION_CURRENT, interruptType)
        if ok and intSources then
            for _, src in ipairs(intSources) do
                local pName = src.name or src.unitName
                if pName and playersByName[pName] then
                    local total = src.totalAmount or 0
                    if not issecurevariable or not issecretvalue or not issecretvalue(total) then
                        playersByName[pName].interrupts = total
                    end
                end
            end
        end
    end

    -- Sort: tank → healer → dps, then by damage
    local roleOrder = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 }
    local sorted = {}
    for _, p in pairs(playersByName) do
        sorted[#sorted + 1] = p
    end
    table.sort(sorted, function(a, b)
        local ra = roleOrder[a.role] or 4
        local rb = roleOrder[b.role] or 4
        if ra ~= rb then return ra < rb end
        -- Damage decides after a run. Outside one it is zero for everyone, and
        -- sorting on it alone left same-role players in `pairs` order, which
        -- reshuffles between two openings of the same board.
        local da, db = a.damage or 0, b.damage or 0
        if da ~= db then return da > db end
        local ka, kb = a.keyLevel or 0, b.keyLevel or 0
        if ka ~= kb then return ka > kb end
        local ga, gb = a.rating or 0, b.rating or 0
        if ga ~= gb then return ga > gb end
        return (a.fullName or "") < (b.fullName or "")
    end)

    data.players = sorted
    return data
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Preview data
-- ─────────────────────────────────────────────────────────────────────────────
function TS:GetPreviewData()
    return {
        -- Midnight Season 2 preview: Altar of Fangs / Autel des crochets.
        dungeonName = (L and L["tmt_preview_dungeon_name"]) or "Altar of Fangs",
        keyLevel    = 12,
        isMPlus     = true,
        onTime      = true,
        duration    = 1560,
        players     = {
            { name = "Tomotank",   fullName = "Tomotank",   class = "WARRIOR", role = "TANK",    specID = 73,  specIcon = 134952, rating = 2510, keyLevel = 14, keyMapID = 587, keyName = "MR",  keySpellID = 1286809, damage = 18450000, healing = 1200000,  interrupts = 14 },
            { name = "Holyspring", fullName = "Holyspring", class = "PRIEST",  role = "HEALER",  specID = 257, specIcon = 135940, rating = 2395, keyLevel = 13, keyMapID = 586, keyName = "NAL", keySpellID = 1286807, damage = 4200000,  healing = 42800000, interrupts = 3  },
            { name = "Blazefury",  fullName = "Blazefury",  class = "MAGE",    role = "DAMAGER", specID = 63,  specIcon = 135810, rating = 2680, keyLevel = 12, keyMapID = 585, keyName = "VSA", keySpellID = 1286804, damage = 52300000, healing = 350000,   interrupts = 22 },
            { name = "Shadowkill", fullName = "Shadowkill", class = "ROGUE",   role = "DAMAGER", specID = 261, specIcon = 236270, rating = 2240, keyLevel = 11, keyMapID = 584, keyName = "TBV", keySpellID = 1286801, damage = 48700000, healing = 280000,   interrupts = 18 },
            { name = "Natureclaw", fullName = "Natureclaw", class = "DRUID",   role = "DAMAGER", specID = 102, specIcon = 136096, rating = 2070, keyLevel = 10, keyMapID = 399, keyName = "RLP", keySpellID = 393256,  damage = 44100000, healing = 1800000,  interrupts = 7  },
        },
    }
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Save / recall last run
-- ─────────────────────────────────────────────────────────────────────────────
function TS:SaveRunData(data)
    local db = self:GetDB()
    if db then
        db.lastRun = data
    end
    if MythicHub_RunHistory and MythicHub_RunHistory.AddRun then
        MythicHub_RunHistory:AddRun(data, "MythicHub")
    end
end

function TS:ShowLastRun()
    local db = self:GetDB()
    if db and db.lastRun then
        self:SafeShowScoreboard(db.lastRun)
    else
        print(L["ts_no_data"])
    end
end
