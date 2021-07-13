#ifndef SCREENSHOT_H
#define SCREENSHOT_H
#include <QObject>
#include <QtWidgets>
#include <QVariant>
#include "QZXing.h"

class ScreenShot: public QObject
{
    Q_OBJECT
public:
    explicit ScreenShot () : QObject() {}
    // Take a screenshot, convert it to a bitarray and return it with some metadata
    Q_INVOKABLE QString capture(QString fileName) {

        const QList<QScreen*> screens = QGuiApplication::screens();
        std::vector<QImage> screenshots(screens.length());
        std::transform(screens.begin(), screens.end(), screenshots.begin(), &ScreenShot::takeScreenshot);

        QZXing decoder;
        //mandatory settings
        decoder.setDecoder( QZXing::DecoderFormat_QR_CODE | QZXing::DecoderFormat_EAN_13 );
        //optional settings
        //decoder.setSourceFilterType(QZXing::SourceFilter_ImageNormal | QZXing::SourceFilter_ImageInverted);
        decoder.setSourceFilterType(QZXing::SourceFilter_ImageNormal);
        decoder.setTryHarderBehaviour(QZXing::TryHarderBehaviour_ThoroughScanning | QZXing::TryHarderBehaviour_Rotate);

        QString result;
        if (fileName == "") { // If user scans the screen
            std::vector<double> scalefactor = {1, 1.5, 3, 0.85};
            QImage image;
            for (size_t i = 0; i < screenshots.size(); i++) {
                QImage screenshot(screenshots[i]);
                for (double j : scalefactor) {
                    image = screenshot.scaledToWidth(screenshot.width() * j);
                    result = decoder.decodeImage(image, image.width(), image.height(), false);
                    if (result.contains("otpauth")) {
                        return result;
                    }
                }
            }
        } else { // If user drag n drops a code
            QImage image(fileName);
            result = decoder.decodeImage(image, image.width(), image.height(), false);
        }

        return result;
    }

private:
    static QImage takeScreenshot(QScreen *screen) {
        QRect g = screen->geometry();
        return screen->grabWindow(
            0,
#ifdef Q_OS_MACOS
            g.x(), g.y(),
#else
            0, 0,
#endif
            g.width(), g.height()
        ).toImage();
    }

};

#endif // SCREENSHOT_H
