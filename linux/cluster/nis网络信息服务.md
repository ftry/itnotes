[TOC]

# 简介

在 NIS 环境中， 有三种类型的主机： 主服务器， 从服务器， 以及客户机。nis系列工具主要包括：

- ypserv   ：NIS Server 端工具
- rpcbind  ： 远程过程调用(Remote Procedure Call)协议支持
- ypbind   ：NIS Client 端工具
- yp-tools ：提供 NIS 相关的工具

# 服务端

## 安装

安装 `ypserv` `rpcbind`

启用`ypserv` `yppasswdd` 并设置开机自启动。

NIS 服务器同时也当成客户端，参看后文[客户端](#客户端)。

## 配置

### nis网域设定/etc/sysconfig/network

编辑`/etc/sysconfig/network`，添加网域名称和端口，示例：

```shell
NETWORKING=yes
HOSTNAME=master
NISDOMAIN=cluster
YPSERV_ARGS="-p 1011" #可选 指定运行端口
```

###  *主配置文件/etc/ypserv.conf

可选，可直接使用预设值。配置允许/禁止访问NIS服务器的网域，编辑`etc/ypserv.conf`，添加类似：

```shell
127.0.0.0/255.255.255.0     : * : * : none
192.168.100.0/255.255.255.0 : * : * : none
* : * : * : deny
```

### 主机名解析/etc/hosts

可选。可配置服务器ip对应的域名方便访问，添加类似：

```shell
192.168.100.101  master.cluster
```

### *nis客户端密码修改功能

可选，该配置启用可启用NIS 用户端的密码修改功能。

centos的配置在`/etc/sysconfig/yppasswdd `，编辑该文件，修改配置，添加yppasswd的启用端口：

```shell
YPPASSWDD_ARGS="--port 1012"
```

## 建立用户帐号资料库

示例

1. 创建用户`useradd -u 1001 user1;passwd user1`

2. 运行` /usr/lib64/yp/ypinit -m`生成用户帐号资料库：
   1. 第一次出现的`next host to add:`之后会自动填入当前系统主机名，按下`ctrl`-`d`即可
   2. `is this correct?`询问时，如果信息无误，按下`y`即可。

   如果运行出现错误则根据错误提示信息进行解决后再生成资料库。

   如果无需配置hosts，直接执行`make -C /var/yp`生成资料库即可。

3. 重启`ypserv`服务

## 测试

查看启用情况：

```shell
rpcinfo -p localhost | grep -E '(portmapper|yp)'
rpcinfo -u localhost ypserv
```

第一条查询命令会看到postmapper、 ypserv（该示例中为1011端口）、yppasswdd（该示例中为1012端口）的端口。第二条查询命令会看到类似：

> program 100004 version 1 ready and waiting
>
> program 100004 version 2 ready and waiting

# 客户端

## 安装

安装`ypbind` `yp-tools`

启用`rpcbind`和`ypbind`服务并设置开机自启动。

## 配置

### nis网域设置

编辑`/etc/sysconfig/network`，添加：

```shell
NISDOMAIN=cluster
```

### 主配置文件/etc/yp.conf

编辑`/etc/yp.conf`，添加类似：

```shell
domain domainname server 192.168.10.1  #domainname换成实际的域名
```

### 服务搜索顺序/etc/nsswitch.conf 

`/etc/nsswitch.conf`用于管理系统中多个配置文件查找的顺序，系统将按照配置中的顺序去查找用户信息文件。

编辑该文件，在`passwd`、`shadow`和`group`添加`nis`（或`nisplus`），类似：

```shell
passwd:  files nis
shadow:  files nis
group:  files nis
```

### 系统认证/etc/sysconfig/authconfig

编辑` /etc/sysconfig/authconfig`， 修改`USENIS`的值为`yes` ；或者运行`authconfig-tui`，选择nis后保存。

### 测试

重启`rpcbind`和`ypbind`服务并设置开机自启动。

- 使用检测工具，如`yptest` `ypwhich` `ypcat` 。

  简单使用：

  ```shell
  yptest  #测试连接情况
  ypwhich  #显示服务器主机名
  ypwhich -x  #显示所有服务端与客户端连线共用的资料库
  ypcat hosts.byname  #查看服务端与客户端共用的hosts资料库内容
  ```

  - `yptest`会进行各项连接检测
  - `ypwhich`可以检查

- 如果连接成功，即可在客户端登录在服务端建立的账号。

  ```shell
  su - nis1  #切换到服务端建立的nis1账户
  # 登录成功
  whoami  #检查以下当前用户
  ```

- 在nis上修改用户相关参数

  - 修改密码 `yppasswd`   --功能同`passwd`
  - 修改shell  `ypchsh`  --功能同`chsh`
  - 修改finger  `ypchfn`  --功能同`chfn`

