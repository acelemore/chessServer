# chessServer
使用skynet制作的黑白棋游戏服务器

学习skynet时撸出来的服务器，客户端信息使用mysql管理

main.lua----启动
connectService.lua---连接服务，负责验证用户的连接，发放token，验证成功后会创建新clientService服务并将套接字的控制权转交给新服务
clientService.lua---客户服务，负责处理客户的请求，如刷新大厅名单等
room.lua---对战房间，游戏在这里进行
serviceInfo.lua---负责记录当前服务器上所有服务的地址，方便服务间进行通讯
