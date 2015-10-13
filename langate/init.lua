local evHub = require 'evHub'
local langate = require 'langate'

local wConf = { ssid = 'sivann', pwd = '26583302' }
local coatAddr = langate.coatAddr
local mqttPort = nil
local mClient = nil
local LED = 1   -- GPIO5, D13

gpio.mode(LED, gpio.OUTPUT, gpio.PULLUP)
--[[
 *************************************************************************
 * Main App                                                              *
 ************************************************************************* ]]
evHub:once('online', function (ip)
    print('ESP8266 is now online with ip: ' .. ip)
    print('Searching for coat server...')

    langate.requestCoatAddr(function (err, servAddr)
        if (err ~= nil) then print(err)
        else evHub:emit('got_coat', servAddr) end
    end)
end)

evHub:once('got_coat', function (servAddr)
    print('Coat found: '.. coatAddr.ip .. '@' .. coatAddr.port)
    print('Querying mqtt broker...')

    langate.serviceInfoReq('mqtt', function (err, serv)
        if (err ~= nil) then print(err) end
        if (serv.name == 'mqtt') then evHub:emit('mqtt_info', serv) end
    end)
end)

evHub:once('mqtt_info', function (serv)
    print('MQTT broker found: ' .. coatAddr.ip .. '@' .. serv.port)
    mqttPort = serv.port
    evHub:emit('mqtt_connect', { ip = coatAddr.ip, port = mqttPort })
end)

evHub:once('mqtt_connect', function (serv)
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
    mClient:connect(langate.coatAddr.ip, mqttPort, 0, 0, function(conn) 
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