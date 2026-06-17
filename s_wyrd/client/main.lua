--[[ s_wyrd client — rolls & reference.
       /roll <modifier> [dc]     a raw d20 + modifier (Displaced / Skald)
       /check <skill> [dc]       a Wyrd Roll read straight from your sheet
       /wyrd                      the Quick Reference card
     The Wyrdbound layer is Displaced-only; a Modern character is told plainly
     that the old ways are not theirs. ]]

local R = Wyrd.rules

local TIER_TYPE = { glorious='success', true_='success', strained='inform', broken='error', doomed='error' }
local function tierLabel(t) local o = R.OUTCOMES[t]; return (o and o.label) or t end
local function signed(n) return (n >= 0 and '+' or '') .. n end

local function noWyrd()
    lib.notify({ title = 'The Old Ways', description = 'You have no wyrd to read. That sight is not yours.', type = 'error' })
end

local function showResult(res)
    if not res then return end
    if res.denied then return noWyrd() end
    if res.err == 'unknown_skill' then
        lib.notify({ title = 'Wyrd', description = 'Unknown skill. Open /wyrd for the list.', type = 'error' }); return
    end
    local body
    if res.hasDC then
        body = ('%s   \u{00B7}   d20 %d %s = %d  vs DC %d'):format(tierLabel(res.tier), res.nat, signed(res.modifier), res.total, res.dc)
    else
        body = ('d20 %d %s = %d'):format(res.nat, signed(res.modifier), res.total)
    end
    lib.notify({
        title = res.label or 'Wyrd Roll',
        description = body,
        type = res.hasDC and (TIER_TYPE[res.tier] or 'inform') or 'inform',
    })
end

-- /roll <modifier> [dc]  (server gates to Displaced / admin)
RegisterCommand('roll', function(_, args)
    local mod = tonumber(args[1]) or 0
    local dc = tonumber(args[2])
    showResult(lib.callback.await('s_wyrd:roll', false, { modifier = mod, dc = dc, label = 'Roll' }))
end, false)

-- /check <skill> [dc]  — full Wyrd Roll computed from your sheet, server-side
RegisterCommand('check', function(_, args)
    local skill = (args[1] or ''):lower()
    if skill == '' then
        lib.notify({ title = 'Wyrd', description = 'Usage: /check <skill> [dc]', type = 'inform' }); return
    end
    if not R.SKILLS[skill] then
        lib.notify({ title = 'Wyrd', description = 'Unknown skill. Open /wyrd for the list.', type = 'error' }); return
    end
    local dc = tonumber(args[2])
    showResult(lib.callback.await('s_wyrd:checkSkill', false, { skill = skill, dc = dc }))
end, false)

-- nearby players see a compact line when someone rolls
RegisterNetEvent('s_wyrd:rollFeed', function(p)
    local body = p.hasDC
        and ('%s \u{2014} %s (%d vs %d)'):format(p.label, tierLabel(p.tier), p.total, p.dc)
        or  ('%s \u{2014} rolled %d'):format(p.label, p.total)
    lib.notify({ title = p.name, description = body, type = 'inform' })
end)

-- ---- /wyrd : in-game Quick Reference card --------------------------------
local function buildReference()
    lib.context.register({ id = 'wyrd_ref', title = 'Wyrdbound \u{2014} Quick Reference', options = {
        { title = 'Difficulty Scale',    icon = '\u{25C8}', menu = 'wyrd_dc' },
        { title = 'Outcome Tiers',       icon = '\u{2726}', menu = 'wyrd_out' },
        { title = 'Skills by Attribute', icon = '\u{2316}', menu = 'wyrd_skills' },
    } })
    local dco = {}
    for _, d in ipairs(R.DC_SCALE) do
        dco[#dco + 1] = { title = ('%s \u{2014} DC %d'):format(d.label, d.dc), description = d.eg }
    end
    lib.context.register({ id = 'wyrd_dc', title = 'Difficulty', menu = 'wyrd_ref', options = dco })
    lib.context.register({ id = 'wyrd_out', title = 'Outcome Tiers', menu = 'wyrd_ref', options = {
        { title = 'Glorious', description = 'Nat 20 or 5+ above DC \u{2014} succeed brilliantly' },
        { title = 'True',     description = 'Meets or beats DC \u{2014} succeed' },
        { title = 'Strained', description = '1 to 4 below \u{2014} partial, there is a cost' },
        { title = 'Broken',   description = '5 to 9 below \u{2014} fail forward' },
        { title = 'Doomed',   description = 'Nat 1 or 10+ below \u{2014} something goes wrong' },
    } })
    local grouped = {}
    for _, attr in ipairs(R.ATTRIBUTES) do
        local names = {}
        for sk, at in pairs(R.SKILLS) do if at == attr then names[#names + 1] = R.SKILL_LABEL[sk] end end
        table.sort(names)
        grouped[#grouped + 1] = { title = R.ATTR_LABEL[attr], description = table.concat(names, ', ') }
    end
    lib.context.register({ id = 'wyrd_skills', title = 'Skills', menu = 'wyrd_ref', options = grouped })
end

RegisterCommand('wyrd', function()
    local s = Wyrd.mySheet and Wyrd.mySheet()
    if s and s.background == 'modern' then
        lib.notify({ title = 'The Old Ways', description = 'These words mean nothing to you. They are not your inheritance.', type = 'inform' })
        return
    end
    buildReference()
    lib.context.show('wyrd_ref')
end, false)
