#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <stdlib.h>
#include <QtGlobal>
#include <QtWidgets>
#ifndef Q_OS_DARWIN
#include <QtSingleApplication>
#endif
#include "screenshot.h"

int main(int argc, char *argv[])
{
    // Global menubar is broken for qt5 apps in Ubuntu Unity, see:
    // https://bugs.launchpad.net/ubuntu/+source/appmenu-qt5/+bug/1323853
    // This workaround enables a local menubar.
    qputenv("UBUNTU_MENUPROXY","0");

    // Don't write .pyc files.
    qputenv("PYTHONDONTWRITEBYTECODE", "1");

    #if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    #endif

    // Non Darwin platforms uses QSingleApplication to ensure only one running instance.
    #ifndef Q_OS_DARWIN
    QtSingleApplication app(argc, argv);
    if (app.sendMessage("")) {
        return 0;
    }
    #else
    QApplication app(argc, argv);
    #endif

    QString app_dir = app.applicationDirPath();
    QString main_qml = "/qml/main.qml";
    QString path_prefix;
    QString url_prefix;

    app.setApplicationName("Yubico Authenticator");
    app.setOrganizationName("Yubico");
    app.setOrganizationDomain("com.yubico");

    if (QFileInfo::exists(":" + main_qml)) {
        // Embedded resources
        path_prefix = ":";
        url_prefix = "qrc://";
    } else if (QFileInfo::exists(app_dir + main_qml)) {
        // Try relative to executable
        path_prefix = app_dir;
        url_prefix = app_dir;
    } else {  //Assume qml/main.qml in cwd.
        app_dir = ".";
        path_prefix = ".";
        url_prefix = ".";
    }

    app.setWindowIcon(QIcon(path_prefix + "/images/windowicon.png"));

    ScreenShot screenshot;
    QQmlApplicationEngine engine;

    QSystemTrayIcon *trayIcon = new QSystemTrayIcon();
    trayIcon->setToolTip("Yubico Authenticator");
    trayIcon->setIcon(QIcon(path_prefix + "/images/windowicon.png"));

    engine.rootContext()->setContextProperty("appDir", app_dir);
    engine.rootContext()->setContextProperty("urlPrefix", url_prefix);
    engine.rootContext()->setContextProperty("appVersion", APP_VERSION);
    engine.rootContext()->setContextProperty("ScreenShot", &screenshot);
    engine.rootContext()->setContextProperty("SysTrayIcon", trayIcon);
    engine.load(QUrl(url_prefix + main_qml));

    #ifndef Q_OS_DARWIN
    // Wake up the root window on a message from new instance.
    for (auto object : engine.rootObjects()) {
        if (QWindow *window = qobject_cast<QWindow*>(object)) {
            QObject::connect(&app, &QtSingleApplication::messageReceived, [window]() {
                window->show();
                window->raise();
                window->requestActivate();
            });
        }
    }
    #endif

    return app.exec();
}
