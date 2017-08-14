#include "systemtray.h"

SystemTray::SystemTray(QObject *parent) :
    QSystemTrayIcon(parent)
{
    connect(this, &SystemTray::activated, this, &SystemTray::onActivate);
}

void SystemTray::onActivate(QSystemTrayIcon::ActivationReason reason) {
    if(reason == QSystemTrayIcon::DoubleClick)
        emit doubleClicked();
}
