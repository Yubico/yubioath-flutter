SET(SOURCES
     ${BIGINT_DIR}/BigInteger.hh
     ${BIGINT_DIR}/BigInteger.cc
     ${BIGINT_DIR}/BigIntegerAlgorithms.hh
     ${BIGINT_DIR}/BigIntegerAlgorithms.cc
     ${BIGINT_DIR}/BigIntegerLibrary.hh
     ${BIGINT_DIR}/BigIntegerUtils.hh
     ${BIGINT_DIR}/BigIntegerUtils.cc
     ${BIGINT_DIR}/BigUnsigned.hh
     ${BIGINT_DIR}/BigUnsigned.cc
     ${BIGINT_DIR}/BigUnsignedInABase.hh
     ${BIGINT_DIR}/BigUnsignedInABase.cc
     ${BIGINT_DIR}/NumberlikeArray.hh
    )

target_sources(qzxing PRIVATE ${SOURCES})
