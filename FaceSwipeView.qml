import QtQuick 2.15
import QtQuick.Controls 2.15

// Learning page: one face at a time, the flow lives in controller.session (LearningSession).
// Swipe left  = done with this person: the name flashes green (known), yellow (typed after
//               "Lösung") or red (not known), then the next face - after red the same face stays,
//               with its name, for another look.
// Swipe right = back to the previous face, its answer can be redone.
Rectangle {
    id: learnView
    property var session: controller ? controller.session : null
    property var person: session ? session.currentPerson : null
    property int flashDuration: controller ? controller.flashDuration : 500 // ms, settings page
    property bool busy: false         // while the name flashes after a swipe
    property int lastOutcome: 1       // LearningSession.Outcome of the last swipe
    property real faceMargin: Math.min(height/40, width/40)
    color: "lightgray"

    function swipedLeft() {
        if (!session || !person) return
        lastOutcome = session.finishCurrent()
        if (lastOutcome === 3) { // SKIPPED: second look without typing - just go on
            session.next()
            syncSolutionOverlay()
            return
        }
        busy = true
        nameOverlay.flash(session.targetName, lastOutcome, flashDuration)
    }
    function swipedRight() {
        if (!session || !session.canGoBack) return
        session.back()
    }
    function pressKey(key) {
        if (busy || !session) return
        if (key === "⌫") session.backspace()
        else session.typeLetter(key)
    }
    // "Lösung" shows the name until the first correct letter is typed (or the swipe)
    function syncSolutionOverlay() {
        if (busy || !session) return
        if (session.solutionVisible) nameOverlay.showPermanent(session.targetName, 0)
        else nameOverlay.hide()
    }

    Connections {
        target: learnView.session
        function onSolutionShownChanged() { learnView.syncSolutionOverlay() }
    }

    Item {
        id: photoArea
        anchors.top: parent.top
        anchors.topMargin: faceMargin
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 2/3
        clip: true

        Image {
            id: faceImage
            width: parent.width
            height: parent.height
            fillMode: Image.PreserveAspectFit
            cache: false
            asynchronous: true
            source: learnView.person ? "image://faceProvider/" + encodeURIComponent(learnView.person.picFileName) : ""
            Behavior on x {
                enabled: !dragHandler.active
                NumberAnimation { duration: 150 }
            }
        }
        DragHandler {
            id: dragHandler
            target: faceImage
            enabled: !learnView.busy
            yAxis.enabled: false
            onActiveChanged: {
                if (active) return
                var dx = faceImage.x
                faceImage.x = 0
                if (dx < -photoArea.width / 4) learnView.swipedLeft()
                else if (dx > photoArea.width / 4) learnView.swipedRight()
            }
        }
        NameOverlay {
            id: nameOverlay
            onFinished: {
                // red: the same face stays, with its name; otherwise the next face
                if (learnView.lastOutcome === 0) learnView.session.retry()
                else learnView.session.next()
                learnView.busy = false
                learnView.syncSolutionOverlay()
            }
        }
    }

    Rectangle {
        id: letterLineRect
        color: "lightgreen"
        border.color: "darkgray"
        border.width: 1
        anchors.top: photoArea.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: faceMargin
        // what has been typed so far - a wrong letter is not marked, it may be a slip the user notices
        Text {
            id: typedText
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.35
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: height * 0.7
            font.bold: true
            text: learnView.session ? learnView.session.typed : ""
        }
        // letter keyboard: 8 likely characters (exactly one of them is right) + backspace
        Row {
            id: keyRow
            anchors.top: typedText.bottom
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            property real keySize: Math.min(letterLineRect.width / 9, height) * 0.9
            spacing: keySize / 9
            Repeater {
                model: learnView.session ? learnView.session.keys.concat(["⌫"]) : []
                Rectangle {
                    width: keyRow.keySize
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: keyMouseArea.pressed ? "gold" : "white"
                    border.color: "darkgray"
                    opacity: keyMouseArea.enabled ? 1 : 0.4
                    Text {
                        anchors.fill: parent
                        text: modelData === " " ? "␣" : modelData
                        font.pixelSize: height * 0.5
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        id: keyMouseArea
                        anchors.fill: parent
                        enabled: !learnView.busy
                        onClicked: learnView.pressKey(modelData)
                    }
                }
            }
        }
    }
}
