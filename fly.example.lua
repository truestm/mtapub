local flyFriction = 0.01
local flyAccelration = 0.025
local flyAntigravity = 0.0051
local flyTurnAccelration = 0.05

local flyKeys = 
{
	accelerate         = { "forward", 1 },
	brake_reverse      = { "forward", -1 },
	vehicle_look_left  = { "roll", 1 },
	vehicle_look_right = { "roll", -1 },
	lshift             = { "lift", 1 },
	steer_forward      = { "up", 1 },
	steer_back         = { "up", -1 },
	vehicle_left       = { "right", -1 },
	vehicle_right      = { "right", 1 }
}

local flyVehicle

local flyControl = {}

local function flyKey( key, state )
	if flyKeys[ key ] then
		local control, value = unpack( flyKeys[ key ] )
		if state == "down" then
			flyControl[control] = value
		else
			flyControl[control] = nil
		end
	end
end

local function flyOnPreRender( time )
	local kTime = time * 0.05
	local matrix = flyVehicle.matrix		
	local forward = matrix.forward
	local right = matrix.right
	local up = matrix.up
	local velocity = flyVehicle.velocity
	local turnVelocity = flyVehicle.turnVelocity
	local velocityModule = velocity.length
	local velocityNormal = velocity:getNormalized()
	
	local turn = ( velocityNormal - forward ).length
	
	velocity = velocity - velocityNormal * velocityModule * velocityModule * turn * turn * turn * flyFriction * kTime
	
	velocity = velocity + up * flyAntigravity * kTime	
	velocity = velocity + forward * ( flyControl.forward or 0 ) * flyAccelration * kTime
	
	flyVehicle.velocity = velocity
	
	turnVelocity =
		matrix.up * -( flyControl.right or 0 ) * flyTurnAccelration * kTime + 
		matrix.right * -( flyControl.up or 0 ) * flyTurnAccelration * kTime + 
		matrix.forward * -( flyControl.roll or 0 ) * flyTurnAccelration * kTime 
		
	local different = Vector3( -up.y, up.x, 0 )
	
	if different.length > 0.05 then
		turnVelocity = turnVelocity - different:getNormalized() * flyTurnAccelration * kTime * 0.5
	end
	
	flyVehicle.turnVelocity = turnVelocity
end

local function flyKeyBinds( enable )
	for key in pairs(flyKeys) do 
		( enable and bindKey or unbindKey )( key, "both", flyKey )
		toggleControl( key, not enable ) 
	end
end

local function flyStop()
	if flyVehicle then
		removeEventHandler( "onClientPreRender",      root,        flyOnPreRender )
		removeEventHandler( "onClientKey",            root,        flyKey  )
		removeEventHandler( "onClientPlayerWasted",   localPlayer, flyStop )
		removeEventHandler( "onClientVehicleExit",    flyVehicle,  flyStop )
		removeEventHandler( "onClientVehicleExplode", flyVehicle,  flyStop )
		removeEventHandler( "onClientElementDestroy", flyVehicle,  flyStop )
		flyKeyBinds( false )
		flyVehicle = nil
	end
end

local function flyStart(vehicle)
	flyVehicle = vehicle
	addEventHandler( "onClientPreRender",      root,        flyOnPreRender )
	addEventHandler( "onClientPlayerWasted",   localPlayer, flyStop )
	addEventHandler( "onClientVehicleExit",    flyVehicle,  flyStop )
	addEventHandler( "onClientVehicleExplode", flyVehicle,  flyStop )
	addEventHandler( "onClientElementDestroy", flyVehicle,  flyStop )
	flyKeyBinds( true )
end

addEventHandler( "onClientVehicleEnter", root, function( player, seat )
	if player == localPlayer and seat == 0 then
		flyStart( source )
	end
end)

