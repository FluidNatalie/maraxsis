local Public = {}
function Public.is_in_shallow_trench(surface,position)
    local elevation = surface.calculate_tile_properties({"maraxsis_primary_trench_elevation"},{position})["maraxsis_primary_trench_elevation"][1]
    
    --game.print(elevation)
            if elevation < 0.1 then
                return true
            else
                return false
            end

end

function Public.generate_light(chunk_data,surface,position)
    if chunk_data.light then chunk_data.light.destroy() end
    chunk_data.light = rendering.draw_light{
        sprite = "utility.light_medium",
        surface = surface,
        target = {type = "position",position=position},
        scale = 40,
        intensity = 0.005,
    }

end

return Public 

