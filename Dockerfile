# Alternative: Build sans les presets CMake
# Remplace la section build par:

# Build avec CMake classique au lieu des presets
RUN \
    cd /project \
    && mkdir -p build/release \
    && cd build/release \
    && cmake ../.. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=${PICO_SDK_PATH}/cmake/preload/toolchains/pico_arm_gcc.cmake \
        -G Ninja \
    && ninja \
    && ls -la \
    && test -f TSM_PicoW_CI_CD.hex && echo "SUCCESS: .hex file created"