#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <stdlib.h>
#include <QtGlobal>
#include <QtWidgets>
#include <QQuickWindow>
#include <QQuickStyle>
#include <singleapplication.h>

#include "screenshot.h"


int main(int argc, char *argv[])
{
    // Don't write .pyc files.
    qputenv("PYTHONDONTWRITEBYTECODE", "1");

    // Use Material "Dense" variant, recommended for Desktop
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");

    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    SingleApplication app(argc, argv);
    application.setApplicationName("Yubico Authenticator");
    application.setApplicationVersion(APP_VERSION);
    application.setOrganizationName("Yubico");
    application.setOrganizationDomain("com.yubico");

    QQuickStyle::setStyle("Material");

    QCommandLineParser cliParser;
    cliParser.setApplicationDescription("Yubico Authenticator for Desktop");
    cliParser.addHelpOption();
    cliParser.addVersionOption();
    cliParser.addOptions({
        {"log-level", QCoreApplication::translate("main", "Enable logging at verbosity <LEVEL>: DEBUG, INFO, WARNING, ERROR, CRITICAL"), QCoreApplication::translate("main", "LEVEL")},
        {"log-file", QCoreApplication::translate("main", "Print logs to <FILE> instead of standard output; ignored without --log-level"), QCoreApplication::translate("main", "FILE")},
    });

    cliParser.process(application);

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


    if (cliParser.isSet("log-level")) {
        if (cliParser.isSet("log-file")) {
            QMetaObject::invokeMethod(root, "enableLoggingToFile", Q_ARG(QVariant, cliParser.value("log-level")), Q_ARG(QVariant, cliParser.value("log-file")));
        } else {
            QMetaObject::invokeMethod(root, "enableLogging", Q_ARG(QVariant, cliParser.value("log-level")));
        }
    } else {
        QMetaObject::invokeMethod(root, "disableLogging");
    }


    QQuickWindow *qmlWindow = qobject_cast<QQuickWindow *>(root);

    // Set icon in the window, doesn't effect desktop icons.
    qmlWindow->setIcon(QIcon(path_prefix + "/images/windowicon.png"));

    // Starting a second instance application should raise the qmlWindow. Replicated steps as above
    root->connect(&application, &SingleApplication::instanceStarted, qmlWindow, &QQuickWindow::hide);
    root->connect(&application, &SingleApplication::instanceStarted, qmlWindow, &QQuickWindow::show);
    root->connect(&application, &SingleApplication::instanceStarted, qmlWindow, &QQuickWindow::raise);
    root->connect(&application, &SingleApplication::instanceStarted, qmlWindow, &QQuickWindow::requestActivate);

    const int status = application.exec();
    return status;
}
