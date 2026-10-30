import QtQuick 2.15
import QtQuick.Controls 2.15
import "."

Rectangle {
    color: Theme.background
    property int borderwidth: 1
    property color bordercolor: Theme.border
    property real widthEighth: ((11/12)*width) / 8
    property real widthMargin: width/24
    property real heightMargin: widthMargin/2
    property real heightUnit: delimiterTitle.height * 1.8
    // basic mode: only group name and table, the automatic detection does the rest;
    // expert mode also shows the rows for deleting/replacing characters and splitting the names
    property bool expertMode: controller ? controller.setting("ui/expertMode") : false
    property real expertRowHeight: expertMode ? heightUnit : 0
    id: showFolderComponentRect
    signal openFolderRequested()
    // first start: a red arrow points at the folder button until a folder is chosen
    property bool showFolderHint: false
    // re-translated combo box texts reset their selection - bumped to re-read it from the controller
    property int languageRevision: 0
    Connections {
        target: controller
        function onLanguageChanged() { Qt.callLater(() => showFolderComponentRect.languageRevision++) }
    }

    Rectangle {
        id: openFolderRect
        color: openFolderMouseArea.pressed ? Theme.accentLight : Theme.background
        width: heightUnit
        height: heightUnit
        anchors.top: parent.top
        anchors.right: groupNameTitleRect.left
        anchors.rightMargin: heightMargin
        border.width: borderwidth
        border.color: bordercolor
        Text {
            anchors.centerIn: parent
            text: "📂"
            font.pointSize: delimiterInput.font.pointSize
        }
        MouseArea {
            id: openFolderMouseArea
            anchors.fill: parent
            onClicked: showFolderComponentRect.openFolderRequested()
        }
    }
    // red arrow from bottom right up to the folder button (drawn: no font needed, works on Android)
    Canvas {
        id: folderHintArrow
        // until the user picks a folder of their own (none yet, or still the example class)
        visible: showFolderComponentRect.showFolderHint && controller && (!controller.groupFolder || controller.exampleOpen)
        z: 10
        width: 3 * heightUnit
        height: 3 * heightUnit
        property real bounce: 0
        x: openFolderRect.x + openFolderRect.width * 0.6 + bounce
        y: openFolderRect.y + openFolderRect.height + bounce
        SequentialAnimation on bounce {
            running: folderHintArrow.visible
            loops: Animation.Infinite
            NumberAnimation { to: heightUnit / 3; duration: 450; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 0; duration: 450; easing.type: Easing.InOutQuad }
        }
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var w = width, h = height, head = width / 4
            ctx.strokeStyle = Theme.unknown
            ctx.fillStyle = Theme.unknown
            ctx.lineWidth = Math.max(4, width / 14)
            ctx.lineCap = "round"
            ctx.beginPath()          // shaft: from bottom right towards the tip at top left
            ctx.moveTo(w - ctx.lineWidth, h - ctx.lineWidth)
            ctx.lineTo(head * 0.5, head * 0.5)
            ctx.stroke()
            ctx.beginPath()          // head
            ctx.moveTo(0, 0)
            ctx.lineTo(head * 1.3, head * 0.25)
            ctx.lineTo(head * 0.25, head * 1.3)
            ctx.closePath()
            ctx.fill()
        }
        onWidthChanged: requestPaint()
    }
    Rectangle {
        id: groupNameTitleRect
        color: Theme.surface
        width: 2 * widthEighth - widthMargin
        height: heightUnit
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 2 * widthMargin
        border.width: borderwidth
        border.color: bordercolor
        Text {
            id: groupNameTitle
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("Name der Gruppe:")
            height: replaceFromTitle.contentHeight
            width: parent.width
            padding: 1
            rightPadding: height/2
        }
    }
    Rectangle {
        id: expertModeRect
        color: expertModeMouseArea.pressed ? Theme.accentLight : Theme.background
        width: 1.2 * widthEighth
        height: heightUnit
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: 2 * widthMargin
        border.width: borderwidth
        border.color: bordercolor
        Text {
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: showFolderComponentRect.expertMode ? qsTr("Einfacher") : qsTr("Komplexer")
            fontSizeMode: Text.HorizontalFit
            minimumPointSize: 6
            font.pointSize: delimiterInput.font.pointSize
        }
        MouseArea {
            id: expertModeMouseArea
            anchors.fill: parent
            onClicked: {
                showFolderComponentRect.expertMode = !showFolderComponentRect.expertMode
                if (controller) controller.setSetting("ui/expertMode", showFolderComponentRect.expertMode)
            }
        }
    }
    Rectangle {
        id: groupNameTextRect
        color: Theme.accentLight
        height: heightUnit
        anchors.top: parent.top
        anchors.left: groupNameTitleRect.right
        anchors.right: expertModeRect.left
        anchors.rightMargin: heightMargin
        border.width: borderwidth
        border.color: bordercolor
        TextInput {
            id:  groupNameTextInput
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            padding: 1
            leftPadding: height/4
            text: controller ? controller.groupName : ""
            width: parent.width
            onTextChanged: if (controller) controller.groupName = text
//            onEditingFinished: if (controller) controller.runNameDerivation()
            clip: true
            font.bold: true
            font.letterSpacing: 1.3
            color: Theme.accentDark
        }
    }
    Rectangle {
        id: deleteNumberTitleRect
        visible: expertMode
        color: Theme.surface
        width: 1 * widthEighth
        height: expertRowHeight
        anchors.top: groupNameTitleRect.bottom
        anchors.topMargin: expertMode ? heightMargin : 0
        anchors.left: parent.left
        anchors.leftMargin: widthMargin
        border.width: borderwidth
        border.color: bordercolor
        Text {
            id: deleteNumberTitle
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("Entferne")
            height: replaceFromTitle.contentHeight
            width: parent.width
            padding: 1
            rightPadding: height/2
        }
    }
    Rectangle {
        id: deleteNumberLocationRect
        visible: expertMode
        color: Theme.background
        width: 1.2 * widthEighth
        height: expertRowHeight
        anchors.top: groupNameTitleRect.bottom
        anchors.topMargin: expertMode ? heightMargin : 0
        anchors.left: deleteNumberTitleRect.right
        border.width: borderwidth
        border.color: bordercolor
        ComboBox {
            model: [qsTr("links"), qsTr("rechts"), qsTr("außen")]
            popup.font.pointSize: font.pointSize
            currentIndex: { showFolderComponentRect.languageRevision; return controller ? controller.deleteNumberLocationIndex : 0 }
            anchors.fill: parent
            padding: 0
            anchors.topMargin: -1
            anchors.bottomMargin: -1
            leftInset: 0
            topInset: 0
            bottomInset: 0
            rightInset: 0
            font.pointSize: delimiterInput.font.pointSize
            onActivated: if (controller) {
                                       controller.deleteNumberLocationIndex = currentIndex
                                       controller.runNameDerivation()
                                   }
        }
    }
    Rectangle {
        id: deleteNumberCountRect
        visible: expertMode
        color: Theme.background
        width: 1 * widthEighth
        height: expertRowHeight
        anchors.top: groupNameTitleRect.bottom
        anchors.topMargin: expertMode ? heightMargin : 0
        anchors.left: deleteNumberLocationRect.right
        border.width: borderwidth
        border.color: bordercolor
        ComboBox {
            model: Array.from({ length: 13 }, (_, i) => qsTr("%1 Z.", "number of characters").arg(i))
            popup.font.pointSize: font.pointSize
            currentIndex: { showFolderComponentRect.languageRevision; return controller ? controller.deleteNumberCountIndex : 0 }
            anchors.fill: parent
            padding: 0
            anchors.topMargin: -1
            anchors.bottomMargin: -1
            leftInset: 0
            topInset: 0
            bottomInset: 0
            rightInset: 0
            font.pointSize: delimiterInput.font.pointSize
            onActivated: if (controller) {
                                       controller.deleteNumberCountIndex = currentIndex
                                       controller.runNameDerivation()
                                   }
        }
    }
    Rectangle {
        id: deleteAndTitleRect
        visible: expertMode
        color: Theme.surface
        width: 0.6 * widthEighth
        height: expertRowHeight
        anchors.top: groupNameTitleRect.bottom
        anchors.topMargin: expertMode ? heightMargin : 0
        anchors.left: deleteNumberCountRect.right
        border.width: borderwidth
        border.color: bordercolor
        Text {
            id: deleteAndTitle
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("und")
            height: replaceFromTitle.contentHeight
            width: parent.width
            padding: 1
            rightPadding: height/2
        }
    }
    Rectangle {
        id: deleteCharsLocationRect
        visible: expertMode
        color: Theme.background
        width: 1.2 * widthEighth
        height: expertRowHeight
        anchors.top: groupNameTitleRect.bottom
        anchors.topMargin: expertMode ? heightMargin : 0
        anchors.right: deleteCharsTextRect.left
        border.width: borderwidth
        border.color: bordercolor
        ComboBox {
            model: [qsTr("links"), qsTr("rechts"), qsTr("außen"), qsTr("nicht"), qsTr("ganz")]
            popup.font.pointSize: font.pointSize
            currentIndex: { showFolderComponentRect.languageRevision; return controller ? controller.deleteCharsLocationIndex : 0 }
            anchors.fill: parent
            padding: 0
            anchors.topMargin: -1
            anchors.bottomMargin: -1
            leftInset: 0
            topInset: 0
            bottomInset: 0
            rightInset: 0
            font.pointSize: delimiterInput.font.pointSize
            onActivated: if (controller) {
                                       controller.deleteCharsLocationIndex = currentIndex
                                       controller.runNameDerivation()
                                   }
        }
    }
    Rectangle {
        id: deleteCharsTextRect
        visible: expertMode
        color: Theme.surface
        width: 3 * widthEighth
        height: expertRowHeight
        anchors.top: groupNameTitleRect.bottom
        anchors.topMargin: expertMode ? heightMargin : 0
        anchors.right: parent.right
        anchors.rightMargin: widthMargin
        border.width: borderwidth
        border.color: deleteCharsTextInput.activeFocus ? Theme.accent : bordercolor
        TextInput {
            id: deleteCharsTextInput
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            padding: 1
            leftPadding: height/4
            text: controller ? controller.deleteCharsText : ""
            width: parent.width
            onTextChanged: if (controller) controller.deleteCharsText = text
            onEditingFinished: if (controller) controller.runNameDerivation()
            clip: true
        }
    }
    Rectangle {
        id: replaceFromTitleRect
        visible: expertMode
        color: Theme.surface
        width: 1 * widthEighth
        height: expertRowHeight
        anchors.top: deleteNumberTitleRect.bottom
        anchors.left: parent.left
        anchors.leftMargin: widthMargin
        border.width: borderwidth
        border.color: bordercolor
        Text {
            id: replaceFromTitle
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("Ersetze")
            height: replaceFromTitle.contentHeight
            width: parent.width
            padding: 1
            rightPadding: height/2
        }
    }
    Rectangle {
        id: replaceFromTextRect
        visible: expertMode
        color: Theme.surface
        width: 2.8 * widthEighth - heightUnit
        height: expertRowHeight
        anchors.top: deleteNumberTitleRect.bottom
        anchors.left: replaceFromTitleRect.right
        border.width: borderwidth
        border.color: replaceFromInput.activeFocus ? Theme.accent : bordercolor
        TextInput {
            id: replaceFromInput
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            padding: 1
            leftPadding: height/4
            text: controller ? controller.replaceFrom : ""
            width: parent.width
            onTextChanged: if (controller) controller.replaceFrom = text
            onEditingFinished: if (controller) controller.runNameDerivation()
        }
    }
    Rectangle {
        id: infoReplaceFromRect
        visible: expertMode
        color: "transparent"
        height: expertRowHeight
        width: height
        anchors.top: deleteNumberTitleRect.bottom
        anchors.left: replaceFromTextRect.right
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.accent
        }
        Text {
            anchors.fill: parent
            text: "i"
            color: Theme.textOnAccent
            font.bold: true
            font.italic: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: replaceWithTitle.font.pixelSize * 1.6
            font.weight: 19
        }
        Dialog {
            id: infoReplaceFromPopup
            width: Math.min(showFolderComponentRect.width, showFolderComponentRect.height) * 0.8
            height: width
            anchors.centerIn: parent
            standardButtons: Dialog.Ok
            parent: Overlay.overlay
            Rectangle {
                anchors.fill: parent
                border.width: 1
                border.color: Theme.border
                color: Theme.accentLight
                Text {
                    id: infoReplaceFromText
                    text: qsTr("Spezielle Suchzeichen: \n\n/? Beliebiges Zeichen\n/# Beliebige Ziffer\n/$ Beliebiger Buchstabe\n/% Beliebige Ziffernfolge\n/W Beliebige Buchstabenfolge")
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: infoReplaceFromPopup.open()
        }
    }
    Rectangle {
        id: replaceWithTitleRect
        visible: expertMode
        color: Theme.surface
        width: 0.8 * widthEighth
        height: expertRowHeight
        anchors.top: deleteNumberTitleRect.bottom
        anchors.right: replaceWithTextRect.left
        border.width: borderwidth
        border.color: bordercolor
        Text {
            id: replaceWithTitle
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("durch")
            height: replaceWithTitle.contentHeight
            width: parent.width
            padding: 1
            rightPadding: height/4
        }
    }
    Rectangle {
        id: replaceWithTextRect
        visible: expertMode
        color: Theme.surface
        width: 2.8 * widthEighth-heightUnit
        height: expertRowHeight
        anchors.top: deleteNumberTitleRect.bottom
        anchors.right: infoReplaceToRect.left
        border.width: borderwidth
        border.color: replaceWithInput.activeFocus ? Theme.accent : bordercolor
        TextInput {
            id: replaceWithInput
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            padding: 1
            leftPadding: height/4
            text: controller ? controller.replaceTo : ""
            width: parent.width
            onTextChanged: if (controller) controller.replaceTo = text
            onEditingFinished: if (controller) controller.runNameDerivation()
        }
    }
    Rectangle {
        id: infoReplaceToRect
        visible: expertMode
        color: "transparent"
        height: expertRowHeight
        width: height
        anchors.top: deleteNumberTitleRect.bottom
        anchors.right: caseSensitivityRect.left
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.accent
        }
        Text {
            anchors.fill: parent
            text: "i"
            color: Theme.textOnAccent
            font.bold: true
            font.italic: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: replaceWithTitle.font.pixelSize * 1.6
        }
        Dialog {
            id: infoReplaceToPopup
            width: Math.min(showFolderComponentRect.width, showFolderComponentRect.height) * 0.8
            height: width
            anchors.centerIn: parent
            standardButtons: Dialog.Ok
            parent: Overlay.overlay
            Rectangle {
                anchors.fill: parent
                border.width: 1
                border.color: Theme.border
                color: Theme.accentLight
                Text {
                    id: infoReplaceToText
                    text: qsTr("Spezielles Ersetzungszeichen: \n\n/& 'Ersetze'-Suchtext")
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: infoReplaceToPopup.open()
        }
    }
    Rectangle {
        id: caseSensitivityRect
        visible: expertMode
        color: caseSensitivityMouseArea.pressed ? Theme.accentLight : Theme.background
        width: 0.6 * widthEighth
        height: expertRowHeight
        anchors.top: deleteNumberTitleRect.bottom
        anchors.right: parent.right
        anchors.rightMargin: widthMargin
        border.width: borderwidth
        border.color: bordercolor
        Text {
            anchors.fill: parent
            text: controller ? (controller.isCaseSensitive ? "a≠A" : "a=A") : ""
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
        MouseArea {
            id: caseSensitivityMouseArea
            anchors.fill: parent
            onClicked: if (controller) {
                           controller.isCaseSensitive = !controller.isCaseSensitive
                           controller.runNameDerivation()
                       }
        }
    }
    Rectangle {
        id: delimiterTitleRect
        visible: expertMode
        color: Theme.surface
        width: 1.1 * widthEighth
        height: expertRowHeight
        anchors.top: replaceFromTitleRect.bottom
        anchors.left: parent.left
        anchors.leftMargin: widthMargin
        border.width: borderwidth
        border.color: bordercolor
        Text {
            id: delimiterTitle
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("Trenne bei")
            height: delimiterTitle.contentHeight
            width: parent.width
            padding: 1
            rightPadding: height/2
        }
    }
    Rectangle {
        id: delimiterTextRect
        visible: expertMode
        color: Theme.surface
        width: 2.3 * widthEighth
        height: expertRowHeight
        anchors.top: replaceFromTitleRect.bottom
        anchors.left: delimiterTitleRect.right
        border.width: borderwidth
        border.color: delimiterInput.activeFocus ? Theme.accent : bordercolor
        TextInput {
            id: delimiterInput
            anchors.centerIn: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            padding: 1
            leftPadding: height/4
            text: controller ? controller.delimiter : ""
            width: parent.width
            onTextChanged: if (controller) controller.delimiter = text
            onEditingFinished: if (controller) controller.runNameDerivation()
        }
    }
    Rectangle {
        id: delimiterCounterRect
        visible: expertMode
        color: Theme.background
        width: 2 * widthEighth
        height: expertRowHeight
        anchors.top: replaceFromTitleRect.bottom
        anchors.right: caseCorrectionRect.left
        border.width: borderwidth
        border.color: bordercolor
        ComboBox {
            model: [qsTr("1. v. links"), qsTr("1. v. rechts"), qsTr("2. v. links"), qsTr("2. v. rechts"),
                    qsTr("Mitte/links"), qsTr("Mitte/rechts")]
            popup.font.pointSize: font.pointSize
            currentIndex: { showFolderComponentRect.languageRevision; return controller ? controller.delimiterCounterIndex : 0 }
            anchors.fill: parent
            padding: 0
            anchors.topMargin: -1
            anchors.bottomMargin: -1
            leftInset: 0
            topInset: 0
            bottomInset: 0
            rightInset: 0
            font.pointSize: delimiterInput.font.pointSize
            onActivated: if (controller) {
                                       controller.delimiterCounterIndex = currentIndex
                                       controller.runNameDerivation()
                                   }
        }
    }
    Rectangle {
        id: caseCorrectionRect
        visible: expertMode
        color: caseCorrectionMouseArea.pressed ? Theme.accentLight : Theme.background
        width: 0.6 * widthEighth
        height: expertRowHeight
        anchors.top: replaceFromTitleRect.bottom
        anchors.right: nameOrderRect.left
        border.width: borderwidth
        border.color: bordercolor
        Text {
            anchors.fill: parent
            text: controller ? (controller.correctCase ? "Abc" : "abc") : ""
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
        MouseArea {
            id: caseCorrectionMouseArea
            anchors.fill: parent
            onClicked: if (controller) {
                           controller.correctCase = !controller.correctCase
                           controller.runNameDerivation()
                       }
        }
    }
    Rectangle {
        id: nameOrderRect
        visible: expertMode
        color: Theme.background
        width: 2 * widthEighth
        height: expertRowHeight
        anchors.top: replaceFromTitleRect.bottom
        anchors.right: parent.right
        anchors.rightMargin: widthMargin
        border.width: borderwidth
        border.color: bordercolor
        ComboBox {
            model: [qsTr("Vor-/Nachname"), qsTr("Nach-/Vorname")]
            popup.font.pointSize: font.pointSize
            currentIndex: { showFolderComponentRect.languageRevision; return controller ? (controller.firstNameFirst ? 0 : 1) : 0 }
            anchors.fill: parent
            padding: 0
            anchors.topMargin: -1
            anchors.bottomMargin: -1
            leftInset: 0
            topInset: 0
            bottomInset: 0
            rightInset: 0
            font.pointSize: delimiterInput.font.pointSize
            onActivated: {
                if (controller) {
                    controller.firstNameFirst = (currentIndex == 0);
                    controller.runNameDerivation()
                }
            }
        }
    }
    Rectangle {
        id: verticalSpaceToTable
        color: "transparent"
        height: parent.width/50
        width: parent.width
        anchors.top: nameOrderRect.bottom
        anchors.left: replaceFromTitleRect.left
    }

    TableView {
        id: nameTable
        function combinedHeights () {
            var heightResult = 0
            for (var i = 0; i < arguments.length; i++) {
                heightResult += (arguments[i].height + arguments[i].anchors.topMargin);
            }
            return heightResult
        }
        columnWidthProvider: function c(column) {
            var rest = width - rowHeight - 3 * columnSpacing
            switch (column) {
            case 0: return rowHeight // square mode button
            case 1: return (rest * 30/100) - nameTable.borderwidth
            case 2: return (rest * 30/100) - nameTable.borderwidth
            case 3: return (rest * 40/100) - nameTable.borderwidth
            default: return 0
            }
        }
        property int rowHeight: 20
        width: parent.width * 22/24
        height: parent.height - combinedHeights(groupNameTitleRect, deleteNumberTitleRect, delimiterTitleRect, replaceFromTitleRect, verticalSpaceToTable) - 3 *borderwidth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: verticalSpaceToTable.bottom
        columnSpacing: 1
        rowSpacing: 1
        clip: true
        property int borderwidth: 1
        ScrollIndicator.horizontal: ScrollIndicator { }
        ScrollIndicator.vertical: ScrollIndicator { }
        model: nameDerivationTable
        delegate: Rectangle {
            id: nameTableRect
            // column 0: mode button, 1: first name, 2: family name, 3: file
            property bool modeColumn: column === 0
            property bool nameColumn: column === 1 || column === 2
            implicitWidth: 100
            implicitHeight: nameTable.rowHeight
            border.color: Theme.divider
            border.width: borderwidth
            color: heading ? Theme.accent
                           : modeColumn ? (exclude ? Theme.unknownLight : (overrideAutomatic ? Theme.almostLight : Theme.surface))
                                        : (exclude && column === 3 ? Theme.unknownLight : (overrideAutomatic && nameColumn ? Theme.almostLight : Theme.surface))
            clip: true
            TextInput {
                visible: !modeColumn
                width: parent.width
                text: heading ? ["", qsTr("Vorname"), qsTr("Nachname"), qsTr("Datei")][column]
                              : (exclude && nameColumn) ? "" : tabledata
                font.pointSize: 10
                anchors.centerIn: parent
                enabled: overrideAutomatic && nameColumn
                color: heading ? Theme.textOnAccent : Theme.text
                onTextChanged: {
                    if (nameDerivationTable && !heading) nameDerivationTable.dataEdited(row, column, text)
                }
                padding: 1
                leftPadding: height/4
            }
            // mode button: automatic -> manual -> excluded -> automatic
            Text {
                visible: modeColumn && !heading
                anchors.centerIn: parent
                font.pointSize: 10
                text: exclude ? "✕" : (overrideAutomatic ? "✎" : "A")
            }
            MouseArea {
                anchors.fill: parent
                enabled: modeColumn && !heading
                onClicked: {
                    if (controller) controller.nameDerivationTableClicked(row, column);
                }
            }
        }
    }
}
