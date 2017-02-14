#ifndef SCREENSHOT_H
#define SCREENSHOT_H
#include <QObject>
#include <QtWidgets>
#include <QVariant>
class ScreenShot: public QObject
{
    Q_OBJECT
public:
    explicit ScreenShot () : QObject() {}

    // Take a screenshot, convert it to a bitarray and return it with some metadata
    Q_INVOKABLE QVariantMap capture() {
        QScreen *screen = QGuiApplication::primaryScreen();
        QPixmap screenShotPixMap = screen->grabWindow(0);
        QImage image = screenShotPixMap.toImage();

        // Monochrome, no dither
        image = image.convertToFormat(QImage::Format_Mono, Qt::ThresholdDither);

        // Iterate over all pixels
        QByteArray imageArray(4 + 4 + (image.width() * image.height()), 0);
        for (int row = 0; row < image.height(); ++row) {
            for (int col = 0; col < image.width(); ++col) {
                QRgb px = image.pixel(col, row);

                // If black 1 else 0
                if (px == 0xFF000000) {
                    imageArray.append((char) 1);
                } else {
                    imageArray.append((char) 0);
                }
            }
        }

        QVariantMap map;
        map.insert("width", image.width());
        map.insert("height", image.height());
        map.insert("data", QString(imageArray.toBase64()));
        return map;
    }
};

#endif // SCREENSHOT_H
