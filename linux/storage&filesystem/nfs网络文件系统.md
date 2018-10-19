注意：本文基于centos7.x ，在其他发行版上配置可能有出入。

[TOC]

# 安装

服务端和客户端均安装`nfs-utils`、`rpcbind`和`portmap`。

portmap为nfs提供rpc(Remote Procedure Call)支持。

# 服务端配置

## 配置共享目录

以下以 `/srv/share`目录（注意目录的权限）为例。

编辑`/etc/exports`，添加共享目录相关配置，示例：

>/srv/share 192.168.0.0/24(rw,async,insecure,anonuid=1000,anongid=1000)

注意：如果服务运行时修改了 `/etc/exports` 文件， 你需要重新导出使其生效：

```shell
exportfs -ra
```

查看已经配置的共享目录：

```shell
exportfs
```

部分配置说明：

- `/srv/share`  共享目录

- `192.168.0.0/24`  可访问的网段（可以是域名；支持通配符）

- `ro`只读  `rw`可读写

- `insecure`  NFS使用1024以上的端口

- `async`文件暂存于内存（另`sync`文件存储在内存中并写入硬盘）

- `anonuid`和`anongid`  匿名的用户和用户组id值（设置1000确保权限的一致）

- 用户映射

  - `root_squash`  NFS客户端连接服务端时如果使用的是root访问共享目录，将root用户映射成匿名用户（nobody）；
  - `all_squash` NFS客户端连接服务端上的任何用户访问该共享目录时都映射成匿名用户 

  - `no_root_squash`  NFS客户端连接服务端时如果使用的是root访共享目录，客户端对服务端分享的目录也拥有root权限。（！使用此项务必**注意安全问题**）

- 权限检查

  - `subtree_check`   NFS检查父目录的权限（默认） 
  - `no_subtree_check` 不检查父目录权限 （！关闭subtree简查可以提高性能，但是安全性降低。）

- `exec`或`noexec`  可以或不可执行二进制文件

- 写入延迟

  - `wdelay`   如果多个用户要写入NFS共享目录，则归组写入（默认） 
  - `no_wdelay` 如果多个用户要写入NFS目录，则立即写入，**当使用async时，无需此设置**。 

- `no_hide` 共享NFS目录的子目录（默认）

- `size`  缓冲区大小

- `bg`/`fg` 以后台/前台形式执行挂载

- `fsid=数字`或`fsid=root`或`fsid=uuid`  导出的文件系统（即共享目录的文件系统）的识别号。

  通常fsid是文件系统的UUID（默认值）；不存储在该设备上的文件系统和没有UUID的文件系统需要显示地指定fsid（该值需唯一）。

  如果使用NFSv4，其能够指定所有导出的文件系统的root，通过`fsid=root`或`fsid=0`来标识。（老版本linux下安装的nfs可能使用v4之前的版本，需要手动指定fsid）

  注意：fsid=0选项的时候只能共享一个目录，这个目录将成为NFS服务器的根目录。

- ……（更多配置项查看nfs文档，如使用`man nfs` ）……

## 启动nfs相关服务

启动服务：`rpcbind`  `nfs` `nfslock`（可选，锁定文件）`nfs-idmap` （可选）

## 防火墙配置

如不需要使用防火墙，关闭`firewalld` 。

如果使用防火墙，需打开NFS服务端口：

```shell
firewall-cmd --zone=public --add-service=nfs --permanent
firewall-cmd --zone=public --add-service=rpc-bind --permanent
firewall-cmd --zone=public --add-service=mountd --permanent
firewall-cmd --reload
```

# 客户端配置

## 启用相关服务

启用`rpcbind`

```shell
systemctl start rpcbind && systemctl enable rpcbind
```

## 挂载共享目录

- 扫描服务器nfs共享目录

  ```shell
  showmount -e <地址>
  ```

- 使用mount 挂载示例

  ```shell
  mount -t nfs 192.168.122.4:/srv/share /srv/share
  ```

- 使用fstab挂载

  写入`/etc/fstab`， 示例：

  ```shell
  192.168.0.101:/srv/share   /srv/share  nfs  default,_netdev	0 0
  ```

## 常见错误

### clnt_create: RPC: Port mapper failure - Unable to receive: errno 113 (No route to host)服务端防火墙

服务端防火墙（firewall、iptables等）未添加规则，关闭防火墙或者添加相应的规则。