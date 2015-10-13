local nwkMgr = require 'nwkManager'
local timers = require 'timers'
local events = require 'events'
local langate = require 'langate'

local wifiConf = { ssid = nil, pwd = nil }
local coatAddr = { ip = nil, port = nil }
local mqttPort = nil
-- first try to read from config file

local eventHub = events:EventEmitter({})
local m = nil

--[[
 *************************************************************************
 * Main App                                                              *
 ************************************************************************* ]]
if (wifiConf.ssid ~= nil and wifiConf.pwd ~= nil) then
    loadListenres()
    nwkMgr.startAsStation('sivann', '26583302', 1000, 10, function ()
        eventHub:emit('online')
    end)
else
    print("\n")
    print("Please set the wireless router in 'init.lua'")
end


local function loadListenres()
    eventHub:once('online', function ()
        print('ESP8266 is now on the local network.')
        print('Searching for the coat server in LAN, please wait...')

        langate.serverAddrReq(function (err, servAddr)
            if (err ~= nil) then
                -- throw error
            end
            eventHub:emit('serv_addr', servAddr)
        end)
    end)

    eventHub:once('serv_addr', function (servAddr)
        print('coat server found: '.. servAddr.ip .. '@' .. servAddr.port)
        print('Query the mqtt broker service, please wait...')
        coatAddr.ip = servAddr.ip
        coatAddr.port = servAddr.port

        langate.serviceInfoReq('mqtt', function (err, serv)
            if (err ~= nil) then
                -- throw error
            end
            if (serv.name == 'mqtt') then eventHub:emit('mqtt_info', serv) end
        end)
    end)

    eventHub:once('mqtt_info', function (serv)
        print('MQTT broker found: ' .. coatAddr.ip .. '@' .. serv.port)
        mqttPort = serv.port
        eventHub:emit('connect_mqtt_broker', { ip = coatAddr.ip, port = mqttPort })
    end)

    eventHub:on('connect_mqtt_broker', function (mqttAddr)
        print('Connecting to MQTT broker...')
        local mac = nwkMgr.mac()

        m = mqtt.Client(mac, 120, "", "")

        m:lwt("/lwt", "offline", 0, 0)

        m:on("connect", function(con) 
            print ("Connect to ") 
        end)

        m:on("offline", function(con) print ("offline") end)

        m:on("message", function(conn, topic, data)
            print(topic .. ":" )
            if data ~= nil then
                print(data)
            end
        end)
        -- m:connect( host, port, secure, auto_reconnect, function(client) )
        -- for secure: m:connect("192.168.11.118", 1880, 1, 0)
        -- for auto-reconnect: m:connect("192.168.11.118", 1880, 0, 1)
        m:connect(mqttAddr.ip, mqttAddr.port, 0, 0, function(conn) 
            m:subscribe("/presence", 0, function(conn)
                print("subscribe success")
                m:publish("/presence", "hello ESP8266", 0, 0, function(conn) print("sent") end)
            end)
        end)
    end)
end
