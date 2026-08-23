-- =====================================================================
-- RunHistory.lua — MythicHub persistent Mythic+ run history
-- =====================================================================

MythicHub_RunHistory = MythicHub_RunHistory or {}
local RH = MythicHub_RunHistory
local L  = MythicHub_L
local DK = MythicHub_DataKeys
local TH = MythicHub_Widgets and MythicHub_Widgets.Theme or {}

local function DB()
    return MythicHubDB and MythicHubDB.runHistory
end

local function Copy(v)
    if type(v) ~= "table" then return v end
    local o = {}
    for k, x in pairs(v) do o[k] = Copy(x) end
    return o
end

local function FormatDuration(sec)
    sec = tonumber(sec) or 0
    if sec <= 0 then return "—" end
    sec = math.floor(sec + 0.5)
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function CalendarToTime(c)
    if type(c) ~= "table" then return nil end
    local day = c.monthDay or c.day
    if not c.year or not c.month or not day then return nil end
    local ok, t = pcall(time, {
        year = c.year, month = c.month, day = day,
        hour = c.hour or 0, min = c.minute or 0, sec = 0,
    })
    return ok and t or nil
end

local function RunSignature(run)
    local mapID = tonumber(run.mapID or run.mapChallengeModeID) or 0
    local level = tonumber(run.keyLevel or run.level) or 0
    local dur   = tonumber(run.duration or run.durationSec) or 0
    return string.format("%d:%d:%d", mapID, level, math.floor(dur + 0.5))
end

function RH:GetRuns()
    local db = DB()
    if not db then return {} end
    db.runs = type(db.runs) == "table" and db.runs or {}
    return db.runs
end

function RH:AddRun(data, source)
    local db = DB()
    if not db or db.enabled == false or type(data) ~= "table" then return false end
    local mapID = tonumber(data.mapID or data.mapChallengeModeID)
    local level = tonumber(data.keyLevel or data.level) or 0
    local duration = tonumber(data.duration or data.durationSec) or 0
    if not mapID or level <= 0 or duration <= 0 then return false end

    local run = Copy(data)
    run.mapID       = mapID
    run.keyLevel    = level
    run.duration    = duration
    run.dungeonName = run.dungeonName or (DK and DK.GetDungeonName(mapID)) or ("ID:" .. tostring(mapID))
    run.completedAt = tonumber(run.completedAt) or time()
    run.source      = source or run.source or "MythicHub"
    run.signature   = RunSignature(run)

    local runs = self:GetRuns()
    for i, old in ipairs(runs) do
        if old.signature == run.signature then
            -- Prefer the richer MythicHub snapshot over the Blizzard import.
            if run.players and #run.players > 0 and (not old.players or #old.players == 0) then
                runs[i] = run
                self:Refresh()
                return true
            end
            return false
        end
    end

    table.insert(runs, 1, run)
    local maxRuns = math.max(10, math.min(500, tonumber(db.maxRuns) or 100))
    while #runs > maxRuns do table.remove(runs) end
    self:Refresh()
    return true
end

function RH:SyncFromBlizzard()
    local db = DB()
    if not db or db.enabled == false then return 0 end
    if not C_MythicPlus or not C_MythicPlus.GetRunHistory then return 0 end
    local ok, list = pcall(C_MythicPlus.GetRunHistory, true, false, true)
    if not ok or type(list) ~= "table" then return 0 end

    local added = 0
    for _, r in ipairs(list) do
        local mapID = tonumber(r.mapChallengeModeID)
        local level = tonumber(r.level) or 0
        local duration = tonumber(r.durationSec) or 0
        if mapID and level > 0 and duration > 0 then
            local item = {
                mapID       = mapID,
                keyLevel    = level,
                duration    = duration,
                dungeonName = DK and DK.GetDungeonName(mapID) or nil,
                runScore    = tonumber(r.runScore) or 0,
                completedAt = CalendarToTime(r.completionDate) or time(),
                onTime      = nil,
                players     = {},
                source      = "Blizzard",
            }
            if self:AddRun(item, "Blizzard") then added = added + 1 end
        end
    end
    return added
end

function RH:Clear()
    local db = DB()
    if not db then return end
    db.runs = {}
    self:Refresh()
end

local function FS(parent, size, text, point, rel, relPoint, x, y, color)
    local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f:SetPoint(point or "LEFT", rel or parent, relPoint or point or "LEFT", x or 0, y or 0)
    f:SetText(text or "")
    f:SetFont(select(1, f:GetFont()), size or 11, "OUTLINE")
    if color then f:SetTextColor(color[1], color[2], color[3], color[4] or 1) end
    return f
end

local function Button(parent, label, w, fn)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w or 100, 28)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    b:SetBackdropColor(0.05,0.08,0.12,0.95)
    b:SetBackdropBorderColor(0.0,0.45,0.72,1)
    local t = FS(b, 11, label, "CENTER", b, "CENTER", 0, 0, TH.text or {1,1,1,1})
    b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0,0.686,1,1); t:SetTextColor(1,1,1,1) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0,0.45,0.72,1); t:SetTextColor(0.9,0.95,1,1) end)
    b:SetScript("OnClick", fn)
    return b
end

function RH:Build()
    if self.Frame then return self.Frame end
    local F = CreateFrame("Frame", "MythicHub_RunHistoryFrame", UIParent, "BackdropTemplate")
    self.Frame = F
    F:SetSize(760, 520)
    F:SetPoint("CENTER")
    F:SetFrameStrata("DIALOG")
    F:SetClampedToScreen(true)
    F:SetMovable(true)
    F:EnableMouse(true)
    F:RegisterForDrag("LeftButton")
    F:SetScript("OnDragStart", function(s) s:StartMoving() end)
    F:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)
    F:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    F:SetBackdropColor(0.02,0.03,0.05,0.985)
    F:SetBackdropBorderColor(0,0.45,0.72,1)
    MythicHub_Utils.CloseOnEscape(F)

    local accent = F:CreateTexture(nil,"ARTWORK")
    accent:SetPoint("TOPLEFT",2,-2); accent:SetPoint("TOPRIGHT",-2,-2); accent:SetHeight(3)
    accent:SetColorTexture(0,0.686,1,1)

    F.title = FS(F, 20, L["history_title"], "TOPLEFT", F, "TOPLEFT", 18, -18, TH.text or {1,1,1,1})
    F.summary = FS(F, 11, "", "TOPLEFT", F.title, "BOTTOMLEFT", 0, -8, TH.textDim or {.55,.65,.75,1})

    local close = Button(F, "×", 30, function() F:Hide() end)
    close:SetPoint("TOPRIGHT", F, "TOPRIGHT", -12, -12)
    local sync = Button(F, L["history_sync"], 120, function() RH:SyncFromBlizzard(); RH:Refresh() end)
    sync:SetPoint("TOPRIGHT", close, "TOPLEFT", -8, 0)
    local clear = Button(F, L["history_clear"], 120, function()
        if IsShiftKeyDown() then RH:Clear() else print(MythicHub.prefix .. " " .. L["history_shift_clear"]) end
    end)
    clear:SetPoint("RIGHT", sync, "LEFT", -8, 0)

    local header = CreateFrame("Frame", nil, F)
    header:SetPoint("TOPLEFT", F, "TOPLEFT", 18, -72)
    header:SetPoint("TOPRIGHT", F, "TOPRIGHT", -18, -72)
    header:SetHeight(24)
    local cols = {
        {L["history_col_date"], 0}, {L["history_col_dungeon"], 115}, {L["history_col_key"], 350},
        {L["history_col_time"], 410}, {L["history_col_score"], 485}, {L["history_col_gain"], 565}, {L["history_col_status"], 640},
    }
    for _, c in ipairs(cols) do FS(header, 10, c[1], "LEFT", header, "LEFT", c[2], 0, TH.textHeader or {.7,.9,1,1}) end

    local scroll = CreateFrame("ScrollFrame", nil, F)
    F.scroll = scroll
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    scroll:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -18, 18)
    scroll:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, scroll)
    F.child = child
    child:SetSize(720, 1)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local max = math.max(0, child:GetHeight() - self:GetHeight())
        local v = math.max(0, math.min(max, self:GetVerticalScroll() - delta * 48))
        self:SetVerticalScroll(v)
    end)
    F.rows = {}
    F:Hide()
    return F
end

function RH:Refresh()
    local F = self.Frame
    if not F or not F:IsShown() then return end
    local runs = self:GetRuns()
    local timed, depleted, gain = 0, 0, 0
    for _, r in ipairs(runs) do
        if r.onTime == true then timed = timed + 1 elseif r.onTime == false then depleted = depleted + 1 end
        gain = gain + (tonumber(r.scoreDelta) or 0)
    end
    F.summary:SetText(string.format(L["history_summary"], #runs, timed, depleted, gain))

    for _, row in ipairs(F.rows) do row:Hide() end
    local y = 0
    for i, r in ipairs(runs) do
        local row = F.rows[i]
        if not row then
            row = CreateFrame("Button", nil, F.child)
            row:SetSize(720, 28)
            row.bg = row:CreateTexture(nil,"BACKGROUND"); row.bg:SetAllPoints(); row.bg:SetColorTexture(0.03,0.05,0.075, i % 2 == 0 and .75 or .35)
            row.date = FS(row,10,"","LEFT",row,"LEFT",0,0,TH.textDim or {.55,.65,.75,1})
            row.dungeon = FS(row,11,"","LEFT",row,"LEFT",115,0,TH.text or {1,1,1,1}); row.dungeon:SetWidth(225); row.dungeon:SetWordWrap(false)
            row.key = FS(row,11,"","LEFT",row,"LEFT",350,0,TH.textHeader or {.7,.9,1,1})
            row.time = FS(row,11,"","LEFT",row,"LEFT",410,0,TH.text or {1,1,1,1})
            row.score = FS(row,11,"","LEFT",row,"LEFT",485,0,TH.text or {1,1,1,1})
            row.gain = FS(row,11,"","LEFT",row,"LEFT",565,0,{.2,1,.55,1})
            row.status = FS(row,10,"","LEFT",row,"LEFT",640,0,TH.textDim or {.55,.65,.75,1})
            row:SetScript("OnEnter", function(s) s.bg:SetColorTexture(0,0.35,0.6,.25) end)
            row:SetScript("OnLeave", function(s) s.bg:SetColorTexture(0.03,0.05,0.075, s._even and .75 or .35) end)
            row:SetScript("OnClick", function(s)
                local d = s._data
                if d and d.players and #d.players > 0 and MythicHub_MythicHubScore then
                    MythicHub_MythicHubScore:SafeShowScoreboard(d)
                end
            end)
            F.rows[i] = row
        end
        row._even = i % 2 == 0
        row.bg:SetColorTexture(0.03,0.05,0.075,row._even and .75 or .35)
        row:SetPoint("TOPLEFT", F.child, "TOPLEFT", 0, y)
        row._data = r
        row.date:SetText(date("%d/%m %H:%M", tonumber(r.completedAt) or time()))
        row.dungeon:SetText(r.dungeonName or (DK and DK.GetDungeonName(r.mapID)) or "?")
        row.key:SetText("+" .. tostring(r.keyLevel or 0))
        row.time:SetText(FormatDuration(r.duration))
        row.score:SetText((tonumber(r.runScore) and r.runScore > 0) and string.format("%.0f", r.runScore) or ((tonumber(r.scoreAfter) and r.scoreAfter > 0) and string.format("%.0f", r.scoreAfter) or "—"))
        local delta = tonumber(r.scoreDelta) or 0
        row.gain:SetText(delta ~= 0 and string.format("%+.0f", delta) or "—")
        if r.onTime == true then row.status:SetText(L["history_timed"]); row.status:SetTextColor(.2,1,.55,1)
        elseif r.onTime == false then row.status:SetText(L["history_depleted"]); row.status:SetTextColor(1,.35,.35,1)
        else row.status:SetText(L["history_complete"]); row.status:SetTextColor(.75,.82,.9,1) end
        row:Show()
        y = y - 30
    end
    F.child:SetHeight(math.max(1, #runs * 30))
end

function RH:Show()
    local db = DB(); if db and db.enabled == false then return end
    local F = self:Build()
    self:SyncFromBlizzard()
    F:Show(); F:Raise(); self:Refresh()
end
function RH:Hide() if self.Frame then self.Frame:Hide() end end
function RH:Toggle() if self.Frame and self.Frame:IsShown() then self:Hide() else self:Show() end end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("CHALLENGE_MODE_COMPLETED")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(3, function() RH:SyncFromBlizzard() end)
    else
        C_Timer.After(4, function() RH:SyncFromBlizzard(); RH:Refresh() end)
    end
end)
