local resource_autoplace = require "resource-autoplace"

--- Nickel processing. Nickel ore is dug out of the core lava cliffs, melted
--- into molten nickel, cast into nickel plates, and alloyed with molten iron
--- into stainless steel.
---
--- Core lava itself is defined here too, because it is the feedstock the whole
--- chain is built on. The recipes below draw its prototype icon into their own
--- composite icons, so it has to exist before they are created.
---
--- Every recipe mirrors its vanilla iron/copper counterpart field for field, so
--- they are all metallurgy (foundry) recipes that live in the vanilla
--- vulcanus-processes subgroup next to the recipes they were modelled on. They
--- are unlocked by a new Maraxsis technology instead of the vanilla foundry
--- technology.
---
--- The icons are taken from snouz's free graphics collection: each one names
--- the pack it came from, and CREDITS.md carries the licences.

--- Core lava is a fluid that is distinct from lava but behaves almost
--- identically. It is pumped from the subtrenches instead of being harvested
--- from the surface lava rivers.
local core_lava_fluid = table.deepcopy(data.raw.fluid["lava"])
core_lava_fluid.name = "core-lava"
--- Core lava is a darker, redder relative of lava. Both the icon and the pipe
--- colour have their green and blue channels shifted down by 15/255.
local darken = 75 / 255
core_lava_fluid.icons = {
    {icon = core_lava_fluid.icon, tint = {1, 1 - darken, 1 - darken, 1}},
}
core_lava_fluid.icon = nil
core_lava_fluid.base_color = {
    core_lava_fluid.base_color[1] ,
    math.max(core_lava_fluid.base_color[2] - darken,0),
    math.max(core_lava_fluid.base_color[3] - darken,0),
}
core_lava_fluid.order = core_lava_fluid.order .. "a"
data:extend {core_lava_fluid}

data:extend {{
    type = "autoplace-control",
    category = "resource",
    name = "core-lava",
    localised_name = {"", "[entity=core-lava] ", {"entity-name.core-lava"}},
    order = "e-1",
    richness = true,
}}

resource_autoplace.initialize_patch_set("core-lava", false)

--- Same spot distribution as crude oil, but tied to the "core-lava" autoplace
--- control so it can be enabled exclusively on the trench surface.
local core_lava_autoplace = resource_autoplace.resource_autoplace_settings {
    name = "core-lava",
    order = "c", -- Other resources are "b"; oil won't get placed if something else is already there.
    base_density = 8.2,
    base_spots_per_km2 = 60,
    random_probability = 1 / 48,
    random_spot_size_minimum = 4,
    random_spot_size_maximum = 8, -- don't randomize spot size
    additional_richness = 220000, -- this increases the total everywhere, so base_density needs to be decreased to compensate
    has_starting_area_placement = false,
    regular_rq_factor_multiplier = 1,
}

core_lava_autoplace.control = "core-lava"
--- The control has to be enabled explicitly on a surface for the resource to
--- generate there.
core_lava_autoplace.default_enabled = false
--- Restrict generation to the subtrenches of the trench surface.
--- The mask is binary, so it removes veins that fall outside the subtrenches
--- without diluting the vein density inside them. The vanilla crude-oil
--- frequency therefore already gives oil-like patch density in the subtrenches
--- after masking; no frequency compensation is needed.
--- 
--core_lava_autoplace.probability_expression = "(" .. core_lava_autoplace.probability_expression .. ") * maraxsis_subtrench"

--- Core lava lives in its own resource category so that only the big pumpjack,
--- which opts into this category, is able to extract it.
data:extend {{
    type = "resource-category",
    name = "maraxsis-core-lava",
}}

local core_lava_resource = table.deepcopy(data.raw.resource["crude-oil"])
core_lava_resource.name = "core-lava"
core_lava_resource.category = "maraxsis-core-lava"
core_lava_resource.minable.results = {
    {type = "fluid", name = "core-lava", amount = 10},
}
core_lava_resource.autoplace = core_lava_autoplace

--- The mod ships its own copies of the crude-oil sprites, recoloured from black
--- to glowing orange by graphics/recolor-crude-oil-to-lava.sh. The sprite
--- tables are deep copied from vanilla, so they already carry their resolved
--- sizes, shifts and frame counts; only the filenames have to move to the mod's
--- copies. The vanilla sprite path is also a prefix of the bubbling animation's
--- path, so one entry covers both.
local copied_graphics = {
    ["__base__/graphics/entity/crude-oil/crude-oil"] = "__maraxsis__/graphics/entity/core-lava/core-lava",
    ["__base__/graphics/entity/crude-oil/oil-smoke-inner"] = "__maraxsis__/graphics/entity/core-lava/core-lava-smoke-inner",
    ["__base__/graphics/entity/crude-oil/oil-smoke-outer"] = "__maraxsis__/graphics/entity/core-lava/core-lava-smoke-outer",
}

local function use_copied_graphics(graphics)
    if type(graphics) ~= "table" then return end
    for key, value in pairs(graphics) do
        if type(value) == "table" then
            use_copied_graphics(value)
        elseif key == "filename" and type(value) == "string" then
            for prefix, replacement in pairs(copied_graphics) do
                if string.starts_with(value, prefix) then
                    value = replacement .. value:sub(#prefix + 1)
                end
            end
            graphics[key] = value
        end
    end
end

core_lava_resource.icon = "__maraxsis__/graphics/icons/core-lava-resource.png"
use_copied_graphics(core_lava_resource.stages)
use_copied_graphics(core_lava_resource.stateless_visualisation)

--- Orange on the map, to match the recoloured sprites.
core_lava_resource.map_color = {1, 0.5, 0}
data:extend {core_lava_resource}

--- Molten nickel mirrors molten iron, but is smelted from core lava rather than
--- the surface lava rivers. Its colours are nickel's pale green rather than
--- molten iron's blue.
local molten_nickel = table.deepcopy(data.raw.fluid["molten-iron"])
molten_nickel.name = "molten-nickel"
--- A puddle of molten nickel, from Periodic Madness, tinted to the pale green
--- the fluid is drawn in.
molten_nickel.icon = "__maraxsis__/graphics/icons/molten-nickel.png"
molten_nickel.order = "b[new-fluid]-b[vulcanus]-c[molten-nickel]"
molten_nickel.base_color = {0.10, 0.30, 0.20}
molten_nickel.flow_color = {0.50, 0.90, 0.70}
data:extend {molten_nickel}

--- Mirrors molten-iron-from-lava, but consumes core lava, which only the big
--- pumpjack is able to extract.
data:extend {{
    type = "recipe",
    name = "molten-nickel-from-core-lava",
    --- A drop of Periodic Madness' molten nickel, tinted to match the fluid:
    --- lava tapped for the same metal the ore melting recipe produces.
    --icon = "__maraxsis__/graphics/icons/molten-nickel-from-core-lava.png",
    icons = PlanetsLib.melting_icon("molten-nickel","core-lava","stone"),
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
--- Chunks of nickel ore, from Periodic Madness.
data:extend {{
    type = "item",
    name = "nickel-ore",
    icon = "__maraxsis__/graphics/icons/nickel-ore.png",
    subgroup = "raw-resource",
    order = "h[nickel-ore]",
    stack_size = 50,
}}

--- Mirrors iron-ore-melting and copper-ore-melting.
data:extend {{
    type = "recipe",
    name = "nickel-ore-melting",
    --- Periodic Madness' crucible, the vessel the ore is melted in.
    icon = "__maraxsis__/graphics/icons/nickel-ore-melting.png",
    icons = PlanetsLib.melting_icon("molten-nickel","nickel-ore"),
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

--- A silvery plate, from the Artisanal Reskins nickel plate.
data:extend {{
    type = "item",
    name = "nickel-plate",
    icon = "__maraxsis__/graphics/icons/nickel-plate.png",
    subgroup = "raw-material",
    order = "a[smelting]-d[nickel-plate]",
    stack_size = 100,
}}

--- Mirrors casting-iron and casting-copper.
data:extend {{
    type = "recipe",
    name = "casting-nickel",
    --- Periodic Madness' casting mould, molten metal poured into a plate.
    --icon = "__maraxsis__/graphics/icons/casting-nickel.png",
    icons = PlanetsLib.dual_icon("nickel-plate","molten-nickel"),
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

--- Stainless steel is an alloy of iron and nickel. Its plate is the Artisanal
--- Reskins invar alloy, a silvery plate that reads as an alloy rather than as
--- plain steel.
data:extend {{
    type = "item",
    name = "stainless-steel",
    icon = "__maraxsis__/graphics/icons/stainless-steel.png",
    subgroup = "raw-material",
    order = "a[smelting]-e[stainless-steel]",
    stack_size = 100,
}}

--- Mirrors casting-steel, but alloyed from molten iron and molten nickel
--- instead of molten iron alone.
data:extend {{
    type = "recipe",
    name = "stainless-steel",
    --- Periodic Madness' alloying icon: molten metal cast into plates and
    --- shapes, the way vanilla draws casting-steel.
    icon = "__maraxsis__/graphics/icons/stainless-steel.png",
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
--- Periodic Madness' advanced nickel processing icon: nickel ore next to the
--- molten metal it becomes.
data:extend {{
    type = "technology",
    name = "maraxsis-nickel-processing",
    icon = "__maraxsis__/graphics/technology/maraxsis-nickel-processing.png",
    icon_size = 256,
    effects = {
        {type = "unlock-recipe", recipe = "molten-nickel-from-core-lava"},
        {type = "unlock-recipe", recipe = "nickel-ore-melting"},
        {type = "unlock-recipe", recipe = "casting-nickel"},
        {type = "unlock-recipe", recipe = "stainless-steel"},
    },
    prerequisites = {"hydraulic-science-pack", "maraxsis-depth-charges"},
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
