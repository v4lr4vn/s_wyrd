--[[ s_wyrd server — Dice Combat & the Wyrd Health layer.

     Wyrd Health is the wound-tier ladder (Unharmed -> Downed). It is SEPARATE
     from GTA health and only matters inside dice combat. Every dice-combat hit
     lands here, never on the GTA bar. Only Displaced characters fight on this
     layer — Modern people resolve violence through GTA. ]]

local R    = Wyrd.rules
local dice = Wyrd.dice
local SW   = exports['s_wyrd']

local function isAdmin(src) return exports['s_core']:IsAdmin(src) == true end
local function woundModOf(tier)
    local w = R.WOUND_TIERS[R.WOUND_INDEX[tier or 'unharmed'] or 1]; return (w and w.rollMod) or 0
end

local combatOn = {}   -- [src] = true   (dice-combat / HUD active)
local deaths   = {}   -- [src] = { succ, fail }   Death's Door tallies

local function setCombat(src, on)
    combatOn[src] = on and true or nil
    TriggerClientEvent('s_wyrd:combat', src, on and true or false)
end

local function statsOf(src)
    local s = SW:GetSheet(src)
    if not s or s.background ~= 'displaced' then return nil end
    return {
        sheet = s, might = s.attributes.might, agility = s.attributes.agility, grit = s.attributes.grit,
        woundMod = woundModOf(s.woundTier), woundTier = s.woundTier or 'unharmed',
        defenceDC = SW:GetDefenceDC(src, 0, false), threshold = SW:GetWoundThreshold(src),
    }
end

-- ---- Death's Door --------------------------------------------------------
local function stabilise(src)
    deaths[src] = nil
    SW:SetWoundTier(src, 'critical')
    TriggerClientEvent('s_wyrd:notify', src, { title = "Death's Door", description = 'You are stabilised \u{2014} unconscious, but alive.', type = 'inform' })
end

local function resolveDeath(src)
    deaths[src] = nil
    TriggerClientEvent('s_wyrd:notify', src, { title = "Death's Door", description = 'Your thread is cut. This saga ends here.', type = 'error' })
    Wyrd.broadcastFeed(src, { name = "Death's Door", body = ('%s falls, and does not rise.'):format(Wyrd.nameOf(src)), ntype = 'error' })
end

local function startDeathDoor(src)
    if deaths[src] then return end
    deaths[src] = { succ = 0, fail = 0 }
    TriggerClientEvent('s_wyrd:notify', src, { title = "Death's Door", description = 'You are Downed. Hold on \u{2014} or die well.', type = 'error' })
end

CreateThread(function()
    while true do
        Wait(8000)
        for src, tally in pairs(deaths) do
            local s = SW:GetSheet(src)
            if not s or s.woundTier ~= 'downed' then
                deaths[src] = nil
            else
                local roll = dice.deathDoor(s.attributes.grit)
                if roll.instantDeath then
                    resolveDeath(src)
                elseif roll.success then
                    tally.succ = tally.succ + 1
                    if tally.succ >= R.DEATH_DOOR.successesToStabilise then stabilise(src)
                    else TriggerClientEvent('s_wyrd:notify', src, { title = "Death's Door", description = ('Holding on \u{2014} success %d/3 (rolled %d).'):format(tally.succ, roll.total), type = 'inform' }) end
                else
                    tally.fail = tally.fail + 1
                    if tally.fail >= R.DEATH_DOOR.failuresToDie then resolveDeath(src)
                    else TriggerClientEvent('s_wyrd:notify', src, { title = "Death's Door", description = ('Slipping \u{2014} failure %d/3 (rolled %d).'):format(tally.fail, roll.total), type = 'error' }) end
                end
            end
        end
    end
end)

-- ---- the dice attack -----------------------------------------------------
lib.callback.register('s_wyrd:diceAttack', function(src, req)
    if type(req) ~= 'table' then return { err = 'bad' } end
    local a = statsOf(src)
    if not a then return { denied = true } end
    local target = tonumber(req.target)
    if not target or target == src then return { err = 'no_target' } end
    local t = statsOf(target)
    if not t then return { err = 'target_not_wyrd' } end   -- Modern / no sheet
    local weaponKey = tostring(req.weapon or 'shortsword')
    local w = R.WEAPONS[weaponKey]
    if not w then return { err = 'unknown_weapon' } end

    local sp, tp = GetEntityCoords(GetPlayerPed(src)), GetEntityCoords(GetPlayerPed(target))
    local dx, dy, dz = sp.x - tp.x, sp.y - tp.y, sp.z - tp.z
    local maxRange = w.ranged and 50.0 or 4.0
    if (dx*dx + dy*dy + dz*dz) > (maxRange * maxRange) then return { err = 'out_of_range' } end

    local atkMod = (w.ranged and a.agility or a.might) + a.woundMod
    local defMod = t.agility + t.woundMod
    local res = dice.combatAttack(atkMod, defMod, t.defenceDC, weaponKey)

    setCombat(src, true); setCombat(target, true)

    local outcome
    if res.landed then
        local wr = dice.applyWound(t.woundTier, res.damage, t.threshold, res.maxHit)
        if wr.to ~= t.woundTier then SW:SetWoundTier(target, wr.to) end
        outcome = { landed = true, result = res.result, damage = res.damage, maxHit = res.maxHit,
                    from = wr.from, to = wr.to, downed = wr.downed, aTotal = res.aTotal, dTotal = res.dTotal }
        if wr.downed then startDeathDoor(target) end
    else
        outcome = { landed = false, aTotal = res.aTotal, dTotal = res.dTotal }
    end

    local aName, tName = Wyrd.nameOf(src), Wyrd.nameOf(target)
    local line
    if not res.landed then            line = ('%s\u{2019}s %s is turned aside by %s'):format(aName, w.label, tName)
    elseif res.result == 'beat' then  line = ('%s lands a brutal %s on %s'):format(aName, w.label, tName)
    elseif res.result == 'meet' then  line = ('%s strikes %s with a %s'):format(aName, tName, w.label)
    else                              line = ('%s grazes %s with a %s'):format(aName, tName, w.label) end
    if outcome.landed and outcome.to ~= outcome.from then
        line = line .. (' \u{2014} %s is now %s'):format(tName, R.WOUND_TIERS[R.WOUND_INDEX[outcome.to]].label)
    end

    TriggerClientEvent('s_wyrd:notify', target, { title = 'Dice Combat', description = line, type = outcome.landed and 'error' or 'inform' })
    Wyrd.broadcastFeed(src, { name = 'Dice Combat', body = line, ntype = outcome.landed and 'error' or 'inform' })
    outcome.line = line
    return outcome
end)

-- ally help: spend your action to stabilise a Downed ally, no roll (rules)
lib.addCommand('stabilise', { help = 'Stabilise a Downed ally (no roll)', restricted = false }, function(src, args)
    if not Wyrd.isDisplaced(src) then return end
    local target = tonumber(args[1]); if not target then return end
    local t = SW:GetSheet(target)
    if t and t.woundTier == 'downed' then
        stabilise(target)
        TriggerClientEvent('s_wyrd:notify', src, { title = "Death's Door", description = ('You stabilise %s.'):format(Wyrd.nameOf(target)), type = 'success' })
    end
end)

-- ---- recovery (breather / short rest / long rest) ------------------------
local function recover(src, kind)
    local s = SW:GetSheet(src)
    if not (s and s.background == 'displaced') then
        TriggerClientEvent('s_wyrd:notify', src, { title = 'Rest', description = 'Only the Displaced mend this way.', type = 'error' }); return
    end
    local tier = s.woundTier or 'unharmed'
    if kind == 'breather' then
        tier = dice.recoverTiers(tier, 1)
        if tier == 'scratched' then tier = 'unharmed' end       -- breather removes Scratched
        SW:SetWoundTier(src, tier)
        TriggerClientEvent('s_wyrd:notify', src, { title = 'Breather', description = 'You catch your breath.', type = 'success' })
    elseif kind == 'short' then
        if R.WOUND_INDEX[tier] > R.WOUND_INDEX['wounded'] then tier = 'wounded' end   -- Wounded at worst
        SW:SetWoundTier(src, tier)
        SW:RestoreWP(src, math.floor((SW:GetWPMax(src) or 0) / 2))
        deaths[src] = nil
        TriggerClientEvent('s_wyrd:notify', src, { title = 'Short Rest', description = 'An hour safe. Wounds eased, some power returns.', type = 'success' })
    else -- long
        SW:SetWoundTier(src, 'unharmed')
        SW:RestoreWP(src, SW:GetWPMax(src) or 0)
        deaths[src] = nil
        setCombat(src, false)
        TriggerClientEvent('s_wyrd:notify', src, { title = 'Long Rest', description = 'A full night. You are whole again.', type = 'success' })
    end
end
lib.addCommand('breather',  { help = 'Breather: remove Scratched, recover a tier', restricted = false }, function(src) recover(src, 'breather') end)
lib.addCommand('shortrest', { help = 'Short rest: Wounded at worst, half WP', restricted = false }, function(src) recover(src, 'short') end)
lib.addCommand('longrest',  { help = 'Long rest: full recovery, all WP', restricted = false }, function(src) recover(src, 'long') end)

-- Skald: toggle the dice-combat HUD for a player (or yourself if no id given)
lib.addCommand('skaldcombat', { help = 'Toggle dice combat: /skaldcombat [id] on|off', restricted = false }, function(src, args)
    if not isAdmin(src) then
        TriggerClientEvent('s_wyrd:notify', src, { title = 'Dice Combat', description = 'Skald (admin) only.', type = 'error' })
        return
    end
    local target, stateArg
    if tonumber(args[1]) then target = tonumber(args[1]); stateArg = args[2]
    else target = src; stateArg = args[1] end
    local on = (stateArg or 'on'):lower() ~= 'off'
    setCombat(target, on)
    TriggerClientEvent('s_wyrd:notify', src, { title = 'Dice Combat', description = ('%s dice combat for #%d.'):format(on and 'Enabled' or 'Disabled', target), type = 'inform' })
end)

-- ---- magic (PLACEHOLDER — spell EFFECTS pending the written spell lists) --
lib.callback.register('s_wyrd:cast', function(src, req)
    local s = SW:GetSheet(src)
    if not (s and s.background == 'displaced') then return { denied = true } end
    local cd = Wyrd.classes[s.class]
    if not ((cd and cd.magic) or s.branch) then return { noMagic = true } end
    local tierKey = tostring(req and req.tier or 't1')
    local mt = R.MAGIC_BY_KEY[tierKey]
    if not mt then return { err = 'unknown_tier' } end

    local train = math.max(R.TRAINING[(s.skills.arcana) or 'untrained'] or 0,
                           R.TRAINING[(s.skills.commune) or 'untrained'] or 0)
    local castMod = s.attributes.wyrd + train + woundModOf(s.woundTier)
    local result = dice.cast(castMod, tierKey, s.wpCurrent or 0)
    if not result.affordable then
        return { affordable = false, reason = result.reason, cost = result.cost }
    end
    local spent = (s.wpCurrent or 0) - result.newWP
    if spent > 0 then SW:SpendWP(src, spent) end

    result.tierLabel = mt.label
    result.placeholder = true
    Wyrd.broadcastFeed(src, { name = Wyrd.nameOf(src), body = ('%s shapes %s magic'):format(s.class, mt.label), ntype = 'inform' })
    return result
end)

AddEventHandler('playerDropped', function()
    local src = source
    combatOn[src] = nil
    deaths[src] = nil
end)

exports('SetCombat',     function(src, on) setCombat(src, on) end)
exports('InDiceCombat',  function(src) return combatOn[src] == true end)
exports('CombatAttack',  function(atk, def, dc, weapon) return dice.combatAttack(atk, def, dc, weapon) end)
