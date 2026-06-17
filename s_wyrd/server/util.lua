--[[ s_wyrd server util — loaded first. Seeds the authoritative RNG and exposes
     shared helpers (name lookup, nearby-roll broadcast) used by both the raw
     roll path and the skill-check path. ]]

local dice = Wyrd.dice

-- seed an authoritative generator and warm it up
math.randomseed((os.time() % 2147483647) + (GetGameTimer() or 0))
for _ = 1, 8 do math.random() end
dice.setRng(math.random)

Wyrd.FEED_RANGE = 25.0   -- metres; who sees a roll happen near them

function Wyrd.nameOf(src)
    local p = exports['s_core']:GetPlayer(src)
    return (p and p.name) or ('Player ' .. src)
end

-- send a payload to every player within FEED_RANGE of src (excludes src)
function Wyrd.broadcast(src, payload)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local origin = GetEntityCoords(ped)
    local players = exports['s_core']:GetPlayers() or {}
    for _, other in ipairs(players) do
        local o = tonumber(other)
        if o and o ~= src then
            local op = GetPlayerPed(o)
            if op and op ~= 0 and #(GetEntityCoords(op) - origin) <= Wyrd.FEED_RANGE then
                TriggerClientEvent('s_wyrd:rollFeed', o, payload)
            end
        end
    end
end
Wyrd.broadcastRoll = Wyrd.broadcast
Wyrd.broadcastFeed = Wyrd.broadcast
