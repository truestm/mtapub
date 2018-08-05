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

function asyncComplete(taskid, ...)
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
		return unpack(task.result)
	else
		while threads[coroutine.running()] do
			coroutine.yield()
		end
	end
end

function asyncTimer( taskid, callback, time, iteration, ... )
	setTimer( callback, time, iteration, taskid, ... )
end

function asyncDbQuery( taskid, connection, sql )
	dbQuery( asyncDbQueryComplete, { taskid }, connection, sql )
end

function asyncDbQueryComplete( handle, taskid )
	asyncComplete( taskid, dbPoll( handle, 0 ) )
end

--[[
-- EXAMPLE:

addEventHandler("onResourceStart", resourceRoot, async(function(...)
	outputDebugString("async start "..tostring(getTickCount()))	
	
	local connection = dbConnect("sqlite", "data/game.dynamic.sqlite")
	
	local r0 = await(asyncDbQuery, connection, "SELECT 1")
	
	local r1 = await(asyncTimer, function(taskid) asyncComplete(taskid, getTickCount()) end, 10000, 1)
	local r2 = await(asyncTimer, function(taskid) asyncComplete(taskid, getTickCount()) end, 10000, 1)
	
	iprint(asyncResult(r0))
	
	outputDebugString("async end "..tostring(asyncResult(r1))..","..tostring(asyncResult(r2)))
end))
]]