#include <QApplication>
#include <QDesktopWidget>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <stdlib.h>
#include <signal.h>
#include <QtGlobal>
#include <QtWidgets>
#include <QQuickWindow>
#include <QQuickStyle>
#include "screenshot.h"
#include "QZXing.h"

void handleExitSignal(int sig) {
  printf("Exiting due to signal %d\n", sig);
  QCoreApplication::quit();
}

void setupSignalHandlers() {
#ifdef _WIN32
  signal(SIGINT, handleExitSignal);
#else
  struct sigaction sa;
  sa.sa_handler = handleExitSignal;
  sigset_t signal_mask;
  sigemptyset(&signal_mask);
  sa.sa_mask = signal_mask;
  sa.sa_flags = 0;
  sigaction(SIGINT, &sa, nullptr);
#endif
}

int main(int argc, char *argv[])
{
    setupSignalHandlers();

    // Don't write .pyc files.
    qputenv("PYTHONDONTWRITEBYTECODE", "1");

    // Use Material "Dense" variant, recommended for Desktop
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");

    // QR scanner
    QZXing::registerQMLTypes();

    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication application(argc, argv);
    application.setApplicationName("Yubico Authenticator");
    application.setApplicationVersion(APP_VERSION);
    application.setOrganizationName("Yubico");
    application.setOrganizationDomain("com.yubico");

    // Get x and y coordinates of all monitors
    QVariantList monitorAreas;
    for (QScreen* screen : QGuiApplication::screens())  {
        QRect monitorArea = screen->geometry();

        QVariantMap coordinates;

        coordinates.insert("xMin", monitorArea.x());
        coordinates.insert("xMax", monitorArea.x() + monitorArea.width());
        coordinates.insert("yMin", monitorArea.y());
        coordinates.insert("yMax", monitorArea.y() + monitorArea.height());

        monitorAreas << coordinates;
    }

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
    engine.rootContext()->setContextProperty("monitorAreas", monitorAreas);
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

    const int status = application.exec();
    return status;
}
