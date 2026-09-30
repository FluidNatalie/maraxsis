local trench_lights = require("lib.trench-lights")

maraxsis.is_in_shallow_trench = trench_lights.is_in_shallow_trench

local generate_light = trench_lights.generate_light

maraxsis.on_event(defines.events.on_chunk_generated, function(event)
    storage.chunks = storage.chunks or {}
    if event.surface.name ~= "maraxsis-trench" then return end
    storage.chunks[event.surface.name] = storage.chunks[event.surface.name] or {}
    local x = event.position.x
    local y = event.position.y
    storage.chunks[event.surface.name][x] = storage.chunks[event.surface.name][x] or {}
    storage.chunks[event.surface.name][x][y] = storage.chunks[event.surface.name][x][y] or {}

    local chunk_data = storage.chunks[event.surface.name][x][y]
    local position = {x=32*x-16,y=32*y+16}
    local is_in_shallow_trench = maraxsis.is_in_shallow_trench(event.surface,position)
    chunk_data.is_in_shallow_trench = is_in_shallow_trench
    if not is_in_shallow_trench then return end
    generate_light(chunk_data,event.surface,position)
    
    
    --game.print("chunk generated at" .. serpent.block(event.position))



end)