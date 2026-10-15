local resource_autoplace = require "resource-autoplace"

--- Core lava is a fluid that is distinct from lava but behaves almost
--- identically. It is pumped from the subtrenches instead of being harvested
--- from the surface lava rivers.
local core_lava_fluid = table.deepcopy(data.raw.fluid["lava"])
core_lava_fluid.name = "core-lava"
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

local core_lava_resource = table.deepcopy(data.raw.resource["crude-oil"])
core_lava_resource.name = "core-lava"
core_lava_resource.minable.results = {
    {type = "fluid", name = "core-lava", amount = 10},
}
core_lava_resource.autoplace = core_lava_autoplace
--- Orange on the map. All other graphics remain those of crude oil.
core_lava_resource.map_color = {1, 0.5, 0}
data:extend {core_lava_resource}
