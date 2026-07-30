if(MSVC)
    add_compile_options(-EHsc)
    add_definitions(-D_HAS_EXCEPTIONS=1)
endif()

otr_module(executable EXECUTABLE BIN)

set_target_properties(opentrack-executable PROPERTIES
    SUFFIX "${opentrack-binary-suffix}"
    OUTPUT_NAME "opentrack"
    PREFIX ""
)

set_source_files_properties(resources.rc OBJECT_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/opentrack.ico")

if(APPLE)
    set_source_files_properties(appnap_mac.mm PROPERTIES COMPILE_FLAGS "-fno-objc-arc")
    target_sources(${self} PRIVATE appnap_mac.mm)
endif()

target_link_libraries(${self} PRIVATE
    opentrack-user-interface
    opentrack-input
    opentrack-logic
    opentrack-migration
    opentrack-spline
    opentrack-pose-widget
    opentrack-version
)

if(APPLE)
    target_link_libraries(${self} PRIVATE "-framework Foundation")
endif()

# A desktop entry and icon so the installed application shows up in menus, and
# so AppImage and the distro package generators have the metadata they require.
if(UNIX AND NOT APPLE)
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/opentrack.desktop"
            DESTINATION "share/applications")
    install(FILES "${CMAKE_SOURCE_DIR}/gui/images/opentrack.png"
            DESTINATION "share/icons/hicolor/256x256/apps")
endif()
