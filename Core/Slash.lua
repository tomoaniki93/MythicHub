local MH = MythicHub
local L = MythicHub_L

local function Help()
    print(MH.prefix .. " |cffffffffcommands:|r")
    print("  |cff00AFFF/mh|r - open settings")
    print("  |cff00AFFF/mh hub|r - open Mythic+ overview")
    print("  |cff00AFFF/mh key|r - announce party keystones in group chat")
    print("  |cff00AFFF/mh kr|r - open Mythic+ key roulette")
    print("  |cff00AFFF/mh tracker|r - preview the Mythic+ tracker")
    print("  |cff00AFFF/mh score|r - show current group MythicHubScore")
    print("  |cff00AFFF/mh score last|r - show last saved run")
    print("  |cff00AFFF/mh ai|r - Keystone Advisor recommendation")
    print("  |cff00AFFF/mh history|r - open MythicHub Run History")
    print("  |cff00AFFF/mh planner|r - open Score Planner / Upgrade Finder")
    print("  |cff00AFFF/mh minimap|r - toggle the MythicHub minimap button")
    print("  |cff00AFFF/mh unlock|r / |cff00AFFF/mh lock|r - move / lock elements")
    print("  |cff00AFFF/mh keysync|r - print KeySync diagnostics")
end

SLASH_MYTHICHUB1 = "/mh"
SlashCmdList["MYTHICHUB"] = function(msg)
    msg = strtrim(msg or "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    rest = (rest or ""):lower()

    if cmd == "" or cmd == "config" or cmd == "options" then
        if MythicHub_Config and MythicHub_Config.Toggle then MythicHub_Config:Toggle() end
    elseif cmd == "hub" then
        if MythicHub_MythicHub then MythicHub_MythicHub:Toggle() end
    elseif cmd == "key" then
        if MythicHub_MythicKeys then MythicHub_MythicKeys:SendKeysToChat() end
    elseif cmd == "kr" or cmd == "roulette" then
        if MythicHub_MythicKeys then MythicHub_MythicKeys:ShowKeyRoulette() end
    elseif cmd == "tracker" or cmd == "preview" then
        if MythicHub_MythicTracker then MythicHub_MythicTracker:Preview() end
    elseif cmd == "score" then
        if MythicHub_MythicHubScore then
            if rest == "last" then MythicHub_MythicHubScore:ShowLastRun()
            else MythicHub_MythicHubScore:ShowGroup() end
        end
    elseif cmd == "unlock" then
        MH:SetLayoutUnlocked(true)
    elseif cmd == "lock" then
        MH:SetLayoutUnlocked(false)
    elseif cmd == "keysync" then
        if MythicHub_KeySync and MythicHub_KeySync.Debug then MythicHub_KeySync.Debug() end
    elseif cmd == "ai" or cmd == "advisor" then
        if MythicHub_KeystoneAdvisor and MythicHub_KeystoneAdvisor.PrintRecommendation then
            MythicHub_KeystoneAdvisor:PrintRecommendation()
        end
    elseif cmd == "history" or cmd == "runs" then
        if MythicHub_RunHistory then MythicHub_RunHistory:Toggle() end
    elseif cmd == "planner" or cmd == "upgrade" or cmd == "upgrades" then
        if MythicHub_ScorePlanner then MythicHub_ScorePlanner:Toggle() end
    elseif cmd == "minimap" then
        if MythicHubDB and MythicHubDB.minimap then
            MythicHubDB.minimap.enabled = not (MythicHubDB.minimap.enabled ~= false)
            if MythicHub_Minimap then MythicHub_Minimap:ApplySettings() end
            print(MH.prefix .. (MythicHubDB.minimap.enabled and " minimap button enabled." or " minimap button disabled."))
        end
    elseif cmd == "reset" then
        if MythicHub_MythicTracker then MythicHub_MythicTracker:ResetPosition() end
        if MythicHub_MythicHubScore then MythicHub_MythicHubScore:ResetPosition() end
        if MythicHub_CharacterSkin then MythicHub_CharacterSkin.ResetCharacterPosition() end
        print(MH.prefix .. " positions reset where supported.")
    elseif cmd == "help" then
        Help()
    else
        print(MH.prefix .. " unknown command: " .. tostring(cmd))
        Help()
    end
end
