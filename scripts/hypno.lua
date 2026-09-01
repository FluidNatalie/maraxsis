local hypno_effects = {
    switch_force = function(entity, on)
        storage.hypno_original_forces = storage.hypno_original_forces or {}
        if on then
            storage.hypno_original_forces[entity.unit_number] = entity.force_index
            entity.force = "enemy"
        else
            entity.force = storage.hypno_original_forces[entity.unit_number]
            storage.hypno_original_forces[entity.unit_number] = nil
        end
    end,
    rotate = function(entity, on)
        storage.hypno_rotated_entities = storage.hypno_rotated_entities or {}

        if storage.hypno_rotated_entities[entity.unit_number] then
            if on then return end
            entity.direction = storage.hypno_rotated_entities[entity.unit_number]
            storage.hypno_rotated_entities[entity.unit_number] = nil
        else
            if not on then return end
            local original_direction = entity.direction
            if not entity.flip {horizontal = true} then
                if not entity.rotate {reverse = false} then
                    return
                end
            end
            storage.hypno_rotated_entities[entity.unit_number] = original_direction
        end
    end,
    rotate_west = function(entity, on)
        storage.hypno_rotated_entities = storage.hypno_rotated_entities or {}

        if storage.hypno_rotated_entities[entity.unit_number] then
            if on then return end
            entity.direction = storage.hypno_rotated_entities[entity.unit_number]
            storage.hypno_rotated_entities[entity.unit_number] = nil
        else
            if not on then return end
            entity.direction = defines.direction.west
            storage.hypno_rotated_entities[entity.unit_number] = entity.direction
        end
    end,
    random_quality_bonus = function(entity, on)

    end,
    extra_arms = function(entity, on)
        storage.hypno_has_extra_arms = storage.hypno_has_extra_arms or {}
        storage.hypno_is_an_extra_arm = storage.hypno_is_an_extra_arm or {}

        if storage.hypno_is_an_extra_arm[entity.unit_number] then return end

        if on then
            if storage.hypno_has_extra_arms[entity.unit_number] then return end
            local extra_arm = surface.create_entity {
                name = entity.name,
                position = entity.position,
                force = entity.force_index,
                mirror = entity.mirroring,
                quality = entity.quality,
                direction = entity.direction,
                create_build_effect_smoke = false,
                raise_built = false,
                move_stuck_players = false,
            }
            extra_arm.minable_flag = false
            extra_arm.operable = false
            extra_arm.rotatable = false
            extra_arm.destructible = false
            extra_arm.rotate {}
            storage.hypno_has_extra_arms[entity.unit_number] = extra_arm
            storage.hypno_is_an_extra_arm[extra_arm.unit_number] = extra_arm
        else
            if not storage.hypno_has_extra_arms[entity.unit_number] then return end
            local extra_arm = storage.hypno_has_extra_arms[entity.unit_number]
            storage.hypno_has_extra_arms[entity.unit_number] = nil
            if not extra_arm.valid then return end
            storage.hypno_is_an_extra_arm[extra_arm.unit_number] = nil
            extra_arm.destroy()
        end
    end,
    explode = function(entity, on)
        entity.surface.create_entity {
            name = "atomic-rocket",
            position = entity.position,
            target = entity,
            speed = 1,
            max_range = 0.1,
        }
    end,
    cant_breathe = function(entity, on)
        -- handled in pressure-dome.lua and drowning.lua
    end,
}

local EFFECTABLE_TYPES = {
    ["assembling-machine"] = hypno_effects.random_quality_bonus,
    ["furnace"] = hypno_effects.random_quality_bonus,
    ["rocket-silo"] = hypno_effects.random_quality_bonus,
    ["transport-belt"] = hypno_effects.rotate_west,
    ["inserter"] = hypno_effects.extra_arms,
    ["splitter"] = hypno_effects.rotate,
    ["pump"] = hypno_effects.rotate,
    ["ammo-turret"] = hypno_effects.switch_force,
    ["electric-turret"] = hypno_effects.switch_force,
    ["fluid-turret"] = hypno_effects.switch_force,
    ["artillery-turret"] = hypno_effects.switch_force,
    ["turret"] = hypno_effects.switch_force,
}

local EFFECTABLE_NAMES = {
    ["maraxsis-regulator"] = hypno_effects.cant_breathe,
    ["kr-fusion-reactor"] = hypno_effects.explode,
    ["nuclear-reactor"] = hypno_effects.explode,
    ["fusion-reactor"] = hypno_effects.explode,
}

maraxsis.on_event(maraxsis.events.on_init(), function()
    storage.hypno_stickers = {}
end)

local function register_hypno_sticker(sticker, target)
    local registration_number = script.register_on_object_destroyed(sticker)
    storage.hypno_stickers[registration_number] = target
end

maraxsis.on_event(defines.events.on_object_destroyed, function(event)
    local target = storage.hypno_stickers[event.registration_number]
    if not target or not target.valid then return end

    if target.type == "character" then
        target.force.script_trigger_research("maraxsis-ooozma-confinement")
    end
    storage.hypno_stickers[event.registration_number] = nil
end)

local function apply_hypno_max_duration(player)
    local c = player.character
    if not c or not c.valid then return end
    local resistance = maraxsis.get_hypno_resistance(player)
    local max_duration = resistance * maraxsis_constants.ESTROGEN_DURATION
    for _, sticker in pairs(c.stickers or {}) do
        if sticker.name == "maraxsis-hypno-sticker" or sticker.name == "maraxsis-hypno-sticker-behind" then
            register_hypno_sticker(sticker, c)
            if sticker.time_to_live > max_duration then
                sticker.time_to_live = max_duration
            end
        end
    end
end

maraxsis.on_event(defines.events.on_script_trigger_effect, function(event)
    local effect_id = event.effect_id
    if effect_id ~= "maraxsis-hypno-sticker-applied" then return end

    for _, player in pairs(game.players) do
        apply_hypno_max_duration(player)
    end
end)

maraxsis.on_event({
    defines.events.on_player_armor_inventory_changed,
    defines.events.on_equipment_inserted,
    defines.events.on_equipment_removed,
}, function()
    for _, player in pairs(game.players) do
        apply_hypno_max_duration(player)
    end
end)
