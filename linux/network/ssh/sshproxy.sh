#!/bin/sh
#========远程转发======
#代理服务器地址 (在该服务器上面的sshd_config中将GatewayPorts 设为yes)
remoteAddr=

#代理服务器登录用户名
remoteUser=

#代理服务器登录端口
remotePort=22

#代理服务器远程转发端口
proxyPort=1998

#登录代理服务器的密钥
key="~/.ssh/id_rsa"

#本地地址
localAddr=localhost

#本地用户名
localUser=

#本地端口
localPort=22

#======
#curl验证网络状况
networkstate=`curl $remoteUser`

#查找进程中是否已经存在指定进程
tunnelstate=`ps aux | grep ${remotePort} | grep ssh | grep -v grep`

#如果网络畅通 并且本地无该服务运行 则重建转发
if [[ -n "$networkstate" && -z "$tunnelstate" ]]
then
  ssh -i ${key} -fCNRg ${proxyPort}:${localAddr}:${localPort} ${remoteUser}@${remoteAddr} -p ${remotePort}
fi
#ssh参数说明
#-f 后台执行
#-C 压缩数据
#-N 不要执行远程命令
#-R 远程转发
#-g 允许远程主机连接转发端口