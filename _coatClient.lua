local coatClient = {}

function coatClient.findServer()
end

function coatClient.queryService()
end

function coatClient.connectToBroker()
    -- default subscription
    -- /mqtt/register
        -- if register ok
        --  /mqtt/clientid/action
    -- default publish
    -- /mqtt/register
        -- if register ok
        --  /mqtt/clientid
end

function coatClient.registerToCoat(deviceInfo)
    m:publish("/mqtt/register", deviceInfo, 0, 0, function(conn)
        print("sent")
    end)
end

return coatClient
