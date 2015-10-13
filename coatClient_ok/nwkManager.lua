local nwkMgr = {}
local timers = require 'timers'

function nwkMgr.startAsStation (ssid, pwd, interval, repeats, callback)
    print("Setting up wifi mode as a STATION")
    wifi.setmode(wifi.STATION)
    wifi.sta.config(ssid, pwd)
    wifi.sta.connect()

    nwkMgr.requestIp(interval, repeats, callback)
end

function nwkMgr.mac ()
    return wifi.sta.getmac()
end

function nwkMgr.ip ()
    return wifi.sta.getip()
end

function nwkMgr.mode ()
    return wifi.getmode()
end

function nwkMgr.channel ()
    return wifi.getchannel()
end

function nwkMgr.status ()
    return wifi.sta.status()
end


function nwkMgr.requestIp (interval, repeats, callback)
    local cnt = 0
    local tId
    
    tId = timers.setInterval(function () 
        if (wifi.sta.getip() == nil) and (cnt < repeats) then
            cnt = cnt + 1
            print("IP is unavaiable, please wait...")
        else
            timers.clear(tId)
            if (cnt < repeats) then
                local wifiMode = wifi.getmode()
                local wifiStatus = wifi.sta.status()
                
                if (wifiMode == 1) then wifiMode = 'STATION'
                elseif (wifiMode == 2) then wifiMode = 'SOFTAP'
                elseif (wifiMode == 3) then wifiMode = 'STATIONAP' end

                if (wifiStatus == 0) then wifiStatus = 'STATION_IDLE'
                elseif (wifiStatus == 1) then wifiStatus = 'STATION_CONNECTING'
                elseif (wifiStatus == 2) then wifiStatus = 'STATION_WRONG_PASSWORD'
                elseif (wifiStatus == 3) then wifiStatus = 'STATION_NO_AP_FOUND'
                elseif (wifiStatus == 4) then wifiStatus = 'STATION_CONNECT_FAIL'
                elseif (wifiStatus == 5) then wifiStatus = 'STATION_GOT_IP' end
                
                print("Successfully connected.")
                print("  >> Mode: " .. wifiMode)
                print("  >> Channel: " .. wifi.getchannel())
                print("  >> MAC: " .. wifi.sta.getmac())
                print("  >> IP: " .. wifi.sta.getip())
                print("  >> STATUS: " .. wifiStatus)
                
                callback()
            else
                 print("Wifi setup time is more than " .. (interval*repeats/1000) .."s. Please check your settings with nwkMgr.startAsStation().")
            end            
        end
    end, interval) 
end

return nwkMgr
