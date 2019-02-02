--[[
function getPedOccupiedVehicle(...) return {} end
function getPedOccupiedVehicleSeat(...) return 0 end
function getTickCount(...) return 0 end
function getElementPosition(...) return 1,2,3 end
function addEventHandler(...) end
]]

local fps = 0
local avgTime = 0
local avgFrames = 0
local avgFps = 0

--local screenWidth, screenHeight = guiGetScreenSize()

local function OnClientPreRender( timeSlice )
    fps = ( 1 / timeSlice ) * 1000
	avgFrames = avgFrames + 1
	avgTime = avgTime + timeSlice
	if avgTime > 10000 then
		avgFps = avgFrames / avgTime * 1000
		avgFrames = 0
		avgTime = 0
	end
end
addEventHandler("onClientPreRender", root, OnClientPreRender)

function getCurrentFPS()
    return fps
end

local timer
local LIFETIME = 5000
local vehicles = {}
local COLOR = tocolor(255,0,0,128)

addEventHandler( "onClientElementStreamIn", root,
function()
	if getElementType( source ) == "vehicle" then
		vehicles[source] = {}
	end
end)

addEventHandler( "onClientElementStreamOut", root,
function()
	if getElementType( source ) == "vehicle" then
		vehicles[source] = nil
	end
end)

local function getLocalVehicle()
	local vehicle = getPedOccupiedVehicle( localPlayer )
	if vehicle and getPedOccupiedVehicleSeat( localPlayer ) == 0 then return vehicle end
end

local function shift(tab,n)
	local c = #tab
	for i = 1,c - n do
		tab[i] = tab[i + n]
	end
	for i = 1,n do 
		tab[c - i + 1] = nil 
	end
end

local function pulse()
	local localVehicle = getLocalVehicle()
	local now = getTickCount()

	for vehicle,data in pairs(vehicles) do

		local m = vehicle.matrix
		local norm = m.right	
		local position = vehicle.position + m.forward * -2
		
		for i = 1,#data do
			if now - data[i][1] < LIFETIME then
				if i > 1 then shift(data,i) end
				break
			end
		end
	
		local c = #data

		if c > 0 then

			local pt,px,py,pz = unpack(data[c])

			local dx, dy, dz = position.x - px, position.y - py, position.z - pz
			local d = dx * dx + dy * dy + dz * dz
			if d > 0.01 then
				data[c + 1] = { now, position.x, position.y, position.z, norm.x, norm.y, norm.z }
			elseif vehicle == localVehicle then
			-- don`t stop
			end
		else
			data[c + 1] = { now, position.x, position.y, position.z, norm.x, norm.y, norm.z }
		end
	end
end

local function stop()
	if timer then 
		killTimer( timer ) 
		timer = nil
	end
end

local function start()
	stop()
	timer = setTimer( pulse, 100, 0 )	
end

local texTail = dxCreateTexture("tail.png")

local function normal2d(x1,y1,x2,y2)
	return y1 - y2, x2 - x1
end

local function draw(now)
	for vehicle,data in pairs(vehicles) do
		local prev_x,prev_y,prev_z = getElementPosition( vehicle )
		local prev_dx,prev_dy,prev_dz
		local c = #data		
		for i = 1,c do
			local t,x,y,z = unpack(data[c - i + 1])
			if now - t > LIFETIME then break end
			local l = getDistanceBetweenPoints2D(prev_x,prev_y,x,y)
			if l > 0.1 then
				local nx,ny = normal2d( prev_x, prev_y, x, y )
			-- in future replace to dxDrawMaterialPrimitive3d
				dxDrawMaterialSectionLine3D( prev_x,prev_y,prev_z, x,y,z, 0,0,2,2,texTail, 1, COLOR, false, x + nx, y + ny, z )
				prev_x,prev_y,prev_z = x,y,z
			end
		end
	end
end

addEvent("DL:onVehicleHit", true)
local function check(now)
	local localVehicle = getLocalVehicle()
	local data = localVehicle and vehicles[localVehicle]
	if not data then return end
	local c = #data
	for i = 1,c do
		local t,x,y,z = unpack(data[c - i + 1])
		if now - t > LIFETIME then break end
		for vehicle,_ in pairs(vehicles) do
			local vx,vy,vz = getElementPosition( vehicle )
			local c = #data
			for i = 1,c do
				local t,x,y,z = unpack(data[c - i + 1])
				if now - t > LIFETIME then break end
				if getDistanceBetweenPoints3D(x,y,z,vx,vy,vz) < 0.7 then
					setTimer( triggerServerEvent, 50, 1, "DL:onVehicleHit", vehicle )
					blowVehicle( vehicle, true )
					break
				end
			end
		end
	end
end

local function OnClientRender()	
	dxDrawText( string.format("%g, %g", avgFps, fps), 0, 0 )
--[[	
	local m = localPlayer.matrix
	local p = localPlayer.position
	local f = p + 5 * m.forward
	local l = p - 5 * m.right
	local dx = p.y - f.y
	local dy = f.x - p.x
	dxDrawLine3D( p.x, p.y, p.z, p.x, p.y, p.z + 5, tocolor(255,255,255,128), 1, false )
	dxDrawLine3D( p.x, p.y, p.z, f.x, f.y, f.z, tocolor(255,0,0,128), 1, false )
	dxDrawLine3D( p.x, p.y, p.z, l.x, l.y, l.z, tocolor(0,0,255,128), 1, false )
	dxDrawLine3D( p.x, p.y, p.z, p.x + dx, p.y + dy, p.z, tocolor(0,255,0,128), 1, false )
]]
	local now = getTickCount()
	draw(now)
	check(now)

end
addEventHandler( "onClientRender", root, OnClientRender )

addCommandHandler("dlstart", start)
addCommandHandler("dlstop", stop)
start()