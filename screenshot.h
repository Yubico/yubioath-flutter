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
        // Get all pixels as 1 (black) or 0 (white)
        QByteArray imageArray;

        // Dimensions of output image
        int outputHeight = 0;
        int outputWidth = 0;

        const QList<QScreen*> screens = QGuiApplication::screens();
        std::vector<QImage> screenshots(screens.length());
        std::transform(screens.begin(), screens.end(), screenshots.begin(), &ScreenShot::takeScreenshot);

        for (QImage image : screenshots) {
            outputWidth = std::max(outputWidth, image.width());
        }

        for (QImage image : screenshots) {
            // Monochrome, no dither
            image = image.convertToFormat(QImage::Format_Mono, Qt::ThresholdDither);

            // Stack screens vertically in output image
            outputHeight += image.height();
            for (int row = 0; row < image.height(); ++row) {
                for (int col = 0; col < image.width(); ++col) {
                    QRgb px = image.pixel(col, row);
                    if (px == 0xFF000000) {
                        imageArray.append((char) 1);
                    } else {
                        imageArray.append((char) 0);
                    }
                }

                // Pad smaller screens horizontally
                for (int col = image.width(); col < outputWidth; ++col) {
                    imageArray.append((char) 0);
                }
            }
        }

        QVariantMap map;
        map.insert("width", outputWidth);
        map.insert("height", outputHeight);
        map.insert("data", QString(imageArray.toBase64()));
        return map;
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
