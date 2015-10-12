local events = {}
local PFX = '__lsns_'
local PFX_LEN = PFX:len()

local function evtLsnsTbl(self, ev)
    local evLsnsTbl = self._on[ev]

    if (type(evLsnsTbl) ~= 'table') then
        evLsnsTbl = {}
        self._on[ev] = evLsnsTbl
    end

    return evLsnsTbl
end

local function addLsn(self, evt, lsn)
    local ev = tostring(PFX) .. tostring(evt)
    local evLsnsTbl = evtLsnsTbl(self, ev)

    table.insert(evLsnsTbl, lsn)
    return self
end

local function rmLsn(self, evt, lsn)
    local ev = tostring(PFX) .. tostring(evt)
    local evLsnsTbl = evtLsnsTbl(self, ev)


    for i, lsn in ipairs(evLsnsTbl) do
        if lsn == lsn then
            table.remove(evLsnsTbl, i)
        end
    end

    if (#evLsnsTbl == 0) then
        self._on[ev] = nil
    end

    ev = ev .. ':once'
    evLsnsTbl = evtLsnsTbl(self, ev)

    for i, lsn in ipairs(evLsnsTbl) do
        if lsn == lsn then
            table.remove(evLsnsTbl, i)
        end
    end

    if (#evLsnsTbl == 0) then
        self._on[ev] = nil
    end

    return self
end

local function rmAllLsns(self, evt)

    if evt ~= nil then
        local ev = tostring(PFX) .. tostring(evt)
        local evLsnsTbl = evtLsnsTbl(self, ev)

        for i, lsn in ipairs(evLsnsTbl) do
            table.remove(evLsnsTbl, i)
        end

        ev = ev .. ':once'
        evLsnsTbl = evtLsnsTbl(self, ev)

        for i, lsn in ipairs(evLsnsTbl) do
            table.remove(evLsnsTbl, i)
        end

        self._on[ev] = nil
    else
        for _ev, _lsnsTable in pairs(self._on) do
            rmAllLsns(_ev:sub(1, PFX_LEN))
        end
    end

    return self
end

local function once(self, evt, lsn)
    local ev = tostring(PFX) .. tostring(evt) .. ':once'
    local evLsnsTbl = evtLsnsTbl(self, ev)

    table.insert(evLsnsTbl, lsn)
    return self
end

local function emit(self, evt, ...)
    assert(evt, "invalid event:" .. tostring(evt))

    local ev = tostring(PFX) .. tostring(evt)
    local evLsnsTbl = evtLsnsTbl(self, ev)

    for _, lsn in pairs(evLsnsTbl) do
        local status, err = pcall(lsn, ...)
        if not (status) then
            print(tostring(self) .. "event emit err: " .. tostring(err))
        end
    end

    ev = ev .. ':once'
    evLsnsTbl = evtLsnsTbl(self, ev)

    for _, lsn in pairs(evLsnsTbl) do
      local status, err = pcall(lsn, ...)
      if not (status) then
        print("[events::" .. tostring(self) .. "::emit] err:" .. tostring(err))
      end
    end

    for i, lsn in ipairs(evLsnsTbl) do
        table.remove(evLsnsTbl, i)
    end

    self._on[ev] = nil

    return self
end

events.EventEmitter = function (obj)
    obj = obj or {}
    obj._on = {}    -- hold different event lsns

    obj.rm = rmLsn
    obj.on = addLsn
    obj.once = once
    obj.rmAll = rmAllLsns
    obj.emit = emit

    return obj
end

return events
