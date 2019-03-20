local fps = 0
local avgTime = 0
local avgFrames = 0
local avgFps

addEventHandler("onClientPreRender", root, 
function( timeSlice )
    fps = ( 1 / timeSlice ) * 1000
	avgFrames = avgFrames + 1
	avgTime = avgTime + timeSlice
	if avgTime > 10000 then
		avgFps = avgFrames / avgTime * 1000
		avgFrames = 0
		avgTime = 0
	end
end)

local realTime = { hour = 0, minute = 0, second = 0 }
local ping = 0
local maxPing = 200
local colors = { tocolor(255,0,0), tocolor(255,192,0), tocolor(255,255,0), tocolor(192,255,0), tocolor(0,255,0) }
local pingColor, fpsColor = 0,0

local function getColor( value, maxValue )	
	if maxValue > 0 then
		return colors[math.min( math.floor( value * #colors / maxValue ), #colors - 1 ) + 1]
	else
		return colors[#colors - math.min( math.floor( value * #colors / -maxValue ), #colors )]
	end
end

setTimer(function()
	realTime = getRealTime()
	ping = getPlayerPing(localPlayer)
	pingColor = getColor( ping, -maxPing )
	fpsColor  = getColor( avgFps or fps or 0, getFPSLimit() * 1.125 )
end, 1000, 0)

local screenWidth, screenHeight = guiGetScreenSize()

local function drawMetrix( x, y, name, value, color )
	if color then dxDrawRectangle( x, y, 4, 14, color ) end
	dxDrawText( name,  x + 8, y )	
	dxDrawText( value, x + 48, y )
end

addEventHandler( "onClientRender", root, 
function()
	local width, height = 128, 56
	local x, y = 0.5 * ( screenWidth - width ), 0
	dxDrawRectangle(x + 1, y + 1, width - 2, height - 2, -2147483648)
	drawMetrix( x + 2, y + 4,  "FPS:",  string.format( "%3.2f, %3.2f", avgFps or fps or 0, fps ), fpsColor )
	drawMetrix( x + 2, y + 20, "PING:", string.format( "%d", ping ), pingColor )
	drawMetrix( x + 2, y + 36, "TIME:", string.format( "%02d:%02d:%02d", realTime.hour, realTime.minute, realTime.second ) )
end)

