# tee

从标准输入设备读取数据，将其内容输出到标准输出设备，同时保存成文件。

```shell
export RSH=ssh
./iozone -I -t 5 -i 0 -i 1 -s 30g -r 1M -+m iolist -O -Rb 90.xls |tee testjiqun.txt
```

