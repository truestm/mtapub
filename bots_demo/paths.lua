--[[
local events = {}

local function fileOpen(filename)
	return io.open(filename,"rb")
end

local function fileRead(file, size)
	return file:read(size)
end

local function fileGetSize(file)
	local cur = file:seek()
	local size = file:seek("end")
	file:seek("set", cur)
	return size
end

local function fileClose(file)
	file:close()
end

local function addEventHandler(event,element,handler)
	events[event] = handler
end

local function outputDebugString(...)
end
]]

local function bitConverter(data,start,length)
	local p = start + length - 1
	local n = string.byte(data, p)
	while p > start do
		p = p - 1
		n = n * 256 + string.byte(data, p)
	end
	return n
end

local function bitConverterUInt16( data, start )
	return bitConverter(data, start, 2)
end

local function bitConverterInt16( data, start )
	local n = bitConverter(data, start, 2)
	return n <= 0x7fff and n or n - 0x10000
end

local function bitConverterUInt8( data, start )
	return bitConverter(data, start, 1)
end

local function parsePathNode(data, start)
	local x = 0.125 * bitConverterInt16(data, start )
	local y = 0.125 * bitConverterInt16(data, start + 2)
	local z = 0.125 * bitConverterInt16(data, start + 4)
	local n = bitConverterUInt8(data, start + 6)
	local adjacents = {}
	for i=1,n do
		adjacents[i] = bitConverterUInt16(data, start + 5 + i * 2) + 1
	end
	return x, y, z, adjacents, n * 2 + 7
end

local octree

local RANGE_LX = -3000
local RANGE_HX = 3000

local RANGE_LY = -3000
local RANGE_HY = 3000

local function octree_index( x, y, z, lx, hx, ly, hy )
	local cx = 0.5 * (hx + lx)
	local cy = 0.5 * (hy + ly)
	local i
	if x < cx then
		hx = cx
		i = 1
	else
		lx = cx
		i = 2
	end
	if y < cy then
		hy = cy
	else
		ly = cy
		i = i + 2
	end
	return -i, lx, hx, ly, hy
end

local function octree_oct_add( tree, id, x, y, z, lx, hx, ly, hy )
	if hx - lx < 100 then
		tree[#tree + 1] = id
	else
		local i, lx, hx, ly, hy = octree_index( x, y, z, lx, hx, ly, hy )
		if not tree[i] then tree[i] = {} end
		octree_oct_add( tree[i], id, x, y, z, lx, hx, ly, hy )
	end
end

local function octree_add( id, x, y, z )
	octree_oct_add( octree, id, x, y, z, RANGE_LX, RANGE_HX, RANGE_LY, RANGE_HY )
end

local function octree_oct_foreach( tree, x, y, z, r, func, lx, hx, ly, hy )
	if not tree then return end
	if tree[1] then
		for _,nodeId in ipairs(tree) do
			func(nodeId)
		end
	else
		local lrx, hrx  = x - r, x + r
		local lry, hry  = y - r, y + r
		local lrz, hrz  = z - r, z + r
		if lrx < hx and hrx > lx and lry < hy and hry > ly then
			local cx = 0.5 * (hx + lx)
			local cy = 0.5 * (hy + ly)
			octree_oct_foreach( tree[-1], x, y, z, r, func, lx, cx, ly, cy )		
			octree_oct_foreach( tree[-2], x, y, z, r, func, cx, hx, ly, cy )

			octree_oct_foreach( tree[-3], x, y, z, r, func, lx, cx, cy, hy )
			octree_oct_foreach( tree[-4], x, y, z, r, func, cx, hx, cy, hy )
		end
	end
end

function octree_foreach( x, y, z, r, func )
	octree_oct_foreach( octree, x, y, z, r, func, RANGE_LX, RANGE_HX, RANGE_LY, RANGE_HY )
end

local nearest_node, nearest_nodeId, nearest_dist, nearest_x, nearest_y, nearest_z

local function octree_check_nearest( nodeId )
	local x,y,z = get_path_node(nodeId)
	local dx,dy,dz = x - nearest_x, y - nearest_y, z - nearest_z
	local dist = dx*dx + dy*dy + dz*dz
	if dist < nearest_dist then
		nearest_nodeId = nodeId
		nearest_dist = dist
	end
end

function octree_nearest( x, y, z, r )
	nearest_x, nearest_y, nearest_z, nearest_nodeId, nearest_node, nearest_dist = x, y, z, nil, nil, math.huge
	octree_foreach( x, y, z, r, octree_check_nearest )
	return nearest_nodeId, nearest_node, nearest_dist
end

--PATH_NODES = {}
PATH_NODES_X = {}
PATH_NODES_Y = {}
PATH_NODES_Z = {}
PATH_NODES_LINK = {}
PATH_NODES_COUNT = {}
PATH_NODES_LINKS = {}

function get_path_node(nodeId)
	--return PATH_NODES[nodeId][1],PATH_NODES[nodeId][2],PATH_NODES[nodeId][3],#PATH_NODES[nodeId][4]
	return 	PATH_NODES_X[nodeId], PATH_NODES_Y[nodeId], PATH_NODES_Z[nodeId], PATH_NODES_COUNT[nodeId]
end

function get_path_adjacent_node(nodeId, index)
	--return PATH_NODES[nodeId][4][index]
	return PATH_NODES_LINKS[PATH_NODES_LINK[nodeId] + index]
end

function add_path_node(x,y,z,adjacents)
--	local nodeId = #PATH_NODES + 1
--	PATH_NODES[nodeId] = {x,y,z,adjacents}
--	return nodeId
----[[
	local nodeId = #PATH_NODES_X + 1
	local linkIndex = #PATH_NODES_LINKS
	local linkCount = #adjacents
	PATH_NODES_X[nodeId] = x
	PATH_NODES_Y[nodeId] = y
	PATH_NODES_Z[nodeId] = z
	PATH_NODES_LINK[nodeId] = linkIndex
	PATH_NODES_COUNT[nodeId] = linkCount
	for i=1, linkCount do		
		PATH_NODES_LINKS[linkIndex + i] = adjacents[i]
	end
	return nodeId
--]]
end

function load_paths()
	outputDebugString("*** begin load paths")
	local file = fileOpen("ped_paths.bin")
	local size = fileGetSize(file)
	local data = fileRead(file, size)
	fileClose(file)	
	outputDebugString("*** end load paths")
	outputDebugString("*** begin parse paths")
	octree = {}
	PATH_NODES_X = {}
	PATH_NODES_Y = {}
	PATH_NODES_Z = {}
	PATH_NODES_LINK = {}
	PATH_NODES_COUNT = {}
	PATH_NODES_LINKS = {}
	local i = 1
	while i <= size do
		local x, y, z, adjacents, length = parsePathNode(data,i)
		local nodeId = add_path_node(x,y,z,adjacents)
		octree_add( nodeId, x, y, z )
		i = i + length
	end
	outputDebugString("*** end parse paths")
	collectgarbage()
end

--load_paths()