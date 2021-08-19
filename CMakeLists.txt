# Set the minimum cmake version requires by this project.
cmake_minimum_required(VERSION VERSION 3.15 FATAL_ERROR)

# Name the project and set languages
project(flamegpu2_example CUDA CXX)

# Option to enable/disable building the visualisation
option(VISUALISATION "Enable visualisation support" OFF)

# Optionaly set the version of flamegpu which should be used.
# Use a branch name such as `master`, or a tagged version such as `v2.0.0-alpha` 
set(FLAMEGPU_VERSION "master" CACHE STRING "Git branch or tag to use")

# Our core dependency is FLAMEGPU2 lib, first lets find it
include(${CMAKE_CURRENT_LIST_DIR}/cmake/flamegpu2.cmake)

# Include common rules from the main repositorys CMake
include(${FLAMEGPU_ROOT}/cmake/common.cmake)

# Manually list all of the files which require building or influence re-building.
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
set_target_properties("${PROJECT_NAME}" PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" VS_DEBUGGER_COMMAND_ARGUMENTS "-s 10")