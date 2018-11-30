AS3 game tool
===============

## AS3游戏工具

* 特效序列帧、动作序列帧打包，支持配置多动作多方向
* 压缩打包PNG，将PNG的ARGB拆分成RGB和Alpha，把RGB压缩成JPG格式，把Alpha通道单独zip压缩
* 位图切片，可以指定命名规则
* 批量图片缩放
* 更友好的交互，使用Worker进行后台线程处理，并同步进度到UI界面

> 特效播放需要配合[as3游戏库](https://github.com/worrysprite/worrysprite)

---

## build

* 先设置bat\SetupSDK.bat里的FlexSDK路径
* 使用WorkerProject.bat打包WorkerProject
* 使用PackageApp.bat即可打包AIR格式安装包
