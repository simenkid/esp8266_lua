local events = require 'events'
local timers = require 'timers'
local lanGate = {}
local broadAddr = '255.255.255.255'
local broadPort = 2658
local servAddr = { ip = '', port = nil, family = '' }

function lanGate.serverAddrReq (callback)
    local client = net.createConnection(net.UDP, 0)
    local req = { type = 'REQ', cmd = 'SERV_IP' }

    lanGate.sendMessageWithRetry({ client = client, req = req,
        port = broadPort, addr = broadAddr }, 5, 2000,
        function (err, rxMsg)
            servAddr.ip = rxMsg.data.ip
            servAddr.port = rxMsg.data.port
            servAddr.family = rxMsg.data.family
            callback(nil, servAddr)
        end
    )
end

function lanGate.serviceInfoReq (serv, callback)
    local client = net.createConnection(net.UDP, 0)
    local req = { type = 'REQ', cmd = 'SERV_IP', service = serv }

    if (servAddr.ip == '') then
        callback(error('Server ip is empty'), nil)
        return
    end
 
    lanGate.sendMessageWithRetry({ client = client, req = req,
        port = servAddr.port or broadPort, addr = servAddr.ip }, 5, 1200,
        function (err, rxMsg)
            callback(nil, rxMsg.data)
        end
    )
end

function lanGate.sendMessage (client, msg, port, addr, cb)
    client:connect(port, addr)
    client:send(cjson.encode(msg), function (sent)
        if (type(cb) == 'function') then cb() end
    end)
end

function lanGate.sendMessageWithRetry (cMsg, maxRetries, interv, callback)
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

return lanGate
