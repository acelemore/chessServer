local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local mysql = require "luasql.mysql"
local getStr = require "getString"
local uuid = require "genUuid"
local sql = require "mysqlAddr"

local env = mysql.mysql()
local conn = env:connect('chessServer',sql.sqlUsr,sql.sqlPsw)

local function echo(id)
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
			--登陆
			if (s["cmd"] == "login") then
				local sqlstr = string.format([[select * from users where usrname = '%s' and usrpsw = '%s']],s["name"],s["pass"])
				local coursor,errorstring = conn:execute(sqlstr)
				if errorstring then
					local str = getStr.stdMsg(string.format("cmd=denied;reason=%s;",errorstring))
					socket.write(id,str)
				else 
					local row = coursor:fetch({},"a")
					if row==nil then
						local str = getStr.stdMsg("cmd=denied;reason=No such user or wrong password;")
						socket.write(id,str)
					else
						local token = uuid.gen()
						local sqlstr = string.format([[insert into tokens (username,token) values ('%s','%s')]],s["name"],token)
						local coursor,errorstring = conn:execute(sqlstr)
						if errorstring then
							local str = getStr.stdMsg(string.format("cmd=denied;reason=%s;",errorstring))
							socket.write(id,str)
						else 
							local str = getStr.stdMsg(string.format("cmd=ok;token=%s;",token))
							socket.write(id,str)
                            local serviceaddr = skynet.newservice("clientService",id)
                            socket.abandon(id)
                            local infoAddr = skynet.queryservice("serviceInfo")
                            local args = {}
                            args["name"] = s["name"]
                            args["addr"] = serviceaddr
                            skynet.call(infoAddr,"lua","new",args)
						    return
                        end
					end
				end
			--注册
			elseif (s["cmd"] == "register") then
				local sqlstr = string.format([[select * from users where usrname = '%s']],s["name"])
				local coursor,errorstring = conn:execute(sqlstr)
				if errorstring then
					local str = getStr.stdMsg(string.format("cmd=denied;reason=%s;",errorstring))
					socket.write(id,str)
				else
					local row = coursor:fetch({},"a")
					if row == nil then
						local sqlstr = string.format([[insert into users (usrname,usrpsw) values ('%s','%s')]],s["name"],s["pass"])
						local coursor,errorstring = conn:execute(sqlstr)
						if errorstring then
							local str = getStr.stdMsg(string.format("cmd=denied;reason=%s;",errorstring))
							socket.write(id,str)
						else
							socket.write(id,getStr.stdMsg("cmd=ok;"))
						end
					else
						socket.write(id,getStr.stdMsg("cmd=denied;reason=user name already exsits;"))
					end
				end
			--强制下线
			elseif (s["cmd"] == "kick") then
				local sqlstr = string.format([[select * from users where usrname = '%s' and usrpsw = '%s']],s["name"],s["pass"])
				local coursor,errorstring = conn:execute(sqlstr)
				local row = coursor:fetch({},"a")
				if (row~=nil) then
					local sqlstr = string.format([[delete from tokens where username = '%s']],s["name"])
					local coursor,errorstring = conn:execute(sqlstr)
					socket.write(id,getStr.stdMsg("cmd=ok;"))
				end 
			end
		else
			socket.close(id)
			print("======client disconnect======")
			return
		end
	end
end

skynet.start(function()
	print("============ConnectService Start================")
	local id = socket.listen("0.0.0.0",8888)
	print("listening...")
	socket.start(id,function(id,addr)
		print("connect from" .. addr .. " " .. id)
		echo(id)
	end)
end
)


