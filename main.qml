import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: mainWin
    width: 640
    height: 480
    visible: true
    title: qsTr("FaceZapper")

    FaceSwipeView {
        id: swipeView
    }
    DeriveNamesTableView {
        anchors.fill: parent
        id: deriveNamesTableView
    }

    footer: Rectangle {
        id: footer
        height: 50
        implicitHeight: 50
        width: swipeView.width
        implicitWidth: 50
        color: "red"
//        Button {
//            visible: swipeView.currentItem.pageType === FaceSwipeView.PageType.FACE_PAGE
//            anchors.centerIn: parent
//            text: "Settings"
//            onClicked: {
////                if (!swipeView.currentItem.pageType !== FaceSwipeView.PageType.SETTINGS_PAGE) swipeView.createSettingsPage()
//                swipeView.visible = !swipeView.visible
//                deriveNamesTableView.visible = !deriveNamesTableView.visible
//            }
//        }
        Button {
//            visible: swipeView.currentItem.pageType === FaceSwipeView.PageType.SHOW_FOLDER_PAGE
            anchors.centerIn: parent
            text: "Übernehmen"
            onClicked: {
//                if (!swipeView.currentItem.pageType !== FaceSwipeView.PageType.SETTINGS_PAGE) swipeView.createSettingsPage()
                if (controller) controller.takeOverTableContent()
                swipeView.createPages()
                deriveNamesTableView.visible = false;
            }
        }
    }
}
