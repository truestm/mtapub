local bots = {}
local commands = {}

local commands_code = 
{ 
    [1] = "idle", 
    idle = 1,
    [2] = "mov",
    mov = 2
}

addEvent("onBotAttach", true)
addEvent("onBotDettach", true)
addEvent("onBotCommand", true)
addEvent("onClientBotAttach", true)
addEvent("onClientBotDettach", true)
addEvent("onClientBotCommand", true)

local function onClientBotCommand(...)
    bots[source].command = {...}
end

local function botPulse(ped)
    local bot = bots[ped]
    botAi( ped, bot )
end

addEventHandler( "onClientElementStreamIn", root, function()
    if getElementType(source) == "ped" then
        if not bots[source] then
            bots[source] = { syncer = false, timer = setTimer(botPulse, 50, 0, source) }
            addEventHandler("onClientBotCommand", source, onClientBotCommand)
        end
        triggerServerEvent("onBotAttach", source)
    end
end)

addEventHandler( "onClientElementStreamOut", root, function()
    if getElementType(source) == "ped" then
        local bot = bots[source]
        if bot then
            triggerServerEvent("onBotDettach", source, bot.shared)
            killTimer(bot.timer)
            removeEventHandler("onClientBotCommand", source, onClientBotCommand)
            bots[source] = nil
        end
    end
end)

addEventHandler( "onClientBotAttach", root, function(shared)
    local bot = bots[source]
    if bot then
        bot.syncer = true
        bot.shared = shared
    end
end)

addEventHandler( "onClientBotDettach", root, function()
    local bot = bots[source]
    if bot then
        bot.syncer = false
        bot.shared = nil
    end
end)

function botAi(ped, bot)
    local result
    if bot.command and bot.command[1] then
        result = commands[commands_code[bot.command[1]]](ped, bot, unpack(bot.command))
    else
        result = commands[commands_code[1]](ped, bot)
    end
    if not result then
        bot.command = nil
    end
end

function commands.idle(ped, bot, cmd)
    if not bot.shared then
        bot.shared = { x = ped.position.x, y = ped.position.y }
    end
    local dist = getDistanceBetweenPoints2D(bot.shared.x,bot.shared.y,ped.position.x,ped.position.y)
    local target
    if dist < 0.8 then
        local target = ped.position - ped.matrix.forward * 35
        triggerServerEvent("onBotCommand", ped, commands_code.mov, target.x, target.y)
    else
        triggerServerEvent("onBotCommand", ped, commands_code.mov, bot.shared.x, bot.shared.y)
    end
end

function commands.mov(ped, bot, cmd, x, y)
    local x0,y0,z0 = getElementPosition(ped)
    local dist = getDistanceBetweenPoints2D(x0,y0,x,y)
    if dist < 0.8 then
        setPedControlState( ped, "forwards", false )
        return
    end
    local yaw = 6.2831853071796 - math.atan2 ( ( x - x0 ), ( y - y0 ) ) % 6.2831853071796
    setElementRotation( ped, 0, 0, math.deg(yaw), "default", true )
    setPedControlState( ped, "forwards", true )
    return true
end
