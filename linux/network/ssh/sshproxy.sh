#!/bin/sh
#========远程转发======

#代理服务器地址 (在该服务器上面的sshd_config中将GatewayPorts 设为yes)
remoteAddr=

#代理服务器登录用户名
remoteUser=

#代理服务器登录端口
remotePort=22

#远程转发端口
proxyPort=

#本地地址
localAddr=localhost

#本地用户名
localUser=root

#本地端口
localPort=22

#密钥
key="~/.ssh/id_rsa"

#curl获取z.cn信息验证网络状况
networkstate=`curl z.cn`

#查找进程中是否已经存在指定进程
tunnelstate=`ps aux | grep ${remotePort} | grep ssh | grep -v grep`

if [[ -z "$networkstate" && -z "$tunnelstate" ]] #网络是通的
then
  ssh -i ${key} -fCNR ${proxyPort}:${localAddr}:${localPort} ${remoteUser}@${remoteAddr} -p ${remotePort}
fi
