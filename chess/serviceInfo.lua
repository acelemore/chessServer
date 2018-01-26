local skynet = require "skynet"


local services = {}

function new(name,addr)
    services[name] = addr
    print("....new name..."..name)
    print("....new addr..."..skynet.address(addr))
    return 0
end

function get(name)
    print("...get name..."..name)
    print("...get addr..."..skynet.address(services[name]))
    return services[name]
end

function delete(name)
    services[name] = nil
    return 0
end

function dispatcher()
    skynet.dispatch("lua",function(session,address,cmd,...)
        local arg = ...
        if cmd == "new" then
            local ret = new(arg["name"],arg["addr"])
            skynet.ret(skynet.pack(ret))
        elseif cmd == "get" then
            local ret = get(arg["name"])
            skynet.ret(skynet.pack(ret))
        elseif cmd == "delete"then
            local ret = delete(arg["name"])
            skynet.ret(skynet.pack(arg["name"]))
        end
    end)
end

skynet.start(dispatcher)

