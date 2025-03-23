#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

#
# o3de_compile_cache_activation activates compiler caching support for O3DE builds in using MSVC 
# This currently supports ccache or sccache and can significantly speed up build times 
# by caching compilation results and reusing them when possible, but only under certain conditions:
# 1. /Z7 or embedded debug must be set
# 2. If on CMake versions > 3.30, set cmake policy CMP0141 to NEW to use CMAKE_MSVC_DEBUG_INFORMATION_FORMAT instead of /Z7
# 2. TrackFileAccess should be disabled or the cache folder has to be placed in %TMP% or %APPDATA%
# Compiler flag examples for CMake can be found here: 
# https://github.com/ccache/ccache/wiki/MS-Visual-Studio
# https://github.com/mozilla/sccache?tab=readme-ov-file#usage 
# 

# - To enable compiler caching, you need to:
#   1. Have ccache or sccache installed
#   2. Set O3DE_ENABLE_COMPILER_CACHE to "true"
#   2. Set O3DE_COMPILER_CACHE_PATH to either:
#      - Direct path to the ccache/sccache executable
#      - A partial directory containing ccache.exe or sccache.exe
#
# - The cache path and enable flag can be set either through:
#   - CMake variable: -DO3DE_COMPILER_CACHE_PATH=<path> -DO3DE_ENABLE_COMPILER_CACHE=true
#   - Environment variable: O3DE_COMPILER_CACHE_PATH=<path> O3DE_ENABLE_COMPILER_CACHE=true
#
# - CMake variables take precedence over environment variables
# - Symlinks are not supported - you must provide the direct path to the actual executable
# - This is primarily used for AR/CI processes but can also be used for local builds
#

function(o3de_compiler_cache_activation)
    message(STATUS "[COMPILER CACHE] Cache is enabled")

    # Check for custom compiler cache path, CMake variable takes precedence over environment
    if(DEFINED O3DE_COMPILER_CACHE_PATH)
        set(o3de_compiler_cache_path ${O3DE_COMPILER_CACHE_PATH})
    elseif(DEFINED ENV{O3DE_COMPILER_CACHE_PATH})
        set(o3de_compiler_cache_path $ENV{O3DE_COMPILER_CACHE_PATH})
    else()
        message(FATAL_ERROR "[COMPILER CACHE] O3DE_COMPILER_CACHE_PATH not provided. This required if compiler cache is enabled.")
    endif()

    message(STATUS "[COMPILER CACHE] Cache path set to ${o3de_compiler_cache_path}")
    
    if(NOT EXISTS "${o3de_compiler_cache_path}")
        message(FATAL_ERROR "[COMPILER CACHE] Path does not exist: ${o3de_compiler_cache_path}")
    endif()
    
    # If direct executable path
    if(NOT IS_DIRECTORY "${o3de_compiler_cache_path}")
        set(o3de_compiler_cache_exe "${o3de_compiler_cache_path}")
    else()
        # Search for executable using glob if a partial path is given
        file(GLOB_RECURSE potential_exes 
            "${o3de_compiler_cache_path}/**/ccache.exe" 
            "${o3de_compiler_cache_path}/**/sccache.exe")
        
        if(potential_exes)
            list(GET potential_exes 0 o3de_compiler_cache_exe)
        else()
            message(FATAL_ERROR "[COMPILER CACHE] Could not find ccache.exe or sccache.exe in directory: ${o3de_compiler_cache_path}")
        endif()
    endif()

    # Check for symlink
    get_filename_component(real_path "${o3de_compiler_cache_exe}" REALPATH)
    if(NOT "${real_path}" STREQUAL "${o3de_compiler_cache_exe}")
        message(FATAL_ERROR "[COMPILER CACHE] Detected symlink at ${o3de_compiler_cache_exe}. Please provide the direct path to the actual executable.")
    endif()

    message(STATUS "[COMPILER CACHE] Found at ${o3de_compiler_cache_exe}, using it for this build")

endfunction()
