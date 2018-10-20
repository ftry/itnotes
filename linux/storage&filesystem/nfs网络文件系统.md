> NFS 网络文件系统(Network File System) 是由Sun公司1984年发布的分布式文件系统协议。

如果客户端和服务端有较大时间差距，NFS 可能产生非预期的延迟。

# 安装

服务端和客户端均安装`nfs-utils`，如还需支持v4版以前的协议，还需要安装`rpcbind`。

服务端配置

启动`nfs`（或名`nfs-server`）服务，如还需支持v4版以前的协议，还需启用`rpcbind`服务。

## 配置共享目录

编辑`/etc/exports`，添加共享目录相关配置：

```shell
#共享目录 允许访问子网(各项)
#示例共享/share目录给192.168.0/24子网
/share 192.168.0.0/24(rw,async,insecure,no_root_squash)
```

`/share`  为共享目录，`192.168.0.0/24`  可访问的网段（可以是域名；支持通配符），括号中为各个选项，部分选项说明：

- 访问权限
  - `ro`只读 
  - `rw`可读写

- 安全策略

  - `insecure`  允许客户端使用1024以上的端口
  - `secure`  限制客户端只能使用小于1024的端口
  - `subtree_check`   NFS检查父目录的权限（默认） 
  - `no_subtree_check` 不检查父目录权限 （！关闭subtree简查可以提高性能，但是安全性降低。）
  - `exec`或`noexec`  可以或不可执行二进制文件

- 数据写入规则

  - `async`  文件暂存于内存（另`sync`文件存储在内存中并写入硬盘）
  - `wdelay` 如果多个用户要写入NFS共享目录，则归组写入（默认） 
  - `no_wdelay` 如果多个用户要写入NFS目录，则立即写入，**当使用async时，无需此设置**。 
  - `size`  缓冲区大小

- 用户映射

  - `root_squash`  NFS客户端连接服务端时如果使用的是root访问共享目录，将root用户映射成匿名用户（nobody）；
  - `all_squash` NFS客户端连接服务端上的任何用户访问该共享目录时都映射成匿名用户 
  - `no_root_squash`  NFS客户端连接服务端时如果使用的是root访共享目录，客户端对服务端分享的目录也拥有root权限。（！根据具体情况使用，务必**注意安全问题**）
  - `anonuid=` 将远程访问的所有用户都映射为匿名用户，并指定该用户为本地用户(id)；
  - `anongid=` 将远程访问的所有用户组都映射为匿名用户组账户，并指定该匿名用户组账户为本地用户组账户（gid）。

- `no_hide` 共享NFS目录的子目录（默认）

- `bg`/`fg` 以后台/前台形式执行挂载

- `fsid=数字`或`fsid=root`或`fsid=uuid`  导出的文件系统（即共享目录的文件系统）的识别号。

  通常fsid是文件系统的UUID（默认值）；不存储在该设备上的文件系统和没有UUID的文件系统需要显示地指定fsid（该值需唯一）。

  如果使用NFSv4，其能够指定所有导出的文件系统的root，通过`fsid=root`或`fsid=0`来标识。系统不能指定时须手动添加该配置项。

  注意：`fsid=0`选项的时候只能共享一个目录，这个目录将成为NFS服务器的根目录。



查看已经配置的共享目录：

```shell
exportfs
```

如果修改了 `/etc/exports` 文件，可使用以下命令重新载入配置：

```shell
exportfs -ra
```

卸载所有共享目录并重新挂载：

```shell
exportfs -au
```

exportfs参数：

- a 全部挂载或卸载目录
- r  重新读取配置文件
- u 卸载单一目录
- v  输出详细信息



查看nfs状态：`nfsstat`

查看rpc执行信息：`rpcinfo`

# 客户端配置

- 扫描服务器共享目录

  ```shell
  #showmount -e <地址>
  showmount -e 192.168.0.251
  ```

- 查看已连接目录

  ```shell
  showmount -a
  ```

- 挂载

  - 使用mount 挂载示例

    ```shell
    mount -t nfs 192.168.0.251:/share /share
    ```

  - 使用fstab挂载

    写入`/etc/fstab`， 示例：

    ```shell
    192.168.0.251:/share /share nfs default,_netdev	0 0
    ```

# 常见错误

## clnt_create: RPC: Port mapper failure - Unable to receive: errno 113 (No route to host)服务端防火墙

服务端防火墙（firewall、iptables等）未添加规则，关闭防火墙或者添加相应的规则。