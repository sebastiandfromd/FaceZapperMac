import QtQuick 2.15
import QtQuick.Controls 2.15

// Learning page: one face at a time, the flow lives in controller.session (LearningSession).
// Swipe left  = done with this person: the name flashes (green/red), then the next face.
// Swipe right = back to the previous face, its answer can be redone.
Rectangle {
    id: learnView
    property var session: controller ? controller.session : null
    property var person: session ? session.currentPerson : null
    property int flashDuration: 500  // ms, will move to the settings page
    property bool busy: false         // while the name flashes after a swipe
    property real faceMargin: Math.min(height/40, width/40)
    color: "lightgray"

    function swipedLeft() {
        if (!session || !person) return
        busy = true
        var known = session.finishCurrent()
        nameOverlay.flash(session.targetName, known, flashDuration)
    }
    function swipedRight() {
        if (!session || !session.canGoBack) return
        session.back()
    }
    // "Lösung" shows the name until the swipe
    function syncSolutionOverlay() {
        if (busy || !session) return
        if (session.solutionShown) nameOverlay.showPermanent(session.targetName, false)
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
                learnView.session.next()
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
        // placeholder until step 2 (letter keyboard): still random letters around a fixed "Ö"
        Row {
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                id: lineRepeater
                model: 9
                property string randomText: (controller && learnView.person) ? controller.randomLetters(9, "Ö") : ""
                Rectangle {
                    width: Math.min(letterLineRect.width / 9, letterLineRect.height) * 0.9
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.fill: parent
                        text: lineRepeater.randomText.charAt(index)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
