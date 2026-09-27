local _, ns = ...
local categories = { start = true, objective = true, turnin = true }

local function surfaceSettings(raw)
    raw = type(raw) == "table" and raw or {}
    local out = {}
    out.enabled = raw.enabled ~= false
    for key in pairs(categories) do
        out[key] = raw[key] ~= false
    end
    out.lowLevel = raw.lowLevel == true
    out.repeatable = raw.repeatable ~= false
    local size = tonumber(raw.size) or 18
    if size ~= size then size = 18 end
    out.size = math.max(10, math.min(36, size))
    return out
end

function ns.NormalizeSettings(raw)
    raw = type(raw) == "table" and raw or {}
    return {
        version = 1,
        world = surfaceSettings(raw.world),
        minimap = surfaceSettings(raw.minimap),
        swapButtons = raw.swapButtons == true,
    }
end

-- Providers supply verified coordinates and quest state; unknown categories stay hidden.
function ns.ShouldShow(pin, settings, surface)
    if type(pin) ~= "table" or not categories[pin.kind] then return false end
    if surface ~= "world" and surface ~= "minimap" then return false end
    local options = settings[surface]
    if not options or not options.enabled or not options[pin.kind] then return false end
    if pin.completed and not pin.repeatable then return false end
    if pin.lowLevel and not options.lowLevel then return false end
    if pin.repeatable and not options.repeatable then return false end
    return true
end

function ns.Value(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end

local function pack(...) return { n = select("#", ...), ... } end
-- Read APIs can be absent or restricted on beta builds. Do not compare secret values.
function ns.Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local result = pack(pcall(fn, ...))
    if not result[1] then
        ns.readErrors = (ns.readErrors or 0) + 1
        return nil
    end
    for i = 2, result.n do result[i] = ns.Value(result[i]) end
    return unpack(result, 2, result.n)
end

function ns.Number(value)
    value = ns.Value(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function ns.ValidPoint(mapID, x, y)
    return ns.Number(mapID) and mapID > 0 and ns.Number(x) and ns.Number(y)
        and x >= 0 and x <= 1 and y >= 0 and y <= 1
end

local function contains(values, wanted)
    if not values then return true end
    for _, value in ipairs(values) do if value == wanted then return true end end
    return false
end

function ns.Eligible(id, record, player, active, completed)
    if active[id] or (completed[id] and not record.repeatable) then return false end
    if record.faction and record.faction ~= player.faction then return false end
    if not contains(record.classes, player.classID) or not contains(record.races, player.raceID) then return false end
    if record.minLevel and player.level < record.minLevel then return false end
    if record.maxLevel and player.level > record.maxLevel then return false end
    if record.requireSkill and not player.skills[record.requireSkill] then return false end
    -- This database has no live holiday/war-effort phase or breadcrumb availability.
    -- Native available POIs may still supply these when the game confirms them.
    if record.isYearly or record.isMonthly or record.isWarEffort or record.isBreadcrumb then return false end
    for _, prerequisite in ipairs(record.sourceQuests or {}) do
        if prerequisite <= 0 or not completed[prerequisite] then return false end
    end
    for _, alternative in ipairs(record.altQuests or {}) do
        if active[alternative] or completed[alternative] then return false end
    end
    return true
end

-- Shared locations may contain both start and turn-in quests. Keep every quest accessible.
function ns.Cluster(points, cellSize)
    local groups, cells = {}, {}
    for _, point in ipairs(points) do
        local key = math.floor(point.x / cellSize) .. ":" .. math.floor(point.y / cellSize)
        local group = cells[key]
        if not group then
            group = { x = point.x, y = point.y, pins = {}, seen = {}, kind = point.pin.kind }
            cells[key], groups[#groups + 1] = group, group
        end
        local identity = point.pin.id .. ":" .. point.pin.kind
        if not group.seen[identity] then
            group.pins[#group.pins + 1] = point.pin
            group.seen[identity] = true
        end
        if group.kind ~= point.pin.kind then group.mixed = true end
    end
    return groups
end

function ns.MinimapOffset(dx, dy, radius, width, height, facing, rotating, inset)
    if not ns.Number(radius) or radius <= 0 then return nil end
    if rotating then
        local c, s = math.cos(facing or 0), math.sin(facing or 0)
        dx, dy = dx * c - dy * s, dx * s + dy * c
    end
    local x, y = dx / radius * width / 2, -dy / radius * height / 2
    local rx, ry = width / 2 - inset, height / 2 - inset
    if rx <= 0 or ry <= 0 or (x / rx)^2 + (y / ry)^2 > 1 then return nil end
    return x, y
end
