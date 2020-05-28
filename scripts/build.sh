#!/bin/bash
# Copyright (c) 2020, Chuck <fanck0605@qq.com>
#
# 警告:
# 对着屏幕的哥们, 我们允许你使用此脚本, 但不允许你抹去作者的信息, 请保留这段话.
# 你可以随意使用本脚本的代码, 但请注明出处.
#

set -eu

# init environment
sudo apt update
sudo apt -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python python3.5 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf
wget -O- https://raw.githubusercontent.com/friendlyarm/build-env-on-ubuntu-bionic/master/install.sh | bash

if ! which repo >/dev/null 2>&1; then
  rm -rf friendlyarm-repo
  git clone https://github.com/friendlyarm/repo friendlyarm-repo
  sudo cp friendlyarm-repo/repo /usr/bin/
  rm -rf friendlyarm-repo
fi
# end of init environment

# init main project
sudo rm -rf nanopi-r2s
git clone --depth 1 -b lean https://github.com/fanck0605/nanopi-r2s.git nanopi-r2s
cd nanopi-r2s
# end of init main project

# init friendlywrt source
mkdir rk3328 && cd rk3328
repo init -u https://github.com/fanck0605/friendlywrt_mainfests -b openwrt-lean -m rk3328.xml --repo-url=https://github.com/friendlyarm/repo --no-clone-bundle
repo sync -c --no-clone-bundle -j8
# end of init friendlywrt source

# upgrade source
pushd friendlywrt
git remote add lean https://github.com/coolsnowwolf/lede.git
git fetch lean master && git rebase lean/master
popd && pushd kernel
git remote add linux https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
git fetch linux linux-5.4.y && git rebase linux/linux-5.4.y
popd
# end of upgrade source

# init lean's project
# enable some feeds
pushd friendlywrt
sed -i 's/#src-git/src-git/g' ./feeds.conf.default
popd
# end of enable some feeds

# update argon
pushd friendlywrt/package/lean
rm -rf luci-theme-argon
git clone --depth 1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git luci-theme-argon
popd
# end of update argon

# install filebrowser
git clone --depth 1 -b openwrt-18.06 https://github.com/project-openwrt/openwrt.git openwrt
mkdir -p friendlywrt/package/ctcgfw
cp -a openwrt/package/ctcgfw/filebrowser friendlywrt/package/ctcgfw/
cp -a openwrt/package/ctcgfw/luci-app-filebrowser friendlywrt/package/ctcgfw/
rm -rf openwrt
# end of install filebrowser

# install r2sflasher
mkdir -p friendlywrt/package/songchenwen
git clone --depth 1 https://github.com/songchenwen/nanopi-r2s.git r2sflasher
cp -a r2sflasher/luci-app-r2sflasher friendlywrt/package/songchenwen/
rm -rf r2sflasher
# end of install r2sflasher
# end of init lean's project

# install openwrt's kernel patches
git clone --depth 1 -b 18.06-kernel5.4 https://github.com/project-openwrt/openwrt.git openwrt
pushd openwrt
./scripts/patch-kernel.sh ../kernel ./target/linux/generic/backport-5.4
./scripts/patch-kernel.sh ../kernel ./target/linux/generic/pending-5.4
./scripts/patch-kernel.sh ../kernel ./target/linux/generic/hack-5.4
./scripts/patch-kernel.sh ../kernel ./target/linux/octeontx/patches-5.4
cp -a ./target/linux/generic/files/* ../kernel/
popd && rm -rf openwrt
# end of install openwrt's kernel patches

# enable 1.5GHz
pushd kernel
wget -O- https://raw.githubusercontent.com/armbian/build/master/patch/kernel/rockchip64-dev/RK3328-enable-1512mhz-opp.patch | git apply
popd
# end of enable 1.5GHz

# enable full cone nat and flow offload
pushd kernel
wget -O net/netfilter/xt_FULLCONENAT.c https://raw.githubusercontent.com/Chion82/netfilter-full-cone-nat/master/xt_FULLCONENAT.c
git apply ../../patches/001-kernel-add-full_cone_nat.patch
cat ../../nanopi-r2_linux_defconfig >./arch/arm64/configs/nanopi-r2_linux_defconfig
popd
# end of enable full cone nat and flow offload

# add daemon script
pushd friendlywrt
mv ../../scripts/check_net4.sh package/base-files/files/usr/bin/check_net4
sed -i '/^exit/i\/bin/sh /usr/bin/check_net4 >/dev/null 2>&1 &' package/base-files/files/etc/rc.local
popd
# end of add daemon script

# swap wan and lan
pushd friendlywrt
git apply ../../patches/003-openwrt-swap-wan-and-lan.patch
popd
# end of swap wan and lan

# update feeds
pushd friendlywrt
./scripts/feeds update -a
./scripts/feeds install -a
popd

# apply myconfig
cat ../config_rk3328 >./friendlywrt/.config
cat ../config_rk3328 >./configs/config_rk3328

cd friendlywrt
make defconfig
cd ..

./build.sh nanopi_r2s.mk

lodev=$(sudo losetup -f) && \
sudo losetup -P $lodev out/FriendlyWrt*.img && \
sudo rm -rf /mnt/friendlywrt-tmp && \
sudo mkdir -p /mnt/friendlywrt-tmp && \
sudo mount ${lodev}p1 /mnt/friendlywrt-tmp && \
sudo chown -R root:root /mnt/friendlywrt-tmp && \
sudo umount /mnt/friendlywrt-tmp && \
sudo losetup -d $lodev

mkdir ../artifact
gzip out/FriendlyWrt*.img
cp out/FriendlyWrt*.img.gz ../artifact/

pushd friendlywrt
./scripts/diffconfig.sh >../../artifact/config-lite
cp .config ../../artifact/config-full
popd && pushd kernel
export PATH=/opt/FriendlyARM/toolchain/6.4-aarch64/bin/:$PATH
export CROSS_COMPILE='aarch64-linux-gnu-'
export ARCH=arm64
make savedefconfig
cp .config ../../artifact/kconfig-full
cp defconfig ../../artifact/kconfig-lite
popd

cd ../../artifact && \
zip -q -r ../FriendlyWrt.zip *
