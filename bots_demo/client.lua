local BOT_PULSE_INTERVAL = 200

BOT_COMMANDS = {}
BOT_COMMANDS_CODE = {}
BOT_CONTROLS = { "forwards", "left", "right", "aim_weapon", "fire" }

local bots = {}

addEvent("onBotAttach", true)
addEvent("onBotDettach", true)
addEvent("onBotCommand", true)
addEvent("onClientBotAttach", true)
addEvent("onClientBotDettach", true)
addEvent("onClientBotCommand", true)
addEvent("onBotUpdatePosition", true)
addEvent("onBotDamage", true)

local debug_info = false

addEvent("onTrace", true)
function trace(...)
----[[
    if debug_info then
        local msg = ""
        for i = 1,select("#",...) do
            local value = select(i,...)
            if type(value) == "string" then
                msg = msg .. " " .. value
            else
                msg = msg .. " " .. inspect(value, {newline="", indent=""})
            end
        end
        outputChatBox(msg)
        outputDebugString(msg)
    end
--]]
end

bindKey("f4", "down", function(key,state)
    debug_info = not debug_info
    if debug_info then
        addEventHandler( "onTrace", root, trace )
    else
        removeEventHandler( "onTrace", root, trace )
    end
end)

local function drawNode( nodeId )
    local x,y,z,count = get_path_node( nodeId )
    local o = 1
    local sx,sy,sz = getScreenFromWorldPosition(x, y, z + o)
    if sx and sy and sz and sz < 50 then
        dxDrawText(tostring(nodeId),sx,sy)
    end
    dxDrawLine3D( x, y, z, x, y, z + o + 0.1, tocolor(255, 0, 0), 10 )
    for index=1,count do
        local adjacentId = get_path_adjacent_node( nodeId, index )
        local ax,ay,az = get_path_node( adjacentId )
        dxDrawLine3D( x, y, z + o, ax, ay, az + o, tocolor(0, 255, 0), 5 )
    end
end

addEventHandler( "onClientRender", root, function()
    if debug_info then
        local x,y,z = getElementPosition(localPlayer)
        octree_foreach( x, y, z, 100, drawNode )

        for ped, bot in pairs(bots) do
            if isElementOnScreen( ped ) then
                local color = isElementSyncer( ped ) and -2147418368 or -2130771968
                local x,y,z = getElementPosition( ped )
                dxDrawLine3D( x, y, z + 0.8, x, y, z + 1, color, 10 )
                local sx,sy,sz = getScreenFromWorldPosition(x, y, z + 1.2)
                if sx and sy then
                    if sz < 50 then
                        dxDrawText(inspect(bot),sx,sy)
                    end
                end
            end
        end
    end
end)

function setBotCommand( bot, command )
    bot.command = command
    bot.stage = nil
    bot.time = nil
end

local function onClientBotCommand( command )
    invokeBotByElement( source, setBotCommand, command )
end

local function botUpdate( bot )
    if bot.syncer then 
        if not isElementSyncer(bot.ped) then
            local x,y,z = getElementPosition(bot.ped)
            if bot.x and bot.y and bot.z then
                local dx, dy, dz = x - bot.x, y - bot.y, z - bot.z
                local d = dx*dx + dy*dy + dz*dz                            
                if d < 0.25 then return end            
            end
            bot.x,bot.y,bot.z = x,y,z
            triggerServerEvent("onBotUpdatePosition", bot.ped, x,y,z)
        end
    end
end

local function botCommand( bot )
    local code, func, time = getBotCommand( bot )
    local result = func( bot, time, getBotCommandArgs( bot ) )
    if not result then return end
    if result == true then
        bot.time = bot.time and bot.time + BOT_PULSE_INTERVAL or BOT_PULSE_INTERVAL
        return true 
    end
    bot.stage = result
    bot.time = nil
    return true
end

local function botPulse( ped )
    local bot = bots[ped]
    botUpdate( bot )
    local result = ( not bot.syncer or botAiPulse( bot ) ) and botCommand( bot )
    if not result then
        bot.command = nil
        bot.stage = nil
        bot.time = nil
        if bot.syncer then 
            botAi( bot ) 
        end
    end
end

addEventHandler( "onClientResourceStart", resourceRoot, function()
    local names = {}    
    for name,func in pairs(BOT_COMMANDS) do table.insert(names,name) end
    table.sort(names)
    for code = 1, #names do
        BOT_COMMANDS_CODE[code] = names[code]
        BOT_COMMANDS_CODE[names[code]] = code
    end
end)

local function onClientPedDamage( attacker, weapon, bodypart, loss )
	local bot = bots[source]
	if bot and bot.syncer then
		triggerServerEvent( "onBotDamage", source, attacker, weapon, bodypart, loss )
	end
    cancelEvent()
end

local function onClientBotDestroy()
    invokeBotByElement( source, removeBot )
end

local function onClientPedWasted( killer, weapon, bodypart, loss )
    invokeBotByElement( source, removeBot )
end

local function attachBotSyncer(bot, command, syncer, shared )
    if syncer and not bot.syncer then
        botAiInit( bot )
    end
    bot.syncer = syncer
    bot.shared = shared
    bot.command = command
end

local function dettachBotSyncer( bot )
    if bot.syncer then
        botAiRelease( bot )
        triggerServerEvent( "onBotDettach", bot.ped, bot.shared )
        bot.syncer = false
        bot.shared = nil
    end
end

function getOrAddBot( ped )
    local bot = bots[ped]    
    if bot then return bot end
    bot = { 
        syncer = false, 
        ped = ped,
        timer = assert( setTimer( botPulse, BOT_PULSE_INTERVAL, 0, ped ) )
    }
    bots[ped] = bot
    addEventHandler("onClientBotCommand", ped, onClientBotCommand)
    addEventHandler("onClientPedDamage", ped, onClientPedDamage)
    addEventHandler("onClientPedWasted", ped, onClientPedWasted)
    addEventHandler("onClientElementDestroy", ped, onClientBotDestroy)
    return bot
end

function removeBot( bot )
    dettachBotSyncer( bot )
    if bot.timer then
        killTimer( bot.timer ) 
        bot.timer = nil
    end
    removeEventHandler("onClientElementDestroy", bot.ped, onClientBotDestroy)
    removeEventHandler("onClientBotCommand", bot.ped, onClientBotCommand)
    removeEventHandler("onClientPedDamage", bot.ped, onClientPedDamage)
    removeEventHandler("onClientPedWasted", bot.ped, onClientPedWasted)
    bots[bot.ped] = nil
    bot.ped = nil
end

addEventHandler( "onClientElementStreamInDelayed", root, function()
    if getElementType(source) == "ped" and not isPedDead( source ) then 
        local bot = getOrAddBot( source )
        local x,y,z = getElementPosition( bot.ped )
        local gz = getGroundPosition( x, y, z + 1.2 )
        triggerServerEvent("onBotAttach", bot.ped, x, y, gz + 1.2)
    end
end)

addEventHandler( "onClientElementStreamOutDelayed", root, function()
    if getElementType(source) == "ped" then
        invokeBotByElement( source, removeBot )
    end
end)

addEventHandler( "onClientBotAttach", root, function( command, syncer, shared )
    invokeBotByElement( source, attachBotSyncer, command, syncer, shared )
end)

addEventHandler( "onClientBotDettach", root, function()
    invokeBotByElement( source, dettachBotSyncer )
end)

addEventHandler( "onClientResourceStart", resourceRoot, function()
	load_paths()
end)

function sendCommand( bot, command, ...)
    triggerServerEvent("onBotCommand", bot.ped, BOT_COMMANDS_CODE[command], ...)
end

function getBotRotation(x0,y0,x,y)
    return 57.295779513082323 * (6.2831853071796 - math.atan2 ( ( x - x0 ), ( y - y0 ) ) % 6.2831853071796)
end

function getBotTargetPrediction(target, time)
    local x, y, z = getElementPosition(target)
    local vx, vy, vz = getElementVelocity(target)
    local k = time / 20
    return x + vx * k, y + vy * k, z + vz * k
end

function setBotRotationTo( bot, x,y,z )
    local x0, y0, z0 = getElementPosition( bot.ped )
    local yaw = getBotRotation(x0,y0,x,y)
    setElementRotation( bot.ped, 0, 0, yaw, "default", true )
    return x0, y0, z0, yaw
end

function setBotRotationToTarget( bot, target, time )
    local x, y, z = getBotTargetPrediction( target, time or BOT_PULSE_INTERVAL )
    local x0, y0, z0, yaw = setBotRotationTo( bot, x,y,z )
    return x0, y0, z0, x, y, z, yaw
end

function getBotByElement( ped )
    return bots[ped]
end

function invokeBotByElement( ped, method, ... )
    local bot = bots[ped]
    if bot then return method( bot, ... ) end
end

function getBotCommand( bot )    
    if bot.command and bot.command[1] then
        return bot.command[1], bot.stage or BOT_COMMANDS[BOT_COMMANDS_CODE[bot.command[1]]], bot.time
    else
        return BOT_COMMANDS_CODE.idle, bot.stage or BOT_COMMANDS.idle, bot.time
    end
end

function getBotCommandArgs( bot )
    if bot.command then
        return select(2,unpack(bot.command))
    end
end

function botStop( bot )
    for _,control in pairs(BOT_CONTROLS) do
        setPedControlState( bot.ped, control, false )
    end
    setPedAnimation( bot.ped )
end

function processBotLineOfSight( x0, y0, z0, x, y, z, ignore )
    return processLineOfSight( x0, y0, z0, x, y, z,
        true, --bool checkBuildings
        true, --bool checkVehicles
        true, --bool checkPlayers
        true, --bool checkObjects
        true, --bool checkDummies
        false, --bool seeThroughStuff
        false, --bool ignoreSomeObjectsForCamera
        false, --bool shootThroughStuff
        ignore,
        false, --bool includeWorldModelInformation
        true --bool bIncludeCarTyres 
    )
end