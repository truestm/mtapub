function importFunctions(resourceName, namespace)
    local resource = getResourceFromName( resourceName )
	for _,name in ipairs(getResourceExportedFunctions(resource)) do
		if type(namespace) == "table" then
			namespace[name] = function(self,...) return call(resource, name, ...) end
		else
			_G[(namespace or "")..name] = function(...) return call(resource, name, ...) end
		end
    end
	return namespace
end