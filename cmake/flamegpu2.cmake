include(FetchContent)
cmake_policy(SET CMP0079 NEW)

# Allow the user to configure the version, until a stable release this should remain as master
set(FLAMEGPU2_Version "master" CACHE STRING "Git branch or tag to use")

# Always use most recent, simply recommend users that they may wish to do otherwise
FetchContent_Declare(
    flamegpu2
    GIT_REPOSITORY https://github.com/FLAMEGPU/FLAMEGPU2.git
    GIT_TAG        ${FLAMEGPU2_Version}
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
