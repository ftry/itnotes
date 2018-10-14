HPC LINPACK benchmark

---

# 介绍

LINPACK （Linear system package）即线性系统软件包，该工具

> 通过在高性能计算机上用**高斯消元法**求解 N 元一次稠密线性代数方程组的测试，评价高性能计算机的**浮点**性能。

HPL（High Performance Linpack）是针对现代**并行计算集群**的测试工具。

>  用户不修改测试程序,通过调节问题规模大小 N（矩阵大小）、进程数等测试参数,使用各种优化方法来执行该测试程序,以获取最佳的性能。

## 浮点计算能力

$浮点计算能力=计算量(2/3 * N^3-2*N^2)/计算时间T$

N为问题规模。当求解问题规模为 N 时，浮点运算次数为(2/3 * N^3-2*N^2)。
测试结果以浮点运算每秒（Flops）表示。

浮点计算峰值衡量计算机性能的一个重要指标，它是指计算机每秒钟能完成的浮点计算操作数：

- 理论浮点峰值（Rpeak）

  理论上能达到的每秒钟能完成的最大浮点计算次数

  决定因素：CPU 本身规格和 CPU 的数量决定
  >Rpeak=CPU 主频(标准频率)× CPU 每个时钟周期执行浮点运算的次数×系
  >统中 CPU 的总核数

- 实测浮点峰值（Rmax）

  Linpack测得的实际值

通常情况下，理论浮点峰值是基于 CPU 的标准频率计算的。如果 CPU超频后使得实际运行的频率高于标准频率，实测浮点峰值(Rmax)可能高于理论浮点峰值(Rpeak)。

###　集群计算能力

$单节点理论计算能力 = 单节点中 CPU 数量 * 单颗 CPU 核数 * CPU 的标称
主频 * 每周期执行的指令数$

$集群理论计算能力 = 集群节点数 * 单节点的理论计算能力$

# 测试准备

## BIOS 配置调优

将 BIOS 配置为性能最优模式，常用配置项如 ：

- 电源策略（Power Policy）或CPU frequency：高性能之类的模式
- 睿频（Turbo Boost或Turbo Core）：启用
- 超线程（Hyper-Threading）：关闭

## 集群配置

- 网卡驱动、IP等配置完成
- 各个节点ssh互信
- 集群共享目录（以下叙述中以/share为共享目录）

## HPL相关工具

编译工具、并行工具及数学库等安装到集群共享目录，常用组合选择：

- HPL + [Intel® Parallel Studio XE](https://software.intel.com/en-us/intel-parallel-studio-xe)

- HPL + [ATLAS](http://math-atlas.sourceforge.net/) + [MPICH2](https://www.mpich.org/)
- HPL + [GotoBLAS2](https://www.tacc.utexas.edu/research-development/tacc-software/gotoblas2) + [Open MPI](https://www.open-mpi.org/)

以下仅描述安装hpl工具本身。

### 安装HPL

1. 下载[hpl](http://www.netlib.org/benchmark/hpl/)，解压后将setup目录中复制相应的文件到解压后的根目录下

   ```shell
   cp setup/Make.Linux_Intel64 ./    #本文当以intel64位为例
   ```

2. 根据此次测试使用的[HPL相关工具](#HPL相关工具)的安装情况，对hpl的Make编译文件进行修改，主要修改的变量有:

   - ARCH:  必须与文件名 `Make.<arch>`中的`<arch>`一致
   - TOPdir: 指明 hpl 程序所在的目录
   - MPdir:  MPI 所在的目录
   - MPlib:  MPI 库文件
   - LAdir:  BLAS 库或 VSIPL 库所在的目录
   - LAinc、LAlib: BLAS 库或 VSIPL 库头文件、库文件
   - HPL_OPTS: 包含采用什么库、是否打印详细的时间、是否在  L 广播之前拷贝 L若采用 FLBAS 库则置为空,采用 CBLAS 库为“-DHPL_CALL_CBLAS”,采用 VSIPL  为“DHPL_CALL_VSIPL”;“-DHPL_DETAILED_TIMING”为打印每一步所需的时间,缺省不打印“-DHPL_COPY_L”为在  L 广播之前拷贝 L,缺省不拷贝(这一选项对性能影响不是很大)
   - CC:  C 语言编译器
   - CCFLAGS: C 编译选项
   - LINKER: Fortran 77 编译器
   - LINKFLAGS: Fortran 77 编译选项(Fortran 77 语言只有在采用 Fortran 库时才需要)

   修改内容主要是：CPU架构ARCH、通信传输接口MPI库的路径、数学核心库MKL的路径和编译器Compiler的路径。



   搭配intel工具使用的hpl的make文件的部分内容示例：

   ```shell
   ARCH = intel64
   
   MPdir = /opt/intel/impi/5.1.1.109
   MPinc = -I$(MPdir)/include64
   MPlib = $(MPdir)/intel64/lib/libmpi_mt.so
   
   LAdir = /opt/intel/compilers_and_libraries_2016/linux/mkl/lib/intel64
   LAinc = -I/opt/intel/compilers_and_libraries_2016/linux/mkl/include
   LAlib = -mkl=cluster
   
   CC           = mpiicc
   CCNOOPT      = $(HPL_DEFS)
   CCFLAGS      = -openmp -xHost -fomit-frame-pointer -O3 -funroll-loops $(HPL_DEFS)
   LINKER       = mpiicc
   ```

3. 编译安装

   ```shell
   make arch=Linux_Intel64
   ```

   编译结果位于bin目录下

# 测试

各种测试方法：

- 运行脚本测试

  例如直接运行Intel® Optimized linpack脚本hybrid

  ```shell
  runme_hybrid_inte64
  ```

- 

  ```shell
   mpirun –np N xhpl    #N为进程数
   mpiexec.hydra -np 4 ./xhpl
  ```

-  `mpirun –p4pg xhpl` 需要自己编写配置文件”p4file”指定每个进程在哪个节点运行。配置文件示例：

  > gnode1 0   /test/hpl/test/bin/xhpl
  >
  > gnode1 1   /test/hpl/test/bin/xhpl
  >
  > gnode2 1   /test/hpl/test/bin/xhpl



初始的HPL.dat文件无法满足需求，需要对其进行修改。

## 测试配置文件HPL.dat

HPL.dat文件配置参考：

- [HPL计算器](http://hpl-calculator.sourceforge.net/)

- [HPL-dat生成工具](http://www.advancedclustering.com/act-kb/tune-hpl-dat-file/)

  填入节点数、每个节点的处理器核数、每个节点的内存大小和Block  Size  (NB—数据分配和计算粒度，代表性的良好块规模是32到256个间隔。)。

「10节点，每节点10核心+96G内存，块大小为192」的HPL.dat文件示例：

```shell
# 以下两行 该文件的注释说明
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee

# 以下两行 输出文件
HPL.out      output file name (if any) 
6            device out (6=stdout,7=stderr,file)  #6标准输出 7标准错误输出 其他值表示输出到指定文件

# 以下两行 求解矩阵的大小
1            # of problems sizes (N)  #矩阵规模 规模越大浮点处理性能越高 但测试时占用内存也更大 80%为宜
321024         Ns  #设置为 192 整数倍，在 90 万左右能整除 192 的数值
 
# 以下两行 求解矩阵分块的大小 为提高整体性能，HPL采用分块矩阵的算法
1            # of NBs  一般在256以下 NB×8一定是Cache line的倍数
192           NBs

# 以下一行 阵列处理方式 （按列的排列方式还是按行的排列方式）
0            PMAP process mapping (0=Row-,1=Column-major)  #节点数较多且单节点处理器较少时适合按列

#以下三行 二维处理器网格 PxQ=进程数=系统CPU数 其中 P<=Q且P=2n
1            # of process grids (P x Q) 
10            Ps
10            Qs

# 以下一行 阈值（用以检测求解结果）
16.0         threshold

# 以下八行 L分解的方式
1            # of panel fact
2            PFACTs (0=left, 1=Crout, 2=Right)
1            # of recursive stopping criterium
4            NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
1            # of recursive panel fact.
1            RFACTs (0=left, 1=Crout, 2=Right) #矩阵作消元三种算法：L-left、R-right、C-crout

# 以下两行 L的广播方式
1            # of broadcast
1            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)

# 以下两行 刚波通信深度
1            # of lookahead depth
1            DEPTHs (>=0)  #小规模集群取值1或2 大规模集群取值2到5

# 以下两行 U的广播算法
2            SWAP (0=bin-exch,1=long,2=mix)  #binary exchange  或 long 或 二者混合
64           swapping threshold

# 以下两行 L和U的数据存放格式（数据在内存的存放方式——行存放和列存放）
0            L1 in (0=transposed,1=no-transposed) form
0            U  in (0=transposed,1=no-transposed) form

# 以下一行 平衡策略
1            Equilibration (0=no,1=yes)

# 以下一行 内存地址对齐
8            memory alignment in double (> 0)

##### This line (no. 32) is ignored (it serves as a separator). ######
0                               Number of additional problem sizes for PTRANS
1200 10000 30000                values of N
0                               number of additional blocking sizes for PTRANS
40 9 8 13 13 20 16 32 64        values of NB
```

