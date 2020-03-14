local primitive = { calculate = {}, draw = {} }

local function getValue(value, ...)
	if type(value) == "function" then
		return value(...)
	end
	return value
end

local function getItemPosition(item)
	local x,y,w,h = getValue(item.x) or 0, getValue(item.y) or 0, getValue(item.w) or 1, getValue(item.h) or 1
	if item.p then
		local p = getValue(item.p)
		local l = getValue(item.l) or 1
		local cos = p and math.cos( math.rad( p ) ) or 1
		local sin = p and math.sin( math.rad( p ) ) or 0
		x = x + cos * l
		y = y + sin * l
	end	
	return x,y,w,h
end

local function getAbsPosition( parent_x, parent_y, parent_w, parent_h, x, y, w, h)
	return x * parent_w, y * parent_h, w * parent_w, h * parent_h
end

local function getVertices( parent_x, parent_y, parent_w, parent_h, x, y, w, h, r, input, output )
	local cos = r and math.cos( math.rad( r ) ) or 1
	local sin = r and math.sin( math.rad( r ) ) or 0
	x = parent_x + x * parent_w
	y = parent_y + y * parent_h
	for k,vert in ipairs(input) do
		local vx, vy, c, u, v = unpack(vert)
		vx, vy = vx * w, vy * h
		local tx, ty = x + ( vx * cos - vy * sin ) * parent_w, y + ( vx * sin + vy * cos ) * parent_h
		if output[k] then
			output[k][1] = tx
			output[k][2] = ty
			output[k][3] = c
			output[k][4] = u
			output[k][5] = v
		else
			output[k] = { tx, ty, c, u, v }
		end
	end
end

function primitive.calculate.text( item, cache, parent_x, parent_y, parent_w, parent_h )
	local x,y,w,h = getAbsPosition( parent_x, parent_y, parent_w, parent_h, getItemPosition(item))
	local hw, hh = w * 0.5, h * 0.5
	cache[1] = getValue(item.text)
	cache[2] = parent_x + x - hw
	cache[3] = parent_y + y - hh
	cache[4] = parent_x + x + hw
	cache[5] = parent_y + y + hh
	cache[6] = getValue(item.font)
	cache[7] = getValue(item.r) or 0
	cache[8] = x
	cache[9] = y
	return x,y,w,h
end

function primitive.draw.text( text, xl, yl, xh, yh, font, r, rx, ry )
	dxDrawText( text, xl, yl, xh, yh,
		nil, --color, 
		1, --scaleXY
		font, --font
		"center", --alignX
		"center", --alignY, 
		true, --clip
		false, --wordBreak,
		false, --postGUI, 
		false, --colorCoded, 
		false, --subPixelPositioning,
		r, --fRotation,
		rx, --fRotationCenterX, 
		ry  --fRotationCenterY
	)
end

function primitive.calculate.primitive( item, cache, parent_x, parent_y, parent_w, parent_h )
	local x,y,w,h = getItemPosition( item )
	cache[1] = getValue(item.type)
	if not cache[2] then cache[2] = {} end
	getVertices( parent_x, parent_y, parent_w, parent_h, x, y, w, h, getValue(item.r), getValue(item.v), cache[2] )
	return getAbsPosition( parent_x, parent_y, parent_w, parent_h, x,y,w,h )
end

function primitive.draw.primitive( primitiveType, vertices )
	dxDrawPrimitive( primitiveType, false, unpack(vertices) )	
end

function primitive.calculate.rect( item, cache, parent_x, parent_y, parent_w, parent_h )
	local x,y,w,h = getAbsPosition( parent_x, parent_y, parent_w, parent_h, getItemPosition( item ) )
	cache[1], cache[2], cache[3], cache[4], cache[5] = parent_x + x, parent_y + y, w, h, getValue(item.c)
	return x,y,w,h
end

function primitive.draw.rect( x, y, w, h, c )
	dxDrawRectangle( x, y, w, h, c, false, false )
end

function primitive.prepare_function_item( func, index, cache, x, y, w, h )
	local iterator,item
	repeat
		iterator,item = func(iterator)
		if not cache[index] then cache[index] = {} end
		primitive.prepare_item( item, cache[index], x, y, w, h )
		index = index + 1
	until not iterator
	return index
end

function primitive.prepare( items, cache, x, y, w, h )
	if not cache then cache = {} end
	if not ( x and y and w and h ) then
		x, y = 0, 0
		w, h = guiGetScreenSize()
	end
	if type(items) == "function" then
		primitive.prepare_function_item( items, 1, cache, x, y, w, h )
	else
		local index = 1
		for i,item in ipairs(items) do
			if not cache[index] then cache[index] = {} end
			if type(item) == "function" then
				index = primitive.prepare_function_item( item, index, cache, x, y, w, h )
			else
				primitive.prepare_item( item, cache[index], x, y, w, h )
				index = index + 1
			end
		end
	end
	return cache
end

function primitive.prepare_item( item, cache, parent_x, parent_y, parent_w, parent_h )
	cache[1] = getValue(item.static) ~= false
	cache[2] = item
	cache[3] = {parent_x, parent_y, parent_w, parent_h}
	cache[4] = primitive.draw[item[1]]
	if not cache[5] then cache[5] = {} end
	local x,y,w,h = primitive.calculate[ item[1] ]( item, cache[5], parent_x, parent_y, parent_w, parent_h )
	if item[2] then
		if not cache[6] then cache[6] = {} end
		primitive.prepare( item[2], cache[6], x,y,w,h )
	end
end

function primitive.render( itemsCache, updated )
	if itemsCache then
		for i,cache in ipairs(itemsCache) do
			local childsUpdated = updated
			if not ( childsUpdated or cache[1] ) then
				primitive.prepare_item( cache[2], cache, unpack(cache[3]) )
				childsUpdated = true
			end
			cache[4](unpack(cache[5]))
			primitive.render(cache[6], childsUpdated)
		end
	end
end

local speedometer = primitive.prepare({
	{ "rect", x = 0.75, y = 0.3, w = 0.125, h = 0.2, c = tocolor(0,0,0,128),
		{
			function(i)
				if not i then i = 0 end
				return i < 9 and i + 1, 
					{ "text", x = 0.5, y = 0.5, p = i * 30 - 45, l = -0.4, w = 0.25, h = 0.25, font = "pricedown", text = tostring(i) }
			end,
			{ "primitive", type = "trianglestrip", x = 0.5, y = 0.5, w = 0.35, h = 0.03, static = false,
				r = function()
					return getDistanceBetweenPoints3D(0,0,0, getElementVelocity(getPedOccupiedVehicle( localPlayer ) or localPlayer)) * 
						300 / getAircraftMaxVelocity() + 135
				end,
				v = { 
					{ 0, -1, tocolor(255,255,255) },
					{ 1,  0, tocolor(255,255,255) }, 
					{ 0,  1, tocolor(255,255,255) }
				} 			
			},
			{ "text", x = 0.5, y = 0.8, w = 0.5, h = 0.2, font = "pricedown", static = false,
				text = function()
					local element = getPedOccupiedVehicle( localPlayer ) or localPlayer
					return tostring(math.floor(100 * getDistanceBetweenPoints3D(0,0,0, getElementVelocity( element ))))
				end 
			}
		}
	}
})

addEventHandler( "onClientRender", root, function()
	primitive.render( speedometer )
end)
