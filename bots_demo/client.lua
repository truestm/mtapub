local bots = {}
local commands = {}
local commands_code

addEvent("onBotAttach", true)
addEvent("onBotDettach", true)
addEvent("onBotCommand", true)
addEvent("onClientBotAttach", true)
addEvent("onClientBotDettach", true)
addEvent("onClientBotCommand", true)
addEvent("onBotUpdate", true)

local debug_info = false

addEvent("onTrace", true)
local function trace(...)
--[[
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

local anim_move = false

bindKey("f3", "down", function(key,state)
    anim_move = not anim_move
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

local function onClientBotCommand(...)
    bots[source].command = {...}
end

local function botUpdate(ped, bot)
    if bot.syncer then 
        if not isElementSyncer(ped) then
            local x,y,z = getElementPosition(ped)
            if bot.x and bot.y and bot.z then
                local dx, dy, dz = x - bot.x, y - bot.y, z - bot.z
                local d = dx*dx + dy*dy + dz*dz                            
                if d < 0.25 then return end            
            end
            bot.x,bot.y,bot.z = x,y,z
            triggerServerEvent("onBotUpdate", ped, x,y,z)
        end
    end
end

local function botPulse(ped)
    local bot = bots[ped]
    botUpdate(ped, bot)
    local result
    if bot.command and bot.command[1] then
        result = commands[commands_code[bot.command[1]]](ped, bot, unpack(bot.command))
    else
        result = commands.idle(ped, bot)
    end
    if not result then
        bot.command = nil
        if bot.syncer then 
            botAi( ped, bot ) 
        end
    end
end

addEventHandler( "onClientResourceStart", resourceRoot, function()
    commands_code = {}
    local code = 1
    local names = {}    
    for name,func in pairs(commands) do 
        table.insert(names,name) 
    end
    table.sort(names)
    for _,name in ipairs(names) do
        commands_code[code] = name
        commands_code[name] = code
        code = code + 1
    end
end)

local function onClientBotDestroy()
    local bot = bots[source]
    if bot then
        killTimer( bot.timer ) 
        bot.timer = nil
        bots[source] = nil
    end
end

local function attachBotSyncer(ped, bot)
    local x,y,z = getElementPosition(ped)
    local gz = getGroundPosition( x, y, z + 1.2 )
    triggerServerEvent("onBotAttach", ped, x, y, gz + 1.2)
end

local function attachBot(ped)    
    local bot = bots[ped]
    if not bot then
        bot = { syncer = false, timer = assert(setTimer(botPulse, 200, 0, ped)) }
        bots[ped] = bot
        addEventHandler("onClientBotCommand", ped, onClientBotCommand)
        addEventHandler("onClientElementDestroy", ped, onClientBotDestroy)
    end
    attachBotSyncer(ped, bot)
end

local function dettachBotSyncer(ped, bot)
    if bot.syncer then
        trace("detach syncer", ped, bot.shared)
        triggerServerEvent("onBotDettach", ped, bot.shared)
        bot.syncer = false
        bot.shared = nil
    end
end

local function dettachBot(ped)
    local bot = bots[ped]
    if bot then
        killTimer(bot.timer)
        bot.timer = nil
        dettachBotSyncer(ped, bot)
        removeEventHandler("onClientElementDestroy", ped, onClientBotDestroy)
        removeEventHandler("onClientBotCommand", ped, onClientBotCommand)
        bots[ped] = nil
    end
end

addEventHandler( "onClientElementStreamIn", root, function()
    if getElementType(source) == "ped" then 
        trace("in", source)
        attachBot(source)
    end
end)

addEventHandler( "onClientElementStreamOut", root, function()
    if getElementType(source) == "ped" then
        trace("out", source)
        dettachBot(source)
    end
end)

addEventHandler( "onClientBotAttach", root, function(command,syncer,shared)
    local bot = bots[source]
    if bot then
        trace("attach", source, syncer, shared)
        bot.command = command
        bot.syncer = syncer
        bot.shared = shared
    end
end)

addEventHandler( "onClientBotDettach", root, function()
    local bot = bots[source]
    if bot then
        dettachBotSyncer(source, bot)
    end
end)

addEventHandler( "onClientResourceStart", resourceRoot, function()
	load_paths()
end)

function botAi( ped, bot )    
    if not bot.shared or not bot.shared.id then
        local x,y,z = getElementPosition(ped)
        local nodeId = octree_nearest( x,y,z, 10 )
        if not nodeId then return end
        if not bot.shared then bot.shared = {} end
        bot.shared.id = nodeId
    end
    local x,y,z,count = get_path_node(bot.shared.id)
    local nextId
    if count > 1 then
        local rand = math.random(count - 1)
        local index = 1
        while rand > 0 do
            nextId = get_path_adjacent_node(bot.shared.id, index)
            if not bot.shared.prevId or nextId ~= bot.shared.prevId then
                rand = rand - 1
            end
            index = index + 1
        end
    else
        nextId = get_path_adjacent_node(bot.shared.id, 1)
    end
    bot.shared.prevId = bot.shared.id
    bot.shared.id = nextId
    if not anim_move then
        sendCommand( ped, "pmov", bot.shared.id )
    else
        sendCommand( ped, "pamov", bot.shared.id, "ped", "FightShF" )
    end
end

function sendCommand(ped, command, ...)
    triggerServerEvent("onBotCommand", ped, commands_code[command], ...)
end

function commands.idle(ped, bot, cmd)
    setPedControlState( ped, "forwards", false )
end

function commands.mov(ped, bot, cmd, x, y)
    local x0,y0,z0 = getElementPosition(ped)
    local dist = getDistanceBetweenPoints2D(x0,y0,x,y)
    if dist < 0.8 then
        return
    end
    local yaw = 6.2831853071796 - math.atan2 ( ( x - x0 ), ( y - y0 ) ) % 6.2831853071796
    setElementRotation( ped, 0, 0, math.deg(yaw), "default", true )
    setPedControlState( ped, "forwards", true )
    return true
end

function commands.pmov(ped, bot, cmd, nodeId)
    setPedAnimation( ped )
    if not nodeId then
        return
    end

    local x0,y0,z0 = getElementPosition(ped)
    local x,y,z = get_path_node(nodeId)
    local dist = getDistanceBetweenPoints2D(x0,y0,x,y)
    if dist < 0.8 then        
        return
    end
    
    bot.dist = dist

    local yaw = 6.2831853071796 - math.atan2 ( ( x - x0 ), ( y - y0 ) ) % 6.2831853071796
    setElementRotation( ped, 0, 0, math.deg(yaw), "default", true )
    setPedControlState( ped, "forwards", true )
    return true
end

function commands.pamov(ped, bot, cmd, nodeId, block, anim)
    if not nodeId then
        return
    end

    local currentBlock, currentAnim = getPedAnimation( ped )
    if currentBlock ~= block or currentAnim ~= anim then
        setPedAnimation( ped, block, anim )
    end

    local x0,y0,z0 = getElementPosition(ped)
    local x,y,z = get_path_node(nodeId)
    local dist = getDistanceBetweenPoints2D(x0,y0,x,y)
    if dist < 0.8 then        
        return
    end
    
    bot.dist = dist

    local yaw = 6.2831853071796 - math.atan2 ( ( x - x0 ), ( y - y0 ) ) % 6.2831853071796
    setElementRotation( ped, 0, 0, math.deg(yaw), "default", true )
    setPedControlState( ped, "forwards", true )
    return true
end

