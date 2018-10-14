

# 网络

## network和NetworkManager

CentOS7默认开启NetworkManager服务。

- network和NetworkManager不能同时生效，如果两个服务同时存在，则默认启用NetworkManager。
- 如果在安装时配置了网络参数，或者`/etc/network/interfaces`文件中进行了手动配置，则会默认启用network服务。

- 使用network

  1. 配置连接参数，可以使用以下方法：

     - 安装时配置网络相关参数，启用网口连接

     - 在安装后进入系统，修改`/etc/sysconfig/network-scripts/`文件目录下网口配置文件——文件名以`ifcfg-`加网口名组成，如`ifcfg-eth0`，该文件部分行内容：

       ```shell
       NAME="eth0"
       HWADDR="52:54:00:04:b5:bd"
       ONBOOT=yes  #默认no 改为yes则开机后自动连接
       UUID="0ae73759-59a7-4505-a245-c58a1e8924da"
       IPV6INIT=yes
       BOOTPROTO=none  #参数none未设置 static静态  dhcp自动分配
       IPADDR="192.168.100.3"  #静态ip 设置了BOOTPROTO为static时生效
       NETMASK="255.255.255.0"
       GATEWAY="192.168.100.1"
       TYPE=Ethernet
       DNS1="192.168.100.1"
       ```

  2. 关闭`NetworkManger`服务，然后重启network服务（或重启系统）。

- 使用NetworkManager

  连接方式

  - （有图形界面时可）使用图形界面工具联网

  - nmtui（可在终端中使用的基于curses的图形化前端）

  - nm命令（具体可参看[redhat docs](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/networking_guide/sec-using_the_networkmanager_command_line_tool_nmcli)

    ```shell
    nmcli connection show  #显示所有链接
    nmcli connection show --active  #或-a 显示当前活动链接
    nmcli dev wifi connect 热点名称 password 密码  #连接到一个wifi热点
    nmcli dev connect eth0  #dev是device的简写 连接到eth0
    nmcli dev disconnect eth0  #从eth0断开
    nmcli con edit  #交互式编辑 可在edit后指定网口名如eth0
    ```

# 常用源

- epel
- yum-utils

可以直接使用yum安装这些源

``` shell
yum repolist  #查看所有yum源
yum install epel-release  yum-utils #安装
yum makecache  #更新yum 缓存
yum update  #更新一下
```
# 防火墙和selinux

centos7默认启用firewall和selinux进行安全策略配置。如果要关闭二者，参考如下：

- 关闭防火墙

  ```shell
  systemctl stop firewalld.service
  systemctl disable firewalld.service
  ```


- 关闭selinux

  - 查看selinux状态  `getenforce`
  - 临时关闭：`setenforce 0`
  - 永久关闭：编辑`/etc/sysconfig/selinux`，将其中的`SELINUX=enforcing`修改为`SELINUX=disabled`，重启后生效（也可执行`setenforce 0`暂时关闭）。

# 安装桌面

以安装gnome为例

```shell
yum groupinstall "GNOME Desktop" -y
systemctl set-default graphical.target
#cent7以下系统 修改/etc/inittab文件 将默认启动从3改为5
```

# 常用工具

某些工具在最小化安装后可能未提供，使用`yum provides 命令`来查询该命令属于哪个软件包，例如：`yum provides lspci`查询得知lspci命令由pciutils软件包提供。

这里列出一些常用命令对应的软件包名：

- `lspci`  -- pciutils
- `killall`  -- psmisc