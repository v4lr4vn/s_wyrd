--[[ s_wyrd server — the character Sheet.

     Two backgrounds, hard split:
       Displaced  full Wyrdbound character (attributes, class, skills, WP,
                  wounds, the dice). Whitelisted.
       Modern     an ordinary Los Santos person. No Wyrdbound layer at all —
                  they live on the standard Saga systems (money, items, jobs).

     The Wyrdbound layer is gated to Displaced everywhere. A Modern character
     has no attributes to roll, so /check, /roll and magic are not theirs. ]]

local R       = Wyrd.rules
local classes = Wyrd.classes
local dice    = Wyrd.dice

local mode       = 'mem'
local sheetsMem  = {}   -- [charid] = sheet
local wlMem      = {}   -- [charid] = true   (Displaced whitelist)

local SHEET_SCHEMA = [[
CREATE TABLE IF NOT EXISTS saga_wyrd_sheets (
    charid     VARCHAR(40)  NOT NULL,
    background VARCHAR(16)  NOT NULL,
    data       LONGTEXT     NOT NULL,
    PRIMARY KEY (charid)
);]]
local WL_SCHEMA = [[
CREATE TABLE IF NOT EXISTS saga_wyrd_whitelist (
    charid VARCHAR(40) NOT NULL,
    PRIMARY KEY (charid)
);]]

-- ---- small helpers -------------------------------------------------------
local function charOf(src) local p = exports['s_core']:GetPlayer(src); return p and p.charid end
local function isAdmin(src) return exports['s_core']:IsAdmin(src) == true end

local function woundMod(sheet)
    local w = R.WOUND_TIERS[R.WOUND_INDEX[sheet.woundTier or 'unharmed'] or 1]
    return (w and w.rollMod) or 0
end

-- WP pool: magic classes get Wyrd x2 from L1; non-magic get Wyrd (x1) only
-- once they take the Branch Point at L12; otherwise none.
local function wpMaxFor(sheet)
    if not sheet or sheet.background ~= 'displaced' then return 0 end
    local cd = classes[sheet.class]
    local wyrd = (sheet.attributes and sheet.attributes.wyrd) or 0
    if cd and cd.magic then return wyrd * 2 end
    if sheet.branch then return wyrd end
    return 0
end

local function defenceDCFor(sheet, armourBonus, hasShield)
    local agi = (sheet.attributes and sheet.attributes.agility) or 0
    return R.defenceDC(agi, armourBonus or 0, hasShield)
end

local function skillMod(sheet, skill)
    local attr = R.SKILLS[skill]; if not attr then return nil end
    local base  = (sheet.attributes and sheet.attributes[attr]) or 0
    local train = R.TRAINING[(sheet.skills and sheet.skills[skill]) or 'untrained'] or 0
    return base + train + woundMod(sheet)
end

-- ---- persistence ---------------------------------------------------------
local function loadSheet(charid)
    if not charid then return nil end
    if mode == 'db' then
        local row = lib.db.single('SELECT data FROM saga_wyrd_sheets WHERE charid = ? LIMIT 1', { charid })
        return row and json.decode(row.data) or nil
    end
    return sheetsMem[charid]
end

local function saveSheet(sheet)
    if not sheet or not sheet.charid then return end
    if mode == 'db' then
        lib.db.query(
            'INSERT INTO saga_wyrd_sheets (charid, background, data) VALUES (?, ?, ?) ' ..
            'ON DUPLICATE KEY UPDATE background = VALUES(background), data = VALUES(data)',
            { sheet.charid, sheet.background, json.encode(sheet) })
    else
        sheetsMem[sheet.charid] = sheet
    end
end

local function isWhitelisted(charid)
    if not charid then return false end
    if mode == 'db' then
        return lib.db.single('SELECT 1 AS x FROM saga_wyrd_whitelist WHERE charid = ? LIMIT 1', { charid }) ~= nil
    end
    return wlMem[charid] == true
end

local function setWhitelist(charid, on)
    if not charid then return end
    if mode == 'db' then
        if on then lib.db.query('INSERT IGNORE INTO saga_wyrd_whitelist (charid) VALUES (?)', { charid })
        else lib.db.query('DELETE FROM saga_wyrd_whitelist WHERE charid = ?', { charid }) end
    else
        wlMem[charid] = on and true or nil
    end
end

-- ---- validation: a Displaced build must obey the rules of creation --------
-- attributes are exactly the 8/7/6/5/4/3 spread; class is valid; 4 distinct
-- Trained skills (2 from Origin + 2 from Class).
local function validateDisplaced(build)
    if type(build) ~= 'table' then return false, 'no build' end

    local a = build.attributes
    if type(a) ~= 'table' then return false, 'attributes missing' end
    local got = {}
    for _, k in ipairs(R.ATTRIBUTES) do
        local v = a[k]
        if type(v) ~= 'number' then return false, 'attribute ' .. k .. ' missing' end
        got[#got + 1] = v
    end
    table.sort(got, function(x, y) return x > y end)
    local need = R.POINT_BUY
    for i = 1, #need do
        if got[i] ~= need[i] then return false, 'attributes must be exactly 8, 7, 6, 5, 4, 3' end
    end

    if not classes[build.class] then return false, 'invalid class' end

    local o = build.origin
    if type(o) ~= 'table' or type(o.name) ~= 'string' or #o.name == 0 then return false, 'origin name required' end
    if type(o.skills) ~= 'table' or #o.skills ~= 2 then return false, 'origin needs exactly 2 skills' end
    if type(build.classSkills) ~= 'table' or #build.classSkills ~= 2 then return false, 'exactly 2 class skills required' end

    local seen = {}
    for _, list in ipairs({ o.skills, build.classSkills }) do
        for _, sk in ipairs(list) do
            if not R.SKILLS[sk] then return false, 'invalid skill ' .. tostring(sk) end
            if seen[sk] then return false, 'duplicate Trained skill ' .. sk end
            seen[sk] = true
        end
    end
    return true
end

local function buildToSheet(charid, name, build)
    local skills = {}
    for _, sk in ipairs(build.origin.skills) do skills[sk] = 'trained' end
    for _, sk in ipairs(build.classSkills) do skills[sk] = 'trained' end
    local at = build.attributes
    local sheet = {
        charid = charid, background = 'displaced', name = name or 'Unnamed',
        attributes = { might=at.might, agility=at.agility, wit=at.wit, wyrd=at.wyrd, sway=at.sway, grit=at.grit },
        class = build.class, subclass = nil, level = 1, branch = false,
        origin = { name = build.origin.name, trait = build.origin.trait, hook = build.origin.hook },
        skills = skills,
        warrior = build.warrior == true,
        oath = build.oath,
        woundTier = 'unharmed',
    }
    sheet.wpCurrent = wpMaxFor(sheet)
    return sheet
end

-- the view of a sheet sent to its owner's client (includes derived values)
local function publicSheet(sheet)
    if not sheet then return nil end
    if sheet.background ~= 'displaced' then
        return { background = sheet.background, name = sheet.name }
    end
    local mods = {}
    for sk in pairs(R.SKILLS) do mods[sk] = skillMod(sheet, sk) end
    local cd = classes[sheet.class]
    return {
        background = 'displaced', name = sheet.name, class = sheet.class, subclass = sheet.subclass,
        origin = sheet.origin, level = sheet.level, branch = sheet.branch,
        attributes = sheet.attributes, skills = sheet.skills, skillMods = mods,
        woundTier = sheet.woundTier, wpCurrent = sheet.wpCurrent, wpMax = wpMaxFor(sheet),
        defenceDC = defenceDCFor(sheet, 0, false), woundThreshold = R.woundThreshold(sheet.attributes.grit),
        warrior = sheet.warrior, magic = cd and cd.magic or false,
        wyrdGift = cd and cd.wyrdGift, ability = cd and cd.abilities[sheet.level],
    }
end

-- ---- callbacks: creation + reads -----------------------------------------
lib.callback.register('s_wyrd:createModern', function(src, payload)
    local charid = charOf(src); if not charid then return { ok = false } end
    if loadSheet(charid) then return { ok = false, err = 'exists' } end
    local p = exports['s_core']:GetPlayer(src)
    local sheet = { charid = charid, background = 'modern', name = (p and p.name) or (payload and payload.name) }
    saveSheet(sheet)
    local mcfg = Wyrd.config and Wyrd.config.modern
    if mcfg and mcfg.spawn then TriggerClientEvent('s_wyrd:spawnAt', src, mcfg.spawn) end
    TriggerClientEvent('s_wyrd:sheet', src, publicSheet(sheet))
    return { ok = true, background = 'modern' }
end)

lib.callback.register('s_wyrd:createDisplaced', function(src, build)
    local charid = charOf(src); if not charid then return { ok = false } end
    if loadSheet(charid) then return { ok = false, err = 'exists' } end
    if not (isWhitelisted(charid) or isAdmin(src)) then return { ok = false, err = 'not_whitelisted' } end
    local ok, err = validateDisplaced(build)
    if not ok then return { ok = false, err = err } end
    local p = exports['s_core']:GetPlayer(src)
    local sheet = buildToSheet(charid, (p and p.name) or build.name, build)
    saveSheet(sheet)
    -- Displaced arrive from Midgard: no modern money, only Old Coin, at the tear.
    local cfg = Wyrd.config and Wyrd.config.displaced
    if cfg then
        exports['s_core']:SetMoney(src, 'cash', 0)
        exports['s_core']:SetMoney(src, 'bank', 0)
        exports['s_core']:SetMoney(src, 'coin', cfg.startingCoin or 0)
        if cfg.spawn then TriggerClientEvent('s_wyrd:spawnAt', src, cfg.spawn) end
        -- (no ID / no phone: enforced by the inventory loadout when items exist)
    end
    TriggerClientEvent('s_wyrd:sheet', src, publicSheet(sheet))
    return { ok = true }
end)

lib.callback.register('s_wyrd:getOwnSheet', function(src) return publicSheet(loadSheet(charOf(src))) end)

-- authoritative skill check: server reads the caller's sheet, computes the
-- modifier (attribute + training + wound penalty) and rolls. Displaced only.
lib.callback.register('s_wyrd:checkSkill', function(src, req)
    local sheet = loadSheet(charOf(src))
    if not (sheet and sheet.background == 'displaced') then return { denied = true } end
    local skill = tostring(req and req.skill or ''):lower()
    local attr = R.SKILLS[skill]
    if not attr then return { err = 'unknown_skill' } end
    local mod = skillMod(sheet, skill)
    local dc = tonumber(req and req.dc)
    local res = dice.wyrdRoll(mod, dc or 0)
    res.hasDC = dc ~= nil
    local train = (sheet.skills[skill] or 'untrained')
    local tag = train ~= 'untrained' and (' (' .. train:gsub('^%l', string.upper) .. ')') or ''
    res.label = ('%s + %s%s'):format(R.ATTR_LABEL[attr], R.SKILL_LABEL[skill], tag)
    Wyrd.broadcastRoll(src, {
        name = Wyrd.nameOf(src), label = res.label, tier = res.tier,
        total = res.total, dc = res.dc, hasDC = res.hasDC, nat = res.nat,
    })
    return res
end)

-- ---- load on join: push sheet, or ask the client to create one -----------
AddEventHandler('s_core:playerLoaded', function(src, charid)
    charid = charid or charOf(src)
    local sheet = loadSheet(charid)
    if sheet then
        TriggerClientEvent('s_wyrd:sheet', src, publicSheet(sheet))
    else
        TriggerClientEvent('s_wyrd:needsCreation', src, { whitelisted = isWhitelisted(charid) })
    end
end)

-- ---- staff commands ------------------------------------------------------
lib.addCommand('wldisplaced', { help = 'Grant/revoke a character the Displaced whitelist', restricted = false }, function(src, args)
    if not isAdmin(src) then return end
    local target = tonumber(args[1]); if not target then return end
    local charid = charOf(target); if not charid then return end
    local on = (args[2] or 'on'):lower() ~= 'off'
    setWhitelist(charid, on)
    TriggerClientEvent('s_wyrd:notify', src, { title = 'Whitelist',
        description = ('%s Displaced whitelist for #%d'):format(on and 'Granted' or 'Revoked', target), type = 'success' })
    TriggerClientEvent('s_wyrd:notify', target, { title = 'Ash & Iron',
        description = on and 'You have been granted the Displaced whitelist.' or 'Your Displaced whitelist was revoked.',
        type = on and 'success' or 'inform' })
end)

lib.addCommand('wyrdreset', { help = 'Wipe a character sheet so they can re-create (staff)', restricted = false }, function(src, args)
    if not isAdmin(src) then return end
    local target = tonumber(args[1]); if not target then return end
    local charid = charOf(target); if not charid then return end
    if mode == 'db' then lib.db.query('DELETE FROM saga_wyrd_sheets WHERE charid = ?', { charid })
    else sheetsMem[charid] = nil end
    TriggerClientEvent('s_wyrd:needsCreation', target, { whitelisted = isWhitelisted(charid) })
end)

-- ---- cross-file + cross-resource gates / accessors -----------------------
function Wyrd.isDisplaced(src)
    local s = loadSheet(charOf(src)); return s ~= nil and s.background == 'displaced'
end
function Wyrd.canRoll(src) return Wyrd.isDisplaced(src) or isAdmin(src) end

exports('IsDisplaced',     function(src) return Wyrd.isDisplaced(src) end)
exports('IsWhitelisted',   function(src) return isWhitelisted(charOf(src)) end)
exports('GetSheet',        function(src) return loadSheet(charOf(src)) end)
exports('GetBackground',   function(src) local s = loadSheet(charOf(src)); return s and s.background or nil end)
exports('GetSkillMod',     function(src, skill) local s = loadSheet(charOf(src)); return s and skillMod(s, skill) end)
exports('GetDefenceDC',    function(src, armourBonus, shield) local s = loadSheet(charOf(src)); return s and defenceDCFor(s, armourBonus, shield) end)
exports('GetWoundThreshold', function(src) local s = loadSheet(charOf(src)); return s and R.woundThreshold(s.attributes.grit) end)
exports('GetWoundTier',    function(src) local s = loadSheet(charOf(src)); return s and s.woundTier end)
exports('GetWP',           function(src) local s = loadSheet(charOf(src)); return s and s.wpCurrent end)
exports('GetWPMax',        function(src) local s = loadSheet(charOf(src)); return s and wpMaxFor(s) end)

exports('SetWoundTier', function(src, tier)
    local s = loadSheet(charOf(src)); if not s or not R.WOUND_INDEX[tier] then return false end
    s.woundTier = tier; saveSheet(s); TriggerClientEvent('s_wyrd:sheet', src, publicSheet(s)); return true
end)
exports('SpendWP', function(src, amount)
    local s = loadSheet(charOf(src)); if not s then return false end
    amount = tonumber(amount) or 0
    if (s.wpCurrent or 0) < amount then return false end
    s.wpCurrent = s.wpCurrent - amount; saveSheet(s); TriggerClientEvent('s_wyrd:sheet', src, publicSheet(s)); return true
end)
exports('RestoreWP', function(src, amount)
    local s = loadSheet(charOf(src)); if not s then return false end
    local maxwp = wpMaxFor(s)
    s.wpCurrent = math.min(maxwp, (s.wpCurrent or 0) + (tonumber(amount) or maxwp))
    saveSheet(s); TriggerClientEvent('s_wyrd:sheet', src, publicSheet(s)); return true
end)

CreateThread(function()
    if GetResourceState('oxmysql') == 'started' then
        mode = 'db'
        lib.db.query(SHEET_SCHEMA, {})
        lib.db.query(WL_SCHEMA, {})
        lib.print.info('s_wyrd sheets: database mode')
    else
        lib.print.warn('s_wyrd sheets: in-memory mode (no oxmysql) — sheets reset on restart')
    end
end)
