-- MythicHub modern standalone configuration
MythicHub_Config = MythicHub_Config or {}
local CFG = MythicHub_Config
local MH = MythicHub
local L = MythicHub_L
local TH = MythicHub_Widgets.Theme

local W, H = 840, 700
local SIDEBAR = 178
local PAD = 18
local panels = {}
local navButtons = {}
local refreshers = {}

local function Color(tex, c, alpha)
    tex:SetColorTexture(c[1], c[2], c[3], alpha or c[4] or 1)
end

local function MakeText(parent, size, text, point, rel, relPoint, x, y, color, width)
    local fs = parent:CreateFontString(nil, "OVERLAY", size >= 16 and "GameFontNormalLarge" or "GameFontNormal")
    fs:SetPoint(point or "TOPLEFT", rel or parent, relPoint or point or "TOPLEFT", x or 0, y or 0)
    fs:SetText(text or "")
    if color then fs:SetTextColor(color[1], color[2], color[3], color[4] or 1) end
    if width then fs:SetWidth(width); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true) end
    return fs
end

local function MakePanel(parent)
    local p = CreateFrame("Frame", nil, parent)
    p:SetPoint("TOPLEFT", parent, "TOPLEFT", SIDEBAR + PAD, -72)
    p:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -PAD, PAD)
    p:Hide()
    return p
end

local function Section(parent, title, x, y, w)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    box:SetSize(w, 1)
    box:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    box:SetBackdropColor(TH.bgMid[1], TH.bgMid[2], TH.bgMid[3], 0.62)
    box:SetBackdropBorderColor(TH.border[1], TH.border[2], TH.border[3], 0.8)
    MakeText(box, 14, title, "TOPLEFT", box, "TOPLEFT", 12, -10, TH.textHeader)
    return box
end

local function GetPath(path)
    local t = MythicHubDB
    for i=1,#path-1 do if not t then return nil end; t=t[path[i]] end
    return t, path[#path]
end

local function Check(parent, label, path, x, y, callback)
    local b = CreateFrame("Button", nil, parent)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b:SetSize(270, 24)

    local box = b:CreateTexture(nil, "ARTWORK")
    box:SetPoint("LEFT", 0, 0); box:SetSize(16,16); Color(box, TH.bgDark)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", box, -1, 1); border:SetPoint("BOTTOMRIGHT", box, 1, -1); Color(border, TH.border)
    box:SetDrawLayer("OVERLAY", 2)
    local mark = b:CreateTexture(nil, "OVERLAY", nil, 3)
    mark:SetPoint("CENTER", box); mark:SetSize(10,10); Color(mark, TH.accent)

    local text = MakeText(b, 12, label, "LEFT", box, "RIGHT", 9, 0, TH.text)
    text:SetWidth(235)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)

    local function Refresh()
        local t,k = GetPath(path)
        local on = t and t[k] ~= false
        mark:SetShown(on)
        text:SetTextColor(on and TH.text[1] or TH.textDim[1], on and TH.text[2] or TH.textDim[2], on and TH.text[3] or TH.textDim[3])
    end
    b:SetScript("OnClick", function()
        local t,k = GetPath(path); if not t then return end
        t[k] = not (t[k] ~= false)
        Refresh()
        if callback then callback(t[k]) end
        MH:ApplyLiveSettings()
    end)
    b:SetScript("OnEnter", function() text:SetTextColor(TH.accent[1], TH.accent[2], TH.accent[3]) end)
    b:SetScript("OnLeave", Refresh)
    refreshers[#refreshers+1] = Refresh
    Refresh()
    return b
end

local function Action(parent, label, x, y, w, fn)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    b:SetSize(w or 170, 30)
    b:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    b:SetBackdropColor(TH.bgLight[1], TH.bgLight[2], TH.bgLight[3], 0.92)
    b:SetBackdropBorderColor(TH.accentDark[1], TH.accentDark[2], TH.accentDark[3], 0.95)
    local txt = MakeText(b, 12, label, "CENTER", b, "CENTER", 0, 0, TH.text)
    b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(TH.accent[1],TH.accent[2],TH.accent[3],1); txt:SetTextColor(1,1,1) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(TH.accentDark[1],TH.accentDark[2],TH.accentDark[3],.95); txt:SetTextColor(TH.text[1],TH.text[2],TH.text[3]) end)
    b:SetScript("OnClick", fn)
    return b
end

local function Slider(parent, label, path, minv, maxv, step, x, y, w, callback, formatter)
    local wrap = CreateFrame("Frame", nil, parent)
    wrap:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    wrap:SetSize(w or 260, 42)
    local lbl = MakeText(wrap, 11, label, "TOPLEFT", wrap, "TOPLEFT", 0, 0, TH.text)
    local val = MakeText(wrap, 11, "", "TOPRIGHT", wrap, "TOPRIGHT", 0, 0, TH.textHeader)
    local s = CreateFrame("Slider", nil, wrap, "BackdropTemplate")
    s:SetPoint("TOPLEFT", wrap, "TOPLEFT", 0, -20)
    s:SetPoint("TOPRIGHT", wrap, "TOPRIGHT", 0, -20)
    s:SetHeight(10)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(minv,maxv); s:SetValueStep(step); s:SetObeyStepOnDrag(true)
    s:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    s:SetBackdropColor(TH.bgDark[1],TH.bgDark[2],TH.bgDark[3],1)
    s:SetBackdropBorderColor(TH.border[1],TH.border[2],TH.border[3],1)
    local thumb = s:CreateTexture(nil,"OVERLAY"); thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal"); thumb:SetSize(18,18); s:SetThumbTexture(thumb)
    local changing = false
    local function Format(v) return formatter and formatter(v) or string.format("%.2f",v) end
    local function Refresh()
        local t,k=GetPath(path); local v=t and tonumber(t[k]) or minv
        changing=true; s:SetValue(v); changing=false; val:SetText(Format(v))
    end
    s:SetScript("OnValueChanged", function(_,v,user)
        if changing then return end
        local t,k=GetPath(path); if not t then return end
        t[k]=v; val:SetText(Format(v)); if callback then callback(v) end; MH:ApplyLiveSettings()
    end)
    refreshers[#refreshers+1]=Refresh; Refresh()
    return wrap
end

local function Cycle(parent, label, path, values, display, x, y, w, callback)
    local wrap = CreateFrame("Frame", nil, parent)
    wrap:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); wrap:SetSize(w or 260, 46)
    MakeText(wrap, 11, label, "TOPLEFT", wrap, "TOPLEFT", 0, 0, TH.text)
    local b = Action(wrap, "", 0, -18, w or 260, nil)
    local btnText = b:GetRegions(); if not btnText or not btnText.SetText then
        -- Action's font string isn't named; discover the first FontString.
        for _,r in ipairs({b:GetRegions()}) do if r:IsObjectType("FontString") then btnText=r; break end end
    end
    local function Refresh()
        local t,k=GetPath(path); local cur=t and t[k] or values[1]
        if btnText and btnText.SetText then btnText:SetText(display[cur] or tostring(cur)) end
    end
    b:SetScript("OnClick", function()
        local t,k=GetPath(path); if not t then return end
        local cur=t[k]; local idx=1
        for i,v in ipairs(values) do if v==cur then idx=i; break end end
        idx=idx%#values+1; t[k]=values[idx]
        if callback then callback(t[k]) end
        Refresh(); MH:ApplyLiveSettings()
    end)
    refreshers[#refreshers+1]=Refresh; Refresh()
    return wrap
end

local function Card(parent, title, x, y, w)
    local c = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    c:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); c:SetSize(w,76)
    c:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    c:SetBackdropColor(TH.bgMid[1],TH.bgMid[2],TH.bgMid[3],.82); c:SetBackdropBorderColor(TH.border[1],TH.border[2],TH.border[3],.8)
    c.title=MakeText(c,10,title,"TOPLEFT",c,"TOPLEFT",12,-10,TH.textDim)
    c.value=MakeText(c,20,"—","BOTTOMLEFT",c,"BOTTOMLEFT",12,13,TH.textHeader)
    return c
end

function CFG:Select(name)
    for key,p in pairs(panels) do p:SetShown(key==name) end
    for key,b in pairs(navButtons) do
        if key==name then b._bar:Show(); b._txt:SetTextColor(TH.text[1],TH.text[2],TH.text[3])
        else b._bar:Hide(); b._txt:SetTextColor(TH.textDim[1],TH.textDim[2],TH.textDim[3]) end
    end
    self.selected=name
    self:Refresh()
end

function CFG:Refresh()
    for _,fn in ipairs(refreshers) do pcall(fn) end
    if self.RefreshDashboard then self:RefreshDashboard() end
end

function CFG:Build()
    if self.Frame then return self.Frame end
    local F=CreateFrame("Frame","MythicHub_ConfigFrame",UIParent,"BackdropTemplate")
    self.Frame=F; F:SetSize(W,H); F:SetPoint("CENTER"); F:SetFrameStrata("DIALOG"); F:SetFrameLevel(300); F:SetClampedToScreen(true); F:SetMovable(true); F:EnableMouse(true); F:RegisterForDrag("LeftButton")
    F:SetScript("OnDragStart",function(s) s:StartMoving() end); F:SetScript("OnDragStop",function(s)s:StopMovingOrSizing()end)
    F:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1}); F:SetBackdropColor(TH.bg[1],TH.bg[2],TH.bg[3],.985); F:SetBackdropBorderColor(TH.accentDark[1],TH.accentDark[2],TH.accentDark[3],1)
    MythicHub_Utils.CloseOnEscape(F)

    local accent=F:CreateTexture(nil,"ARTWORK"); accent:SetPoint("TOPLEFT",2,-2); accent:SetPoint("TOPRIGHT",-2,-2); accent:SetHeight(3); Color(accent,TH.accent)
    MakeText(F,22,L["gui_title"],"TOPLEFT",F,"TOPLEFT",20,-19,TH.text)
    MakeText(F,11,L["gui_subtitle"],"TOPLEFT",F,"TOPLEFT",20,-48,TH.textDim)
    local ver=MakeText(F,10,"v"..MH.version,"TOPRIGHT",F,"TOPRIGHT",-48,-27,TH.textDim)
    local close=Action(F,"×",W-42,-15,28,function()F:Hide()end); close:SetHeight(28)

    local sidebar=CreateFrame("Frame",nil,F,"BackdropTemplate"); sidebar:SetPoint("TOPLEFT",F,"TOPLEFT",0,-68); sidebar:SetPoint("BOTTOMLEFT",F,"BOTTOMLEFT",0,0); sidebar:SetWidth(SIDEBAR); sidebar:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8"}); sidebar:SetBackdropColor(TH.bgDark[1],TH.bgDark[2],TH.bgDark[3],.92)

    local tabs={{"dashboard",L["gui_dashboard"]},{"tracker",L["gui_tracker"]},{"keys",L["gui_keys_score"]},{"progression",L["gui_progression"]},{"character",L["gui_character"]},{"brez",L["gui_brez"]}}
    for i,info in ipairs(tabs) do
        local key,label=info[1],info[2]
        local b=CreateFrame("Button",nil,sidebar); b:SetPoint("TOPLEFT",sidebar,"TOPLEFT",0,-(18+(i-1)*44)); b:SetSize(SIDEBAR,38)
        b._txt=MakeText(b,12,label,"LEFT",b,"LEFT",20,0,TH.textDim)
        b._bar=b:CreateTexture(nil,"ARTWORK"); b._bar:SetPoint("TOPLEFT",0,0); b._bar:SetPoint("BOTTOMLEFT",0,0); b._bar:SetWidth(3); Color(b._bar,TH.accent); b._bar:Hide()
        b:SetScript("OnClick",function()CFG:Select(key)end); b:SetScript("OnEnter",function() b._txt:SetTextColor(TH.accent[1],TH.accent[2],TH.accent[3]) end); b:SetScript("OnLeave",function() CFG:Select(CFG.selected or "dashboard") end)
        navButtons[key]=b; panels[key]=MakePanel(F)
    end

    -- DASHBOARD
    local p=panels.dashboard
    MakeText(p,18,L["gui_dashboard"],"TOPLEFT",p,"TOPLEFT",0,0,TH.text)
    MakeText(p,11,L["gui_about"],"TOPLEFT",p,"TOPLEFT",0,-28,TH.textDim,610)
    local cardW=142
    self.cards={score=Card(p,"MYTHIC+ SCORE",0,-68,cardW), key=Card(p,"YOUR KEY",154,-68,cardW), group=Card(p,"GROUP KEYS",308,-68,cardW), brez=Card(p,"BATTLE REZ",462,-68,cardW)}
    local mod=Section(p,L["gui_modules"],0,-162,602); mod:SetHeight(238)
    Check(mod,"Mythic+ Hub",{"mythicHub","enabled"},12,-38,function(on) if not on and MythicHub_MythicHub then MythicHub_MythicHub:Hide() end end)
    Check(mod,"Mythic+ Tracker",{"MythicTracker","enabled"},12,-68,function(on) if not on and MythicHub_MythicTracker then MythicHub_MythicTracker:HideFrame() end end)
    Check(mod,L["gui_score_name"],{"MythicHubScore","enabled"},12,-98,function(on) if not on and MythicHub_MythicHubScore then MythicHub_MythicHubScore:HideScoreboard() end end)
    Check(mod,"Keystone Viewer / Roulette",{"MythicKeys","enabled"},12,-128)
    Check(mod,L["gui_keysync"],{"KeySync","enabled"},310,-38)
    Check(mod,L["gui_auto_key"],{"autoKeystone","enabled"},310,-68)
    Check(mod,"Character + Inspect",{"characterSkin","enabled"},310,-98)
    Check(mod,"Battle Rez",{"battleRez","enabled"},310,-128,function() if MythicHub_ResurrectTracker then MythicHub_ResurrectTracker.ApplySettings() end end)
    Check(mod,L["gui_run_history"],{"runHistory","enabled"},12,-158,function(on) if not on and MythicHub_RunHistory then MythicHub_RunHistory:Hide() end end)
    Check(mod,L["gui_score_planner"],{"scorePlanner","enabled"},12,-188,function(on) if not on and MythicHub_ScorePlanner then MythicHub_ScorePlanner:Hide() end end)
    Check(mod,L["gui_advisor"],{"advisor","enabled"},310,-158)
    Check(mod,L["gui_minimap"],{"minimap","enabled"},310,-188,function() if MythicHub_Minimap then MythicHub_Minimap:ApplySettings() end end)

    local quick=Section(p,L["gui_quick"],0,-416,602); quick:SetHeight(158)
    Action(quick,L["gui_open_hub"],12,-38,180,function() if MythicHub_MythicHub then MythicHub_MythicHub:Toggle() end end)
    Action(quick,L["gui_send_keys"],204,-38,180,function() if MythicHub_MythicKeys then MythicHub_MythicKeys:SendKeysToChat() end end)
    Action(quick,L["gui_roulette"],396,-38,180,function() if MythicHub_MythicKeys then MythicHub_MythicKeys:ShowKeyRoulette() end end)
    Action(quick,L["gui_tracker_preview"],12,-78,180,function() if MythicHub_MythicTracker then MythicHub_MythicTracker:Preview() end end)
    Action(quick,L["gui_score_preview"],204,-78,180,function() if MythicHub_MythicHubScore then MythicHub_MythicHubScore:ShowPreview() end end)
    Action(quick,L["gui_advisor_btn"],396,-78,180,function() if MythicHub_KeystoneAdvisor then MythicHub_KeystoneAdvisor:PrintRecommendation() end end)
    Action(quick,L["gui_unlock"],12,-118,276,function() MH:SetLayoutUnlocked(true); CFG:Refresh() end)
    Action(quick,L["gui_lock"],300,-118,276,function() MH:SetLayoutUnlocked(false); CFG:Refresh() end)

    -- TRACKER
    p=panels.tracker
    MakeText(p,18,L["gui_tracker"],"TOPLEFT",p,"TOPLEFT",0,0,TH.text)
    local general=Section(p,L["gui_display"],0,-38,290); general:SetHeight(310)
    Check(general,L["gui_enabled"],{"MythicTracker","enabled"},12,-38)
    Check(general,L["gui_hide_blizzard"],{"MythicTracker","hideBlizzard"},12,-68)
    Check(general,L["gui_show_timer"],{"MythicTracker","showTimer"},12,-98)
    Check(general,L["gui_show_forces"],{"MythicTracker","showForces"},12,-128)
    Check(general,L["gui_show_bosses"],{"MythicTracker","showBosses"},12,-158)
    Check(general,L["gui_show_background"],{"MythicTracker","showBackground"},12,-188)
    Check(general,L["gui_show_header"],{"MythicTracker","showHeaderBlock"},12,-218)
    Check(general,L["gui_show_dungeon"],{"MythicTracker","showDungeonName"},12,-248)
    Check(general,L["gui_splits"],{"MythicTracker","splitsEnabled"},12,-278)

    local style=Section(p,L["gui_style_progress"],304,-38,298); style:SetHeight(310)
    Cycle(style,L["gui_preset"],{"MythicTracker","preset"},{"panel","hud","minimal"},{panel="Panel",hud="HUD",minimal="Minimal"},12,-38,270,function(v) if MythicHub_MythicTracker then MythicHub_MythicTracker:ApplyPreset(v); MythicHub_MythicTracker:RefreshStyle() end end)
    Cycle(style,L["gui_objective"],{"MythicTracker","objectiveStyle"},{"rows","text","none"},{rows="Rows",text="Text",none="Hidden"},12,-92,270,function() if MythicHub_MythicTracker then MythicHub_MythicTracker:ResolvePreset() end end)
    Cycle(style,L["gui_timer_layout"],{"MythicTracker","timerLayout"},{"stacked","inline"},{stacked="Stacked",inline="Inline"},12,-146,270,function() if MythicHub_MythicTracker then MythicHub_MythicTracker:ResolvePreset() end end)
    Cycle(style,L["gui_segment"],{"MythicTracker","segmentColors"},{"palier","brand"},{palier="Tier colors",brand="Azure"},12,-200,270,function() if MythicHub_MythicTracker then MythicHub_MythicTracker:ResolvePreset() end end)
    Check(style,L["gui_checkpoints"],{"MythicTracker","checkpointsEnabled"},12,-258)

    local sizes=Section(p,L["gui_size_opacity"],0,-362,602); sizes:SetHeight(150)
    Slider(sizes,L["gui_scale"],{"MythicTracker","scale"},0.65,1.50,0.05,12,-38,270,function(v) if MythicHub_MythicTracker and MythicHub_MythicTracker.Frame then MythicHub_MythicTracker.Frame:SetScale(v) end end,function(v)return string.format("%d%%",v*100)end)
    Slider(sizes,L["gui_alpha"],{"MythicTracker","alpha"},0.30,1.00,0.05,310,-38,270,nil,function(v)return string.format("%d%%",v*100)end)
    Slider(sizes,L["gui_font_scale"],{"MythicTracker","fontScale"},0.70,1.50,0.05,12,-92,270,nil,function(v)return string.format("%d%%",v*100)end)
    Action(sizes,L["gui_tracker_preview"],310,-94,132,function() if MythicHub_MythicTracker then MythicHub_MythicTracker:Preview() end end)
    Action(sizes,L["gui_reset_pos"],448,-94,132,function() if MythicHub_MythicTracker then MythicHub_MythicTracker:ResetPosition() end end)

    -- KEYS & SCORE
    p=panels.keys
    MakeText(p,18,L["gui_keys_score"],"TOPLEFT",p,"TOPLEFT",0,0,TH.text)
    local keys=Section(p,L["gui_keystones"],0,-38,602); keys:SetHeight(214)
    Check(keys,"Keystone module",{"MythicKeys","enabled"},12,-38)
    Check(keys,L["gui_keysync"],{"KeySync","enabled"},12,-68)
    Check(keys,L["gui_auto_key"],{"autoKeystone","enabled"},12,-98)
    Check(keys,L["gui_advisor"],{"advisor","enabled"},12,-128)
    Action(keys,L["gui_send_keys"],310,-38,260,function() if MythicHub_MythicKeys then MythicHub_MythicKeys:SendKeysToChat() end end)
    Action(keys,L["gui_roulette"],310,-78,260,function() if MythicHub_MythicKeys then MythicHub_MythicKeys:ShowKeyRoulette() end end)
    Action(keys,L["gui_advisor_btn"],310,-118,260,function() if MythicHub_KeystoneAdvisor then MythicHub_KeystoneAdvisor:PrintRecommendation() end end)

    local score=Section(p,L["gui_score_name"],0,-268,602); score:SetHeight(286)
    Check(score,L["gui_enabled"],{"MythicHubScore","enabled"},12,-38)
    Check(score,L["gui_auto_score"],{"MythicHubScore","autoShowMPlus"},12,-68)
    Slider(score,L["gui_scale"],{"MythicHubScore","scale"},0.65,1.50,0.05,12,-108,270,nil,function(v)return string.format("%d%%",v*100)end)
    Slider(score,L["gui_alpha"],{"MythicHubScore","alpha"},0.30,1.00,0.05,310,-108,270,nil,function(v)return string.format("%d%%",v*100)end)
    Action(score,L["gui_score_preview"],12,-172,178,function() if MythicHub_MythicHubScore then MythicHub_MythicHubScore:ShowPreview() end end)
    Action(score,L["gui_score_last"],202,-172,178,function() if MythicHub_MythicHubScore then MythicHub_MythicHubScore:ShowLastRun() end end)
    Action(score,L["gui_reset_pos"],392,-172,178,function() if MythicHub_MythicHubScore then MythicHub_MythicHubScore:ResetPosition() end end)
    Action(score,L["gui_unlock_score"],12,-214,276,function()
        if MythicHub_MythicHubScore then MythicHub_MythicHubScore:SetMovable(true) end
    end)
    Action(score,L["gui_lock_score"],300,-214,276,function()
        if MythicHub_MythicHubScore then MythicHub_MythicHubScore:SetMovable(false) end
    end)

    -- PROGRESSION
    p=panels.progression
    MakeText(p,18,L["gui_progression"],"TOPLEFT",p,"TOPLEFT",0,0,TH.text)

    local hist=Section(p,L["gui_run_history"],0,-38,602); hist:SetHeight(190)
    Check(hist,L["gui_enabled"],{"runHistory","enabled"},12,-38,function(on) if not on and MythicHub_RunHistory then MythicHub_RunHistory:Hide() end end)
    Slider(hist,L["gui_history_max"],{"runHistory","maxRuns"},25,250,25,12,-78,270,nil,function(v)return tostring(math.floor(v+0.5))end)
    Action(hist,L["gui_open_history"],310,-38,260,function() if MythicHub_RunHistory then MythicHub_RunHistory:Toggle() end end)
    Action(hist,L["gui_sync_history"],310,-78,260,function() if MythicHub_RunHistory then MythicHub_RunHistory:SyncFromBlizzard(); MythicHub_RunHistory:Refresh() end end)
    Action(hist,L["gui_clear_history"],310,-118,260,function()
        if not IsShiftKeyDown() then print(MH.prefix .. " " .. L["history_shift_clear"]); return end
        if MythicHub_RunHistory then MythicHub_RunHistory:Clear() end
    end)

    local planner=Section(p,L["gui_score_planner"],0,-242,602); planner:SetHeight(176)
    Check(planner,L["gui_enabled"],{"scorePlanner","enabled"},12,-38,function(on) if not on and MythicHub_ScorePlanner then MythicHub_ScorePlanner:Hide() end end)
    Cycle(planner,L["gui_target_increase"],{"scorePlanner","targetIncrease"},{1,2,3},{[1]="+1",[2]="+2",[3]="+3"},12,-78,270,function() if MythicHub_ScorePlanner then MythicHub_ScorePlanner:Refresh() end end)
    Action(planner,L["gui_open_planner"],310,-38,260,function() if MythicHub_ScorePlanner then MythicHub_ScorePlanner:Toggle() end end)
    Action(planner,L["gui_advisor_btn"],310,-78,260,function() if MythicHub_ScorePlanner then MythicHub_ScorePlanner:PrintRecommendation() end end)

    local access=Section(p,L["gui_minimap"],0,-432,602); access:SetHeight(132)
    Check(access,L["gui_minimap"],{"minimap","enabled"},12,-38,function() if MythicHub_Minimap then MythicHub_Minimap:ApplySettings() end end)
    MakeText(access,11,L["minimap_tooltip"],"TOPLEFT",access,"TOPLEFT",12,-74,TH.textDim,566)

    -- CHARACTER
    p=panels.character
    MakeText(p,18,L["gui_character"],"TOPLEFT",p,"TOPLEFT",0,0,TH.text)
    local skin=Section(p,L["gui_character_sheet"],0,-38,602); skin:SetHeight(292)
    Check(skin,L["gui_enabled"],{"characterSkin","enabled"},12,-38)
    Check(skin,L["gui_char_skin"],{"characterSkin","skinCharacter"},12,-68)
    Check(skin,L["gui_inspect_skin"],{"characterSkin","skinInspect"},12,-98)
    Check(skin,L["gui_item_info"],{"characterSkin","showItemInfo"},12,-128)
    Check(skin,L["gui_gems"],{"characterSkin","showGems"},12,-158)
    Check(skin,L["gui_inspect_info"],{"characterSkin","showInspectItemInfo"},12,-188)
    Check(skin,L["gui_char_movable"],{"characterSkin","movable"},12,-218,function(on) if MythicHub_CharacterSkin then MythicHub_CharacterSkin.SetMovable(on) end end)
    Check(skin,L["gui_midnight_enchants"],{"characterSkin","midnightEnchants"},310,-38,function() if MythicHub_CharacterSkin then MythicHub_CharacterSkin.ApplySettings() end end)
    local note=MakeText(skin,11,L["gui_reload_note"],"TOPLEFT",skin,"TOPLEFT",310,-76,TH.textDim,260)
    Slider(skin,L["gui_character_scale"],{"characterSkin","scale"},0.75,1.50,0.05,310,-122,260,function(v)
        if MythicHub_CharacterSkin and MythicHub_CharacterSkin.ApplyScale then MythicHub_CharacterSkin.ApplyScale(v) end
    end,function(v)return string.format("%d%%",v*100)end)
    Action(skin,L["gui_reset_pos"],310,-190,260,function() if MythicHub_CharacterSkin then MythicHub_CharacterSkin.ResetCharacterPosition() end end)
    local info=Section(p,L["gui_integrated_mplus"],0,-346,602); info:SetHeight(142)
    MakeText(info,11,L["gui_mplus_info_text"],"TOPLEFT",info,"TOPLEFT",12,-40,TH.textDim,566)

    -- BATTLE REZ
    p=panels.brez
    MakeText(p,18,L["gui_brez"],"TOPLEFT",p,"TOPLEFT",0,0,TH.text)
    local rez=Section(p,L["gui_counter"],0,-38,602); rez:SetHeight(272)
    Check(rez,L["gui_enabled"],{"battleRez","enabled"},12,-38,function() if MythicHub_ResurrectTracker then MythicHub_ResurrectTracker.ApplySettings() end end)
    Check(rez,L["gui_only_instance"],{"battleRez","onlyInstance"},12,-68,function() if MythicHub_ResurrectTracker then MythicHub_ResurrectTracker.ApplySettings() end end)
    Check(rez,L["gui_swipe"],{"battleRez","showSwipe"},12,-98,function() if MythicHub_ResurrectTracker then MythicHub_ResurrectTracker.ApplySettings() end end)
    Slider(rez,L["gui_brez_size"],{"battleRez","size"},30,80,1,12,-136,270,function() if MythicHub_ResurrectTracker then MythicHub_ResurrectTracker.ApplySettings() end end,function(v)return tostring(math.floor(v+0.5))end)
    Slider(rez,L["gui_brez_font"],{"battleRez","fontSize"},10,32,1,310,-136,270,function() if MythicHub_ResurrectTracker then MythicHub_ResurrectTracker.ApplySettings() end end,function(v)return tostring(math.floor(v+0.5))end)
    Action(rez,L["gui_unlock"],12,-204,180,function() MH:SetLayoutUnlocked(true) end)
    Action(rez,L["gui_lock"],204,-204,180,function() MH:SetLayoutUnlocked(false) end)
    Action(rez,L["gui_reset_pos"],396,-204,180,function()
        MythicHubDB.battleRez.position={point="CENTER",relativePoint="CENTER",x=0,y=200}; if MythicHub_ResurrectTracker then MythicHub_ResurrectTracker.ApplySettings() end
    end)
    local help=Section(p,L["gui_how_it_works"],0,-326,602); help:SetHeight(156)
    MakeText(help,11,L["gui_brez_help_text"],"TOPLEFT",help,"TOPLEFT",12,-40,TH.textDim,566)

    self:Select("dashboard")
    F:Hide()
    return F
end

function CFG:RefreshDashboard()
    if not self.cards then return end
    local score = C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore and C_ChallengeMode.GetOverallDungeonScore() or 0
    self.cards.score.value:SetText(score and score > 0 and tostring(math.floor(score)) or "—")

    local own = MythicHub_KeySync and MythicHub_KeySync.ReadOwnKeystone and MythicHub_KeySync.ReadOwnKeystone()
    if own and (own.level or 0)>0 then
        local name=MythicHub_DataKeys and MythicHub_DataKeys.GetShortName(own.challengeMapID) or "KEY"
        self.cards.key.value:SetText(string.format("%s +%d",name or "KEY",own.level))
    else self.cards.key.value:SetText("—") end

    local count=0
    if MythicHub_KeySync and MythicHub_KeySync.GetAllKeystonesInfo then
        for _,entry in pairs(MythicHub_KeySync.GetAllKeystonesInfo()) do if entry and (entry.level or 0)>0 then count=count+1 end end
    end
    self.cards.group.value:SetText(tostring(count))

    local cur,maxc = 0,0
    if MythicHub_ResurrectTracker and MythicHub_ResurrectTracker.GetBrezCharges then cur,maxc=MythicHub_ResurrectTracker.GetBrezCharges() end
    self.cards.brez.value:SetText(string.format("%s/%s",tostring(cur or 0),tostring(maxc or 0)))
end

function CFG:Show()
    local F=self:Build(); self:Refresh(); F:Show(); F:Raise()
end
function CFG:Hide() if self.Frame then self.Frame:Hide() end end
function CFG:Toggle() if self.Frame and self.Frame:IsShown() then self:Hide() else self:Show() end end
