# project name
project(Flow123d C)

# minimum version
cmake_minimum_required(VERSION 2.8.8)


# configurable via makefile
SET(IMAGE_TAG           "flow123d/v200" CACHE STRING "Docker image name (how it will be tagged)")
SET(IMAGE_NAME          "filename" CACHE STRING "Filename of docker image archive")
SET(DEST                "destination/folder" CACHE STRING "Destination folder, where tests and doc and images are stored")
SET(IMAGE_PATH          "${DEST}/${IMAGE_NAME}" CACHE STRING "Location of docker image")
SET(IS_WINDOWS          1 CACHE STRING "if 1 build windows install package otherwise linux package")
SET(FLOW123D_ROOT       "/opt/flow123d/flow123d" CACHE STRING "Location of the Flow123d repository root")
SET(FLOW_VERSION        "1.0.0" CACHE STRING "Dot separated")
    

message(STATUS "Packaging Flow123d version ${FLOW_VERSION}")
message(STATUS "Docker image tag name: '${IMAGE_NAME}'")
message(STATUS "Docker image location: '${IMAGE_PATH}'")
message(STATUS "Flow123d root: '${FLOW123D_ROOT}'")


# check platform
IF(IS_WINDOWS)
    message(STATUS "Creating Windows package")
    
    # docker toolbox variables
    SET(DOCKER_TOOLBOX_URL  "https://github.com/docker/toolbox/releases/download/v18.03.0-ce/DockerToolbox-18.03.0-ce.exe")
    SET(DOCKER_TOOLBOX_NAME "DockerToolbox-18.03.0-ce.exe")
    SET(DOCKER_TOOLBOX_MD5  "a5ac596f6cabddf280b4d14318e24387")
    SET(DOCKER_TOOLBOX_PATH "${CMAKE_BINARY_DIR}/pack/${DOCKER_TOOLBOX_NAME}" CACHE STRING "Location of DockerToolbox")
    
    # prepare docker toolbox
    if(NOT EXISTS ${DOCKER_TOOLBOX_PATH})
        message(STATUS "Downloading ${DOCKER_TOOLBOX_NAME}")
        file(DOWNLOAD
          ${DOCKER_TOOLBOX_URL} ${DOCKER_TOOLBOX_PATH}
          EXPECTED_HASH MD5=${DOCKER_TOOLBOX_MD5}
          SHOW_PROGRESS
        )
    endif()
    
    
    # configure script so that IMAGE_TAG is correctly set
    configure_file(src/windows/install.ps1    pack/install.ps1    @ONLY)
    configure_file(src/windows/uninstall.ps1  pack/uninstall.ps1  @ONLY)
    
    configure_file(src/linux/install.sh     pack/install.sh     @ONLY)
    configure_file(src/linux/uninstall.sh   pack/uninstall.sh   @ONLY)
    configure_file(src/linux/flow123d.sh    pack/flow123d.sh    @ONLY)
    configure_file(src/linux/fterm.sh       pack/fterm.sh       @ONLY)
    configure_file(src/linux/runtest.sh     pack/runtest.sh     @ONLY)
    
    # install docker image
    INSTALL(PROGRAMS ${IMAGE_PATH}                          DESTINATION data/
                                                            RENAME ${IMAGE_NAME})
    INSTALL(PROGRAMS ${DOCKER_TOOLBOX_PATH}                 DESTINATION data/)
    
    # install tests and docs
    INSTALL(DIRECTORY ${DEST}/htmldoc/                          DESTINATION doc/htmldoc/)
    INSTALL(FILES     ${DEST}/flow123d_${FLOW_VERSION}_doc.pdf  DESTINATION doc/)
    
    INSTALL(DIRECTORY ${DEST}/tests/                        DESTINATION tests/)
    INSTALL(PROGRAMS  ${CMAKE_BINARY_DIR}/pack/runtest.sh   DESTINATION tests/)
    
    # install and uninstall scripts to root
    INSTALL(PROGRAMS src/windows/install.bat                DESTINATION ./)
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/install.sh    DESTINATION ./)
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/uninstall.sh  DESTINATION ./)
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/install.ps1   DESTINATION ./)
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/uninstall.ps1 DESTINATION ./)
    # add shortcuts to bin
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/fterm.sh      DESTINATION bin/)
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/flow123d.sh   DESTINATION bin/)
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/runtest.sh    DESTINATION bin/)
    INSTALL(PROGRAMS src/windows/create_shortcuts.sh        DESTINATION bin/)
    INSTALL(PROGRAMS src/windows/mounts.sh                  DESTINATION bin/)
    
    # install configure
    INSTALL(PROGRAMS ${FLOW123D_ROOT}/bin/fterm             DESTINATION bin
                                                            RENAME configure)
    INSTALL(DIRECTORY ${FLOW123D_ROOT}/config/docker/customize/.
                                                            DESTINATION config/docker/customize)
    
    
    set(CPACK_PACKAGE_FILE_NAME "flow123d_${FLOW_VERSION}")
    SET(CPACK_GENERATOR "ZIP")
ELSE()
    message(STATUS "Creating Linux package")
    
    # configure script so that IMAGE_TAG is correctly set
    configure_file(src/linux/install.sh     pack/install.sh     @ONLY)
    configure_file(src/linux/uninstall.sh   pack/uninstall.sh   @ONLY)
    configure_file(src/linux/flow123d.sh    pack/flow123d.sh    @ONLY)
    configure_file(src/linux/fterm.sh       pack/fterm.sh       @ONLY)
    configure_file(src/linux/runtest.sh     pack/runtest.sh     @ONLY)
    

    # install docker image
    INSTALL(PROGRAMS ${IMAGE_PATH}                            DESTINATION data/
                                                              RENAME ${IMAGE_NAME})
    
    # install tests and docs
    INSTALL(DIRECTORY ${DEST}/htmldoc/                          DESTINATION doc/htmldoc/)
    INSTALL(FILES     ${DEST}/flow123d_${FLOW_VERSION}_doc.pdf  DESTINATION doc/)
    
    INSTALL(DIRECTORY ${DEST}/tests/                        DESTINATION tests/)
    INSTALL(PROGRAMS  ${CMAKE_BINARY_DIR}/pack/runtest.sh   DESTINATION tests/)
    
    # install and uninstall scripts to root
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/install.sh    DESTINATION ./)
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/uninstall.sh  DESTINATION ./)
    # add shortcuts to bin
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/fterm.sh      DESTINATION bin/)
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/flow123d.sh   DESTINATION bin/)
    INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/pack/runtest.sh    DESTINATION bin/)
    
    # install configure
    INSTALL(PROGRAMS ${FLOW123D_ROOT}/bin/fterm             DESTINATION bin
                                                            RENAME configure)
    INSTALL(DIRECTORY ${FLOW123D_ROOT}/config/docker/customize/.
                                                            DESTINATION config/docker/customize)
    
    
    SET(CPACK_PACKAGE_FILE_NAME "flow123d_${FLOW_VERSION}")
    SET(CPACK_GENERATOR "TGZ")
ENDIF()

# create package rule
include(CPack)
