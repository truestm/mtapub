addEvent("onClientElementStreamInDelayed")
addEvent("onClientElementStreamOutDelayed")

local queue = {}

setTimer(function()
    for element in pairs(queue) do
        if isElement(element) and isElementStreamedIn(element) then
            triggerEvent("onClientElementStreamInDelayed", element)
        end
    end
    for element in pairs(queue) do
        queue[element] = nil
    end
end, 1000, 0)

addEventHandler( "onClientElementStreamIn", root, function()
    --outputDebugString("onClientElementStreamIn "..inspect(source))
    queue[source] = true
end)

addEventHandler( "onClientElementStreamOut", root, function()
    --outputDebugString("onClientElementStreamOut "..inspect(source))
    if queue[source] then
        queue[source] = nil
    else
        triggerEvent("onClientElementStreamOutDelayed", source)
    end
end)
