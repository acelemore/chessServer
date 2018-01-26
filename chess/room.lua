local skynet = require"skynet"
local socket = require "skynet.socket"
local getStr = require "getString"

firstId = ...
firstId = tonumber(firstId)

local function roundStart()
    socket.start(firstId)
    socket.start(secondId)
    socket.write(firstId,getStr.stdMsg("test1"))
    socket.write(secondId,getStr.stdMsg("test2"))



end




skynet.start(function()
    print("===========room create==================")
    skynet.dispatch("lua",function(session,address,cmd,...)
        local args = ...
        if cmd == "joinSecond" then
            secondId = args["id"]
            skynet.fork(function()
                roundStart()
            end
            )
        end
    end
    )
    end
 )
