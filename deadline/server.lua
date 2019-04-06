addEvent("DL:onVehicleHit", true)
addEventHandler("DL:onVehicleHit", root, function(winner,loser)    
    setElementHealth( source, 0 )
    setTimer( blowVehicle, 1000, 1, source, true )
end)

addEvent("DL:onSpawn", true)
addEventHandler("DL:onSpawn", root, function(x,y,z)
    if isPedDead( client ) then        
        spawnPlayer( client, x, y, z, 0, getElementModel(client) or 0 )
    end
    local vehicle = createVehicle( 522, x, y, z )
    warpPedIntoVehicle( client, vehicle, 0 )
end)

