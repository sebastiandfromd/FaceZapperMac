import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs
//import QtCore

ApplicationWindow {
    id: mainWin
    width: 640
    height: 480
    visible: true
    title: qsTr("FaceZapper")

    FaceSwipeView {
        id: swipeView
    }
    FolderDialog {
        id: fileDialog

//        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        // start in the current group's folder ("D:/x" -> "file:///D:/x", "/x" -> "file:///x",
        // Android "content://..." stays as it is)
        currentFolder: !controller || !controller.groupFolder ? ""
                       : controller.groupFolder.indexOf("://") >= 0 ? controller.groupFolder
                       : "file://" + (controller.groupFolder.startsWith("/") ? "" : "/") + controller.groupFolder
        onAccepted: {
            console.debug(selectedFolder)
            controller.groupFolder = selectedFolder
        }
    }

    DeriveNamesTableView {
        anchors.fill: parent
        id: deriveNamesTableView

        onOpenFolderRequested: fileDialog.open()
    }

    footer: Rectangle {
        id: footer
        height: 50
        implicitHeight: 50
        // no explicit width: ApplicationWindow stretches the footer over the whole window
        color: "red"
//        visible: deriveNamesTableView.visible
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
