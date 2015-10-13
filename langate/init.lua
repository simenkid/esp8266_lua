local evHub = require 'evHub'
local langate = require 'langate'

local wConf = { ssid = 'sivann', pwd = '26583302' }
local coatAddr = langate.coatAddr
local mqttPort = nil
local LED = 1   -- GPIO5, D13
gpio.mode(LED, gpio.OUTPUT, gpio.PULLUP)
--[[
 *************************************************************************
 * Main App                                                              *
 ************************************************************************* ]]
evHub:once('online', function (ip)
    print('ESP8266 is now online with ip: ' .. ip)
    print('Searching coat server, wait...')

    langate.requestCoatAddr(function (err, servAddr)
        if (err ~= nil) then
            print(err)
            tmr.alarm(2, 200, 1, function ()
                if (gpio.read(LED) == 1) then
                    gpio.write(LED, gpio.LOW)
                else
                    gpio.write(LED, gpio.HIGH)
                end
            end)
        else evHub:emit('got_coat', servAddr) end
    end)
end)

evHub:once('got_coat', function (servAddr)
    print('Coat found: '.. coatAddr.ip .. '@' .. coatAddr.port)
    print('Query mqtt broker, wait...')

    langate.serviceInfoReq('mqtt', function (err, serv)
        if (err ~= nil) then print(err) end
        if (serv.name == 'mqtt') then evHub:emit('mqtt_info', serv) end
    end)
end)

evHub:once('mqtt_info', function (serv)
    print('MQTT broker found: ' .. coatAddr.ip .. '@' .. serv.port)
    mqttPort = serv.port
    -- evHub:emit('connect_mqtt_broker', { ip = coatAddr.ip, port = mqttPort })

    tmr.alarm(3, 1000, 1, function ()
        if (gpio.read(LED) == 1) then
            gpio.write(LED, gpio.LOW)
        else
            gpio.write(LED, gpio.HIGH)
        end
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
