# 安装

安装`ntp`包并启用`ntpd`服务。

# 配置

配置`/etc/ntpd.conf`示例概览：

```shell
restrict 192.168.0.251 noquery  #禁止该主机查询时间
restrict 192.168.0.0 mask 255.255.255.0 nomodify  #禁止该网段来源的主机修改时间

#以下两个是默认值
restrict 127.0.0.1
restrict -6 ::1     #ipv6使用

server 0.arch.pool.ntp.org  #同步时间的服务器
server 1.arch.pool.ntp.org prefer  #优先使用该服务器
fudge  127.127.1.0 stratum 10  #注意，如果采用本机内部时钟 使用127.127.1.0而非127.0.0.1

driftfile /var/ntp/driftfile
```

如果一台设备只作为ntp客户端，只设置server信息即可。

## restrict限制权限

`restrict <ip> [mask <netmask>] [parameter]`

当该设备作为ntp服务器时，才有设置strict的必要，restrict是对客户端进行权限设置的。

设置指定ip或网段的主机的权限。如果parameter处不添加任何内容，即对该IP或该网段不进行任何限制。

其可以取以下值：

- ignore： 拒绝所有类型的 NTP 联机
- nomodify： 客户端不能使用 ntpc 与 ntpq 这两支程序来修改服务器的时间参数
- noquery： 客户端不能够使用 ntpq, ntpc 等指令查询时间服务器
- notrap： 不提供 trap 这个远程事件登录 (remote event logging) 的功能
- notrust： 拒绝没有认证的客户端

## server设置ntp服务器

`server <ip or hostname> [prefer]`

设置时间服务器，本机作为客户端，获取时间服务器的时间信息，设置为本机的时间。

如果配置文件中有多个server，添加了`prefer`的server将被优先采用。

## driftfile 记录时间差异

`driftfile <absolute file path>`

ntpd会自动计算该主机的频率与上层  Time server 的频率，并且将两个频率的误差记录下来。（该误差的记录的单位是百万分之一秒 --ppm）。

# 时间相关常用命令

- `ntpq -p` 查看ntp同步状态

  `watch ntpq -p`  监控同步状态 （其中reach一项的值增加到17时同步完成）

- 查看时间  `date`

- 查看时间相关设置情况  `timedatectl` （包括本地时间、通用时间、硬件时钟、时区、NTP启用情况等等）

- 手动同步 `ntpdate <time  server>` 从指定服务器同步时间

- 写入到硬件实时时钟（Real Time Clock, RTC）

  - 读取硬件时钟的时间 `hwclock -r`（或`--show`）
  - 将当前系统时间写入硬件时钟 `hwclock -w`（或`--systohc`）
  - 将系统时间写入硬件实时时钟，且使用了UTC时间作为标准  `hwclock -w -u` （`-u`也可写为`--utc`）
  - 校准时间漂移  `hwclock -a`（或`--adjust`）

- 设置时区（以Asia/Shanghai为例） `ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime`

  也可以使用`tzselect`选择。

