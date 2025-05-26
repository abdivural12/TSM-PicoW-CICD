# Fetch ubuntu image
FROM ubuntu:24.04

# Install prerequisites
RUN \
    apt update \
    && apt install -y git python3 \
    && apt install -y cmake gcc-arm-none-eabi libnewlib-arm-none-eabi build-essential ninja-build

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

# DEBUG: Vérifier l'environnement
RUN echo "=== ENVIRONMENT DEBUG ===" && \
    echo "PWD: $(pwd)" && \
    echo "PICO_SDK_PATH: $PICO_SDK_PATH" && \
    ls -la $PICO_SDK_PATH && \
    echo "CMake version:" && cmake --version && \
    echo "GCC ARM version:" && arm-none-eabi-gcc --version && \
    echo "Ninja version:" && ninja --version

# DEBUG: Vérifier les fichiers copiés
RUN echo "=== PROJECT FILES DEBUG ===" && \
    ls -la /project/ && \
    echo "CMakePresets.json content:" && \
    cat CMakePresets.json

# DEBUG: Tester les presets disponibles
RUN echo "=== CMAKE PRESETS DEBUG ===" && \
    cmake --list-presets=all

# ETAPE 1: Configuration DEBUG seulement
RUN echo "=== STEP 1: Configuring DEBUG preset ===" && \
    cmake --preset debug && \
    echo "DEBUG configuration SUCCESS"

# ETAPE 2: Build DEBUG seulement  
RUN echo "=== STEP 2: Building DEBUG ===" && \
    cmake --build --preset debug && \
    echo "DEBUG build SUCCESS" && \
    ls -la build/debug/

# ETAPE 3: Configuration RELEASE seulement
RUN echo "=== STEP 3: Configuring RELEASE preset ===" && \
    cmake --preset release && \
    echo "RELEASE configuration SUCCESS"

# ETAPE 4: Build RELEASE seulement
RUN echo "=== STEP 4: Building RELEASE ===" && \
    cmake --build --preset release && \
    echo "RELEASE build SUCCESS" && \
    ls -la build/release/

# Vérifier que le fichier .hex existe
RUN test -f build/release/TSM_PicoW_CI_CD.hex && \
    echo "SUCCESS: .hex file found!" && \
    ls -la build/release/TSM_PicoW_CI_CD.hex

# Create documentation (déplacé après les builds critiques)
RUN \
    cd /project/doxy \
    && doxygen Doxyfile

# Command that will be invoked when the container starts
ENTRYPOINT ["/bin/bash"]