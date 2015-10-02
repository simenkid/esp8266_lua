-- init mqtt client with keepalive timer 120sec
m = mqtt.Client("esp8266ssss", 120, "", "")

-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline"
-- to topic "/lwt" if client don't send keepalive packet
m:lwt("/lwt", "offline", 0, 0)

m:on("connect", function(con) 
    print ("connected2") 
end
)
m:on("offline", function(con) print ("offline") end)

-- on publish message receive event
m:on("message", function(conn, topic, data)
    print(topic .. ":" )
    if data ~= nil then
        print(data)
    end
end)

-- m:connect( host, port, secure, auto_reconnect, function(client) )
-- for secure: m:connect("192.168.11.118", 1880, 1, 0)
-- for auto-reconnect: m:connect("192.168.11.118", 1880, 0, 1)
m:connect("192.168.1.108", 1883, 0, 0, function(conn) 
    print("connected1")
    m:subscribe("/presence", 0, function(conn)
        print("subscribe success")
        m:publish("/presence", "hello ESP8266", 0, 0, function(conn) print("sent") end)
    end)
end)

