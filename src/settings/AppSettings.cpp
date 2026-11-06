#include "settings/AppSettings.h"
#include <QSettings>
#include <QSysInfo>
#include <QRandomGenerator>

namespace airshow {

AppSettings::AppSettings() = default;

// ---------------------------------------------------------------------------
// Receiver identity
// ---------------------------------------------------------------------------

QString AppSettings::receiverName() const {
    QSettings s;
    QString name = s.value(QStringLiteral("receiver/name"), defaultReceiverName()).toString();
    if (name.isEmpty() || name == QStringLiteral("AirShow")) {
        return defaultReceiverName();
    }
    return name;
}

void AppSettings::setReceiverName(const QString& name) {
    QSettings s;
    s.setValue(QStringLiteral("receiver/name"), name);
    s.sync();
}

bool AppSettings::isFirstLaunch() const {
    QSettings s;
    return !s.value(QStringLiteral("app/firstLaunchComplete"), false).toBool();
}

void AppSettings::setFirstLaunchComplete() {
    QSettings s;
    s.setValue(QStringLiteral("app/firstLaunchComplete"), true);
    s.sync();
}

QString AppSettings::defaultReceiverName() {
    return QStringLiteral("CS Society Display");
}

// ---------------------------------------------------------------------------
// Security settings (Phase 7 / D-11)
// ---------------------------------------------------------------------------

bool AppSettings::requireApproval() const {
    QSettings s;
    return s.value(QStringLiteral("security/requireApproval"), true).toBool();
}

void AppSettings::setRequireApproval(bool v) {
    QSettings s;
    s.setValue(QStringLiteral("security/requireApproval"), v);
    s.sync();
}

bool AppSettings::pinEnabled() const {
    QSettings s;
    return s.value(QStringLiteral("security/pinEnabled"), true).toBool();
}

void AppSettings::setPinEnabled(bool v) {
    QSettings s;
    s.setValue(QStringLiteral("security/pinEnabled"), v);
    s.sync();
}

QString AppSettings::pin() const {
    QSettings s;
    QString currentPin = s.value(QStringLiteral("security/pin"), QString()).toString();
    if (currentPin.length() != 4) {
        currentPin = const_cast<AppSettings*>(this)->generateNewPin();
    }
    return currentPin;
}

void AppSettings::setPin(const QString& v) {
    QSettings s;
    s.setValue(QStringLiteral("security/pin"), v);
    s.sync();
}

QString AppSettings::generateNewPin() {
    int randomVal = QRandomGenerator::global()->bounded(1000, 10000);
    QString newPin = QString::number(randomVal);
    setPin(newPin);
    return newPin;
}

QStringList AppSettings::trustedDevices() const {
    QSettings s;
    return s.value(QStringLiteral("security/trustedDevices"), QStringList()).toStringList();
}

void AppSettings::addTrustedDevice(const QString& deviceId) {
    QSettings s;
    QStringList list = s.value(QStringLiteral("security/trustedDevices"), QStringList()).toStringList();
    if (!list.contains(deviceId)) {
        list.append(deviceId);
        s.setValue(QStringLiteral("security/trustedDevices"), list);
        s.sync();
    }
}

void AppSettings::removeTrustedDevice(const QString& deviceId) {
    QSettings s;
    QStringList list = s.value(QStringLiteral("security/trustedDevices"), QStringList()).toStringList();
    if (list.removeAll(deviceId) > 0) {
        s.setValue(QStringLiteral("security/trustedDevices"), list);
        s.sync();
    }
}

void AppSettings::clearTrustedDevices() {
    QSettings s;
    s.setValue(QStringLiteral("security/trustedDevices"), QStringList());
    s.sync();
}

} // namespace airshow
