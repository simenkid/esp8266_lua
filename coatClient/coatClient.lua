
-- timers utils
local timers = {
    status = { [3] = nil, [4] = nil, [5] = nil, [6] = nil }
}

function timers.getIdleTimerId()
    local tid
    if (timers.status[3] == nil) then tid = 3
    elseif (timers.status[4] == nil) then tid = 4
    elseif (timers.status[5] == nil) then tid = 5
    elseif (timers.status[6] == nil) then tid = 6
    else tid = nil end

    return tid
end


function timers.alarm(fn, intvl, rpt)
    local idleId = getIdleTimerId()
    assert(idleId ~= nil, 'Timers are not available.')

    status[idleId] = true

    tmr.alarm(idleId, intvl, rpt, function ()
        if (rpt == 0) then
            status[idleId] = nil
        end
        fn()
    end)

    return idleId
end

function timers.clear(tmrId)
    tmr.stop(tmrId)
    status[tmrId] = nil
end

-- nwkMgr
local langate = {}

function langate.startAsStation (ssid, pwd, interval, repeats, callback)
    print("Setting up wifi mode as a STATION")
    wifi.setmode(wifi.STATION)
    wifi.sta.config(ssid, pwd)
    wifi.sta.connect()

    nwkMgr.findCoatIp(interval, repeats, callback)
end

function langate.findCoatIp (interval, repeats, callback)
    local tId
    local retries = 0
    
    tId = timers.alarm(function () 
        retries = retries + 1
        if (wifi.sta.getip() == nil) then
            print("IP is unavaiable, please wait...")
            if (retries == repeats) {
                print("Get no ip address! Please check the ssid and password settings.")
            }
        else
            timers.clear(tId)
            print("  >> Mode: " .. wifi.getmode())
            print("  >> Channel: " .. wifi.getchannel())
            print("  >> MAC: " .. wifi.sta.getmac())
            print("  >> IP: " .. wifi.sta.getip())
            print("  >> STATUS: " .. wifi.sta.status())
            callback()        
        end
    end, interval, repeats)
end

local broadAddr = '255.255.255.255'
local broadPort = 2658
local servAddr = { ip = '', port = nil, family = '' }

function langate.serverAddrReq (callback)
    local client = net.createConnection(net.UDP, 0)
    local req = { type = 'REQ', cmd = 'SERV_IP' }

    langate.sendMessageWithRetry({ client = client, req = req,
        port = broadPort, addr = broadAddr }, 5, 2000,
        function (err, rxMsg)
            servAddr.ip = rxMsg.data.ip
            servAddr.port = rxMsg.data.port
            servAddr.family = rxMsg.data.family
            callback(nil, servAddr)
        end
    )
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

function langate.sendMessageWithRetry (cMsg, maxRetries, interv, callback)
    local client = cMsg.client
    local msg = cMsg.msg
    local port = cMsg.port
    local addr = cMsg.addr
    local tmrId = 6
    local retries = 0
    local sendScheduler

    client.auxEvt = events.EventEmitter()
    client.auxEvt:on('timeout', function ()
        client:close()
        callback(error('RSP Timeout'), nil)
    end)

    client:on('receive', function (sock, strData)
        local rxMsg = cjson.decode(strData)
        if (rxMsg.type == 'RSP' and rxMsg.cmd == msg.cmd) then
            timers.clear(sendScheduler)
            client:close()
            callback(nil, rxMsg)
        end
    end)

    gateClient.sendMessage(client, msg, port, addr, callback);

    sendScheduler = timers.setInterval(function ()
        if (retries == maxRetries) then
            timers.clear(sendScheduler)
            client.auxEvt:emit('timeout')
        else
            gateClient.sendMessage(client, msg, port, addr)
            retries = retries + 1
        end        
    end)

   return sendScheduler
end
