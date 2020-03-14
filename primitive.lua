local primitive = { calculate = {}, draw = {}, refresh = true }

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
	return parent_x + x * parent_w, parent_y + y * parent_h, w * parent_w, h * parent_h
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
	cache[2] = x - hw
	cache[3] = y - hh
	cache[4] = x + hw
	cache[5] = y + hh
	cache[6] = getValue(item.font)
	cache[7] = getValue(item.r) or 0
	cache[8] = x - parent_x
	cache[9] = y - parent_y
	return x,y,w,h
end

function primitive.draw.text( childs, updated, text, xl, yl, xh, yh, font, r, rx, ry )
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
	primitive.render( childs, updated )
end

function primitive.calculate.primitive( item, cache, parent_x, parent_y, parent_w, parent_h )
	local x,y,w,h = getItemPosition( item )
	cache[1] = getValue(item.type)
	if not cache[2] then cache[2] = {} end
	getVertices( parent_x, parent_y, parent_w, parent_h, x, y, w, h, getValue(item.r), getValue(item.v), cache[2] )
	return getAbsPosition( parent_x, parent_y, parent_w, parent_h, x,y,w,h )
end

function primitive.draw.primitive( childs, updated, primitiveType, vertices )
	dxDrawPrimitive( primitiveType, false, unpack(vertices) )
	primitive.render( childs, updated )
end

function primitive.calculate.rect( item, cache, parent_x, parent_y, parent_w, parent_h )
	local x,y,w,h = getAbsPosition( parent_x, parent_y, parent_w, parent_h, getItemPosition( item ) )
	cache[1], cache[2], cache[3], cache[4], cache[5] = x, y, w, h, getValue(item.c)
	return x,y,w,h
end

function primitive.draw.rect( childs, updated, x, y, w, h, c )
	dxDrawRectangle( x, y, w, h, c, false, false )
	primitive.render( childs, updated )
end

function primitive.calculate.block( item, cache, parent_x, parent_y, parent_w, parent_h )
	local x,y,w,h = getAbsPosition( parent_x, parent_y, parent_w, parent_h, getItemPosition( item ) )
	w, h = math.floor( w ), math.floor( h )
	cache[1], cache[2], cache[3], cache[4] = x, y, w, h
	if getValue(item.buffered) then
		if not cache[5] then 
			cache[5] = assert(dxCreateRenderTarget( w, h, true ))
		else
			local rw,rh = dxGetMaterialSize( cache[5] )
			if rw ~= w or rh ~= h then
				destroyElement( cache[5] )
				cache[5] = assert(dxCreateRenderTarget( w, h, true ))
			end
		end
		return 0,0,w,h
	end
	return x,y,w,h
end

function primitive.draw.block( childs, updated, x, y, w, h, rt )
	if rt then
		if updated or primitive.refresh then
			dxSetRenderTarget( rt, true )
			dxSetBlendMode("modulate_add")
			primitive.render( childs, updated )
			dxSetBlendMode("blend")
			dxSetRenderTarget()
		end
		dxSetBlendMode("add")
		dxDrawImage( x, y, w, h, rt )
		dxSetBlendMode("blend")
	else
		primitive.render( childs, updated )
	end
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
	if not cache[3] then cache[3] = {} end
	cache[3][1] = parent_x
	cache[3][2] = parent_y
	cache[3][3] = parent_w
	cache[3][4] = parent_h
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
			cache[4](cache[6], childsUpdated, unpack(cache[5])) 
		end
	end
end

local currentSpeed, currentHours, currentMinutes, currentDir = 0, 0, 0, 0
local arrowVertices = { 
	{ 0, -1, tocolor(255,255,255) },
	{ 1,  0, tocolor(255,255,255) }, 
	{ 0,  1, tocolor(255,255,255) }
}

local speedometer = primitive.prepare({
	{ "rect", x = 1 - 0.125 - 0.0625, y = 0.3, w = 0.125 + 0.0625, h = 0.2, c = tocolor(0,0,0,128),
		{
			{ "block", x = 0, y = 0, w = 0.66, h = 1, 
				{
					{ "block", buffered = true, 
						function(i)
							if not i then i = 0 end
							return i < 9 and i + 1, 
								{ "text", x = 0.5, y = 0.5, p = i * 30 - 45, l = -0.4, w = 0.25, h = 0.25, font = "pricedown", text = tostring(i) }
						end
					},
					{ "primitive", type = "trianglestrip", x = 0.5, y = 0.5, w = 0.35, h = 0.03, static = false,
						r = function() return currentSpeed * 300 / getAircraftMaxVelocity() + 135 end,
						v = arrowVertices		
					},
					{ "text", x = 0.5, y = 0.8, w = 0.5, h = 0.2, font = "pricedown", static = false,
						text = function() return tostring(math.floor(100 * currentSpeed)) end 
					}
				}
			},
			{ "block", x = 0.66, y = 0, w = 0.33, h = 0.5, 
				{
					{ "block", buffered = true, 
						function(i)
							if not i then i = 0 end
							return i < 11 and i + 1, 
								{ "text", x = 0.5, y = 0.5, p = i * 30 + 120, l = -0.4, w = 0.25, h = 0.25, font = "default", text = tostring(i + 1) }
						end
					},
					{ "primitive", type = "trianglestrip", x = 0.5, y = 0.5, w = 0.35, h = 0.02, static = false,
						r = function() return currentMinutes * 6 end,
						v = arrowVertices 			
					},
					{ "primitive", type = "trianglestrip", x = 0.5, y = 0.5, w = 0.25, h = 0.02, static = false,
						r = function() return currentHours * 30 + currentMinutes * 0.5 end,
						v = arrowVertices		
					}
				}
			},
			{ "block", x = 0.66, y = 0.5, w = 0.33, h = 0.5, 
				{
					{ "block", buffered = true,
						{ 
							{ "text", x = 0.5, y = 0.5, p = 0,   l = 0.4, w = 0.25, h = 0.25, font = "default", text = "E" },
							{ "text", x = 0.5, y = 0.5, p = 90,  l = 0.4, w = 0.25, h = 0.25, font = "default", text = "S" },
							{ "text", x = 0.5, y = 0.5, p = 180, l = 0.4, w = 0.25, h = 0.25, font = "default", text = "W" },
							{ "text", x = 0.5, y = 0.5, p = 270, l = 0.4, w = 0.25, h = 0.25, font = "default", text = "N" }
						}
					},
					{ "primitive", type = "trianglefan", x = 0.5, y = 0.5, w = 0.5, h = 0.2, static = false,
						r = function() return 270 - currentDir end,
						v = { 
							{  0.5,    0, tocolor(255,255,255) },
							{ -0.5, -0.5, tocolor(255,255,255) }, 
							{ -0.3,    0, tocolor(255,255,255) }, 
							{ -0.5,  0.5, tocolor(255,255,255) }
						}
					}
				}
			}
		}
	}
})

local show = true

bindKey("f4", "down", function()
	show = not show
end)

addEventHandler( "onClientRender", root, function()
	if show then
		local element = getPedOccupiedVehicle( localPlayer ) or localPlayer
		currentHours, currentMinutes = getTime()	
		currentSpeed    = getDistanceBetweenPoints3D(0,0,0, getElementVelocity(element))
		_,_, currentDir = getElementRotation(element)
		primitive.render( speedometer )
		primitive.refresh = false
	end
end)

addEventHandler("onClientRestore", root, function( didClearRenderTargets )
	--if didClearRenderTargets then
		primitive.refresh = true
	--end
end)