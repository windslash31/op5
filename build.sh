# Clang and GCC paths
CLANG=${HOME}/kernel/flash-clang-7.x/bin/clang
CROSS_COMPILE=${HOME}/kernel/aarch64-linux-gnu/bin/aarch64-linux-gnu-

# Clean up
rm ${HOME}/kernel/AnyKernel2/kernels/custom/* \
   ${HOME}/kernel/AnyKernel2/kernels/oos/* \
   ${HOME}/kernel/AnyKernel2/ramdisk/modules \
   ${HOME}/kernel/AnyKernel2/RenderFlash*

# rm -rf ${HOME}/kernel/flash-clang-7.x ${HOME}/kernel/aarch64-linux-gnu

# Update Clang
#cd ${HOME}/kernel/scripts/ && git pull && ./build-clang
#mv ${HOME}/toolchains/flash-clang-7.x ${HOME}/kernel/

# Update Linaro
#cd ${HOME}/kernel/build-tools-gcc && git pull && ./build -a arm64 -s linaro -v 7
#mv ${HOME}/kernel/build-tools-gcc/aarch64-linux-gnu ${HOME}/kernel/

# Build "custom" kernel
cd ${HOME}/kernel/op5
rm -rf out/

make O=out ARCH=arm64 flash-custom_defconfig
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC="${CLANG}" \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE="${CROSS_COMPILE}" \
                      KBUILD_COMPILER_STRING="$(${CLANG}  --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"

# Move custom Image to AK
mv ${HOME}/kernel/op5/out/arch/arm64/boot/Image.gz-dtb ${HOME}/kernel/AnyKernel2/kernels/custom

# Build "oos" kernel
rm -rf out/

make O=out ARCH=arm64 flash-oos_defconfig
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC="${CLANG}" \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE="${CROSS_COMPILE}" \
                      KBUILD_COMPILER_STRING="$(${CLANG}  --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"

# Move OOS Image to AK
mv ${HOME}/kernel/op5/out/arch/arm64/boot/Image.gz-dtb ${HOME}/kernel/AnyKernel2/kernels/oos

# Strip/sign wlan.ko
(
    mkdir -p ${HOME}/kernel/AnyKernel2/ramdisk/modules
    cd out
    ${CROSS_COMPILE}strip --strip-unneeded drivers/staging/qcacld-3.0/wlan.ko
    ./scripts/sign-file sha512 \
                        certs/signing_key.pem \
                        certs/signing_key.x509 \
                        drivers/staging/qcacld-3.0/wlan.ko
    cp drivers/staging/qcacld-3.0/wlan.ko ${HOME}/kernel/AnyKernel2/ramdisk/modules
)

# Make zip.
cd ${HOME}/kernel/AnyKernel2
zip -r9	RenderFlash-2.3.4.zip * -x README RenderFlash-2.3.4.zip

# Move to git folder and auto upload
mv ${HOME}/kernel/AnyKernel2/RenderFlash* ${HOME}/kernel/rfk-zips/op5/8.1/stable/
cd ${HOME}/kernel/rfk-zips/
git add *
git commit -m "Update"
git push


# Clean up at the end as well for good measure
rm ${HOME}/kernel/AnyKernel2/kernels/custom/* \
   ${HOME}/kernel/AnyKernel2/kernels/oos/* \
   ${HOME}/kernel/AnyKernel2/ramdisk/modules \
   ${HOME}/kernel/AnyKernel2/RenderFlash*

rm -rf ${HOME}/kernel/op5/out
