# chessServer
使用skynet制作的黑白棋游戏服务器

学习skynet时撸出来的服务器，客户端信息使用mysql管理  

## 部署  
1. 需要skynet：https://github.com/cloudwu/skynet  
2. 将本项目克隆到skynet根目录下，修改common/mysqlAddr中的数据库用户名和密码  
3. 部署数据库（mysql）：登陆mysql后，执行sqlDeploy中的mysql语句  
4. 回到skynet根目录，执行./skynet chessServer/chess/config  

客户端：https://github.com/acelemore/chessClient  


