local langate = {
    coatAddr = { ip = '', port = nil, family = '' }
}
local broadAddr = '255.255.255.255'
local broadPort = 2658

-- timers utils
local timers = {
    status = { [4] = false, [5] = false, [6] = false }
}

function timers.getIdleTimerId ()
    local tid = nil
    for k, v in pairs(timers.status) do
        if (v == false) then tid = k break end
    end
    return tid
end

function timers.alarm (fn, intvl, rpt)
    local idleId = timers.getIdleTimerId()
    assert(idleId ~= nil, 'Timers are not available.')

    timers.status[idleId] = true
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


-- langate facilities
function langate.startAsStation (ssid, pwd, interval, repeats, callback)
    wifi.setmode(wifi.STATION)
    wifi.sta.config(ssid, pwd)
    wifi.sta.connect()

    langate.requestIp(interval, repeats, callback)
end

function langate.requestIp (interval, retries, callback)
    local tId
    local repeats = 0
    
    local doReq
    doReq = function () 
        repeats = repeats + 1
        if (wifi.sta.getip() == nil) then
            print("IP is unavaiable, please wait...")
            if (retries == repeats) then
                print("Get no ip address! Please check the ssid and password settings.")
                timers.clear(tId)
                callback('Got no ip.', nil)
                doReq = nil
                collectgarbage('collect')
            end
        else
            timers.clear(tId)
            callback(nil, wifi.sta.getip())
            doReq = nil
            collectgarbage('collect')
        end
    end
    tId = timers.alarm(doReq, interval, 1)
end

function langate.requestCoatAddr (callback)
    local client = net.createConnection(net.UDP, 0)
    local req = { type = 'REQ', cmd = 'SERV_IP' }

    local afterSend
    afterSend = function (err, rxMsg)
        if (err ~= nil) then
            print(err)
        else
            langate.coatAddr.ip = rxMsg.data.ip
            langate.coatAddr.port = rxMsg.data.port
            langate.coatAddr.family = rxMsg.data.family
            callback(nil, rxMsg)
        end
        afterSend = nil
        collectgarbage('collect')
    end

    langate.sendMessage(client, req, broadPort, broadAddr, 5, 2000, afterSend)
end

function langate.serviceInfoReq (serv, callback)
    local client = net.createConnection(net.UDP, 0)
    local req = { type = 'REQ', cmd = 'QRY_SERV', service = serv }

    if (langate.coatAddr.ip == '') then
        callback('Server ip is empty', nil)
        return
    end
 
    local afterSend
    afterSend = function (err, rxMsg)
        if (err ~= nil) then print(err)
        else  callback(nil, rxMsg.data) end

        afterSend = nil
        collectgarbage('collect')
    end
    langate.sendMessage(client, req, langate.coatAddr.port or broadPort, 
                        langate.coatAddr.ip, 5, 1200, afterSend)
end

function langate.sendMessage (client, msg, port, addr, maxRetries, interv, callback)
    local retries = 0
    local tId

    client:on('receive', function (sock, strData)
        local rxMsg = cjson.decode(strData)
        if (rxMsg.type == 'RSP' and rxMsg.cmd == msg.cmd) then
            timers.clear(tId)
            client:close()
            msg = nil
            client = nil
            callback(nil, rxMsg)
            collectgarbage("collect")
        end        
    end)

    client:connect(port, addr)
    client:send(cjson.encode(msg))

    local doReq
    doReq = function ()
        if (retries == maxRetries) then
            timers.clear(tId)
            client:close()
            callback('RSP Timeout', nil)
            msg = nil
            doReq = nil
            collectgarbage()
        else
            client:send(cjson.encode(msg))
            retries = retries + 1
        end
    end

    tId = timers.alarm(doReq, interv, 1)
    collectgarbage()
end

return langate
