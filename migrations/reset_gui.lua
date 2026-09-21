local switch_surface_button_name = "maraxsis-switch-surface-button"
for _,player in pairs(game.players) do
    if  player.gui.top[switch_surface_button_name] then
        player.gui.top[switch_surface_button_name].destroy()
    end
    
end