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
                                          "image://faceProvider/"+controller.currentFolderPath()+"/"+picPageComponentRect.person.picFileName
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
                    sourceComponent: fullTypeInSolver
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
}
