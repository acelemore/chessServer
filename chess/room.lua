local skynet = require"skynet"
local socket = require "skynet.socket"
local getStr = require "getString"
local sql = require "mysqlAddr"
local mysql = require "luasql.mysql"

local env = mysql.mysql()
local conn = env:connect('chessServer',sql.sqlUsr,sql.sqlPsw)

firstId = ...
firstId = tonumber(firstId)

playerFirst = ""
playerSecond = ""

local function idToken(token)
    local sqlstr = string.format([[select * from tokens where token = '%s']],token)
    local coursor,errorstring = conn:execute(sqlstr)
    if errorstring then
        return errorstring
    else
        local row = coursor:fetch({},"a")
        if row == nil then
            return "token unavailable"
        else 
            return "ok"
        end
    end
end
        
local function readSocket(id)
    local str = socket.read(id,4)
    if str then
        local str2 = socket.read(id,str-4)
        local strfinal = str..str2
        print(strfinal.."===room")
        local s = {}
        for k,v in string.gmatch(strfinal,"(%w+)=(%w+)") do
            s[k] = v
        end
        return s
    end
end

local function returnToLobby()
    local infoAddr = skynet.queryservice("serviceInfo")
    local addr1 = skynet.newservice("clientService",firstId)
    socket.abandon(firstId)
    local args1 = {}
    args1["name"] = playerFirst
    args1["addr"] = addr1
    skynet.call(infoAddr,"lua","new",args1)

    local addr2 = skynet.newservice("clientService",secondId)
    socket.abandon(secondId)
    local args2 = {}
    args2["name"] = playerSecond
    args2["addr"] = addr2
    skynet.call(infoAddr,"lua","new",args2)

    print("=======room closed=====")
    skynet.exit()
end



local function roundStart()
    socket.start(firstId)
    socket.start(secondId)
    local rec = readSocket(firstId)
    if idToken(rec["token"]) == "ok" then
        playerFirst = rec["player"]
        socket.write(firstId,getStr.stdMsg("cmd=ack;what=ok;"))
    else
        socket.write(firstId,getStr.stdMsg("cmd=denied;reason=unavailableToken;"))
    end

    local rec = readSocket(secondId)
    if idToken(rec["token"]) == "ok" then
        playerSecond = rec["player"]
        socket.write(secondId,getStr.stdMsg("cmd=ack;what=ok;"))
    else
        socket.write(secondId,getStr.stdMsg("cmd=denied;reason=unavailableToken;"))
    end

    
    socket.write(firstId,getStr.stdMsg("cmd=go;"))
    socket.write(secondId,getStr.stdMsg("cmd=go;"))
    
    while true do
        local rec = readSocket(firstId)
        if rec["cmd"] == "move" then
            local posX = rec["posX"]
            local posY = rec["posY"]
            socket.write(secondId,getStr.stdMsg(string.format("cmd=move;posX=%s;posY=%s;",posX,posY)))
        elseif rec["cmd"] == "end" then
            break
        end

        
        local rec = readSocket(secondId)
        if rec["cmd"] == "move" then
            local posX = rec["posX"]
            local posY = rec["posY"]
            socket.write(firstId,getStr.stdMsg(string.format("cmd=move;posX=%s;posY=%s;",posX,posY)))
        elseif rec["cmd"] == "end" then
            break
        end
        
    end

    returnToLobby()


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
            local ret = nil
            skynet.ret(skynet.pack(ret))
        end
    end
    )
    end
 )
