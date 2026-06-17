--[[ s_wyrd — the ten Classes of Wyrdbound. Each carries a primary/secondary
     attribute, a magic flag, a Wyrd Gift (granted at creation), Foundation
     Abilities by level (1/3/5/8/12/17/20), and three subclasses chosen at
     level 5. Transcribed from the Wyrdbound character sheet / Wanderer's Codex. ]]

Wyrd = Wyrd or {}

Wyrd.classes = {
    Ironborn = {
        primary='might', secondary='grit', magic=false,
        tagline='You survived. You should not have. Whatever broke you also made you.',
        wyrdGift={ name='Unbroken', desc='The first time each session you would drop to zero health, you drop to 1 instead. You do not fall. You never fall.' },
        abilities={
            [1]={ name='Scarred Hide', desc='Permanent +2 to your Defence DC. Your scars have hardened into armour.' },
            [3]={ name='Iron Will', desc='Once per combat, reroll any failed roll against fear, pain, or mental effects.' },
            [5]={ name='Retribution Strike', desc='When you take damage, your next attack deals Standard damage minimum regardless of the Defence DC check.' },
            [8]={ name='Endure', desc='Ignore the mechanical penalties of one Wound Tier per combat.' },
            [12]={ name='Become the Wound', desc='For every Wound Tier you carry, gain +1 to attack rolls. Maximum +4.' },
            [17]={ name='Deathless Fury', desc='Once per session, when Unbroken triggers, enter a fury state for 3 rounds. Every hit deals Max damage.' },
            [20]={ name='Wyrd Ascendant: Ironborn', desc='Work with your Skald. At this level the Ironborn transcends mortal limits. You cannot be permanently destroyed by conventional means.' },
        },
        subclasses={
            { name='Chainbreaker', desc='The unstoppable force. Breaking through defences, shattering armour, turning raw momentum into devastation.' },
            { name='Gravewall', desc='The immovable object. Protecting allies, holding positions, becoming an unbreakable anchor.' },
            { name='Scarborn', desc='The beautiful disaster. Abilities interact with your own Wound Tiers, converting suffering into power.' },
        },
    },
    Skeinblade = {
        primary='agility', secondary='wit', magic=false,
        tagline='The fight is already over. They just have not realised it yet.',
        wyrdGift={ name='Fatereader', desc='Once per combat, before either side rolls on a contested attack, call the outcome. If you are right, your roll automatically counts as a Glorious result.' },
        abilities={
            [1]={ name='Thread Step', desc='Once per round, move without triggering a contested roll from enemies.' },
            [3]={ name='Fracture Point', desc="Once per combat, identify an enemy's lowest attribute. The Skald must tell you." },
            [5]={ name='Counter Wyrd', desc='When an enemy wins a contested roll against you, immediately make a free retaliatory strike at +2.' },
            [8]={ name='Inevitable Strike', desc='Once per combat, declare a strike Inevitable. If it lands, it automatically beats the Defence DC.' },
            [12]={ name='Unravel', desc="Each hit reduces the target's Defence DC by 1 until combat ends. Stacks with every hit." },
            [17]={ name='The Last Thread', desc='Once per session, after seeing an enemy roll, swap their result with yours retroactively.' },
            [20]={ name='Wyrd Ascendant: Skeinblade', desc='Work with your Skald. At this level the Skeinblade reads fate itself, knowing what will happen before it does.' },
        },
        subclasses={
            { name='Strikewoven', desc='The duelist. Single-target mastery, dismantling one opponent with surgical precision.' },
            { name='Threadcutter', desc='The chaos agent. Control multiple enemies, reposition freely, turn enemies against each other.' },
            { name='Ghostblade', desc='The assassin. Strike from impossible angles and disappear mid-combat.' },
        },
    },
    Ashen = {
        primary='wyrd', secondary='grit', magic=true,
        tagline='Death knows your name. It is waiting for you to use it.',
        wyrdGift={ name="Death's Debt", desc='When you or an ally would die, you may take their death instead, reducing to 1 HP. The soul you saved owes you a Death Mark. Once per session they must answer your call for aid.' },
        abilities={
            [1]={ name='Ashen Touch', desc="Melee attacks reduce the target's maximum HP by 1 until they rest." },
            [3]={ name='Grave Calling', desc='Summon the echo of a fallen enemy to fight for you for 3 rounds at half stats.' },
            [5]={ name='Soul Drain', desc='Steal vitality from a wounded enemy. Heal HP equal to their current Wound Tier.' },
            [8]={ name='Death Walking', desc='Once per session, feign death perfectly for up to 1 hour. Magic cannot detect you as living.' },
            [12]={ name='Unravel the Living', desc='Your decay attacks ignore armour bonuses to Defence DC.' },
            [17]={ name='The Final Breath', desc='Once per session, touch a dying creature. They survive at 1 HP but cannot act against you this session.' },
            [20]={ name='Wyrd Ascendant: Ashen', desc='Work with your Skald. At this level the Ashen stands with one foot in death permanently, able to cross and return at will.' },
        },
        subclasses={
            { name='Bonecaller', desc='Commands the dead. Summon and maintain a growing host of fallen echoes. You never fight alone.' },
            { name='Plagueborn', desc='Spreads decay through enemies. Stack conditions and compound suffering.' },
            { name='Deathpact', desc='Makes deals with death itself. Tremendous power in exchange for real personal cost.' },
        },
    },
    Stormcaller = {
        primary='wyrd', secondary='might', magic=true,
        tagline='The sky answers to you. So does everything beneath it.',
        wyrdGift={ name='Stormborn', desc='Weather responds to your emotional state. You gain +2 to all rolls during natural storms or extreme weather.' },
        abilities={
            [1]={ name='Elemental Strike', desc='Infuse attacks with fire, ice, lightning, or wind. Deals +1d4 elemental damage.' },
            [3]={ name='Storm Step', desc='Teleport up to 20 feet to any visible location once per combat.' },
            [5]={ name='Tempest Shield', desc='+3 to Defence DC. Any melee attacker takes 1d4 elemental damage.' },
            [8]={ name='Call Lightning', desc='Single target, Max damage, ignores Defence DC. Once per combat.' },
            [12]={ name='Eye of the Storm', desc='All enemies in range make Grit vs DC 16 or be knocked prone and Strained on their next action.' },
            [17]={ name='Worldbreaker', desc='For 3 rounds, all your attacks are automatically Glorious results.' },
            [20]={ name='Wyrd Ascendant: Stormcaller', desc='Work with your Skald. At this level the Stormcaller does not call the storm. They become it.' },
        },
        subclasses={
            { name='Ashstorm', desc='Fire and destruction. Everything burns and keeps burning.' },
            { name='Frostbound', desc='Ice and control. Slow, freeze, and cage the battlefield.' },
            { name='Thunderborn', desc='Lightning and speed. Chain strikes and overwhelm with aggression.' },
        },
    },
    Veilwalker = {
        primary='agility', secondary='wyrd', magic=true,
        tagline='You are not fully here. That has always been the point.',
        wyrdGift={ name='Between', desc='Once per session, step sideways out of reality for one round. You cannot be targeted, damaged, or detected, but you can observe everything.' },
        abilities={
            [1]={ name='Shadow Step', desc='Teleport to any shadow within 30 feet as a free action once per round.' },
            [3]={ name='Reality Blur', desc='Attackers have a 1-in-4 chance of missing you entirely.' },
            [5]={ name='Veil Strike', desc='Attack from within the Veil. Automatically beats Defence DC. Once per combat.' },
            [8]={ name='Mirror Self', desc='Create a perfect duplicate for 3 rounds. If it is hit, it vanishes.' },
            [12]={ name='World Splice', desc='Teleport yourself and up to 3 allies to any previously visited location. Once per session.' },
            [17]={ name='Fade', desc='Permanently semi-translucent. Ranged attacks miss on a 1-in-3. You always act first in combat.' },
            [20]={ name='Wyrd Ascendant: Veilwalker', desc='Work with your Skald. At this level the Veilwalker exists in multiple places simultaneously. Reality is a suggestion they have stopped listening to.' },
        },
        subclasses={
            { name='Nightshroud', desc='Pure stealth and assassination. Perfect concealment and devastating openers from hiding.' },
            { name='Mirrorblade', desc='Illusion and deception. Turn the battlefield into a hall of mirrors.' },
            { name='Riftstalker', desc='True dimensional travel. Push further into other realities, bringing pieces back.' },
        },
    },
    Bloodskalder = {
        primary='sway', secondary='wyrd', magic=true,
        tagline='The right words, spoken right, are the oldest weapon there is.',
        wyrdGift={ name='The Living Word', desc='Once per session, speak a sentence of absolute truth about a creature. That truth becomes mechanically real for the rest of the session.' },
        abilities={
            [1]={ name='Battle Cry', desc='All allies who hear you gain +2 to their next roll. Once per combat.' },
            [3]={ name='Wound Song', desc='Curse an enemy with -2 to all rolls for 3 rounds.' },
            [5]={ name='Saga of Strength', desc='One ally deals Max damage on their next hit regardless of Defence DC.' },
            [8]={ name='The Haunting', desc='An enemy makes Wyrd vs DC 16 or flees for 2 rounds.' },
            [12]={ name='Rewrite the Moment', desc='Once per session, change one roll result from the last round to True.' },
            [17]={ name='The Final Verse', desc="Once per session, compose an enemy's ending. Sway plus Wyrd vs their Wyrd. On success, they surrender, flee, or break." },
            [20]={ name='Wyrd Ascendant: Bloodskalder', desc="Work with your Skald. At this level the Bloodskalder's words reshape reality. What they say happened, happened." },
        },
        subclasses={
            { name='Warsinger', desc='Song as weapon. Your voice becomes a physical force on the battlefield.' },
            { name='Grimskalder', desc='Dark poetry. Target the mind and will rather than the body.' },
            { name='Lorebound', desc='Ancient words of power from dead skalds unlock forgotten magic.' },
        },
    },
    Runewarden = {
        primary='wit', secondary='wyrd', magic=true,
        tagline='Everything that exists can be written. Anything written can be rewritten.',
        wyrdGift={ name='Runesight', desc='You can see magical effects, enchantments, and wyrd connections as faintly glowing runes. You always know if something is magical, cursed, or fate-touched.' },
        abilities={
            [1]={ name='Inscribe', desc='Carve a rune: Ward (+2 Defence DC to bearer), Strike (+2 to attacks), or Seal (locks or unlocks mechanisms).' },
            [3]={ name='Runic Shield', desc='Completely absorb the next hit directed at any ally within sight.' },
            [5]={ name='Bind', desc='An enemy cannot move for 3 rounds unless they beat Wyrd vs DC 15.' },
            [8]={ name='Runic Empowerment', desc='Spend 1 hour inscribing a weapon. Permanently deals +1d4 extra damage.' },
            [12]={ name='Ancient Word', desc='Shatter (destroy any non-living object), Silence (no magic in 30ft for 3 rounds), or Awaken (a written word becomes physical force).' },
            [17]={ name='World Rune', desc='A rune affects an entire location until removed. Fortress, Drain, or Sanctuary.' },
            [20]={ name='Wyrd Ascendant: Runewarden', desc='Work with your Skald. At this level the Runewarden can inscribe permanent changes into the fabric of reality.' },
        },
        subclasses={
            { name='Siegewright', desc='Runic constructs and war machines. Build inscribed weapons and structures.' },
            { name='Soulscribe', desc='Runes inscribed onto living flesh. Carve permanent bonuses into willing recipients.' },
            { name='Voidcarver', desc="Dark runes that unmake and destroy. Use the void's own language against it." },
        },
    },
    Thornbound = {
        primary='grit', secondary='sway', magic=false,
        tagline='You swore something once. You meant it. That is the whole of you.',
        wyrdGift={ name='The Oath', desc='Declare what you protect at character creation. When it is threatened, all your rolls gain +3 and you cannot be reduced below 1 HP until the threat is resolved.' },
        abilities={
            [1]={ name='Shield of Purpose', desc='Once per combat, take a hit meant for an adjacent ally. Damage is reduced by your Grit score.' },
            [3]={ name='Judgement', desc='Declare an enemy your Quarry. +2 to your rolls against them, -1 to theirs.' },
            [5]={ name='Sacred Ground', desc='Plant yourself. You cannot be moved or knocked prone unless you choose to move.' },
            [8]={ name='Oath Surge', desc='When protecting your oath, once per combat deal Max damage regardless of Defence DC.' },
            [12]={ name='Unbreakable Vow', desc='Your oath manifests as golden light. Enemies must beat Wyrd vs DC 17 to act against what you protect.' },
            [17]={ name="Martyr's Will", desc='Once per session, reduce yourself to 1 HP willingly. All allies heal Wound penalties and gain +3 to all rolls for 3 rounds.' },
            [20]={ name='Wyrd Ascendant: Thornbound', desc="Work with your Skald. At this level the Thornbound's oath becomes a physical force. The world itself enforces it." },
        },
        subclasses={
            { name='Oathkeeper', desc='Pure protection. An indestructible wall between harm and those you guard.' },
            { name='Wrathbound', desc='The oath was broken. Now you hunt, driven by grief and fury.' },
            { name='Lightforged', desc='Divine protection through sacred oath. Spiritual power and healing.' },
        },
    },
    Greymantled = {
        primary='wit', secondary='agility', magic=false,
        tagline='You have already been here. You have already done this. Trust the path.',
        wyrdGift={ name='Known Paths', desc='Once per session, declare you have been here before, anywhere, however impossible. The Skald must give you one genuinely useful piece of information no one else would know.' },
        abilities={
            [1]={ name='Trackless', desc='You leave no trace. Tracks, scent, sound, nothing. Enemies cannot follow your trail.' },
            [3]={ name='Read the Room', desc='Spend one minute observing a location or person. The Skald answers three yes or no questions truthfully.' },
            [5]={ name='Ghost Arrow', desc='Ranged attacks ignore cover and obstacles.' },
            [8]={ name='Vanish', desc='Disappear in plain sight once per combat. Cannot be targeted until you attack.' },
            [12]={ name='The Long Watch', desc='Once per session, declare a fact about any named NPC that the Skald must make true.' },
            [17]={ name='Grey Verdict', desc='Once per session, reveal you planned for this moment. Name one item, ally, or piece of information already in place. It exists.' },
            [20]={ name='Wyrd Ascendant: Greymantled', desc='Work with your Skald. At this level the Greymantled has been everywhere and knows everything.' },
        },
        subclasses={
            { name='Irontracker', desc='Relentless hunter. No quarry has ever escaped you permanently.' },
            { name='Shadowagent', desc='Master of identity and deception. Become someone else entirely.' },
            { name='Stormbow', desc='Impossible ranged shots from impossible distances.' },
        },
    },
    Volva = {
        primary='wyrd', secondary='wit', magic=true,
        tagline='You have seen how it ends. You are deciding whether to let it.',
        wyrdGift={ name='The Sight', desc='At the start of each session, the Skald gives you one true prophecy about something that will happen. It is always accurate. How you use it is up to you.' },
        abilities={
            [1]={ name='Fate Read', desc='Touch a creature or object. Learn one thing about its past and one about its immediate future.' },
            [3]={ name='Curse of Misfortune', desc="Once per round for 3 rounds, an enemy's highest roll result becomes their lowest." },
            [5]={ name='Sever', desc='One enemy loses access to one class ability for the rest of combat.' },
            [8]={ name='Reweave', desc='Change one roll result already made this session to any number you choose. Once per session.' },
            [12]={ name='Prophecy', desc='Declare a prophecy about the current scene. It will come true before the scene ends.' },
            [17]={ name='Doom', desc='Place a specific condition of death on a named enemy. They are immune to all other forms of death until that condition is met.' },
            [20]={ name='Wyrd Ascendant: Volva', desc='Work with your Skald. At this level the Volva does not predict the future. They write it.' },
        },
        subclasses={
            { name='Wyrdweaver', desc='Pure fate manipulation. Control and rewrite probability.' },
            { name='Cursecaller', desc='Dark hexes and dooms that shatter lives and compound misfortune.' },
            { name='Seer Eternal', desc='Prophecy extending further and further into what will be.' },
        },
    },
}

-- ordered list for menus (matches the character sheet dropdown order)
Wyrd.classOrder = { 'Ironborn', 'Skeinblade', 'Ashen', 'Stormcaller', 'Veilwalker',
                    'Bloodskalder', 'Runewarden', 'Thornbound', 'Greymantled', 'Volva' }

return Wyrd.classes
