local area = {}
local values = {}
local max_x = 21
local max_y = 21

local function get_index(x,y)
	return math.floor(x) + math.floor(y) * 65536
end

local function get_xy(index)
	local x = index % 65536
	local y = ( index - x ) / 65536
	return x,y
end

local adj = {
	-1, -1,
	-1,  0,
	-1,  1,
	 0,  1,
	 1,  1,
	 1,  0,
	 1, -1,
	 0, -1
}

local function do_wawe( values, check, wawe, next_wawe )
	local adj_count = #adj
	local result = false
	for index in pairs(wawe) do
		local value = values[index]
		local x0,y0 = get_xy(index)
		for i = 1, adj_count, 2 do
			local x,y = x0 + adj[i], y0 + adj[i + 1]
			if x >= 0 and y >= 0 and x < max_x and y < max_y then
				local delta = check(x0,y0,x,y)
				if delta then
					local next_index = get_index(x,y)
					local prev_value = values[next_index]
					local next_value = value + delta
					if not prev_value or next_value < prev_value then
						values[next_index] = next_value
						next_wawe[next_index] = true
						result = true
					end
				end
			end
		end
		wawe[index] = nil
	end
	return result
end

function find_values( values, check, x, y )
	local index = get_index(x,y)
	values[ index ] = 0
	local wawe, next_wawe = { [index] = 0 }, {}
	while do_wawe( values, check, wawe, next_wawe ) do
		wawe, next_wawe = next_wawe, wawe
	end
end

local function get_min_cell( values, index )
	local x0, y0 = get_xy(index)
	local min_index, min_value
	for i = 1, #adj, 2 do
		local x,y = x0 + adj[i], y0 + adj[i + 1]
		if x >= 0 and y >= 0 and x < max_x and y < max_y then
			local next_index = get_index(x,y)
			local next_value = values[next_index]
			if next_value then
				if not min_value or next_value < min_value then
					min_value = next_value
					min_index = next_index
				end
			end
		end
	end
	return min_index, min_value
end

function get_path( values, x, y )
	local index = get_index(x,y)
	local value = values[index]
	if not value then return end
	local path = {}
	while index do
		path[#path + 1] = index
		if value <= 0 then 
			break
		end
		index, value = get_min_cell( values, index )
	end
	return path
end

local area = {}
local values = {}
local path

local function check( x0,y0, x,y )
	local index = get_index(x,y)
	if not area[index] then
		return getDistanceBetweenPoints2D(x0,y0, x,y)
	end
end
----[[

local startPoint, endPoint

local cellSize = 32
addEventHandler( "onClientRender", root, function()
	local emptyColor = tocolor( 0, 0, 255, 128 )
	local blockColor = tocolor( 255, 0, 0, 128 )
	local pathColor  = tocolor( 0, 0, 0, 128 )
	local startColor = tocolor( 0, 255, 0, 128 )
	
	for y = 0, 20 do 
		for x = 0, 20 do
			local index = get_index(x,y)
			if area[index] then
				dxDrawRectangle( x * cellSize, y * cellSize, cellSize, cellSize, blockColor, true )
			else
				dxDrawRectangle( x * cellSize, y * cellSize, cellSize, cellSize, emptyColor, true )
			end
			if values[index] then
				dxDrawText( string.format("%.1f", values[index]), x * cellSize, y * cellSize, x * cellSize + cellSize, y * cellSize + cellSize )
			end
			if startPoint and startPoint[1] == x and startPoint[2] == y then
				dxDrawRectangle( x * cellSize, y * cellSize, cellSize, cellSize, startColor, true )
			end
		end
	end	
	if path then
		for _,index in ipairs(path) do 
			local x,y = get_xy(index)
			dxDrawRectangle( x * cellSize, y * cellSize, cellSize, cellSize, pathColor, true )
		end	
	end
end)

local blockOn

addEventHandler( "onClientClick", root, function( button, state, absoluteX, absoluteY)
	local x,y = math.floor(absoluteX / cellSize), math.floor( absoluteY / cellSize )
	if x < 21 and y < 21 and state == "down" then
		if button == "left" then
			if not endPoint then
				if not startPoint then
					startPoint = {x,y}
				else
					endPoint = {x,y}
					values = {}
					find_values( values, check, startPoint[1], startPoint[2] )
					path = get_path( values, x, y )
					startPoint = nil
					endPoint = nil
				end
			end
		elseif button == "right" then
			local index = get_index(x,y)
			area[index] = not area[index]
		end
	end
end)

addEventHandler( "onClientMouseMove", root, function ( x, y )
end)

showCursor(true)
--]]
--[[
area = 
{
	[0x00000] = false, [0x00001] = false, [0x00002] = false,
	[0x10000] = false, [0x10001] = false, [0x10002] = false,
	[0x20000] = false, [0x20001] = false, [0x20002] = false,
}
values = {}
find_values( values, check, 0, 0 )
path = get_path( values, 2, 2 )
--]]