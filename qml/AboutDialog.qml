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

    // Modal background overlay (soft dimmed translucent backdrop)
    Rectangle {
        anchors.fill: parent
        color: "#660F172A"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: aboutDialog.close()
        }
    }

    // Centered Dialog Card (Clean white-first institutional panel)
    Rectangle {
        id: card
        width: Math.min(760, parent.width - 48)
        height: Math.min(620, parent.height - 48)
        anchors.centerIn: parent
        radius: 20
        color: "#FFFFFF"
        border.color: "#E2E8F0"
        border.width: 1.5

        // Prevent click-through from inside card
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 64
            spacing: 14

            // ComSSU Logo
            Image {
                id: dialogLogo
                source: "qrc:/assets/comssu_logo.png"
                width: 90
                height: 90
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Application Title
            Text {
                text: "ComSSU — Wireless Display System"
                color: "#172B45" // Dark navy
                font.pixelSize: 24
                font.bold: true
                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Version & Academic Year Badges
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Rectangle {
                    width: verText.width + 18
                    height: 26
                    radius: 13
                    color: "#F1F5F9"
                    border.color: "#E2E8F0"
                    border.width: 1

                    Text {
                        id: verText
                        anchors.centerIn: parent
                        text: "Version 1.0.0"
                        color: "#475569"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                    }
                }

                Rectangle {
                    width: academicYearText.width + 18
                    height: 26
                    radius: 13
                    color: "#E1F5FE"
                    border.color: "#B3E5FC"
                    border.width: 1

                    Text {
                        id: academicYearText
                        anchors.centerIn: parent
                        text: "2026/27 Academic Year"
                        color: "#1565C0"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                    }
                }
            }

            // Department & University
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 3

                Text {
                    text: "COMPUTER SCIENCE STUDENTS' SOCIETY (ComSSU)"
                    color: "#172B45"
                    font.pixelSize: 15
                    font.bold: true
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "University of Makeni (UniMak)"
                    color: "#64748B"
                    font.pixelSize: 13
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Subtle divider
            Rectangle {
                width: parent.width - 32
                height: 1
                color: "#F1F5F9"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Developer Attribution
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Text {
                    text: "Lead Developer:"
                    color: "#64748B"
                    font.pixelSize: 13
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                }

                Text {
                    text: "Abdul Malik Barrie (BAHRI)"
                    color: "#172B45"
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                }

                Text {
                    text: "—"
                    color: "#CBD5E1"
                    font.pixelSize: 13
                }

                Text {
                    text: "abdulmalikbarrie@gmail.com"
                    color: "#0288D1"
                    font.pixelSize: 13
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                }
            }

            // Purpose Statement Container
            Rectangle {
                width: parent.width
                height: purposeText.height + 22
                radius: 10
                color: "#F4F9FD" // Soft blue-white
                border.color: "#E2E8F0"
                border.width: 1

                Text {
                    id: purposeText
                    anchors.centerIn: parent
                    width: parent.width - 32
                    text: "Engineered for cross-platform wireless screen projection (AirPlay, Miracast, Google Cast) for large-format interactive flat panel displays."
                    color: "#334155"
                    font.pixelSize: 13
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.25
                }
            }

            // Open-Source Framework Acknowledgment
            Text {
                width: parent.width
                text: "Built with love by BAHRI"
                color: "#64748B"
                font.pixelSize: 12
                font.family: "Segoe UI, Inter, -apple-system, sans-serif"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item { width: 1; height: 4 }

            // Blue Close Button
            Rectangle {
                id: closeBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 150
                height: 44
                radius: 22
                color: closeMouse.containsMouse ? "#0288D1" : "#1565C0"

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "Close"
                    color: "#FFFFFF"
                    font.pixelSize: 15
                    font.bold: true
                    font.family: "Segoe UI, Inter, -apple-system, sans-serif"
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
