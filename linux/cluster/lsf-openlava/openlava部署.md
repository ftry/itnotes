# 编译按装

编译所需依赖

- gcc
- ncurses-devel
- tcl-devel

以编译安装安装到`/opt/openlava`为例，下同。

```shell
dest=/otp/openlava
./configure --prefix=$dest
make -j4 #j指定编译时使用的线程数
make install  #自动安装

#生成配置文件
./config.status
cp config/* $dest/etc
cd $dest/etc
rm Makefile* *.in -f
```

# 配置文件

- 执行用户和环境变量

  ```shell
  dest=/otp/openlava
  
  #创建运行openlava的用户
  useradd -M -s /sbin/nologin openlava
  chown -R openlava:openlava $dest
  
  #环境变量
  chmod +x openlava* *.sh
  ln -sf $dest/etc/openlava $dest/bin/
  ./openlava.setup  #可选
  source ./openlava.sh
  ./openlava.setup
  ```

  `openlava.setup`是将相关环境变量文件放入`/etc/profile.d/`下，将openlava放到`/etc/init.d/`下，根据具体情况选择性使用该脚本。

- 主配置文件

  修改文件`lsf.cluster.openlava`（openlava字样可改为集群名字），部分内容如下：

  ```shell
  Begin   ClusterAdmins
  Administrators = openlava #运行openlava服务的用户
  End    ClusterAdmins
  
  Begin   Host  #主机列表
  HOSTNAME    model    type  server  r1m  RESOURCES
  #yourhost IntelI5    linux   1      3.5    (cs)
  #node1       !       linux   1      3.5    (cs)
  master       !      linux    1      3.5    (cs) 
  c01          !      linux    1      3.5    (cs)
  End     Host
  ```

  主机列表中，第一行被认为是管理节点，其后一一添加其他节点，也可以使用`default`代表所有节点。

- 检查配置

  ```shell
  badmin ckconfig
  lsamdin ckconfig
  ```

# 测试服务

```shell
oepenlava start
openlava status  #仅主节点有mbatchd服务
lsid
lshosts
bhosts
```