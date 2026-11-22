#pragma once
#include "protocol/ProtocolHandler.h"
#include "protocol/MiracastHandler.h"
#include <QObject>
#include <QProcess>
#include <QString>
#include <memory>
#include <string>

namespace airshow {

class AppSettings;
class ConnectionBridge;
class MediaPipeline;
class SecurityManager;

// Bridge that integrates the native Windows.Media.Miracast receiver helper
// (ComSSUMiracastHelper.exe) with ComSSUCast via QProcess and JSON lines over
// stdout/stdin.
//
// On Windows (#ifdef _WIN32):
//   - Launches ComSSUMiracastHelper.exe at startup.
//   - Defers AirShow's built-in MS-MICE MiracastHandler so there is NO port 7250
//     conflict with Windows' native Wireless Display service.
//   - If ComSSUMiracastHelper.exe reports that Windows.Media.Miracast is unavailable
//     (e.g. missing Wi-Fi Direct hardware or App.WirelessDisplay.Connect capability),
//     automatically falls back to starting the built-in MS-MICE MiracastHandler.
//   - Integrates ConnectionCreated / MediaSourceCreated / Disconnected events with
//     SecurityManager (ApprovalDialog.qml) and ConnectionBridge (HUD).
class WindowsMiracastBridge : public QObject, public ProtocolHandler {
    Q_OBJECT
public:
    WindowsMiracastBridge(ConnectionBridge* connectionBridge,
                          SecurityManager* securityManager,
                          AppSettings* settings,
                          std::unique_ptr<MiracastHandler> fallbackHandler,
                          QObject* parent = nullptr);
    ~WindowsMiracastBridge() override;

    // ProtocolHandler interface
    bool        start() override;
    void        stop() override;
    std::string name() const override { return "windows-miracast"; }
    bool        isRunning() const override { return m_running; }
    void        setMediaPipeline(MediaPipeline* pipeline) override;

    bool        isNativeActive() const { return m_nativeActive; }
    bool        isFallbackActive() const;

    // Locate ComSSUMiracastHelper.exe beside the running binary or build tree.
    static QString findHelperExecutable();

private slots:
    void onHelperReadyReadStdout();
    void onHelperReadyReadStderr();
    void onHelperErrorOccurred(QProcess::ProcessError error);
    void onHelperFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
    void processJsonLine(const QByteArray& line);
    void sendJsonCommand(const QByteArray& jsonLine);
    void sendApprovalDecision(const QString& requestId, bool approved);
    void startFallbackMice(const QString& reason);

    ConnectionBridge*                m_connectionBridge = nullptr;
    SecurityManager*                 m_securityManager  = nullptr;
    AppSettings*                     m_settings         = nullptr;
    std::unique_ptr<MiracastHandler> m_fallbackHandler;

    QProcess*                        m_process          = nullptr;
    QByteArray                       m_stdoutBuffer;
    bool                             m_running          = false;
    bool                             m_stopping         = false;
    bool                             m_nativeActive     = false;
    bool                             m_fallbackStarted  = false;
};

} // namespace airshow
