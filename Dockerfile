# Fetch ubuntu image
FROM ubuntu:24.04

# Force rebuild - change this comment to invalidate cache: v2024-05-27-fix
# This ensures GitHub Actions rebuilds from scratch

# Install prerequisites
RUN \
    apt update \
    && apt install -y git python3 \
    && apt install -y cmake gcc-arm-none-eabi libnewlib-arm-none-eabi build-essential ninja-build make

# Install nano editor
RUN apt-get install -y nano

# Install doxygen and graphviz
RUN apt-get install -y doxygen graphviz

# Install curl and others, needed to get SEGGER
RUN apt-get install -y apt-transport-https ca-certificates curl software-properties-common
RUN apt-get install -y libx11-xcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 libxcb-xkb1 libxkbcommon-x11-0 libxkbcommon0 xkb-data
RUN apt-get install -y udev

# Install SEGGER
RUN \
    mkdir -p /project \
    && cd /project \
    && curl -d "accept_license_agreement=accepted&submit=Download+software" -X POST -O "https://www.segger.com/downloads/jlink/JLink_Linux_x86_64.deb" 

# issue with udev, see https://forum.segger.com/index.php/Thread/8953-SOLVED-J-Link-Linux-installer-fails-for-Docker-containers-Error-Failed-to-update/
RUN \
    cd /project \
    && dpkg --unpack JLink_Linux_x86_64.deb \
    && rm -f /var/lib/dpkg/info/jlink.postinst \
    && dpkg --configure jlink \
    && apt install -yf

# Install Pico SDK
RUN \
    mkdir -p /project/src/ \
    && cd /project \
    && git clone https://github.com/raspberrypi/pico-sdk.git --branch master \
    && cd pico-sdk/ \
    && git submodule update --init
    
# Set the Pico SDK environment variable
ENV PICO_SDK_PATH=/project/pico-sdk/

# Copy project sources into image
COPY CMakePresets.json          /project/
COPY CMakeLists.txt             /project/
COPY gcovr                      /project/gcovr/
COPY gcov                       /project/gcov/
COPY doxy                       /project/doxy/
COPY McuLib                     /project/McuLib/
COPY src                        /project/src/

# Set working directory
WORKDIR /project

# Build project using CMake classic instead of presets
# DEBUG BUILD first
RUN \
    mkdir -p build/debug \
    && cd build/debug \
    && PICO_SDK_PATH=/project/pico-sdk cmake ../.. \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_TOOLCHAIN_FILE=/project/pico-sdk/cmake/preload/toolchains/pico_arm_gcc.cmake \
        -G "Unix Makefiles" \
    && make -j$(nproc) \
    && echo "DEBUG build completed successfully"

# RELEASE BUILD (the important one for the .hex file)
RUN \
    mkdir -p build/release \
    && cd build/release \
    && PICO_SDK_PATH=/project/pico-sdk cmake ../.. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=/project/pico-sdk/cmake/preload/toolchains/pico_arm_gcc.cmake \
        -G "Unix Makefiles" \
    && make -j$(nproc) \
    && ls -la \
    && test -f TSM_PicoW_CI_CD.hex && echo "SUCCESS: .hex file created" \
    && ls -la TSM_PicoW_CI_CD.*

# Create documentation
RUN \
    cd /project/doxy \
    && doxygen Doxyfile

# Command that will be invoked when the container starts
ENTRYPOINT ["/bin/bash"]