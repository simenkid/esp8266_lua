local nwkMgr = require 'nwkManager'
local timers = require 'timers'
local events = require 'events'
-- local langate = require 'langate'

local wifiConf = { ssid = 'sivann', pwd = '26583302' }
local coatAddr = { ip = nil, port = nil }
local mqttPort = nil

local eventHub = {}
eventHub = events:EventEmitter(eventHub)
local LED = 1   -- GPIO5, D1
--[[
 *************************************************************************
 * Main App                                                              *
 ************************************************************************* ]]
gpio.mode(LED, gpio.OUTPUT, gpio.PULLUP)

eventHub:on('online', function ()
    print('ESP8266 is online.')
    local blinkCounts = 0
    local blinker

    blinker = timers.setInterval(function ()
        if (gpio.read(LED) == 1) then
            gpio.write(LED, gpio.LOW)
        else
            gpio.write(LED, gpio.HIGH)
        end

        blinkCounts = blinkCounts + 1
        if (blinkCounts == 10) then
            eventHub:emit('blink_over', blinker)
        end
    end, 1000)

    print(blinker)
end)

eventHub:on('blink_over', function (blker)
    print('blinker')
    print(blker)

    timers.clear(blker)
end)

if (wifiConf.ssid ~= nil and wifiConf.pwd ~= nil) then
    nwkMgr.startAsStation(wifiConf.ssid, wifiConf.pwd, 1000, 10, function ()
        eventHub:emit('online')
    end)
else
    print("\n")
    print("Please set the wireless router in 'init.lua'")
end
