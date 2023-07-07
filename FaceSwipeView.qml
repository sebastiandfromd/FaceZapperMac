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
                anchors.topMargin: parent.height/15
                width: parent.width
                height: parent.height *2/3
                fillMode: Image.PreserveAspectFit
                property string name: (controller && picPageComponentRect.person) ?
                                          "image://faceProvider/"+controller.currentFolderPath()+"/"+picPageComponentRect.person.picFileName
                                        : ""
                source: name
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
}
