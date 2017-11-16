#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <stdlib.h>
#include <QtGlobal>
#include <QtWidgets>
#include <QQuickWindow>
#ifndef Q_OS_DARWIN
#include <QtSingleApplication>
#endif
#include "screenshot.h"
#include "systemtray.h"

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


    // What OpenGL implementation to use on Windows.
    // Use ANGLE library on Windows 8 & 10
    // Use software opengl on Windows 7, because of issues with ANGLE.
    // More reading: http://doc.qt.io/qt-5/windows-requirements.html#graphics-drivers
    #ifdef Q_OS_WIN
    if (QSysInfo::productVersion().contains("7")) {
        app.setAttribute(Qt::AA_UseSoftwareOpenGL);
    } else {
        app.setAttribute(Qt::AA_UseOpenGLES);
    }
    #endif


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

    ScreenShot screenshot;
    QQmlApplicationEngine engine;

    SystemTray *trayIcon = new SystemTray();
    trayIcon->setIcon(QIcon(path_prefix + "/images/windowicon.png"));

    engine.rootContext()->setContextProperty("appDir", app_dir);
    engine.rootContext()->setContextProperty("urlPrefix", url_prefix);
    engine.rootContext()->setContextProperty("appVersion", APP_VERSION);
    engine.rootContext()->setContextProperty("ScreenShot", &screenshot);
    engine.rootContext()->setContextProperty("SysTrayIcon", trayIcon);
    engine.rootContext()->setContextProperty("app", &app);
    engine.load(QUrl(url_prefix + main_qml));

    // This is the current system tray icon.
    // Should probably be replaced by QML when all supported platforms are on > Qt 5.8
    // See http://doc-snapshots.qt.io/qt5-5.8/qml-qt-labs-platform-systemtrayicon.html
    QObject *root = engine.rootObjects().first();
    QQuickWindow *qmlWindow = qobject_cast<QQuickWindow *>(root);

    // Set icon in the window, doesn't effect desktop icons.
    qmlWindow->setIcon(QIcon(path_prefix + "/images/windowicon.png"));
    // Show root window unless explicitly hidden in settings.
    if (qmlWindow->property("hideOnLaunch").toBool() == false) {
        qmlWindow->show();
    }

    QAction *showAction = new QAction(QObject::tr("&Show credentials"), qmlWindow);
    // The call to hide doesn't make much sense but makes it work on macOS when hidden from the dock.
    root->connect(showAction, &QAction::triggered, qmlWindow, &QQuickWindow::hide);
    root->connect(showAction, &QAction::triggered, qmlWindow, &QQuickWindow::show);
    root->connect(showAction, &QAction::triggered, qmlWindow, &QQuickWindow::raise);
    root->connect(showAction, &QAction::triggered, qmlWindow, &QQuickWindow::requestActivate);
    QAction *quitAction = new QAction(QObject::tr("&Quit"), qmlWindow);
    root->connect(quitAction, &QAction::triggered, qApp, &QApplication::quit);
    QMenu *trayIconMenu = new QMenu();
    trayIconMenu->addAction(showAction);
    trayIconMenu->addSeparator();
    trayIconMenu->addAction(quitAction);
    trayIcon->setContextMenu(trayIconMenu);
    trayIcon->setToolTip("Yubico Authenticator");
    #ifndef Q_OS_DARWIN
    // Double-click should show credentials.
    // Double-click in systemtray icons is not supported on macOS.
    root->connect(trayIcon,SIGNAL(doubleClicked()), qmlWindow,SLOT(show()));
    root->connect(trayIcon,SIGNAL(doubleClicked()), qmlWindow,SLOT(raise()));
    root->connect(trayIcon,SIGNAL(doubleClicked()), qmlWindow,SLOT(requestActivate()));
    #endif

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
