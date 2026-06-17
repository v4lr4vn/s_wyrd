--[[ s_wyrd server — raw roll endpoint + engine exports.
     RNG seed, name lookup and the nearby-roll broadcast live in util.lua.
     The Wyrd Roll is gated to Displaced characters and admins (Skalds); an
     ordinary Modern person has no wyrd to read. ]]

local dice        = Wyrd.dice
local R           = Wyrd.rules
local rollCooldown = {}   -- [src] = GetGameTimer() ms

-- A raw Wyrd Roll: d20 + modifier, optional DC. Used by /roll and Skald tools.
lib.callback.register('s_wyrd:roll', function(src, req)
    if type(req) ~= 'table' then return nil end
    if not Wyrd.canRoll(src) then return { denied = true } end
    local now = GetGameTimer()
    if rollCooldown[src] and (now - rollCooldown[src]) < 2000 then return { cooldown = true } end
    rollCooldown[src] = now
    local modifier = tonumber(req.modifier) or 0
    local dc = tonumber(req.dc)                       -- nil => ungated roll, no tier shown
    local res = dice.wyrdRoll(modifier, dc or 0)
    res.hasDC = dc ~= nil
    res.label = tostring(req.label or 'Roll'):sub(1, 64)
    Wyrd.broadcastRoll(src, {
        name = Wyrd.nameOf(src), label = res.label, tier = res.tier,
        total = res.total, dc = res.dc, hasDC = res.hasDC, nat = res.nat,
    })
    return res
end)

-- ---- engine exports for other Saga resources ----------------------------
exports('WyrdRoll',     function(mod, dc) return dice.wyrdRoll(mod, dc or 0) end)
exports('Outcome',      function(total, dc, nat) return dice.outcome(total, dc, nat) end)
exports('Contested',    function(a, b) return dice.contested(a, b) end)
exports('Attack',       function(atk, def, weapon) return dice.attack(atk, def, weapon) end)
exports('Cast',         function(mod, tier, wp) return dice.cast(mod, tier, wp) end)
exports('CastCost',     function(tier, wp) return dice.castCost(tier, wp) end)
exports('ApplyWound',   function(tier, dmg, thr, maxHit) return dice.applyWound(tier, dmg, thr, maxHit) end)
exports('RecoverTiers', function(tier, n) return dice.recoverTiers(tier, n) end)
exports('DeathDoor',    function(grit) return dice.deathDoor(grit) end)
exports('GetRules',     function() return R end)
exports('GetClasses',   function() return Wyrd.classes end)

CreateThread(function()
    lib.print.info('s_wyrd engine online — Wyrdbound First Edition ruleset loaded')
end)
