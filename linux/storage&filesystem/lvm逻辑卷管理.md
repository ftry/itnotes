# 概述

lvm, logic volume manager

> LVM利用Linux内核的[device-mapper](http://sources.redhat.com/dm/)来实现存储系统的虚拟化（系统分区独立于底层硬件）。它在[硬盘](https://zh.wikipedia.org/wiki/%E7%A1%AC%E7%A2%9F)的[硬盘分区](https://zh.wikipedia.org/wiki/%E7%A1%AC%E7%A2%9F%E5%88%86%E5%89%B2)之上，又创建一个逻辑层，以方便系统管理硬盘分区系统。

通过lvm可以实现存储空间的抽象化，建立虚拟分区（Virtual Partitions），轻松实现对虚拟分区的扩大和缩小操作。

特点：

> 比起正常的硬盘分区管理，LVM更富于弹性： 
>
> - 使用卷组(VG)，使众多硬盘空间看起来像一个大硬盘。
> - 使用逻辑卷（LV），可以创建跨越众多硬盘空间的分区。
> - 可以创建小的逻辑卷（LV），在空间不足时再动态调整它的大小。
> - 在调整逻辑卷（LV）大小时可以不用考虑逻辑卷在硬盘上的位置，不用担心没有可用的连续空间。
> - 可以在线（online）对逻辑卷（LV）和卷组（VG）进行创建、删除、调整大小等操作。LVM上的文件系统也需要重新调整大小，某些文件系统也支持这样的在线操作。
> - 无需重新启动服务，就可以将服务中用到的逻辑卷（LV）在线（online）/动态（live）迁移至别的硬盘上。
> - 允许创建快照，可以保存文件系统的备份，同时使服务的下线时间（downtime）降低到最小。

注意：当卷组中的一个硬盘损坏时，整个卷组都会受到影响，因此多硬盘组合使用时或可考虑使用raid等技术手段实现数据冗余存储。

## lvm组成

-  **物理卷Physical volume (PV)**：指硬盘分区，或硬盘本身，或者回环文件（loopback  file）。物理卷包括一个特殊的header，其余部分被切割为一块块物理区域（physical extents）。 
-  **卷组Volume group (VG)**：将一组物理卷收集为一个管理单元。
-  **逻辑卷Logical volume (LV)**：虚拟分区，由物理区域（physical extents）组成。
-  **物理区域Physical extent (PE)**：硬盘可供指派给逻辑卷的最小单位（通常为4MB）。

# lvm操作

建立lvm的流程：

1. 创建物理卷pv
2. 创建卷组vg：卷组含有一个和多个物理卷
3. 创建逻辑卷lv：在卷组中创建逻辑卷
4. 使用逻辑卷：像普通分区一样使用逻辑卷，只是逻辑卷挂载位置不同，可使用以下两种方式：
   - `/dev/mapper/卷组名-逻辑卷名`    如`/dev/mapper/cent-swap`
   - `/dev/卷组名/逻辑卷名`    如`/dev/cent/swap`

以下为常用lvm操作

```shell
lvmdiskscan  #扫描lvm情况
```

## 物理卷pv

- 查看

  ```shell
  pvscan  #扫描是否存在物理卷
  pvdisplay  #查看物理卷
  ```

- 创建

  ```shell
  #将一个或多个分区创建为物理卷
  pvcreate /dev/sda /dev/sdb  #创建物理卷
  ```

- 修改

  ```shell
  pvremove /dev/sda  #删除物理卷/dev/sda
  pvchange -x -u /dev/sda  #-x禁止分配PE -u生成uuid
  
  #扩增物理卷（可在线）：分区扩大后需要对物理卷扩增才能使用新增空间
  pvresize /dev/sda
  
  #缩小物理卷（可在线）：缩小分区前需要先缩小物理卷
  pvresize --setphysicalvolumesize 40G /dev/sda1
  ```

## 卷组vg

- 查看

  ```shell
  vgscan  #扫描是否存在卷组
  vgdisplay  #查看卷组
  ```

- 创建

  ```shell
  #将一个或多个物理卷加入新建的卷组 <vg-name>为卷组名
  vgcreate <vg-name> /dev/sda /dev/sdb  #将sda和sdb加到新卷组
  ```

- 修改

  ```shell
  vgextend <vg-name> /dev/sdc #扩充卷组 新加一个sdc物理卷
  vgrename <old-name> <new-name>  #卷组更名
  vgremove <vg-name> #删除卷组
  ```

## 逻辑卷lv

- 查看

  ```shell
  lvscan  #扫描是否存逻辑卷
  lvdisplay  #查看逻辑卷
  ```

- 创建

  ```shell
  #在卷组中创建逻辑卷 可使用-n添加该逻辑卷名字（可选）
  lvcreate -L <size> <vg-name> [-n <lv-name>]
  
  #-l参数可使用 百分比加关键字 的方式分配空间 
  lvcreate -l +100%FREE <vg-name> [-n <lv-name>]  #使用所有剩余空间（加号可省略）
  
  lvcreate -l 50%VG <vg-name> [-n <lv-name>]  #使用卷组50%的空间
  ```

- 修改

  ```shell
  #容量变更
  #警告: 并非所有文件系统都支持无损或/且在线（不卸载分区情况下）地调整大小。
  #lvextend扩大逻辑卷容量 用法同下方lvresize
  #lvreduce缩小逻辑卷容量 用法同下方lvresize
  
  #lvresize变更容量 -r(--resizefs）
  lvresize -r -L +2G <vg-name>/<lv-name>  #增加2G
  lvresize -r -L -2G <vg-name>/<lv-name>  #减少2G
  lvresize -r -L 10G <vg-naem>/<lv-name>  #新大小为10G
  lvresize -r -l +100%FREE <vg-naem>/<lv-name>  #增加所有剩余空间 (+加号可省略）
  
  #变更容量后可检查磁盘错误 需要卸载分区
  e2fsck -f /dev/<vg-name>/<lv-name>
  
  lvremove /dev/<vg-name>/<lv-name>  #删除逻辑卷
  ```

  注意：

  > 如果在执行`lv{resize,extend,reduce}`时没有使用`-r, --resizefs`选项， 或文件系统不支持`fsadm(8)`（如[Btrfs](https://wiki.archlinux.org/index.php/Btrfs), [ZFS](https://wiki.archlinux.org/index.php/ZFS)等），则需要在缩小逻辑卷之前或扩增逻辑卷后手动调整文件系统大小。

  ```shell
   resize2fs <vg-naem>/<lv-name>
  ```

  警告：xfs分区不能缩小只能扩大，可以使用xfsdump备份数据，然后进行分区缩小操作，最后使用xfsrestore还原备份的数据。