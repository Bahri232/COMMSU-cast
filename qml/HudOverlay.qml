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
    width: hudContent.width + 36
    height: hudContent.height + 20

    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"
        radius: 12
        border.color: "#29B6F6"
        border.width: 1.5
    }

    Text {
        id: hudContent
        anchors.centerIn: parent
        text: {
            var icon = ""
            if (connectionBridge.protocol === "AirPlay")        icon = "\uD83C\uDF4E "   // 🍎
            else if (connectionBridge.protocol === "Cast")     icon = "\uD83D\uDCFA "   // 📺
            else if (connectionBridge.protocol === "Miracast")  icon = "\uD83D\uDCBB "   // 💻
            else if (connectionBridge.protocol === "DLNA")      icon = "\uD83C\uDFB5 "   // 🎵
            else                                               icon = "\uD83D\uDCF1 "   // 📱

            var dev = connectionBridge.deviceName.length > 0 ? connectionBridge.deviceName : "Presenter"
            return icon + dev + " connected via " + connectionBridge.protocol
        }
        color: "#172B45"
        font.pixelSize: 18
        font.bold: true
        font.family: "Segoe UI, Inter, -apple-system, sans-serif"
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
