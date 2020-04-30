#!/bin/sh
# 注意: 本脚本不会初始化编译所需的环境，请自行安装

# Copyright (c) 2020, Chuck <fanck0605@qq.com>
#
# 警告:
# 对着屏幕的哥们, 我们允许你使用此脚本, 但不允许你抹去作者的信息, 请保留这段话.
# 你可以随意使用本脚本的代码, 但请注明出处.
#
set -eu

# init main project
echo "deleting ./nanopi-r2s"
sudo rm -rf nanopi-r2s
git clone --single-branch --depth=1 -b lean https://github.com/fanck0605/nanopi-r2s.git nanopi-r2s
cd nanopi-r2s

# init friendlywrt source
mkdir rk3328 && cd rk3328
repo init -u https://github.com/fanck0605/friendlywrt_manifests -b master-v19.07.1 -m rk3328.xml --repo-url=https://github.com/friendlyarm/repo --no-clone-bundle
repo sync -c --no-clone-bundle -j8


# install lean's project
# enable some feeds
cd friendlywrt
sed -i 's/#src-git/src-git/g' ./feeds.conf.default
cd ..
# end of enable some feeds

# update argon
cd friendlywrt
rm -rf package/lean/luci-theme-argon
git clone --single-branch --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/lean/luci-theme-argon
cd ..
# end of update argon

# install filebrowser
git clone --single-branch --depth=1 -b openwrt-18.06 https://github.com/project-openwrt/openwrt.git openwrt
mkdir -p friendlywrt/package/ctcgfw
cp -a openwrt/package/ctcgfw/filebrowser friendlywrt/package/ctcgfw/
cp -a openwrt/package/ctcgfw/luci-app-filebrowser friendlywrt/package/ctcgfw/
rm -rf openwrt
# end of install filebrowser

# install r2sflasher
rm -rf r2sflasher
mkdir -p friendlywrt/package/songchenwen
git clone https://github.com/songchenwen/nanopi-r2s.git r2sflasher
cp -a r2sflasher/luci-app-r2sflasher friendlywrt/package/songchenwen/
rm -rf r2sflasher
# end of install r2sflasher

# swap wan and lan
cd friendlywrt
git apply ../../patches/003-openwrt-swap-wan-and-lan.patch
cd ..
# end of swap wan and lan
# end of install lean's project


# install openwrt's kernel patches
git clone --single-branch --depth=1 -b master https://github.com/openwrt/openwrt.git openwrt
cd openwrt
./scripts/patch-kernel.sh ../kernel ./target/linux/generic/backport-5.4
./scripts/patch-kernel.sh ../kernel ./target/linux/generic/pending-5.4
./scripts/patch-kernel.sh ../kernel ./target/linux/generic/hack-5.4
./scripts/patch-kernel.sh ../kernel ./target/linux/octeontx/patches-5.4
cp -a ./target/linux/generic/files/* ../kernel/
cd ../ && rm -rf openwrt
# end of install openwrt's kernel patches


# enable full cone nat and flow offload
cd kernel/
wget -O net/netfilter/xt_FULLCONENAT.c https://raw.githubusercontent.com/Chion82/netfilter-full-cone-nat/master/xt_FULLCONENAT.c
git apply ../../patches/001-kernel-add-full_cone_nat.patch
cat ../../nanopi-r2_linux_defconfig > ./arch/arm64/configs/nanopi-r2_linux_defconfig
cd ../
# end of enable full cone nat and flow offload

# apply myconfig
cat ../config_rk3328 > ./friendlywrt/.config
cat ../config_rk3328 > ./configs/config_rk3328

cd friendlywrt
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
cd ..

exit 0

# 如果你不需要再改配置了,直接去除 exit 0,就会自动编译好固件，否则下面的语句不会执行
./build.sh nanopi_r2s.mk

lodev=$(sudo losetup -f) && \
sudo losetup -o 100663296 $lodev out/FriendlyWrt*.img && \
sudo rm -rf /mnt/friendlywrt-tmp && \
sudo mkdir -p /mnt/friendlywrt-tmp && \
sudo mount $lodev /mnt/friendlywrt-tmp && \
sudo chown -R root:root /mnt/friendlywrt-tmp && \
sudo umount /mnt/friendlywrt-tmp && \
sudo losetup -d $lodev && \
gzip out/FriendlyWrt*.img
