# 使用 Github Actions 在线编译 NanoPi-R2s 固件

## 预编译的版本
https://github.com/fanck0605/nanopi_r2s/releases

## 说明
* ipv4: 192.168.2.1
* username: root
* password: password

## 特色
* 完美的 Flow Offload 支持，不与 PPPoE 冲突，降低 CPU 负载
* 使用 [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)，并 merge 了 [friendlyarm/friendlywrt](https://github.com/friendlyarm/friendlywrt)
    - 包含大部分 [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) 的特性（网络相关的内核功能已经正常啦！）
    - 可以支持 [friendlyarm/friendlywrt](https://github.com/friendlyarm/friendlywrt) 所支持的机型
* 开启了 [Full Cone Nat](https://github.com/Chion82/netfilter-full-cone-nat)，对游戏用户支持更佳
* 支持 IPv6，可以访问最新 IPv6 规范的互联网。
    - 需要关闭 *网络* -> *DHCP/DNS* -> *高级设置* -> *禁止解析 IPv6 DNS 记录*
* wan 和 lan 互换，lan 口是原生千兆网卡，更加稳定

## 用法
1. Fork 到自己的账号下
2. 进入 Actions 界面，启用 Github Actions
3. 在 `config_rk3328` 文件中，自定义所需要的软件包
    - 比如需要 luci-app-samba， 那么只要在文件中添加一行 CONFIG_PACKAGE_luci-app-samba=y

## 注意
应用 friendlyelec 修改的 [patch](https://github.com/fanck0605/nanopi_r2s/raw/lean/patches/002-openwrt-apply-friendlywrt.patch)，需要的自行拿走

已经合并 friendlyelec 修改的 Lean's LEDE: [fanck0605/friendlywrt](https://github.com/fanck0605/friendlywrt)
 - 这个版本加入了我自己的一些配置，如需去除，请使用 git reset --hard <commit_id>

产品发布初期，官方代码每天都在变，遇到无法编译时，请过来查看 `.yml` 与 `config` 最新异动。

cifsd 与 samba 有冲突，只能二选一。(cifsd 暂时无法工作)
ps: 可能是永久

## 特别感谢（本项目的出现离不开以下项目）
* [soffchen/NanoPi-R2S](https://github.com/soffchen/NanoPi-R2S)
* [klever1988/nanopi-openwrt](https://github.com/klever1988/nanopi-openwrt)
* [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
* [friendlyarm/friendlywrt](https://github.com/friendlyarm/friendlywrt)

## 参考
* [使用Github的Actions功能在线编译NanoPi-R1S固件（包含H5和H3）](https://totoro.site/index.php/archives/70/)
* [skytotwo/NanoPi-R1S-Build-By-Actions](https://github.com/skytotwo/NanoPi-R1S-Build-By-Actions)
* [yangliu/NanoPi-R2S](https://github.com/yangliu/NanoPi-R2S)
* [maxming2333/NanoPi-R2S](https://github.com/maxming2333/NanoPi-R2S)
