#For backward compatibility, when using QZXing.pri, enable the complete
# library functionality
CONFIG += enable_decoder_1d_barcodes \
          enable_decoder_qr_code \
          enable_decoder_data_matrix \
          enable_decoder_aztec \
          enable_decoder_pdf17 \
          enable_encoder_qr_code

include(./QZXing-components.pri)
