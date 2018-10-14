本文基于centos7.x，其余发行版或有出入。

[TOC]

# 服务端

安装`samba`，启用`smb`和`nmb`服务（提示：根据发行版不同，服务名也可能是`smbd`和`nmbd`)。

## 配置

### 主配置文件`/etc/samba/smb.conf`

```shell
[global]     #定义全局策略
    workgroup = WORKGROUP
    netbios name  = samba-server
    server string = Samba Server Version %v
    log file = /var/log/samba/log.%m
    max log size = 50
    security = user
    passdb backend = tdbsam
    load printers = yes
    cups options = raw
    
[homes]
    comment = Home Directories
    browseable = no
    writable = yes
     valid users = %S
    
[printers]
    comment = All Printers
    path = /var/spool/samba
    browseable = no
    guest ok = no
    writable = no
    printable = yes
    
[share]
    comment = Share Directory
    path = /home/share
    create mask = 0750
    directory mask = 0775
    browseable = yes 
    writable= no
    #write list = tom
    #admin users = tom
    invalid users = root bin
    guest ok = no
```

配置中常用变量：

- %S：取代目前的设定项目值（即`[ ]`中的内容）
- %m：客户机的 NetBIOS 主机名
- %M：客户机的 Internet  主机名（hostname）
- %L：服务器 NetBIOS 主机名
- %H：用户的家目录
- %U：目前登入的使用者的名称
- %g：目前登入的使用者的组名
- %h：目前服务器的hostname
- %I：客户机的 IP
- %T：目前的日期与时间

使用`testparam`命令检测配置文件语法是否正确。

### 添加用户

samba的用户名可以和linux系统用户名共用，但是仍需创建单独的密码（可以同系统用户名密码相同），设置密码示例：

```shell
smbpasswd -a username  #为用户添加密码
smbpasswd username  #修改用户的samba密码
```

- 启动服务`smb`（也可能名为`smbd` ）

# 客户端

示例要挂载的服务器地址及路径为`192.168.0.123/home/share`，本地路径为`/home/smb` 。

## linux

- 命令行

  - 使用`cifs-utils`

    ```shell
    mount -t cifs //192.168.0.123/home/share  /home/smb -o 
    ```

  - 使用`samba-client`（包名或为`smbclient` ）


- 图形界面

  文件管理器中连接服务器地址栏输入：`smb://samba服务器地址/路径`


## windows

运行，输入`\\192.168.0.123/home/share`