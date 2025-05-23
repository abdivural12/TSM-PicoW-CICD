# Fetch ubuntu image
FROM ubuntu:24.04

# Install prerequisites
RUN \
    apt update && apt install -y \
    git python3 cmake gcc-arm-none-eabi libnewlib-arm-none-eabi \
    build-essential ninja-build nano doxygen graphviz \
    apt-transport-https ca-certificates curl software-properties-common \
    libx11-xcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 \
    libxcb-render-util0 libxcb-shape0 libxcb-sync1 libxcb-util1 \
    libxcb-xfixes0 libxcb-xkb1 libxkbcommon-x11-0 libxkbcommon0 xkb-data \
    udev

# Install SEGGER
RUN \
    mkdir -p /project && cd /project && \
    curl -d "accept_license_agreement=accepted&submit=Download+software" \
    -X POST -O "https://www.segger.com/downloads/jlink/JLink_Linux_x86_64.deb"

RUN \
    cd /project && \
    dpkg --unpack JLink_Linux_x86_64.deb && \
    rm -f /var/lib/dpkg/info/jlink.postinst && \
    dpkg --configure jlink && \
    apt install -yf

# Install Pico SDK
RUN \
    mkdir -p /project/src && cd /project && \
    git clone https://github.com/raspberrypi/pico-sdk.git --branch master && \
    cd pico-sdk && git submodule update --init

# Set Pico SDK env var
ENV PICO_SDK_PATH=/project/pico-sdk

# Copy project sources into image
COPY CMakeLists.txt             /project/
COPY gcovr                      /project/gcovr/
COPY gcov                       /project/gcov/
COPY doxy                       /project/doxy/
COPY McuLib                     /project/McuLib/
COPY src                        /project/src/

# Build manually using CMake (no presets)
RUN mkdir /project/build && cd /project/build && \
    cmake .. \
    -DPICO_SDK_PATH=/project/pico-sdk \
    -DCMAKE_TOOLCHAIN_FILE=/project/pico-sdk/cmake/preload/toolchains/pico_arm_gcc.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja && \
    cmake --build . --parallel

# Create documentation
RUN cd /project/doxy && doxygen Doxyfile

# Entry point
ENTRYPOINT ["/bin/bash"]
