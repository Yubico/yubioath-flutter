// -*- mode:c++; tab-width:2; indent-tabs-mode:nil; c-basic-offset:2 -*-
/*
 *  Copyright 2010 ZXing authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <zxing/MultiFormatReader.h>
#include <zxing/ReaderException.h>
#include <zxing/ZXing.h>

#ifdef ENABLE_DECODER_AZTEC
    #include <zxing/aztec/AztecReader.h>
#endif // ENABLE_DECODER_AZTEC

#ifdef ENABLE_DECODER_DATA_MATRIX
#include <zxing/datamatrix/DataMatrixReader.h>
#endif // ENABLE_DECODER_DATA_MATRIX

#ifdef ENABLE_DECODER_1D_BARCODES
#include <zxing/oned/MultiFormatOneDReader.h>
#include <zxing/oned/MultiFormatUPCEANReader.h>
#endif // ENABLE_DECODER_1D_BARCODES

#ifdef ENABLE_DECODER_PDF17
#include <zxing/pdf417/PDF417Reader.h>
#endif // ENABLE_DECODER_PDF17

#ifdef ENABLE_DECODER_QR_CODE
#include <zxing/qrcode/QRCodeReader.h>
#endif // ENABLE_DECODER_QR_CODE


using zxing::Ref;
using zxing::Result;
using zxing::MultiFormatReader;

// VC++
using zxing::DecodeHints;
using zxing::BinaryBitmap;

MultiFormatReader::MultiFormatReader() {}
  
Ref<Result> MultiFormatReader::decode(Ref<BinaryBitmap> image) {
  setHints(DecodeHints::DEFAULT_HINT);
  return decodeInternal(image);
}

Ref<Result> MultiFormatReader::decode(Ref<BinaryBitmap> image, DecodeHints hints) {
  setHints(hints);
  return decodeInternal(image);
}

Ref<Result> MultiFormatReader::decodeWithState(Ref<BinaryBitmap> image) {
  // Make sure to set up the default state so we don't crash
  if (readers_.empty()) {
    setHints(DecodeHints::DEFAULT_HINT);
  }
  return decodeInternal(image);
}

void MultiFormatReader::setHints(DecodeHints hints) {
  hints_ = hints;
  readers_.clear();

  enableReaders(hints, false);

  if (readers_.empty())
      enableReaders(hints, true);
}

void MultiFormatReader::enableReaders(zxing::DecodeHints hints, bool allowAll)
{
    bool tryHarder = hints.getTryHarder();

    bool addOneDReader = hints.containsFormat(BarcodeFormat::UPC_E) ||
      hints.containsFormat(BarcodeFormat::UPC_A) ||
      hints.containsFormat(BarcodeFormat::UPC_E) ||
      hints.containsFormat(BarcodeFormat::EAN_13) ||
      hints.containsFormat(BarcodeFormat::EAN_8) ||
      hints.containsFormat(BarcodeFormat::CODABAR) ||
      hints.containsFormat(BarcodeFormat::CODE_39) ||
      hints.containsFormat(BarcodeFormat::CODE_93) ||
      hints.containsFormat(BarcodeFormat::CODE_128) ||
      hints.containsFormat(BarcodeFormat::ITF) ||
      hints.containsFormat(BarcodeFormat::RSS_14) ||
      hints.containsFormat(BarcodeFormat::RSS_EXPANDED);

  #ifdef ENABLE_DECODER_1D_BARCODES
    if ((allowAll || addOneDReader) && !tryHarder) {
      readers_.push_back(Ref<Reader>(new zxing::oned::MultiFormatOneDReader(hints)));
    }
  #endif

  #ifdef ENABLE_DECODER_QR_CODE
    if (allowAll || hints.containsFormat(BarcodeFormat::QR_CODE)) {
      readers_.push_back(Ref<Reader>(new zxing::qrcode::QRCodeReader()));
    }
  #endif

  #ifdef ENABLE_DECODER_DATA_MATRIX
    if (allowAll || hints.containsFormat(BarcodeFormat::DATA_MATRIX)) {
      readers_.push_back(Ref<Reader>(new zxing::datamatrix::DataMatrixReader()));
    }
  #endif

  #ifdef ENABLE_DECODER_AZTEC
    if (allowAll || hints.containsFormat(BarcodeFormat::AZTEC)) {
      readers_.push_back(Ref<Reader>(new zxing::aztec::AztecReader()));
    }
  #endif

  #ifdef ENABLE_DECODER_PDF17
    if (allowAll || hints.containsFormat(BarcodeFormat::PDF_417)) {
      readers_.push_back(Ref<Reader>(new zxing::pdf417::PDF417Reader()));
    }
  #endif
    /*
    if (hints.contains(BarcodeFormat.MAXICODE)) {
      readers.add(new MaxiCodeReader());
    }
    */
  #ifdef ENABLE_DECODER_1D_BARCODES
    if ((allowAll || addOneDReader) && tryHarder) {
      readers_.push_back(Ref<Reader>(new zxing::oned::MultiFormatOneDReader(hints)));
    }
  #endif
}

Ref<Result> MultiFormatReader::decodeInternal(Ref<BinaryBitmap> image) {
  for (size_t i = 0; i < readers_.size(); i++) {
    try {
      return readers_[i]->decode(image, hints_);
    } catch (ReaderException const& re) {
      (void)re;
      // continue
    }
  }
  throw ReaderException("No code detected");
}
  
MultiFormatReader::~MultiFormatReader() {}
