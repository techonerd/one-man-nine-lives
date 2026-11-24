# SPDX-License-Identifier: GPL-3.0-or-later
cmake_minimum_required(VERSION 3.16)
project(laptime-idle VERSION 0.1.0 LANGUAGES C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(WAYLAND REQUIRED IMPORTED_TARGET wayland-client)
find_program(WAYLAND_SCANNER wayland-scanner REQUIRED)

set(XML ${CMAKE_CURRENT_SOURCE_DIR}/ext-idle-notify-v1.xml)
set(GEN_H ${CMAKE_CURRENT_BINARY_DIR}/ext-idle-notify-v1-client-protocol.h)
set(GEN_C ${CMAKE_CURRENT_BINARY_DIR}/ext-idle-notify-v1-protocol.c)
add_custom_command(OUTPUT ${GEN_H} COMMAND ${WAYLAND_SCANNER} client-header ${XML} ${GEN_H} DEPENDS ${XML})
add_custom_command(OUTPUT ${GEN_C} COMMAND ${WAYLAND_SCANNER} private-code ${XML} ${GEN_C} DEPENDS ${XML})

add_executable(laptime-idle laptime-idle.c ${GEN_C} ${GEN_H})
target_include_directories(laptime-idle PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(laptime-idle PRIVATE PkgConfig::WAYLAND)
target_compile_options(laptime-idle PRIVATE -Wall -Wextra -O2)

include(GNUInstallDirs)
install(TARGETS laptime-idle RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
