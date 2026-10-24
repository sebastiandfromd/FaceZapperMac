import QtQuick 2.15
import QtQuick.Controls 2.15

SwipeView {
    id: swipeView
    property int lastIndex: -1;
    property int counter: 0
    anchors.fill: parent
    property bool creationInProgress: false;
    property var colors: ["orange", "lightgreen", "yellow"]
    background: Rectangle { color: "blue" }

    function clear() {
        while (swipeView.count() > 0) {
            takeItem(0);
        }
    }
    function createPages() {
        creationInProgress = true
        for (var i = 0; i<4; i++) {
            // create a number of pre-load pages
            addItem(picPageComponent.createObject(swipeView, {color: swipeView.colors[counter%3], count: counter++, person: controller.nextPersonData()}));
        }
        creationInProgress = false
    }

    enum PageType {
        FACE_PAGE,
        SHOW_FOLDER_PAGE,
        SETTINGS_PAGE
    }
    function createSettingsPage() {
        creationInProgress = true
        if (currentIndex>0) removeItem(swipeView.itemAt(0));
        insertItem(currentIndex,settingsComponent.createObject(swipeView))
        swipeView.decrementCurrentIndex()
        creationInProgress = false
    }

    onCurrentIndexChanged: {
        if (creationInProgress) {
            return // don't interfere with a current operation!
        }
        if (controller) controller.solveAttempt = ""
        var forw = currentIndex > lastIndex     // forw: user swiped to the *next* picture
        if (currentIndex>=2 && forw) {
            creationInProgress = true
            addItem(picPageComponent.createObject(swipeView, {color: swipeView.colors[counter%3], count: counter++, person: controller.nextPersonData()}));
            removeItem(swipeView.itemAt(0));
            lastIndex = currentIndex
            creationInProgress = false
        }
        lastIndex = currentIndex
        creationInProgress = false
    }

    Component.onCompleted: {

    }


    Component {
        id: picPageComponent
        Rectangle {
            property int count: -1
            property var person: null
            property int pageType: FaceSwipeView.PageType.FACE_PAGE
            property real faceMargin: Math.min(height/40, width/40)
            id: picPageComponentRect
            color: picPageComponent.color
            Text {
                id: rectTextField
                anchors.fill: parent
                text: picPageComponentRect.count+": "+(picPageComponentRect.person ? picPageComponentRect.person.picFileName : "")
            }
            Image {
                id: faceImage
                cache: false
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: faceMargin
                width: parent.width
                height: parent.height *2/3
                fillMode: Image.PreserveAspectFit
                property string name: (controller && picPageComponentRect.person) ?
                                          "image://faceProvider/"+encodeURIComponent(picPageComponentRect.person.picFileName)
                                        : ""
                source: name
            }
            Rectangle {
                id:solveAttemptsRec
                color: "lightgray"
                height: parent.height - (faceImage.height + 3*faceMargin)
                width: parent.width - 2* anchors.margins
                anchors.top: faceImage.bottom
                anchors.left: parent.left
                anchors.margins: faceMargin
                border.color: "darkgray"
                border.width: 1
                Loader {
                    property bool isCurrent: swipeView.currentItem == picPageComponentRect
                    id: solveAttemptsLoader
                    sourceComponent: letterLineSolver
                    anchors.fill: parent
                    property var person: picPageComponentRect.person
                }
            }
        }
    }

    Component {
        id: settingsComponent
        Rectangle {
            property int pageType: FaceSwipeView.PageType.SETTINGS_PAGE
            id: settingsComponentRect
            color: "white"
            Text {
                id: settingsTextField
                anchors.fill: parent
                text: "Settings"
            }
        }
    }
    Component {
        id: fullTypeInSolver
        Rectangle {
            color: "lightgreen"
            anchors.fill: parent
            TextInput {
                property bool curr: isCurrent
                onCurrChanged: {
                    controller.solveAttempt = "";
                    forceActiveFocus()
                }
                id: fullTypeInSolverInput
                anchors.fill: parent
                verticalAlignment: "AlignVCenter"
                horizontalAlignment: "AlignHCenter"
                text: (controller && isCurrent)? controller.solveAttempt : ""
                onTextChanged: {
                    if (controller && isCurrent) {
                        controller.solveAttempt = text;
                        console.debug("onTextChanged: "+person.picFileName)
                        console.debug("onTextChanged: "+person.firstName)
                        console.debug("onTextChanged: "+person.familyName)
                        console.debug("onTextChanged: "+person.uid)
                    }
                }
            }
        }
    }
    Component {
        id: letterLineSolver
        Rectangle {
            id: letterLineRect
            color: "lightgreen"
            anchors.fill: parent
            Row {
                height: parent.height
                width: childrenRect.width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter



                Repeater {
                    id: lineRepeater
                    model: 9
                    property string randomText: controller? controller.randomLetters(9,"Ö") : "012345678"
                    Rectangle {
                        width: Math.min(letterLineRect.width, letterLineRect.height) / 2
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
    Component {
        id: letterCircleSolver
        Rectangle {
            color: "lightgreen"
            anchors.fill: parent

            Repeater {
                id: circleRepeater
                model: 9
                Rectangle {
                    width: Math.min(parent.width, parent.height) / 3
                    height: width
                    radius: width / 2
                    property real phi: Math.PI*1/2 + index*2*Math.PI/circleRepeater.count
                    x: 70*Math.cos(phi)+parent.width/2 - width/2
                    y: 40*Math.sin(phi)+parent.height/2 - height/2
                    Text {
                        anchors.fill: parent
                        text: Math.round(phi * 360 / (2*Math.PI))
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                }
            }



        }
    }

}
