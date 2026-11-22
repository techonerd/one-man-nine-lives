# Window Perch: KWin window decoration for the One Man Nine Lives suite.
# A fork of the Breeze window decoration (KDE Plasma 6.7.4), see README.md for attribution.
# SPDX-License-Identifier: GPL-3.0-or-later
cmake_minimum_required(VERSION 3.16)
project(windowperch VERSION 0.1.0)

set(QT_MIN_VERSION "6.10.0")
set(KF6_MIN_VERSION "6.26.0")
set(QT_MAJOR_VERSION 6)
set(KDE_COMPILERSETTINGS_LEVEL "5.82")   # same as Breeze: keeps Qt keywords like emit
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})

include(KDEInstallDirs6)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED CONFIG COMPONENTS Core Gui Widgets DBus)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    CoreAddons ColorScheme Config GuiAddons I18n IconThemes KCMUtils WindowSystem)
find_package(KDecoration3 REQUIRED)

# The sources expect to be built from a tree whose root holds kdecoration/ and libbreezecommon/
set(WP_SRC ${CMAKE_CURRENT_SOURCE_DIR}/src)
add_subdirectory(src/libbreezecommon libbreezecommon6)
add_subdirectory(src/kdecoration kdecoration)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
