[TOC]

# 常用参数

- p：指定要连接的远程主机的端口
- f：成功连接ssh后将指令放入后台执行
- C：请求压缩所有数据
- N：不登陆到远程主机
- D：动态端口转发
- R：远程端口转发
- L：本地端口转发
- g：允许连接到主机转发的端口。相当于临时设置`sshd_config`文件中的`GatewayPorts yes`
- T：不分配TTY
- q：安静模式（不输出错误/警告）
- -v：显示详细信息（可用于排错）

# 远程登录

```bash
ssh [-p port] <user>e@<host>     #<user>是用户名, <host>是该ssh服务器的主机地址
ssh -p 2333 <user>@<host>     #-p指定端口（更改了默认端口22时需要使用）
```
- port：要登录的远程主机的端口

  在更改了远程主机ssh服务的默认ssh端口时使用，默认为22。下文不再特别说明该参数。

- user：要登录的主机上的用户名

- host：要登录的主机地址

注意：如果省略用户名（和`@`），将会以当前用户名尝试登录ssh服务器，例如root用户执行`ssh <host>`同于`ssh root@<host>`。

## 使用密钥免密码登录

### 生成和上传密钥

1. 生成密钥——生成非对称加密的密钥对

   ```shell
   ssh-keygen   #根据提示选择或填写相关信息
   ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" #相等于执行ssh-keygen后一直回车(均默认)
   ```
   - t：加密类型，有dsa、ecdsa 、ed25519、rsa等，默认rsa
   - b：密钥长度，默认2048
   - f：密钥放置位置
   - N：为密钥设置密码

2. 上传密钥——将密钥对中的公钥上传到ssh服务器

   ```shell
   ssh-copy-id <user>@<host>
   ssh-copy-id -i ~/.ssh/test.pub <user>@<host>  #有多个公钥时可使用参数-i指定一个公钥
   ```

   提示：上传时需要输入密码。

   如要手动添加公钥：可将客户端生成的**`id_rsa.pub`**内容添加到服务端的`~/.ssh/authorized_keys`中。

### ssh登录失败原因

提示：可以在登录命令中加入`-v`参数，从输入内容中获取信息。

- 权限问题（客户端或服务端）

  **~/.ssh/authorized_keys文件的权限为600**，**~/.ssh文件夹权限为700**

  ```shell
  chmod 600 ~/.ssh* && chmod 700 ~/.ssh
  ```

- 客户端存在多个密钥对

  ssh默认使用的私钥可能和服务器上保存的客户端公钥并不是一对，可在登录时使用`-i`指定**私钥** ：

  ```shell
  ssh -i /path/to/private-key/ [-p port] <user>@<host>
  ```

- 严格的主机密钥检查不通过——服务器的公钥发生了变更

  ssh客户端首次登录ssh服务器时，客户端会记录服务器的公钥信息到`~/.ssh/known_hosts`（已知主机列表）文件中。
  而后每次客户端登录该服务器时，会先将`.ssh/know_hosts`中的公钥与服务器的公钥进行对比，二者一致才会通过校验。

  当ssh服务器公钥发生变化后，客户端的know_hosts中信息若未随之更新，就会校验不通过。

  解决方案：

  - 删除客户端`.ssh/known_hosts`文件中检查不通过的ssh服务器的公钥信息

  - 关闭客户端的严格主机密钥检查(strict host key check)

    在`.ssh/config`（或`/etc/ssh/ssh_config`）中添加

    ```shell
    StrictHostKeyChecking no
    ```

  如果无需严格的主机密钥检查，也可以将已知主机信息文件指向`/dev/null`。

## 保持ssh连接

在服务端或客户端设置keep-alive以保持连接。

- 服务端`sshd_config`中添加

  ```shell
  ClientAliveInterval 30
  ClientAliveCountMax 60
  ```
  每30s向连接的客户端传送信息；客户端连续60次无响应则自动关闭该连接。

- 客户端`ssh_config`中添加

  ```shell
  ServerAliveInterval 30
  ServerAliveCountMax 60
  ```

  每30s向连接的服务端端传送信息；服务端连续60次无响应则自动关闭该连接。

# 远程操作

直接在登录命令后添加命令可使该命令在远程主机上执行，示例如下：

```shell
ssh [-p port] <user>@<host> <command>
ssh root@192.168.1.11 whoami
ssh root@192.168.1.11 'mkdir -p .ssh && cat >> .ssh/authorized_keys' < ~/.ssh/id_rsa.pub
```

如果是交互式操作，例如使用vim操作远程主机的文件，配合scp使用，示例：

```shell
vim scp://<user>@<host>[:port]//path/to/file
```

# 端口转发（ssh隧道）

> 隧道是一种把一种网络协议封装进另外一种网络协议进行传输的技术。

ssh隧道又被称作ssh端口转发，因为ssh隧道**通常会绑定一个本地端口**，通过该端口的数据包都会被加密并透明地传输到远端系统。

- 使用1024以下的端口需要root权限。

- 开启/关闭端口转发，在`sshd_config`文件根据需要设置`yes`或`no`：

  ```shell
  GatewayPorts yes
  ```


- 端口转发一般都配合`f`和`N`参数将命令放到后台并且不执行登录操作，参看[常用参数](#常用参数)。

- 在sshd的配置文件`sshd_config`中设置了`GatewayPorts yes`（或者ssh转发时添加[-g参数](#常用参数)），就可以允许其他ssh客户端连接主机时，能够直接连接到转发的端口。（否则默认只能本地主机连接到转发的端口）

- 远程主机只是一个通常的相对概念。例如转发主机某端口到该主机另一端口也是可以的：

  ```shell
  ssh -L localhost:2333:localhost:22 localhost  #将本地2333端口转发到本地22端口
  ```

- 动态转发时正向代理，本地转发和远程转发是反向代理。

- 本地转发和远程转发区别

  - 本地转发：转发本地端口到远程主机端口。访问本地端口即相当于访问远程主机端口。
  - 远程转发：转发远程主机端口到本机端口。访问远程主机端口即相当于访问本地端口。

  > SSH 端口转发自然需要 SSH 连接，而 SSH 连接是有方向的，从 SSH Client 到 SSH Server 。

  转发时ssh连接方向：执行转发操作的主机--->远程主机


  > 如果这两个连接的**方向一致，那我们就说它是本地转发**。而如果两个方**向不一致，我们就说它是远程转发**。

  访问时ssh连接方向

  - 本地转发：访问端--->执行转发操作的主机--->远程主机
  - 远程转发：访问端--->远程主机--->执行转发操作的主机

## 动态端口转发（socks代理）

转发本地端口到目标主机。本地的应用程序需要使用Socks协议与本地端口通讯。

即用于代理访问，同时加密数据又提升了访问安全性。

```shell
ssh -D <local-port>  <user>@<ssh-server> [-p host-port]
ssh -fDN 1080 root@192.168.1.2  #将通过1080端口的数据转发到192.168.1.2上
```

- local-port：本地端口
- user：要转发到的主机上的登录用户名
- ssh-server：要转发到的主机地址

需要手动为要使用代理的程序配置socks5代理，如果该程序无配置socks代理的选项，可尝试借助工具如proxychains或redsocks等。

## 本地端口转发

将本地机(客户机)的某个端口转发到远端指定机器的指定端口。访问本地端口即相当于访问远程主机端口。

```shell
ssh -L [bind_address:]<local-port>:<host>:<host-port> <user>@<ssh-server>
ssh -fDNL 5901:192.168.2.10:5900 root@192.168.2.10  #将本地5901端口数据转发到192.168.2.10:5900端口
```

- bind-address：绑定的地址，如果不指定该地址，默认绑定在本地的回环地址（127.0.0.1）。

其余参数解释参看动态转口转发。

## 远程端口转发

将远程主机(服务器)的某个端口转发到本地端指定机器的指定端口。访问远程主机端口即相当于访问本地端口。

用于某些单向阻隔的内网环境，例如从外访问NAT，网络防火墙内网主机，在目标内网主机向外网主机建立一个远程转发端口，使得外网主机可以通过该端口访问该内网主机的服务。

```shell
ssh -R [bind_address:]port:<host>:<host-port> <user>@<ssh-server>
ssh -fgDNR 5900:192.168.2.10:5901 root@192.168.2.10
```

参数解释参看动态转口转发。

# scp远程复制

scp是基于ssh的远程复制，使用**类似cp命令**。基本形式：

```shell
scp </path/to/local-file> <user>@<host>:</path/to/file>  #本地到远程
scp <user>@<host>:</path/to/file> </path/to/local-file>  #远程到本地
```

常用选项：

- -P  指定远程主机的端口号
- -C  使用压缩
- -r  递归方式复制（即复制文件夹下所有内容）
- -p  保留文件的权限、修改时间、最后访问时间
- -q  静默模式（不显示复制进度）
- -F  指定配置文件

示例——复制本地ssh公钥到远程主机：

```shell
#复制本地公钥到远程主机 并将其命名为authorized_keys
scp ~/.ssh/id_rsa.pub root@ip:/root/.ssh/authorized_keys
#指定端口需要紧跟在scp之后
scp -P 999 ~/.ssh/id_rsa.pub root@ip:/root.ssh/authorized_keys
```

# sftp传输协议

使用sftp协议可以同ssh服务器进行文件传输，访问地址类似：

> sftp://192.168.1.100:22/home/<user>/path/to/file

# 服务器安全策略

- 工具
  - [denyhosts](https://github.com/denyhosts/denyhosts)
  - [fail2ban](https://github.com/fail2ban/fail2ban)

- 在`/var/log/secure`可查看到失败的ssh登录记录
- 禁止指定ip登录ssh
  - 在`/etc/hosts.deny`中添加ip，格式`sshd:ip地址`。
  - 使用[denyhosts](https://zh.wikipedia.org/wiki/DenyHosts)工具，安装后启用`denyhosts`服务即可。


- 更改默认的22端口
  修改服务器的`/etc/ssh/sshd_config`文件中的`Port` 值为其他可用端口。
- 使用非对称加密密钥

  ```shell
  ssh-keygen  #或者ssh-keygen -t rsa 4096  客户机生成密钥
  ssh-copy-d -p 23579 ip@8.8.8.8  #上传公钥到服务器（23579是端口号，8.8.8.8是ip地址）
  ```


- 用户控制

  - 禁用root登录
    修改服务器的`/etc/ssh/sshd_config`文件中的`PermitRootLogin` 值改为no
    - 禁止root用户使用密码登陆
      仅禁止使用密码登陆root账户（可使用密钥登陆）， 将服务器的`/etc/ssh/sshd_config`文件中的`PermitRootLogin` 值改为`prohibit-password`

  - 禁止登录shell

    - 在`/etc/passwd`文件中找到该用户所在行，将`/bin/bash`字样改为`/sbin/nologin`。

    - 在ssh配置文件中添加`DenyUsers username`（username即用户名，下同）。

    - 在`/etc/pam.d/sshd`文件中添加：

      > auth  required  pam_listfile.so  item=user  sense=allow  file=/etc/ssh/deny onerr=succeed

      在`/etc/ssh/deny`中加上要禁止的用户名

  - 只允许某些用户登录

    在ssh配置文件中内容：

    - 允许单用户：`AllowUsers username`
    - 允许用户组：`AllowGroups groupname`（groupname是组名）

# 问题解决

- > no matching key exchange method found. Their offer: diffie-hellman-group-exchange-sha1,diffie-hellman-group1-sha1

  ssh server 不支持diffie-hellman-group1-sha1造成的，服务器ssh版本过低（或者说客户端ssh版本过高）

  升级服务端ssh或者在客户端ssh的config中添加

  ```shell
  KexAlgorithms +diffie-hellman-group1-sha1
  ```

- > no compatible cipher.The server supports these cipher:  aes128-ctr,aes192-ctr,aes256-ctr

  ssh服务端不支持某些协议

  升级服务端ssh或者在客户端ssh的config中添加

  ```shell
  Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc
  ```
