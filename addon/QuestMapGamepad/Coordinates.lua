local _, ns = ...
local M = C_Map or {}
local cache = {}

local function vectorXY(vector)
    if not vector then return nil end
    local x, y = ns.Call(vector.GetXY, vector)
    if ns.Number(x) and ns.Number(y) then return x, y end
end

-- Descendant maps project via map rectangles, including the Azeroth overview.
-- Sibling maps use world coordinates only if their world/instance identifier matches.
function ns.Project(pin, target)
    if pin.mapID == target then return pin.x, pin.y end
    local key = pin.mapID .. ":" .. target
    local transform = cache[key]
    if transform == nil then
        local child, seen, descendant = pin.mapID, {}, false
        for _ = 1, 12 do
            if child == target then descendant = true; break end
            if seen[child] then break end
            seen[child] = true
            local info = ns.Call(M.GetMapInfo, child)
            child = info and ns.Value(info.parentMapID)
            if not child or child == 0 then break end
        end
        if descendant then
            local minX, maxX, minY, maxY = ns.Call(M.GetMapRectOnMap, pin.mapID, target)
            if ns.Number(minX) and ns.Number(maxX) and ns.Number(minY) and ns.Number(maxY) and maxX > minX and maxY > minY then
                transform = { minX, maxX, minY, maxY }
            end
        end
        cache[key] = transform or false
    end
    local x, y
    if transform then
        x = transform[1] + pin.x * (transform[2] - transform[1])
        y = transform[3] + pin.y * (transform[4] - transform[3])
    elseif CreateVector2D then
        local instance, world = ns.Call(M.GetWorldPosFromMapPos, pin.mapID, CreateVector2D(pin.x, pin.y))
        local targetInstance = ns.Call(M.GetWorldPosFromMapPos, target, CreateVector2D(0.5, 0.5))
        if world and instance and instance == targetInstance then
            local returnedMap, position = ns.Call(M.GetMapPosFromWorldPos, instance, world, target)
            if returnedMap == target then x, y = vectorXY(position) end
        end
    end
    if ns.ValidPoint(target, x, y) then return x, y end
end

function ns.PlayerPosition(mapID)
    return vectorXY(ns.Call(M.GetPlayerMapPosition, mapID, "player"))
end

function ns.ClearCoordinateCache() cache = {} end
