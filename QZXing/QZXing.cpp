#include "QZXing.h"

#include <zxing/common/GlobalHistogramBinarizer.h>
#include <zxing/Binarizer.h>
#include <zxing/BinaryBitmap.h>
#include <zxing/MultiFormatReader.h>
#include <zxing/DecodeHints.h>
#include <zxing/ResultMetadata.h>
#include <zxing/common/detector/WhiteRectangleDetector.h>
#include <zxing/InvertedLuminanceSource.h>
#include "CameraImageWrapper.h"
#include "ImageHandler.h"
#include <QTime>
#include <QUrl>
#include <QFileInfo>
#include <QColor>
#include <QtCore/QTextCodec>
#include <QDebug>

#ifdef ENABLE_ENCODER_QR_CODE
#include <zxing/qrcode/encoder/Encoder.h>
#include <zxing/qrcode/ErrorCorrectionLevel.h>
#endif // ENABLE_ENCODER_QR_CODE

#ifdef QZXING_MULTIMEDIA
#include "QZXingFilter.h"
#endif //QZXING_MULTIMEDIA

#ifdef QZXING_QML
#if QT_VERSION >= 0x040700 && QT_VERSION < 0x050000
#include <QtDeclarative>
#elif QT_VERSION >= 0x050000
#include <QtQml/qqml.h>
#endif

#include <QQmlEngine>
#include <QQmlContext>
#include <QQuickImageProvider>
#include "QZXingImageProvider.h"
#endif //QZXING_QML


using namespace zxing;

QZXing::QZXing(QObject *parent) : QObject(parent), tryHarder_(false), lastDecodeOperationSucceded_(false)
{
    decoder = new MultiFormatReader();
    setDecoder(DecoderFormat_QR_CODE |
               DecoderFormat_DATA_MATRIX |
               DecoderFormat_UPC_E |
               DecoderFormat_UPC_A |
               DecoderFormat_UPC_EAN_EXTENSION |
               DecoderFormat_RSS_14 |
               DecoderFormat_RSS_EXPANDED |
               DecoderFormat_PDF_417 |
               DecoderFormat_MAXICODE |
               DecoderFormat_EAN_8 |
               DecoderFormat_EAN_13 |
               DecoderFormat_CODE_128 |
               DecoderFormat_CODE_93 |
               DecoderFormat_CODE_39 |
               DecoderFormat_CODABAR |
               DecoderFormat_ITF |
               DecoderFormat_Aztec);

    setTryHarderBehaviour(TryHarderBehaviour_Rotate |
                          TryHarderBehaviour_ThoroughScanning);

    setSourceFilterType(SourceFilter_ImageNormal);

    imageHandler = new ImageHandler();
}

QZXing::~QZXing()
{
    if (imageHandler)
        delete imageHandler;

    if (decoder)
        delete decoder;
}

QZXing::QZXing(QZXing::DecoderFormat decodeHints, QObject *parent) : QObject(parent), lastDecodeOperationSucceded_(false)
{
    decoder = new MultiFormatReader();
    imageHandler = new ImageHandler();

    setDecoder(decodeHints);
    setSourceFilterType(SourceFilter_ImageNormal);
}

#ifdef QZXING_QML

#if QT_VERSION >= 0x040700
void QZXing::registerQMLTypes()
{
    qmlRegisterType<QZXing>("QZXing", 2, 3, "QZXing");

#ifdef QZXING_MULTIMEDIA
    qmlRegisterType<QZXingFilter>("QZXing", 2, 3, "QZXingFilter");
#endif //QZXING_MULTIMEDIA

}
#endif //QT_VERSION >= Qt 4.7

#if  QT_VERSION >= 0x050000
void QZXing::registerQMLImageProvider(QQmlEngine& engine)
{
    engine.addImageProvider(QLatin1String("QZXing"), new QZXingImageProvider());
}
#endif //QT_VERSION >= Qt 5.0

#endif //QZXING_QML

void QZXing::setTryHarder(bool tryHarder)
{
    tryHarder_ = tryHarder;
}

bool QZXing::getTryHarder()
{
    return tryHarder_;
}

void QZXing::setTryHarderBehaviour(QZXing::TryHarderBehaviourType tryHarderBehaviour)
{
    tryHarderType = tryHarderBehaviour;
}

QZXing::TryHarderBehaviourType QZXing::getTryHarderBehaviour()
{
    return tryHarderType;
}

void QZXing::setSourceFilterType(QZXing::SourceFilterType sourceFilter)
{
    imageSourceFilter = sourceFilter;
}

QZXing::SourceFilterType QZXing::getSourceFilterType()
{
    return imageSourceFilter;
}
void QZXing::setAllowedExtensions(const QVariantList& extensions)
{
    std::set<int> allowedExtensions;
    for (const QVariant& extension: extensions) {
        allowedExtensions.insert(extension.toInt());
    }

    allowedExtensions_ = allowedExtensions;
}

QVariantList QZXing::getAllowedExtensions()
{
    QVariantList allowedExtensions;
    for (const int& extension: allowedExtensions_) {
        allowedExtensions << extension;
    }

    return allowedExtensions;
}

QString QZXing::decoderFormatToString(int fmt)
{
    switch (fmt) {
    case DecoderFormat_Aztec:
        return "AZTEC";

    case DecoderFormat_CODABAR:
        return "CODABAR";

    case DecoderFormat_CODE_39:
        return "CODE_39";

    case DecoderFormat_CODE_93:
        return "CODE_93";

    case DecoderFormat_CODE_128:
        return "CODE_128";

    case DecoderFormat_CODE_128_GS1:
        return "CODE_128_GS1";

    case DecoderFormat_DATA_MATRIX:
        return "DATA_MATRIX";

    case DecoderFormat_EAN_8:
        return "EAN_8";

    case DecoderFormat_EAN_13:
        return "EAN_13";

    case DecoderFormat_ITF:
        return "ITF";

    case DecoderFormat_MAXICODE:
        return "MAXICODE";

    case DecoderFormat_PDF_417:
        return "PDF_417";

    case DecoderFormat_QR_CODE:
        return "QR_CODE";

    case DecoderFormat_RSS_14:
        return "RSS_14";

    case DecoderFormat_RSS_EXPANDED:
        return "RSS_EXPANDED";

    case DecoderFormat_UPC_A:
        return "UPC_A";

    case DecoderFormat_UPC_E:
        return "UPC_E";

    case DecoderFormat_UPC_EAN_EXTENSION:
        return "UPC_EAN_EXTENSION";
    } // switch
    return QString();
}

QString QZXing::foundedFormat() const
{
    return foundedFmt;
}

QString QZXing::charSet() const
{
    return charSet_;
}

bool QZXing::getLastDecodeOperationSucceded()
{
    return lastDecodeOperationSucceded_;
}

QVariantMap QZXing::metadataToMap(const ResultMetadata &metadata)
{
    QVariantMap obj;
    for (const ResultMetadata::Key &key: metadata.keys()) {
        QString keyName = QString::fromStdString(metadata.keyToString(key));

        switch (key) {
        case ResultMetadata::ORIENTATION:
        case ResultMetadata::ISSUE_NUMBER:
        case ResultMetadata::STRUCTURED_APPEND_SEQUENCE:
        case ResultMetadata::STRUCTURED_APPEND_CODE_COUNT:
        case ResultMetadata::STRUCTURED_APPEND_PARITY:
            obj[keyName] = QVariant(metadata.getInt(key));
            break;
        case ResultMetadata::ERROR_CORRECTION_LEVEL:
        case ResultMetadata::SUGGESTED_PRICE:
        case ResultMetadata::POSSIBLE_COUNTRY:
        case ResultMetadata::UPC_EAN_EXTENSION:
            obj[keyName] = QVariant(metadata.getString(key).c_str());
            break;

        case ResultMetadata::OTHER:
        case ResultMetadata::PDF417_EXTRA_METADATA:
        case ResultMetadata::BYTE_SEGMENTS:
            break;
        }
    }

    return obj;
}

void QZXing::setDecoder(const uint &hint)
{
    unsigned int newHints = 0;

    if(hint & DecoderFormat_Aztec)
        newHints |= DecodeHints::AZTEC_HINT;

    if(hint & DecoderFormat_CODABAR)
        newHints |= DecodeHints::CODABAR_HINT;

    if(hint & DecoderFormat_CODE_39)
        newHints |= DecodeHints::CODE_39_HINT;

    if(hint & DecoderFormat_CODE_93)
        newHints |= DecodeHints::CODE_93_HINT;

    if(hint & DecoderFormat_CODE_128)
        newHints |= DecodeHints::CODE_128_HINT;

    if(hint & DecoderFormat_DATA_MATRIX)
        newHints |= DecodeHints::DATA_MATRIX_HINT;

    if(hint & DecoderFormat_EAN_8)
        newHints |= DecodeHints::EAN_8_HINT;

    if(hint & DecoderFormat_EAN_13)
        newHints |= DecodeHints::EAN_13_HINT;

    if(hint & DecoderFormat_ITF)
        newHints |= DecodeHints::ITF_HINT;

    if(hint & DecoderFormat_MAXICODE)
        newHints |= DecodeHints::MAXICODE_HINT;

    if(hint & DecoderFormat_PDF_417)
        newHints |= DecodeHints::PDF_417_HINT;

    if(hint & DecoderFormat_QR_CODE)
        newHints |= DecodeHints::QR_CODE_HINT;

    if(hint & DecoderFormat_RSS_14)
        newHints |= DecodeHints::RSS_14_HINT;

    if(hint & DecoderFormat_RSS_EXPANDED)
        newHints |= DecodeHints::RSS_EXPANDED_HINT;

    if(hint & DecoderFormat_UPC_A)
        newHints |= DecodeHints::UPC_A_HINT;

    if(hint & DecoderFormat_UPC_E)
        newHints |= DecodeHints::UPC_E_HINT;

    if(hint & DecoderFormat_UPC_EAN_EXTENSION)
        newHints |= DecodeHints::UPC_EAN_EXTENSION_HINT;

    if(hint & DecoderFormat_CODE_128_GS1)
    {
        newHints |= DecodeHints::CODE_128_HINT;
        newHints |= DecodeHints::ASSUME_GS1;
    }

    enabledDecoders = newHints;

    emit enabledFormatsChanged();
}

/*!
 * \brief getTagRec - returns rectangle containing the tag.
 *
 * To be able display tag rectangle regardless of the size of the bit matrix rect is in related coordinates [0; 1].
 * \param resultPoints
 * \param bitMatrix
 * \return
 */
QRectF getTagRect(const ArrayRef<Ref<ResultPoint> > &resultPoints, const Ref<BitMatrix> &bitMatrix)
{
    if (resultPoints->size() < 2)
        return QRectF();

    int matrixWidth = bitMatrix->getWidth();
    int matrixHeight = bitMatrix->getHeight();
    // 1D barcode
    if (resultPoints->size() == 2) {
        WhiteRectangleDetector detector(bitMatrix);
        std::vector<Ref<ResultPoint> > resultRectPoints = detector.detect();

        if (resultRectPoints.size() != 4)
            return QRectF();

        qreal xMin = qreal(resultPoints[0]->getX());
        qreal xMax = xMin;
        for (int i = 1; i < resultPoints->size(); ++i) {
            qreal x = qreal(resultPoints[i]->getX());
            if (x < xMin)
                xMin = x;
            if (x > xMax)
                xMax = x;
        }

        qreal yMin = qreal(resultRectPoints[0]->getY());
        qreal yMax = yMin;
        for (size_t i = 1; i < resultRectPoints.size(); ++i) {
            qreal y = qreal(resultRectPoints[i]->getY());
            if (y < yMin)
                yMin = y;
            if (y > yMax)
                yMax = y;
        }

        return QRectF(QPointF(xMin / matrixWidth, yMax / matrixHeight), QPointF(xMax / matrixWidth, yMin / matrixHeight));
    }

    // 2D QR code
    if (resultPoints->size() == 4) {
        qreal xMin = qreal(resultPoints[0]->getX());
        qreal xMax = xMin;
        qreal yMin = qreal(resultPoints[0]->getY());
        qreal yMax = yMin;
        for (int i = 1; i < resultPoints->size(); ++i) {
            qreal x = qreal(resultPoints[i]->getX());
            qreal y = qreal(resultPoints[i]->getY());
            if (x < xMin)
                xMin = x;
            if (x > xMax)
                xMax = x;
            if (y < yMin)
                yMin = y;
            if (y > yMax)
                yMax = y;
        }

        return QRectF(QPointF(xMin / matrixWidth, yMax / matrixHeight), QPointF(xMax / matrixWidth, yMin / matrixHeight));
    }

    return QRectF();
}

QString QZXing::decodeImage(const QImage &image, int maxWidth, int maxHeight, bool smoothTransformation)
{
    //qDebug() << "Start decoding";
    QElapsedTimer t;
    t.start();
    processingTime = -1;
    Ref<Result> res;
    emit decodingStarted();

    if(image.isNull())
    {
        emit decodingFinished(false);
        processingTime = t.elapsed();
        //qDebug() << "End decoding 1";
        return "";
    }

    CameraImageWrapper *ciw = ZXING_NULLPTR;

    if ((maxWidth > 0) || (maxHeight > 0))
        ciw = CameraImageWrapper::Factory(image, maxWidth, maxHeight, smoothTransformation);
    else
        ciw = CameraImageWrapper::Factory(image, 999, 999, true);

    QString errorMessage = "Unknown";

    Ref<LuminanceSource> imageRefOriginal = Ref<LuminanceSource>(ciw);
    Ref<LuminanceSource> imageRef = imageRefOriginal;
    Ref<GlobalHistogramBinarizer> binz;
    Ref<BinaryBitmap> bb;

    size_t numberOfIterations = 0;
    if (imageSourceFilter & SourceFilter_ImageNormal)
        numberOfIterations++;
    if (imageSourceFilter & SourceFilter_ImageInverted)
        numberOfIterations++;

    //qDebug() << "Iterations: "<< numberOfIterations << ", sourceFilter: " << imageSourceFilter;

    for(size_t i=0; i<numberOfIterations; ++i){
        try {
            if((numberOfIterations == 1 && (imageSourceFilter & SourceFilter_ImageInverted)) || i == 1) {
                //qDebug() << "Selecting Inverted Luminance source";
                imageRef = Ref<LuminanceSource>((LuminanceSource*)(new InvertedLuminanceSource(imageRefOriginal)));
            }
            binz = Ref<GlobalHistogramBinarizer>( new GlobalHistogramBinarizer(imageRef) );
            bb = Ref<BinaryBitmap>( new BinaryBitmap(binz) );

            DecodeHints hints(static_cast<DecodeHintType>(enabledDecoders));

            if (hints.containsFormat(BarcodeFormat::UPC_EAN_EXTENSION)) {
                hints.setAllowedEanExtensions(allowedExtensions_);
            }

            lastDecodeOperationSucceded_ = false;
            try {
                //qDebug() << "Decoding phase 1: started";
                res = decoder->decode(bb, hints);
                processingTime = t.elapsed();
                lastDecodeOperationSucceded_ = true;
                break;
            } catch(zxing::Exception &/*e*/){
                //qDebug() << "Decoding phase 1: failed";
            }

            if(!lastDecodeOperationSucceded_ && tryHarder_ && (tryHarderType & TryHarderBehaviour_ThoroughScanning))
            {
                //qDebug() << "Decoding phase 2, thorought scan: starting";
                hints.setTryHarder(true);
                if(hints.containsFormat(BarcodeFormat::UPC_EAN_EXTENSION) &&
                        !allowedExtensions_.empty() &&
                        !(hints & DecodeHints::PRODUCT_HINT).isEmpty() )
                    hints.setAllowedEanExtensions(std::set<int>());

                try {
                    res = decoder->decode(bb, hints);
                    processingTime = t.elapsed();
                    lastDecodeOperationSucceded_ = true;
                    break;
                } catch(zxing::Exception &/*e*/) {
                    //qDebug() << "Decoding phase 2, thorought scan: failed";
                }
            }

            if (!lastDecodeOperationSucceded_&& tryHarder_ && (tryHarderType & TryHarderBehaviour_Rotate) && bb->isRotateSupported()) {
                Ref<BinaryBitmap> bbTmp = bb;

                //qDebug() << "Decoding phase 2, rotate: starting";

                hints.setTryHarder(true);
                for (int i=0; (i<3 && !lastDecodeOperationSucceded_); i++) {
                    Ref<BinaryBitmap> rotatedImage(bbTmp->rotateCounterClockwise());
                    bbTmp = rotatedImage;

                    try {
                        res = decoder->decode(rotatedImage, hints);
                        processingTime = t.elapsed();
                        lastDecodeOperationSucceded_ = true;
                        break;
                    } catch(zxing::Exception &/*e*/) {
                        //qDebug() << "Decoding phase 2, rotate: failed";
                    }
                }
            }
        }
        catch(zxing::Exception &e)
        {
            errorMessage = QString(e.what());
            //qDebug() << "Decoding failed: " << errorMessage;
        }
    }

    if (lastDecodeOperationSucceded_) {
        //qDebug() << "Decoding succeeded.";
        QString string = QString(res->getText()->getText().c_str());
        if (!string.isEmpty() && (string.length() > 0)) {
            int fmt = res->getBarcodeFormat().value;
            foundedFmt = decoderFormatToString(1<<fmt);
            charSet_ = QString::fromStdString(res->getCharSet());
            if (!charSet_.isEmpty()) {
                QTextCodec *codec = QTextCodec::codecForName(res->getCharSet().c_str());
                if (codec)
                    string = codec->toUnicode(res->getText()->getText().c_str());
            }

            emit tagFound(string);
            emit tagFoundAdvanced(string, foundedFmt, charSet_);

            QVariantMap metadataMap = metadataToMap(res->getMetadata());
            emit tagFoundAdvanced(string, foundedFmt, charSet_, metadataMap);

            try {
                const QRectF rect = getTagRect(res->getResultPoints(), binz->getBlackMatrix());
                emit tagFoundAdvanced(string, foundedFmt, charSet_, rect);
            }catch(zxing::Exception &/*e*/){}
        }
        emit decodingFinished(true);
        //qDebug() << "End decoding 2";
        return string;
    }

    emit error(errorMessage);
    emit decodingFinished(false);
    processingTime = t.elapsed();
    //qDebug() << "End decoding 3";
    return "";
}

QString QZXing::decodeImageFromFile(const QString& imageFilePath, int maxWidth, int maxHeight, bool smoothTransformation)
{
    // used to have a check if this image exists
    // but was removed because if the image file path doesn't point to a valid image
    // then the QImage::isNull will return true and the decoding will fail eitherway.
    const QString header = "file://";

    QString filePath = imageFilePath;
    if(imageFilePath.startsWith(header))
        filePath = imageFilePath.right(imageFilePath.size() - header.size());

    QUrl imageUrl = QUrl::fromLocalFile(filePath);
    QImage tmpImage = QImage(imageUrl.toLocalFile());
    return decodeImage(tmpImage, maxWidth, maxHeight, smoothTransformation);
}

QString QZXing::decodeImageQML(QObject *item)
{
    return decodeSubImageQML(item);
}

QString QZXing::decodeSubImageQML(QObject *item,
                                  const int offsetX, const int offsetY,
                                  const int width, const int height)
{
    if(item  == ZXING_NULLPTR)
    {
        processingTime = 0;
        emit decodingFinished(false);
        return "";
    }

    QImage img = imageHandler->extractQImage(item, offsetX, offsetY, width, height);

    return decodeImage(img);
}

QString QZXing::decodeImageQML(const QUrl &imageUrl)
{
    return decodeSubImageQML(imageUrl);
}

QString QZXing::decodeSubImageQML(const QUrl &imageUrl,
                                  const int offsetX, const int offsetY,
                                  const int width, const int height)
{
#ifdef QZXING_QML

    QString imagePath = imageUrl.path();
    imagePath = imagePath.trimmed();
    QImage img;
    if (imageUrl.scheme() == "image") {
        if (imagePath.startsWith("/"))
            imagePath = imagePath.right(imagePath.length() - 1);
        QQmlEngine *engine = QQmlEngine::contextForObject(this)->engine();
        QQuickImageProvider *imageProvider = dynamic_cast<QQuickImageProvider *>(engine->imageProvider(imageUrl.host()));
        QSize imgSize;
        img = imageProvider->requestImage(imagePath, &imgSize, QSize());
    } else {
        QFileInfo fileInfo(imagePath);
        if (!fileInfo.exists()) {
            qDebug() << "[decodeSubImageQML()] The file" << imagePath << "does not exist.";
            emit decodingFinished(false);
            return "";
        }
        img = QImage(imagePath);
    }

    if (offsetX || offsetY || width || height)
        img = img.copy(offsetX, offsetY, width, height);
    return decodeImage(img);
#else
    Q_UNUSED(imageUrl);
    Q_UNUSED(offsetX);
    Q_UNUSED(offsetY);
    Q_UNUSED(width);
    Q_UNUSED(height);
    return decodeImage(QImage());
#endif //QZXING_QML
}

#ifdef ENABLE_ENCODER_GENERIC
QImage QZXing::encodeData(const QString& data,
                          const EncoderFormat encoderFormat,
                          const QSize encoderImageSize,
                          const EncodeErrorCorrectionLevel errorCorrectionLevel,
                          const bool border,
                          const bool transparent)
{
    return encodeData(data,
                      QZXingEncoderConfig(encoderFormat,
                                          encoderImageSize,
                                          errorCorrectionLevel,
                                          border,
                                          transparent));
}

QImage QZXing::encodeData(const QString &data, const QZXingEncoderConfig &encoderConfig)
{
    QImage image;

    try {
        switch (encoderConfig.format) {
#ifdef ENABLE_ENCODER_QR_CODE
        case EncoderFormat_QR_CODE:
        {
            Ref<qrcode::QRCode> barcode = qrcode::Encoder::encode(
                        data.toStdWString(),
                        encoderConfig.errorCorrectionLevel == EncodeErrorCorrectionLevel_H ?
                            qrcode::ErrorCorrectionLevel::H :
                            (encoderConfig.errorCorrectionLevel == EncodeErrorCorrectionLevel_Q ?
                                 qrcode::ErrorCorrectionLevel::Q :
                                 (encoderConfig.errorCorrectionLevel == EncodeErrorCorrectionLevel_M ?
                                      qrcode::ErrorCorrectionLevel::M :
                                      qrcode::ErrorCorrectionLevel::L)));

            Ref<qrcode::ByteMatrix> bytesRef = barcode->getMatrix();
            const std::vector< std::vector <zxing::byte> >& bytes = bytesRef->getArray();
            const int width = int(bytesRef->getWidth()) + (encoderConfig.border ? 2 : 0);
            const int height = int(bytesRef->getHeight()) + (encoderConfig.border ? 2 : 0);
            const QRgb black = qRgba(0, 0, 0, encoderConfig.transparent ? 0 : 255);
            const QRgb white = qRgba(255, 255, 255, 255);

            image = QImage(width, height, QImage::Format_ARGB32);
            image.fill(white);

            int offset = encoderConfig.border ? 1 : 0;

            for (size_t i=0; i<bytesRef->getWidth(); ++i) {
                for (size_t j=0; j<bytesRef->getHeight(); ++j) {
                    if (bytes[j][i]) {
                        image.setPixel(offset+int(i), offset+int(j), black);
                    }
                }
            }

            image = image.scaled(encoderConfig.imageSize);
            break;
        }
#endif // ENABLE_ENCODER_QR_CODE
        case EncoderFormat_INVALID:
            break;
        }
    } catch (std::exception& e) {
        std::cout << "Error: " << e.what() << std::endl;
    }

    return image;
}
#endif // ENABLE_ENCODER_GENERIC

int QZXing::getProcessTimeOfLastDecoding()
{
    return processingTime;
}

uint QZXing::getEnabledFormats() const
{
    return enabledDecoders;
}
