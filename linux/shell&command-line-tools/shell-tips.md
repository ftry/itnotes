- 获取当前文件的路径

  ```shell
  readlink -f `dirname $0`
  ```

- 打开默认应用 `xdg-open <file or url>`
  ```shell
  xdg-open http://localhost #使用默认浏览器访问http://localhost
  xdg-open testfile  #使用默认编辑器打开testfile文件
  ```

- 退出shell不保存此次操作历史到history
  - `kill -9 $$`