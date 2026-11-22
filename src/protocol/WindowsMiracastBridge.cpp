#include "protocol/WindowsMiracastBridge.h"
#include "ui/ConnectionBridge.h"
#include "security/SecurityManager.h"
#include "settings/AppSettings.h"
#include "pipeline/MediaPipeline.h"

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

namespace airshow {

WindowsMiracastBridge::WindowsMiracastBridge(
    ConnectionBridge* connectionBridge,
    SecurityManager* securityManager,
    AppSettings* settings,
    std::unique_ptr<MiracastHandler> fallbackHandler,
    QObject* parent)
    : QObject(parent)
    , m_connectionBridge(connectionBridge)
    , m_securityManager(securityManager)
    , m_settings(settings)
    , m_fallbackHandler(std::move(fallbackHandler))
{}

WindowsMiracastBridge::~WindowsMiracastBridge() {
    stop();
}

void WindowsMiracastBridge::setMediaPipeline(MediaPipeline* pipeline) {
    if (m_fallbackHandler) {
        m_fallbackHandler->setMediaPipeline(pipeline);
    }
}

bool WindowsMiracastBridge::isFallbackActive() const {
    return m_fallbackStarted && m_fallbackHandler && m_fallbackHandler->isRunning();
}

// static
QString WindowsMiracastBridge::findHelperExecutable() {
    const QString appDir = QCoreApplication::applicationDirPath();
    const QStringList candidates = {
        appDir + QStringLiteral("/ComSSUMiracastHelper.exe"),
        appDir + QStringLiteral("/tools/miracast-helper/ComSSUMiracastHelper.exe"),
        QDir::currentPath() + QStringLiteral("/ComSSUMiracastHelper.exe"),
        QDir::currentPath() + QStringLiteral("/tools/miracast-helper/ComSSUMiracastHelper.exe"),
    };
    for (const QString& candidate : candidates) {
        if (QFileInfo::exists(candidate)) {
            return QFileInfo(candidate).absoluteFilePath();
        }
    }
    return {};
}

bool WindowsMiracastBridge::start() {
    if (m_running) return true;
    m_stopping        = false;
    m_nativeActive    = false;
    m_fallbackStarted = false;
    m_stdoutBuffer.clear();

#ifdef _WIN32
    const QString helperPath = findHelperExecutable();
    if (helperPath.isEmpty()) {
        m_running = true;
        startFallbackMice(QStringLiteral("ComSSUMiracastHelper.exe not found next to ComSSUCast.exe"));
        return isFallbackActive();
    }

    const QString friendlyName = m_settings
        ? m_settings->receiverName()
        : QStringLiteral("CS Society Display");

    // Determine authorization mode aligned with SecurityManager policy
    QString authMode = QStringLiteral("confirm");
    if (m_settings) {
        if (m_settings->requireApproval()) {
            authMode = QStringLiteral("confirm");
        } else if (m_settings->pinEnabled()) {
            authMode = QStringLiteral("pin_if_requested");
        } else {
            authMode = QStringLiteral("none");
        }
    }

    const QStringList args = {
        QStringLiteral("--friendly-name"), friendlyName,
        QStringLiteral("--model-name"),    QStringLiteral("ComSSU Cast"),
        QStringLiteral("--model-number"),  QStringLiteral("1.0.0"),
        QStringLiteral("--auth"),          authMode,
    };

    m_process = new QProcess(this);
    connect(m_process, &QProcess::readyReadStandardOutput,
            this, &WindowsMiracastBridge::onHelperReadyReadStdout);
    connect(m_process, &QProcess::readyReadStandardError,
            this, &WindowsMiracastBridge::onHelperReadyReadStderr);
    connect(m_process, &QProcess::errorOccurred,
            this, &WindowsMiracastBridge::onHelperErrorOccurred);
    connect(m_process,
            qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, &WindowsMiracastBridge::onHelperFinished);

    qInfo("WindowsMiracastBridge: launching native helper '%s' as '%s'",
          qPrintable(helperPath), qPrintable(friendlyName));
    m_running = true;
    m_process->start(helperPath, args);
    return true;
#else
    m_running = true;
    startFallbackMice(QStringLiteral("non-Windows platform"));
    return isFallbackActive();
#endif
}

void WindowsMiracastBridge::stop() {
    if (!m_running) return;
    m_stopping     = true;
    m_running      = false;
    m_nativeActive = false;

    if (m_process) {
        m_process->disconnect(this);
        if (m_process->state() != QProcess::NotRunning) {
            sendJsonCommand(QByteArrayLiteral("{\"command\":\"shutdown\"}\n"));
            m_process->waitForBytesWritten(300);
            m_process->closeWriteChannel();
            if (!m_process->waitForFinished(1500)) {
                m_process->kill();
                m_process->waitForFinished(500);
            }
        }
        delete m_process;
        m_process = nullptr;
    }

    if (m_fallbackHandler && m_fallbackHandler->isRunning()) {
        m_fallbackHandler->stop();
    }
    m_fallbackStarted = false;
    m_stdoutBuffer.clear();
    qDebug("WindowsMiracastBridge: stopped");
}

void WindowsMiracastBridge::onHelperReadyReadStdout() {
    if (!m_process) return;
    m_stdoutBuffer.append(m_process->readAllStandardOutput());

    int newlineIdx = -1;
    while ((newlineIdx = m_stdoutBuffer.indexOf('\n')) >= 0) {
        QByteArray line = m_stdoutBuffer.left(newlineIdx).trimmed();
        m_stdoutBuffer.remove(0, newlineIdx + 1);
        if (!line.isEmpty()) {
            processJsonLine(line);
        }
    }
}

void WindowsMiracastBridge::onHelperReadyReadStderr() {
    if (!m_process) return;
    const QByteArray err = m_process->readAllStandardError().trimmed();
    if (!err.isEmpty()) {
        qWarning("ComSSUMiracastHelper stderr: %s", err.constData());
    }
}

void WindowsMiracastBridge::onHelperErrorOccurred(QProcess::ProcessError error) {
    if (m_stopping) return;
    qWarning("WindowsMiracastBridge: helper process error (%d): %s",
             static_cast<int>(error),
             m_process ? qPrintable(m_process->errorString()) : "unknown");
    if (!m_nativeActive && !m_fallbackStarted) {
        startFallbackMice(QStringLiteral("helper process failed to start"));
    }
}

void WindowsMiracastBridge::onHelperFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    if (m_stopping) return;

    // Drain any remaining stdout lines before handling exit
    onHelperReadyReadStdout();

    qDebug("WindowsMiracastBridge: helper exited (code=%d, status=%d)",
           exitCode, static_cast<int>(exitStatus));

    if (m_nativeActive) {
        m_nativeActive = false;
        if (m_connectionBridge && m_connectionBridge->protocol().compare(
                QStringLiteral("Miracast"), Qt::CaseInsensitive) == 0) {
            m_connectionBridge->setConnected(false);
        }
    }

    if (!m_fallbackStarted) {
        startFallbackMice(QStringLiteral("native helper exited without active session"));
    }
}

void WindowsMiracastBridge::processJsonLine(const QByteArray& line) {
    QJsonParseError parseError{};
    const QJsonDocument doc = QJsonDocument::fromJson(line, &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        qDebug("ComSSUMiracastHelper: %s", line.constData());
        return;
    }

    const QJsonObject obj   = doc.object();
    const QString     event = obj.value(QStringLiteral("event")).toString();

    if (event == QStringLiteral("status")) {
        const bool    available  = obj.value(QStringLiteral("available")).toBool(false);
        const QString statusStr  = obj.value(QStringLiteral("status")).toString();
        const QString wifiStatus = obj.value(QStringLiteral("wifiStatus")).toString();
        const QString reason     = obj.value(QStringLiteral("reason")).toString();

        if (available && statusStr == QStringLiteral("listening")) {
            m_nativeActive = true;
            // Ensure fallback MS-MICE listener is NOT occupying TCP 7250
            if (m_fallbackHandler && m_fallbackHandler->isRunning()) {
                m_fallbackHandler->stop();
                m_fallbackStarted = false;
            }
            qInfo("WindowsMiracastBridge: native Windows.Media.Miracast receiver listening as '%s' "
                  "(WiFiStatus=%s, MS-MICE port 7250 reserved for OS receiver)",
                  qPrintable(obj.value(QStringLiteral("friendlyName")).toString()),
                  qPrintable(wifiStatus));
        } else {
            m_nativeActive = false;
            startFallbackMice(reason.isEmpty() ? statusStr : reason);
        }
    }
    else if (event == QStringLiteral("connection_created")) {
        const QString requestId  = obj.value(QStringLiteral("requestId")).toString();
        const QString deviceName = obj.value(QStringLiteral("deviceName")).toString(
            QStringLiteral("Wireless Display Device"));
        const QString macAddress = obj.value(QStringLiteral("macAddress")).toString();
        const QString pin        = obj.value(QStringLiteral("pin")).toString();

        qInfo("WindowsMiracastBridge: incoming Miracast connection from '%s' (MAC=%s, PIN=%s)",
              qPrintable(deviceName), qPrintable(macAddress), qPrintable(pin));

        if (!pin.isEmpty() && m_settings) {
            m_settings->setPin(pin);
        }

        if (m_securityManager) {
            const QString deviceId = macAddress.isEmpty() ? deviceName : macAddress;
            m_securityManager->checkConnectionAsync(
                deviceName,
                QStringLiteral("Miracast"),
                deviceId,
                [this, requestId](bool approved) {
                    sendApprovalDecision(requestId, approved);
                });
        } else {
            sendApprovalDecision(requestId, true);
        }
    }
    else if (event == QStringLiteral("media_source_created")) {
        const QString deviceName = obj.value(QStringLiteral("deviceName")).toString(
            QStringLiteral("Wireless Display Device"));
        qInfo("WindowsMiracastBridge: Miracast streaming started from '%s'",
              qPrintable(deviceName));
        if (m_connectionBridge) {
            m_connectionBridge->setConnected(true, deviceName, QStringLiteral("Miracast"));
        }
    }
    else if (event == QStringLiteral("disconnected")) {
        const QString deviceName = obj.value(QStringLiteral("deviceName")).toString();
        qInfo("WindowsMiracastBridge: Miracast session ended (%s)", qPrintable(deviceName));
        if (m_connectionBridge) {
            m_connectionBridge->setConnected(false);
        }
    }
    else if (event == QStringLiteral("error")) {
        qWarning("WindowsMiracastBridge: helper error at stage '%s': %s",
                 qPrintable(obj.value(QStringLiteral("stage")).toString()),
                 qPrintable(obj.value(QStringLiteral("message")).toString()));
    }
}

void WindowsMiracastBridge::sendJsonCommand(const QByteArray& jsonLine) {
    if (!m_process || m_process->state() != QProcess::Running) return;
    m_process->write(jsonLine);
}

void WindowsMiracastBridge::sendApprovalDecision(const QString& requestId, bool approved) {
    QJsonObject cmd;
    cmd.insert(QStringLiteral("command"),   QStringLiteral("resolve_approval"));
    cmd.insert(QStringLiteral("requestId"), requestId);
    cmd.insert(QStringLiteral("approved"),  approved);
    QByteArray line = QJsonDocument(cmd).toJson(QJsonDocument::Compact);
    line.append('\n');
    sendJsonCommand(line);
}

void WindowsMiracastBridge::startFallbackMice(const QString& reason) {
    if (m_stopping || m_fallbackStarted) return;
    m_fallbackStarted = true;
    qWarning("WindowsMiracastBridge: native Windows.Media.Miracast unavailable (%s) — "
             "falling back to built-in MS-MICE listener on TCP port 7250",
             qPrintable(reason));
    if (m_fallbackHandler) {
        m_fallbackHandler->start();
    }
}

} // namespace airshow
