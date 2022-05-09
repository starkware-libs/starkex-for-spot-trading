cmake_minimum_required (VERSION 3.22)

project(StarkEx VERSION 4.5)
include(CTest)

enable_testing()

if (NOT DEFINED CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

# Python library macro.
find_program(PYTHON "python3")

include("src/cmake_utils/cmake_rules.cmake")
include("src/starkware/cairo/lang/cairo_cmake_rules.cmake")

add_subdirectory(src)
