#ifndef I18N_H
#define I18N_H
#include <QObject>
#include <QTranslator>
#include <QMap>
#include <QCoreApplication>
#include <QQmlApplicationEngine>
#include <QLocale>
#include <QDebug>

class i18n: public QObject {
    Q_OBJECT

public:
    i18n(QQmlEngine *engine) {
        _translator = new QTranslator(this);
        _engine = engine;
    }

    Q_INVOKABLE void retranslate(QString language) {
        if(language == "") {
            QString name = QLocale().name();
            name.truncate(name.indexOf("_"));
            language = name;
        }
        if (!_translator->isEmpty()) {
            qApp->removeTranslator(_translator);
        }
        if (!_translator->load(QStringLiteral(":/i18n/%1.qm").arg(language)) && language != "en") {
            qDebug() << QString("Failed to load translation file (%1), falling back to English").arg(language);
        }
        qApp->installTranslator(_translator);
        _engine->retranslate();
        emit languageChanged();
    }

signals:
    void languageChanged();

private:
    QTranslator *_translator;
    QQmlEngine *_engine;
};

#endif // I18N_H
