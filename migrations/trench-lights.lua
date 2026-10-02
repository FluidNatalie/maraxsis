local trench_lights = require("lib.trench-lights")

local is_in_shallow_trench = trench_lights.is_in_shallow_trench

local generate_light = trench_lights.generate_light

if game.planets["maraxsis-trench"] then
    if game.planets["maraxsis-trench"].surface then
        local surface = game.planets["maraxsis-trench"].surface
        for chunk in surface.get_chunks() do
            storage.chunks = storage.chunks or {}
            --if surface.name ~= "maraxsis-trench" then return end
            storage.chunks[surface.name] = storage.chunks[surface.name] or {}
            local x = chunk.x
            local y = chunk.y
            storage.chunks[surface.name][x] = storage.chunks[surface.name][x] or {}
            storage.chunks[surface.name][x][y] = storage.chunks[surface.name][x][y] or {}

            local chunk_data = storage.chunks[surface.name][x][y]
            local position = {x=32*x-16,y=32*y+16}
            local is_in_shallow_trench = is_in_shallow_trench(surface,position)
            chunk_data.is_in_shallow_trench = is_in_shallow_trench
            if not is_in_shallow_trench then goto continue end
            generate_light(chunk_data,surface,position)
            ::continue::
        end
    end
end