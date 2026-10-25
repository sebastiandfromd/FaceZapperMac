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

    function showImportTable() {
        controller.session.clear()
        deriveNamesTableView.visible = true
    }
    function startLearning() {
        controller.takeOverTableContent()
        controller.session.start()
        deriveNamesTableView.visible = false
    }
    // a folder that was worked on before (it has a .faceZapperData) goes straight to learning,
    // a new one starts with the import table
    function showFolder() {
        if (controller.folderKnown) startLearning()
        else showImportTable()
    }
    Component.onCompleted: if (controller) showFolder()

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
            mainWin.showFolder()
        }
    }

    DeriveNamesTableView {
        anchors.fill: parent
        id: deriveNamesTableView

        onOpenFolderRequested: fileDialog.open()
    }

    SettingsPage {
        id: settingsPage
        anchors.fill: parent
        visible: false
        z: 10
        onDone: visible = false
    }

    // close the app (saves on the way out, see Controller: aboutToQuit) - not on the settings
    // page, which has its own way back
    RoundButton {
        visible: !settingsPage.visible
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        z: 20
        width: 36
        height: 36
        text: "✕"
        font.pixelSize: 16
        onClicked: Qt.quit()
    }

    Dialog {
        id: resetTrainingDialog
        anchors.centerIn: parent
        modal: true
        title: qsTr("Trainingsdaten zurücksetzen?")
        standardButtons: Dialog.Yes | Dialog.No
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: qsTr("Alles Gelernte für „%1“ wird gelöscht. Namen und Einlese-Einstellungen bleiben erhalten.")
                  .arg(controller ? controller.groupName : "")
        }
        onAccepted: controller.resetTrainingData()
    }
    Dialog {
        id: resetFolderDialog
        anchors.centerIn: parent
        modal: true
        title: qsTr("Alle Daten dieses Ordners zurücksetzen?")
        standardButtons: Dialog.Yes | Dialog.No
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: qsTr("Gelerntes, Namenskorrekturen, Einlese-Einstellungen und Gruppenname von „%1“ werden gelöscht. Der Ordner wird neu eingelesen.")
                  .arg(controller ? controller.groupName : "")
        }
        onAccepted: {
            mainWin.showImportTable()
            controller.resetFolderData()
        }
    }

    footer: Rectangle {
        id: footer
        visible: !settingsPage.visible
        height: 50
        implicitHeight: 50
        // no explicit width: ApplicationWindow stretches the footer over the whole window
        color: "red"
        // learning progress: all pictures / rated at least once / known several times in a row
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            visible: mainWin.learning && controller !== null
            property var session: controller ? controller.session : null
            Repeater {
                model: parent.session ? [qsTr("%1 Bilder").arg(parent.session.cardCount),
                                         qsTr("%1 gesehen").arg(parent.session.seenCount),
                                         qsTr("%1 sicher").arg(parent.session.learnedCount)] : []
                Text {
                    text: modelData
                    color: "black"
                    font.bold: true
                    font.pixelSize: 11
                }
            }
        }
        // shown when the data couldn't be saved in the picture folder itself
        Text {
            anchors.left: footerButton.right
            anchors.right: menuButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 8
            text: controller ? controller.storageHint : ""
            color: "white"
            wrapMode: Text.WordWrap
            font.pixelSize: 11
        }
        Button {
            id: footerButton
            anchors.centerIn: parent
            // import table: take the names over and start learning; learning: show the name
            text: mainWin.learning ? "Lösung" : "Übernehmen"
            enabled: !mainWin.learning || (controller && controller.session.currentPerson !== null
                                           && !controller.session.solutionVisible)
            onClicked: {
                if (!controller) return
                if (mainWin.learning) controller.session.showSolution()
                else mainWin.startLearning()
            }
        }
        Button {
            id: menuButton
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "☰"
            font.pixelSize: 18
            onClicked: menu.open()
            Menu {
                id: menu
                y: -height
                MenuItem {
                    text: qsTr("Namen bearbeiten")
                    enabled: mainWin.learning
                    onTriggered: mainWin.showImportTable()
                }
                MenuItem {
                    text: qsTr("Ordner öffnen")
                    onTriggered: fileDialog.open()
                }
                MenuSeparator {}
                MenuItem {
                    text: qsTr("Trainingsdaten zurücksetzen")
                    onTriggered: resetTrainingDialog.open()
                }
                MenuItem {
                    text: qsTr("Alle Daten dieses Ordners zurücksetzen")
                    onTriggered: resetFolderDialog.open()
                }
                MenuSeparator {}
                MenuItem {
                    text: qsTr("Einstellungen")
                    onTriggered: {
                        settingsPage.visible = true
                        settingsPage.forceActiveFocus() // for Esc / Android back
                    }
                }
            }
        }
    }
}
