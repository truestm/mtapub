local tasks = {}
local threads = {}
local watch = {}

function async(func)
	return function(...)
		coroutine.resume(coroutine.create(func), ...)
	end
end

local function asyncTaskSetDispose( task, dispose, ... )
	task.dispose = dispose
	task.param = {...}
end

local function asyncTaskSetLink( thread, taskid, task )
	tasks[taskid] = task
	if task then
		if not threads[thread] then 
			threads[thread] = { [taskid] = task } 
		else
			threads[thread][taskid] = task
		end
	else
		if threads[thread] then
			threads[thread][taskid] = nil
			if not next( threads[thread] ) then
				threads[thread] = nil
			end
		end
	end
end

local function asyncTaskSetResult( task, ... )
	if select( "#", ... ) > 0 then
		if task.repeatable then
			if not task.result then 
				task.result = { {...} }
			else
				task.result[ #task.result + 1 ] = { ... }
			end
		else
			task.result = {...}
		end
	end
end

function asyncTask( repeatable, dispose, ...)
	local thread = coroutine.running()
	local task = { thread = thread, repeatable = repeatable }
	local taskid = tostring(task)
	asyncTaskSetDispose( task, dispose, ... )
	asyncTaskSetLink( thread, taskid, task )
	return taskid, task
end

function asyncDispose( task )
	if task then
		local taskid = tostring(task)
		asyncTaskSetLink( task.thread, taskid, nil )
		if task.dispose then
			task.dispose(unpack(task.param))
			task.dispose = nil
			task.param = nil
		end
	end
end

function asyncDisposeAll()
	local thread = coroutine.running()
	while threads[thread] do
		local taskid, task = next(threads[thread])
		if taskid then
			asyncDispose( task )
		end
	end
end

function asyncContinue( task )
	if task.repeatable then
		task.result = nil
		task.complete = false
	end
end

function asyncComplete( taskid, ... )
	local task = tasks[taskid]
	task.complete = true
	asyncTaskSetResult( task, ... )
	local thread = watch[task]
	if not task.repeatable then 
		asyncDispose( task ) 
	end
	if thread then 
		coroutine.resume( thread ) 
	end
end

function asyncResult( task )	
	asyncWaitAny( task )
	if task.result then
		local result = task.result
		if task.repeatable then	
			asyncContinue( task )
			return result
		else
			return unpack(result)
		end
	end
end

function asyncIsComplete(task)
	return task.complete
end

local function watchTask( thread, ... )
	for i = 1, select("#",...) do
		local task = select(i,...)
		watch[task] = thread
	end
end

local function checkTask( condition, ...)
	for i = 1, select("#",...) do
		local task = select(i,...)
		if task.complete == condition then return task end
	end
end

function asyncWaitAny(...)
	local task = checkTask(true, ...)
	if not task then 
		watchTask(coroutine.running(), ...)
		repeat
			coroutine.yield()
			task = checkTask(true, ...)
		until task
		watchTask(nil, ...)
	end
	return task
end

function asyncWaitAll(...)
	local task = checkTask(false, ...)
	if task then 
		watchTask(coroutine.running(), ...)
		repeat
			coroutine.yield()
			task = checkTask(false, ...)
		until not task
		watchTask(nil, ...)
	end
end

function asyncSleep( time, repeatable )
	local taskid, task = asyncTask( repeatable )
	local timer = setTimer( asyncComplete, time, repeatable and 0 or 1, taskid )	
	asyncTaskSetDispose( task, killTimer, timer )
	return task
end

function asyncDbQueryComplete( handle, taskid )
	asyncComplete( taskid, dbPoll( handle, 0 ) )
end
	
function asyncDbQuery( connection, sql )
	local taskid, task = asyncTask()
	dbQuery( asyncDbQueryComplete, { taskid }, connection, sql )
	return task
end

function asyncWaitEvent( event, element, propagated, repeatable )
	local handler, taskid, task
	handler = function(...)
		asyncComplete( taskid, client, source, ... )
	end
	taskid, task = asyncTask( repeatable, removeEventHandler, event, element, handler )
	addEventHandler( event, element, handler, propagated )
	return task
end

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
				
		while not asyncIsComplete( task3 ) do		
			local task = asyncWaitAny( task3, task4, task5 )
			if task == task4 then
				for _,result in ipairs(asyncResult( task )) do
					local client, source = unpack(result)
					outputChatBox( "hello "..tostring(source), source )
				end
			elseif task == task5 then
				outputDebugString("tick")
			end
			asyncContinue( task )
		end
		
		asyncDisposeAll()
		outputDebugString("async end")
	end))
else
-- client side demo
	addCommandHandler( "t", async(function()
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
		
		local clicked
		repeat
			-- wait any button click
			clicked = asyncWaitAny( unpack(events) )
			
			-- commonly one event returned but in generic case may be several
			for _,result in ipairs( asyncResult(clicked) ) do
				
				-- get click event arguments
				local client, source, button, state, absoluteX, absoluteY = unpack( result )
				
				local text = guiGetText( source )
				
				outputChatBox( "pressed "..button.." button on:"..text )
			end
		-- exit if button 4 clicked
		until clicked == events[#events]
		
		-- release watcher tasks
		asyncDisposeAll()
		
		destroyElement(window)
		
		showCursor( false )
	end))
end