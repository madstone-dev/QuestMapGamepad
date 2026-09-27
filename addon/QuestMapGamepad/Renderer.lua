local _, ns = ...
local M = C_Map or {}
local symbols = { start = "!", objective = "*", turnin = "?" }
local colors = { start = {1, 0.82, 0.1}, objective = {1, 1, 1}, turnin = {1, 0.82, 0.1} }
local worldPool, miniPool = {}, {}
local worldOverlay, miniOverlay, tooltip, mapButton, miniButton
local worldPoints, miniPoints = {}, {}
local worldKey, miniKey
local worldLayout
ns.visiblePins = {}

function ns.PinText(pin)
    local prefix = pin.level and ("[" .. pin.level .. "] ") or ""
    return symbols[pin.kind] .. " " .. prefix .. ns.Title(pin.id)
end

function ns.PinDetails(pin)
    local lines = { ns.PinText(pin), ns.L[pin.kind], ns.L[pin.source] }
    for _, objective in ipairs(ns.Call(C_QuestLog and C_QuestLog.GetQuestObjectives, pin.id) or {}) do
        local text = ns.Value(objective.text)
        if type(text) == "string" and text ~= "" then
            lines[#lines + 1] = (ns.Value(objective.finished) == true and "|cff55dd77" or "|cffffffff") .. text .. "|r"
        end
    end
    local map = ns.Call(M.GetMapInfo, pin.mapID)
    local name = map and ns.Value(map.name) or tostring(pin.mapID)
    lines[#lines + 1] = string.format("%s · %.1f, %.1f", name, pin.x * 100, pin.y * 100)
    return lines
end

local function showTooltip(frame)
    if ns.dialogue or (ns.window and ns.window:IsShown()) then return end
    tooltip:SetOwner(frame, "ANCHOR_RIGHT")
    tooltip:ClearLines()
    local pins = frame.group and frame.group.pins or {}
    for i = 1, math.min(#pins, 8) do
        if i > 1 then tooltip:AddLine(" ") end
        for _, line in ipairs(ns.PinDetails(pins[i])) do tooltip:AddLine(line, 1, 1, 1, true) end
    end
    if #pins > 8 then tooltip:AddLine(ns.L.more:format(#pins - 8), 1, 0.8, 0.2, true) end
    tooltip:Show()
end

local function acquire(pool, index, parent)
    local frame = pool[index]
    if not frame then
        frame = CreateFrame("Frame", nil, parent)
        frame:EnableMouse(true)
        frame.back = frame:CreateTexture(nil, "BACKGROUND")
        frame.back:SetAllPoints()
        frame.back:SetColorTexture(0.035, 0.045, 0.07, 0.92)
        frame.symbol = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.symbol:SetPoint("CENTER")
        frame.count = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 6, -5)
        frame:SetScript("OnEnter", showTooltip)
        frame:SetScript("OnLeave", function() tooltip:Hide() end)
        frame:SetScript("OnHide", function(self) if tooltip:IsOwned(self) then tooltip:Hide() end end)
        pool[index] = frame
    end
    return frame
end

local function draw(pool, overlay, groups, size, anchor)
    for i, group in ipairs(groups) do
        local frame = acquire(pool, i, overlay)
        frame.group = group
        frame:SetSize(size, size)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", overlay, anchor, group.x, group.y)
        local pin = group.pins[1]
        local color = pin.repeatable and {0.35, 0.75, 1} or colors[pin.kind]
        frame.symbol:SetText(group.mixed and "+" or symbols[pin.kind])
        frame.symbol:SetTextColor(unpack(color))
        frame.count:SetText(#group.pins > 1 and tostring(#group.pins) or "")
        frame:Show()
    end
    for i = #groups + 1, #pool do pool[i]:Hide() end
end

-- Rectangles use UIParent units. This addon never writes into MapCanvas or its pin pool.
local function rect(frame)
    if not frame then return nil end
    local left, bottom, width, height = ns.Call(frame.GetRect, frame)
    local scale = ns.Call(frame.GetEffectiveScale, frame)
    if not ns.Number(left) or not ns.Number(bottom) or not ns.Number(width) or not ns.Number(height)
        or not ns.Number(scale) then return nil end
    scale = scale / UIParent:GetEffectiveScale()
    return left * scale, bottom * scale, width * scale, height * scale
end

local function place(overlay, left, bottom, width, height)
    overlay:ClearAllPoints()
    overlay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
    overlay:SetSize(width, height)
end

local function filteredPoints(mapID, surface)
    local points = {}
    for _, pin in ipairs(ns.pins) do
        if ns.ShouldShow(pin, ns.settings, surface) then
            local x, y = ns.Project(pin, mapID)
            if x then points[#points + 1] = { x = x, y = y, pin = pin } end
        end
    end
    return points
end

local function updateWorld()
    local map = WorldMapFrame
    if not map or not map:IsShown() or ns.dialogue then
        worldOverlay:Hide(); mapButton:Hide(); ns.visiblePins = {}; worldLayout = nil; return
    end
    local mapID = ns.Call(map.GetMapID, map)
    local canvas = ns.Call(map.GetCanvas, map)
    local container = ns.Call(map.GetCanvasContainer, map)
    local left, bottom, width, height = rect(container)
    local cl, cb, cw, ch = rect(canvas)
    if not mapID or not left or not cl or width <= 0 or height <= 0 then
        worldOverlay:Hide(); mapButton:Hide(); return
    end
    if ns.visibleMap ~= mapID then ns.visibleMap = mapID; ns.dirty = true end
    place(worldOverlay, left, bottom, width, height)
    worldOverlay:SetFrameStrata(map:GetFrameStrata())
    worldOverlay:SetFrameLevel(map:GetFrameLevel() + 30)
    mapButton:SetFrameStrata(map:GetFrameStrata())
    mapButton:SetFrameLevel(map:GetFrameLevel() + 35)
    mapButton:ClearAllPoints()
    mapButton:SetPoint("TOPRIGHT", worldOverlay, "TOPRIGHT", -12, -12)
    mapButton:Show()
    local key = mapID .. ":" .. ns.revision
    if key ~= worldKey then worldPoints, worldKey = filteredPoints(mapID, "world"), key end
    local layout = table.concat({key, left, bottom, width, height, cl, cb, cw, ch}, ":")
    if layout == worldLayout then worldOverlay:Show(); return end
    worldLayout = layout
    local points, visible, seen = {}, {}, {}
    local inset = ns.settings.world.size / 2
    for _, point in ipairs(worldPoints) do
        local x = cl - left + point.x * cw
        local y = cb - bottom + (1 - point.y) * ch
        if x >= inset and y >= inset and x <= width - inset and y <= height - inset then
            points[#points + 1] = { x = x, y = y, pin = point.pin }
            if not seen[point.pin.id] then visible[#visible + 1] = point.pin; seen[point.pin.id] = true end
        end
    end
    ns.visiblePins = visible
    draw(worldPool, worldOverlay, ns.Cluster(points, math.max(22, ns.settings.world.size)), ns.settings.world.size, "BOTTOMLEFT")
    worldOverlay:Show()
end

local function updateMini()
    if not Minimap or not Minimap:IsShown() or ns.dialogue or (WorldMapFrame and WorldMapFrame:IsShown()) then
        miniOverlay:Hide(); miniButton:Hide(); return
    end
    local left, bottom, width, height = rect(Minimap)
    if not left or width <= 0 or height <= 0 then miniOverlay:Hide(); miniButton:Hide(); return end
    place(miniOverlay, left, bottom, width, height)
    miniOverlay:SetFrameStrata(Minimap:GetFrameStrata())
    miniOverlay:SetFrameLevel(Minimap:GetFrameLevel() + 20)
    miniButton:ClearAllPoints()
    miniButton:SetPoint("BOTTOMLEFT", miniOverlay, "BOTTOMLEFT", 0, 0)
    miniButton:SetFrameStrata(Minimap:GetFrameStrata())
    miniButton:SetFrameLevel(Minimap:GetFrameLevel() + 30)
    miniButton:Show()
    local mapID = ns.Call(M.GetBestMapForUnit, "player")
    if not mapID then miniOverlay:Hide(); return end
    local x, y = ns.PlayerPosition(mapID)
    local radius = ns.Call(C_Minimap and C_Minimap.GetViewRadius)
    local mapWidth, mapHeight = ns.Call(M.GetMapWorldSize, mapID)
    if not x or not ns.Number(radius) or not ns.Number(mapWidth) or not ns.Number(mapHeight)
        or mapWidth <= 0 or mapHeight <= 0 then miniOverlay:Hide(); return end
    local key = mapID .. ":" .. ns.revision
    if key ~= miniKey then miniPoints, miniKey = filteredPoints(mapID, "minimap"), key end
    local facing = ns.Call(GetPlayerFacing) or 0
    local rotating = ns.Call(GetCVar, "rotateMinimap") == "1"
    local points = {}
    for _, point in ipairs(miniPoints) do
        local px, py = ns.MinimapOffset((point.x - x) * mapWidth, (point.y - y) * mapHeight,
            radius, width, height, facing, rotating, ns.settings.minimap.size / 2 + 2)
        if px then points[#points + 1] = { x = px, y = py, pin = point.pin } end
    end
    draw(miniPool, miniOverlay, ns.Cluster(points, math.max(16, ns.settings.minimap.size)), ns.settings.minimap.size, "CENTER")
    miniOverlay:Show()
end

function ns.InvalidatePins() worldKey, miniKey, worldLayout = nil, nil, nil end

function ns.InitializeRenderer()
    worldOverlay = CreateFrame("Frame", nil, UIParent)
    worldOverlay:SetClipsChildren(true)
    worldOverlay:EnableMouse(false)
    miniOverlay = CreateFrame("Frame", nil, UIParent)
    miniOverlay:EnableMouse(false)
    tooltip = CreateFrame("GameTooltip", "QuestMapGamepadTooltip", UIParent, "GameTooltipTemplate")
    tooltip:SetFrameStrata("TOOLTIP")
    local function button()
        local b = CreateFrame("Button", nil, UIParent)
        b:SetSize(30, 30)
        local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.08, 0.12, 0.18, 1)
        local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); label:SetPoint("CENTER"); label:SetText("Q")
        b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        b:SetScript("OnClick", function() ns.ToggleSettings() end)
        b:SetScript("OnEnter", function(self)
            tooltip:SetOwner(self, "ANCHOR_RIGHT"); tooltip:ClearLines(); tooltip:AddLine(ns.L.mapButton); tooltip:Show()
        end)
        b:SetScript("OnLeave", function() tooltip:Hide() end)
        return b
    end
    mapButton, miniButton = button(), button()
    worldOverlay:Hide(); miniOverlay:Hide(); mapButton:Hide(); miniButton:Hide()
end

function ns.Render()
    if not worldOverlay then return end
    updateWorld(); updateMini()
end
