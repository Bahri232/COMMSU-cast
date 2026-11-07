import QtQuick
import QtQuick.Controls

Item {
    id: hudOverlay

    visible: opacity > 0
    opacity: 0

    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
        topMargin: 24
    }
    width: hudRow.width + 36
    height: hudRow.height + 20

    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"
        radius: 12
        border.color: "#29B6F6"
        border.width: 1.5
    }

    Row {
        id: hudRow
        anchors.centerIn: parent
        spacing: 10

        Image {
            source: {
                var proto = connectionBridge.protocol
                if (proto === "AirPlay") return "qrc:/assets/apple_icon.png"
                if (proto === "Miracast") return "qrc:/assets/windows_icon.png"
                return "qrc:/assets/android_icon.png"
            }
            width: 22
            height: 22
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: hudContent
            anchors.verticalCenter: parent.verticalCenter
            text: {
                var dev = connectionBridge.deviceName.length > 0 ? connectionBridge.deviceName : "Presenter"
                return dev + " connected via " + connectionBridge.protocol
            }
            color: "#172B45"
            font.pixelSize: 18
            font.bold: true
            font.family: "Segoe UI, Inter, -apple-system, sans-serif"
        }
    }

    NumberAnimation {
        id: fadeIn
        target: hudOverlay
        property: "opacity"
        to: 1.0
        duration: 250
        easing.type: Easing.InOutQuad
    }

    NumberAnimation {
        id: fadeOut
        target: hudOverlay
        property: "opacity"
        to: 0.0
        duration: 250
        easing.type: Easing.InOutQuad
    }

    Timer {
        id: hudHideTimer
        interval: 3500
        repeat: false
        onTriggered: fadeOut.start()
    }

    Connections {
        target: connectionBridge
        function onConnectedChanged(c) {
            fadeOut.stop()
            hudOverlay.opacity = 0
            fadeIn.start()
            hudHideTimer.restart()
        }
    }
}
