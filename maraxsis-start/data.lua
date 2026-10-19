require "maraxsis-start.prototypes.a-breath-of-fresh-air"

data:extend {{
    type = "space-connection",
    name = "nauvis-maraxsis",
    from = "nauvis",
    to = "maraxsis",
    length = 20000,
    asteroid_spawn_definitions = table.deepcopy(data.raw["space-connection"]["nauvis-gleba"].asteroid_spawn_definitions),
}}

data:extend {{
    type = "recipe",
    name = "maraxsis-tungsten-ore-dissolution",
    categories = {"chemistry"},
    enabled = false,
    energy_required = 5,
    ingredients = {
        {type = "item",  name = "tungsten-carbide",      amount = 10},
        {type = "fluid", name = "maraxsis-saline-water", amount = 300},
    },
    results = {
        {type = "item", name = "tungsten-ore", amount = 5},
    },
    main_product = "tungsten-ore",
    allow_recycling = false,
    allow_decomposition = false,
    allow_productivity = false,
}}

data:extend {{
    type = "recipe",
    name = "maraxsis-carbon-fiber-from-jelly",
    categories = {"hand-crafting","organic"},
    enabled = false,
    energy_required = 10,
    ingredients = {
        {type = "item", name = "tungsten-carbide", amount = 1},
        {type = "item", name = "jelly",            amount = 10},
    },
    results = {
        {type = "item", name = "carbon-fiber", amount = 1},
    },
    main_product = "carbon-fiber",
    allow_recycling = false,
    allow_decomposition = false,
    allow_productivity = true,
    always_show_made_in = true,
    localised_name = {"item-name.carbon-fiber"},
    auto_recycle = false,
}}

-- Starting on Maraxsis changes what the foundry and lubricant technologies do
-- (lava casting and fish liquefaction). Use dedicated locale keys and override
-- their descriptions here, so the vanilla descriptions are not clobbered for
-- other planets and for players who do not use Any Planet Start.
data.raw["technology"]["foundry"].localised_description = {"technology-description.foundry-maraxsis-start"}
data.raw["technology"]["lubricant"].localised_description = {"technology-description.lubricant-maraxsis-start"}
