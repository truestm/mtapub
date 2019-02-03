--[[
function dxCreateTexture(...) return {} end
function tocolor(...) return {} end
function getPedOccupiedVehicle(...) return {} end
function getPedOccupiedVehicleSeat(...) return 0 end
function getTickCount(...) return 0 end
function getElementPosition(...) return 1,2,3 end
function addEvent(...) end
function addEventHandler(...) end
function addCommandHandler(...) end
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
local COLOR = tocolor(255,0,0,255)
local COLOR_BB = tocolor(0,255,0,128)
local COLOR_IN_BB = tocolor(0,0,255,128)
local MIN_RADIUS = 0.5
local boundingBoxes


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

local function bound_range(min,max,radius)
	if max - min > radius + radius then return min, max end
	local o = ( min + max ) / 2
	return o - radius, o + radius
end

local function findBoundingBox(data,start,length)
	local max_x,max_y,max_z = -math.huge, -math.huge, -math.huge
	local min_x,min_y,min_z =  math.huge,  math.huge,  math.huge
	for i = start,start + length - 1 do
		local t,x,y,z = unpack(data[i])
		if x > max_x then max_x = x end
		if y > max_y then max_y = y end
		if z > max_z then max_z = z end
		if x < min_x then min_x = x end
		if y < min_y then min_y = y end
		if z < min_z then min_z = z end
	end

	min_x, max_x = bound_range( min_x, max_x, MIN_RADIUS )
	min_y, max_y = bound_range( min_y, max_y, MIN_RADIUS )
	min_z, max_z = bound_range( min_z, max_z, MIN_RADIUS )
	
	return min_x, min_y, min_z, max_x, max_y, max_z
end

local function buildBoundingBoxes(data,start,length)
	if length <= 3 then
		return 
		{ 
			false, 
			false, 
			start, length, findBoundingBox(data,start,length) 
		}
	else
		local halfLength = math.floor(length / 2)
		return { 
			buildBoundingBoxes(data, start,              halfLength + 1 ),
			buildBoundingBoxes(data, start + halfLength, halfLength),
			start, length, findBoundingBox(data,start,length) 
		}
	end
end

local function pulse()
	local localVehicle = getLocalVehicle()
	local now = getTickCount()

	for vehicle,data in pairs(vehicles) do

		local m = vehicle.matrix
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
			if d > 0.2 then
				data[c + 1] = { now, position.x, position.y, position.z }
			elseif vehicle == localVehicle then
			-- don`t stop
			end
		else
			data[c + 1] = { now, position.x, position.y, position.z }
		end

		if vehicle == localVehicle then
			boundingBoxes = buildBoundingBoxes(data,1,#data)
		end
	end
end

local function stop()
	if timer then 
		killTimer( timer ) 
		timer = nil
	end
	boundingBoxes = nil
	local vehicle = getLocalVehicle()
	if vehicle then vehicles[vehicle] = nil end
end

local function start()
	stop()
	timer = setTimer( pulse, 100, 0 )	
	local vehicle = getLocalVehicle()
	if vehicle then vehicles[vehicle] = {} end
end

local texTail = dxCreateTexture("tail.png")

local function normal2d(x1,y1,x2,y2)
	return y1 - y2, x2 - x1
end

local function drawBoundingBox(box,color,nested)
	local first, second, start, length, min_x, min_y, min_z, max_x, max_y, max_z = unpack(box)
	
	if nested then 
		if first then drawBoundingBox(first,color,nested) end
		if second then drawBoundingBox(second,color,nested) end
	end

	dxDrawLine3D(min_x, min_y, min_z, max_x, min_y, min_z, color)
	dxDrawLine3D(min_x, min_y, min_z, min_x, max_y, min_z, color)
	dxDrawLine3D(min_x, min_y, min_z, min_x, min_y, max_z, color)
	
	dxDrawLine3D(min_x, min_y, max_z, max_x, min_y, max_z, color)
	dxDrawLine3D(min_x, min_y, max_z, min_x, max_y, max_z, color)

	dxDrawLine3D(max_x, max_y, max_z, min_x, max_y, max_z, color)
	dxDrawLine3D(max_x, max_y, max_z, max_x, min_y, max_z, color)
	dxDrawLine3D(max_x, max_y, max_z, max_x, max_y, min_z, color)

	dxDrawLine3D(max_x, max_y, min_z, max_x, min_y, min_z, color)
	dxDrawLine3D(max_x, max_y, min_z, min_x, max_y, min_z, color)
end

local function draw(now)
	for vehicle,data in pairs(vehicles) do
		local prev_x,prev_y,prev_z = getElementPosition( vehicle )
		local prev_dx,prev_dy,prev_dz
		local c = #data		
		for i = 1,c do
			local t,x,y,z = unpack(data[c - i + 1])
			if now - t > LIFETIME then break end
			local n = i + 1
			if n <= c then
				local next_t, next_x, next_y, next_z = unpack(data[c - n + 1])
				local nx,ny = normal2d( prev_x, prev_y, next_x, next_y )
			-- in future replace to dxDrawMaterialPrimitive3d
				dxDrawMaterialSectionLine3D( prev_x,prev_y,prev_z,
					next_x,next_y,next_z, 
					0,0,32,32,texTail, MIN_RADIUS + MIN_RADIUS, COLOR, false, next_x + nx, next_y + ny, next_z )
				prev_x,prev_y,prev_z = x,y,z
			end
		end
	end
--	if boundingBoxes then
--		drawBoundingBox(boundingBoxes,COLOR_BB,true)
--	end
end

local function in_range(x,l,h)
	return x <= h and x >= l
end

local function inBoundingBox(box,x,y,z)
	if not box then return false end
	local first, second, start, length, min_x, min_y, min_z, max_x, max_y, max_z = unpack(box)
	if in_range(x, min_x, max_x) and in_range(y, min_y, max_y) and in_range(z, min_z, max_z) then
--		drawBoundingBox(box,COLOR_IN_BB,false)
		if not (first or second) then return true end
		return inBoundingBox(first,x,y,z) or inBoundingBox(second,x,y,z)
	end
	return false
end

addEvent("DL:onVehicleHit", true)
local function check(now)
	if not boundingBoxes then return end
	for vehicle,_ in pairs(vehicles) do
		local x,y,z = getElementPosition( vehicle )
		local box = inBoundingBox(boundingBoxes,x,y,z)
		if box then
			setTimer( triggerServerEvent, 50, 1, "DL:onVehicleHit", localPlayer, getVehicleOccupant(vehicle) )
			setElementHealth( vehicle, 0 )
			setTimer( blowVehicle, 1000, 1, vehicle, true )
		end
	end
end

local function OnClientRender()	
	dxDrawText( string.format("%g, %g", avgFps, fps), 0, 0 )

	local now = getTickCount()
	draw(now)
	check(now)
end
addEventHandler( "onClientRender", root, OnClientRender )

addCommandHandler("dlstart", start)
addCommandHandler("dlstop", stop)
start()
