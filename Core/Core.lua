-- MythicHub - standalone Mythic+ toolkit
local ADDON_NAME = ...

MythicHub = MythicHub or {}
local MH = MythicHub
MH.name = "MythicHub"
do
    local version
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    elseif GetAddOnMetadata then
        version = GetAddOnMetadata(ADDON_NAME, "Version")
    end
    MH.version = version or "0.1.3-beta"
end
MH.colorHex = "00AFFF"
MH.prefix = "|cff00AFFFMythic|r|cffffffffHub|r"

-- Shared azure / white theme used by the extracted TomoMod modules.
MythicHub_Utils = MythicHub_Utils or {}
local U = MythicHub_Utils
U.BRAND       = { 0.000, 0.686, 1.000 }
U.BRAND_DARK  = { 0.000, 0.360, 0.620 }
U.BRAND_HOVER = { 0.250, 0.820, 1.000 }
U.BRAND_HEX   = "00AFFF"

function U.CloseOnEscape(frame)
    if not frame or not frame.GetName then return end
    local name = frame:GetName()
    if not name or name == "" then return end
    for _, existing in ipairs(UISpecialFrames or {}) do
        if existing == name then return end
    end
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, name)
end

function U.UnitClassToken(unit)
    if not unit or not UnitExists(unit) then return nil end
    return select(2, UnitClass(unit))
end

function U.SafeGroupRole(unit)
    if not unit or not UnitExists(unit) then return "NONE" end
    local ok, role = pcall(UnitGroupRolesAssigned, unit)
    if ok and role then return role end
    return "NONE"
end

function U.Debug(...)
    if MythicHubDB and MythicHubDB.debug then
        print(MH.prefix, ...)
    end
end

MythicHub_Widgets = MythicHub_Widgets or {}
MythicHub_Widgets.Theme = {
    bg         = { 0.025, 0.030, 0.045, 0.96 },
    bgDark     = { 0.018, 0.022, 0.034, 1.00 },
    bgMid      = { 0.040, 0.055, 0.080, 1.00 },
    bgLight    = { 0.060, 0.085, 0.120, 1.00 },
    accent     = { 0.000, 0.686, 1.000, 1.00 },
    accentDark = { 0.000, 0.360, 0.620, 1.00 },
    border     = { 0.150, 0.210, 0.280, 0.95 },
    text       = { 0.960, 0.975, 1.000, 1.00 },
    textHeader = { 0.700, 0.900, 1.000, 1.00 },
    textDim    = { 0.520, 0.600, 0.690, 1.00 },
    red        = { 0.900, 0.240, 0.260, 1.00 },
    yellow     = { 1.000, 0.790, 0.170, 1.00 },
}

MythicHub_Defaults = {
    schemaVersion = 3,
    debug = false,
    layoutUnlocked = false,

    mythicHub = {
        enabled = true,
        locked = true,
        position = { anchor = "CENTER", relTo = "CENTER", x = 0, y = 0 },
    },

    MythicTracker = {
        enabled = true,
        scale = 1.0,
        alpha = 0.95,
        locked = true,
        hideBlizzard = true,
        showTimer = true,
        showForces = true,
        showBosses = true,
        preset = "panel",
        showBackground = true,
        showHeaderBlock = true,
        showDungeonName = false,
        objectiveStyle = "rows",
        timerLayout = "stacked",
        segmentColors = "palier",
        splitsEnabled = true,
        checkpointsEnabled = true,
        fontLSM = "",
        fontScale = 1.0,
        position = { anchor = "TOPRIGHT", relTo = "TOPRIGHT", x = -20, y = -260 },
        learnedEJ = {},
        splits = {},
    },

    MythicHubScore = {
        enabled = true,
        autoShowMPlus = true,
        scale = 1.0,
        alpha = 0.95,
        locked = true,
        position = { anchor = "CENTER", relTo = "CENTER", x = 0, y = 100 },
        lastRun = nil,
    },

    MythicKeys = {
        enabled = true,
        miniFrame = true,
        autoRefresh = true,
        sendToChat = true,
    },

    KeySync = {
        enabled = true,
        guildSync = true,
    },

    autoKeystone = {
        enabled = true,
    },

    advisor = {
        enabled = true,
    },

    runHistory = {
        enabled = true,
        maxRuns = 100,
        runs = {},
    },

    scorePlanner = {
        enabled = true,
        targetIncrease = 1,
    },

    minimap = {
        enabled = true,
        angle = 225,
    },

    characterSkin = {
        enabled = true,
        skinCharacter = true,
        skinInspect = true,
        showItemInfo = true,
        showGems = true,
        showInspectItemInfo = true,
        midnightEnchants = false,
        scale = 1.0,
        movable = false,
        position = nil,
    },

    battleRez = {
        enabled = true,
        onlyInstance = true,
        size = 44,
        fontSize = 18,
        showSwipe = true,
        showResurrectIndicator = false,
        resurrectIconSize = 22,
        position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 200 },
    },

    Keystones = {},
    KeystonesResetAt = nil,
}

local function DeepCopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = DeepCopy(v) end
    return out
end

local function MergeDefaults(dst, defaults)
    for k, v in pairs(defaults) do
        if dst[k] == nil then
            dst[k] = DeepCopy(v)
        elseif type(v) == "table" and type(dst[k]) == "table" then
            MergeDefaults(dst[k], v)
        end
    end
end

function MH:ResetAllSettings()
    MythicHubDB = DeepCopy(MythicHub_Defaults)
    print(self.prefix .. " settings reset. Type /reload to fully re-apply the character skin.")
end

MythicHub_Modules = MythicHub_Modules or {}
function MythicHub_RegisterModule(name, module)
    if not name or type(module) ~= "table" then return end
    MythicHub_Modules[name] = module
end

-- Compatibility registry for the battle-rez mover hook.
MythicHub_Movers = MythicHub_Movers or { entries = {} }
function MythicHub_Movers.RegisterEntry(entry)
    if type(entry) == "table" then table.insert(MythicHub_Movers.entries, entry) end
end

function MH:IsModuleEnabled(key)
    local db = MythicHubDB and MythicHubDB[key]
    return type(db) ~= "table" or db.enabled ~= false
end

function MH:SetLayoutUnlocked(unlocked)
    if not MythicHubDB then return end
    unlocked = unlocked and true or false
    MythicHubDB.layoutUnlocked = unlocked

    local tracker = MythicHub_MythicTracker
    if tracker then
        if not tracker.Frame and unlocked and tracker.BuildFrame then tracker:BuildFrame() end
        if tracker.SetMovable then tracker:SetMovable(unlocked) end
    end

    local rez = MythicHub_ResurrectTracker
    if rez and rez.SetLocked then rez.SetLocked(not unlocked) end

    local score = MythicHub_MythicHubScore or MythicHub_TomoScore
    if score then
        local db = score.GetDB and score:GetDB()
        if db then db.locked = not unlocked end
        if score.SetMovable then
            score:SetMovable(unlocked)
        elseif score.SB then
            score.SB:SetMovable(true)
            score.SB:EnableMouse(true)
        end
    end

    if MythicHubDB.mythicHub then
        MythicHubDB.mythicHub.locked = not unlocked
        local frame = MythicHub_MythicHub and MythicHub_MythicHub.Frame
        if frame then frame:EnableMouse(true) end
    end

    local skin = MythicHub_CharacterSkin
    if skin and skin.SetMovable then skin.SetMovable(unlocked) end

    print(self.prefix .. (unlocked and " layout unlocked. Drag visible MythicHub elements." or " layout locked."))
end

function MH:ApplyLiveSettings()
    if MythicHub_MythicTracker and MythicHub_MythicTracker.RefreshStyle then
        MythicHub_MythicTracker:RefreshStyle()
    end
    if MythicHub_ResurrectTracker and MythicHub_ResurrectTracker.ApplySettings then
        MythicHub_ResurrectTracker.ApplySettings()
    end
    local score = MythicHub_MythicHubScore or MythicHub_TomoScore
    if score and score.SB then
        local db = MythicHubDB and MythicHubDB.MythicHubScore
        if db then
            score.SB:SetScale(db.scale or 1)
            score.SB:SetAlpha(db.alpha or 0.95)
        end
    end
    if MythicHub_CharacterSkin and MythicHub_CharacterSkin.ApplyScale then
        local cdb = MythicHubDB and MythicHubDB.characterSkin
        if cdb then MythicHub_CharacterSkin.ApplyScale(cdb.scale or 1) end
    end
    if MythicHub_Minimap and MythicHub_Minimap.ApplySettings then
        MythicHub_Minimap:ApplySettings()
    end
end

local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" then
        if addon ~= ADDON_NAME then return end
        MythicHubDB = type(MythicHubDB) == "table" and MythicHubDB or {}
        -- 0.1.2: TomoScore was renamed to MythicHubScore. Preserve existing
        -- settings/position/last run during the migration.
        if type(MythicHubDB.TomoScore) == "table" and type(MythicHubDB.MythicHubScore) ~= "table" then
            MythicHubDB.MythicHubScore = MythicHubDB.TomoScore
        end
        MythicHubDB.TomoScore = nil
        MergeDefaults(MythicHubDB, MythicHub_Defaults)
        MythicHubDB.schemaVersion = MythicHub_Defaults.schemaVersion
        return
    end

    if event == "PLAYER_LOGIN" then
        if MythicHub_CharacterSkin and MythicHub_CharacterSkin.Initialize then
            MythicHub_CharacterSkin.Initialize()
        end
        if MythicHub_ResurrectTracker and MythicHub_ResurrectTracker.Initialize then
            MythicHub_ResurrectTracker.Initialize()
        end
        if MythicHub_MythicKeys and MythicHub_MythicKeys.Enable then
            MythicHub_MythicKeys:Enable()
        end
        if MythicHubDB and MythicHubDB.layoutUnlocked then
            C_Timer.After(0.5, function() MH:SetLayoutUnlocked(true) end)
        end
    end
end)
