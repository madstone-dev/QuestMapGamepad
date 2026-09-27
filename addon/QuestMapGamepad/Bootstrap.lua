local addonName, ns = ...
local events = CreateFrame("Frame")
local elapsed, refreshElapsed, initialized = 0, 0, false
local log = {}
local gossipOpen, questOpen = false, false
local function note(message)
    log[#log + 1] = message
    if #log > 25 then table.remove(log, 1) end
end

local function status()
    local version, build = GetBuildInfo()
    return string.format("QuestMap Gamepad 0.2.0 | WoW %s (%s) | pins=%d | missingActive=%d | readErrors=%d | locale=%s",
        version or "?", build or "?", #ns.pins, ns.missingActive or 0, ns.readErrors or 0, GetLocale())
end

events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        QuestMapGamepadDB = ns.NormalizeSettings(QuestMapGamepadDB)
        ns.settings = QuestMapGamepadDB
        ns.InitializeSettings()
        ns.InitializeRenderer()
        initialized, ns.dirty = true, true
        self:UnregisterEvent("ADDON_LOADED")
        for _, name in ipairs({"PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED",
            "QUEST_TURNED_IN", "QUEST_DATA_LOAD_RESULT", "PLAYER_LEVEL_UP", "SKILL_LINES_CHANGED", "ZONE_CHANGED_NEW_AREA",
            "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "GOSSIP_SHOW", "GOSSIP_CLOSED", "QUEST_DETAIL",
            "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_FINISHED", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN"}) do
            self:RegisterEvent(name)
        end
        print(ns.L.title .. ": " .. ns.L.ready)
        return
    end
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        if ns.Value(arg1) == addonName then note(event .. " " .. tostring(ns.Value(arg2) or "restricted")) end
        return
    end
    if event == "QUEST_DATA_LOAD_RESULT" then ns.RefreshSettingsDetails(); return end
    if event == "PLAYER_REGEN_DISABLED" then ns.window:Hide(); return end
    if event == "GOSSIP_SHOW" then gossipOpen = true end
    if event == "GOSSIP_CLOSED" then gossipOpen = false end
    if event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then questOpen = true end
    if event == "QUEST_FINISHED" then questOpen = false end
    if event == "PLAYER_ENTERING_WORLD" then gossipOpen, questOpen = false, false end
    ns.dialogue = gossipOpen or questOpen
    if ns.dialogue then ns.window:Hide() end
    if event == "QUEST_TURNED_IN" and ns.Number(arg1) then ns.completed[arg1] = true end
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then ns.ClearCoordinateCache() end
    ns.dirty = true
end)

events:SetScript("OnUpdate", function(_, delta)
    if not initialized then return end
    elapsed, refreshElapsed = elapsed + delta, refreshElapsed + delta
    if ns.dirty and refreshElapsed >= 0.5 and not InCombatLockdown() and not ns.dialogue then
        ns.dirty, refreshElapsed = false, 0
        ns.RefreshModel()
    end
    if elapsed >= 0.1 then elapsed = 0; ns.Render() end
end)

SLASH_QUESTMAPGAMEPAD1 = "/qmg"
SlashCmdList.QUESTMAPGAMEPAD = function(message)
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    if message == "status" then print(status())
    elseif message == "log" then
        print(status())
        for _, entry in ipairs(log) do print(entry) end
    elseif message == "refresh" then ns.dirty = true
    else ns.ToggleSettings() end
end
