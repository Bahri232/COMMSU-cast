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

    // Modal background overlay
    Rectangle {
        anchors.fill: parent
        color: "#B3030712"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }
    }

    // Centered Dialog Card (Optimized for 85" interactive display touch)
    Rectangle {
        id: card
        width: Math.min(600, parent.width - 48)
        height: Math.min(380, parent.height - 48)
        anchors.centerIn: parent
        radius: 18
        color: "#0F1A2E"
        border.color: "#00A8E8"
        border.width: 2

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
                spacing: 12
                Text {
                    text: "\uD83D\uDEE1\uFE0F" // 🛡️
                    font.pixelSize: 28
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Incoming Connection Request"
                    color: "#FFFFFF"
                    font.pixelSize: 22
                    font.bold: true
                    font.family: "sans-serif"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Device Name & Protocol Card
            Rectangle {
                width: parent.width
                height: 72
                radius: 12
                color: "#16253D"
                border.color: "#22395D"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: {
                            var proto = connectionBridge.pendingProtocol
                            if (proto === "AirPlay") return "\uD83C\uDF4E"
                            if (proto === "Cast") return "\uD83D\uDCFA"
                            if (proto === "Miracast") return "\uD83D\uDCBB"
                            return "\uD83D\uDCF1"
                        }
                        font.pixelSize: 28
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: connectionBridge.pendingDeviceName.length > 0
                                  ? connectionBridge.pendingDeviceName
                                  : "Unknown Device"
                            color: "#FFFFFF"
                            font.pixelSize: 19
                            font.bold: true
                            font.family: "sans-serif"
                        }

                        Text {
                            text: "Protocol: " + connectionBridge.pendingProtocol
                            color: "#38BDF8"
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "sans-serif"
                        }
                    }
                }
            }

            // PIN Reference Badge alongside request prompt
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Text {
                    text: "Security PIN:"
                    color: "#94A3B8"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: pinText.width + 16
                    height: 28
                    radius: 6
                    color: "#0B1322"
                    border.color: "#00A8E8"
                    border.width: 1

                    Text {
                        id: pinText
                        anchors.centerIn: parent
                        text: appSettings.pin
                        color: "#38BDF8"
                        font.pixelSize: 15
                        font.bold: true
                        font.letterSpacing: 3
                    }
                }

                Text {
                    text: "• Allow projection to interactive screen?"
                    color: "#CBD5E1"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { width: 1; height: 6 }

            // Large Touch-Friendly Action Buttons
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                // Allow Button
                Rectangle {
                    id: allowBtn
                    width: 200
                    height: 56
                    radius: 12
                    color: allowMouse.containsMouse ? "#059669" : "#10B981"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "\u2714" // ✔
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text {
                            text: "Allow Screen"
                            color: "white"
                            font.pixelSize: 17
                            font.bold: true
                            font.family: "sans-serif"
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
                    width: 160
                    height: 56
                    radius: 12
                    color: denyMouse.containsMouse ? "#DC2626" : "#EF4444"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "\u2716" // ✖
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Text {
                            text: "Deny"
                            color: "white"
                            font.pixelSize: 17
                            font.bold: true
                            font.family: "sans-serif"
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
