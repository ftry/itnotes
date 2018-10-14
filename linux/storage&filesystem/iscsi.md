> **iSCSI**（Internet Small Computer System Interface，发音为/ˈаɪskʌzi/），互联网小型计算机系统接口，又称为IP-[SAN](https://zh.wikipedia.org/wiki/SAN)，是一种基于[因特网](https://zh.wikipedia.org/wiki/%E5%9B%A0%E7%89%B9%E7%BD%91)及[SCSI-3](https://zh.wikipedia.org/wiki/SCSI-3)协议下的存储技术。

# 挂载iscsi存储设备

1. 安装iscsi软件包，启动`iscsi`服务。

2. 查找

   ```shell
   iscsiadm -m discovery -t sendtargets -p <ip>  #sendtargets可缩写为st
   #---
   iscsiadm -m discovery -p <ip> -o delete  #删除旧的目标
   iscsiadm -m node --op delete  #删除所有目标
   ```

3. 登录

   ```shell
   iscsiadm -m node -L all  #登入到有效的目标
   iscsiadm -m node --targetname=<targetname> --login  #登录到指定目标
   #---
   iscsiadm -m node -U all  #登出
   iscsiadm -m node -T <targetname> -p <ip> #登出指定目标
   ```

   查看登录目标的信息

   ```shell
   iscsiadm -m node
   ```

4. 挂载

   登录后可使用`lsblk`从块设备中发现存储设备，将其挂载即可。

# 多路径配置

由iSCSI组成的IP-SAN环境中或光纤组成的FC-SAN环境中，主机和存储通过了光纤交换机或者**多块网卡及多个IP来连接**，构成了**多对多**的关系，主机到存储可以有多条路径可以选择。

操作系统认为每条路径各自通一个物理盘，但实际上这些路径只通向同一个物理盘，这种情况下需要配置多路径。

> 多路径的主要功能就是和存储设备一起配合实现如下功能：
> 1.故障的切换和恢复
> 2.IO流量的负载均衡
> 3.磁盘的虚拟化    



1. 安装多路径软件包（包名搜索关键词device mapper multipath等），启动`multipath`服务。

2. 配置文件`/etc/multipath`

   提示：如无该文件，可执行`multipath -F`生成模板。

   ```shell
   blacklist {
       devnode "^sda"  #将非多路径的块设备排除
   }
   defaults {
       user_friendly_names yes
       path_grouping_policy multibus
       failback immediate
       no_path_retry fail
   }
   ```

3. 重启`multipath`服务，查看多路径情况。

   ```shell
   multipath -ll  #查看多路径服务情况
   lsblk
   ```

   此时可看到块设备列表中type为`mpath`的块设备，相同名字的块设备（如`mpatha`）即配置了多路径的统一存储设备，其位于`/dev/mapper/`下（例如`/dve/mapper/mptha`）。