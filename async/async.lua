local tasks = {}
local threads = {}
local watch = {}

function async(func)
	return function(...) asyncCall( func, ... ) end
end

function asyncCall(func, ...)
	coroutine.resume( coroutine.create(func), ... )
end

function asyncTaskSetDispose( task, dispose, ... )
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

local function asyncTaskSetResult( task, override, ... )
	local count = select( "#", ... )
	if count > 0 then
		if task.repeatable then
			if not task.result then 
				task.result = { {...} }
			else
				if override then
					for i = 1, count do task.result[#task.result][i] = select( i, ... ) end
				else
					task.result[ #task.result + 1 ] = { ... }
				end
			end
		else
			if not task.result then
				task.result = {...}
			else
				for i = 1, count do task.result[i] = select( i, ... ) end
			end
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

function asyncDisposeAll(thread)
	if not thread then thread = coroutine.running() end
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
	asyncTaskSetResult( task, false, ... )
	local thread = watch[task]
	if not task.repeatable then 
		asyncDispose( task ) 
	end
	if thread then 
		coroutine.resume( thread ) 
	end
end

function asyncCompleteOverride( taskid, ... )
	local task = tasks[taskid]
	task.complete = true
	asyncTaskSetResult( task, true, ... )
	local thread = watch[task]
	if not task.repeatable then 
		asyncDispose( task ) 
	end
	if thread then 
		coroutine.resume( thread ) 
	end
end

function asyncTaskGet( taskid )
	return taskid and tasks[taskid] or nil
end

function asyncTaskLastResult( taskid )
	local task = tasks[taskid]
	local result = task.result
	task.result = nil
	if result then
		if task.repeatable then
			return unpack(result[#result])
		else
			return unpack(result)
		end
	end
end

function asyncResult( task )
	if not task.complete then
		watch[task] = coroutine.running()
		repeat
			coroutine.yield()
		until task.complete
		watch[task] = nil
	end
	local result = task.result
	if task.repeatable then	
		asyncContinue( task )
		return result
	else
		if result then 
			return unpack(result) 
		end
	end
end

function asyncIsComplete(task)
	return task.complete
end

local function watchTask( thread, tasks )
	for index,task in pairs(tasks) do
		watch[task] = thread
	end
end

local function checkTask( condition, tasks )
	for index,task in pairs(tasks) do
		if task.complete == condition then 
			return task,index 
		end
	end
end

function asyncWaitAny( tasks )
	local task,index = checkTask( true, tasks )
	if not task then 
		watchTask( coroutine.running(), tasks )
		repeat
			coroutine.yield()
			task,index = checkTask( true, tasks )
		until task
		watchTask( nil, tasks )
	end
	return task,index
end

function asyncWaitAll( tasks )
	if not tasks then tasks = threads[ coroutine.running() ] end
	local task = checkTask(false, tasks )
	if task then 
		watchTask(coroutine.running(), tasks)
		repeat
			coroutine.yield()
			task = checkTask(false, tasks)
		until not task
		watchTask(nil, tasks)
	end
end

function asyncSwitch(tasks,...)
	while true do
		local task, index = asyncWaitAny( tasks )
		local handler = select(index,...)
		if task.repeatable then
			local results = asyncResult( task )
			if results then
				for _,result in ipairs(results) do
					if handler then
						result = handler(unpack(result))
						if result ~= nil then
							return index, result
						end					
					end
				end
			elseif handler then 
				result = handler()
				if result ~= nil then
					return index, result
				end					
			end
		else
			if handler then
				return index, handler(asyncResult( task ))
			else
				return index, asyncResult( task )
			end
		end
	end
end
