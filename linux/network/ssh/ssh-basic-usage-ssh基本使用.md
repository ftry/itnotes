[TOC]

# 常用参数

- `p`：指定要连接的远程主机的端口
- `f`：成功连接ssh后将指令放入后台执行
- `C`：请求压缩所有数据
- `N`：不执行远程命令（不登录到服务器执行命令）
- `D`：动态端口转发
- `R`：远程端口转发
- `L`：本地端口转发
- `g`：（配合端口转发）允许远程主机连接到建立的转发的端口（不使用该参数则只允许本地主机建立连接）
- `-t`：强制分配伪终端（可以用来执行任意的远程计算机上基于屏幕的程序）
- `T`：不分配TTY
- `A`：开启身份认证代理转发
- `q`：安静模式（不输出错误/警告）
- `-v`：显示详细信息（可用于排错）

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

## 密钥登录

使用非对称加密的密钥，可免密码登录。

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

## 别名登录

为需要经常登录的服务器设置别名，简化登录步骤。

在`~/.ssh/config`（如无该文件则创建之）中配置：

```shell
Host server1 #server1为所命名的别名
  hostname xxx.xxx.xxx.xxx #登录地址
  user user1  #用户名
  #port 1998  #如果修改过默认端口则指定之
  #IdentityFile  ~/path/to/id_rsa.pub #如果要指定公钥
  #IdentitiesOnly yes #只使用指定的公钥进行认证
```

登录时直接使用`ssh server1`即可。

## 跳板登录

在某些情况下，需要先登录跳板机（可能不止一个跳板机），再从跳板机登录到目标服务器：

**客户端** ---> **跳板机** ---> **目标主机**

可使用以下方法简化登录步骤。

---

以下示例中，**客户端Client**欲通过**跳板机Jump-server**用户，登录到**目标主机target-server**：

sshd端口均为22，各主机使用的用户名相同（用户名一致时可不指明登录服务器的用户名，参看上文[远程登录](#远程登录)所述）。

---

- 分配伪终端跳转登录`-t`

  ```shell
  ssh -t <jump-server> \
  ssh -t <target-server>
  ```

  如果以上各步骤的ssh登录都实现了ssh密钥验证，将直接登录到目标主机。如果某一步登录无密钥验证，将会提示输入密码。

  密钥转发`-A`：该参数可将客户端密钥通过跳板机转发到目标服务器上

  ```shell
  ssh -A -t <jump-server> \
  ssh -A -t <target-server>
  ```

  多个跳板机时，按顺序一一写上即可。

- 跳跃登录`-J`——更为简洁的用法：

  ```shell
  ssh -J <jump-server> <target-server>
  ```

  如有多个跳板机使用`,`逗号隔开。

  ```shell
  ssh -J <jump-server1>,<jump-server2> <target-server>
  ```

- 代理命令`proxyCommand`

  ```shell
  ssh <target-server> -o ProxyCommand='ssh <jump-server> -W %h:%p'
  ```

  为了简化操作可使用[别名登录](#别名登录)：

  ```shell
  Host jump #跳板机配置
    HostName <jump-server>
    
  Host target #目标主机配置
    HostName <target-server>
    ForwardAgent yes
    ProxyCommand ssh jump -q -W %h:%p
  ```

  直接`ssh target`即可登录。

## 保持连接

在服务端或客户端设置keep-alive以保持连接。

- 服务端`/etc/ssh/sshd_config`中添加

  ```shell
  ClientAliveInterval 30
  ClientAliveCountMax 60
  ```

  每30s向连接的客户端传送信息；客户端连续60次无响应则自动关闭该连接。

- 客户端`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加

  ```shell
  ServerAliveInterval 30
  ServerAliveCountMax 60
  ```

  每30s向连接的服务端端传送信息；服务端连续60次无响应则自动关闭该连接。

## 连接复用

在已经连接到某个服务器的情况下，再连接该服务器时将直接从先前的连接缓存中读取信息，加快连接速度。

在`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加：

```shell
ControlMaster auto
ControlPath ~/.ssh/sockets/socket-%r@%h:%p #连接信息存储路径
ControlPersist yes  #连接保持
ControlPersist 1h  #连接保持时间
```

## 远程操作

直接在登录命令后添加命令，可使该命令在远程主机上执行，示例：

```shell
ssh [-p port] <user>@<host> <command>
ssh root@192.168.1.11 whoami

#将本地.vimrc内容传入远程主机的.vimrc中
ssh root@192.168.1.11 'cat > .vimrc' < .vimrc

#多条命令使用引号包裹起来
ssh 10.10.1.1 'echo `whoami` > name && mv -f name myname'
```

如果是交互式操作，例如使用vim操作远程主机的文件，配合scp使用，示例：

```shell
vim scp://<user>@<host>[:port]//path/to/file
```

## 登录失败原因

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

# 端口转发（ssh隧道）

> 隧道是一种把一种网络协议封装进另外一种网络协议进行传输的技术。

以下关于不同转发的论述中的三种角色：

客户端：原始请求的发起者

目标主机：真正的服务提供者

代理：客户端与服务端（目标）的中介

---

- 使用1024以下的端口需要root权限。

- 端口转发命令配合`-g`参数，可允许远程主机连接到建立的转发的端口，如果不使用该参数，只允许本地主机建立连接。也可在代理主机的配置文件`/etc/ssh/sshd_config`中设置：`GatewayPorts yes`，以允许远程主机建立连接。

- 动态转发与本地/远程转发

  **动态转发是正向代理，本地/远程转发是反向代理。**

  **”正向“代理客户端，”反向“代理服务端。**

  （这里的”正向“是正向代理的简称，代理作动词，”反向“亦同）

  正向代理代表客户端向服务器发送请求，使真实客户端对服务器不可见。反向代理代表服务器为客户端提供服务，使真实服务器对客户端不可见。

- 本地转发和远程转发

  在本地转发和远程转发的应用中，客户端都是直接访问代理主机的端口，代理主机通过端口转发，将数据传送到真实目标主机相应的端口上。

  二者不同在于：

  - 执行转发命令的主机
    - 本地转发中，执行转发命令的是**代理主机**（即所谓“本地”主机）。
    - 远程转发中，执行转发命令的是**目标主机**（代理主机即所谓“远程”主机）

    此外，动态端口转发中，执行转发命令的是**客户端**。

  - 客户端的访问方向

    - 本地转发：**客户端** ---> **执行转发操作的主机（代理）**---> **目标**
    - 远程转发：**客户端** ---> **远程主机（代理）** ---> **执行转发操作的主机（目标）**

## 动态端口转发（socks代理）

在客户端执行转发命令

转发客户端的端口到代理主机的端口，客户端访问目标主机时，实际是经过代理主机访问目标主机。

*需要手动为要使用代理的程序配置socks5代理（或设置全局的代理，可配合PAC使用）*

可用于代理/加密访问。

```shell
#使用-D参数进行动态端口转发
ssh -D <local-port>  <user>@<ssh-server> [-p host-port]
#应使用示例
ssh -fDN 1080 root@192.168.1.2
```

- local-port：本地端口
- user：要转发到的主机上的登录用户名
- ssh-server：要转发到的主机地址

## 本地端口转发

**在代理主机执行转发命令**

映射目标主机端口到本地主机（代理主机）端口，来自客户端的数据从本地主机（代理主机）端口转发到目的主机端口，访问本地主机（代理主机）的端口即相当于访问目标主机的端口。

```shell
ssh -L [bind_address:]<local-port>:<host>:<host-port> <user>@<ssh-server>
ssh -fCNL 5901:192.168.2.10:5900 root@192.168.2.10 #将本地5901端口数据转发到192.168.2.10:5900端口
```

- bind-address：绑定的地址，如果不指定该地址，默认绑定在本地的回环地址（127.0.0.1）。

其余参数解释参看动态转口转发。

## 远程端口转发

**在目标主机执行转发命令**

映射远程主机（代理主机）的端口到目标主机端口，来自客户端的数据从远程主机（代理主机）端口转发到目的主机端口，访问远程主机（代理主机）的端口即访问目标主机的端口。

与本地转发不同，**目标主机主动向代理主机（远程主机）建立一个反向 SSH 隧道**，客户端通过代理上的反向隧道连接到目标主机。

```shell
ssh -R [bind_address:]port:<host>:<host-port> <user>@<ssh-server>
ssh -fCNR 5900:192.168.2.10:5901 root@192.168.2.10
```

参数解释参看动态转口转发。

# 文件传输

## scp远程复制

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

## sftp传输协议

使用sftp协议可以同ssh服务器进行文件传输，访问地址类似：

> sftp://192.168.1.100:22/home/<user>/path/to/file

## sshfs文件系统

> SSHFS 是一个通过 SSH 挂载基于 FUSE 的文件系统的客户端程序。 

需要安装有`sshfs`。

挂载示例：

```shell
#sshfs [user@]host:[dir] <mountpoint> [options]
sshfs ueser1@host1:/share /share -C -p 2333 -o allow_other
```

常用选项有：

- `-C` 启用压缩

- `-p` 指定端口

- `-o allow_other` 允许非root用户读写


`/etc/fastab`自动挂载示例：

```shell
user@host:/remote/folder /mount/point  fuse.sshfs noauto,x-systemd.automount,_netdev,users,idmap=user,IdentityFile=/home/user/.ssh/id_rsa,allow_other,reconnect 0 0
```



卸载示例：

```shell
#fusermount -u <mount-point>
fusermount -u /share
```

# 服务器安全策略

## 工具

- [denyhosts](https://github.com/denyhosts/denyhosts)
- [fail2ban](https://github.com/fail2ban/fail2ban)
- [sshguard](https://www.sshguard.net/)

## 白名单和黑名单

- 黑名单

  在`/etc/hosts.deny`中添加禁止列表。

- 白名单

  在`/etc/hosts.allow`中添加允许列表。


- 更改默认的22端口
  修改服务器的`/etc/ssh/sshd_config`文件中的`Port` 值为其他可用端口。

- 登录记录查看

  - 成功记录：`lastlog`

    其保存在`/var/log/secure`（或在`/etc/log/btmp`）。

  - 失败记录：`lastb`

    其保存在`/etc/log/btmp`。


- 使用非对称加密密钥

  ```shell
  ssh-keygen  #或者ssh-keygen -t rsa 4096 客户机生成密钥
  ssh-copy-d -p 23579 ip@8.8.8.8  #上传公钥到服务
  ```

  注意，dsa密钥已经证实为不安装，rsa密钥位数过低也较为不安全，推荐至少4096位。


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

  ssh server 不支持diffie-hellman-group1-sha1造成的，服务器ssh版本过低（或者说客户端ssh版本过高）。

  升级服务端ssh版本，或在`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加

  ```shell
  KexAlgorithms +diffie-hellman-group1-sha1
  ```

- > no compatible cipher.The server supports these cipher:  aes128-ctr,aes192-ctr,aes256-ctr

  ssh服务端不支持某些协议（或者说客户端ssh版本过高）。

  升级服务端ssh版本，或在`/etc/ssh/ssh_config`或用户家目录的`~/.ssh/config`中添加

  ```shell
  Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc
  ```
