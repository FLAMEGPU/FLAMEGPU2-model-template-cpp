include(FetchContent)
cmake_policy(SET CMP0079 NEW)

# If a FLAMEGPU_VERSION has not been defined, set it to the default option.
if(NOT DEFINED FLAMEGPU_VERSION OR FLAMEGPU_VERSION STREQUAL "")
    set(FLAMEGPU_VERSION "master" CACHE STRING "Git branch or tag to use")
endif()

# Allow users to switch to forks with relative ease.

if(NOT DEFINED FLAMEGPU_REPOSITORY OR FLAMEGPU_REPOSITORY STREQUAL "")
    set(FLAMEGPU_REPOSITORY "https://github.com/FLAMEGPU/FLAMEGPU2.git" CACHE STRING "Remote Git Repository for FLAME GPU 2+")
endif()

# Always use most recent, simply recommend users that they may wish to do otherwise
FetchContent_Declare(
    flamegpu2
    GIT_REPOSITORY ${FLAMEGPU_REPOSITORY}
    GIT_TAG        ${FLAMEGPU_VERSION}
    GIT_SHALLOW    1
    GIT_PROGRESS   ON
    # UPDATE_DISCONNECTED   ON
)

# Fetch and populate the content if required.
FetchContent_GetProperties(flamegpu2)
if(NOT flamegpu2_POPULATED)
    FetchContent_Populate(flamegpu2)   

    # Now disable extra bells/whistles and add flamegpu2 as a dependency
    set(NO_EXAMPLES ON CACHE INTERNAL "-")
    set(BUILD_TESTS OFF CACHE BOOL "-")
    mark_as_advanced(FORCE BUILD_TESTS)

    # Add the subdirectory
    add_subdirectory(${flamegpu2_SOURCE_DIR} ${flamegpu2_BINARY_DIR})

    # Add flamegpu2' expected location to the prefix path.
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${flamegpu2_SOURCE_DIR}/cmake")
endif()

message(STATUS "Found FLAMEGPU2 ${flamegpu2_SOURCE_DIR}")
set(FLAMEGPU_ROOT ${flamegpu2_SOURCE_DIR})
