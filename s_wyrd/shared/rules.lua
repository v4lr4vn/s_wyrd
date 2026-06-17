--[[ s_wyrd — the canonical Wyrdbound ruleset, encoded once as shared data.
     Every later system (sheet, checks, combat, magic) reads from THIS file so
     the rules live in exactly one place. First Edition. ]]

Wyrd = Wyrd or {}
local R = {}
Wyrd.rules = R

-- ---- attributes ----------------------------------------------------------
-- Score 1-10. The score IS the modifier (no conversion). Point-buy spread:
R.ATTRIBUTES   = { 'might', 'agility', 'wit', 'wyrd', 'sway', 'grit' }
R.ATTR_LABEL   = { might='Might', agility='Agility', wit='Wit', wyrd='Wyrd', sway='Sway', grit='Grit' }
R.ATTR_BLURB   = {
    might   = 'Strength, forcing, lifting, heavy weapons',
    agility = 'Speed, reflexes, finesse, stealth, Defence',
    wit     = 'Intelligence, memory, perception, cunning',
    wyrd    = 'Willpower, magic, fate connection, WP pool',
    sway    = 'Presence, leadership, persuasion, social',
    grit    = 'Endurance, pain tolerance, Wound Threshold',
}
R.POINT_BUY    = { 8, 7, 6, 5, 4, 3 }   -- distribute among the six attributes

-- ---- skills --------------------------------------------------------------
-- skill key -> governing attribute. Training: Untrained +0, Trained +2, Mastered +4.
R.SKILLS = {
    athletics='might',  brawl='might',     intimidation='might',
    acrobatics='agility', stealth='agility', sleight_of_hand='agility',
    lore='wit',         perception='wit',  medicine='wit',
    arcana='wyrd',      commune='wyrd',    resolve='wyrd',
    persuasion='sway',  deception='sway',  performance='sway',
    endurance='grit',   fortitude='grit',  composure='grit',
}
R.SKILL_LABEL = {
    athletics='Athletics', brawl='Brawl', intimidation='Intimidation',
    acrobatics='Acrobatics', stealth='Stealth', sleight_of_hand='Sleight of Hand',
    lore='Lore', perception='Perception', medicine='Medicine',
    arcana='Arcana', commune='Commune', resolve='Resolve',
    persuasion='Persuasion', deception='Deception', performance='Performance',
    endurance='Endurance', fortitude='Fortitude', composure='Composure',
}
R.TRAINING = { untrained = 0, trained = 2, mastered = 4 }

-- ---- difficulty ----------------------------------------------------------
R.DC_SCALE = {
    { key='simple',    dc=8,  label='Simple',    eg='Lifting a door, a friendly ask' },
    { key='moderate',  dc=12, label='Moderate',  eg='Tracking in a forest, basic lock' },
    { key='hard',      dc=16, label='Hard',      eg='Climbing a wet cliff, a wary guard' },
    { key='severe',    dc=20, label='Severe',    eg='Persuading a hostile jarl' },
    { key='legendary', dc=25, label='Legendary', eg='Resisting divine influence' },
}
R.DC_BY_KEY = {}
for _, d in ipairs(R.DC_SCALE) do R.DC_BY_KEY[d.key] = d.dc end

-- ---- outcome tiers -------------------------------------------------------
-- Resolved from (total - dc) margin plus the natural d20. Order best->worst.
R.OUTCOMES = {
    glorious = { label='Glorious', desc='Succeed brilliantly' },
    true_    = { label='True',     desc='Succeed' },
    strained = { label='Strained', desc='Partial, there is a cost' },
    broken   = { label='Broken',   desc='Fail forward' },
    doomed   = { label='Doomed',   desc='Something goes wrong' },
}

-- ---- combat: weapons -----------------------------------------------------
R.WEAPONS = {
    dagger     = { label='Dagger',     die=4,  min=1, max=4 },
    shortsword = { label='Shortsword', die=6,  min=2, max=6 },
    longsword  = { label='Longsword',  die=8,  min=3, max=8 },
    greataxe   = { label='Greataxe',   die=12, min=4, max=12 },
    spear      = { label='Spear',      die=6,  min=2, max=6 },
    shortbow   = { label='Shortbow',   die=6,  min=2, max=6, ranged=true },
    longbow    = { label='Longbow',    die=8,  min=3, max=8, ranged=true },
}

-- ---- combat: armour & defence -------------------------------------------
-- Defence DC = 8 + Agility + armour bonus (+ shield if held).
R.ARMOUR = {
    none   = { label='No armour', def=0, agiPenalty=0 },
    light  = { label='Light',     def=2, agiPenalty=0 },
    medium = { label='Medium',    def=4, agiPenalty=-1 },
    heavy  = { label='Heavy',     def=6, agiPenalty=-2 },
}
R.SHIELD_BONUS = 1

R.SITUATIONAL = {
    flanking      = { label='Flanking',     defMod=-2 },
    high_ground   = { label='High Ground',  rangedAtkMod=1 },
    partial_cover = { label='Partial Cover',defModVsRanged=2 },
    full_cover    = { label='Full Cover',   blocksRanged=true },
    prone         = { label='Prone',        atkMod=-2, defModVsMelee=-2, defModVsRanged=2 },
}

-- ---- wounds --------------------------------------------------------------
-- Wound Threshold = Grit + 5. Damage over threshold steps tiers down:
-- Standard hit = 1 tier, Max hit = 2 tiers. Ordered best (1) -> worst (6).
R.WOUND_TIERS = {
    { key='unharmed',     label='Unharmed',      rollMod=0,  note='No effect' },
    { key='scratched',    label='Scratched',     rollMod=0,  note='No effect' },
    { key='wounded',      label='Wounded',       rollMod=-1, note='-1 to all rolls' },
    { key='badly_wounded',label='Badly Wounded', rollMod=-2, note='-2 to all rolls. Move costs Main Action.' },
    { key='critical',     label='Critical',      rollMod=-3, note='-3 to all rolls. Only 1 action per turn.' },
    { key='downed',       label='Downed',        rollMod=0,  note="Death's Door rolls." },
}
R.WOUND_INDEX = {}
for i, w in ipairs(R.WOUND_TIERS) do R.WOUND_INDEX[w.key] = i end
R.DEATH_DOOR = { dc = 12, successesToStabilise = 3, failuresToDie = 3 }

R.RECOVERY = {
    breather   = { label='Breather',   time='5-10 min', effect='Remove Scratched. Recover 1 extra tier.' },
    short_rest = { label='Short Rest', time='1 hour safe', effect='Wounded at worst. Regain half max WP.' },
    long_rest  = { label='Long Rest',  time='Full night', effect='Full recovery. All WP restored.' },
}

-- ---- magic ---------------------------------------------------------------
-- Magic roll: d20 + Wyrd + (Arcana or Commune) vs Cast DC. WP max = Wyrd x 2.
-- WP cost is spent before the roll and is spent even if the spell fails.
R.MAGIC_TIERS = {
    { key='cantrip', label='Cantrip', wp=0,         dc=nil, power='Minor, unlimited' },
    { key='t1',      label='Tier 1',  wp=2,         dc=10,  power='Small, reliable' },
    { key='t2',      label='Tier 2',  wp=4,         dc=13,  power='Noticeable' },
    { key='t3',      label='Tier 3',  wp=6,         dc=16,  power='Significant' },
    { key='t4',      label='Tier 4',  wp=8,         dc=20,  power='Near-legendary' },
    { key='t5',      label='Tier 5',  wp='all', wpMin=8, dc=22, power='Catastrophic. Once per saga.' },
}
R.MAGIC_BY_KEY = {}
for _, m in ipairs(R.MAGIC_TIERS) do R.MAGIC_BY_KEY[m.key] = m end
R.MAGIC_CLASSES = { 'Ashen', 'Stormcaller', 'Runewarden', 'Veilwalker', 'Bloodskalder', 'Volva' }
R.BRANCH_POINT_LEVEL = 12   -- non-magic classes can access minor magic here (WP = Wyrd score)
R.SUBCLASS_LEVEL = 5

-- ---- conditions ----------------------------------------------------------
R.CONDITIONS = {
    strained   = { label='Strained',   desc='-2 to your next roll. Then it ends.' },
    frightened = { label='Frightened', desc='-2 to all rolls while source is visible. Cannot willingly move toward source.' },
    charmed    = { label='Charmed',    desc='Treat charmer as friendly. Cannot attack them.' },
    prone      = { label='Prone',      desc='-2 to attacks. -2 Defence vs melee. +2 Defence vs ranged. Costs Move to stand.' },
    stunned    = { label='Stunned',    desc='Cannot take actions or Reactions until end of your next turn.' },
    grappled   = { label='Grappled',   desc='Speed 0. -1 to attack rolls. Escape: contested Might+Brawl or Agility+Acrobatics.' },
    deafened   = { label='Deafened',   desc='Cannot hear. Fail hearing Perception. -1 Sway in conversation.' },
    blinded    = { label='Blinded',    desc='-4 to attacks. Attackers ignore your Agility armour bonus.' },
}

-- ---- formulas ------------------------------------------------------------
function R.defenceDC(agility, armourBonus, hasShield)
    return 8 + (agility or 0) + (armourBonus or 0) + (hasShield and R.SHIELD_BONUS or 0)
end
function R.woundThreshold(grit) return (grit or 0) + 5 end
function R.wpMax(wyrd) return (wyrd or 0) * 2 end

return R
