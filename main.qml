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
    Component.onCompleted: {
        if (!controller) return
        showFolder()
        // first start (the example class is open) or no picture folder at all
        if (controller.firstRun || !controller.groupFolder) welcomeDialog.open()
    }

    // first start: what kind of folder is needed - then the red arrow points at the folder button
    TextDialog {
        id: welcomeDialog
        heading: qsTr("Willkommen bei FaceZapper!")
        standardButtons: Dialog.Ok
        message: (controller && controller.exampleOpen
                  ? qsTr("Zum Ausprobieren ist die Beispielgruppe „Klasse 10d (Beispiel)“ geöffnet – "
                         + "die Fotos sind KI-generiert, die Namen ausgedacht. Mit „Übernehmen“ geht es los.\n\n"
                         + "Für deine eigene Gruppe wählst du mit dem Ordner-Knopf oben links einen Ordner mit Fotos.\n\n")
                  : qsTr("Wähle zuerst einen Ordner mit Fotos der Personen, die du lernen möchtest – "
                         + "mit dem Ordner-Knopf oben links.\n\n"))
                 + qsTr("Die Dateinamen sollten die Namen enthalten, am besten so:\n"
                      + "    „Nachname, Vorname.jpg“  (z. B. „Muster, Anna.jpg“)\n"
                      + "oder so:\n"
                      + "    „Vorname Nachname.jpg“  (z. B. „Anna Muster.jpg“)\n\n"
                      + "Die Namen werden automatisch erkannt. Zusätze wie die Klasse „(09B)“ oder "
                      + "Nummern lassen sich mit „Komplexer“ entfernen.")
        onClosed: deriveNamesTableView.showFolderHint = true
    }

    FaceSwipeView {
        id: learnView
        anchors.fill: parent
    }
    FolderDialog {
        id: fileDialog

//        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        // start in the current group's folder ("D:/x" -> "file:///D:/x", "/x" -> "file:///x",
        // Android "content://..." stays as it is)
        // (the example class lives inside the app - the picker can't start there)
        currentFolder: !controller || !controller.groupFolder || controller.exampleOpen ? ""
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
        text: "×" // not "✕": Android's default font doesn't have that one
        font.pixelSize: 16
        onClicked: Qt.quit()
    }

    TextDialog {
        id: resetTrainingDialog
        heading: qsTr("Trainingsdaten zurücksetzen?")
        standardButtons: Dialog.Yes | Dialog.No
        message: qsTr("Alles Gelernte für „%1“ wird gelöscht. Namen und Einlese-Einstellungen bleiben erhalten.")
                 .arg(controller ? controller.groupName : "")
        onAccepted: controller.resetTrainingData()
    }
    TextDialog {
        id: resetFolderDialog
        heading: qsTr("Alle Gruppendaten löschen?")
        standardButtons: Dialog.Yes | Dialog.No
        message: qsTr("Gelerntes, Namenskorrekturen, Einlese-Einstellungen und Gruppenname von „%1“ werden gelöscht. Die Gruppe wird danach neu eingelesen, wie beim ersten Öffnen.")
                 .arg(controller ? controller.groupName : "")
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
            // on phones the rounded screen corner would cover the start of the lines
            anchors.leftMargin: 8 + (Qt.platform.os === "android" ? width / 3 : 0)
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
            text: "≡" // not "☰": Android's default font doesn't have that one
            font.pixelSize: 18
            onClicked: menu.open()
            Menu {
                id: menu
                // wide enough for the long entries (they were cut off on phones), right-aligned
                width: Math.min(mainWin.width - 16, 460)
                x: menuButton.width - width
                y: -height
                MenuItem {
                    text: qsTr("Namen bearbeiten")
                    enabled: mainWin.learning
                    onTriggered: mainWin.showImportTable()
                }
                MenuItem {
                    // back to the first page, picker right away (cancelled: stay on the first page)
                    text: qsTr("Gruppe ändern")
                    onTriggered: {
                        mainWin.showImportTable()
                        fileDialog.open()
                    }
                }
                Menu {
                    id: recentMenu
                    title: qsTr("Letzte Gruppen")
                    width: menu.width
                    enabled: count > 0
                    Instantiator {
                        model: controller ? controller.recentFolders : []
                        delegate: MenuItem {
                            text: modelData.name
                            // the group that is open now can't be chosen again
                            enabled: !controller || modelData.path !== controller.groupFolder
                            onTriggered: {
                                mainWin.showImportTable()
                                controller.groupFolder = modelData.path
                                mainWin.showFolder()
                            }
                        }
                        onObjectAdded: (index, object) => recentMenu.insertItem(index, object)
                        onObjectRemoved: (index, object) => recentMenu.removeItem(object)
                    }
                }
                MenuSeparator {}
                MenuItem {
                    text: qsTr("Trainingsdaten zurücksetzen")
                    onTriggered: resetTrainingDialog.open()
                }
                MenuItem {
                    text: qsTr("Alle Gruppendaten löschen")
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
