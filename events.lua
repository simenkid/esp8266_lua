local events = {}
local LSNS_PREFIX = '__lsns_'
local LSNS_PREFIX_LEN = LSNS_PREFIX:len()

--[[
 *************************************************************************
 * Local Functions                                                       *
 ************************************************************************* ]]
local function traceback(err)
  print("LUA ERROR: " .. tostring(err) .. '\n')
  return print(debug.traceback('', 2))
end

local function getEvtListenersTable(self, evtKey)
    local evtListenersTable = self._on[evtKey]

    if (type(evtListenersTable) ~= 'table') then
        evtListenersTable = {}
        self._on[evtKey] = evtListenersTable
    end

    return evtListenersTable
end

local function addListener(self, evt, listener)
    local evtKey = tostring(LSNS_PREFIX) .. tostring(evt)
    local evtListenersTable = getEvtListenersTable(self, evtKey)

    table.insert(evtListenersTable, listener)
    return self
end

local function removeListener(self, evt, listener)
    local evtKey = tostring(LSNS_PREFIX) .. tostring(evt)
    local evtListenersTable = getEvtListenersTable(self, evtKey)


    for i, lsn in ipairs(evtListenersTable) do
        if lsn == listener then
            table.remove(evtListenersTable, i)
        end
    end

    if (#evtListenersTable == 0) then
        self._on[evtKey] = nil
    end

    evtKey = evtKey .. ':once'
    evtListenersTable = getEvtListenersTable(self, evtKey)

    for i, lsn in ipairs(evtListenersTable) do
        if lsn == listener then
            table.remove(evtListenersTable, i)
        end
    end

    if (#evtListenersTable == 0) then
        self._on[evtKey] = nil
    end

    return self
end

local function removeAllListeners(self, evt)

    if evt ~= nil then
        local evtKey = tostring(LSNS_PREFIX) .. tostring(evt)
        local evtListenersTable = getEvtListenersTable(self, evtKey)

        for i, lsn in ipairs(evtListenersTable) do
            table.remove(evtListenersTable, i)
        end

        evtKey = evtKey .. ':once'
        evtListenersTable = getEvtListenersTable(self, evtKey)

        for i, lsn in ipairs(evtListenersTable) do
            table.remove(evtListenersTable, i)
        end

        self._on[evtKey] = nil
    else
        for _evtKey, _lsnsTable in pairs(self._on) do
            removeAllListeners(_evtKey:sub(1, LSNS_PREFIX_LEN))
        end
    end

    return self
end

local function once(self, evt, listener)
    local evtKey = tostring(LSNS_PREFIX) .. tostring(evt) .. ':once'
    local evtListenersTable = getEvtListenersTable(self, evtKey)

    table.insert(evtListenersTable, listener)
    return self
end

local function emit(self, evt, ...)
    assert(evt, "invalid event:" .. tostring(evt))

    local evtKey = tostring(LSNS_PREFIX) .. tostring(evt)
    local evtListenersTable = getEvtListenersTable(self, evtKey)

    for _, lsn in pairs(evtListenersTable) do
        local status, err = pcall(lsn, ...)
        if not (status) then
            print(tostring(self) .. "event emit err: " .. tostring(err))
            traceback(err)
        end
    end

    evtKey = evtKey .. ':once'
    evtListenersTable = getEvtListenersTable(self, evtKey)

    for _, lsn in pairs(evtListenersTable) do
      local status, err = pcall(lsn, ...)
      if not (status) then
        print("[events::" .. tostring(self) .. "::emit] err:" .. tostring(err))
        traceback(err)
      end
    end

    for i, lsn in ipairs(evtListenersTable) do
        table.remove(evtListenersTable, i)
    end

    self._on[evtKey] = nil

    return self
end

events.EventEmitter = function (obj)
    obj = obj or {}
    obj._on = {}    -- hold different event listeners

    obj.addListener = addListener
    obj.removeListener = removeListener
    obj.on = addListener
    obj.once = once
    obj.removeAllListeners = removeAllListeners
    obj.emit = emit

    return obj
end

return events
