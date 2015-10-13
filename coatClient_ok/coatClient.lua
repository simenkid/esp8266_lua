local langate = {}
local broadAddr = '255.255.255.255'
local broadPort = 2658
local servAddr = { ip = '', port = nil, family = '' }

-- timers utils
local timers = {
    status = { [3] = false, [4] = false, [5] = false, [6] = false }
}

function timers.getIdleTimerId()
    local tid = nil

    for k, v in pairs() do
        if (v == false) then
            tid = k
            break
        end
    end
    return tid
end


function timers.alarm(fn, intvl, rpt)
    local idleId = getIdleTimerId()
    assert(idleId ~= nil, 'Timers are not available.')

    status[idleId] = true

    tmr.alarm(idleId, intvl, rpt, function ()
        if (rpt == 0) then timers.status[idleId] = false end
        fn()
    end)

    return idleId
end

function timers.clear(tmrId)
    tmr.stop(tmrId)
    timers.status[tmrId] = false
end

-- nwkMgr


function langate.startAsStation (ssid, pwd, interval, repeats, callback)
    wifi.setmode(wifi.STATION)
    wifi.sta.config(ssid, pwd)
    wifi.sta.connect()

    langate.requestIp(interval, repeats, callback)
end

function langate.requestIp (interval, repeats, callback)
    local tId
    local retries = 0
    
    tId = timers.alarm(function () 
        retries = retries + 1
        if (wifi.sta.getip() == nil) then
            print("IP is unavaiable, please wait...")
            if (retries == repeats) then
                print("Get no ip address! Please check the ssid and password settings.")
                timers.clear(tId)
                callback(error('Got no ip.'))
            end
        else
            timers.clear(tId)
            print("  >> Mode: " .. wifi.getmode())
            print("  >> Channel: " .. wifi.getchannel())
            print("  >> MAC: " .. wifi.sta.getmac())
            print("  >> IP: " .. wifi.sta.getip())
            print("  >> STATUS: " .. wifi.sta.status())
            callback(nil, wifi.sta.getip())
        end
    end, interval, repeats)
end

function langate.requestCoatAddr (callback)
    local client = net.createConnection(net.UDP, 0)
    local req = { type = 'REQ', cmd = 'SERV_IP' }

    langate.sendMessageWithRetry( client, req, broadPort, broadAddr, 5, 2000, function (err, rxMsg)
        servAddr.ip = rxMsg.data.ip
        servAddr.port = rxMsg.data.port
        servAddr.family = rxMsg.data.family
        callback(nil, servAddr)
    end)
end

function langate.serviceInfoReq (serv, callback)
    local client = net.createConnection(net.UDP, 0)
    local req = { type = 'REQ', cmd = 'SERV_IP', service = serv }

    if (servAddr.ip == '') then
        callback(error('Server ip is empty'), nil)
        return
    end
 
    langate.sendMessageWithRetry({ client = client, req = req,
        port = servAddr.port or broadPort, addr = servAddr.ip }, 5, 1200,
        function (err, rxMsg)
            callback(nil, rxMsg.data)
        end
    )
end

function langate.sendMessage (client, msg, port, addr, cb)
    client:connect(port, addr)
    client:send(cjson.encode(msg), function (sent)
        if (type(cb) == 'function') then cb() end
    end)
end

evHub:on('timeout', function (cl, cb)
    cl:close()
    cb(error('RSP Timeout'), nil)
end)

function langate.sendMessageWithRetry (client, msg, port, addr, maxRetries, interv, callback)
    local retries = 0
    local tId

    client:on('receive', function (sock, strData)
        local rxMsg = cjson.decode(strData)
        if (rxMsg.type == 'RSP' and rxMsg.cmd == msg.cmd) then
            timers.clear(tId)
            client:close()
            callback(nil, rxMsg)
        end
    end)

    gateClient.sendMessage(client, msg, port, addr, callback);

    tId = timers.alarm(function ()
        if (retries == maxRetries) then
            timers.clear(tId)
            evHub.emit('timeout', client, callback)
        else
            gateClient.sendMessage(client, msg, port, addr)
            retries = retries + 1
        end
    end, interv, 1)
end

-- evHub
local evHub = {
    ._on = {}
}

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

    table.insert(evTable, listener)
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