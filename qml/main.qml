import QtQuick
import QtQuick.Window
import QtQuick.Controls
import ComSSUCast 1.0

Window {
    id: root

    // Launches fullscreen by default on 85" 4K interactive flat panel displays
    visibility: Qt.application.arguments.indexOf("--windowed") !== -1
                ? Window.Windowed : Window.FullScreen
    width: 1920
    height: 1080
    color: "#050A14"
    title: "ComSSU — Wireless Display System"
    visible: true

    // VideoFrameSink receives RGBA frames from GStreamer appsink
    VideoFrameSink {
        id: videoItem
        objectName: "videoItem"
        anchors.fill: parent
        forceAspectRatio: true
    }

    // Idle / Welcome screen — visible when no sender device is streaming
    IdleScreen {
        id: idleScreenView
        anchors.fill: parent
        onRequestAbout: aboutDialog.open()
    }

    // Connection status HUD pill overlay
    HudOverlay {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // Interactive Authorization Dialog (Allow / Deny incoming devices)
    ApprovalDialog {
        anchors.fill: parent
    }

    // Dedicated About Dialog Modal
    AboutDialog {
        id: aboutDialog
        anchors.fill: parent
    }

    // Touch & Mouse tracker for hover controls
    MouseArea {
        id: mouseTracker
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true

        property bool controlsHovered: false

        onPositionChanged: {
            controlsHovered = true
            hideTimer.restart()
        }

        Timer {
            id: hideTimer
            interval: 4000
            onTriggered: mouseTracker.controlsHovered = false
        }
    }

    // ── TOP-RIGHT ACTION CONTROLS ──────────────────────────────────────────────
    // Clean, consistent circular buttons with white surfaces, blue accents, red exit
    Row {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 20
            rightMargin: 20
        }
        spacing: 12
        // Subtly visible on touchscreen kiosk displays; full opacity on hover/interaction
        opacity: (mouseTracker.controlsHovered || !connectionBridge.connected) ? 0.98 : 0.45

        Behavior on opacity { NumberAnimation { duration: 200 } }

        // 1. About Information Button (ℹ)
        Item {
            id: aboutIconBtn
            width: 46
            height: 46

            Rectangle {
                anchors.fill: parent
                radius: 23
                color: aboutMouse.pressed ? "#D0E8F8" : (aboutMouse.containsMouse ? "#E1F5FE" : "#FFFFFF")
                border.color: aboutMouse.containsMouse ? "#1565C0" : "#CFE2F3"
                border.width: 1.2

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "\u2139\uFE0F" // ℹ️
                    color: "#1565C0"
                    font.pixelSize: 17
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                }
            }

            MouseArea {
                id: aboutMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: aboutDialog.open()

                ToolTip.visible: containsMouse
                ToolTip.text: "About System"
                ToolTip.delay: 400
            }
        }

        // 2. Fullscreen Toggle Button (⛶)
        Item {
            id: fullscreenButton
            width: 46
            height: 46

            Rectangle {
                anchors.fill: parent
                radius: 23
                color: fsMouseArea.pressed ? "#D0E8F8" : (fsMouseArea.containsMouse ? "#E1F5FE" : "#FFFFFF")
                border.color: fsMouseArea.containsMouse ? "#1565C0" : "#CFE2F3"
                border.width: 1.2

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "\u26F6" // ⛶
                    color: "#1565C0"
                    font.pixelSize: 20
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                }
            }

            MouseArea {
                id: fsMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.visibility = root.visibility === Window.FullScreen
                        ? Window.Windowed
                        : Window.FullScreen
                }

                ToolTip.visible: containsMouse
                ToolTip.text: root.visibility === Window.FullScreen ? "Exit Fullscreen" : "Enter Fullscreen"
                ToolTip.delay: 400
            }
        }

        // 3. Close / Exit Button (✕) — Reserved Red Accent
        Item {
            id: closeButton
            width: 46
            height: 46

            Rectangle {
                anchors.fill: parent
                radius: 23
                color: closeMouseArea.pressed ? "#FCA5A5" : (closeMouseArea.containsMouse ? "#FEE2E2" : "#FFFFFF")
                border.color: closeMouseArea.containsMouse ? "#DC2626" : "#FECACA"
                border.width: 1.2

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1
                    text: "\u2715" // ✕
                    color: "#DC2626" // Pure alert red
                    font.pixelSize: 18
                    font.bold: true
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                }
            }

            MouseArea {
                id: closeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.quit()

                ToolTip.visible: containsMouse
                ToolTip.text: "Close Application"
                ToolTip.delay: 400
            }
        }
    }

    // ── ACTIVE STREAM AUDIO MUTE CONTROL ───────────────────────────────────────
    Item {
        id: muteButton
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 28
        }
        width: muteLabel.width + 40
        height: 46
        visible: connectionBridge.connected && (mouseTracker.controlsHovered || opacity > 0)
        opacity: mouseTracker.controlsHovered ? 0.98 : 0.0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            anchors.fill: parent
            radius: 23
            color: muteMouse.containsMouse ? "#E1F5FE" : "#FFFFFF"
            border.color: "#29B6F6"
            border.width: 1.2
        }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: audioBridge.muted ? "\uD83D\uDD07" : "\uD83D\uDD0A"
                font.pixelSize: 17
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                id: muteLabel
                text: audioBridge.muted ? "Unmute Audio" : "Mute Audio"
                color: "#1565C0"
                font.pixelSize: 15
                font.bold: true
                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: muteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: audioBridge.setMuted(!audioBridge.muted)
        }
    }
}
