#ifndef SCREENSHOT_H
#define SCREENSHOT_H
#include <QObject>

class ScreenShot: public QObject
{
    Q_OBJECT
public:
    explicit ScreenShot () : QObject() {}

    Q_INVOKABLE int capture(){
        return 1;
    }
};

#endif // SCREENSHOT_H
