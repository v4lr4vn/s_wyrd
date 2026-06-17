--[[ s_wyrd client — Dice Combat, magic, and the Wyrd Health HUD.
       /attack [weapon]   strike the nearest Wyrd combatant in dice combat
       /cast <tier>       work magic (cantrip, t1..t5) — placeholder effects
     The HUD shows the Wyrd Health (wound) bar + WP only while in dice combat.
     GTA health is untouched and entirely separate. ]]

local R = Wyrd.rules
local hudVisible = false
local lastSheet = nil

-- register the Wyrd Health bar with s_hud so players can reposition it (/hud)
local HUD_ID = 'wyrd_health'
local function registerHud()
    TriggerEvent('s_hud:register', { id = HUD_ID, label = 'Wyrd Health', dx = 2, dy = 68, w = 248, h = 96 })
end
AddEventHandler('s_hud:apply', function(id, x, y)
    if id == HUD_ID then SendNUIMessage({ action = 'wyrd:pos', x = x, y = y }) end
end)
AddEventHandler('s_hud:ready', registerHud)
CreateThread(function() Wait(500); registerHud() end)

local function currentSheet()
    return lastSheet or (Wyrd.mySheet and Wyrd.mySheet())
end

local function refreshHud()
    local s = currentSheet()
    if not s or s.background ~= 'displaced' then
        SendNUIMessage({ action = 'wyrd:hud', show = false }); return
    end
    local idx = R.WOUND_INDEX[s.woundTier or 'unharmed'] or 1
    SendNUIMessage({
        action = 'wyrd:hud', show = hudVisible,
        tierIndex = idx, tierCount = #R.WOUND_TIERS,
        tierLabel = R.WOUND_TIERS[idx].label, tierNote = R.WOUND_TIERS[idx].note,
        magic = s.magic == true, wp = s.wpCurrent or 0, wpMax = s.wpMax or 0,
        name = s.name or '', class = s.class or '',
    })
end

-- make sure we have a sheet cached; fetch it once if not
local function ensureSheet()
    local s = currentSheet()
    if s then return s end
    s = lib.callback.await('s_wyrd:getOwnSheet', false)
    if s then lastSheet = s end
    return s
end

RegisterNetEvent('s_wyrd:sheet', function(s) lastSheet = s; refreshHud() end)

RegisterNetEvent('s_wyrd:combat', function(on)
    hudVisible = (on == true)
    if hudVisible and not (currentSheet() and currentSheet().background == 'displaced') then
        CreateThread(function() ensureSheet(); refreshHud() end)
    else
        refreshHud()
    end
end)

-- self-serve: a Displaced player can show/hide their own Wyrd Health bar
RegisterCommand('wyrdhud', function(_, args)
    CreateThread(function()
        local s = ensureSheet()
        if not s or s.background ~= 'displaced' then
            lib.notify({ title = 'Wyrd Health', description = 'Only the Displaced carry a Wyrd Health bar.', type = 'inform' }); return
        end
        local a = (args[1] or ''):lower()
        if a == 'on' then hudVisible = true
        elseif a == 'off' then hudVisible = false
        else hudVisible = not hudVisible end
        refreshHud()
    end)
end, false)

-- nearest other player within range -> their server id
local function nearestPlayer(maxDist)
    local me = PlayerPedId()
    local myc = GetEntityCoords(me)
    local best, bestD = nil, maxDist or 5.0
    for _, p in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(p)
        if ped ~= me and ped ~= 0 then
            local d = #(GetEntityCoords(ped) - myc)
            if d < bestD then best, bestD = p, d end
        end
    end
    return best and GetPlayerServerId(best) or nil
end

RegisterCommand('attack', function(_, args)
    local weapon = (args[1] or 'shortsword'):lower()
    local target = nearestPlayer(5.0)
    if not target then
        lib.notify({ title = 'Dice Combat', description = 'No one close enough to strike.', type = 'error' }); return
    end
    local res = lib.callback.await('s_wyrd:diceAttack', false, { target = target, weapon = weapon })
    if not res then return end
    if res.denied then lib.notify({ title = 'Dice Combat', description = 'You do not fight on the Wyrd. (Displaced only.)', type = 'error' }); return end
    if res.err == 'target_not_wyrd' then lib.notify({ title = 'Dice Combat', description = 'They are no Wyrd combatant. Settle it the modern way.', type = 'inform' }); return end
    if res.err == 'no_target' then lib.notify({ title = 'Dice Combat', description = 'No valid target.', type = 'error' }); return end
    if res.err == 'unknown_weapon' then lib.notify({ title = 'Dice Combat', description = 'Unknown weapon. Try dagger, shortsword, longsword, greataxe, spear, shortbow, longbow.', type = 'error' }); return end
    if res.err then lib.notify({ title = 'Dice Combat', description = 'Cannot attack: ' .. res.err, type = 'error' }); return end
    lib.notify({ title = 'Dice Combat', description = res.line or 'Strike resolved.', type = res.landed and 'success' or 'inform' })
end, false)

RegisterCommand('cast', function(_, args)
    local tier = (args[1] or 't1'):lower()
    local res = lib.callback.await('s_wyrd:cast', false, { tier = tier })
    if not res then return end
    if res.denied then lib.notify({ title = 'Magic', description = 'The wyrd does not answer you.', type = 'error' }); return end
    if res.noMagic then lib.notify({ title = 'Magic', description = 'Your class wields no magic until the Branch Point at level 12.', type = 'error' }); return end
    if res.err == 'unknown_tier' then lib.notify({ title = 'Magic', description = 'Unknown tier. Use cantrip, t1, t2, t3, t4, t5.', type = 'error' }); return end
    if res.affordable == false then
        lib.notify({ title = 'Magic', description = ('Not enough Wyrd Points (need %s).'):format(tostring(res.cost or '?')), type = 'error' }); return
    end
    local tail = res.placeholder and '   [effect pending \u{2014} spell lists in progress]' or ''
    local body
    if res.cantrip then
        body = ('%s cantrip woven.%s'):format(res.tierLabel, tail)
    else
        body = ('%s %s   \u{00B7}   d20 %d = %d vs DC %d. WP left: %d.%s'):format(
            res.tierLabel, res.success and 'succeeds' or 'falters', res.nat or 0, res.total or 0, res.dc or 0, res.newWP or 0, tail)
    end
    lib.notify({ title = 'Magic', description = body, type = (res.success or res.cantrip) and 'success' or 'error' })
end, false)
