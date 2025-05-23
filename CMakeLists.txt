cmake_minimum_required(VERSION 3.1...3.27)

# Required for McuLib, to know the target system
set(
  MCULIB_TARGET RP2040 CACHE STRING 
  "Select McuLib target: MCUXPRESSO, RP2040 or ESP32"
)

# turn variable on for verbose output, useful for build debugging. Or run 'ninja --verbose' in the build folder
#set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "ON")

# settings for the board and hardware used
set(PICO_PLATFORM rp2040)
set(PICO_BOARD pico_w) # pico or pico_w

# initialize the SDK based on PICO_SDK_PATH
# note: this must happen before project()
# Include build functions from Pico SDK
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

# set project name ${CMAKE_PROJECT_NAME}
project(TSM_PicoW_CI_CD
  C CXX ASM
)

# set C and C++ standard to be used
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# [Platfrom specific command] Initialize the Raspberry Pi Pico SDK
pico_sdk_init()

# set variables for directories
set(PROJECT_ROOT_DIR  "${CMAKE_CURRENT_SOURCE_DIR}")
set(MCULIB_DIR        "${PROJECT_ROOT_DIR}/McuLib")
set(EXECUTABLE         ${PROJECT_NAME}.elf)
set(BUILD_DIR         "${PROJECT_ROOT_DIR}/build")
set(TEST_EXECUTABLE   "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.elf")

add_compile_options(-include "${PROJECT_ROOT_DIR}/src/IncludeMcuLibConfig.h")
add_compile_options(-I "${PROJECT_ROOT_DIR}/src") # McuLib to find our local header files

# add linker flags to print cross-reference table in map file and memory usage on console
add_link_options(-Wl,--cref,--print-memory-usage)

# to avoid that it shows up as 'Reset' USB device, see https://forums.raspberrypi.com/viewtopic.php?t=324909
add_compile_options(-DPICO_STDIO_USB_ENABLE_RESET_VIA_VENDOR_INTERFACE=0)

# Check if ENABLE_UNIT_TESTING is set to ON in the CMake preset
if (ENABLE_UNIT_TESTING)
  message(STATUS "ENABLE_UNIT_TESTING is ON")
  add_compile_options(-DENABLE_UNIT_TESTS=1) # used to enable tests in code
else()
  message(STATUS "ENABLE_UNIT_TESTING is OFF")
  add_compile_options(-DENABLE_UNIT_TESTS=0) # used to disable tests in code
endif()

add_executable(${CMAKE_PROJECT_NAME}
  # add additional source files here
)

add_custom_command(TARGET ${CMAKE_PROJECT_NAME} POST_BUILD
  COMMAND arm-none-eabi-size "${CMAKE_PROJECT_NAME}.elf"
  COMMENT "Printing code and data size"
)

# add component directories to the list
add_subdirectory(./src                  src)
add_subdirectory(${MCULIB_DIR}          McuLib)
add_subdirectory(${MCULIB_DIR}/rdimon   rdimon)
add_subdirectory(./gcov                 gcov)

# generate extra files (map/bin/hex/uf2)
pico_add_extra_outputs(${CMAKE_PROJECT_NAME})

target_link_libraries(
  ${CMAKE_PROJECT_NAME}
  PUBLIC srcLib
  PUBLIC pico_stdlib
  PUBLIC rdimonLib # file I/O with semihosting
)

##################################################################################
# Unit Test support
if (ENABLE_UNIT_TESTING)
  # Adding some options to make CTest more verbose, helpful in case of failures.
  list(APPEND CMAKE_CTEST_ARGUMENTS "--output-on-failure")
  list(APPEND CMAKE_CTEST_ARGUMENTS "--verbose")

  # Include CTest support
  include(CTest) # note: this adds a BUILD_TESTING which defaults to ON, which can be used in other CMakeLists.txt

  # Just a check for the variable
  if (BUILD_TESTING)
    message(STATUS "BUILD_TESTING is ON")
  endif()

  message(STATUS "Adding unity")
  add_subdirectory(${MCULIB_DIR}/unity   unity)
endif()
