# 使用 Github Actions 在线编译 NanoPi-R2S 固件

## 说明
* ipv4: 192.168.2.1
* username: root
* password: password

## 特色
* 使用 [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)，并 merge 了 [friendlyarm/friendlywrt](https://github.com/friendlyarm/friendlywrt)
    - 编译时，自动使用 lean 的最新源码
    - 包含大部分 [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) 的特性
    - 可以支持 [friendlyarm/friendlywrt](https://github.com/friendlyarm/friendlywrt) 所支持的机型
* 集成最新实时监控 Netdata，可以查看 NanoPi-R2s 的实时状态
* 开启了 [Full Cone Nat](https://github.com/Chion82/netfilter-full-cone-nat)，对游戏用户支持更佳
* 默认支持 IPv6，可以访问最新 IPv6 规范的互联网。
* 使用 [cifsd](https://github.com/namjaejeon/cifsd)(内核态的 samba)，性能更高

再次感谢 [lean 的源码](https://github.com/coolsnowwolf/lede)

## 用法
1. Fork 到自己的账号下
2. 进入 Actions 界面，启用 Github Actions
3. 在 `config_rk3328` 文件中，自定义所需要的软件包
   比如需要 luci-app-samba， 那么只要在文件中添加一行 CONFIG_PACKAGE_luci-app-samba=y

## 注意
应用 friendlyelec 修改的 [patch](https://github.com/fanck0605/friendlywrt-nanopi_r2s/raw/lean/patches/002-openwrt-apply-friendlywrt.patch)，需要的自行拿走
产品发布初期，官方代码每天都在变，遇到无法编译时，请过来查看 `.yml` 与 `config` 最新异动。

## 参考
* [使用Github的Actions功能在线编译NanoPi-R1S固件（包含H5和H3）](https://totoro.site/index.php/archives/70/)
* [skytotwo/NanoPi-R1S-Build-By-Actions](https://github.com/skytotwo/NanoPi-R1S-Build-By-Actions)
* [klever1988/nanopi-openwrt](https://github.com/klever1988/nanopi-openwrt)
* [yangliu/NanoPi-R2S](https://github.com/yangliu/NanoPi-R2S)
* [maxming2333/NanoPi-R2S](https://github.com/maxming2333/NanoPi-R2S)
* [soffchen/NanoPi-R2S](https://github.com/soffchen/NanoPi-R2S)
