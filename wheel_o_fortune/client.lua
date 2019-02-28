local wheel_o_fortune, wheel_support, clicker
local sectors = { 1, "*", 2,10,1,2,1,5,1,2,10,1,2,1,5,2,1,20,1,2,5,10,1,2,1,5,1,2,1,"*",2,1,2,1,2,5,1,2,1,5,1,20,1,10,1,2,1,5,1,2,1,5,1,2,1 }
local sector, rotation
local velocity = 0
local fraction = 0.001

local function create(player)
    local position = player.position + player.matrix.forward * 2
    if not wheel_support or (wheel_support.position - position).length > 10 then
        if wheel_support   then destroyElement(wheel_support) end
        if wheel_o_fortune then destroyElement(wheel_o_fortune) end

        wheel_support = createObject( 1897, position.x, position.y, position.z, 0,0,0 )
        clicker = createObject( 1898, position.x, position.y, position.z, 0,0,0 )
        wheel_o_fortune = createObject( 1895, position.x, position.y, position.z, 0,0,0 )

        attachElements( wheel_o_fortune, wheel_support, 0, -0.05, 0.1, 0, 0, 0 )
        attachElements( clicker, wheel_support, 0, -0.1, 1.10, 0, 0, 0 )
        rotation = 0
        sector = 1
        return true
    end
end

local function rotate(angle)
    local ox,oy,oz, rx,ry,rz = getElementAttachedOffsets(wheel_o_fortune)
    rotation = ry + angle
    sector = math.floor( ( rotation + 3.333 ) / 6.667 + 0.0005 ) + 1
    setElementAttachedOffsets( wheel_o_fortune, 0, -0.05, 0.1, 0, rotation, 0 )
end

local function fixRotation()
    local ox,oy,oz, rx,ry,rz = getElementAttachedOffsets(wheel_o_fortune)
    rotation = ry + angle
    sector = math.floor( ( rotation + 3.333 ) / 6.667 + 0.0005 ) + 1
    setElementAttachedOffsets( wheel_o_fortune, 0, -0.05, 0.1, 0, sector * 6.667 - 3.333, 0 )
end

addCommandHandler("casino", function()
    if not create(localPlayer) then
        velocity = math.random() * 2 + 0.1
    end
end)

addEventHandler( "onClientPreRender", root, function(time)
    if velocity then
        velocity = velocity - time * fraction
        if velocity < 0.001 then
            fixRotation()
            velocity = nil
        else
            rotate(velocity * time)
        end
    end
end)

local screenWidth, screenHeight = guiGetScreenSize()

addEventHandler( "onClientRender", root, function()
    dxDrawText( tostring(sectors[sector]).."/"..tostring(rotation).."/"..tostring(sector), 0, 0, screenWidth, screenHeight, white, 3, 3, "default", "center", "top")
end)

bindKey("p", "down", function()
    executeCommandHandler("casino")
end)
