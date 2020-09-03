cmake_minimum_required(VERSION 3.2)
project(QZXing)

find_package(Qt5 COMPONENTS Core REQUIRED)
find_package(Qt5 COMPONENTS Gui REQUIRED)
find_package(Qt5 COMPONENTS Multimedia )
find_package(Qt5 REQUIRED Svg Quick QuickControls2)

SET(BIGINT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/zxing/bigint)
SET(WIN32_DIR  ${CMAKE_CURRENT_SOURCE_DIR}/zxing/win32/zxing)
SET(ZXING_DIR  ${CMAKE_CURRENT_SOURCE_DIR}/zxing/zxing)

set(CMAKE_AUTOMOC ON)
set(CMAKE_WARN_ON)

set(SOURCES

    CameraImageWrapper.cpp
    CameraImageWrapper.h
    ImageHandler.cpp
    ImageHandler.h
    QZXing.cpp
    QZXing.h
    QZXing_global.h
    )

if(QZXING_MULTIMEDIA)

    LIST(APPEND SOURCES QZXingFilter.cpp QZXingFilter.h)
    add_definitions(-DQZXING_MULTIMEDIA)

    SET(QZXING_USE_QML ON)

endif(QZXING_MULTIMEDIA)

if(QZXING_USE_QML)
    LIST(APPEND SOURCES QZXingImageProvider.cpp QZXingImageProvider.h)
    add_definitions(-DQZXING_QML)
endif(QZXING_USE_QML)

add_library(qzxing "" ${SOURCES})

if(WIN32)
    add_subdirectory(zxing/win32)
    if(MSVC)
        add_definitions(-D__STDC_LIMIT_MACROS)
    endif(MSVC)

    add_definitions(-DNO_ICONV)
endif(WIN32)

if(VS_WINRT_COMPONENT)
    add_definitions(-DNO_ICONV)
endif(VS_WINRT_COMPONENT)

add_subdirectory(zxing/bigint)

add_subdirectory(zxing/zxing)

target_link_libraries(qzxing Qt5::Core Qt5::Gui)

if(QZXING_MULTIMEDIA)
    target_link_libraries(qzxing Qt5::Multimedia)
endif(QZXING_MULTIMEDIA)

if(QZXING_USE_QML)
    target_link_libraries(qzxing
        Qt5::Svg
        Qt5::Quick
        Qt5::QuickControls2)
endif(QZXING_USE_QML)

# Change Global Definitions depending on how you want to use the library
target_compile_definitions(qzxing PUBLIC DISABLE_LIBRARY_FEATURES)

# Target includes
target_include_directories(qzxing
  PRIVATE
        .
        zxing
        zxing/win32/zxing
        zxing/zxing
        zxing/bigint
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

