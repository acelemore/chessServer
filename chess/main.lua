local skynet = require "skynet"

skynet.start(function()
	print("==========Server Start=============")

	skynet.newservice("connectService")
    skynet.uniqueservice("serviceInfo")
	skynet.exit()
end
	)
