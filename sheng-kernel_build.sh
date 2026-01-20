#!/bin/bash
set -e  # 遇到错误立即退出

# 克隆指定版本的内核源码
git clone https://github.com/map220v/sm8550-mainline.git --branch sheng-6.18 --depth 1 linux
cd linux

# 下载内核配置文件
wget -O arch/arm64/configs/sheng.config https://gitlab.postmarketos.org/alghiffaryfa19/pmaports/-/raw/sheng/device/testing/linux-postmarketos-qcom-sm8550/config-postmarketos-qcom-sm8550.aarch64

# 生成内核配置
make -j$(nproc) ARCH=arm64 LLVM=1 defconfig sheng.config

# 编译内核
make -j$(nproc) ARCH=arm64 LLVM=1

# 获取内核版本号
_kernel_version="$(make kernelrelease -s)"

wget https://raw.githubusercontent.com/alghiffaryfa19/ubuntu-xiaomi-elish-enuma-sheng/refs/heads/main/mkbootimg
chmod +x mkbootimg

cat $2/linux/arch/arm64/boot/Image.gz $2/linux/arch/arm64/boot/dts/qcom/sm8550-xiaomi-sheng.dtb > $2/linux/Image.gz-dtb_sheng
mv $2/linux/Image.gz-dtb_sheng $2/linux/zImage_sheng
mkbootimg --kernel zImage_sheng --cmdline "root=PARTLABEL=linux" --base 0x00000000 --kernel_offset 0x00008000 --tags_offset 0x01e00000 --pagesize 4096 --id -o $2/boot_sheng.img


# 更新 deb 包控制文件中的版本号
sed -i "s/Version:.*/Version: ${_kernel_version}/" ../linux-xiaomi-sheng/DEBIAN/control

# 清理并安装内核模块
rm -rf ../linux-xiaomi-sheng/lib
make -j$(nproc) ARCH=arm64 LLVM=1 INSTALL_MOD_PATH=../linux-xiaomi-sheng modules_install
rm ../linux-xiaomi-sheng/lib/modules/**/build

cd ..

# 清理源码目录
rm -rf linux

# 构建 deb 包
dpkg-deb --build --root-owner-group linux-xiaomi-sheng
