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

addEventHandler( "onClientRender", root, 
function()
	dxDrawText( string.format("%g, %g", avgFps, fps), 0, 0 )
end)

