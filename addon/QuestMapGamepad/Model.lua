local _, ns = ...
ns.pins, ns.active, ns.completed = {}, {}, {}
ns.revision = 0
local Q = C_QuestLog or {}
local M = C_Map or {}
local requestedTitles = {}

function ns.Title(id)
    local title = ns.Call(Q.GetTitleForQuestID, id)
    if type(title) == "string" and title ~= "" then return title end
    if not requestedTitles[id] and Q.RequestLoadQuestByID then
        requestedTitles[id] = true
        ns.Call(Q.RequestLoadQuestByID, id)
    end
    return ns.L.unknown:format(id)
end

function ns.Player()
    local _, _, classID = ns.Call(UnitClass, "player")
    local _, _, raceID = ns.Call(UnitRace, "player")
    local player = { level = ns.Call(UnitLevel, "player") or 1,
        faction = ns.Call(UnitFactionGroup, "player"), classID = classID, raceID = raceID, skills = {} }
    if GetProfessions and GetProfessionInfo then
        local professions = { ns.Call(GetProfessions) }
        for _, index in pairs(professions) do
            local _, _, _, _, _, _, skillID = ns.Call(GetProfessionInfo, index)
            if ns.Number(skillID) then player.skills[skillID] = true end
        end
    end
    return player
end

local function activeQuests()
    local active = {}
    local count = ns.Call(Q.GetNumQuestLogEntries) or ns.Call(GetNumQuestLogEntries) or 0
    for index = 1, count do
        local info = ns.Call(Q.GetInfo, index)
        if not info and GetQuestLogTitle then
            local title, level, _, header, _, complete, _, id = ns.Call(GetQuestLogTitle, index)
            info = { title = title, level = level, isHeader = header, questID = id, ready = complete == 1 }
        end
        if info and ns.Value(info.isHeader) ~= true and ns.Value(info.isHidden) ~= true
            and ns.Value(info.isInternalOnly) ~= true and ns.Number(info.questID) and info.questID > 0 then
            local id = info.questID
            local ready = ns.Call(Q.IsComplete, id)
            active[id] = { id = id, title = ns.Value(info.title), level = ns.Value(info.level),
                ready = ready == true or info.ready == true }
        end
    end
    return active
end

function ns.RefreshModel()
    local player = ns.Player()
    ns.player, ns.active = player, activeQuests()
    local completed = ns.Call(Q.GetAllCompletedQuestIDs)
    if completed then
        ns.completed = {}
        for _, id in ipairs(completed) do if ns.Number(id) then ns.completed[id] = true end end
    end
    local result, seen, covered = {}, {}, {}
    local function append(id, kind, mapID, x, y, record, native)
        if not ns.ValidPoint(mapID, x, y) then return end
        local key = id .. ":" .. kind .. ":" .. mapID .. ":" .. string.format("%.4f:%.4f", x, y)
        if seen[key] then return end
        seen[key] = true
        local active = ns.active[id]
        local level = active and active.level or ns.Call(Q.GetQuestDifficultyLevel, id)
        if not ns.Number(level) or level <= 0 then level = nil end
        local trivialRange = ns.Call(GetQuestGreenRange) or 10
        result[#result + 1] = { id = id, kind = kind, mapID = mapID, x = x, y = y,
            level = level, lowLevel = level and player.level - level > trivialRange or false,
            repeatable = record and record.repeatable or false,
            source = native and "native" or "database" }
        if active then covered[id] = true end
    end

    -- Query each known zone, not only the open map: remote active quests remain visible.
    local maps = {}
    for _, record in pairs(ns.StartDB or {}) do
        maps[record.mapID] = true
        for _, coord in ipairs(record.coords or {}) do maps[coord[3]] = true end
    end
    local playerMap = ns.Call(M.GetBestMapForUnit, "player")
    if playerMap then maps[playerMap] = true end
    if ns.visibleMap then maps[ns.visibleMap] = true end
    for id, active in pairs(ns.active) do
        local mapID, x, y = ns.Call(Q.GetNextWaypoint, id)
        if ns.ValidPoint(mapID, x, y) then
            maps[mapID] = true
            append(id, active.ready and "turnin" or "objective", mapID, x, y, ns.StartDB[id], true)
        end
    end
    local nativeStarts = {}
    for mapID in pairs(maps) do
        for _, poi in ipairs(ns.Call(Q.GetQuestsOnMap, mapID) or {}) do
            local id = ns.Value(poi.questID)
            if ns.Number(id) and id > 0 then
                local active = ns.active[id]
                if active or ns.Value(poi.isQuestStart) == true then
                    local kind = active and (active.ready and "turnin" or "objective") or "start"
                    -- GetQuestsOnMap coordinates are relative to the queried map.
                    append(id, kind, mapID, ns.Value(poi.x), ns.Value(poi.y), ns.StartDB[id], true)
                    if kind == "start" and ns.ValidPoint(mapID, ns.Value(poi.x), ns.Value(poi.y)) then nativeStarts[id] = true end
                end
            end
        end
    end
    for id, record in pairs(ns.StartDB or {}) do
        if not nativeStarts[id] and ns.Eligible(id, record, player, ns.active, ns.completed) then
            if record.coords then
                for _, coord in ipairs(record.coords) do append(id, "start", coord[3], coord[1] / 100, coord[2] / 100, record) end
            else
                append(id, "start", record.mapID, record.x / 100, record.y / 100, record)
            end
        end
    end
    table.sort(result, function(a, b)
        if a.id ~= b.id then return a.id < b.id end
        if a.mapID ~= b.mapID then return a.mapID < b.mapID end
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)
    ns.missingActive = 0
    for id in pairs(ns.active) do if not covered[id] then ns.missingActive = ns.missingActive + 1 end end
    ns.pins, ns.revision = result, ns.revision + 1
end
