# s_wyrd

A faithful, server-authoritative implementation of the WyrdBound tabletop RPG ruleset as
a FiveM resource, including character sheets, dice resolution, combat, and Death's Door.

## Function

s_wyrd is the lore and mechanics engine for Ash & Iron RP. `rules.lua` encodes the entire
WyrdBound ruleset (attributes, skills, DC scale, outcome tiers, weapons, armour, wound
tiers, magic tiers, conditions, and formulas) as a single source of truth that every other
file in the resource reads from. Nothing duplicates a rule. Everything calls into rules.lua.

The engine enforces the two-faction lore (Displaced vs Modern) at the data layer: Displaced
characters get a full Wyrd sheet with attributes, skills, and class abilities, gated behind
the server's whitelist system. Modern characters get a stripped-down public sheet with no
Wyrd mechanics, matching the server's lore that only those from Midgard carry the old magic.

## Key Features

- `dice.lua`: the full WyrdBound dice engine. Five-tier outcome resolution (Glorious,
  Success, Strained, Fail, Disaster), attack resolution with beat/meet/miss damage scaling,
  magic casting with WP cost deducted before the roll, and Death's Door resolution
- Server-authoritative RNG, seeded once on startup and warmed up with discarded rolls to
  avoid weak initial state, so no client can influence or predict outcomes
- Proximity roll broadcast: anyone within range sees a live feed line when a nearby
  player rolls, replicating the shared-table feeling of a TTRPG session in FiveM
- `sheet.lua`: full server-side character creation validation. Enforces the exact
  8/7/6/5/4/3 attribute spread, validates class selection against the registry, and
  enforces exactly two origin skills and two class skills with no duplicates
- Sequential point-buy character creation UI on the client using `lib.context` menus
- Combat module: Death's Door checks on a timer, three successes to stabilise, three
  failures to die, with an ally-assisted `/stabilise` command
- Full class data (`classes.lua`): ten classes, Wyrd gifts, abilities, and subclasses
  encoded faithfully from the WyrdBound rulebook
- `/sheet` command for viewing a full computed character sheet in a context menu

## Security Updates

- All character creation is validated server-side against the exact rules in `rules.lua`.
  No client-supplied attribute array, skill list, or class selection is trusted without
  full validation, closing off any possibility of an illegal or min-maxed build.
- Displaced character creation (the mechanically significant background) is gated behind
  the server's whitelist check, enforced server-side, with an explicit admin bypass for
  testing. Clients attempting to create a Displaced character without whitelist approval
  receive a clear rejection rather than a silent failure.
- Combat and Death's Door state is tracked entirely server-side. Clients display the
  result of a roll; they never compute or report it themselves.

## Dependencies

`s_core` (character identity, whitelist status, admin checks), `s_lib` (callbacks,
context menus, cron).
