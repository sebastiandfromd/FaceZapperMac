import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material
import QtQuick.Dialogs
//import QtCore
import "."

ApplicationWindow {
    id: mainWin
    width: 640
    height: 480
    visible: true
    title: qsTr("FaceZapper")
    color: Theme.background
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
    AboutPage {
        id: aboutPage
        anchors.fill: parent
        visible: false
        z: 10
        onDone: visible = false
    }

    // close the app (saves on the way out, see Controller: aboutToQuit) - not on the settings
    // page, which has its own way back
    RoundButton {
        visible: !settingsPage.visible && !aboutPage.visible
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        z: 20
        width: 36
        height: 36
        flat: true
        text: "×" // not "✕": Android's default font doesn't have that one
        font.pixelSize: 18
        Material.foreground: Theme.textMuted
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
        visible: !settingsPage.visible && !aboutPage.visible
        height: 50
        implicitHeight: 50
        // no explicit width: ApplicationWindow stretches the footer over the whole window
        color: Theme.surface
        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: Theme.divider
        }
        // learning progress: a bar (green = known several times in a row, light teal = rated at
        // least once, the rest = all pictures) and the three numbers in one line below it
        Column {
            id: progress
            anchors.left: parent.left
            // on phones the rounded screen corner would cover the start of the lines
            anchors.leftMargin: 8 + (Qt.platform.os === "android" ? 40 : 0)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(90, Math.min(200, footerButtons.x - x - 12))
            spacing: 3
            visible: mainWin.learning && controller !== null
            property var session: controller ? controller.session : null
            property int cards: session ? session.cardCount : 0
            property int seen: session ? session.seenCount : 0
            property int learned: session ? session.learnedCount : 0
            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: Theme.divider
                clip: true
                Rectangle {
                    height: parent.height
                    color: Theme.accentMid
                    width: progress.cards > 0 ? parent.width * progress.seen / progress.cards : 0
                    Behavior on width { NumberAnimation { duration: 250 } }
                }
                Rectangle {
                    height: parent.height
                    color: Theme.known
                    width: progress.cards > 0 ? parent.width * progress.learned / progress.cards : 0
                    Behavior on width { NumberAnimation { duration: 250 } }
                }
            }
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                color: Theme.textMuted
                textFormat: Text.StyledText
                text: "<font color=\"" + Theme.known + "\">" + qsTr("%n sicher", "", progress.learned) + "</font>"
                      + " · " + qsTr("%n gesehen", "", progress.seen)
                      + " · " + qsTr("%n Bilder", "", progress.cards)
            }
        }
        // shown when the data couldn't be saved in the picture folder itself
        Text {
            anchors.left: footerButtons.right
            anchors.right: menuButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 8
            text: controller ? controller.storageHint : ""
            color: Theme.textMuted
            wrapMode: Text.WordWrap
            font.pixelSize: 11
        }
        // import table: take the names over and start learning;
        // learning: "Bekannt" (= swipe left) and "Unbekannt" (shows the name)
        Row {
            id: footerButtons
            anchors.centerIn: parent
            spacing: 10
            Button {
                visible: !mainWin.learning
                text: qsTr("Übernehmen")
                highlighted: true
                Material.accent: Theme.accent
                onClicked: if (controller) mainWin.startLearning()
            }
            Button {
                visible: mainWin.learning
                text: qsTr("Bekannt")
                highlighted: true
                Material.accent: Theme.known
                enabled: controller !== null && controller.session.currentPerson !== null && !learnView.busy
                onClicked: learnView.markKnown()
            }
            Button {
                visible: mainWin.learning
                text: qsTr("Unbekannt")
                highlighted: true
                Material.accent: Theme.unknown
                enabled: controller !== null && controller.session.currentPerson !== null
                         && !controller.session.solutionVisible && !learnView.busy
                onClicked: controller.session.showSolution()
            }
        }
        Button {
            id: menuButton
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            flat: true
            text: "≡" // not "☰": Android's default font doesn't have that one
            font.pixelSize: 22
            Material.foreground: Theme.text
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
                MenuItem {
                    text: qsTr("Über FaceZapper")
                    onTriggered: {
                        aboutPage.visible = true
                        aboutPage.forceActiveFocus() // for Esc / Android back
                    }
                }
            }
        }
    }
}
