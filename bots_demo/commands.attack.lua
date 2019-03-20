local function cease( bot, time, target )
    if not target or not isElement(target) then return end
    if time and time > 200 then return end
    local x0, y0, z0, x, y, z = setBotRotationToTarget( bot, target )
    setPedAimTarget( bot.ped, x,y,z )
    setPedControlState( bot.ped, "fire", false )
    setPedControlState( bot.ped, "aim_weapon",  false )
end

local function fire( bot, time, target )
    if not target or not isElement(target) then return end
    if time and time > 500 then return cease end
    local x0, y0, z0, x, y, z = setBotRotationToTarget( bot, target )
    setPedAimTarget( bot.ped, x,y,z )
    setPedControlState( bot.ped, "fire", true )
    return true
end

local function aim( bot, time, target )
    if not target or not isElement(target) then return end
    if time and time > 200 then return fire end
    local x0, y0, z0, x, y, z = setBotRotationToTarget( bot, target )
    setPedAimTarget( bot.ped, x,y,z )
    setPedControlState( bot.ped, "aim_weapon", true )
    return true
end

function BOT_COMMANDS.attack( bot, time, target )
    if not target or not isElement(target) then return end

    local weapon = getPedWeapon(bot.ped)
    if not weapon then return end
    
    local range = getWeaponProperty(weapon, "poor", "weapon_range") or 0.5
    
    local x0, y0, z0, x, y, z = setBotRotationToTarget( bot, target )

    local dist = getDistanceBetweenPoints3D( x0,y0,z0, x,y,z )
    if dist > range then
        setPedControlState( bot.ped, "forwards", true )
        return true
    end
    setPedControlState( bot.ped, "forwards", false )
    return aim
end
