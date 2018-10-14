注意：本文基于centos7.x ，在其他发行版上配置可能有出入。

[TOC]

# 安装

服务端和客户端均安装`nfs-utils`、`rpcbind`和`portmap`

portmap为nfs提供rpc(Remote Procedure Call)支持。

# 服务端配置

## 配置共享目录

以下以 `/srv/share`目录（注意目录的权限）为例。编辑`/etc/exports`，添加共享目录相关配置，示例：

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
- `rw`可读写
- `async`文件暂存于内存（另`sync`文件存储在内存中并写入硬盘）
- `anonuid`和`anongid`  匿名的用户和用户组id值（设置1000确保权限的一致）
- `no_root_squash`  NFS客户端连接服务端时如果使用的是root的话，那么客户端对服务端分享的目录也拥有root权限。（！使用此项务必注意安全问题）
- `no_subtree_check` 不检查权限（！关闭subtree简查可以提高性能，但是安全性降低。）
- `exec`/`noexec`  可以/不可执行二进制文件
- `size`  缓冲区大小
- `bg`/`fg` 以后台/前台形式执行挂载
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