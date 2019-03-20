function BOT_COMMANDS.idle( bot, time, cmd)
    botStop( bot )
end

function BOT_COMMANDS.move_to( bot, time, x, y )   
    local x0, y0, z0 = setBotRotationTo( bot, x, y, 0 )
    local dist = getDistanceBetweenPoints2D( x0,y0, x,y )    
    if dist < 0.8 then
        return
    end
    setPedControlState( bot.ped, "forwards", true )
    return true
end

function BOT_COMMANDS.move_to_node( bot, time, id )
    if not id then return end

    local x,y,z = get_path_node(id)
    local x0, y0, z0 = getElementPosition(bot.ped)
    local dist = getDistanceBetweenPoints2D(x0,y0,x,y)

    if dist < 0.8 then
        return
    end
    setElementRotation( bot.ped, 0, 0, getBotRotation(x0,y0,x,y), "default", true )
    setPedControlState( bot.ped, "forwards", true )
    return true
end
