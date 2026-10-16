--- Core lava cliffs drop nickel ore when they are destroyed.
---
--- Cliffs have no health, so the destroy-cliffs effect of the big cliff
--- explosives removes them without ever raising on_entity_died. Instead,
--- `prototypes/technology/depth-charges.lua` slips a script trigger into the
--- big cliff explosives right before the cliffs are destroyed, which lets this
--- script find the cliffs while they are still standing.

--- Matches the name in `prototypes/entity/cliffs.lua`.
local CORE_LAVA_CLIFF_NAME = "maraxsis-core-lava-cliff"

--- How much ore a single cliff leaves behind.
local NICKEL_ORE_PER_CLIFF = 20

--- Matches the destroy-cliffs radius of `maraxsis-big-cliff-explosives`.
local BIG_CLIFF_EXPLOSIVES_RADIUS = 450

maraxsis.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id ~= "maraxsis-core-lava-cliff-destroyed" then return end

    local position = event.target_position
    local surface = game.get_surface(event.surface_index)
    if not position or not surface then return end

    for _, cliff in pairs(surface.find_entities_filtered {
        name = CORE_LAVA_CLIFF_NAME,
        position = position,
        radius = BIG_CLIFF_EXPLOSIVES_RADIUS,
    }) do
        surface.create_entity {
            name = "item-on-ground",
            position = cliff.position,
            stack = {name = "nickel-ore", count = NICKEL_ORE_PER_CLIFF},
        }
    end
end)
