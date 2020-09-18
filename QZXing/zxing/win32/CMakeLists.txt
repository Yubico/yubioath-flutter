SET(SOURCES

    ${WIN32_DIR}/iconv.h
    ${WIN32_DIR}/win_iconv.c
)

if(MSVC)
    LIST(APPEND SOURCES ${WIN32_DIR}/zxing/msvc/stdint.h)
endif(MSVC)

target_sources(qzxing PRIVATE ${SOURCES})
