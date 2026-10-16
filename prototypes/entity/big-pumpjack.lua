--- A higher tier pumpjack. It mines at 150% speed and drains resource patches
--- at half rate. Like the big mining drill unlocked on Vulcanus, it can still
--- extract every ordinary pumpjack resource, so the reduced resource drain
--- applies everywhere. It is the only pumpjack able to extract core lava.
--- Its sole connection category is "ducts", so it refuses to connect to normal
--- pipes. Its graphics are copies of the vanilla pumpjack sprites and icon,
--- stored in the mod so that they can be edited independently.

local big_pumpjack = table.deepcopy(data.raw["mining-drill"]["pumpjack"])
big_pumpjack.name = "maraxsis-big-pumpjack"
big_pumpjack.minable = {mining_time = 0.5, result = "maraxsis-big-pumpjack"}
--- 150% mining speed and 50% resource drain.
big_pumpjack.mining_speed = 1.5
big_pumpjack.resource_drain_rate_percent = 50
big_pumpjack.max_health = 300
big_pumpjack.module_slots = 3
--- 300kW to run and 100kW to heat, with twice the vanilla pumpjack's pollution.
big_pumpjack.energy_usage = "300kW"
big_pumpjack.heating_energy = "100kW"
big_pumpjack.energy_source.emissions_per_minute.pollution = big_pumpjack.energy_source.emissions_per_minute.pollution * 2
--- In addition to every ordinary pumpjack resource, the big pumpjack can mine
--- core lava, which lives in its own resource category.
big_pumpjack.resource_categories = {"basic-fluid", "maraxsis-core-lava"}
--- Connects exclusively to the "ducts" connection category.
for _, connection in pairs(big_pumpjack.output_fluid_box.pipe_connections) do
    connection.connection_category = "ducts"
end

--- Use the mod's own copies of the vanilla pumpjack sprites and icon so that
--- they can be edited independently of the vanilla pumpjack. This covers the
--- base sprites, the "frozen patch" overlay added by Space Age, and the
--- remnants (corpse) sprite. Shadows are not copied and keep using the vanilla
--- sprites.
local copied_graphics = {
    ["__base__/graphics/entity/pumpjack/pumpjack"] = "__maraxsis__/graphics/entity/big-pumpjack/big-pumpjack",
    ["__base__/graphics/entity/pumpjack/remnants/pumpjack"] = "__maraxsis__/graphics/entity/big-pumpjack/remnants/big-pumpjack",
    ["__space-age__/graphics/entity/frozen/pumpjack/pumpjack"] = "__maraxsis__/graphics/entity/big-pumpjack/frozen/big-pumpjack",
}

local function replace_prefix(path, prefix, replacement)
    if path:sub(1, #prefix) == prefix then
        return replacement .. path:sub(#prefix + 1)
    end
    return path
end

local function use_copied_graphics(graphics)
    if type(graphics) ~= "table" then return end
    for key, value in pairs(graphics) do
        if type(value) == "table" then
            use_copied_graphics(value)
        elseif key == "filename" and type(value) == "string" then
            --- Shadow sprites are not forked, so they keep using the vanilla sprites.
            if not value:find("-shadow", 1, true) then
                for prefix, replacement in pairs(copied_graphics) do
                    value = replace_prefix(value, prefix, replacement)
                end
                graphics[key] = value
            end
        end
    end
end

big_pumpjack.icon = "__maraxsis__/graphics/icons/big-pumpjack.png"
use_copied_graphics(big_pumpjack.graphics_set)
use_copied_graphics(big_pumpjack.graphics_set_flipped)
use_copied_graphics(big_pumpjack.radius_visualisation_picture)

--- Fork the corpse as well, so that its sprite can also be edited without
--- affecting the vanilla pumpjack.
local big_pumpjack_remnants = table.deepcopy(data.raw.corpse["pumpjack-remnants"])
big_pumpjack_remnants.name = "maraxsis-big-pumpjack-remnants"
big_pumpjack_remnants.icon = "__maraxsis__/graphics/icons/big-pumpjack.png"
use_copied_graphics(big_pumpjack_remnants.animation)
data:extend {big_pumpjack_remnants}

big_pumpjack.corpse = "maraxsis-big-pumpjack-remnants"
data:extend {big_pumpjack}

--- Boilerplate item, reusing the copied pumpjack icon and the vanilla sounds.
local big_pumpjack_item = table.deepcopy(data.raw.item["pumpjack"])
big_pumpjack_item.name = "maraxsis-big-pumpjack"
big_pumpjack_item.icon = "__maraxsis__/graphics/icons/big-pumpjack.png"
big_pumpjack_item.place_result = "maraxsis-big-pumpjack"
big_pumpjack_item.order = "b[fluids]-c[maraxsis-big-pumpjack]"
big_pumpjack_item.stack_size = 10
data:extend {big_pumpjack_item}

--- Boilerplate recipe.
data:extend {{
    type = "recipe",
    name = "maraxsis-big-pumpjack",
    enabled = false,
    energy_required = 10,
    ingredients = {
        {type = "item", name = "pumpjack",        amount = 1},
        {type = "item", name = "tungsten-plate",  amount = 50},
        {type = "item", name = "processing-unit", amount = 20},
    },
    results = {
        {type = "item", name = "maraxsis-big-pumpjack", amount = 1},
    },
    auto_recycle = true,
    categories = {"maraxsis-hydro-plant"},
    surface_conditions = maraxsis.surface_conditions(),
}}

--- Boilerplate technology, unlocked after the hydraulic science pack.
data:extend {{
    type = "technology",
    name = "maraxsis-big-pumpjack",
    icon = "__maraxsis__/graphics/technology/big-pumpjack.png",
    icon_size = 256,
    effects = {
        {type = "unlock-recipe", recipe = "maraxsis-big-pumpjack"},
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
    order = "ex[maraxsis]-b[big-pumpjack]",
}}
