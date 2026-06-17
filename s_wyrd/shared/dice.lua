--[[ s_wyrd — the resolution engine. Pure functions, no FiveM natives, so it is
     fully unit-testable. The RNG is injectable (dice.setRng) so tests are
     deterministic; the server seeds it with a real generator at startup.

     Outcome tiers (margin = total - DC, nat = the raw d20):
       GLORIOUS  nat 20, or margin >= 5
       TRUE      margin >= 0
       STRAINED  margin -1 .. -4
       BROKEN    margin -5 .. -9
       DOOMED    nat 1, or margin <= -10
]]

Wyrd = Wyrd or {}
local R = Wyrd.rules or require and nil   -- rules.lua loads first in the manifest
local dice = {}
Wyrd.dice = dice

local rng = math.random
function dice.setRng(fn) rng = fn or math.random end

-- roll a single dN (1..n)
function dice.die(n) return rng(1, n) end
function dice.d20() return rng(1, 20) end

-- ---- outcome tier from a finished roll -----------------------------------
function dice.outcome(total, dc, nat)
    local margin = total - dc
    if nat == 20 or margin >= 5 then return 'glorious' end
    if nat == 1  or margin <= -10 then return 'doomed' end
    if margin >= 0 then return 'true_' end
    if margin >= -4 then return 'strained' end
    return 'broken'   -- margin -5..-9
end

-- success classification: glorious/true succeed, strained is a partial, the rest fail
local SUCCESS  = { glorious=true, true_=true }
local PARTIAL  = { strained=true }
function dice.isSuccess(tier) return SUCCESS[tier] == true end
function dice.isPartial(tier) return PARTIAL[tier] == true end

-- ---- the Wyrd Roll: d20 + modifier vs DC ---------------------------------
function dice.wyrdRoll(modifier, dc)
    modifier = modifier or 0
    dc = dc or 0
    local nat = dice.d20()
    local total = nat + modifier
    local tier = dice.outcome(total, dc, nat)
    return {
        nat = nat, modifier = modifier, total = total, dc = dc,
        margin = total - dc, tier = tier,
        success = dice.isSuccess(tier), partial = dice.isPartial(tier),
    }
end

-- ---- contested roll: both sides d20 + modifier, higher wins --------------
-- Tie -> 'tie' (callers break ties by Wit, or treat as defender-favoured).
function dice.contested(aMod, bMod)
    local a = dice.d20() + (aMod or 0)
    local b = dice.d20() + (bMod or 0)
    local winner = (a > b) and 'a' or (b > a) and 'b' or 'tie'
    return { a = a, b = b, winner = winner }
end

-- ---- attack resolution: d20 + atkMod vs Defence DC -----------------------
-- Beat the DC -> Max damage. Meet -> roll the weapon die. Miss -> Min (glancing).
function dice.attack(atkMod, defenceDC, weaponKey)
    local w = Wyrd.rules.WEAPONS[weaponKey]
    if not w then return nil, 'unknown weapon' end
    local nat = dice.d20()
    local total = nat + (atkMod or 0)
    local result, damage, maxHit
    if total > defenceDC then
        result, damage, maxHit = 'beat', w.max, true
    elseif total == defenceDC then
        result, damage, maxHit = 'meet', dice.die(w.die), false
    else
        result, damage, maxHit = 'miss', w.min, false   -- glancing, never a clean whiff
    end
    return { nat = nat, total = total, defenceDC = defenceDC, weapon = weaponKey,
             result = result, damage = damage, maxHit = maxHit }
end

-- ---- magic: spend WP (before the roll, even on failure) then resolve ------
-- Returns affordable=false (and spends nothing) if WP can't cover the cost.
function dice.castCost(tierKey, currentWP)
    local t = Wyrd.rules.MAGIC_BY_KEY[tierKey]
    if not t then return nil end
    if t.wp == 'all' then
        if currentWP < (t.wpMin or 0) then return nil, 'need_min' end
        return currentWP
    end
    return t.wp
end

function dice.cast(modifier, tierKey, currentWP)
    local t = Wyrd.rules.MAGIC_BY_KEY[tierKey]
    if not t then return nil, 'unknown tier' end
    local cost, why = dice.castCost(tierKey, currentWP)
    if cost == nil then return { affordable = false, reason = why or 'unknown' } end
    if cost > currentWP then return { affordable = false, reason = 'insufficient_wp', cost = cost } end

    local newWP = currentWP - cost
    -- Cantrips have no Cast DC and always succeed.
    if t.dc == nil then
        return { affordable = true, cantrip = true, cost = cost, newWP = newWP,
                 success = true, tier = 'true_' }
    end
    local nat = dice.d20()
    local total = nat + (modifier or 0)
    local otier = dice.outcome(total, t.dc, nat)
    return {
        affordable = true, cost = cost, newWP = newWP,
        nat = nat, total = total, dc = t.dc, tier = otier,
        success = dice.isSuccess(otier), partial = dice.isPartial(otier),
    }
end

-- ---- wounds: a hit whose damage exceeds the threshold steps tiers down ----
-- Standard hit = 1 tier, Max-damage hit = 2 tiers. Clamps at Downed.
function dice.applyWound(currentTierKey, damage, threshold, maxHit)
    local tiers = Wyrd.rules.WOUND_TIERS
    local idx = Wyrd.rules.WOUND_INDEX[currentTierKey] or 1
    local step = 0
    if damage > threshold then step = maxHit and 2 or 1 end
    local newIdx = math.min(#tiers, idx + step)
    return { from = tiers[idx].key, to = tiers[newIdx].key, stepped = step,
             downed = (tiers[newIdx].key == 'downed') }
end

-- recovery helpers: move UP toward Unharmed (index 1)
function dice.recoverTiers(currentTierKey, tiersUp)
    local tiers = Wyrd.rules.WOUND_TIERS
    local idx = Wyrd.rules.WOUND_INDEX[currentTierKey] or 1
    local newIdx = math.max(1, idx - (tiersUp or 1))
    return tiers[newIdx].key
end

-- ---- Death's Door: roll Grit vs DC 12 each turn while Downed --------------
-- Doomed result = instant death. Caller tallies 3 successes (stabilise at
-- Critical) or 3 failures (death).
function dice.deathDoor(gritMod)
    local dd = Wyrd.rules.DEATH_DOOR
    local nat = dice.d20()
    local total = nat + (gritMod or 0)
    local otier = dice.outcome(total, dd.dc, nat)
    local instantDeath = (otier == 'doomed')
    return { nat = nat, total = total, dc = dd.dc, tier = otier,
             success = total >= dd.dc and not instantDeath,
             instantDeath = instantDeath }
end

-- ---- contested combat: both sides roll d20 + mod, higher wins -----------
-- Ties go to the defender (the one being acted upon). If the attacker wins,
-- the hit lands and its damage tier comes from the attacker's total vs the
-- defender's Defence DC (beat = max, meet = roll the die, miss = glancing min).
function dice.combatAttack(atkMod, defMod, defenceDC, weaponKey)
    local w = Wyrd.rules.WEAPONS[weaponKey]
    if not w then return nil, 'unknown weapon' end
    local aNat, dNat = dice.d20(), dice.d20()
    local aTotal = aNat + (atkMod or 0)
    local dTotal = dNat + (defMod or 0)
    if aTotal <= dTotal then   -- tie -> defender
        return { aNat=aNat, dNat=dNat, aTotal=aTotal, dTotal=dTotal,
                 landed=false, result='defended', damage=0, maxHit=false, weapon=weaponKey }
    end
    local result, damage, maxHit
    if aTotal > defenceDC then result, damage, maxHit = 'beat', w.max, true
    elseif aTotal == defenceDC then result, damage, maxHit = 'meet', dice.die(w.die), false
    else result, damage, maxHit = 'miss', w.min, false end
    return { aNat=aNat, dNat=dNat, aTotal=aTotal, dTotal=dTotal,
             landed=true, result=result, damage=damage, maxHit=maxHit, weapon=weaponKey }
end

return dice
