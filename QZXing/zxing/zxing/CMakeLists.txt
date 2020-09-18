SET(SOURCES

    ${ZXING_DIR}/BarcodeFormat.cpp
    ${ZXING_DIR}/BarcodeFormat.h
    ${ZXING_DIR}/Binarizer.cpp
    ${ZXING_DIR}/Binarizer.h
    ${ZXING_DIR}/BinaryBitmap.cpp
    ${ZXING_DIR}/BinaryBitmap.h
    ${ZXING_DIR}/ChecksumException.cpp
    ${ZXING_DIR}/ChecksumException.h
    ${ZXING_DIR}/DecodeHints.cpp
    ${ZXING_DIR}/DecodeHints.h
    ${ZXING_DIR}/EncodeHint.cpp
    ${ZXING_DIR}/EncodeHint.h
    ${ZXING_DIR}/Exception.cpp
    ${ZXING_DIR}/Exception.h
    ${ZXING_DIR}/FormatException.cpp
    ${ZXING_DIR}/FormatException.h
    ${ZXING_DIR}/IllegalStateException.cpp
    ${ZXING_DIR}/IllegalStateException.h
    ${ZXING_DIR}/InvertedLuminanceSource.cpp
    ${ZXING_DIR}/InvertedLuminanceSource.h
    ${ZXING_DIR}/LuminanceSource.cpp
    ${ZXING_DIR}/LuminanceSource.h
    ${ZXING_DIR}/MultiFormatReader.cpp
    ${ZXING_DIR}/MultiFormatReader.h
    ${ZXING_DIR}/NotFoundException.h
    ${ZXING_DIR}/NotFoundException.cpp
    ${ZXING_DIR}/Reader.cpp
    ${ZXING_DIR}/Reader.h
    ${ZXING_DIR}/ReaderException.h
    ${ZXING_DIR}/ReaderException.cpp
    ${ZXING_DIR}/Result.cpp
    ${ZXING_DIR}/Result.h
    ${ZXING_DIR}/ResultMetadata.cpp
    ${ZXING_DIR}/ResultMetadata.h
    ${ZXING_DIR}/ResultIO.cpp
    ${ZXING_DIR}/ResultPoint.cpp
    ${ZXING_DIR}/ResultPoint.h
    ${ZXING_DIR}/ResultPointCallback.cpp
    ${ZXING_DIR}/ResultPointCallback.h
    ${ZXING_DIR}/UnsupportedEncodingException.h
    ${ZXING_DIR}/WriterException.h
    ${ZXING_DIR}/WriterException.cpp
    ${ZXING_DIR}/ZXing.h

    )

SET(AZTEC_DIR

    ${ZXING_DIR}/aztec/AztecDetectorResult.cpp
    ${ZXING_DIR}/aztec/AztecDetectorResult.h
    ${ZXING_DIR}/aztec/AztecReader.cpp
    ${ZXING_DIR}/aztec/AztecReader.h
    ${ZXING_DIR}/aztec/decoder/AztecDecoder.cpp
    ${ZXING_DIR}/aztec/decoder/Decoder.h
    ${ZXING_DIR}/aztec/detector/AztecDetector.cpp
    ${ZXING_DIR}/aztec/detector/Detector.h

    )

SET(COMMON_DIR

    ${ZXING_DIR}/common/Array.h
    ${ZXING_DIR}/common/BitArray.cpp
    ${ZXING_DIR}/common/BitArray.h
    ${ZXING_DIR}/common/BitArrayIO.cpp
    ${ZXING_DIR}/common/BitMatrix.cpp
    ${ZXING_DIR}/common/BitMatrix.h
    ${ZXING_DIR}/common/BitSource.cpp
    ${ZXING_DIR}/common/BitSource.h
    ${ZXING_DIR}/common/CharacterSetECI.cpp
    ${ZXING_DIR}/common/CharacterSetECI.h
    ${ZXING_DIR}/common/Counted.h
    ${ZXING_DIR}/common/Counted.cpp
    ${ZXING_DIR}/common/DecoderResult.cpp
    ${ZXING_DIR}/common/DecoderResult.h
    ${ZXING_DIR}/common/DetectorResult.cpp
    ${ZXING_DIR}/common/DetectorResult.h
    ${ZXING_DIR}/common/GlobalHistogramBinarizer.cpp
    ${ZXING_DIR}/common/GlobalHistogramBinarizer.h
    ${ZXING_DIR}/common/GreyscaleLuminanceSource.cpp
    ${ZXING_DIR}/common/GreyscaleLuminanceSource.h
    ${ZXING_DIR}/common/GreyscaleRotatedLuminanceSource.cpp
    ${ZXING_DIR}/common/GreyscaleRotatedLuminanceSource.h
    ${ZXING_DIR}/common/GridSampler.cpp
    ${ZXING_DIR}/common/GridSampler.h
    ${ZXING_DIR}/common/HybridBinarizer.cpp
    ${ZXING_DIR}/common/HybridBinarizer.h
    ${ZXING_DIR}/common/IllegalArgumentException.cpp
    ${ZXING_DIR}/common/IllegalArgumentException.h
    ${ZXING_DIR}/common/PerspectiveTransform.cpp
    ${ZXING_DIR}/common/PerspectiveTransform.h
    ${ZXING_DIR}/common/Point.h
    ${ZXING_DIR}/common/Str.cpp
    ${ZXING_DIR}/common/Str.h
    ${ZXING_DIR}/common/StringUtils.cpp
    ${ZXING_DIR}/common/StringUtils.h
    ${ZXING_DIR}/common/Types.h

    ${ZXING_DIR}/common/detector/JavaMath.h
    ${ZXING_DIR}/common/detector/MathUtils.h
    ${ZXING_DIR}/common/detector/MonochromeRectangleDetector.cpp
    ${ZXING_DIR}/common/detector/MonochromeRectangleDetector.h
    ${ZXING_DIR}/common/detector/WhiteRectangleDetector.cpp
    ${ZXING_DIR}/common/detector/WhiteRectangleDetector.h

    ${ZXING_DIR}/common/reedsolomon/GenericGF.cpp
    ${ZXING_DIR}/common/reedsolomon/GenericGF.h
    ${ZXING_DIR}/common/reedsolomon/GenericGFPoly.cpp
    ${ZXING_DIR}/common/reedsolomon/GenericGFPoly.h
    ${ZXING_DIR}/common/reedsolomon/ReedSolomonDecoder.cpp
    ${ZXING_DIR}/common/reedsolomon/ReedSolomonDecoder.h
    ${ZXING_DIR}/common/reedsolomon/ReedSolomonEncoder.cpp
    ${ZXING_DIR}/common/reedsolomon/ReedSolomonEncoder.h
    ${ZXING_DIR}/common/reedsolomon/ReedSolomonException.cpp
    ${ZXING_DIR}/common/reedsolomon/ReedSolomonException.h

    )

SET(DATAMATRIX_DIR

    ${ZXING_DIR}/datamatrix/DataMatrixReader.cpp
    ${ZXING_DIR}/datamatrix/DataMatrixReader.h
    ${ZXING_DIR}/datamatrix/DataMatrixVersion.cpp
    ${ZXING_DIR}/datamatrix/Version.h

    ${ZXING_DIR}/datamatrix/decoder/BitMatrixParser.h
    ${ZXING_DIR}/datamatrix/decoder/DataBlock.h
    ${ZXING_DIR}/datamatrix/decoder/DataMatrixBitMatrixParser.cpp
    ${ZXING_DIR}/datamatrix/decoder/DataMatrixDataBlock.cpp
    ${ZXING_DIR}/datamatrix/decoder/DataMatrixDecodedBitStreamParser.cpp
    ${ZXING_DIR}/datamatrix/decoder/DataMatrixDecoder.cpp
    ${ZXING_DIR}/datamatrix/decoder/DecodedBitStreamParser.h
    ${ZXING_DIR}/datamatrix/decoder/Decoder.h

    ${ZXING_DIR}/datamatrix/detector/CornerPoint.h
    ${ZXING_DIR}/datamatrix/detector/DataMatrixCornerPoint.cpp
    ${ZXING_DIR}/datamatrix/detector/DataMatrixDetector.cpp
    ${ZXING_DIR}/datamatrix/detector/DataMatrixDetectorException.cpp
    ${ZXING_DIR}/datamatrix/detector/Detector.h
    ${ZXING_DIR}/datamatrix/detector/DetectorException.h

    )

SET(MULTI_DIR

    ${ZXING_DIR}/multi/ByQuadrantReader.cpp
    ${ZXING_DIR}/multi/ByQuadrantReader.h
    ${ZXING_DIR}/multi/GenericMultipleBarcodeReader.cpp
    ${ZXING_DIR}/multi/GenericMultipleBarcodeReader.h
    ${ZXING_DIR}/multi/MultipleBarcodeReader.cpp
    ${ZXING_DIR}/multi/MultipleBarcodeReader.h

    ${ZXING_DIR}/multi/qrcode/QRCodeMultiReader.cpp
    ${ZXING_DIR}/multi/qrcode/QRCodeMultiReader.h

    ${ZXING_DIR}/multi/qrcode/detector/MultiDetector.cpp
    ${ZXING_DIR}/multi/qrcode/detector/MultiDetector.h
    ${ZXING_DIR}/multi/qrcode/detector/MultiFinderPatternFinder.cpp
    ${ZXING_DIR}/multi/qrcode/detector/MultiFinderPatternFinder.h

    )

SET(ONED_DIR

    ${ZXING_DIR}/oned/UPCEReader.h
    ${ZXING_DIR}/oned/UPCEANReader.h
    ${ZXING_DIR}/oned/UPCEANExtensionSupport.h
    ${ZXING_DIR}/oned/UPCEANExtension2Support.h
    ${ZXING_DIR}/oned/UPCEANExtension5Support.h
    ${ZXING_DIR}/oned/UPCAReader.h
    ${ZXING_DIR}/oned/OneDResultPoint.h
    ${ZXING_DIR}/oned/OneDReader.h
    ${ZXING_DIR}/oned/MultiFormatUPCEANReader.h
    ${ZXING_DIR}/oned/MultiFormatOneDReader.h
    ${ZXING_DIR}/oned/ITFReader.h
    ${ZXING_DIR}/oned/EAN13Reader.h
    ${ZXING_DIR}/oned/EAN8Reader.h
    ${ZXING_DIR}/oned/EANManufacturerOrgSupport.h
    ${ZXING_DIR}/oned/Code128Reader.h
    ${ZXING_DIR}/oned/Code39Reader.h
    ${ZXING_DIR}/oned/CodaBarReader.h
    ${ZXING_DIR}/oned/Code93Reader.h
    ${ZXING_DIR}/oned/rss/AbstractRSSReader.h
    ${ZXING_DIR}/oned/rss/DataCharacter.h
    ${ZXING_DIR}/oned/rss/FinderPattern.h
    ${ZXING_DIR}/oned/rss/Pair.h
    ${ZXING_DIR}/oned/rss/RSS14Reader.h
    ${ZXING_DIR}/oned/rss/RSSUtils.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AbstractExpandedDecoder.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI013103decoder.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01320xDecoder.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01392xDecoder.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01393xDecoder.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI013x0x1xDecoder.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI013x0xDecoder.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01AndOtherAIs.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01decoder.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01weightDecoder.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/AnyAIDecoder.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/BlockParsedResult.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/CurrentParsingState.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/DecodedChar.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/DecodedInformation.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/DecodedNumeric.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/DecodedObject.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/FieldParser.h
    ${ZXING_DIR}/oned/rss/expanded/decoders/GeneralAppIdDecoder.h
    ${ZXING_DIR}/oned/rss/expanded/BitArrayBuilder.h
    ${ZXING_DIR}/oned/rss/expanded/ExpandedPair.h
    ${ZXING_DIR}/oned/rss/expanded/ExpandedRow.h
    ${ZXING_DIR}/oned/rss/expanded/RSSExpandedReader.h

    ${ZXING_DIR}/oned/UPCEReader.cpp
    ${ZXING_DIR}/oned/UPCEANReader.cpp
    ${ZXING_DIR}/oned/UPCEANExtensionSupport.cpp
    ${ZXING_DIR}/oned/UPCEANExtension2Support.cpp
    ${ZXING_DIR}/oned/UPCEANExtension5Support.cpp
    ${ZXING_DIR}/oned/UPCAReader.cpp
    ${ZXING_DIR}/oned/OneDResultPoint.cpp
    ${ZXING_DIR}/oned/OneDReader.cpp
    ${ZXING_DIR}/oned/MultiFormatUPCEANReader.cpp
    ${ZXING_DIR}/oned/MultiFormatOneDReader.cpp
    ${ZXING_DIR}/oned/ITFReader.cpp
    ${ZXING_DIR}/oned/EAN13Reader.cpp
    ${ZXING_DIR}/oned/EAN8Reader.cpp
    ${ZXING_DIR}/oned/EANManufacturerOrgSupport.cpp
    ${ZXING_DIR}/oned/Code128Reader.cpp
    ${ZXING_DIR}/oned/Code39Reader.cpp
    ${ZXING_DIR}/oned/CodaBarReader.cpp
    ${ZXING_DIR}/oned/Code93Reader.cpp
    ${ZXING_DIR}/oned/rss/AbstractRSSReader.cpp
    ${ZXING_DIR}/oned/rss/DataCharacter.cpp
    ${ZXING_DIR}/oned/rss/FinderPattern.cpp
    ${ZXING_DIR}/oned/rss/Pair.cpp
    ${ZXING_DIR}/oned/rss/RSS14Reader.cpp
    ${ZXING_DIR}/oned/rss/RSSUtils.cpp
    ${ZXING_DIR}/oned/rss/expanded/BitArrayBuilder.cpp
    ${ZXING_DIR}/oned/rss/expanded/ExpandedPair.cpp
    ${ZXING_DIR}/oned/rss/expanded/ExpandedRow.cpp
    ${ZXING_DIR}/oned/rss/expanded/RSSExpandedReader.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AbstractExpandedDecoder.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01AndOtherAIs.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01decoder.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01weightDecoder.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI013x0x1xDecoder.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI013x0xDecoder.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01320xDecoder.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01392xDecoder.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI01393xDecoder.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AI013103decoder.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/AnyAIDecoder.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/BlockParsedResult.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/CurrentParsingState.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/DecodedChar.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/DecodedInformation.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/DecodedNumeric.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/DecodedObject.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/FieldParser.cpp
    ${ZXING_DIR}/oned/rss/expanded/decoders/GeneralAppIdDecoder.cpp


    )

SET(PDF417_DIR

    ${ZXING_DIR}/pdf417/PDF417Reader.cpp
    ${ZXING_DIR}/pdf417/PDF417Reader.h

    ${ZXING_DIR}/pdf417/decoder/BitMatrixParser.h
    ${ZXING_DIR}/pdf417/decoder/DecodedBitStreamParser.h
    ${ZXING_DIR}/pdf417/decoder/Decoder.h
    ${ZXING_DIR}/pdf417/decoder/PDF417BitMatrixParser.cpp
    ${ZXING_DIR}/pdf417/decoder/PDF417DecodedBitStreamParser.cpp
    ${ZXING_DIR}/pdf417/decoder/PDF417Decoder.cpp

    ${ZXING_DIR}/pdf417/decoder/ec/ErrorCorrection.cpp
    ${ZXING_DIR}/pdf417/decoder/ec/ErrorCorrection.h
    ${ZXING_DIR}/pdf417/decoder/ec/ModulusGF.cpp
    ${ZXING_DIR}/pdf417/decoder/ec/ModulusGF.h
    ${ZXING_DIR}/pdf417/decoder/ec/ModulusPoly.cpp
    ${ZXING_DIR}/pdf417/decoder/ec/ModulusPoly.h

    ${ZXING_DIR}/pdf417/detector/Detector.h
    ${ZXING_DIR}/pdf417/detector/LinesSampler.cpp
    ${ZXING_DIR}/pdf417/detector/LinesSampler.h
    ${ZXING_DIR}/pdf417/detector/PDF417Detector.cpp

    )

SET(QRCODE_DIR

    ${ZXING_DIR}/qrcode/ErrorCorrectionLevel.h
    ${ZXING_DIR}/qrcode/FormatInformation.h
    ${ZXING_DIR}/qrcode/QRCodeReader.cpp
    ${ZXING_DIR}/qrcode/QRCodeReader.h
    ${ZXING_DIR}/qrcode/QRErrorCorrectionLevel.cpp
    ${ZXING_DIR}/qrcode/QRFormatInformation.cpp
    ${ZXING_DIR}/qrcode/QRVersion.cpp
    ${ZXING_DIR}/qrcode/Version.h

    ${ZXING_DIR}/qrcode/decoder/BitMatrixParser.h
    ${ZXING_DIR}/qrcode/decoder/DataBlock.h
    ${ZXING_DIR}/qrcode/decoder/DataMask.h
    ${ZXING_DIR}/qrcode/decoder/DecodedBitStreamParser.h
    ${ZXING_DIR}/qrcode/decoder/Decoder.h
    ${ZXING_DIR}/qrcode/decoder/Mode.h
    ${ZXING_DIR}/qrcode/decoder/QRBitMatrixParser.cpp
    ${ZXING_DIR}/qrcode/decoder/QRDataBlock.cpp
    ${ZXING_DIR}/qrcode/decoder/QRDataMask.cpp
    ${ZXING_DIR}/qrcode/decoder/QRDecodedBitStreamParser.cpp
    ${ZXING_DIR}/qrcode/decoder/QRDecoder.cpp
    ${ZXING_DIR}/qrcode/decoder/QRMode.cpp

    ${ZXING_DIR}/qrcode/detector/AlignmentPattern.h
    ${ZXING_DIR}/qrcode/detector/AlignmentPatternFinder.h
    ${ZXING_DIR}/qrcode/detector/Detector.h
    ${ZXING_DIR}/qrcode/detector/FinderPattern.h
    ${ZXING_DIR}/qrcode/detector/FinderPatternFinder.h
    ${ZXING_DIR}/qrcode/detector/FinderPatternInfo.h
    ${ZXING_DIR}/qrcode/detector/QRAlignmentPattern.cpp
    ${ZXING_DIR}/qrcode/detector/QRAlignmentPatternFinder.cpp
    ${ZXING_DIR}/qrcode/detector/QRDetector.cpp
    ${ZXING_DIR}/qrcode/detector/QRFinderPattern.cpp
    ${ZXING_DIR}/qrcode/detector/QRFinderPatternFinder.cpp
    ${ZXING_DIR}/qrcode/detector/QRFinderPatternInfo.cpp

    ${ZXING_DIR}/qrcode/encoder/BlockPair.h
    ${ZXING_DIR}/qrcode/encoder/ByteMatrix.cpp
    ${ZXING_DIR}/qrcode/encoder/ByteMatrix.h
    ${ZXING_DIR}/qrcode/encoder/Encoder.h
    ${ZXING_DIR}/qrcode/encoder/MaskUtil.cpp
    ${ZXING_DIR}/qrcode/encoder/MaskUtil.h
    ${ZXING_DIR}/qrcode/encoder/MatrixUtil.cpp
    ${ZXING_DIR}/qrcode/encoder/MatrixUtil.h
    ${ZXING_DIR}/qrcode/encoder/QRCode.cpp
    ${ZXING_DIR}/qrcode/encoder/QRCode.h
    ${ZXING_DIR}/qrcode/encoder/QREncoder.cpp

    )

target_sources(qzxing PRIVATE
    ${SOURCES}
    ${AZTEC_DIR}
    ${COMMON_DIR}
    ${DATAMATRIX_DIR}
    ${MULTI_DIR}
    ${ONED_DIR}
    ${PDF417_DIR}
    ${QRCODE_DIR})
