addEvent("onBotAttach", true)
addEvent("onBotDettach", true)
addEvent("onBotCommand", true)
addEvent("onClientBotAttach", true)
addEvent("onClientBotDettach", true)
addEvent("onClientBotCommand", true)

local bots = {}

addEventHandler( "onBotAttach", root, function()
    if not bots[source] then bots[source] = {} end
    local bot = bots[source]
    if not bot.syncer then
        if setElementSyncer( source, client ) then
            bot.syncer = client
            triggerClientEvent( client, "onClientBotAttach", source, bot.shared )
        end
    end
end)

addEventHandler( "onBotDettach", root, function(shared)
    local bot = bots[source]
    if bot and bot.syncer == client then
        bot.shared = shared
        local syncer = setElementSyncer( source, true ) and getElementSyncer( source )
        if syncer then
            bot.syncer = syncer
            triggerClientEvent( syncer, "onClientBotAttach", source, bot.shared )
        else
            bot.syncer = nil
        end
    end
end)

addEventHandler( "onBotCommand", root, function(...)
    local bot = bots[source]
    if bot and bot.syncer == client then
        triggerClientEvent("onClientBotCommand", source, ...)
    end
end)

addCommandHandler("bot", function(player, command, skin)
    local position = player.position + player.matrix.forward * 3
    local ped = createPed( tonumber(skin), position.x, position.y, position.z)
end)