local fps = 0
local avgTime = 0
local avgFrames = 0
local avgFps = 0

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

local screenWidth, screenHeight = guiGetScreenSize();

addEventHandler( "onClientRender", root, 
function()
	local width, height = 128, 48
	local x, y = 0.5 * ( screenWidth - width ), 0
	dxDrawRectangle(x + 1, y + 1, width - 2, height - 2, -2147483648)
	dxDrawText( string.format( "FPS: %3.2f, %3.2f", avgFps, fps), x + 8, y + 8 )
	dxDrawText( string.format( "PING: %d", getPlayerPing (localPlayer)), x + 8, y + 24 )
end)

