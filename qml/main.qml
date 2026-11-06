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

    // Top-Right Quick Action Button Row (Touch-friendly for 85" Flat Panels)
    Row {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 20
            rightMargin: 20
        }
        spacing: 12
        // Always maintain subtle visibility on touchscreen kiosk displays (opacity 0.4 at rest, 1.0 on active touch/hover)
        opacity: (mouseTracker.controlsHovered || !connectionBridge.connected) ? 0.95 : 0.4

        Behavior on opacity { NumberAnimation { duration: 200 } }

        // About Button (ℹ️)
        Item {
            id: aboutIconBtn
            width: 48
            height: 48

            Rectangle {
                anchors.fill: parent
                color: aboutMouse.containsMouse ? "#00A8E8" : "#B30A1426"
                border.color: "#00A8E8"
                border.width: 1
                radius: 24
            }

            Text {
                anchors.centerIn: parent
                text: "\u2139\uFE0F" // ℹ️
                color: "white"
                font.pixelSize: 18
                font.family: "sans-serif"
            }

            MouseArea {
                id: aboutMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: aboutDialog.open()
            }
        }

        // Fullscreen Toggle Button (⛶)
        Item {
            id: fullscreenButton
            width: 48
            height: 48

            Rectangle {
                anchors.fill: parent
                color: fsMouseArea.containsMouse ? "#00A8E8" : "#B30A1426"
                border.color: "#1E3A5F"
                border.width: 1
                radius: 24
            }

            Text {
                anchors.centerIn: parent
                text: "\u26F6"
                color: "white"
                font.pixelSize: 22
                font.family: "sans-serif"
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
            }
        }

        // Close / Exit Application Button (✕)
        Item {
            id: closeButton
            width: 48
            height: 48

            Rectangle {
                anchors.fill: parent
                color: closeMouseArea.containsMouse ? "#EF4444" : "#B30A1426"
                border.color: "#EF4444"
                border.width: 1
                radius: 24
            }

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: "\u2715"
                color: "white"
                font.pixelSize: 20
                font.family: "sans-serif"
            }

            MouseArea {
                id: closeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.quit()
            }
        }
    }

    // Touch-Friendly Audio Mute / Unmute Button (Active during streams)
    Item {
        id: muteButton
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 28
        }
        width: muteLabel.width + 36
        height: 48
        visible: connectionBridge.connected && (mouseTracker.controlsHovered || opacity > 0)
        opacity: mouseTracker.controlsHovered ? 0.95 : 0.0

        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            anchors.fill: parent
            color: "#CC0F1A2E"
            border.color: "#00A8E8"
            border.width: 1
            radius: 24
        }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: audioBridge.muted ? "\uD83D\uDD07" : "\uD83D\uDD0A"
                font.pixelSize: 18
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                id: muteLabel
                text: audioBridge.muted ? "Unmute Audio" : "Mute Audio"
                color: "white"
                font.pixelSize: 16
                font.bold: true
                font.family: "sans-serif"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: audioBridge.setMuted(!audioBridge.muted)
        }
    }
}
