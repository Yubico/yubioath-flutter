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
    Q_INVOKABLE QVariantList capture() {
        QList<QScreen*> screens = QGuiApplication::screens();
        QScreen *screen;
        QVariantList maps;
        // Iterate the screens
        for (int i = 0; i < screens.length(); i++) {
            screen = screens.at(i);
            // Screen geometry
            QRect g = screen->geometry();
            QPixmap screenShot = screen->grabWindow(0, g.x(), g.y(), g.width(), g.height());
            // Monochrome, no dither
            QImage image = screenShot.toImage();
            image = image.convertToFormat(QImage::Format_Mono, Qt::ThresholdDither);
            // Get all pixels as 1 (black) or 0 (white)
            QByteArray imageArray;
            for (int row = 0; row < image.height(); ++row) {
                for (int col = 0; col < image.width(); ++col) {
                    QRgb px = image.pixel(col, row);
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
            maps.append(map);
        }
        return maps;
    }
};

#endif // SCREENSHOT_H
