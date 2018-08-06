local tasks = {}
local threads = {}

function async(func)
	return function(...)
		coroutine.resume(coroutine.create(func), ...)
	end
end

function await(repeatable, finish, ...)
	local thread = coroutine.running()
	local task = { thread = thread, repeatable = repeatable, finish = finish, param = {...} }
	local taskid = tostring(task)
	tasks[taskid] = task
	if not threads[thread] then 
		threads[thread] = { [taskid] = task } 
	else
		threads[thread][taskid] = task
	end
	return taskid, task
end

function asyncFinish( task )
	if task then
		local taskid = tostring(task)
		threads[task.thread][taskid] = nil
		if not next(threads[task.thread]) then 
			threads[task.thread] = nil 
		end
		tasks[taskid] = nil
		if task.finish then
			task.finish(unpack(task.param))
			task.finish = nil
			task.param = nil
		end
	else
		local tasks = threads[coroutine.running()]
		while true do
			local task = tasks and next(tasks)
			if not task then return end
			asyncFinish( task )
		end
	end
end

function asyncResume( task )
	if task.repeatable then
		task.result = nil
		task.complete = false
	end
end

function asyncComplete( taskid, ... )
	local task = tasks[taskid]
	task.complete = true
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
	if not task.repeatable then asyncFinish( task ) end
	coroutine.resume(task.thread)
end

function asyncResult(task)
	if task then
		while not task.complete do
			coroutine.yield()
		end
		if task.result then
			if task.repeatable then
				return task.result
			else
				return unpack(task.result)
			end
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

function asyncSleep( time, repeatable )
	local taskid, task = await(repeatable)
	setTimer( asyncComplete, time, repeatable and 0 or 1, taskid )
	return task
end

function asyncDbQueryComplete( handle, taskid )
	asyncComplete( taskid, dbPoll( handle, 0 ) )
end
	
function asyncDbQuery( connection, sql )
	local taskid, task = await()
	dbQuery( asyncDbQueryComplete, { taskid }, connection, sql )
	return task
end

function asyncWaitEvent( event, element, repeatable )
	local handler, taskid, task
	handler = function(...)
		asyncComplete( taskid, client, source, ... )
	end
	taskid, task = await( repeatable, removeEventHandler, event, element, handler )
	addEventHandler( event, element, handler )
	return task
end

addEventHandler("onResourceStart", resourceRoot, async(function(...)
	outputDebugString("async start")	
	
	local connection = dbConnect("sqlite", "testdb.sqlite")
	
	local task0 = asyncDbQuery(connection, "SELECT 1")	
	local task1 = asyncSleep(10000)
	local task2 = asyncSleep(10000)
	local task3 = asyncWaitEvent("onResourceStop", resourceRoot)
	local task4 = asyncWaitEvent("onPlayerJoin", root, true)
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
		asyncResume( task )
	end
	
	asyncFinish()	
	outputDebugString("async end")
end))
