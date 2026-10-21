data:extend {{
    type = "technology",
    name = "maraxsis-water-treatment",
    icon = "__maraxsis__/graphics/technology/water-treatment.png",
    icon_size = 256,
    effects = {
        {
            type = "unlock-recipe",
            recipe = "maraxsis-advanced-electrolysis"
        },
        {
            type = "unlock-recipe",
            recipe = "maraxsis-electrode",
        },
    },
    prerequisites = {"maraxsis-nickel-processing"},
    unit = {
        count = 5000,
        ingredients = {
            {"automation-science-pack",      1},
            {"logistic-science-pack",        1},
            {"military-science-pack",        1},
            {"chemical-science-pack",        1},
            {"space-science-pack",           1},
            {"production-science-pack",      1},
            {"utility-science-pack",         1},
            {"hydraulic-science-pack",       1},
        },
        time = 60,
    },
    order = "ei[water-treatment]",
}}

data:extend {{
    type = "item",
    name = "maraxsis-electrode",
    icon = "__maraxsis__/graphics/icons/electrode.png",
    icon_size = 64,
    stack_size = 10,
}}

data:extend {{
    type = "item",
    name = "maraxsis-spent-electrode",
    icon = "__maraxsis__/graphics/icons/spent-electrode.png",
    icon_size = 64,
    stack_size = 10,
}}

data:extend {{
    type = "recipe",
    name = "maraxsis-electrode",
    energy_required = data.raw.recipe["grenade"].energy_required,
    categories = {"electromagnetics", mods.Krastorio2 and "kr-electrolysis" or nil},
    enabled = false,
    results = {
        {type = "item", name = "maraxsis-electrode", amount = 1},
    },
    ingredients = {
        {type = "item", name = "nickel-plate", amount = 8, quality_change = 1},
        {type = "item", name = "stainless-steel", amount = 4},
    },
    auto_recycle = false,
    allow_productivity = false,
}}

data:extend {{
    type = "recipe",
    name = "maraxsis-advanced-electrolysis",
    enabled = false,
    energy_required = 2.5,
    ingredients = {
        {type = "item", name = "maraxsis-electrode", amount = 1},
        {type = "fluid", name = "maraxsis-brackish-water", amount = 300},
    },
    results = {
        {type = "item",  name = "maraxsis-spent-electrode", amount = 1, quality_change = -1, ignored_by_productivity = 1, ignored_by_stats = 1},
        {type = "item",  name = "salt",     amount = 5, quality_change = 2},
        {type = "fluid", name = "oxygen",   amount = 100},
        {type = "fluid", name = "hydrogen", amount = 200},
    },
    auto_recycle = false,
    allow_productivity = true,
    main_product = "maraxsis-spent-electrode",
    categories = {"maraxsis-hydro-plant", "electromagnetics", mods.Krastorio2 and "kr-electrolysis" or nil},
    icons = {
        {
            icon = "__maraxsis__/graphics/icons/saline-electrolysis.png",
            icon_size = 64,
        },
        {
            icon = "__maraxsis__/graphics/icons/electrode.png",
            icon_size = 64,
            scale = 0.25,
            shift = {-8, 8},
            floating = true
        },
    },
}}