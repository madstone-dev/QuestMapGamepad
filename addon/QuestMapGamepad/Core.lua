local _, ns = ...
local categories = { start = true, objective = true, turnin = true }

local function surfaceSettings(raw)
    raw = type(raw) == "table" and raw or {}
    local out = {}
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
    }
end

-- Providers supply verified coordinates and quest state; unknown categories stay hidden.
function ns.ShouldShow(pin, settings, surface)
    if type(pin) ~= "table" or not categories[pin.kind] then return false end
    if surface ~= "world" and surface ~= "minimap" then return false end
    local options = settings[surface]
    if not options or not options[pin.kind] then return false end
    if pin.completed and not pin.repeatable then return false end
    if pin.lowLevel and not options.lowLevel then return false end
    if pin.repeatable and not options.repeatable then return false end
    return true
end
