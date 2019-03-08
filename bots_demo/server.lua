addEvent("onBotAttach", true)
addEvent("onBotDettach", true)
addEvent("onBotCommand", true)
addEvent("onClientBotAttach", true)
addEvent("onClientBotDettach", true)
addEvent("onClientBotCommand", true)

local bots = {}

addEventHandler( "onBotAttach", root, function()
    if not getElementSyncer( source ) then
        if setElementSyncer( source, client ) then
            triggerClientEvent( client, "onClientBotAttach", source, bots[source] )
        end
    end
end)

addEventHandler( "onBotDettach", root, function(shared)
    bots[source] = shared
    if getElementSyncer( source ) == client then
        if setElementSyncer( source, true ) then
            local syncer = getElementSyncer( source )
            if syncer and syncer ~= client then
                triggerClientEvent( syncer, "onClientBotAttach", source, shared )
            end
        end
    end
end)

addEventHandler( "onBotCommand", root, function(...)
    if getElementSyncer( source ) == client then
        triggerClientEvent("onClientBotCommand", source, ...)
    end
end)

addCommandHandler("bot", function(player, command, skin)
    local position = player.position + player.matrix.forward * 3
    local ped = createPed( tonumber(skin), position.x, position.y, position.z)
end)