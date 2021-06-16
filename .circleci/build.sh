#!/bin/bash
echo "Cloning dependencies"
git clone --depth=1 -b main https://github.com/brucetech627/kernel_xiaomi_sweet-3 kernel
cd kernel
git clone --depth=1 -b master https://github.com/MASTERGUY/proton-clang clang
git clone --depth=1 https://github.com/stormbreaker-project/AnyKernel3 -b sweet AnyKernel3
echo "Done"
KERNEL_DIR=$(pwd)
ANYKERNEL3_DIR="${KERNEL_DIR}/AnyKernel3"
export PATH="${KERNEL_DIR}/clang/bin:${PATH}"
export KBUILD_COMPILER_STRING="(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=brucetech
export KBUILD_BUILD_HOST=circleci
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>• Sweet-Stormbreaker Kernel •</b>%0ABuild started on <code>Circle CI</code>%0AFor device <b>Redmi Note 10 Pro/Max</b> (sweet/sweetin)%0Abranch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: <code>Proton clang 13</code>%0AStarted on <code>$(date)</code>%0A<b>Build Status:</b>"
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)."
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {
    make sweet_user_defconfig O=out
    make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip

echo "**** Verify Image.gz-dtb & dtbo.img ****"
ls $PWD/out/arch/arm64/boot/Image.gz-dtb
}
# Zipping
function zipping() {
    cp $PWD/out/arch/arm64/boot/Image.gz-dtb $ANYKERNEL3_DIR/
    cd $ANYKERNEL3_DIR || exit 1
    zip -r9 Sweet-StormBreaker.zip *
    curl --upload-file ./Sweet-StormBreaker.zip https://transfer.sh/Sweet-StormBreaker.zip
}
sendinfo
compile
zipping
finerr
push
