local lanGate = {}

local broadAddr = '255.255.255.255'
local broadPort = 2658
local servAddr = { ip = '', port = null, family = '' }

function lanGate.serverAddrReq (callback)
    local client = net.createConnection(net.UDP, 0)
    local tmrid

    client:on('receive', function (sock, strData)
        local msg = cjson.decode(strData)

        if (msg.type == 'RSP' && msg.cmd == 'SERV_IP') then
            servAddr.ip = msg.data.ip
            servAddr.port = msg.data.port
            servAddr.family = msg.data.family
        end

        -- process.nextTick(function () {
        --     callback(null, servAddr);
        -- });

        tmr.stop(tmrid)
        client:close()
    end)

    client:on('timeout', function () 
        -- process.nextTick(function () {
        --     callback(new Error('RSP Timeout'), null);
        -- })
    end)

    client:connect(broadPort, broadAddr)

    local req = {
        type = 'REQ',
        cmd = 'SERV_IP'
    }

    

    tmrid = lanGate.sendMessageWithRetry({
        client =  client,
        req = req,
        port = broadPort,
        addr = broadAddr
    }, 5, 2000);
end

function lanGate.serviceInfoReq ()
end

function lanGate.sendMessage (client, msg, port, addr, cb)
    client:send(cjson.encode(msg), function (sent)
        if (type(cb) == 'function') then
            cb()
        end
    end)
end

function lanGate.sendMessageWithRetry (cMsg, maxRetries, interv, callback)
    local client = cMsg.client
    local msg = cMsg.msg
    local port = cMsg.port
    local addr = cMsg.addr
    local tmrId = 6
    local retries = 0
    local cb;

    gateClient.sendMessage(client, msg, port, addr, callback);

    tmr.alarm(tmrId, interv, 1, function ()
        if (retries == maxRetries) then
            tmr.stop(6)
            -- client.emit('timeout');
            client:close()
        else
            gateClient.sendMessage(client, msg, port, addr)
            retries = retries + 1
        end
    end)

    return tmrId
end

return lanGate
