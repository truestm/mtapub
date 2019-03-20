addEvent("onBotAttach", true)
addEvent("onBotDettach", true)
addEvent("onBotCommand", true)
addEvent("onClientBotAttach", true)
addEvent("onClientBotDettach", true)
addEvent("onClientBotCommand", true)
addEvent("onBotUpdatePosition", true)
addEvent("onBotDamage", true)

local bots = {}
local players = {}

addEvent("onTrace", true)
function trace(...)
    triggerClientEvent(client,"onTrace",client,...)
end

local function attachBot( ped, player )
    local bot = bots[ped]
    if not bot then
        bot = { players = { [player] = true } }
        bots[ped] = bot
    end
    
    bot.players[player] = true
    
    local playerBots = players[player]
    if not playerBots then 
        players[player] = { [ped] = true }
    else
        playerBots[ped] = true
    end
    return bot
end

local function setSyncer( ped, bot, syncer, x, y, z )
    if syncer then
        bot.syncer = syncer
        if x and y and z then
            setElementPosition( ped, x, y, z, false )
        end
        setElementFrozen( ped, false )
        setElementCollisionsEnabled( ped, true ) 
        setElementSyncer( ped, syncer )
    else
        bot.syncer = nil
        if not isPedDead( ped ) then
            setElementFrozen( ped, true )
            setElementCollisionsEnabled( ped, false ) 
        end
    end
end

local function detachBot( ped, player, shared )
    local bot = bots[ped]
    if not bot then return end        
    bot.players[player] = nil
    if bot.syncer == player then
        bot.shared = shared
        bot.syncer = getElementSyncer( ped )
        if not bot.players[syncer] or syncer == client then
            bot.syncer = next(bot.players)
        end
        setSyncer( ped, bot, bot.syncer )
        if bot.syncer then
            triggerClientEvent( bot.syncer, "onClientBotAttach", ped, bot.command, true, bot.shared )
        end
    end
    return bot
end

local function destroyPlayer( player )
    local playerBots = players[player]
    if playerBots then 
        for ped in pairs(playerBots) do
            detachBot( ped, player )
        end
        players[player] = nil
    end
end

addEventHandler( "onBotAttach", root, function(x,y,z)
    local bot = attachBot( source, client )
    if not bot.syncer or bot.syncer == client then
        setSyncer( source, bot, client, x, y, z )
        triggerClientEvent( client, "onClientBotAttach", source, bot.command, true, bot.shared )
    else
        triggerClientEvent( client, "onClientBotAttach", source, bot.command )
    end
end)

addEventHandler( "onPlayerQuit", root, function(type, reason, element)
    destroyPlayer( source )    
end)

addEventHandler( "onBotDettach", root, function(shared)
    detachBot( source, client, shared )
end)

addEventHandler( "onBotUpdatePosition", root, function(x,y,z)
    local bot = bots[source]
    if bot and bot.syncer == client then
        local syncer = getElementSyncer( source )
        if syncer ~= client then
            if syncer then
                triggerClientEvent( client, "onClientBotDettach", source )
            else
                setElementPosition( source, x,y,z, false )
                setElementSyncer( source, client )
            end
        end
    end
end)

local function doDamageBot( ped, attacker, weapon, bodypart, loss )
    local health = getElementHealth( source )
    health = health - loss
    if health <= 1 then
        killPed( source, attacker, weapon, bodypart )
    else
        setElementHealth( source, math.max( 0, health ) )
    end
end

addEventHandler( "onBotDamage", root, function( attacker, weapon, bodypart, loss )
    if attacker == client then
        doDamageBot( source, attacker, weapon, bodypart, loss )
    elseif getElementType(attacker) == "ped" then
        local bot = bots[attacker]
        if bot and bot.syncer == client then
            doDamageBot( source, attacker, weapon, bodypart, loss )
        end
    end
end)

addEventHandler( "onBotCommand", root, function(...)
    local bot = bots[source]
    if bot and bot.syncer == client then
        local syncer = getElementSyncer( source )
        if not syncer or syncer == client then
            bot.command = {...}
            triggerClientEvent( "onClientBotCommand", source, bot.command )
        else
            if syncer then 
                triggerClientEvent( client, "onClientBotDettach", source )
            end
        end
    end
end)

local function botDestroy()
    local bot = bots[source]
    if bot then
        for player in pairs(bot.players) do
            local playerBots = players[player]            
            if playerBots then
                playerBots[source] = nil
            end
        end
    end
    bots[source] = nil
end

local function botRespawn(ped)
    local bot = bots[ped]
    if bot then
        local skin = getElementModel(ped)
        local x,y,z = unpack(bot.respawn)
        destroyElement(ped)
        createBot(skin, x,y,z)
    end
end

local function botWasted()
    local bot = bots[source]
    if bot then
--        if bot.syncer then
--            triggerClientEvent( client, "onClientBotDettach", source )
--        end
        setTimer(botRespawn, 20000, 1, source)
    end
end

function createBot(skin,x,y,z)
    local ped = createPed( skin, x, y, z )
    local bot = { shared = {}, players = {}, respawn = {x, y, z} }
    bots[ped] = bot
    --setElementHealth( ped, 10000 )
    addEventHandler( "onElementDestroy", ped, botDestroy )
    addEventHandler( "onPedWasted", ped, botWasted )
    setElementFrozen( ped, true )
    setElementCollisionsEnabled( ped, false )
    giveWeapon( ped, 31, 9999, true )
    return ped, bot
end

addCommandHandler("bot", function(player, command, skin)
    local x,y,z = getElementPosition(player)
    local id = octree_nearest(x,y,z, 10)
    if id then
        local nx,ny,nz = get_path_node(id)
        local ped, bot = createBot(tonumber(skin), nx,ny,nz + 1)
        bot.shared.id = id
    end
end)

addEventHandler( "onResourceStart", resourceRoot, function()
    load_paths()
----[[
    local nodes = {}
    octree_foreach(0, 0, 0, 3000, function(id,node)
        nodes[#nodes + 1] = id
    end)
    local skins = getValidPedModels()
    for i = 1, 3000 do
        local index = math.random(#nodes)
        local id = nodes[index]
        local skin = skins[math.random(#skins)]
        local x,y,z = get_path_node(id)
        createBot(skin, x, y, z + 1)
    end
--]]
end)

addEventHandler( "onResourceStop", resourceRoot, function()
    for ped in pairs(bots) do 
        destroyElement(ped) 
    end
end)

