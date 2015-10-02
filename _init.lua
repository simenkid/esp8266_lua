local nwkMgr = require '_nwkManager'

if true then  --change to if true
    nwkMgr.startAsStation('sivann', '26583302', 1000, 10, function ()
        print('done')
        -- run udp broadcast to get hiver server ip
        -- if server ip ok
        --  then ask for mqtt service (which port, and get a client id)
        -- if mqtt is served by hiver
        --  then create mqtt client and connect to the broker
        --      if connect successful
        --          which topic to subscribe
        --          which topic to publish
    end)
else
    print("\n")
    print("Please edit 'init.lua' first:")
    print("Step 1: Modify wifi.sta.config() function in line 5 according settings of your wireless router.")
    print("Step 2: Change the 'if false' statement in line 1 to 'if true'.")
end
