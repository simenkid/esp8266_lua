local nwkMgr = {}

function nwkMgr.startAsStation (ssid, pwd, interval, repeats, callback)
    print("Setting up wifi mode as a STATION")
    wifi.setmode(wifi.STATION)
    wifi.sta.config(ssid, pwd)
    wifi.sta.connect()

    nwkMgr.getIp(interval, repeats, callback)
end

function nwkMgr.getIp (interval, repeats, callback)
    local cnt = 0
   
    tmr.alarm(1, interval, 1, function () 
        if (wifi.sta.getip() == nil) and (cnt < repeats) then 
            cnt = cnt + 1
            print("IP is unavaiable, please wait...")
        else
            tmr.stop(1)
            if (cnt < repeats) then
                local wifiMode = wifi.getmode()
                local phyMode = 1
                local wifiStatus = wifi.sta.status()
                
                if (wifiMode == 1) then
                    wifiMode = 'STATION'
                elseif (wifiMode == 2) then
                    wifiMode = 'SOFTAP'
                elseif (wifiMode == 3) then
                    wifiMode = 'STATIONAP'
                end

                
                if (phyMode == 1) then
                    phyMode = '802.11b'
                elseif (phyMode == 2) then
                    phyMode = '802.11g'
                elseif (phyMode == 3) then
                    phyMode = '802.11n'
                end

                
                if (wifiStatus == 0) then
                    wifiStatus = 'STATION_IDLE'
                elseif (wifiStatus == 1) then
                    wifiStatus = 'STATION_CONNECTING'
                elseif (wifiStatus == 2) then
                    wifiStatus = 'STATION_WRONG_PASSWORD'
                elseif (wifiStatus == 3) then
                    wifiStatus = 'STATION_NO_AP_FOUND'
                elseif (wifiStatus == 4) then
                    wifiStatus = 'STATION_CONNECT_FAIL'
                elseif (wifiStatus == 5) then
                    wifiStatus = 'STATION_GOT_IP'
                end
                
                print("Successfully connected.")
                print("  >> Mode: " .. wifiMode)
                print("  >> Channel: " ..  wifi.getchannel())
                print("  >> PHY Mode: " ..  phyMode)
                print("  >> MAC: " ..  wifi.sta.getmac())
                print("  >> IP: " ..  wifi.sta.getip())
                print("  >> STATUS: " .. wifiStatus)
                
                callback()
            else
                 print("Wifi setup time is more than " .. (interval*repeats/1000) .."s. Please check your settings with nwkMgr.startAsStation().")
            end
        end
    end)    
end

return nwkMgr
