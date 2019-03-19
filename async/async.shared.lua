function asyncSleep( time, repeatable )
	local taskid, task = asyncTask( repeatable )
	local timer = setTimer( asyncComplete, time, repeatable and 0 or 1, taskid )	
	asyncTaskSetDispose( task, killTimer, timer )
	return task
end

function asyncWaitEvent( event, element, propagated, repeatable, complete )
	local handler, taskid, task
	handler = function(...)
		if complete then
			complete( taskid, client, source, this, ...  )
		else
			asyncComplete( taskid, client, source, this, ... )
		end
	end	
	taskid, task = asyncTask( repeatable, removeEventHandler, event, element, handler )
	addEventHandler( event, element, handler, propagated )
	addEventHandler( triggerServerEvent == nil and "onElementDestroy" or "onClientElementDestroy", 
		element, function() asyncDispose(task) end, false )
	return task
end

function asyncClientSingleton(func, busy, dispose)
    local threads = {}
    return
		function(...)
			if threads[client] then
				if busy then return busy(client, source, this, ...) end
				return
			end
			threads[client] = coroutine.create(function(client, source, this, ...)
				func(client, source, this, ...)
				threads[client] = nil
			end)
			assert(coroutine.resume(threads[client], client, source, this, ... ))
		end,
		function()
			if threads then
				for client,thread in pairs(threads) do
					if dispose then dispose(thread, client) end
					threads[client] = nil
				end
			end
		end
end

function asyncSingleton(func, busy, dispose)
    local thread
    return
		function(...)
			if thread then
				if busy then return busy(client, source, this, ...) end
			return
			end
			thread = coroutine.create(function(client, source, this, ...)
				func(client, source, this, ...)
				thread = nil
			end)
			assert(coroutine.resume(thread, client, source, this, ... ))
		end,
		function()
			if thread then
				if dispose then dispose(thread) end
				thread = nil
			end
		end
end

function asyncAddEventHandler( event, element, handler, propagated, busy )
	local wrapper,cleaner = asyncSingleton(handler, busy, asyncDisposeAll)
	addEventHandler( event, element, wrapper, propagated )
	addEventHandler( triggerServerEvent == nil and "onElementDestroy" or "onClientElementDestroy", 
		element, cleaner, false )
end

function asyncAddClientEventHandler( event, element, handler, propagated, busy )
	local wrapper,cleaner = asyncClientSingleton(handler, busy, asyncDisposeAll)
	addEventHandler( event, element, wrapper, propagated )
	addEventHandler( triggerServerEvent == nil and "onElementDestroy" or "onClientElementDestroy", 
		element, cleaner, false )
end
