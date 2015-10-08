local timers = {}
local timerStatus = { [3] = nil, [4] = nil, [5] = nil, [6] = nil }

local getIdleTimerId = function ()
    for k, v in pairs(timerStatus) do
        if (v == nil) then
            return k
        end
    end

    return nil
end

--[[
 *************************************************************************
 * Timer Class                                                           *
 ************************************************************************* ]]
Timer = { id = nil }

function Timer:new(obj, tmrid)
   obj = obj or {}
   setmetatable(obj, self)
   self.__index = self
   self.id = tmrid or nil
   return obj
end

function Timer:setTimeout(fn, delay)
    assert(self.id ~= nil, 'Timers are not available.')

    timerStatus[self.id] = self
    tmr.alarm(self.id, delay, 0, function ()
        fn()
        if (timerStatus[self.id] ~= nil) then
            timerStatus[self.id] = nil
        end
        self.id = nil
    end)

    return self
end

function Timer:setInterval(fn, interval)
    assert(self.id ~= nil, 'Timers are not available.')

    timerStatus[self.id] = self
    tmr.alarm(self.id, interval, 1, fn)
    return self
end

function Timer:clear()
    tmr.stop(self.id)
    if (timerStatus[self.id] ~= nil) then
        timerStatus[self.id] = nil
    end
    self.id = nil
    return self
end

--[[
 *************************************************************************
 * Timers Methods                                                        *
 ************************************************************************* ]]
function timers.setTimeout(fn, delay)
    local idleId = getIdleTimerId()
    assert(idleId ~= nil, 'Timers are not available.')

    local newTmr = Timer:new(nil, idleId)
    newTmr:setTimeout(fn, delay)
    return newTmr
end

function timers.setInterval(fn, interval)
    local idleId = getIdleTimerId()
    assert(idleId ~= nil, 'Timers are not available.')

    local newTmr = Timer:new(nil, idleId)
    newTmr:setInterval(fn, interval)
    return newTmr
end

function timers.clear(tmrObj)
    tmrObj.clear()
    tmrObj = nil
end

return timers
