import QtQuick
import QtQuick.Controls

Item {
    id: idleScreen
    anchors.fill: parent

    signal requestAbout()

    visible: !connectionBridge.connected

    // Smooth entrance fade
    opacity: visible ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // White-first background: Institutional soft blue-white (#F4F9FD)
    Rectangle {
        anchors.fill: parent
        color: "#F4F9FD"

        // Subtle top brand accent bar (Deep blue #1565C0)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 4
            color: "#1565C0"
        }
    }

    // Scrollable / responsive container
    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, mainContent.implicitHeight + 48)
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Item {
            id: mainContent
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 1380)
            implicitHeight: contentColumn.implicitHeight

            Column {
                id: contentColumn
                width: parent.width
                spacing: 24

                // ── 1. HEADER SECTION ──────────────────────────────────────────────
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Image {
                        id: logo
                        source: "qrc:/assets/comssu_logo.png"
                        width: 116
                        height: 116
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "ComSSU | Wireless Display System"
                        color: "#172B45" // Dark navy
                        font.pixelSize: 34
                        font.bold: true
                        font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Computer Science Students' Society (ComSSU) | University of Makeni"
                        color: "#1565C0" // Deep blue
                        font.pixelSize: 17
                        font.weight: Font.Medium
                        font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Connected Display Status Indicator Pill
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: broadcastRow.width + 28
                        height: 36
                        radius: 18
                        color: "#FFFFFF"
                        border.color: "#CFE2F3"
                        border.width: 1

                        Row {
                            id: broadcastRow
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                width: 9
                                height: 9
                                radius: 4.5
                                color: "#10B981" // Emerald green
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on opacity {
                                    running: idleScreen.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.25; duration: 900; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                                }
                            }

                            Text {
                                text: "Display Name:"
                                color: "#64748B" // Muted blue-grey
                                font.pixelSize: 14
                                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: appSettings.receiverName
                                color: "#1565C0" // Deep blue
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // ── 2. DEVICE INSTRUCTIONS & SECURITY PIN STATION ──────────────────
                Item {
                    id: cardsSection
                    width: parent.width
                    implicitHeight: wideLayout ? Math.max(cardsGrid.height, pinStation.height) : (cardsGrid.height + pinStation.height + 20)
                    property bool wideLayout: width >= 1060

                    // Left Column: 3 Device Instruction Cards
                    Item {
                        id: cardsGrid
                        anchors.left: parent.left
                        anchors.right: cardsSection.wideLayout ? pinStation.left : parent.right
                        anchors.rightMargin: cardsSection.wideLayout ? 24 : 0
                        height: wideCardsRow.height

                        Row {
                            id: wideCardsRow
                            width: parent.width
                            spacing: 16

                            // --- Card 1: Apple Devices ---
                            Rectangle {
                                id: cardApple
                                width: (parent.width - 32) / 3
                                height: 264
                                radius: 16
                                color: "#FFFFFF"
                                border.color: appleMouse.containsMouse ? "#29B6F6" : "#E2E8F0"
                                border.width: appleMouse.containsMouse ? 1.5 : 1
                                y: appleMouse.containsMouse ? -3 : 0

                                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: appleMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 18
                                    spacing: 12

                                    Row {
                                        spacing: 12
                                        Rectangle {
                                            width: 42
                                            height: 42
                                            radius: 21
                                            color: "#E1F5FE"
                                            anchors.verticalCenter: parent.verticalCenter
                                            Image {
                                                anchors.centerIn: parent
                                                source: "qrc:/assets/apple_icon.png"
                                                width: 24
                                                height: 24
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                mipmap: true
                                            }
                                        }
                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2
                                            Text {
                                                text: "Apple Devices"
                                                color: "#172B45"
                                                font.pixelSize: 17
                                                font.bold: true
                                                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                            }
                                            Text {
                                                text: "iOS / iPadOS / macOS"
                                                color: "#64748B"
                                                font.pixelSize: 12
                                                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                            }
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: "#F1F5F9" }

                                    Column {
                                        spacing: 10
                                        width: parent.width

                                        Text {
                                            text: "1. Open <b>Control Center</b>"
                                            color: "#334155"
                                            font.pixelSize: 14
                                            textFormat: Text.RichText
                                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                        }
                                        Text {
                                            text: "2. Tap <b>Screen Mirroring</b>"
                                            color: "#334155"
                                            font.pixelSize: 14
                                            textFormat: Text.RichText
                                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                        }
                                        Text {
                                            text: "3. Select <font color='#0288D1'><b>CS Society Display</b></font>"
                                            color: "#334155"
                                            font.pixelSize: 14
                                            textFormat: Text.RichText
                                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                            wrapMode: Text.WordWrap
                                            width: parent.width
                                        }
                                    }
                                }
                            }

                            // --- Card 2: Windows PC ---
                            Rectangle {
                                id: cardWindows
                                width: (parent.width - 32) / 3
                                height: 264
                                radius: 16
                                color: "#FFFFFF"
                                border.color: winMouse.containsMouse ? "#29B6F6" : "#E2E8F0"
                                border.width: winMouse.containsMouse ? 1.5 : 1
                                y: winMouse.containsMouse ? -3 : 0

                                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: winMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 18
                                    spacing: 12

                                    Row {
                                        spacing: 12
                                        Rectangle {
                                            width: 42
                                            height: 42
                                            radius: 21
                                            color: "#E1F5FE"
                                            anchors.verticalCenter: parent.verticalCenter
                                            Image {
                                                anchors.centerIn: parent
                                                source: "qrc:/assets/windows_icon.png"
                                                width: 24
                                                height: 24
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                mipmap: true
                                            }
                                        }
                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2
                                            Text {
                                                text: "Windows PC"
                                                color: "#172B45"
                                                font.pixelSize: 17
                                                font.bold: true
                                                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                            }
                                            Text {
                                                text: "Windows 10 / 11"
                                                color: "#64748B"
                                                font.pixelSize: 12
                                                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                            }
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: "#F1F5F9" }

                                    Column {
                                        spacing: 10
                                        width: parent.width

                                        Text {
                                            text: "1. Press <font color='#0288D1'><b>Win + K</b></font> or use <b>Chrome</b>"
                                            color: "#334155"
                                            font.pixelSize: 14
                                            textFormat: Text.RichText
                                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                        }
                                        Text {
                                            text: "2. Select <font color='#0288D1'><b>CS Society Display</b></font>"
                                            color: "#334155"
                                            font.pixelSize: 14
                                            textFormat: Text.RichText
                                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                            wrapMode: Text.WordWrap
                                            width: parent.width
                                        }
                                        Text {
                                            text: "3. Confirm approval on screen"
                                            color: "#64748B"
                                            font.pixelSize: 14
                                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                        }
                                    }
                                }
                            }

                            // --- Card 3: Android / Chrome ---
                            Rectangle {
                                id: cardAndroid
                                width: (parent.width - 32) / 3
                                height: 264
                                radius: 16
                                color: "#FFFFFF"
                                border.color: androidMouse.containsMouse ? "#29B6F6" : "#E2E8F0"
                                border.width: androidMouse.containsMouse ? 1.5 : 1
                                y: androidMouse.containsMouse ? -3 : 0

                                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: androidMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 18
                                    spacing: 12

                                    Row {
                                        spacing: 12
                                        Rectangle {
                                            width: 42
                                            height: 42
                                            radius: 21
                                            color: "#E1F5FE"
                                            anchors.verticalCenter: parent.verticalCenter
                                            Image {
                                                anchors.centerIn: parent
                                                source: "qrc:/assets/android_icon.png"
                                                width: 24
                                                height: 24
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                mipmap: true
                                            }
                                        }
                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2
                                            Text {
                                                text: "Android / Chrome"
                                                color: "#172B45"
                                                font.pixelSize: 17
                                                font.bold: true
                                                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                            }
                                            Text {
                                                text: "Google Cast / Smart View"
                                                color: "#64748B"
                                                font.pixelSize: 12
                                                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                            }
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: "#F1F5F9" }

                                    Column {
                                        spacing: 10
                                        width: parent.width

                                        Text {
                                            text: "1. Open <b>Chrome</b> / Quick Settings"
                                            color: "#334155"
                                            font.pixelSize: 14
                                            textFormat: Text.RichText
                                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                        }
                                        Text {
                                            text: "2. Tap <b>Cast</b> or <b>Smart View</b>"
                                            color: "#334155"
                                            font.pixelSize: 14
                                            textFormat: Text.RichText
                                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                        }
                                        Text {
                                            text: "3. Select <font color='#0288D1'><b>CS Society Display</b></font>"
                                            color: "#334155"
                                            font.pixelSize: 14
                                            textFormat: Text.RichText
                                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                            wrapMode: Text.WordWrap
                                            width: parent.width
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Right Column: High-Contrast Security Session PIN Station
                    Rectangle {
                        id: pinStation
                        anchors.right: parent.right
                        anchors.top: cardsSection.wideLayout ? parent.top : cardsGrid.bottom
                        anchors.topMargin: cardsSection.wideLayout ? 0 : 20
                        width: cardsSection.wideLayout ? 370 : parent.width
                        height: 264
                        radius: 16
                        color: "#EBF5FB" // Subtle light-blue surface
                        border.color: "#BEE3F8"
                        border.width: 1.5

                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            width: parent.width - 36

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 8
                                Text {
                                    text: "\uD83D\uDEE1\uFE0F" // 🛡️
                                    font.pixelSize: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "SECURITY SESSION PIN"
                                    color: "#1565C0" // Deep blue
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.letterSpacing: 1.5
                                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Large High-Contrast PIN Container
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                height: 88
                                radius: 12
                                color: "#FFFFFF"
                                border.color: pinMouseArea.containsMouse ? "#29B6F6" : "#CFE2F3"
                                border.width: 1

                                Text {
                                    id: pinDisplay
                                    anchors.centerIn: parent
                                    text: appSettings.pin && appSettings.pin.length > 0 ? appSettings.pin : "----"
                                    color: "#1565C0" // Deep blue digits
                                    font.pixelSize: 58
                                    font.bold: true
                                    font.family: "Consolas, 'Courier New', monospace"
                                    font.letterSpacing: 14
                                    horizontalAlignment: Text.AlignHCenter

                                    // Subtle pulse animation when PIN updates
                                    Behavior on text {
                                        SequentialAnimation {
                                            NumberAnimation { target: pinDisplay; property: "scale"; to: 0.92; duration: 100 }
                                            NumberAnimation { target: pinDisplay; property: "scale"; to: 1.0; duration: 120 }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: pinMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: appSettings.generateNewPin()

                                    ToolTip.visible: containsMouse
                                    ToolTip.text: "Click to generate a new PIN"
                                    ToolTip.delay: 400
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Enter this 4-digit code if prompted by device"
                                color: "#64748B"
                                font.pixelSize: 12
                                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                            }

                            // Operator Approval Requirement Notice
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: approvalRow.width + 20
                                height: 28
                                radius: 14
                                color: "#FFFFFF"
                                border.color: "#E2E8F0"
                                border.width: 1

                                Row {
                                    id: approvalRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        text: "\u2705"
                                        font.pixelSize: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "On-screen operator approval required"
                                        color: "#1565C0"
                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // ── 3. BOTTOM BAR: About Button & Academic Year ────────────────────
                Item {
                    width: parent.width
                    height: 50

                    // About Button (Bottom Left)
                    Rectangle {
                        id: aboutBtn
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 160
                        height: 42
                        radius: 21
                        color: aboutMouse.containsMouse ? "#E1F5FE" : "#FFFFFF"
                        border.color: aboutMouse.containsMouse ? "#1565C0" : "#29B6F6"
                        border.width: 1.2

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "\u2139\uFE0F" // ℹ️
                                font.pixelSize: 15
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "About System"
                                color: "#1565C0"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
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

                    // Academic Year & Institution Note (Bottom Right)
                    Column {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "2026/27 Academic Year"
                            color: "#172B45"
                            font.pixelSize: 14
                            font.bold: true
                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                            horizontalAlignment: Text.AlignRight
                            anchors.right: parent.right
                        }

                        Text {
                            text: "University of Makeni (UniMak)"
                            color: "#64748B"
                            font.pixelSize: 12
                            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                            horizontalAlignment: Text.AlignRight
                            anchors.right: parent.right
                        }
                    }
                }
            }
        }
    }
}
