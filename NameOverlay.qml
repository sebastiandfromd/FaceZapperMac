import QtQuick 2.15

// Big name in the middle of its parent, colored by LearningSession.Outcome:
// 0 = red (not known), 1 = green (known), 2 = yellow (typed correctly after the name was shown).
// flash() hides it again after a while and emits finished(), showPermanent() keeps it.
Rectangle {
    id: overlay
    property alias text: label.text
    property int outcome: 1
    signal finished()

    visible: false
    anchors.centerIn: parent
    width: parent.width * 0.9
    height: parent.height / 4
    radius: height / 8
    color: outcome === 1 ? "#dd2e7d32" : outcome === 2 ? "#eef9c825" : "#ddc62828"

    function flash(newText, newOutcome, duration) {
        text = newText
        outcome = newOutcome
        visible = true
        timer.interval = duration
        timer.restart()
    }
    function showPermanent(newText, newOutcome) {
        timer.stop()
        text = newText
        outcome = newOutcome
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
        color: overlay.outcome === 2 ? "black" : "white"
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
