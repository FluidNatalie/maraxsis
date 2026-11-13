data:extend {{
    type = "technology",
    name = "maraxsis-project-seadragon",
    icon = "__maraxsis__/graphics/technology/project-seadragon.png",
    icon_size = 256,
    effects = {
        {
            type = "nothing",
            use_icon_overlay_constant = true,
            icon = "__maraxsis__/graphics/technology/project-seadragon.png",
            icon_size = 256,
            effect_description = {"modifier-description.maraxsis-project-seadragon"}
        },
        {
            type = "unlock-recipe",
            recipe = "maraxsis-rocket-part"
        },
        {
            type = "unlock-recipe",
            recipe = "maraxsis-super-sealant-substance"
        },
        {
            type = "unlock-recipe",
            recipe = "maraxsis-bio-oil"
        }
    },
    prerequisites = {"hydraulic-science-pack"},
    unit = {
        count = 500,
        ingredients = {
            {"hydraulic-science-pack", 1},
        },
        time = 30,
    },
    order = "ea[seadragon]",
}}

local maraxsis_rocket_part = table.deepcopy(data.raw["recipe"]["rocket-part"])
maraxsis_rocket_part.name = "maraxsis-rocket-part"
maraxsis_rocket_part.localised_name = maraxsis_rocket_part.localised_name or {"item-name.rocket-part"}
maraxsis_rocket_part.enabled = false
maraxsis_rocket_part.surface_conditions = maraxsis.shallow_surface_conditions()
maraxsis_rocket_part.auto_recycle = false
maraxsis_rocket_part.order = data.raw.item["rocket-part"].order .. "-a[maraxsis]"
data:extend {maraxsis_rocket_part}

data:extend {{
    type = "recipe",
    name = "maraxsis-super-sealant-substance",
    enabled = false,
    energy_required = 5,
    ingredients = {
        {type = "item",  name = "sulfur", amount = 3},
        {type = "fluid", name = "heavy-oil", amount = 200},
        {type = "fluid", name = "hydrogen", amount = 100},
    },
    results = {
        {type = "item", name = "maraxsis-super-sealant-substance", amount = 1},
    },
    categories = {"chemistry", "cryogenics"},
    allow_productivity = true,
    auto_recycle = false,
    sort_item_ingredients = false
}}

local super_sealant_substance_variants = {}
for i = 1, 3 do
    super_sealant_substance_variants[i] = {
        filename = "__maraxsis__/graphics/icons/super-sealant-substance-" .. i .. ".png",
        width = 64,
        height = 64,
        scale = 1 / 2,
        flags = {"icon"}
    }
end

data:extend {{
    type = "item",
    name = "maraxsis-super-sealant-substance",
    icon = "__maraxsis__/graphics/icons/super-sealant-substance-1.png",
    icon_size = 64,
    stack_size = data.raw.item["rocket-fuel"].stack_size,
    weight = data.raw.item["rocket-fuel"].weight,
    pictures = super_sealant_substance_variants,
}}

-- Adapted from Rubia & Alternative Rocket Sprite Extension.
local rocket_shift = 48
local rocket = util.table.deepcopy(data.raw["rocket-silo-rocket"]["rocket-silo-rocket"])
rocket.name = "maraxsis-rocket-silo-rocket"
rocket.localised_name = {"entity-name.rocket-silo-rocket"}
rocket.localised_description = {"entity-description.rocket-silo-rocket"}
rocket.hidden = true
rocket.hidden_in_factoriopedia = true
if settings.startup["maraxsis-fish-rocket"].value == true then
    rocket.rocket_sprite = {
        filename = "__maraxsis__/graphics/entity/rocket-silo/rocket.png",
        height = 290,
        width = 290,
        scale = 1.2,
        shift = {0, 6}
    }
    rocket.rocket_rise_offset = {0, -7}
    rocket.rocket_smoke_bottom1_animation.scale = 0.01
    rocket.rocket_smoke_bottom1_animation.hr_version = nil
    rocket.rocket_smoke_bottom2_animation.scale = 0.01
    rocket.rocket_smoke_bottom2_animation.hr_version = nil
    rocket.rocket_smoke_top1_animation.scale = 0.01
    rocket.rocket_smoke_top1_animation.hr_version = nil
    rocket.rocket_smoke_top2_animation.scale = 0.01
    rocket.rocket_smoke_top2_animation.hr_version = nil
    rocket.rocket_smoke_top3_animation.scale = 0.01
    rocket.rocket_smoke_top3_animation.hr_version = nil

else
    rocket.rocket_sprite =
    {
    layers =
      {
        util.sprite_load("__maraxsis__/graphics/entity/rocket-silo/maraxsis-new-rocket/rocket-static-pod",
      {
        dice_y = 4,
        shift = util.by_pixel( 0, 17.0+rocket_shift),
        scale = 0.5
      }),
      util.sprite_load("__maraxsis__/graphics/entity/rocket-silo/maraxsis-new-rocket/rocket-static-emission",
      {
        dice_y = 4,
        shift = util.by_pixel( 0, 17+rocket_shift),
        draw_as_glow = true,
        blend_mode = "additive",
        scale = 0.5
      })
    }
    }
    rocket.rocket_flame_animation = util.sprite_load("__maraxsis__/graphics/entity/rocket-silo/maraxsis-new-rocket/rocket-jet",
    {
      shift = util.by_pixel( 0, 17+rocket_shift),
      draw_as_glow = true,
      blend_mode = "additive",
      scale = 0.5,
      frame_count = 8,
      animation_speed = 0.5
    })
end

data:extend { rocket }

for surface in pairs(maraxsis_constants.MARAXSIS_SURFACES) do
    PlanetsLib.create_planet_entity_variant(
        surface,
        data.raw["rocket-silo"]["rocket-silo"],
        {
            name = "maraxsis-rocket-silo",
            localised_name = {"entity-name.rocket-silo"},
            localised_description = {"entity-description.rocket-silo"},
            rocket_entity = "maraxsis-rocket-silo-rocket",
            fixed_recipe = "maraxsis-rocket-part",
            disabled_when_recipe_not_researched = true,
            placeable_by = {{item = "rocket-silo", count = 1}},
            flags = {"placeable-player", "player-creation", "not-in-made-in"},
            hidden = true,
            hidden_in_factoriopedia = true,
            base_day_sprite =
                {
                  filename = "__maraxsis__/graphics/entity/rocket-silo/06-rocket-silo.png",
                  dice_y = 3,
                  width = 608,
                  height = 596,
                  shift = util.by_pixel(3, -1),
                  scale = 0.5
                },
            base_front_sprite =
                {
                  filename = "__maraxsis__/graphics/entity/rocket-silo/14-rocket-silo-front.png",
                  width = 580,
                  height = 262,
                  shift = util.by_pixel(-1, 78),
                  scale = 0.5
                },
        },
        "maraxsis-runtime-entity-replacement",
        "rocket-silo"
    )
    --separately (create_planet_entity_variant doesn't support all fields we edit)
    data.raw["rocket-silo"]["maraxsis-rocket-silo"].graphics_set = nil --these are the welding and engine animation on the new new silo
    data.raw["rocket-silo"]["maraxsis-rocket-silo"].working_sound.sound_accents = nil --these are the welding sounds

    -- https://github.com/notnotmelon/maraxsis/issues/417
    PlanetsLib.assign_rocket_part_recipe(surface, maraxsis_rocket_part.name)
end
