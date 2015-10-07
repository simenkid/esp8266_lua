local IDENTIFIER = "__event_emitter"
-- local PREFIX_LISTENERS = "__listeners_"
-- local LEN_PREFIX_LISTENERS = PREFIX_LISTENERS:len()

local LISN_PREFIX = '__LISTENERS'
local LISN_PREFIX_LEN = LISN_PREFIX:len()


local traceback
local findOrCreateListenerTable
local addListener
local once
local removeListener
local removeAllListeners
local emit

traceback = function(err)
  print("LUA ERROR: " .. tostring(err) .. "\n")
  return print(debug.traceback("", 2))
end


getListenerTbl = function (self, evt)
    local evtKey = tostring(LISN_PREFIX) .. tostring(evt)
    local lisnTbl = rawget(self, evtKey)

    if (type(lisnTbl) ~= 'table') then
        lisnTbl = {}
        rawset(self, evtKey, lisnTbl)
    end

    return lisnTbl
end


once = function(self, evt, lisn)
  -- local useWeakReference = rawget(self, IDENTIFIER)
  evt = tostring(evt) .. ":once"
  local listeners = getListenerTbl(self, event)
  rawset(listeners, lisn, true)
  return self
end


emit = function(self, event, ...)
  assert(event, "invalid event:" .. tostring(event))
  -- assert(type(self) == "table", tostring(self) .. " is not a table")
  -- assert(type(self) == "table" and rawget(self, IDENTIFIER) ~= nil, "self is not valid EventEmitter")
  local keyEvent = tostring(PREFIX_LISTENERS) .. tostring(event)
  local listeners = rawget(self, keyEvent)

  if type(listeners) == "table" then
    for listener in pairs(listeners) do
      local status, err = pcall(listener, ...)
      if not (status) then
        print("[events::" .. tostring(self) .. "::emit] err:" .. tostring(err))
        traceback(err)
      end
    end
  end

  keyEvent = tostring(PREFIX_LISTENERS) .. tostring(event) .. ":once"
  listeners = rawget(self, keyEvent)
  if type(listeners) == "table" then
    for listener in pairs(listeners) do
      local status, err = pcall(listener, ...)
      if not (status) then
        print("[events::" .. tostring(self) .. "::emit] err:" .. tostring(err))
        traceback(err)
      end
    end
  end
  rawset(self, keyEvent, nil)
  return self
end


local events = {}

events.EventEmitter = function(tbl)

    assert(type(tbl) == "table", "The argument should be a table")
    rawset(tbl, IDENTIFIER, (not not useWeakReference))

    tbl.on = addListener
    tbl.addListener = addListener
    tbl.once = once
    tbl.removeListener = removeListener
    tbl.removeAllListeners = removeAllListeners
    tbl.emit = emit
    return tbl
  end

return events

--[[
--]]
addListener = function (self, event, listener)
      -- local useWeakReference = rawget(self, IDENTIFIER)
      -- local listeners = findOrCreateListenerTable(self, event, useWeakReference)
      local listeners = findOrCreateListenerTable(self, event)
      rawset(listeners, listener, true)
      return self
end


removeListener = function (self, event, listener)
  assert(event and listener, "invalid event:" .. tostring(event) .. " or listener:" .. tostring(listener) .. ", self:" .. tostring(self))
  assert(type(self) == "table", tostring(self) .. " is not a table")

  --local useWeakReference = rawget(self, IDENTIFIER)
  --assert(useWeakReference ~= nil, "self is not valid EventEmitter")

  local keyEvent = tostring(PREFIX_LISTENERS) .. tostring(event)
  local listeners = rawget(self, keyEvent)

  if listeners then
    rawset(listeners, listener, nil)
  end

  keyEvent = tostring(PREFIX_LISTENERS) .. tostring(event) .. ":once"
  listeners = rawget(self, keyEvent)

  if listeners then
    rawset(listeners, listener, nil)
  end

  return self
end



removeAllListeners = function (self, event)
  -- print("[events::removeAllListeners] self:" .. tostring(self) .. ", event:" .. tostring(event))
  -- assert(type(self) == "table", tostring(self) .. " is not a table")
  -- assert(type(self) == "table" and rawget(self, IDENTIFIER) ~= nil, "self is not valid EventEmitter")
  if event ~= nil then
    local keyEvent = tostring(PREFIX_LISTENERS) .. tostring(event)
    rawset(self, keyEvent, nil)
    keyEvent = tostring(PREFIX_LISTENERS) .. tostring(event) .. ":once"
    rawset(self, keyEvent, nil)
  else
    local listToRemove = {}
    for key in pairs(self) do
      if type(key) == "string" and key:sub(1, LEN_PREFIX_LISTENERS) == PREFIX_LISTENERS then
        table.insert(listToRemove, key)
      end
    end
    for _index_0 = 1, #listToRemove do
      local key = listToRemove[_index_0]
      rawset(self, key, nil)
    end
  end
  return self
end