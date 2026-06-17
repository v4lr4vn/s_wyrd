--[[ s_wyrd client — the Sheet on the player's side.
     Caches the owner's sheet, runs character creation (background choice, and
     for the Displaced a guided point-buy / class / origin / skills flow built
     on lib.context + lib.inputDialog), and shows it with /sheet. ]]

local R       = Wyrd.rules
local classes = Wyrd.classes

local mySheet = nil
function Wyrd.mySheet() return mySheet end

RegisterNetEvent('s_wyrd:sheet',  function(s) mySheet = s end)
RegisterNetEvent('s_wyrd:notify', function(p) lib.notify(p) end)

-- spawn the player at their background's location (Displaced -> the tear)
RegisterNetEvent('s_wyrd:spawnAt', function(p)
    if type(p) ~= 'table' or not p.x then return end
    CreateThread(function()
        DoScreenFadeOut(400); Wait(450)
        local ped = PlayerPedId()
        SetEntityCoords(ped, p.x + 0.0, p.y + 0.0, p.z + 0.0, false, false, false, false)
        SetEntityHeading(ped, (p.h or 0.0) + 0.0)
        Wait(250); DoScreenFadeIn(500)
    end)
end)

-- a flat, sorted skill option list for select rows: "Stealth (Agility)"
local function skillOptions()
    local opts = {}
    for sk, at in pairs(R.SKILLS) do
        opts[#opts + 1] = { value = sk, label = ('%s (%s)'):format(R.SKILL_LABEL[sk], R.ATTR_LABEL[at]) }
    end
    table.sort(opts, function(a, b) return a.label < b.label end)
    return opts
end

-- ---- Displaced creation: sequential point-buy ----------------------------
local function assignPoints(build, idx, remaining, done)
    if idx > #R.POINT_BUY then return done(build) end
    local val = R.POINT_BUY[idx]
    local opts = {}
    for _, attr in ipairs(remaining) do
        local a = attr
        opts[#opts + 1] = {
            title = R.ATTR_LABEL[a],
            description = R.ATTR_BLURB[a],
            onSelect = function()
                build.attributes[a] = val
                local rest = {}
                for _, x in ipairs(remaining) do if x ~= a then rest[#rest + 1] = x end end
                assignPoints(build, idx + 1, rest, done)
            end,
        }
    end
    lib.context.register({ id = 'wyrd_pb', title = ('Assign %d to which attribute?'):format(val), options = opts })
    lib.context.show('wyrd_pb')
end

local function finalizeDisplaced(build)
    CreateThread(function()
        local res = lib.callback.await('s_wyrd:createDisplaced', false, build)
        if res and res.ok then
            lib.notify({ title = 'Ash & Iron', description = 'Your wyrd is set. Welcome, Displaced.', type = 'success' })
        elseif res and res.err == 'not_whitelisted' then
            lib.notify({ title = 'Displaced Whitelist', description = 'You are not whitelisted for a Displaced character. Apply via Discord.', type = 'error' })
        elseif res and res.err == 'exists' then
            lib.notify({ title = 'Creation', description = 'You already have a character sheet.', type = 'inform' })
        else
            lib.notify({ title = 'Creation', description = 'Could not create: ' .. tostring(res and res.err or 'unknown') .. '. Try /wyrdcreate again.', type = 'error' })
        end
    end)
end

local function chooseSkills(build)
    CreateThread(function()
        local opts = skillOptions()
        local origin = lib.inputDialog('Origin', {
            { type = 'input',  label = 'Origin name', placeholder = 'e.g. Fisher of Eldvik', required = true, max = 48 },
            { type = 'input',  label = 'Background trait (optional)', max = 80 },
            { type = 'input',  label = 'Starting hook (optional)', max = 120 },
            { type = 'select', label = 'Origin skill 1', options = opts, required = true },
            { type = 'select', label = 'Origin skill 2', options = opts, required = true },
        })
        if not origin then return end
        build.origin = { name = origin[1], trait = origin[2], hook = origin[3], skills = { origin[4], origin[5] } }

        local cd = classes[build.class]
        local cls = lib.inputDialog(('%s \u{2014} Class Skills'):format(build.class), {
            { type = 'select', label = 'Class skill 1', options = opts, required = true },
            { type = 'select', label = 'Class skill 2', options = opts, required = true },
        })
        if not cls then return end
        build.classSkills = { cls[1], cls[2] }

        -- quick client-side dup guard for a friendlier message before the server check
        local seen = {}
        for _, sk in ipairs({ origin[4], origin[5], cls[1], cls[2] }) do
            if seen[sk] then
                lib.notify({ title = 'Skills', description = 'Your four Trained skills must all be different. Run /wyrdcreate to retry.', type = 'error' })
                return
            end
            seen[sk] = true
        end
        finalizeDisplaced(build)
    end)
end

local function chooseClass(build)
    local opts = {}
    for _, name in ipairs(Wyrd.classOrder) do
        local cd = classes[name]
        local n = name
        opts[#opts + 1] = {
            title = name,
            description = ('%s%s'):format(cd.magic and '[Magic] ' or '', cd.tagline or ''),
            onSelect = function() build.class = n; chooseSkills(build) end,
        }
    end
    lib.context.register({ id = 'wyrd_class', title = 'Choose your Class', options = opts })
    lib.context.show('wyrd_class')
end

local function startDisplacedCreation()
    local build = { attributes = {} }
    local order = {}
    for _, a in ipairs(R.ATTRIBUTES) do order[#order + 1] = a end
    assignPoints(build, 1, order, function(b) chooseClass(b) end)
end

-- ---- background choice ---------------------------------------------------
local function openBackgroundChoice(info)
    lib.context.register({ id = 'wyrd_bg', title = 'Who are you?', options = {
        {
            title = 'Displaced', icon = '\u{2694}',
            description = 'Pulled from Midgard. Old knowledge, no modern world. Whitelisted, full Wyrdbound character.',
            onSelect = function()
                if info and info.whitelisted == false then
                    lib.notify({ title = 'Displaced Whitelist', description = 'You must be whitelisted to play Displaced. Apply via Discord.', type = 'error' })
                    return
                end
                startDisplacedCreation()
            end,
        },
        {
            title = 'Modern', icon = '\u{1F3D9}',
            description = 'Born in Los Santos. An ordinary life — no wyrd, no old ways. Just the city and what you make of it.',
            onSelect = function()
                CreateThread(function()
                    local res = lib.callback.await('s_wyrd:createModern', false, {})
                    if res and res.ok then
                        lib.notify({ title = 'Los Santos', description = 'Welcome. Make your own way.', type = 'success' })
                    else
                        lib.notify({ title = 'Creation', description = 'Could not create character.', type = 'error' })
                    end
                end)
            end,
        },
    } })
    lib.context.show('wyrd_bg')
end

RegisterNetEvent('s_wyrd:needsCreation', function(info) openBackgroundChoice(info or {}) end)

RegisterCommand('wyrdcreate', function()
    if mySheet then
        lib.notify({ title = 'Creation', description = 'You already have a character.', type = 'inform' })
        return
    end
    openBackgroundChoice({})
end, false)

-- ---- /sheet : view your own character ------------------------------------
local function showSheet()
    if not mySheet then
        lib.notify({ title = 'Sheet', description = 'No character yet. Use /wyrdcreate.', type = 'inform' })
        return
    end
    if mySheet.background ~= 'displaced' then
        lib.notify({ title = mySheet.name or 'Modern', description = 'An ordinary life in Los Santos. No wyrd to speak of.', type = 'inform' })
        return
    end
    local s = mySheet
    local attrLine = {}
    for _, a in ipairs(R.ATTRIBUTES) do attrLine[#attrLine + 1] = ('%s %d'):format(R.ATTR_LABEL[a], s.attributes[a]) end

    local trained = {}
    for sk, st in pairs(s.skills or {}) do
        if st ~= 'untrained' then trained[#trained + 1] = ('%s (%s)'):format(R.SKILL_LABEL[sk], st:gsub('^%l', string.upper)) end
    end
    table.sort(trained)

    local wt = R.WOUND_TIERS[R.WOUND_INDEX[s.woundTier or 'unharmed']]
    local opts = {
        { title = s.name or 'Unnamed', description = ('%s%s  ·  Level %d'):format(s.class, s.subclass and (' / ' .. s.subclass) or '', s.level or 1) },
        { title = 'Attributes', description = table.concat(attrLine, '   ') },
        { title = 'Defence DC ' .. (s.defenceDC or '?'), description = ('Wound Threshold %d  ·  %s'):format(s.woundThreshold or 0, s.magic and ('WP %d / %d'):format(s.wpCurrent or 0, s.wpMax or 0) or 'No magic') },
        { title = 'Wound: ' .. (wt and wt.label or '?'), description = wt and wt.note or '' },
        { title = 'Trained Skills', description = #trained > 0 and table.concat(trained, ', ') or 'None' },
    }
    if s.origin then opts[#opts + 1] = { title = 'Origin: ' .. (s.origin.name or '?'), description = s.origin.hook or s.origin.trait or '' } end
    if s.wyrdGift then opts[#opts + 1] = { title = 'Wyrd Gift: ' .. s.wyrdGift.name, description = s.wyrdGift.desc } end
    if s.ability then opts[#opts + 1] = { title = ('Ability (L%d): %s'):format(s.level or 1, s.ability.name), description = s.ability.desc } end

    lib.context.register({ id = 'wyrd_sheet', title = 'Your Saga', options = opts })
    lib.context.show('wyrd_sheet')
end

RegisterCommand('sheet', function() showSheet() end, false)
