-- server side demo
if triggerServerEvent == nil then
	addEventHandler("onResourceStart", resourceRoot, async(function(...)
		outputDebugString("async start")
		
		local connection = dbConnect("sqlite", "testdb.sqlite")
		
		local task0 = asyncDbQuery(connection, "SELECT 1")	
		local task1 = asyncSleep(10000)
		local task2 = asyncSleep(10000)
		local task3 = asyncWaitEvent("onResourceStop", resourceRoot)
		local task4 = asyncWaitEvent("onPlayerJoin", root, nil, true)
		local task5 = asyncSleep(10000, true)
		
		outputDebugString("query result "..tostring(asyncResult(task0)[1]["1"]))
		
		asyncResult(task1)
		outputDebugString("sleep 1 end ")
		
		asyncResult(task2)
		outputDebugString("sleep 2 end ")
				
		asyncSwitch({task4, task5, task3},
			function(client, source)
				outputChatBox( "hello "..tostring(source), source )
			end,
			function(client, source)
				outputDebugString("tick")
			end)
		
		asyncDisposeAll()
		outputDebugString("async end")
	end))
else
-- client side demo
	addCommandHandler( "t", (asyncSingleton(function()
		showCursor( true )
		
		local window  = guiCreateWindow( 0.75, 0.75, 0.25, 0.25, "test", true )
		
		local buttons = 
		{
			{ 0,    0.1,  0.25, 0.25, "1" },
			{ 0.75, 0.1,  0.25, 0.25, "2" },
			{ 0,    0.75, 0.25, 0.25, "3" },
			{ 0.75, 0.75, 0.25, 0.25, "4" }
		}
		-- create four buttons and watcher tasks
		local controls = {}
		local events = {}
		for i,button in ipairs(buttons) do
			local x,y,w,h,text = unpack(button)
			controls[i] = guiCreateButton( x, y, w, h, text, true, window )
			events[i]   = asyncWaitEvent( "onClientGUIClick", controls[i], false, true )
		end
		
		local function buttonClick(client, source, this, button, state, absoluteX, absoluteY)
			outputChatBox( "pressed "..button.." button on "..guiGetText( source ) )
		end
	
		asyncSwitch(events,
			buttonClick,
			buttonClick,
			buttonClick,			
			function(...)
				buttonClick(...)
				return true
			end)
		
		-- release watcher tasks
		asyncDisposeAll()
		
		destroyElement(window)
		
		showCursor( false )
	end)))
end