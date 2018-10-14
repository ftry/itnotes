# DNS服务器

## bind

 [BIND](https://www.isc.org/downloads/bind/) (Berkeley Internet Name Daemon，伯克利互联网名称服务）。

1. 安装bind。

2. 配置

   如果安装了bind-chroot，BIND会被封装到一个伪根目录内，配置文件的位置变为：
   `/var/named/chroot/etc/named.conf`和`/var/named/chroot/var/named/`

   - `/etc/named.conf`（bind配置文件）

     ```shell
     options{
         directory "/var/named";
     };
     
     zone "example.com" {
         type master;
         file "example.com.zone";
     }
     ```

   - `/var/named/*.zone`  zone文件（域的dns信息）
     ``/var/named/example.com.zone`文件示例：

     ```shell
     $TTL 3600;
     @ IN SOA example.com. user1.example.com. (222 1H 15M 1W 1D)
     @ IN NS dns1.example.com.
     dns1 IN A 123.123.123.123
     www IN A 233.233.233.233
     ```

3. 启用`named`服务。

## dnsmasq

[Dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) 提供 DNS 缓存和 DHCP 服务功能。



TTL值
 TTL值全称是“生存时间（Time To Live)”，表示解析记录在DNS服务器中的缓存时间，`TTL`的时间长度单位是秒。

# 域名解析类型

## A和AAAA

- A (Address) 记录： 指定主机名（或域名）对应的IPv4地址。
- AAAA记录： 指定主机名（或域名）对应的IPv6地址。

例如：域名/主机名---A记录--->IP

## PTR

A/AAAA记录的逆向记录，将IP反向解析为域名。

## CNAME

**别名**记录。将一个域名指向另一个域名（别名），实现与被指向域名相同的访问效果。 

在将多个域名指向同一访问目标的场景中，使用CNAME将解析指向一个同一的别名，方便管理。例如：

域名1---CNAME记录--->域名x---A记录--->IP

域名2---CNAME记录--->域名x---A记录--->IP

...

域名n---CNAME记录--->域名x---A记录--->IP

## MX

MX（Mail Exchanger）邮件交换记录：指向邮件服务器。

例如：user@example.com---MX记录--->IP

## NS记录

域名解析服务器记，将子域名指定某个域名服务器来解析，需要设置NS记录。

- NS记录只对子域名生效。

- “优先级”中的数字越小表示级别越高；
- NS记录优先于A记录。

例如：sub.example.com---NS记录--->IP

## SOA

起始授权机构记录，用于在众多NS记录中哪一台是主服务器。

## SRV记录
添加服务记录服务器服务记录时会添加此项，SRV记录了哪台计算机提供了哪个服务。

格式为：服务的名字.协议的类型（例如：_example-server._tcp）。

## TXT

用作验证。（如：做SPF（反垃圾邮件）记录）

## 显性URL转发和隐形URL转发

将一个http(s)地址指向目标地址，访问该地址将自动跳转到目标地址。

例如：a.example.com---显性/隐性URL转发--->example.com/a，访问a.example.com即是访问example.com/a。

二者区别：

- 显性：浏览器地址栏显示跳转的目标地址。

  接上示例：访问a.example.com，跳转后，浏览器地址栏显示为example.com/a。

- 隐性：浏览器地址栏显示跳转前的地址，不会显示跳转的目标地址。

  接上示例：访问a.example.com，跳转后，浏览器地址栏仍显示为a.example.com。



 进行DNS查询的一个非常有用的工具是nslookup，可以使用它来查询DNS中的各种数据。可以在Windows的命令行下直接运行nslookup进入一个交互模式，在这里能查询各种类型的DNS数据。
 DNS的名字解析数据可以有各种不同的类型，有设置这个zone的参数的SOA类型数据，有设置名字对应的IP地址的A类型数据，有设置邮件交换的MX类型数据。这些不同类型的数据均可以通过nslookup的交互模式来查询，在查询过程中可以使用  set type命令设置相应的查询类型。

dig