local evHub = require 'evHub'
local timers = require 'timers'
local langate = nil

local wConf = { ssid = 'sivann', pwd = '26583302' }
local coatIp = ''
local mqttPort = nil
local mClient = nil
local LED = 1   -- GPIO5, D13

gpio.mode(LED, gpio.OUTPUT, gpio.PULLUP)

function unrequire(m)
    package.loaded[m] = nil
    _G[m] = nil
    collectgarbage("collect")
end

-- Network Initialization Steps
evHub:once('step1_startSTA', function (ip)
    langate = require 'langate'
    langate.startAsStation(wConf.ssid, wConf.pwd, 1000, 10, function (err, ip)
        if (err ~= nil) then print (err)
        else
            print('Now online: ' .. ip)
            evHub:emit('step2_findCoat', ip)
        end
    end)
end)

evHub:once('step2_findCoat', function (ip)
    print('Searching for coat server...')
    langate.requestCoatAddr(function (err, servAddr)
        if (err ~= nil) then print(err)
        else
            coatIp = servAddr.ip
            print('Coat alive: '.. coatIp .. '@' .. servAddr.port)
            evHub:emit('step3_queryMqtt', servAddr)
        end
    end)
end)

evHub:once('step3_queryMqtt', function (servAddr)
    print('Querying mqtt broker...')
    langate.serviceInfoReq('mqtt', function (err, serv)
        if (err ~= nil) then print(err)
        else
            if (serv.name == 'mqtt') then
                print('MQTT broker alive: ' .. coatIp .. '@' .. serv.port)
                mqttPort = serv.port
                evHub:emit('step4_connect_broker', { ip = coatIp, port = mqttPort })
            end
        end
    end)
end)

evHub:once('step4_connect_broker', function (serv)
    -- unload langate, since we don't need it anymore
    langate = nil
    unrequire('langate')

    print('Connecting mqtt broker...')
    local cId = wifi.sta.getmac()
    mClient = mqtt.Client(cId, 120, "", "")
    mClient:lwt("/lwt", "offline", 0, 0)

    mClient:on("connect", function(con) 
        print ("Connect to ") 
    end)

    mClient:on("offline", function(con) print ("offline") end)
    mClient:on("message", function(conn, topic, data)
        print(topic .. ":" )
        if data ~= nil then print(data) end
    end)
    -- m:connect( host, port, secure, auto_reconnect, function(client) )
    -- for secure: m:connect("192.168.11.118", 1880, 1, 0)
    -- for auto-reconnect: m:connect("192.168.11.118", 1880, 0, 1)
    mClient:connect(coatIp, mqttPort, 0, 0, function(conn) 
        mClient:subscribe("/presence", 0, function(conn)
            timers.setTimeout(function ()
                evHub:emit('step5_pub', mClient)
            end, 3000)
            print("subscribe success")           
        end)
    end)
end)


evHub:once('step5_pub', function (mc)
    local c = 0
    timers.setInterval(function ()
        mc:publish("/presence", "hello count: " .. c, 0, 0, function(conn) print("sent") end)
        c = c + 1
        print(collectgarbage("count"))
    end, 5000)
end)

if (wConf.ssid ~= nil and wConf.pwd ~= nil) then
    evHub:emit('step1_startSTA')
else
    print("\n")
    print("Please set the ssid and passwrod of the wireless router in 'init.lua'")
end

-- tmr.alarm(3, 1000, 1, function ()
--     if (gpio.read(LED) == 1) then
--         gpio.write(LED, gpio.LOW)
--     else
--         gpio.write(LED, gpio.HIGH)
--     end
-- end)