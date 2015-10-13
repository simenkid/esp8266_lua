local timers = {}
local timerStatus = { [3] = nil, [4] = nil, [5] = nil, [6] = nil }

local function getIdleTimerId()
    local tid
    if (timerStatus[3] == nil) then tid = 3
    elseif (timerStatus[4] == nil) then tid = 4
    elseif (timerStatus[5] == nil) then tid = 5
    elseif (timerStatus[6] == nil) then tid = 6
    else tid = nil end

    return tid
end

function timers.setTimeout(fn, delay)
    local idleId = getIdleTimerId()
    assert(idleId ~= nil, 'Timers are not available.')

    timerStatus[idleId] = true
    local busyId = idleId

    tmr.alarm(busyId, delay, 0, function ()
        if (timerStatus[busyId] ~= nil) then
            timerStatus[busyId] = nil
        end
        fn()
    end)

    return busyId
end

function timers.setInterval(fn, interval)
    local idleId = getIdleTimerId()
    assert(idleId ~= nil, 'Timers are not available.')

    timerStatus[idleId] = true
    local busyId = idleId
    tmr.alarm(busyId, interval, 1, fn)

    return busyId
end

function timers.clear(tmrId)
    tmr.stop(tmrId)
    if (timerStatus[tmrId] ~= nil) then
        timerStatus[tmrId] = nil
    end
end

return timers
