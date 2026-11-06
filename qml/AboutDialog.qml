import QtQuick
import QtQuick.Controls

Item {
    id: aboutDialog
    anchors.fill: parent

    property bool isOpen: false

    function open() {
        isOpen = true
    }

    function close() {
        isOpen = false
    }

    visible: opacity > 0
    opacity: isOpen ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Modal background overlay
    Rectangle {
        anchors.fill: parent
        color: "#B3030712"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: aboutDialog.close()
        }
    }

    // Centered Dialog Card
    Rectangle {
        id: card
        width: Math.min(840, parent.width - 48)
        height: Math.min(680, parent.height - 48)
        anchors.centerIn: parent
        radius: 18
        color: "#0F172A"
        border.color: "#00A8E8"
        border.width: 1.5

        // Prevent click-through from inside card
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 56
            spacing: 14

            // Top Header with Logo
            Image {
                id: dialogLogo
                source: "qrc:/assets/comssu_logo.png"
                width: 105
                height: 105
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Title & Version
            Text {
                text: "ComSSU — Wireless Display System (v1.0.0)"
                color: "#FFFFFF"
                font.pixelSize: 24
                font.bold: true
                font.family: "sans-serif"
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Academic Year Badge
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: academicYearText.width + 24
                height: 30
                radius: 15
                color: "#1E293B"
                border.color: "#00A8E8"
                border.width: 1

                Text {
                    id: academicYearText
                    anchors.centerIn: parent
                    text: "2026/27 Academic Year"
                    color: "#38BDF8"
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "sans-serif"
                }
            }

            // Institution & Department
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 3

                Text {
                    text: "COMPUTER SCIENCE STUDENTS' SOCIETY (ComSSU)"
                    color: "#F1F5F9"
                    font.pixelSize: 15
                    font.bold: true
                    font.family: "sans-serif"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "University of Makeni (UniMak)"
                    color: "#94A3B8"
                    font.pixelSize: 14
                    font.family: "sans-serif"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Divider
            Rectangle {
                width: parent.width - 40
                height: 1
                color: "#334155"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Lead Developer
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Text {
                    text: "Lead Developer:"
                    color: "#94A3B8"
                    font.pixelSize: 14
                    font.family: "sans-serif"
                }

                Text {
                    text: "Abdul Malik Barrie (BAHRI)"
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "sans-serif"
                }

                Text {
                    text: "—"
                    color: "#64748B"
                    font.pixelSize: 14
                }

                Text {
                    text: "abdulmalikbarrie@gmail.com"
                    color: "#38BDF8"
                    font.pixelSize: 14
                    font.family: "sans-serif"
                }
            }

            // Purpose Statement Box
            Rectangle {
                width: parent.width
                height: purposeText.height + 20
                radius: 10
                color: "#162032"
                border.color: "#1E293B"
                border.width: 1

                Text {
                    id: purposeText
                    anchors.centerIn: parent
                    width: parent.width - 32
                    text: "Engineered for cross-platform wireless screen projection (AirPlay, Miracast, Google Cast) for large-format interactive flat panel displays."
                    color: "#CBD5E1"
                    font.pixelSize: 13
                    font.italic: true
                    font.family: "sans-serif"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.2
                }
            }

            // Licensing & Credit
            Text {
                width: parent.width
                text: "Built upon the open-source AirShow framework (GPL-3.0). Core multimedia streaming powered by Qt 6 and GStreamer."
                color: "#64748B"
                font.pixelSize: 12
                font.family: "sans-serif"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item { width: 1; height: 6 }

            // Touch-Friendly Close Button
            Rectangle {
                id: closeBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 170
                height: 48
                radius: 24
                color: closeMouse.containsMouse ? "#0284C7" : "#00A8E8"

                Text {
                    anchors.centerIn: parent
                    text: "Close"
                    color: "#FFFFFF"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "sans-serif"
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: aboutDialog.close()
                }
            }
        }
    }
}
