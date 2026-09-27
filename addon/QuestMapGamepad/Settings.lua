local _, ns = ...
local L = ns.L
local buttons, selection, surface, page = {}, 1, "world", 1
local tabs, hint, details, listTitle
local selectedPin, listedPins = nil, {}
local pressedDirection, repeatAt
local updateList

local function padNames()
    if ns.settings.swapButtons then return "PAD2", "PAD1" end
    return "PAD1", "PAD2"
end

local function refresh()
    if not ns.window then return end
    for i, b in ipairs(buttons) do
        b.selected:SetShown(i == selection)
        if b.key then
            local value = ns.settings[surface][b.key]
            b.text:SetText((b.key == "size" and (L.size .. "  < " .. value .. " >")) or ((value and "[x] " or "[ ] ") .. L[b.key]))
        elseif b.swap then
            b.text:SetText((ns.settings.swapButtons and "[x] " or "[ ] ") .. L.swapButtons)
        end
    end
    tabs:SetText((surface == "world" and "|cffffd100[ " or "[ ") .. L.world .. " ]|r     "
        .. (surface == "minimap" and "|cffffd100[ " or "[ ") .. L.minimap .. " ]|r")
    local confirm, cancel = padNames()
    local c = GetBindingText and GetBindingText(confirm, "KEY_") or confirm
    local x = GetBindingText and GetBindingText(cancel, "KEY_") or cancel
    hint:SetText(L.hint:format(c, x))
end

local function changed()
    ns.InvalidatePins()
    updateList()
    refresh()
end

local function move(delta)
    selection = ((selection - 1 + delta) % #buttons) + 1
    local b = buttons[selection]
    if b.pin then selectedPin = b.pin; details:SetText(table.concat(ns.PinDetails(b.pin), "\n")) end
    refresh()
end

function ns.SettingsAction(action)
    if not ns.window or not ns.window:IsShown() then return end
    if action == "close" then ns.window:Hide(); return end
    if action == "up" then move(-1); return end
    if action == "down" then move(1); return end
    local b = buttons[selection]
    if action == "left" or action == "right" then
        if b.key == "size" then
            ns.settings[surface].size = math.max(10, math.min(36, ns.settings[surface].size + (action == "left" and -2 or 2)))
            changed()
        elseif b.tab then
            surface = surface == "world" and "minimap" or "world"; changed()
        end
    elseif action == "confirm" then b:Click() end
end

updateList = function()
    listedPins = {}
    local mapID = WorldMapFrame and WorldMapFrame:IsVisible() and ns.Call(WorldMapFrame.GetMapID, WorldMapFrame)
        or ns.Call(C_Map and C_Map.GetBestMapForUnit, "player")
    local seen = {}
    for _, pin in ipairs(ns.pins) do
        if not seen[pin.id] and ns.ShouldShow(pin, ns.settings, surface) and mapID and ns.Project(pin, mapID) then
            listedPins[#listedPins + 1] = pin; seen[pin.id] = true
        end
    end
    local count = math.max(1, math.ceil(#listedPins / 4))
    page = math.max(1, math.min(page, count))
    listTitle:SetText(L.page:format(page, count))
    for i = 1, 4 do
        local b = ns.listButtons[i]
        b.pin = listedPins[(page - 1) * 4 + i]
        b.text:SetText(b.pin and ns.PinText(b.pin) or "—")
    end
    selectedPin = ns.listButtons[1].pin
    details:SetText(selectedPin and table.concat(ns.PinDetails(selectedPin), "\n") or L.empty)
end

function ns.InitializeSettings()
    local f = CreateFrame("Frame", "QuestMapGamepadSettings", UIParent)
    ns.window = f
    f:SetSize(620, 650)
    f:SetPoint("CENTER")
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(1000)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    local bg = f:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.025, 0.035, 0.055, 0.98)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18); title:SetText(L.title)
    local function row(label, y, callback, x, width)
        local b = CreateFrame("Button", nil, f)
        b:SetSize(width or 280, 27); b:SetPoint("TOPLEFT", x or 20, y)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        b.text:SetPoint("LEFT", 8, 0); b.text:SetWidth((width or 280) - 16); b.text:SetJustifyH("LEFT"); b.text:SetText(label)
        b.selected = b:CreateTexture(nil, "BACKGROUND"); b.selected:SetAllPoints(); b.selected:SetColorTexture(0.2, 0.38, 0.58, 0.8)
        b.selected:Hide()
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b:SetScript("OnClick", callback)
        local index = #buttons + 1; buttons[index] = b
        b:SetScript("OnEnter", function()
            selection = index
            if b.pin then selectedPin = b.pin; details:SetText(table.concat(ns.PinDetails(b.pin), "\n")) end
            refresh()
        end)
        return b
    end
    local tab = row("", -50, function() surface = surface == "world" and "minimap" or "world"; changed() end, 20, 580)
    tab.tab, tabs = true, tab.text
    for i, key in ipairs({"enabled", "start", "objective", "turnin", "lowLevel", "repeatable", "size"}) do
        local b = row("", -84 - (i - 1) * 29, function()
            local options = ns.settings[surface]
            if key == "size" then options.size = options.size >= 36 and 10 or options.size + 2
            else options[key] = not options[key] end
            changed()
        end)
        b.key = key
    end
    local swap = row("", -287, function() ns.settings.swapButtons = not ns.settings.swapButtons; refresh() end, 20, 580)
    swap.swap = true
    row(L.reset, -318, function()
        local defaults = ns.NormalizeSettings(nil)
        ns.settings.world, ns.settings.minimap = defaults.world, defaults.minimap
        changed()
    end)
    local coverage = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    coverage:SetPoint("TOPLEFT", 320, -90); coverage:SetWidth(275); coverage:SetJustifyH("LEFT"); coverage:SetText(L.coverage)
    details = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    details:SetPoint("TOPLEFT", 320, -153); details:SetSize(275, 190); details:SetJustifyH("LEFT"); details:SetJustifyV("TOP")
    listTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listTitle:SetPoint("TOPLEFT", 26, -363)
    ns.listButtons = {}
    for i = 1, 4 do
        local b
        b = row("", -388 - (i - 1) * 29, function()
            if b.pin then selectedPin = b.pin; details:SetText(table.concat(ns.PinDetails(b.pin), "\n")) end
        end, 20, 580)
        ns.listButtons[i] = b
    end
    row(L.previous, -510, function() page = math.max(1, page - 1); updateList() end, 20, 140)
    row(L.next, -510, function() page = page + 1; updateList() end, 170, 140)
    row(L.close, -510, function() f:Hide() end, 460, 140)
    hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 25, -559); hint:SetWidth(570); hint:SetJustifyH("LEFT")
    local help = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    help:SetPoint("TOPLEFT", 25, -601); help:SetText("/qmg · /qmg status · /qmg log")
    f:EnableKeyboard(true)
    f:SetPropagateKeyboardInput(false)
    f:SetScript("OnKeyDown", function(_, key)
        local action = ({UP="up", DOWN="down", LEFT="left", RIGHT="right", ENTER="confirm", SPACE="confirm", ESCAPE="close"})[key]
        if action then ns.SettingsAction(action) end
    end)
    if f.EnableGamePadButton then
        f:EnableGamePadButton(true)
        f:SetScript("OnGamePadButtonDown", function(_, key)
            local confirm, cancel = padNames()
            local action = ({PADDDOWN="down", PADDUP="up", PADDLEFT="left", PADDRIGHT="right"})[key]
            if key == confirm then action = "confirm" elseif key == cancel then action = "close" end
            if action then ns.SettingsAction(action) end
        end)
    end
    if f.EnableGamePadStick then
        f:EnableGamePadStick(true)
        f:SetScript("OnGamePadStick", function(_, stick, x, y)
            if stick ~= "Left" or not ns.Number(x) or not ns.Number(y) then return end
            local direction
            if math.max(math.abs(x), math.abs(y)) > 0.55 then
                if math.abs(x) > math.abs(y) then direction = x > 0 and "right" or "left"
                else direction = y > 0 and "up" or "down" end
            end
            if direction ~= pressedDirection then
                pressedDirection, repeatAt = direction, GetTime() + 0.4
                if direction then ns.SettingsAction(direction) end
            end
        end)
    end
    f:SetScript("OnUpdate", function()
        if pressedDirection and GetTime() >= repeatAt then
            repeatAt = GetTime() + 0.15; ns.SettingsAction(pressedDirection)
        end
    end)
    f:SetScript("OnHide", function() pressedDirection = nil; selectedPin = nil end)
    f:Hide()
end

function ns.ToggleSettings()
    if not ns.window then return end
    if ns.window:IsShown() then ns.window:Hide(); return end
    if InCombatLockdown() or ns.dialogue then print(L.title .. ": " .. L.combat); return end
    ns.window:SetScale(math.min(1, UIParent:GetHeight() / 700, UIParent:GetWidth() / 670))
    selection, page = 1, 1
    updateList(); refresh(); ns.window:Show()
end

function ns.RefreshSettingsDetails()
    if not ns.window or not ns.window:IsShown() then return end
    for _, button in ipairs(ns.listButtons) do
        if button.pin then button.text:SetText(ns.PinText(button.pin)) end
    end
    if selectedPin then details:SetText(table.concat(ns.PinDetails(selectedPin), "\n")) end
end

BINDING_HEADER_QUESTMAPGAMEPAD = L.title
BINDING_NAME_QUESTMAPGAMEPAD_TOGGLE = L.settings
QuestMapGamepad_Toggle = function() ns.ToggleSettings() end
