--- Atmosphere consumed per second by a regulator of the given quality, along
--- with the energy usage that makes a fluid energy source burn it at that rate.
function maraxsis.atmosphere_consumption(quality)
    local quality_level = quality.level + 1
    if quality.name == "legendary" then quality_level = 5 end
    local consumption_per_second
    if quality_level <= 5 then
        consumption_per_second = 6 - quality_level
    else
        consumption_per_second = 1 / (quality_level - 4)
    end
    return consumption_per_second, tostring(consumption_per_second * 100) .. "kW"
end

--- The visible regulator is only a roboport and the buildability proxy of its
--- dome. The atmosphere is actually burned by these hidden fluid boxes, one per
--- quality level.
--- @param name_prefix string Prototype name prefix, e.g. "maraxsis-regulator-fluidbox-".
--- @param regulator_name string The visible regulator entity these fluid boxes belong to.
--- @param consumption_multiplier number Multiple of the base atmosphere consumption rate.
local function make_regulator_fluidboxes(name_prefix, regulator_name, consumption_multiplier)
    for _, quality in pairs(data.raw.quality) do
        if quality.hidden and quality.name ~= "normal" then goto continue end

        local consumption_per_second = maraxsis.atmosphere_consumption(quality) * consumption_multiplier
        local energy_consumption = tostring(consumption_per_second * 100) .. "kW"

        if mods["assembler-pipe-passthrough"] then
            appmod.blacklist[name_prefix .. quality.name] = true
        end

        data:extend {{
            type = "assembling-machine",
            name = name_prefix .. quality.name,
            icon = "__maraxsis__/graphics/icons/regulator.png",
            icon_size = 64,
            flags = {"placeable-neutral", "player-creation", "not-on-map", "no-automated-item-removal", "no-automated-item-insertion"},
            minable = nil,
            localised_name = {"entity-name." .. regulator_name},
            hidden = true,
            quality_indicator_scale = 0,
            max_health = 99999,
            collision_mask = {layers = {}},
            factoriopedia_alternative = regulator_name,
            collision_box = {{-1.9, -1.9}, {1.9, 1.9}},
            selection_box = {{-2, -2}, {2, 2}},
            selectable_in_game = false,
            crafting_categories = {"maraxsis-regulator"},
            crafting_speed = 1,
            energy_usage = energy_consumption,
            icon_draw_specification = {scale = 0, scale_for_many = 0},
            fixed_recipe = "maraxsis-regulator",
            working_sound = {
                sound = {
                    filename = "__maraxsis__/sounds/regulator.ogg",
                    volume = 0.3
                },
                max_sounds_per_type = 3,
                audible_distance_modifier = 0.4,
                fade_in_ticks = 4,
                fade_out_ticks = 20
            },
            energy_source = {
                type = "fluid",
                burns_fluid = false,
                scale_fluid_usage = false,
                destroy_non_fuel_fluid = false,
                maximum_temperature = nil,
                fluid_box = {
                    production_type = "input",
                    pipe_picture = require("__space-age__.prototypes.entity.electromagnetic-plant-pictures").pipe_pictures,
                    pipe_picture_frozen = require("__space-age__.prototypes.entity.electromagnetic-plant-pictures").pipe_pictures_frozen,
                    pipe_covers = pipecoverspictures(),
                    volume = 100,
                    pipe_connections = {
                        {position = {0.5, -1.5},  direction = defines.direction.north, flow_direction = "input-output"},
                        {position = {-0.5, 1.5},  direction = defines.direction.south, flow_direction = "input-output"},
                        {position = {1.5, 0.5},   direction = defines.direction.east,  flow_direction = "input-output"},
                        {position = {-1.5, -0.5}, direction = defines.direction.west,  flow_direction = "input-output"},
                    },
                    filter = "maraxsis-atmosphere",
                    secondary_draw_orders = {north = -1},
                },
                smoke = {
                    {
                        name = "maraxsis-swimming-bubbles",
                        frequency = 100,
                        position = {-0.9, -2.7},
                        starting_vertical_speed = 0.03
                    }
                }
            },
            effect_receiver = {
                uses_module_effects = false,
                uses_beacon_effects = false,
                uses_surface_effects = false,
            },
            graphics_set = {
                animation = {
                    layers = {
                        {
                            filename = "__maraxsis__/graphics/entity/regulator/regulator.png",
                            priority = "high",
                            width = 1680 / 8,
                            height = 2320 / 8,
                            shift = {0, -0.5},
                            frame_count = 60,
                            line_length = 8,
                            animation_speed = 1.5,
                            scale = 0.5 * 4 / 3,
                            flags = {"no-scale"}
                        },
                        {
                            filename = "__maraxsis__/graphics/entity/regulator/sh.png",
                            priority = "high",
                            width = 400,
                            height = 350,
                            shift = util.by_pixel(0, -16),
                            frame_count = 1,
                            line_length = 1,
                            repeat_count = 60,
                            animation_speed = 1.5,
                            scale = 0.5 * 4 / 3,
                            draw_as_shadow = true,
                        }
                    }
                }
            }
        }}

        ::continue::
    end
end

make_regulator_fluidboxes("maraxsis-regulator-fluidbox-", "maraxsis-regulator", 1)
--- The big dome is twice the size, so its regulator burns twice the atmosphere.
make_regulator_fluidboxes("maraxsis-big-regulator-fluidbox-", "maraxsis-big-regulator", 2)
