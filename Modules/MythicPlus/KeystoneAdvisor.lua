-- MythicHub Keystone Advisor
-- Lightweight, local-only recommendation helper. No external AI/service is used.
MythicHub_KeystoneAdvisor = MythicHub_KeystoneAdvisor or {}
local KA = MythicHub_KeystoneAdvisor
local DK = MythicHub_DataKeys

local function SafeScoreInfo(mapID)
    local bestLevel, bestScore = 0, 0
    if C_MythicPlus and C_MythicPlus.GetSeasonBestAffixScoreInfoForMap then
        local ok, infos = pcall(C_MythicPlus.GetSeasonBestAffixScoreInfoForMap, mapID)
        if ok and type(infos) == "table" then
            if infos.score then
                bestLevel = tonumber(infos.level) or 0
                bestScore = tonumber(infos.score) or 0
            else
                for _, info in ipairs(infos) do
                    local score = tonumber(info.score) or 0
                    if score > bestScore then
                        bestScore = score
                        bestLevel = tonumber(info.level) or bestLevel
                    end
                end
            end
        end
    end
    return bestLevel, bestScore
end

function KA:GetRecommendation()
    if MythicHubDB and MythicHubDB.advisor and MythicHubDB.advisor.enabled == false then return nil end
    if not DK then return nil end
    DK.RefreshFromAPI()
    local ids = DK.GetCurrentSeasonIDs()
    if not ids or #ids == 0 then return nil end

    local candidate
    for _, mapID in ipairs(ids) do
        local level, score = SafeScoreInfo(mapID)
        local row = { mapID = mapID, level = level, score = score, name = DK.GetDungeonName(mapID) }
        if not candidate
            or row.score < candidate.score
            or (row.score == candidate.score and row.level < candidate.level) then
            candidate = row
        end
    end
    return candidate
end

function KA:PrintRecommendation()
    local pick = self:GetRecommendation()
    if not pick then
        print("|cff00AFFFMythicHub|r Keystone Advisor: no season data available yet.")
        if C_MythicPlus and C_MythicPlus.RequestMapInfo then C_MythicPlus.RequestMapInfo() end
        return
    end

    local myKey = MythicHub_KeySync and MythicHub_KeySync.ReadOwnKeystone and MythicHub_KeySync.ReadOwnKeystone()
    print(string.format("|cff00AFFFMythicHub|r Keystone Advisor: |cffffffff%s|r is your lowest current season score (%d, best +%d).",
        pick.name or ("Map " .. pick.mapID), math.floor(pick.score or 0), pick.level or 0))
    if myKey and (myKey.level or 0) > 0 then
        local own = DK.GetDungeonName(myKey.challengeMapID) or "Unknown dungeon"
        print(string.format("  Current key: |cff00AFFF%s +%d|r", own, myKey.level or 0))
    end
end
