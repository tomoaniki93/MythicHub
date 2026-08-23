-- =====================================================================
-- ScorePlanner.lua — MythicHub Score Planner / Upgrade Finder
-- =====================================================================

MythicHub_ScorePlanner = MythicHub_ScorePlanner or {}
local SP = MythicHub_ScorePlanner
local L  = MythicHub_L
local DK = MythicHub_DataKeys
local TH = MythicHub_Widgets and MythicHub_Widgets.Theme or {}

local function DB() return MythicHubDB and MythicHubDB.scorePlanner end

local function FS(parent, size, text, point, rel, relPoint, x, y, color)
    local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f:SetPoint(point or "LEFT", rel or parent, relPoint or point or "LEFT", x or 0, y or 0)
    f:SetText(text or "")
    f:SetFont(select(1, f:GetFont()), size or 11, "OUTLINE")
    if color then f:SetTextColor(color[1],color[2],color[3],color[4] or 1) end
    return f
end

local function Button(parent, label, w, fn)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate"); b:SetSize(w or 100,28)
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    b:SetBackdropColor(.05,.08,.12,.95); b:SetBackdropBorderColor(0,.45,.72,1)
    local t=FS(b,11,label,"CENTER",b,"CENTER",0,0,TH.text or {1,1,1,1})
    b:SetScript("OnEnter",function(s)s:SetBackdropBorderColor(0,.686,1,1);t:SetTextColor(1,1,1,1)end)
    b:SetScript("OnLeave",function(s)s:SetBackdropBorderColor(0,.45,.72,1);t:SetTextColor(.9,.95,1,1)end)
    b:SetScript("OnClick",fn); return b
end

local function BuildRunMap()
    local summary = C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary and C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    local byMap, points = {}, {}
    if summary and type(summary.runs) == "table" then
        for _, r in ipairs(summary.runs) do
            local mapID = tonumber(r.challengeModeID)
            if mapID then
                local item = {
                    mapID = mapID,
                    score = tonumber(r.mapScore) or 0,
                    level = tonumber(r.bestRunLevel) or 0,
                    durationMS = tonumber(r.bestRunDurationMS) or 0,
                    timed = r.finishedSuccess and true or false,
                }
                byMap[mapID] = item
                if item.level > 0 and item.score > 0 then points[#points+1] = {x=item.level,y=item.score} end
            end
        end
    end
    return byMap, points, summary and tonumber(summary.currentSeasonScore) or 0
end

-- Empirical slope from the player's own season data. This intentionally avoids
-- hardcoding a score formula that Blizzard may change between seasons.
local function EstimateSlope(points)
    if #points < 2 then return 10 end
    local sx, sy = 0, 0
    for _,p in ipairs(points) do sx=sx+p.x; sy=sy+p.y end
    local mx,my=sx/#points,sy/#points
    local num,den=0,0
    for _,p in ipairs(points) do num=num+(p.x-mx)*(p.y-my); den=den+(p.x-mx)^2 end
    if den <= 0 then return 10 end
    local slope=num/den
    if slope < 4 then slope=4 elseif slope > 25 then slope=25 end
    return slope
end

local function AverageLevel(points)
    if #points == 0 then return 2 end
    local s=0; for _,p in ipairs(points) do s=s+p.x end
    return math.max(2, math.floor(s/#points + .5))
end

function SP:GetPlan()
    if DK and DK.RefreshFromAPI then DK.RefreshFromAPI() end
    local byMap, points, overall = BuildRunMap()
    local slope = EstimateSlope(points)
    local avgLevel = AverageLevel(points)
    local db = DB() or {}
    local increase = math.max(1, math.min(3, tonumber(db.targetIncrease) or 1))
    local ids = DK and DK.GetCurrentSeasonIDs and DK.GetCurrentSeasonIDs() or {}
    local rows = {}
    for _, mapID in ipairs(ids) do
        local cur = byMap[mapID] or {mapID=mapID,score=0,level=0,timed=false}
        local target = cur.level > 0 and (cur.level + increase) or avgLevel
        local estGain
        if cur.level > 0 then
            estGain = slope * math.max(1, target-cur.level)
            if cur.timed == false then estGain = estGain + slope * .5 end
        else
            -- A missing dungeon is almost always the biggest upgrade. Estimate
            -- its value from the player's own average score/level relationship.
            local avgScore=0
            for _,p in ipairs(points) do avgScore=avgScore+p.y end
            avgScore = #points > 0 and avgScore/#points or slope*target
            estGain = math.max(slope*target, avgScore*.85)
        end
        rows[#rows+1] = {
            mapID=mapID,
            name=(DK and DK.GetDungeonName(mapID)) or ("ID:"..tostring(mapID)),
            short=(DK and DK.GetShortName(mapID)) or "",
            level=cur.level or 0,
            score=cur.score or 0,
            timed=cur.timed,
            target=target,
            estimatedGain=math.max(1, math.floor(estGain+.5)),
            teleport=(DK and DK.GetTeleportSpellID(mapID)) or nil,
        }
    end
    table.sort(rows,function(a,b)
        if a.estimatedGain ~= b.estimatedGain then return a.estimatedGain > b.estimatedGain end
        if a.score ~= b.score then return a.score < b.score end
        return a.name < b.name
    end)
    return rows, overall, slope
end

function SP:PrintRecommendation()
    local rows = self:GetPlan()
    local r = rows and rows[1]
    if not r then print(MythicHub.prefix .. " " .. L["planner_no_data"]); return end
    print(MythicHub.prefix, string.format(L["planner_chat_pick"], r.name, r.target, r.estimatedGain))
end

function SP:Build()
    if self.Frame then return self.Frame end
    local F=CreateFrame("Frame","MythicHub_ScorePlannerFrame",UIParent,"BackdropTemplate"); self.Frame=F
    F:SetSize(735,465); F:SetPoint("CENTER"); F:SetFrameStrata("DIALOG"); F:SetClampedToScreen(true); F:SetMovable(true); F:EnableMouse(true); F:RegisterForDrag("LeftButton")
    F:SetScript("OnDragStart",function(s)s:StartMoving()end); F:SetScript("OnDragStop",function(s)s:StopMovingOrSizing()end)
    F:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1}); F:SetBackdropColor(.02,.03,.05,.985); F:SetBackdropBorderColor(0,.45,.72,1)
    MythicHub_Utils.CloseOnEscape(F)
    local ac=F:CreateTexture(nil,"ARTWORK");ac:SetPoint("TOPLEFT",2,-2);ac:SetPoint("TOPRIGHT",-2,-2);ac:SetHeight(3);ac:SetColorTexture(0,.686,1,1)
    F.title=FS(F,20,L["planner_title"],"TOPLEFT",F,"TOPLEFT",18,-18,TH.text or {1,1,1,1})
    F.subtitle=FS(F,11,L["planner_subtitle"],"TOPLEFT",F.title,"BOTTOMLEFT",0,-8,TH.textDim or {.55,.65,.75,1})
    F.score=FS(F,12,"","TOPRIGHT",F,"TOPRIGHT",-170,-22,TH.textHeader or {.7,.9,1,1})
    local close=Button(F,"×",30,function()SP:Hide()end);close:SetPoint("TOPRIGHT",F,"TOPRIGHT",-12,-12)
    local refresh=Button(F,L["planner_refresh"],110,function()SP:Refresh()end);refresh:SetPoint("RIGHT",close,"LEFT",-8,0)

    local header=CreateFrame("Frame",nil,F); header:SetPoint("TOPLEFT",F,"TOPLEFT",18,-82); header:SetSize(699,24)
    local cols={{L["planner_col_dungeon"],0},{L["planner_col_best"],330},{L["planner_col_score"],405},{L["planner_col_target"],485},{L["planner_col_gain"],565},{L["planner_col_action"],635}}
    for _,c in ipairs(cols) do FS(header,10,c[1],"LEFT",header,"LEFT",c[2],0,TH.textHeader or {.7,.9,1,1}) end
    F.rows={}
    for i=1,8 do
        local row=CreateFrame("Frame",nil,F); row:SetSize(699,36); row:SetPoint("TOPLEFT",header,"BOTTOMLEFT",0,-4-(i-1)*39)
        row.bg=row:CreateTexture(nil,"BACKGROUND"); row.bg:SetAllPoints(); row.bg:SetColorTexture(.03,.05,.075,i%2==0 and .75 or .35)
        row.rank=FS(row,10,tostring(i),"LEFT",row,"LEFT",8,0,TH.textDim or {.55,.65,.75,1})
        row.name=FS(row,11,"","LEFT",row,"LEFT",32,0,TH.text or {1,1,1,1}); row.name:SetWidth(290); row.name:SetWordWrap(false)
        row.best=FS(row,11,"","LEFT",row,"LEFT",330,0,TH.text or {1,1,1,1})
        row.score=FS(row,11,"","LEFT",row,"LEFT",405,0,TH.text or {1,1,1,1})
        row.target=FS(row,11,"","LEFT",row,"LEFT",485,0,TH.textHeader or {.7,.9,1,1})
        row.gain=FS(row,12,"","LEFT",row,"LEFT",565,0,{.2,1,.55,1})
        row.tp=CreateFrame("Button",nil,row,"SecureActionButtonTemplate,BackdropTemplate")
        row.tp:SetSize(60,28)
        row.tp:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        row.tp:SetBackdropColor(.05,.08,.12,.95); row.tp:SetBackdropBorderColor(0,.45,.72,1)
        row.tp.text=FS(row.tp,11,L["planner_tp"],"CENTER",row.tp,"CENTER",0,0,TH.text or {1,1,1,1})
        row.tp:SetAttribute("type","spell")
        row.tp:SetPoint("RIGHT",row,"RIGHT",0,0)
        F.rows[i]=row
    end
    F.note=FS(F,10,L["planner_estimate_note"],"BOTTOMLEFT",F,"BOTTOMLEFT",18,16,TH.textDim or {.55,.65,.75,1}); F.note:SetWidth(690);F.note:SetWordWrap(true)
    F:Hide(); return F
end

function SP:Refresh()
    local F=self.Frame; if not F or not F:IsShown() or InCombatLockdown() then return end
    local rows,overall,slope=self:GetPlan()
    F.score:SetText(string.format(L["planner_overall"], math.floor((overall or 0)+.5)))
    for i,row in ipairs(F.rows) do
        local d=rows[i]; row._data=d; row.tp._data=d
        if d then
            row.name:SetText(d.name)
            row.best:SetText(d.level>0 and ("+"..d.level) or "—")
            row.score:SetText(d.score>0 and string.format("%.0f",d.score) or "—")
            row.target:SetText("+"..d.target)
            row.gain:SetText("~+"..d.estimatedGain)
            local canTP = d.teleport ~= nil and (not DK or not DK.IsTeleportKnown or DK.IsTeleportKnown(d.teleport))
            row.tp:SetShown(canTP)
            if canTP and not InCombatLockdown() then row.tp:SetAttribute("spell", d.teleport) end
            if i==1 then row.bg:SetColorTexture(0,.25,.42,.48); row.rank:SetTextColor(0,.8,1,1) else row.bg:SetColorTexture(.03,.05,.075,i%2==0 and .75 or .35); row.rank:SetTextColor(.55,.65,.75,1) end
            row:Show()
        else row:Hide() end
    end
end
function SP:Show() local db=DB();if db and db.enabled==false then return end;if InCombatLockdown() then print(MythicHub.prefix .. " " .. L["planner_combat"]) return end;local F=self:Build();F:Show();F:Raise();self:Refresh()end
function SP:Hide()
    if not self.Frame then return end
    if InCombatLockdown() then self._hideAfterCombat = true; return end
    self.Frame:Hide()
end
function SP:Toggle() if self.Frame and self.Frame:IsShown() then self:Hide() else self:Show() end end
local ev=CreateFrame("Frame");ev:RegisterEvent("PLAYER_REGEN_ENABLED");ev:SetScript("OnEvent",function() if SP._hideAfterCombat then SP._hideAfterCombat=nil;SP:Hide() end end)
