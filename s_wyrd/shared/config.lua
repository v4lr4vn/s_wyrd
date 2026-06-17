--[[ s_wyrd — Ash & Iron server config. Tune spawns and the Displaced economy
     here. Coordinates are plain {x,y,z,h} so they load anywhere. ]]

Wyrd = Wyrd or {}

Wyrd.config = {
    displaced = {
        -- Old Coin granted at creation (s_core 'coin' account). Not spendable
        -- in the modern economy — flavour / Displaced-only trade later.
        startingCoin = 120,
        -- Displaced arrive through a tear, not in the city. Set this to your
        -- Season 1 wound site / root-road exit. Default: out in the desert.
        spawn = { x = 2490.0, y = 4948.0, z = 45.5, h = 120.0 },
        -- Displaced carry nothing modern: no ID, no phone. When the inventory
        -- grants starting items, it must skip them for Displaced (this flag).
        noModernItems = true,
    },
    modern = {
        -- nil = use the s_core default spawn (the city). Set {x,y,z,h} to override.
        spawn = nil,
    },
}

return Wyrd.config
