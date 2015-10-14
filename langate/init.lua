local evHub = require 'evHub'
local timers = require 'timers'
local langate = require 'langate'

local wConf = { ssid = 'sivann', pwd = '26583302' }
local coatIp = ''
local mqttPort = nil
local mClient = nil
local LED = 1   -- GPIO5, D13

gpio.mode(LED, gpio.OUTPUT, gpio.PULLUP)
--[[
 *************************************************************************
 * Main App                                                              *
 ************************************************************************* ]]
-- print(collectgarbage("count"))
function unrequire(m)
    package.loaded[m] = nil
    _G[m] = nil
    collectgarbage("collect")
end

print(collectgarbage("count"))
evHub:once('online', function (ip)
    print(collectgarbage("count"))
    print('ESP8266 is now online with ip: ' .. ip)
    print('Searching for coat server...')
    langate.requestCoatAddr(function (err, servAddr)
        if (err ~= nil) then print(err)
        else
            coatIp = servAddr.ip
            evHub:emit('got_coat', servAddr)
        end
    end)
end)

evHub:once('got_coat', function (servAddr)
    print(collectgarbage("count"))
    print('Coat found: '.. coatIp .. '@' .. servAddr.port)
    print('Querying mqtt broker...')
    print(collectgarbage("count"))
    langate.serviceInfoReq('mqtt', function (err, serv)
        if (err ~= nil) then print(err) end
        if (serv.name == 'mqtt') then evHub:emit('mqtt_info', serv) end
    end)
end)

evHub:once('mqtt_info', function (serv)
    print(collectgarbage("count"))
    print('MQTT broker found: ' .. coatIp .. '@' .. serv.port)
    print(collectgarbage("count"))
    mqttPort = serv.port
    evHub:emit('mqtt_connect', { ip = coatIp, port = mqttPort })
end)

evHub:once('mqtt_connect', function (serv)
    print(collectgarbage("count"))
    -- unload langate, since we don't need it anymore
    langate = nil
    unrequire('langate')
    collectgarbage("collect")
    print(collectgarbage("count"))

    print('Connecting mqtt broker...')
    local cId = wifi.sta.getmac()
    print(collectgarbage("count"))
    mClient = mqtt.Client(cId, 120, "", "")
    mClient:lwt("/lwt", "offline", 0, 0)

    mClient:on("connect", function(con) 
        print ("Connect to ") 
    end)

    mClient:on("offline", function(con) print ("offline") end)
    print(collectgarbage("count"))
    mClient:on("message", function(conn, topic, data)
        print(topic .. ":" )
        if data ~= nil then print(data) end
    end)
    -- m:connect( host, port, secure, auto_reconnect, function(client) )
    -- for secure: m:connect("192.168.11.118", 1880, 1, 0)
    -- for auto-reconnect: m:connect("192.168.11.118", 1880, 0, 1)
    mClient:connect(coatIp, mqttPort, 0, 0, function(conn) 
        mClient:subscribe("/presence", 0, function(conn)
            print("subscribe success")
            mClient:publish("/presence", "hello ESP8266", 0, 0, function(conn) print("sent") end)
        end)
    end)

end)


if (wConf.ssid ~= nil and wConf.pwd ~= nil) then
    langate.startAsStation(wConf.ssid, wConf.pwd, 1000, 10, function (err, ip)
        evHub:emit('online', ip)
    end)
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