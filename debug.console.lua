local scripts = {}
local results = {}

local filename = "debug.expressions.json"
local debugWindow

addEvent("onClientGUIChildUpdated")

local function packResult( result, ... )
	return result, {...}
end

local function runScript( script )
	local chunk,message = loadstring(script)
	if not chunk then
		return false,message
	end
	return packResult(pcall(chunk))
end

local function writeScripts( filename, scripts )
	local file = fileCreate(filename)
	if not file then return false end
	local result = fileWrite(file, toJSON(scripts))
	fileClose(file)
	return result
end

local function readScripts( filename )
	local file = fileExists(filename) and fileOpen(filename)
	if not file then return {} end
	local scripts = fromJSON(fileRead(file, fileGetSize(file)))
	fileClose(file)
	return scripts
end

local function getBounds( elements )
	local bounds = {}
	for i,element in ipairs(elements) do
		local x,y = guiGetPosition( element, true )
		local w,h = guiGetSize( element, true )
		local childs = getBounds(getElementChildren(element))
		bounds[i] = { x,y,w,h,childs }
	end
	return bounds
end

local function setBounds( elements, bounds )
	for i,element in ipairs(elements) do
		local x,y,w,h,childs = unpack(bounds[i])
		guiSetPosition( element, x, y, true )
		guiSetSize( element, w, h, true )
		setBounds( getElementChildren(element), childs )
	end
end

local function createConsoleTab( name, script, window )
	local tab = guiCreateTab( name, getElementChild( window, 0 ) )
	local expression = guiCreateMemo( 0, 0, 1, 0.5, script, true, tab )
	local success,value = runScript( script )
	results[name] = success and value
	local result     = guiCreateMemo( 0, 0.5, 1, 0.4, inspect(value),  true, tab )
	local button     = guiCreateButton( 0, 0.9, 1, 0.1, "Update", true, tab )
	addEventHandler( "onClientGUIClick", button, function()
		local script = guiGetText(expression)
		local success,value = runScript( script )
		guiSetText(result, inspect(value))
		results[name] = success and value
		scripts[name] = script
		writeScripts( filename, scripts )
	end, false)
	triggerEvent("onClientGUIChildUpdated", tab)
end

local function createConsole( x, y, w, h )
	scripts = readScripts( filename )
	local window = guiCreateWindow( x, y, w, h, "Debug", true )
	local tabs = guiCreateTabPanel( 0, 0.1, 1, 0.9, true, window )
	local bounds
	addEventHandler( "onClientGUIChildUpdated", window, function()
		bounds = getBounds(getElementChildren(window))
	end)
	addEventHandler( "onClientGUISize", window, function()
		setBounds(getElementChildren(window), bounds)
	end, false)
	createConsoleTab( "default", scripts["default"], window )
	showCursor( true )
	return window, tabs
end

addEventHandler("onClientKey", root, function(key, press)
	if key == "F12" and press then
		if not debugWindow then
			debugWindow = createConsole( 0, 0, 0.25, 0.25 )
		else
			local visible = not guiGetVisible( debugWindow )
			showCursor( visible )
			guiSetVisible( debugWindow, visible )
		end
	end
end)

function debugCon(name, script)
	if not debugWindow then
		debugWindow = createConsole( 0, 0, 0.25, 0.25 )
	end
	if results[name] == nil then
		createConsoleTab( name, scripts["name"] or script, debugWindow )
	end
	if results[name] then
		return unpack(results[name])
	end
end

