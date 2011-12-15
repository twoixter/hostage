cmake_minimum_required(VERSION 2.8)
project(hostage)

if (APPLE)
    find_library(FOUNDATION_LIBRARY Foundation)
    find_library(OPEN_DIRECTORY_LIBRARY OpenDirectory)
    file(GLOB SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/osx/*.mm)
    set(EXTRA_LIBS ${OPEN_DIRECTORY_LIBRARY} ${FOUNDATION_LIBRARY})
endif (APPLE)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
add_executable(hostage ${SOURCES})
target_link_libraries(hostage ${EXTRA_LIBS})

install(TARGETS hostage RUNTIME DESTINATION bin)
