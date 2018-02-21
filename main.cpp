#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <stdlib.h>
#include <QtGlobal>
#include <QtWidgets>
#include <QQuickWindow>
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

    QString tmpDir = QDir::tempPath();
    QLockFile lockFile(tmpDir + "/yubioath-desktop.lock");
    QApplication app(argc, argv);

    if(!lockFile.tryLock(100)){
        QMessageBox msgBox;
        msgBox.setIcon(QMessageBox::Warning);
        msgBox.setText("Yubico Authenticator is already running."
                        "\r\nOnly one instance is allowed.");
        msgBox.exec();
        return 1;
    }

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


    QObject *root = engine.rootObjects().first();

    if (argc > 2 && strcmp(argv[1], "--log-level") == 0) {
        if (argc > 4 && strcmp(argv[3], "--log-file") == 0) {
            QMetaObject::invokeMethod(root, "enableLoggingToFile", Q_ARG(QVariant, argv[2]), Q_ARG(QVariant, argv[4]));
        } else {
            QMetaObject::invokeMethod(root, "enableLogging", Q_ARG(QVariant, argv[2]));
        }
    } else {
        QMetaObject::invokeMethod(root, "disableLogging");
    }

    QQuickWindow *qmlWindow = qobject_cast<QQuickWindow *>(root);

    // Set icon in the window, doesn't effect desktop icons.
    qmlWindow->setIcon(QIcon(path_prefix + "/images/windowicon.png"));
    // Show root window unless explicitly hidden in settings.
    if (qmlWindow->property("hideOnLaunch").toBool() == false) {
        qmlWindow->show();
    }

    // This is the current system tray icon.
    // Should probably be replaced by QML when all supported platforms are on > Qt 5.8
    // See http://doc-snapshots.qt.io/qt5-5.8/qml-qt-labs-platform-systemtrayicon.html
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

    // Explicitly hide trayIcon on exit
    const int status = app.exec();
    trayIcon->hide();
    return status;
}
