local tmrs = {}
local sts = { [3] = nil, [4] = nil, [5] = nil, [6] = nil }

local function getIdleTimerId()
    local tid
    if (sts[3] == nil) then tid = 3
    elseif (sts[4] == nil) then tid = 4
    elseif (sts[5] == nil) then tid = 5
    elseif (sts[6] == nil) then tid = 6
    else tid = nil end

    return tid
end

function tmrs.setTimeout(fn, delay)
    local fid = getIdleTimerId()
    assert(fid ~= nil, 'tmrs are not available.')

    sts[fid] = true
    tmr.alarm(fid, delay, 0, function ()
        if (sts[fid] ~= nil) then
            sts[fid] = nil
        end
        fn()
    end)

    return fid
end

function tmrs.setInterval(fn, interval)
    local fid = getIdleTimerId()
    assert(fid ~= nil, 'tmrs are not available.')

    sts[fid] = true
    tmr.alarm(fid, interval, 1, fn)

    return fid
end

function tmrs.clear(tmrId)
    tmr.stop(tmrId)
    if (sts[tmrId] ~= nil) then
        sts[tmrId] = nil
    end
end

return tmrs
