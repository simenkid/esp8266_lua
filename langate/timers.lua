local timers = {}
local status = { [3] = false, [4] = false, [5] = false, [6] = false }

local function getIdleTimerId()
    local tid = nil
    for k, v in pairs(status) do
        if (v == false) then tid = k break end
    end
    return tid
end

function timers.setTimeout(fn, delay)
    local tid = getIdleTimerId()
    assert(tid ~= nil, 'Timers are not available.')

    status[tid] = true

    tmr.alarm(tid, delay, 0, function ()
        status[tid] = false
        fn()
    end)

    return tid
end

function timers.setInterval(fn, interval)
    local tid = getIdleTimerId()
    assert(tid ~= nil, 'Timers are not available.')

    status[tid] = true
    tmr.alarm(tid, interval, 1, fn)

    return tid
end

function timers.clear(tmrId)
    tmr.stop(tmrId)
    status[tmrId] = false
end

return timers
