local timers = require 'timers'
local langate = { coatAddr = { ip = '', port = nil, family = '' } }
local broadAddr = '255.255.255.255'
local broadPort = 2658

function langate.startAsStation (ssid, pwd, interval, repeats, callback)
    wifi.setmode(wifi.STATION)
    wifi.sta.config(ssid, pwd)
    wifi.sta.connect()

    langate.requestIp(interval, repeats, callback)
end

function langate.requestIp (interval, retries, callback)
    local tid
    local repeats = 0

    tid = timers.setInterval(function () 
        repeats = repeats + 1
        if (wifi.sta.getip() == nil) then
            print("IP is unavaiable, please wait...")
            if (retries == repeats) then
                print("Get no ip address! Please check the ssid and password settings.")
                timers.clear(tid)
                callback('GOT_NO_IP', nil)
            end
        else
            timers.clear(tid)
            callback(nil, wifi.sta.getip())
        end
    end, interval)
end

function langate.requestCoatAddr (callback)
    local client = net.createConnection(net.UDP, 0)
    local req = { type = 'REQ', cmd = 'SERV_IP' } 

    langate.sendMessage(client, req, broadPort, broadAddr, 5, 2000, function (err, rxMsg)
        if (rxMsg ~= nil) then
            langate.coatAddr.ip = rxMsg.data.ip
            langate.coatAddr.port = rxMsg.data.port
            langate.coatAddr.family = rxMsg.data.family
        end
        callback(err, rxMsg.data)
    end)
end

function langate.serviceInfoReq (serv, callback)
    local client = net.createConnection(net.UDP, 0)
    local req = { type = 'REQ', cmd = 'QRY_SERV', service = serv }
    local servIp = langate.coatAddr.ip
    local servPort = langate.coatAddr.port or broadPort

    if (langate.coatAddr.ip == '') then
        callback('NO_SERV_IP', nil)
        return
    end
 
    langate.sendMessage(client, req, servPort, servIp, 5, 1200, function (err, rxMsg)
        callback(err, rxMsg.data)
    end)
end

function langate.sendMessage (client, msg, port, addr, maxRetries, interv, callback)
    local retries = 0
    local tid

    client:on('receive', function (sock, strData)
        local rxMsg = cjson.decode(strData)
        if (rxMsg.type == 'RSP' and rxMsg.cmd == msg.cmd) then
            timers.clear(tid)
            client:close()
            msg = nil
            client = nil
            callback(nil, rxMsg)
            collectgarbage("collect")
        end        
    end)

    client:connect(port, addr)
    client:send(cjson.encode(msg))

    tid = timers.setInterval(function ()
        if (retries == maxRetries) then
            timers.clear(tid)
            client:close()
            callback('RSP_TIMEOUT', nil)
            client = nil
            msg = nil
            collectgarbage()
        else
            client:send(cjson.encode(msg))
            retries = retries + 1
        end
    end, interv)
end

return langate
