import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import "."

// Learning page: one face at a time, the flow lives in controller.session (LearningSession).
// Swipe left  = done with this person: as soon as a drag to the left is noticed the answer is
//               decided (no peeking, no taking back) and the name shows up in its color - green
//               (known), yellow (typed correctly after the name had been shown) or red (the name
//               had been shown, nothing or a slip typed since). When the finger lets go the face
//               slides out to the left, then the next face.
//               Red with a wrong letter left (Outcome 0): the face springs back and stays, with
//               its name, for another look. The "Bekannt" button does the same (markKnown), with the face
//               leaving at the speed set in the settings.
// Swipe right = back to the previous face, its answer can be redone.
Rectangle {
    id: learnView
    property var session: controller ? controller.session : null
    property var person: session ? session.currentPerson : null
    property int flashDuration: controller ? controller.flashDuration : 500 // ms, settings page
    property int slideOutDuration: controller ? controller.slideOutDuration : 300 // ms after "Bekannt"
    readonly property int swipeSlideOutDuration: 220 // ms: the finger has already moved the face
    property bool busy: false         // while the face slides out / the name flashes after a swipe
    property bool cardOut: false      // the face is sliding / has slid out: no spring-back animation
    property bool decided: false      // a drag to the left has decided the answer (finger still down)
    property int lastOutcome: 1       // LearningSession.Outcome of the last swipe
    property real faceMargin: Math.min(height/40, width/40)
    color: Theme.background

    // "Bekannt" button in the footer: the same as swiping left
    function markKnown() {
        if (busy || decided || !session || !person) return
        decideLeft()
        leaveLeft(slideOutDuration)
    }
    // rates the card and shows the name in the answer's color (for a drag: while the finger is down)
    function decideLeft() {
        decided = true
        lastOutcome = session.finishCurrent()
        // SKIPPED (second look without typing): no name, the next face right after
        if (lastOutcome !== 3) nameOverlay.showPermanent(session.targetName, lastOutcome)
    }
    // after the decision: the face leaves (or, after red, goes back to the middle)
    function leaveLeft(duration) {
        decided = false
        busy = true
        if (lastOutcome === 0) {
            photoCard.x = 0 // red: the same face stays - back to the middle
            nameOverlay.flash(session.targetName, lastOutcome, flashDuration)
            return
        }
        // the name stays while the face moves out; its flash time starts once the face is gone
        cardOut = true
        if (duration > 0) {
            slideOut.duration = duration
            slideOut.start()
        } else {
            photoCard.x = -photoArea.width // "at once": the face just vanishes
            slidOut()
        }
    }
    function slidOut() {
        if (lastOutcome === 3) finishSwipe()
        else nameOverlay.flash(session.targetName, lastOutcome, flashDuration)
    }
    // after the flash (or the slide-out without one): the next face, or the second look after red
    function finishSwipe() {
        if (lastOutcome === 0) session.retry()
        else session.next()
        slideOut.stop()
        photoCard.x = 0 // the new face in the middle at once (cardOut: no animation)
        cardOut = false
        busy = false
        syncSolutionOverlay()
    }
    function swipedRight() {
        if (!session || !session.canGoBack) return
        session.back()
    }
    function pressKey(key) {
        if (busy || decided || !session) return
        if (key === "⌫") session.backspace()
        else session.typeLetter(key)
    }
    // "Unbekannt" shows the name until the first correct letter is typed (or the swipe)
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

        // the photo as a card: rounded corners (mask over the painted part) and a white rim
        Item {
            id: photoCard
            width: parent.width
            height: parent.height
            Behavior on x {
                enabled: !dragHandler.active && !learnView.cardOut
                NumberAnimation { duration: 150 }
            }
            // where the picture is actually drawn (PreserveAspectFit leaves space at the sides)
            property rect painted: Qt.rect((width - faceImage.paintedWidth) / 2, (height - faceImage.paintedHeight) / 2,
                                           faceImage.paintedWidth, faceImage.paintedHeight)
            property real cornerRadius: Math.min(painted.width, painted.height) / 14

            Image {
                id: faceImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                cache: false
                asynchronous: true
                source: learnView.person ? "image://faceProvider/" + encodeURIComponent(learnView.person.picFileName) : ""
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: photoMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
            }
            Item {
                id: photoMask
                anchors.fill: parent
                layer.enabled: true
                visible: false
                Rectangle {
                    x: photoCard.painted.x
                    y: photoCard.painted.y
                    width: photoCard.painted.width
                    height: photoCard.painted.height
                    radius: photoCard.cornerRadius
                }
            }
            Rectangle {
                x: photoCard.painted.x
                y: photoCard.painted.y
                width: photoCard.painted.width
                height: photoCard.painted.height
                radius: photoCard.cornerRadius
                visible: faceImage.status === Image.Ready
                color: "transparent"
                border.color: Theme.surface
                border.width: Math.max(3, width / 60)
            }
        }
        DragHandler {
            id: dragHandler
            target: photoCard
            enabled: !learnView.busy
            yAxis.enabled: false
            onActiveChanged: {
                if (active) return
                if (learnView.decided) {
                    // decided while dragging: goes on sliding out from here (or back after red)
                    learnView.leaveLeft(learnView.swipeSlideOutDuration)
                    return
                }
                var dx = photoCard.x
                photoCard.x = 0
                if (dx > photoArea.width / 4) learnView.swipedRight()
            }
        }
        // a drag to the left is noticed as soon as the face has moved a little that way
        Connections {
            target: photoCard
            function onXChanged() {
                if (dragHandler.active && !learnView.decided && !learnView.busy && learnView.person
                        && photoCard.x < -photoArea.width / 40)
                    learnView.decideLeft()
            }
        }
        // the old face leaves to the left (from wherever the finger let go)
        NumberAnimation {
            id: slideOut
            target: photoCard
            property: "x"
            to: -photoArea.width
            easing.type: Easing.InQuad
            onFinished: learnView.slidOut()
        }
        NameOverlay {
            id: nameOverlay
            onFinished: learnView.finishSwipe()
        }
    }

    Item {
        id: letterLineRect
        anchors.top: photoArea.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: faceMargin
        // what has been typed so far - a wrong letter is not marked, it may be a slip the user notices -
        // followed by a blinking block cursor (only one, whatever the length of the name)
        Item {
            id: typedLine
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.35
            Row {
                anchors.centerIn: parent
                spacing: typedText.font.pixelSize / 12
                Text {
                    id: typedText
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: typedLine.height * 0.7
                    font.bold: true
                    color: Theme.text
                    text: learnView.session ? learnView.session.typed : ""
                    // typing shows the cursor at once, then it blinks again
                    onTextChanged: { cursorBlock.on = true; cursorTimer.restart() }
                }
                Rectangle {
                    id: cursorBlock
                    property bool on: true
                    anchors.verticalCenter: parent.verticalCenter
                    width: typedText.font.pixelSize * 0.55
                    height: typedText.font.pixelSize * 0.8
                    color: Theme.text
                    visible: on && learnView.person !== null && !learnView.busy && !learnView.decided
                    Timer {
                        id: cursorTimer
                        interval: 530
                        repeat: true
                        running: learnView.person !== null && !learnView.busy
                        onTriggered: cursorBlock.on = !cursorBlock.on
                    }
                }
            }
        }
        // letter keyboard: 8 likely characters (exactly one of them is right) + backspace
        Row {
            id: keyRow
            anchors.top: typedLine.bottom
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
                    color: keyMouseArea.pressed ? Theme.accentLight : Theme.surface
                    border.color: keyMouseArea.pressed ? Theme.accent : Theme.border
                    border.width: keyMouseArea.pressed ? 2 : 1
                    opacity: keyMouseArea.enabled ? 1 : 0.4
                    Text {
                        anchors.fill: parent
                        color: Theme.text
                        // "⌫" and "␣" are missing in Android's default font: "←" for backspace,
                        // the space is drawn (see below)
                        text: modelData === " " ? "" : modelData === "⌫" ? "←" : modelData
                        font.pixelSize: height * 0.5
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    // space key: the usual "␣" shape - a line with two short ends
                    Item {
                        visible: modelData === " "
                        anchors.centerIn: parent
                        width: parent.width * 0.45
                        height: parent.height * 0.15
                        property real stroke: Math.max(2, parent.width / 22)
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.stroke; color: Theme.text }
                        Rectangle { anchors.left: parent.left; width: parent.stroke; height: parent.height; color: Theme.text }
                        Rectangle { anchors.right: parent.right; width: parent.stroke; height: parent.height; color: Theme.text }
                    }
                    MouseArea {
                        id: keyMouseArea
                        anchors.fill: parent
                        enabled: !learnView.busy && !learnView.decided
                        onClicked: learnView.pressKey(modelData)
                    }
                }
            }
        }
    }
}
