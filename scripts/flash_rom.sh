#!/bin/sh
# Copyright (c) 2020, Chuck <fanck0605@qq.com>
# Copyright (c) 2020, klever1988 <56048681+klever1988@users.noreply.github.com>
#
#     警告:对着屏幕的哥们,我们允许你使用此脚本，但不允许你抹去作者的信息,请保留这段话。
#

# the function to flash a rom
# useage: flash_rom /tmp/rom.img.gz /dev/mmcblk0 gz
flash_rom() {
    rom_path=$1
    sys_dev=$2
    rom_type=$3
    echo -e "\e[92m开始刷写固件: $rom_path\e[0m"

    # 启用 sysrq 魔术键
    echo 1 >/proc/sys/kernel/sysrq

    # 立即重新挂载所有的文件系统为只读，防止新数据损坏镜像
    echo u >/proc/sysrq-trigger

    rotestfile="/rotest.txt"
    touch ${rotestfile}
    if [ $? -eq 0 ]; then
        rm ${rotestfile}
        echo -e "\e[91mUnmount system partition failed! Please reboot before using.\e[0m"
        exit 1
    fi

    # it may be more safer to use fsync
    case $rom_type in
    gz)
        pv $rom_path | gunzip -c | dd of=$sys_dev conv=fsync
        ;;
    zst)
        pv $rom_path | zstdcat | dd of=$sys_dev conv=fsync
        ;;
    esac

    echo -e "\e[92mFlashing done! Rebooting...\e[0m"

    # waiting for std out, it is necessary,
    # otherwise you will not see the output
    sleep 1

    # here we can't use `reboot`, after we flash
    # the system partition, `reboot` may fail
    echo b >/proc/sysrq-trigger
}

choose_yn() {
    while :; do
        read input
        case ${input:0:1} in
        y | Y)
            return 0
            ;;
        n | N)
            return 1
            ;;
        *)
            echo -e "\e[92mPlease enter Y/n: \e[0m\c"
            ;;
        esac
    done
}

############################
#                          #
#     Check Dependence     #
#                          #
############################
pv --version >/dev/null
if [ $? -ne 0 ]; then
    echo -e "\e[91m未安装 pv!\e[0m"
    exit 4
fi

gunzip --version >/dev/null
if [ $? -ne 0 ]; then
    have_gunzip=false
else
    have_gunzip=true
fi

zstd --version >/dev/null
if [ $? -ne 0 ]; then
    have_zstd=false
else
    have_zstd=true
fi

losetup --version >/dev/null
if [ $? -ne 0 ]; then
    have_losetup=false
else
    have_losetup=true
fi

if [ $# -eq 0 ]; then
    echo -e "\e[91m请输入固件包路径!\e[0m"
    exit 2
fi

rom_path=$1

if [ ! -f $rom_path ]; then
    echo -e "\e[91m未找到固件包: $rom_path\e[0m"
    exit 1
fi

if [ ${rom_path: -2} = "gz" ]; then
    if [ $have_gunzip = false ]; then
        echo -e "\e[91m未安装 gunzip, 无法刷写该类型固件!\e[0m"
        exit 4
    fi
    rom_type="gz"
elif [ ${rom_path: -3} = "zst" ]; then
    if [ $have_zstd = false ]; then
        echo -e "\e[91m未安装 zstd, 无法刷写该类型固件!\e[0m"
        exit 4
    fi
    rom_type="zst"
else
    echo -e "\e[91m不支持的固件包: $rom_path\e[0m"
    exit 3
fi

if [ $have_zstd = false ] || [ $have_losetup = false ]; then
    echo -e "\e[91m未安装 zstd 或 losetup, 无法保留配置!\e[0m"
    echo -e "\e[92m请选择是否继续刷写固件(y/n): \e[0m\c"
    choose_yn
    case $? in
    0)
        save_conf=false
        ;;
    1)
        exit 0
        ;;
    *) ;;
    esac
else
    echo -e "\e[92m请选择是否保留配置文件(y/n): \e[0m\c"
    choose_yn
    case $? in
    0)
        save_conf=true
        ;;
    1)
        save_conf=false
        ;;
    *) ;;
    esac
fi

if [ $save_conf = true ]; then
    echo -e '\e[92m正在解压镜像文件...\e[0m'
    case $rom_type in
    gz)
        pv $rom_path | gunzip -c >/root/FriendlyWrt.img
        ;;
    zst)
        pv $rom_path | zstdcat >/root/FriendlyWrt.img
        ;;
    esac

    rm -f $rom_path

    echo -e '\e[92m正在备份配置文件...\e[0m'
    rm -rf /mnt/friendlywrt-tmp
    mkdir -p /mnt/friendlywrt-tmp

    lodev=$(losetup -f)
    losetup -P $lodev /root/FriendlyWrt.img
    mount ${lodev}p1 /mnt/friendlywrt-tmp

    sysupgrade -b /tmp/backup.tar.gz
    tar zxf /tmp/backup.tar.gz -C /mnt/friendlywrt-tmp
    umount /mnt/friendlywrt-tmp
    losetup -d $lodev
    echo -e '\e[92m配置文件备份完毕, 正在重新打包...\e[0m'
    zstdmt /root/FriendlyWrt.img -o /tmp/FriendlyWrtUpgrade.img.zst
    rom_type="zst"
else
    case $rom_type in
    gz)
        mv $rom_path /tmp/FriendlyWrtUpgrade.img.gz
        ;;
    zst)
        mv $rom_path /tmp/FriendlyWrtUpgrade.img.zst
        ;;
    esac
fi
#echo "flashing"
flash_rom /tmp/FriendlyWrtUpgrade.img.* /dev/mmcblk0 $rom_type
