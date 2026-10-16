local collision_mask_util = require "__core__/lualib/collision-mask-util"

local cliff = scaled_cliff {
    mod_name = "__maraxsis__",
    name = "cliff-maraxsis",
    map_color = {144, 119, 87},
    suffix = "maraxsis",
    subfolder = "maraxsis",
    scale = 1.0,
    has_lower_layer = true,
    sprite_size_multiplier = 2,
    factoriopedia_simulation = {
        hide_factoriopedia_gradient = true,
        init = "    game.simulation.camera_position = {0, 2.5}\n    for x = -8, 8, 1 do\n      for y = -3, 4 do\n        game.surfaces[1].set_tiles{{position = {x, y}, name = \"sand-3-underwater\"}}\n      end\n    end\n    for x = -8, 8, 4 do\n      game.surfaces[1].create_entity{name = \"cliff-maraxsis\", position = {x, 0}, cliff_orientation = \"west-to-east\"}\n    end\n  ",
        planet = "maraxsis"
    },
}
local function recursively_replace_cliff_shadows_to_vulcanus(cliff_orientations)
    if type(cliff_orientations) ~= "table" then return end

    if cliff_orientations.draw_as_shadow then
        local filename = cliff_orientations.filename
        if filename:match("%-shadow.png") then
            cliff_orientations.filename = filename:gsub("__maraxsis__/graphics/terrain/cliffs/maraxsis/cliff%-maraxsis", "__space-age__/graphics/terrain/cliffs/vulcanus/cliff-vulcanus")
        end
        return
    end

    for k, v in pairs(cliff_orientations) do
        if type(v) == "table" then
            recursively_replace_cliff_shadows_to_vulcanus(v)
        end
    end
end
recursively_replace_cliff_shadows_to_vulcanus(cliff.orientations)
cliff.map_color = maraxsis.color_combine(cliff.map_color, data.raw.tile["deepwater"].map_color, 0.3)
data:extend {cliff}
collision_mask_util.get_mask(cliff)[maraxsis_underwater_collision_mask] = nil

local collisionless_cliff = table.deepcopy(cliff)
collisionless_cliff.name = cliff.name .. "-collisionless"
collisionless_cliff.collision_mask = {layers = {}}
collisionless_cliff.created_effect = {
    type = "direct",
    action_delivery = {
        type = "instant",
        source_effects = {
            {
                type = "script",
                effect_id = "maraxsis-cliff-created",
            },
        }
    }
}
collisionless_cliff.hidden = true
collisionless_cliff.factoriopedia_alternative = "cliff-maraxsis"
data:extend {collisionless_cliff}

local huge_rock = data.raw["simple-entity"]["huge-rock"]

--- The bounding box of the huge rock the cliff is made out of.
local CORE_LAVA_CLIFF_BOUNDING_BOX = {{-1.5, -1.1}, {1.5, 1.1}, 0}

--- A huge rock perched on top of a core lava well. Cliffs only understand the
--- 20 directions the map generator can point them in, so instead of trying to
--- limit this cliff to a single direction, every direction is given the same
--- rock sprite and the same bounding box. The result is a cliff that always
--- looks and behaves like a rock, whichever way it is placed.
---
--- There is no autoplace: the map generator spreads cliffs over a whole core
--- lava patch instead of putting them on the lava itself, so
--- `scripts/map-gen/maraxsis-trench.lua` places them by script instead, as the
--- trench generates.
local core_lava_cliff = maraxsis.merge(data.raw.cliff["cliff"], {
    name = "maraxsis-core-lava-cliff",
    --- Placeholder graphics: the huge rocks of Nauvis.
    icon = huge_rock.icon,
    order = "b[decorative]-l[rock]-c[core-lava-cliff]",
    map_color = huge_rock.map_color,
    collision_box = CORE_LAVA_CLIFF_BOUNDING_BOX,
    selection_box = CORE_LAVA_CLIFF_BOUNDING_BOX,
    --- These rocks are far too heavy for a handheld cliff explosive.
    cliff_explosive = "maraxsis-big-cliff-explosives",
    factoriopedia_simulation = "nil",
})

core_lava_cliff.orientations = {}
for orientation in pairs(data.raw.cliff["cliff"].orientations) do
    core_lava_cliff.orientations[orientation] = {
        collision_bounding_box = CORE_LAVA_CLIFF_BOUNDING_BOX,
        pictures = table.deepcopy(huge_rock.pictures),
    }
end

data:extend {core_lava_cliff}
