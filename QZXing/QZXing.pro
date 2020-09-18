#
# Copyright 2011 QZXing authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

CONFIG += \
          enable_decoder_1d_barcodes \
          enable_decoder_qr_code \
          enable_decoder_data_matrix \
          enable_decoder_aztec \
          enable_decoder_pdf17 \
          enable_encoder_qr_code
          #staticlib
          #qzxing_qml
          #qzxing_multimedia

VERSION = 2.3

TARGET = QZXing
TEMPLATE = lib

DEFINES -= DISABLE_LIBRARY_FEATURES

include(QZXing-components.pri)
