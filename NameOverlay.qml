import QtQuick 2.15

// Big name (or letter) in the middle of its parent: green = correct, red = correction.
// flash() hides it again after a while and emits finished(), showPermanent() keeps it.
Rectangle {
    id: overlay
    property alias text: label.text
    property bool correct: true
    signal finished()

    visible: false
    anchors.centerIn: parent
    width: parent.width * 0.9
    height: parent.height / 4
    radius: height / 8
    color: correct ? "#dd2e7d32" : "#ddc62828"

    function flash(newText, isCorrect, duration) {
        text = newText
        correct = isCorrect
        visible = true
        timer.interval = duration
        timer.restart()
    }
    function showPermanent(newText, isCorrect) {
        timer.stop()
        text = newText
        correct = isCorrect
        visible = true
    }
    function hide() {
        timer.stop()
        visible = false
    }

    Text {
        id: label
        anchors.fill: parent
        anchors.margins: parent.height / 10
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: "white"
        font.bold: true
        font.pixelSize: height * 0.8
        fontSizeMode: Text.Fit
        minimumPixelSize: 8
    }
    Timer {
        id: timer
        onTriggered: {
            overlay.visible = false
            overlay.finished()
        }
    }
}
