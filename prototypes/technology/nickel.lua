--- Nickel processing. Nickel ore is dug out of the core lava cliffs, melted
--- into molten nickel, cast into nickel plates, and alloyed with molten iron
--- into stainless steel.
---
--- Every recipe mirrors its vanilla iron/copper counterpart field for field, so
--- they are all metallurgy (foundry) recipes that live in the vanilla
--- vulcanus-processes subgroup next to the recipes they were modelled on. They
--- are unlocked by a new Maraxsis technology instead of the vanilla foundry
--- technology.
---
--- All graphics are vanilla placeholders.

--- Molten nickel mirrors molten iron, but is smelted from core lava rather than
--- the surface lava rivers. Its colours are nickel's pale green rather than
--- molten iron's blue.
local molten_nickel = table.deepcopy(data.raw.fluid["molten-iron"])
molten_nickel.name = "molten-nickel"
--- Placeholder: reuse the molten iron icon.
molten_nickel.icon = "__space-age__/graphics/icons/fluid/molten-iron.png"
molten_nickel.order = "b[new-fluid]-b[vulcanus]-c[molten-nickel]"
molten_nickel.base_color = {0.10, 0.30, 0.20}
molten_nickel.flow_color = {0.50, 0.90, 0.70}
data:extend {molten_nickel}

--- Mirrors molten-iron-from-lava, but consumes core lava, which only the big
--- pumpjack is able to extract.
data:extend {{
    type = "recipe",
    name = "molten-nickel-from-core-lava",
    --- Placeholder: reuse the molten iron icon.
    icon = "__space-age__/graphics/icons/fluid/molten-iron-from-lava.png",
    categories = {"metallurgy"},
    subgroup = "vulcanus-processes",
    order = "a[melting]-a[lava-c]",
    auto_recycle = false,
    enabled = false,
    ingredients = {
        {type = "fluid", name = "core-lava", amount = 500},
        {type = "item",  name = "calcite",   amount = 1},
    },
    energy_required = 16,
    results = {
        {type = "fluid", name = "molten-nickel", amount = 250},
        {type = "item",  name = "stone",         amount = 10},
    },
    allow_productivity = true,
}}

--- Nickel ore is blasted out of the core lava cliffs at the bottom of the
--- trench. Like the ores of the other planets it is melted down with calcite
--- before it can be used.
--- Placeholder icon: reuse the vanilla iron ore icon.
data:extend {{
    type = "item",
    name = "nickel-ore",
    icon = "__base__/graphics/icons/iron-ore.png",
    subgroup = "raw-resource",
    order = "h[nickel-ore]",
    stack_size = 50,
}}

--- Mirrors iron-ore-melting and copper-ore-melting.
data:extend {{
    type = "recipe",
    name = "nickel-ore-melting",
    --- Placeholder: reuse the iron ore melting icon.
    icon = "__space-age__/graphics/icons/iron-ore-melting.png",
    categories = {"metallurgy"},
    subgroup = "vulcanus-processes",
    order = "a[melting]-d[nickel-ore-melting]",
    auto_recycle = false,
    enabled = false,
    ingredients = {
        {type = "item", name = "nickel-ore", amount = 50},
        {type = "item", name = "calcite",    amount = 1},
    },
    energy_required = 32,
    results = {
        {type = "fluid", name = "molten-nickel", amount = 500},
    },
    hide_from_signal_gui = false,
    allow_productivity = true,
    main_product = "molten-nickel",
}}

--- Placeholder icon: the holmium plate is the closest thing vanilla has to a
--- silvery plate.
data:extend {{
    type = "item",
    name = "nickel-plate",
    icon = "__space-age__/graphics/icons/holmium-plate.png",
    subgroup = "raw-material",
    order = "a[smelting]-d[nickel-plate]",
    stack_size = 100,
}}

--- Mirrors casting-iron and casting-copper.
data:extend {{
    type = "recipe",
    name = "casting-nickel",
    --- Placeholder: reuse the casting iron icon.
    icon = "__space-age__/graphics/icons/casting-iron.png",
    categories = {"metallurgy"},
    subgroup = "vulcanus-processes",
    order = "b[casting]-d[casting-nickel]",
    enabled = false,
    ingredients = {
        {type = "fluid", name = "molten-nickel", amount = 20, fluidbox_multiplier = 10},
    },
    energy_required = 3.2,
    allow_decomposition = false,
    results = {{type = "item", name = "nickel-plate", amount = 2}},
    allow_productivity = true,
    auto_recycle = false,
}}

--- Stainless steel is an alloy of iron and nickel.
--- Placeholder icon: reuse the vanilla steel plate icon.
data:extend {{
    type = "item",
    name = "stainless-steel",
    icon = "__base__/graphics/icons/steel-plate.png",
    subgroup = "raw-material",
    order = "a[smelting]-e[stainless-steel]",
    stack_size = 100,
}}

--- Mirrors casting-steel, but alloyed from molten iron and molten nickel
--- instead of molten iron alone.
data:extend {{
    type = "recipe",
    name = "stainless-steel",
    --- Placeholder: reuse the casting steel icon.
    icon = "__space-age__/graphics/icons/casting-steel.png",
    categories = {"metallurgy"},
    subgroup = "vulcanus-processes",
    order = "b[casting]-e[casting-stainless-steel]",
    enabled = false,
    ingredients = {
        {type = "fluid", name = "molten-iron",   amount = 30, fluidbox_multiplier = 10},
        {type = "fluid", name = "molten-nickel", amount = 20, fluidbox_multiplier = 10},
    },
    energy_required = 3.2,
    allow_decomposition = false,
    results = {{type = "item", name = "stainless-steel", amount = 1}},
    allow_productivity = true,
    auto_recycle = false,
}}

--- Unlocked after the hydraulic science pack, like the rest of the trench
--- technology.
--- Placeholder icon: reuse the vanilla foundry technology icon.
data:extend {{
    type = "technology",
    name = "maraxsis-nickel-processing",
    icon = "__space-age__/graphics/technology/foundry.png",
    icon_size = 256,
    effects = {
        {type = "unlock-recipe", recipe = "molten-nickel-from-core-lava"},
        {type = "unlock-recipe", recipe = "nickel-ore-melting"},
        {type = "unlock-recipe", recipe = "casting-nickel"},
        {type = "unlock-recipe", recipe = "stainless-steel"},
    },
    prerequisites = {"hydraulic-science-pack"},
    unit = {
        count = 500,
        ingredients = {
            {"automation-science-pack", 1},
            {"logistic-science-pack",   1},
            {"chemical-science-pack",   1},
            {"production-science-pack", 1},
            {"utility-science-pack",    1},
            {"hydraulic-science-pack",  1},
        },
        time = 30,
    },
    order = "ex[maraxsis]-c[nickel-processing]",
}}
