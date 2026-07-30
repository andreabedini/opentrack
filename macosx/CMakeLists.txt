if(APPLE)
    # macdeployqt ships with Qt but is not on PATH -- with vcpkg it lands under
    # <installed>/tools/Qt6/bin. Resolve it here rather than making the bundle
    # script guess; it previously died with "macdeployqt: command not found".
    if(TARGET Qt6::macdeployqt)
        get_target_property(otr_macdeployqt Qt6::macdeployqt IMPORTED_LOCATION)
    endif()
    if(NOT otr_macdeployqt)
        find_program(otr_macdeployqt
            NAMES macdeployqt6 macdeployqt
            HINTS "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}"
                  "${QT6_INSTALL_PREFIX}/bin"
            REQUIRED)
    endif()
    message(STATUS "macdeployqt: ${otr_macdeployqt}")

    otr_escape_string(srcdir "${CMAKE_SOURCE_DIR}")
    otr_escape_string(instdir "${CMAKE_INSTALL_PREFIX}")
    otr_escape_string(commit "${OPENTRACK_COMMIT}")
    otr_escape_string(macdeployqt "${otr_macdeployqt}")

    # COMMAND_ERROR_IS_FATAL matters here: without it execute_process() discards
    # the exit status, so a failing bundle script left a half-assembled .app
    # behind and the install still reported success.
    install(CODE "
       execute_process(COMMAND /bin/sh \"${srcdir}/macosx/make-app-bundle.sh\"
                                        \"${srcdir}/macosx\"
                                        \"${instdir}\"
                                        \"${commit}\"
                                        \"${macdeployqt}\"
                       COMMAND_ERROR_IS_FATAL ANY)
    ")
endif()
