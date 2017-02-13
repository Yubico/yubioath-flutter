#ifndef SCREENSHOT_H
#define SCREENSHOT_H
#include <QObject>
#include <QtWidgets>

class ScreenShot: public QObject
{
    Q_OBJECT
public:
    explicit ScreenShot () : QObject() {}

    // Take a screenshot and return a base64 encoded string
    Q_INVOKABLE QString capture(){
        QScreen *screen = QGuiApplication::primaryScreen();
        QPixmap screenShotPixMap = screen->grabWindow(0);
        QByteArray byteArray;
        QBuffer buffer(&byteArray);
        screenShotPixMap.save(&buffer, "PNG");
        return QString(byteArray.toBase64());
    }
};

#endif // SCREENSHOT_H
