include(FetchContent)
include(FindPackageHandleStandardArgs)
cmake_policy(SET CMP0079 NEW)

# Find or fetch FLAME GPU 2
# If FLAMEGPU_ROOT is set, check it exists and use it. Otherwise error.
# Otherwise, fetch FLAMEGPU/FLAMEGPU2 from github, and use it in the _deps directory.  

# If a FLAMEGPU_VERSION has not been defined, set it to the default option.
if(NOT DEFINED FLAMEGPU_VERSION OR FLAMEGPU_VERSION STREQUAL "")
    set(FLAMEGPU_VERSION "master" CACHE STRING "Git branch or tag to use")
endif()

# Allow users to switch to forks with relative ease.
if(NOT DEFINED FLAMEGPU_REPOSITORY OR FLAMEGPU_REPOSITORY STREQUAL "")
    set(FLAMEGPU_REPOSITORY "https://github.com/FLAMEGPU/FLAMEGPU2.git" CACHE STRING "Remote Git Repository for FLAME GPU 2+")
endif()

# If FLAMEGPU_ROOT is set, and it contains flame gpu do nothing. Otherwise download the appropraite version
if(DEFINED FLAMEGPU_ROOT AND NOT FLAMEGPU_VERSION STREQUAL "")
    #  Look for a file we expect to always exist. version.h is dynamically created so cannot be relied upon
    find_path(FLAMEGPU_ROOT include/flamegpu/flamegpu.h
        HINTS
            $ENV{FLAMEGPU_ROOT}
            ${FLAMEGPU_ROOT}
        NO_DEFAULT_PATH
        NO_PACKAGE_ROOT_PATH
        NO_CMAKE_PATH
        NO_CMAKE_ENVIRONMENT_PATH
        NO_SYSTEM_ENVIRONMENT_PATH
        NO_CMAKE_SYSTEM_PATH
        DOC "Path to clone of FLAMEPU/FLAMEGPU2 source repository"
    )
    # Easy way to error if it could not be found?
    find_package_handle_standard_args(FLAMEGPU2 "Failed to find FLAMEGPU root" FLAMEGPU_ROOT)

    # disable extra bells/whistles and add flamegpu2 as a dependency
    set(NO_EXAMPLES ON CACHE INTERNAL "-")
    set(BUILD_TESTS OFF CACHE BOOL "-")
    mark_as_advanced(FORCE BUILD_TESTS)

    # Add the subdirectory
    add_subdirectory(${FLAMEGPU_ROOT} "FLAMEGPU")

    # Add flamegpu2' expected location to the prefix path.
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${FLAMEGPU_ROOT}/cmake")
else()
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
    set(FLAMEGPU_ROOT ${flamegpu2_SOURCE_DIR})
endif()
message(STATUS "Using FLAMEGPU2 ${FLAMEGPU_ROOT}")
