local evHub = { _on = {} }

function evHub:evTable(ev)
    if (type(self._on[ev]) ~= 'table') then self._on[ev] = {} end
    return self._on[ev]
end

function evHub:on (ev, lsn)
    local evTable = self:evTable(ev)
    table.insert(evTable, lsn)
end

function evHub:once(ev, lsn)
    local ev = ev .. ':once'
    local evTable = self:evTable(ev)
    table.insert(evTable, lsn)
end

function evHub:rm (ev, lsn)
    local evTable = self:evTable(ev)
    for i, l in ipairs(evTable) do
        if l == lsn then table.remove(evTable, i) end
    end

    if (#evTable == 0) then self._on[ev] = nil end

    ev = ev .. ':once'
    evTable = self:evTable(ev)
    for i, l in ipairs(evTable) do
        if l == lsn then table.remove(evTable, i) end
    end

    if (#evTable == 0) then self._on[ev] = nil end
end

function evHub:rmAll (ev)
    if ev ~= nil then
        local evTable = self:evTable(ev)

        for i, lsn in ipairs(evTable) do table.remove(evTable, i) end

        self._on[ev] = nil

        ev = ev .. ':once'
        evTable = self:evTable(ev)

        for i, lsn in ipairs(evTable) do table.remove(evTable, i) end
        self._on[ev] = nil
    else
        for _ev, _lsnTbl in pairs(self._on) do evHub:rmAll(_ev) end
    end
end


function evHub:emit (ev, ...)
    assert(ev, "invalid event:" .. tostring(ev))
    local evTable = self:evTable(ev)
    for _, lsn in pairs(evTable) do
        local status, err = pcall(lsn, ...)
        if not (status) then print(tostring(self) .. "event emit err: " .. tostring(err)) end
    end

    ev = ev .. ':once'
    evTable = self:evTable(ev)
    for _, lsn in pairs(evTable) do
        local status, err = pcall(lsn, ...)
        if not (status) then print("[events::" .. tostring(self) .. "::emit] err:" .. tostring(err)) end
    end

    for i, lsn in ipairs(evTable) do table.remove(evTable, i) end

    self._on[ev] = nil
end

return evHub
