#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <stdlib.h>
#include <QtGlobal>
#include <QtWidgets>
#include <QQuickWindow>
#include <QQuickStyle>
#include "screenshot.h"
#include "systemtray.h"

int main(int argc, char *argv[])
{
    // Don't write .pyc files.
    qputenv("PYTHONDONTWRITEBYTECODE", "1");

    // Use Material "Dense" variant, recommended for Desktop
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");

    QApplication application(argc, argv);
    application.setApplicationName("Yubico Authenticator");
    application.setOrganizationName("Yubico");
    application.setOrganizationDomain("com.yubico");

    QQuickStyle::setStyle("Material");

    // A lock file is used, to ensure only one running instance at the time.
    QString tmpDir = QDir::tempPath();
    QLockFile lockFile(tmpDir + "/yubioath-desktop.lock");
    if(!lockFile.tryLock(100)){
        QMessageBox msgBox;
        msgBox.setIcon(QMessageBox::Warning);
        msgBox.setText("Yubico Authenticator is already running.");
        msgBox.exec();
        return 1;
    }

    QString app_dir = application.applicationDirPath();
    QString main_qml = "/qml/main.qml";
    QString path_prefix;
    QString url_prefix;

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

    engine.rootContext()->setContextProperty("appDir", app_dir);
    engine.rootContext()->setContextProperty("urlPrefix", url_prefix);
    engine.rootContext()->setContextProperty("appVersion", APP_VERSION);
    engine.rootContext()->setContextProperty("ScreenShot", &screenshot);
    engine.rootContext()->setContextProperty("application", &application);
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

    const int status = application.exec();
    return status;
}
