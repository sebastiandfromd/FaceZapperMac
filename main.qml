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
    property bool learning: !deriveNamesTableView.visible

    FaceSwipeView {
        id: learnView
        anchors.fill: parent
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
        Button {
            anchors.centerIn: parent
            // import table: take the names over and start learning; learning: show the name
            text: mainWin.learning ? "Lösung" : "Übernehmen"
            enabled: !mainWin.learning || (controller && controller.session.currentPerson !== null
                                           && !controller.session.solutionVisible)
            onClicked: {
                if (!controller) return
                if (mainWin.learning) {
                    controller.session.showSolution()
                } else {
                    controller.takeOverTableContent()
                    controller.session.start()
                    deriveNamesTableView.visible = false
                }
            }
        }
    }
}
