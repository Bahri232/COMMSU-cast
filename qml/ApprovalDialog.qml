import QtQuick
import QtQuick.Controls

Item {
    id: approvalDialog
    anchors.fill: parent

    visible: opacity > 0
    opacity: connectionBridge.approvalPending ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    // Modal background overlay (soft dimmed translucent backdrop)
    Rectangle {
        anchors.fill: parent
        color: "#660F172A"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }
    }

    // Centered Authorization Card (Clean white institutional surface)
    Rectangle {
        id: card
        width: Math.min(600, parent.width - 48)
        height: Math.min(380, parent.height - 48)
        anchors.centerIn: parent
        radius: 18
        color: "#FFFFFF"
        border.color: "#CFE2F3"
        border.width: 1.5

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 56
            spacing: 16

            // Header Row: Shield Icon & Title
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Text {
                    text: "\uD83D\uDEE1\uFE0F" // 🛡️
                    font.pixelSize: 26
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Incoming Connection Request"
                    color: "#172B45" // Dark navy
                    font.pixelSize: 21
                    font.bold: true
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Device Name & Protocol Card
            Rectangle {
                width: parent.width
                height: 74
                radius: 12
                color: "#F4F9FD" // Soft blue-white
                border.color: "#E2E8F0"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 14

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: "#E1F5FE"
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            source: {
                                var proto = connectionBridge.pendingProtocol
                                if (proto === "AirPlay") return "qrc:/assets/apple_icon.png"
                                if (proto === "Miracast") return "qrc:/assets/windows_icon.png"
                                return "qrc:/assets/android_icon.png"
                            }
                            width: 26
                            height: 26
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: connectionBridge.pendingDeviceName.length > 0
                                  ? connectionBridge.pendingDeviceName
                                  : "Unknown Device"
                            color: "#172B45"
                            font.pixelSize: 18
                            font.bold: true
                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                        }

                        Text {
                            text: "Protocol: " + connectionBridge.pendingProtocol
                            color: "#1565C0"
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                        }
                    }
                }
            }

            // PIN Reference Badge alongside request prompt
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Text {
                    text: "Session PIN:"
                    color: "#64748B"
                    font.pixelSize: 14
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: pinText.width + 16
                    height: 28
                    radius: 6
                    color: "#EBF5FB"
                    border.color: "#BEE3F8"
                    border.width: 1

                    Text {
                        id: pinText
                        anchors.centerIn: parent
                        text: appSettings.pin
                        color: "#1565C0"
                        font.pixelSize: 15
                        font.bold: true
                        font.letterSpacing: 2
                        font.family: "Consolas, monospace"
                    }
                }

                Text {
                    text: "• Allow projection to interactive screen?"
                    color: "#334155"
                    font.pixelSize: 14
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { width: 1; height: 6 }

            // Touch-Friendly Action Buttons
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18

                // Allow Button
                Rectangle {
                    id: allowBtn
                    width: 190
                    height: 52
                    radius: 12
                    color: allowMouse.containsMouse ? "#059669" : "#10B981"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "\u2714" // ✔
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Text {
                            text: "Allow Screen"
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                        }
                    }

                    MouseArea {
                        id: allowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            securityManager.resolveApproval(connectionBridge.pendingRequestId, true)
                            connectionBridge.clearApprovalRequest()
                        }
                    }
                }

                // Deny Button
                Rectangle {
                    id: denyBtn
                    width: 150
                    height: 52
                    radius: 12
                    color: denyMouse.containsMouse ? "#FEE2E2" : "#FFFFFF"
                    border.color: "#DC2626"
                    border.width: 1.5

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "\u2716" // ✖
                            color: "#DC2626"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            text: "Deny"
                            color: "#DC2626"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                        }
                    }

                    MouseArea {
                        id: denyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            securityManager.resolveApproval(connectionBridge.pendingRequestId, false)
                            connectionBridge.clearApprovalRequest()
                        }
                    }
                }
            }
        }
    }
}
