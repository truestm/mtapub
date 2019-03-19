function asyncDbQueryComplete( handle, taskid )
	asyncComplete( taskid, dbPoll( handle, 0 ) )
end
	
function asyncDbQuery( connection, sql, ... )
	local taskid, task = asyncTask()
	local query = dbPrepareString( connection, sql, ... )
	local handle = dbQuery( asyncDbQueryComplete, { taskid }, connection, query )
	return task
end
