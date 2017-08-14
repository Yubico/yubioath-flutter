#ifndef SYSTEMTRAY_H
#define SYSTEMTRAY_H
#include <QSystemTrayIcon>

class SystemTray : public QSystemTrayIcon
{
    Q_OBJECT
public:
    explicit SystemTray(QObject *parent = 0);
signals:
    void doubleClicked();
private slots:
    void onActivate(QSystemTrayIcon::ActivationReason reason);
};

#endif // SYSTEMTRAY_H
