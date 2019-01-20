function importFunctions(resourceName, namespace)
	local resource = getResourceFromName( resourceName )
	for _,name in ipairs(getResourceExportedFunctions(resource)) do
		if type(namespace) == "table" then
			namespace[name] = function(self,...)
				if getUserdataType(resource) ~= "resource-data" then
					resource = getResourceFromName( resourceName )
				end
				return call(resource, name, ...)
			end
		else
			_G[(namespace or "")..name] = function(...)
				if getUserdataType(resource) ~= "resource-data" then
					resource = getResourceFromName( resourceName )
				end
				return call(resource, name, ...)
			end
		end
	end
	return namespace
end