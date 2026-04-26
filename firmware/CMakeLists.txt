# The following five lines of boilerplate have to be in your project's
# CMakeLists in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.16)

set(PROJECT_VER "1.2.14-dev")
add_definitions(-DFIRMWARE_VERSION=\"${PROJECT_VER}\")
add_definitions(-DSTACKCHAN_DEV_FIRMWARE=1)
add_definitions(-DSTACKCHAN_DISABLE_VENDOR_FIRMWARE_OTA=1)

# Add this line to disable the specific warning
add_compile_options(-Wno-missing-field-initializers)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(stack-chan)
