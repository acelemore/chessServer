local skynet = require "skynet"
local socket = require "skynet.socket"
local mysql = require "luasql.mysql"
local getStr = require "getString"
local sql = require "mysqlAddr"

local env = mysql.mysql()
local conn = env:connect('chessServer',sql.sqlUsr,sql.sqlPsw)

id = ...
id = tonumber(id)

matching = false

--验证token 
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

local function closeService()
    local sqlstr =string.format([[delete from tokens where username = '%s']],player)
    local coursor,errstring = conn:execute(sqlstr)
    if errorstring then
        print("sql"..errstring)
    end
    sqlstr = string.format([[delete from players where player = '%s']],player)
    coursor,errstring = conn:execute(sqlstr)
    if errorstring then
        print("sql"..errstring)
    end
    print("========Client Lobby Service Stop========")
    skynet.exit()
end
--接受匹配处理函数
local function match(challangerAddr)
    if(matching == false) then
        matching = true
        cAddr = challangerAddr
        socket.write(id,getStr.stdMsg("cmd=ask;what=newMatch;"))
        return 0
    else
        return -1
    end    
end

--匹配确认
local function ackMatch(room)
    socket.write(id,getStr.stdMsg("cmd=ack;what=matchAccapted;"))
    local args = {}
    args["id"] = id
    skynet.call(room,"lua","joinSecond",args)
    socket.abandon(id)
    --socket.abandon(id)
    --local args = {}
    --args["name"] = player
    --skynet.call(infoAddr,"lua","delete",args)
    --skynet.exit()
end

--匹配拒绝
local function deMatch()
    socket.write(id,getStr.stdMsg("cmd=ack;what=matchDenied;"))
end



local function work(id)
    socket.start(id)
    while true do 
        local str = socket.read(id,4)
        if str then
            local str2 = socket.read(id,str-4)
            local strfinal = str..str2
            print(strfinal)
            local s = {}
            for k,v in string.gmatch(strfinal,"(%w+)=(%w+)") do
                s[k] = v
            end
        --处理请求
            --刷新大厅
            if(s["cmd"] == "refresh") then
                player = s["player"]
                local check = idToken(s["token"])
                if check == "ok" then
                    local sqlstr = [[select * from players limit 0,20]]
                    local coursor,errstring = conn:execute(sqlstr)
                    if errorstring then
                        socket.write(id,getStr.stdMsg(string.format("cmd=denied;reason=%s;",errorstring)))
                    else
                        local playerList = ""
                        row = coursor:fetch({},"a")
                        while row do
                            playerList = playerList..row.player..","
                            row = coursor:fetch(row,"a")
                        end
                        socket.write(id,getStr.stdMsg(string.format("cmd=ok;players=%s;",playerList)))
                    end                    
                else
                    socket.write(id,getStr.stdMsg("token unavailable"))
                end
            --匹配请求
            elseif(s["cmd"] == "match") then
                local check = idToken(s["token"])
                if check == "ok" then
                    infoAddr = skynet.queryservice("serviceInfo")
                    player = s["player"]
                    local args = {}
                    args["name"] = s["opponent"]
                    local opponentAddr = skynet.call(infoAddr,"lua","get",args)
                    local args2 = {}
                    args2["addr"] = skynet.self()
                    local ret = skynet.call(opponentAddr,"lua","match",args2)
                    socket.write(id,getStr.stdMsg("cmd=ack;what=wait"))
                    if ret == -1 then
                        socket.write(id,getStr.stdMsg("cmd=ack;what=busy;"))
                    end
                    
                else
                    socket.write(id,getStr.stdMsg("token unavailable"))
                end
            --准备
            elseif(s["cmd"] == "ready") then
                local check = idToken(s["token"])
                if check == "ok" then
                    player = s["player"]
                    local sqlstr = string.format([[insert into players (player) values ('%s')]],s["player"])
                    local coursor,errstring = conn:execute(sqlstr)
                    if errstring then
                        print("sql:"..errstring)
                    end
                    socket.write(id,getStr.stdMsg("cmd=ack;what=ok;"))

                else
                    socket.write(id,getStr.stdMsg("token unavailable"))
                end

            --匹配回应
            elseif(s["cmd"] == "ack") then
                local check = idToken(s["token"])
                if check == "ok" then
                    if s["what"] == "ok" then
                        print("=====debug=====")
                        local roomAddr = skynet.newservice("room",id)
                        socket.write(id,getStr.stdMsg("cmd=ack;what=ok;"))
                        socket.abandon(id)
                        local args = {}
                        args["room"] = roomAddr
                        skynet.call(cAddr,"lua","ackMatch",args)
                        closeService()
                    else
                        skynet.call(cAddr,"lua","deMatch")
                        socket.write(id,getStr.stdMsg("cmd=ack;what=ok;"))
                        sqlstr = string.format([[delete from players where player = '%s']],player)
                        coursor,errstring = conn:execute(sqlstr)
                        if errorstring then
                            print("sql"..errstring)
                        end
                    end
                    matching = false




                else
                    socket.write(id,getStr.stdMsg("token unavailable"))
                end



            end
        else
            socket.close(id)
            closeService()
            return
        end
    end
end


skynet.start(function()
    print("============Client Lobby Service Start===========")
    skynet.fork(function()
        skynet.sleep(50)
        work(id)
    end)

    skynet.dispatch("lua",function(session,address,cmd,...)
            if cmd == "match" then
                local args = ...
                local ret = match(args["addr"])
                skynet.ret(skynet.pack(ret))
            elseif cmd == "deMatch" then
                local ret = deMatch()
                skynet.ret(skynet.pack(ret))
            elseif cmd == "ackMatch" then
                local args = ...
                local ret = ackMatch(args["room"])
                skynet.ret(ret)
                closeService()
            end

        end
        )
end
    )
