[TOC]



DHCP，动态主机配置协议(Dynamic Host Configuration Protocol)。

> 自动的将**网络参数**正确的**分配**给网络中的每部计算机，让**客户端的计算**机可以在开机的时候就立即自动的设定好网络的参数值，这些参数值可以包括了 IP、netmask、network、gateway与 DNS 的地址等。

DHCP 服务器给予客户端的 IP 参数主要有两种：固定（或静态）IP和动态IP。

注意：多个DHCP服务器在同一物理网段中时，客户端计算机分配到的网络参数信息来自于最先响应的那个服务器。因此在已经正常运作的网络中运行新的DHCP服务器的地址池设置需慎重（或者直接关闭地址池），因为这极可能对同一网段中的其他正在获取IP的设备连接到新部署的DHCP服务器。

主要配置文件为`/etc/dhcp/dhcpd.conf` ，配置示例：

```shell
ddns-update-style            none;          #是否更新 DDNS 的设定
ignore client-updates;                        #忽略客户端的 DNS 更新功能
default-lease-time           259200;          #预设租约时间 单位为秒
max-lease-time               518400;          #最大租约时间
option routers               192.168.10.1;   #预设路由的ip地址（DHCP服务器的ip）
option domain-name           "xxx.com";   #指定域名
option domain-name-servers   168.95.1.1, 139.175.10.20;  # DNS 的 IP 设定

# 动态分配的 IP
subnet 192.168.100.0 netmask 255.255.255.0 {
    range 192.168.100.101 192.168.100.200;   #分配的 IP 范围

# 固定的IP
    host  servername {    #servername是该主机的名字（hostname）
        hardware ethernet    08:00:27:11:EB:C2;   #客户端网卡 MAC
        fixed-address        192.168.100.30;    #分配的 IP
    }
}
```

对于客户机较少的情况，也可以直接将域名解析信息写到`/etc/hosts` 。搭建DNS服务器参看：xxx



# dnsmasq