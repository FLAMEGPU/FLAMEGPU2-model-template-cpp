# Set the minimum cmake version to that which supports cuda natively.
# 3.10 required for cuda -std=c++14, however 3.12 fixes some device linker errors
cmake_minimum_required(VERSION VERSION 3.12 FATAL_ERROR)

# Name the project and set languages
project(flamegpu2_example CUDA CXX)

# Our core dependency is FLAMEGPU2 lib, first lets find it
include(${CMAKE_CURRENT_LIST_DIR}/cmake/flamegpu2.cmake)
# Now disable extra bells/whistles and add flamegpu2 as a dependency
set(NO_EXAMPLES ON CACHE INTERNAL "-")
set(BUILD_TESTS OFF CACHE BOOL "-")
add_subdirectory(${FLAMEGPU_ROOT})
mark_as_advanced(FORCE BUILD_TESTS)

# Option to enable/disable building the visualisation
option(VISUALISATION "Enable visualisation support" OFF)

# Include common rules.
include(${FLAMEGPU_ROOT}/cmake/common.cmake)

# Define output location of binary files
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin/${CMAKE_BUILD_TYPE}/)

# Prepare list of source files
# Can't do this automatically, as CMake wouldn't know when to regen (as CMakeLists.txt would be unchanged)
SET(ALL_SRC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cu
)

# Add the executable and set required flags for the target
add_flamegpu_executable("${PROJECT_NAME}" "${ALL_SRC}" "${FLAMEGPU_ROOT}" "${PROJECT_BINARY_DIR}" TRUE)

# Add src directory to include path
target_include_directories("${PROJECT_NAME}" PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

# Also set as (visual studio) startup project
set_property(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY VS_STARTUP_PROJECT "${PROJECT_NAME}")

# Set the default (visual studio) debugger configuration
set_target_properties("${PROJECT_NAME}" PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                                                   VS_DEBUGGER_COMMAND_ARGUMENTS "-s 100")