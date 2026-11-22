add_definitions(-DTRANSLATION_DOMAIN="breeze_kwin_deco")

################# includes #################
include_directories(${WP_SRC}/libbreezecommon)
include_directories(${CMAKE_BINARY_DIR}/libbreezecommon6)

################# newt target #################
### plugin classes
set(windowperchdecoration_SRCS
    breezebutton.cpp
    breezedecoration.cpp
    breezesettingsprovider.cpp
    breezeexceptionlist.cpp
)

### build library
kconfig_add_kcfg_files(windowperchdecoration_SRCS breezesettings.kcfgc)
add_library(windowperchdecoration MODULE
    ${windowperchdecoration_SRCS}
    ${windowperchdecoration_config_PART_FORMS_HEADERS})

set_target_properties(windowperchdecoration PROPERTIES
    OUTPUT_NAME com.github.techonerd.windowperch
)

target_link_libraries(windowperchdecoration
    PRIVATE
        breezecommon6
        Qt6::DBus
        KF6::CoreAddons
        KF6::ConfigGui
        KF6::GuiAddons
        KF6::I18n
        KF6::IconThemes
        KDecoration3::KDecoration
        KF6::ColorScheme
)

install(TARGETS windowperchdecoration DESTINATION ${KDE_INSTALL_PLUGINDIR}/${KDECORATION_PLUGIN_DIR})

add_subdirectory(config)

