local function asyncWaitPreRenderComplete( taskid, client, source, this, time )
	asyncCompleteOverride( taskid, asyncTaskLastResult( taskid ) or 0 + time )		
end

function asyncWaitPreRender()
	return asyncWaitEvent( "onClientPreRender", root, false, true, asyncWaitPreRenderComplete )
end

local function asyncWaitRenderComplete( taskid, client, source, this )
	asyncCompleteOverride( taskid )		
end

function asyncWaitRender()
	return asyncWaitEvent( "onClientRender", root, false, true, asyncWaitRenderComplete )
end