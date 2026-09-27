local addonName, ns = ...
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, loadedName)
    if loadedName ~= addonName then return end
    QuestMapGamepadDB = ns.NormalizeSettings(QuestMapGamepadDB)
    ns.settings = QuestMapGamepadDB
    self:UnregisterEvent("ADDON_LOADED")
end)

SLASH_QUESTMAPGAMEPAD1 = "/qmg"
SlashCmdList.QUESTMAPGAMEPAD = function()
    print("QuestMap Gamepad: development foundation; map pins and controller settings are not implemented yet.")
end
