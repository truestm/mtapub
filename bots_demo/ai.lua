local function onClientPedDamage( attacker, weapon, bodypart, loss )
    local bot = getBotByElement( source )
    if bot and bot.syncer and not bot.shared.target then
        bot.shared.target = attacker
    end
end

function botAiInit( bot )
    addEventHandler( "onClientPedDamage", bot.ped, onClientPedDamage )
end

function botAiRelease( bot )
    removeEventHandler( "onClientPedDamage", bot.ped, onClientPedDamage )        
end

function botAiPulse( bot )
    local code = getBotCommand( bot )
    if bot.shared then
        if bot.shared and bot.shared.target then
            return code == BOT_COMMANDS_CODE.attack
        else
            return code ~= BOT_COMMANDS_CODE.attack
        end
    end
end

function botAi( bot )
    if bot.shared and bot.shared.target then
        if isElement(bot.shared.target) and getElementHealth(bot.shared.target) > 0 then
            sendCommand( bot, "attack", bot.shared.target )
            return
        else
            bot.shared.target = nil
        end
    end

    if not bot.shared or not bot.shared.id then
        local x,y,z = getElementPosition( bot.ped )
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
        sendCommand( bot, "move_to_node", bot.shared.id )
    end
end

