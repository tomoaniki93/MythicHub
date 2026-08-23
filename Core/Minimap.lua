-- =====================================================================
-- Minimap.lua — MythicHub minimap button + addon compartment integration
-- =====================================================================

MythicHub_Minimap = MythicHub_Minimap or {}
local MM = MythicHub_Minimap
local L = MythicHub_L
local ICON = "Interface\\AddOns\\MythicHub\\Textures\\MinimapIcon.tga"

local function DB() return MythicHubDB and MythicHubDB.minimap end

function MM:ShowMenu(owner)
    owner = owner or UIParent
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(owner, function(_, root)
            root:CreateTitle("MythicHub")
            root:CreateButton(L["minimap_open_config"], function() if MythicHub_Config then MythicHub_Config:Toggle() end end)
            root:CreateButton(L["minimap_open_hub"], function() if MythicHub_MythicHub then MythicHub_MythicHub:Toggle() end end)
            root:CreateButton(L["minimap_open_history"], function() if MythicHub_RunHistory then MythicHub_RunHistory:Toggle() end end)
            root:CreateButton(L["minimap_open_planner"], function() if MythicHub_ScorePlanner then MythicHub_ScorePlanner:Toggle() end end)
            root:CreateDivider()
            root:CreateButton(L["gui_roulette"], function() if MythicHub_MythicKeys then MythicHub_MythicKeys:ShowKeyRoulette() end end)
            root:CreateButton(L["gui_score_name"], function() if MythicHub_MythicHubScore then MythicHub_MythicHubScore:ShowGroup() end end)
            root:CreateDivider()
            local unlocked = MythicHubDB and MythicHubDB.layoutUnlocked
            root:CreateButton(unlocked and L["gui_lock"] or L["gui_unlock"], function() MythicHub:SetLayoutUnlocked(not unlocked) end)
        end)
    elseif MythicHub_Config then
        MythicHub_Config:Toggle()
    end
end

local function UpdatePosition()
    local b=MM.Button; if not b or not Minimap then return end
    local db=DB() or {}
    local angle=math.rad(tonumber(db.angle) or 225)

    -- Follow the actual minimap edge instead of a fixed inner orbit.
    -- This remains correct when the minimap is resized or scaled.
    local radiusX=(Minimap:GetWidth() or 140)/2
    local radiusY=(Minimap:GetHeight() or 140)/2

    b:ClearAllPoints()
    b:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*radiusX,math.sin(angle)*radiusY)
end

function MM:ApplySettings()
    local b=self.Button; if not b then return end
    local db=DB(); b:SetShown(not db or db.enabled~=false); UpdatePosition()
end

function MM:Build()
    if self.Button or not Minimap then return self.Button end
    local b=CreateFrame("Button","MythicHub_MinimapButton",Minimap); self.Button=b
    b:SetSize(31,31); b:SetFrameStrata("MEDIUM"); b:SetClampedToScreen(true); b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:RegisterForDrag("LeftButton")

    local icon=b:CreateTexture(nil,"ARTWORK")
    icon:SetTexture(ICON)
    icon:SetAllPoints(b)
    icon:SetTexCoord(0,1,0,1)
    b.icon = icon

    local highlight=b:CreateTexture(nil,"HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetPoint("CENTER", b, "CENTER", 0, 0)
    highlight:SetSize(48,48)
    b.highlight = highlight

    b:SetScript("OnClick",function(self,button)
        if button=="RightButton" then MM:ShowMenu(self) elseif MythicHub_Config then MythicHub_Config:Toggle() end
    end)
    b:SetScript("OnDragStart",function(self)
        self:SetScript("OnUpdate",function()
            local db=DB();if not db then return end
            local mx,my=Minimap:GetCenter();local cx,cy=GetCursorPosition();local scale=Minimap:GetEffectiveScale();cx,cy=cx/scale,cy/scale
            local a=(math.atan2 and math.atan2(cy-my,cx-mx)) or math.atan(cy-my,cx-mx)
            db.angle=math.deg(a);UpdatePosition()
        end)
    end)
    b:SetScript("OnDragStop",function(self)self:SetScript("OnUpdate",nil)end)
    b:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT");GameTooltip:SetText("MythicHub",0,.686,1);GameTooltip:AddLine(L["minimap_tooltip"],1,1,1,true);GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function()GameTooltip:Hide()end)
    self:ApplySettings(); return b
end

function MythicHub_OnAddonCompartmentClick()
    if MythicHub_Minimap then MythicHub_Minimap:ShowMenu(UIParent) end
end
function MythicHub_OnAddonCompartmentEnter(button)
    if not button then return end
    GameTooltip:SetOwner(button,"ANCHOR_LEFT");GameTooltip:SetText("MythicHub",0,.686,1);GameTooltip:AddLine(L["minimap_compartment_tooltip"],1,1,1,true);GameTooltip:Show()
end
function MythicHub_OnAddonCompartmentLeave() GameTooltip:Hide() end

local f=CreateFrame("Frame");f:RegisterEvent("PLAYER_LOGIN");f:SetScript("OnEvent",function()MM:Build()end)
