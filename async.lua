local tasks = {}
local threads = {}

function async(func)
	return function(...)
		coroutine.resume(coroutine.create(func), ...)
	end
end

function await(func, ...)
	local thread = coroutine.running()
	local task = { thread = thread }
	local taskid = tostring(task)
	tasks[taskid] = task
	if not threads[thread] then 
		threads[thread] = { [taskid] = task } 
	else
		threads[thread][taskid] = task
	end
	func(taskid, ...)
	return task
end

function asyncComplete( taskid, ... )
	local task = tasks[taskid]
	task.result = {...}
	task.complete = true
	threads[task.thread][taskid] = nil
	if not next(threads[task.thread]) then 
		threads[task.thread] = nil 
	end
	tasks[taskid] = nil
	coroutine.resume(task.thread)
end

function asyncResult(task)
	if task then
		while not task.complete do
			coroutine.yield()
		end
		if task.result then 
			return unpack(task.result) 
		end
	else
		while threads[coroutine.running()] do
			coroutine.yield()
		end
	end
end

function asyncIsComplete(task)
	return task.complete
end

function asyncWaitAny(...)
	local count = select("#",...)
	while true do
		for i = 1,count do 
			local task = select(i,...)
			if task.complete then return task end
		end
		coroutine.yield()
	end
end

function asyncWaitAll(...)
	local complete
	repeat
		complete = true
		for i=1,select("#",...) do 
			local task = select(i,...)
			if not task.complete then
				complete = false
				break
			end
		end
		coroutine.yield()
	until complete
end

function asyncSleepStart( taskid, time )
	setTimer( asyncComplete, time, 1, taskid )
end

function asyncSleep( time )
	return await(asyncSleepStart, time)
end

function asyncDbQueryComplete( handle, taskid )
	asyncComplete( taskid, dbPoll( handle, 0 ) )
end
	
local function asyncDbQueryStart( taskid, connection, sql )
	dbQuery( asyncDbQueryComplete, { taskid }, connection, sql )
end

function asyncDbQuery( connection, sql )
	return await( asyncDbQueryStart, connection, sql )
end

local function asyncWaitEventStart( taskid, event, element )
	local handler
	handler = function(...)
		removeEventHandler( event, element, handler )
		asyncComplete( taskid, client, source, ... )
	end
	addEventHandler( event, element, handler )
end

function asyncWaitEvent( event, element )
	return await( asyncWaitEventStart, event, element )
end

addEventHandler("onResourceStart", resourceRoot, async(function(...)
	outputDebugString("async start")	
	
	local connection = dbConnect("sqlite", "testdb.sqlite")
	
	local task0 = asyncDbQuery(connection, "SELECT 1")	
	local task1 = asyncSleep(10000)
	local task2 = asyncSleep(10000)
	local task3 = asyncWaitEvent("onResourceStop", resourceRoot)
	
	outputDebugString("query result "..tostring(asyncResult(task0)[1]["1"]))
	
	asyncResult(task1)
	outputDebugString("sleep 1 end ")
	
	asyncResult(task2)
	outputDebugString("sleep 2 end ")
	
	while not asyncIsComplete( task3 ) do
		
		local task4 = asyncWaitEvent("onPlayerJoin", root)
		
		if asyncWaitAny( task3, task4 ) == task4 then
			local client, source = asyncResult( task4 )
			outputChatBox( "hello "..tostring(source), source )
		end
	end
	
	outputDebugString("async end")
end))
