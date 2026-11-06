import QtQuick
import QtQuick.Controls

Item {
    id: idleScreen
    anchors.fill: parent

    signal requestAbout()

    visible: !connectionBridge.connected

    // Deep modern dark background for high-contrast presentation on 85" displays
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#060B14" }
            GradientStop { position: 0.5; color: "#0A1322" }
            GradientStop { position: 1.0; color: "#080F1D" }
        }
    }

    // Main layout container
    Column {
        anchors.fill: parent
        anchors.margins: 36
        spacing: 24

        // ── TOP HEADER: Logo, Title, Subtitle & Status Badge ────────────────
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Image {
                id: logo
                source: "qrc:/assets/comssu_logo.png"
                width: 130
                height: 130
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "ComSSU — Wireless Display System"
                color: "#FFFFFF"
                font.pixelSize: 38
                font.bold: true
                font.family: "sans-serif"
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Computer Science Students' Society (ComSSU) | University of Makeni"
                color: "#38BDF8"
                font.pixelSize: 20
                font.bold: true
                font.family: "sans-serif"
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Broadcast Name & Status Pill
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Rectangle {
                    width: broadcastRow.width + 24
                    height: 34
                    radius: 17
                    color: "#132138"
                    border.color: "#00A8E8"
                    border.width: 1

                    Row {
                        id: broadcastRow
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: "#10B981"
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on opacity {
                                running: idleScreen.visible
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            text: "Display Name: "
                            color: "#94A3B8"
                            font.pixelSize: 15
                            font.family: "sans-serif"
                        }

                        Text {
                            text: appSettings.receiverName
                            color: "#FFFFFF"
                            font.pixelSize: 15
                            font.bold: true
                            font.family: "sans-serif"
                        }
                    }
                }
            }
        }

        // ── MIDDLE SECTION: Instructions (Left) + Prominent PIN Station (Right) ──
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, 1360)
            spacing: 28

            // --- Platform Connection Cards ---
            Row {
                id: cardsRow
                spacing: 16
                width: parent.width - pinStation.width - 28

                // 1. Apple AirPlay
                Rectangle {
                    width: (parent.width - 32) / 3
                    height: 250
                    radius: 16
                    color: "#0F1A2E"
                    border.color: "#1E2E4A"
                    border.width: 1.5

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Row {
                            spacing: 10
                            Text {
                                text: "\uD83C\uDF4E" // 🍎
                                font.pixelSize: 24
                            }
                            Column {
                                Text {
                                    text: "Apple Devices"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                Text {
                                    text: "iOS / iPadOS / macOS"
                                    color: "#64748B"
                                    font.pixelSize: 12
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: "#1E293B" }

                        Column {
                            spacing: 8
                            width: parent.width

                            Text {
                                text: "1. Open <b>Control Center</b>"
                                color: "#CBD5E1"
                                font.pixelSize: 14
                                textFormat: Text.RichText
                            }
                            Text {
                                text: "2. Tap <b>Screen Mirroring</b>"
                                color: "#CBD5E1"
                                font.pixelSize: 14
                                textFormat: Text.RichText
                            }
                            Text {
                                text: "3. Select <font color='#38BDF8'><b>CS Society Display</b></font>"
                                color: "#CBD5E1"
                                font.pixelSize: 14
                                textFormat: Text.RichText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }
                }

                // 2. Windows Miracast
                Rectangle {
                    width: (parent.width - 32) / 3
                    height: 250
                    radius: 16
                    color: "#0F1A2E"
                    border.color: "#1E2E4A"
                    border.width: 1.5

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Row {
                            spacing: 10
                            Text {
                                text: "\uD83D\uDCBB" // 💻
                                font.pixelSize: 24
                            }
                            Column {
                                Text {
                                    text: "Windows PC"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                Text {
                                    text: "Windows 10 / 11"
                                    color: "#64748B"
                                    font.pixelSize: 12
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: "#1E293B" }

                        Column {
                            spacing: 8
                            width: parent.width

                            Text {
                                text: "1. Press <font color='#38BDF8'><b>Win + K</b></font> (Cast)"
                                color: "#CBD5E1"
                                font.pixelSize: 14
                                textFormat: Text.RichText
                            }
                            Text {
                                text: "2. Select <font color='#38BDF8'><b>CS Society Display</b></font>"
                                color: "#CBD5E1"
                                font.pixelSize: 14
                                textFormat: Text.RichText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                            Text {
                                text: "3. Enter PIN if prompted"
                                color: "#CBD5E1"
                                font.pixelSize: 14
                                textFormat: Text.RichText
                            }
                        }
                    }
                }

                // 3. Android & Google Cast
                Rectangle {
                    width: (parent.width - 32) / 3
                    height: 250
                    radius: 16
                    color: "#0F1A2E"
                    border.color: "#1E2E4A"
                    border.width: 1.5

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Row {
                            spacing: 10
                            Text {
                                text: "\uD83D\uDCFA" // 📺
                                font.pixelSize: 24
                            }
                            Column {
                                Text {
                                    text: "Android / Chrome"
                                    color: "#FFFFFF"
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                                Text {
                                    text: "Google Cast / Smart View"
                                    color: "#64748B"
                                    font.pixelSize: 12
                                }
                            }
                        }

                        Rectangle { width: parent.width; height: 1; color: "#1E293B" }

                        Column {
                            spacing: 8
                            width: parent.width

                            Text {
                                text: "1. Open Quick Settings or Chrome"
                                color: "#CBD5E1"
                                font.pixelSize: 14
                            }
                            Text {
                                text: "2. Tap <b>Cast</b> / <b>Smart View</b>"
                                color: "#CBD5E1"
                                font.pixelSize: 14
                                textFormat: Text.RichText
                            }
                            Text {
                                text: "3. Select <font color='#38BDF8'><b>CS Society Display</b></font>"
                                color: "#CBD5E1"
                                font.pixelSize: 14
                                textFormat: Text.RichText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }
                }
            }

            // --- High-Contrast Security PIN Station ---
            Rectangle {
                id: pinStation
                width: 380
                height: 250
                radius: 18
                color: "#0A172D"
                border.color: "#00A8E8"
                border.width: 2

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    width: parent.width - 36

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        Text {
                            text: "\uD83D\uDD12" // 🔒
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "SECURITY SESSION PIN"
                            color: "#94A3B8"
                            font.pixelSize: 14
                            font.bold: true
                            font.letterSpacing: 2
                            font.family: "sans-serif"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Huge glowing 4-digit PIN legible across a large lecture hall
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: 90
                        radius: 12
                        color: "#070E1C"
                        border.color: "#1E3A5F"
                        border.width: 1

                        Text {
                            id: pinDisplay
                            anchors.centerIn: parent
                            text: appSettings.pin && appSettings.pin.length > 0 ? appSettings.pin : "----"
                            color: "#38BDF8"
                            font.pixelSize: 62
                            font.bold: true
                            font.family: "monospace"
                            font.letterSpacing: 16
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // Touch to refresh PIN
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                appSettings.generateNewPin()
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Enter this 4-digit code if prompted by device"
                        color: "#94A3B8"
                        font.pixelSize: 12
                        font.family: "sans-serif"
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        Text {
                            text: "\uD83D\uDEE1\uFE0F" // 🛡️
                            font.pixelSize: 13
                        }
                        Text {
                            text: "On-screen operator approval required"
                            color: "#38BDF8"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }
            }
        }

        // ── BOTTOM BAR: About Button & Academic Year Note ──────────────────
        Item {
            width: parent.width
            height: 54

            // About Button (Bottom Left)
            Rectangle {
                id: aboutBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 170
                height: 48
                radius: 24
                color: aboutMouse.containsMouse ? "#1E3A5F" : "#132138"
                border.color: "#00A8E8"
                border.width: 1.2

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "\u2139\uFE0F" // ℹ️
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "About System"
                        color: "#FFFFFF"
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "sans-serif"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: aboutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: idleScreen.requestAbout()
                }
            }

            // Academic Year & Institution (Bottom Right)
            Column {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "2026/27 Academic Year"
                    color: "#94A3B8"
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "sans-serif"
                    horizontalAlignment: Text.AlignRight
                    anchors.right: parent.right
                }

                Text {
                    text: "University of Makeni (UniMak)"
                    color: "#64748B"
                    font.pixelSize: 12
                    font.family: "sans-serif"
                    horizontalAlignment: Text.AlignRight
                    anchors.right: parent.right
                }
            }
        }
    }
}
