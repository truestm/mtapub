addEvent("onClientElementStreamInDelayed")
addEvent("onClientElementStreamOutDelayed")

local queue = {}

setTimer(function()
    local element = next(queue)
    if element and not isElementWaitingForGroundToLoad(localPlayer) then
        repeat
            local nextElement = next(queue,element)
            if isElement(element) then
                if isElementStreamedIn(element) and not isElementWaitingForGroundToLoad(element) then
                    triggerEvent("onClientElementStreamInDelayed", element)
                    queue[element] = nil
                end
            else
                queue[element] = nil
            end
            element = nextElement
        until not element
    end
end, 1000, 0)

addEventHandler( "onClientElementStreamIn", root, function()
    queue[source] = true
end)

addEventHandler( "onClientElementStreamOut", root, function()
    if queue[source] then
        queue[source] = nil
    else
        triggerEvent("onClientElementStreamOutDelayed", source)
    end
end)
