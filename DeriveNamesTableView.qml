import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    property int pageType: FaceSwipeView.PageType.SHOW_FOLDER_PAGE
    property int borderwidth: 1
    property color bordercolor: "darkgray"
    property real widthEighth: ((11/12)*width) / 8
    property real widthMargin: width/24
    property real heightUnit: delimiterTitle.height * 1.8
    id: showFolderComponentRect
    Rectangle {
        id: deleteNumberTitleRect
        color: "white";
        width: 1 * widthEighth
        height: heightUnit
        anchors.top: parent.top
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
        color: "lightgray";
        width: 1.2 * widthEighth
        height: heightUnit
        anchors.top: parent.top
        anchors.left: deleteNumberTitleRect.right
        border.width: borderwidth
        border.color: bordercolor
        ComboBox {
            model: ListModel {
                ListElement { text: "links" }
                ListElement { text: "rechts" }
                ListElement { text: "außen" }
            }
            popup.font.pointSize: font.pointSize
            currentIndex: controller ? controller.deleteNumberLocationIndex : 0
            anchors.fill: parent
            padding: 0
            anchors.topMargin: -1
            anchors.bottomMargin: -1
            leftInset: 0
            topInset: 0
            bottomInset: 0
            rightInset: 0
            font.pointSize: delimiterInput.font.pointSize
            onCurrentIndexChanged: if (controller) {
                                       controller.deleteNumberLocationIndex = currentIndex
                                       controller.runNameDerivation()
                                   }
        }
    }
    Rectangle {
        id: deleteNumberCountRect
        color: "lightgray";
        width: 1 * widthEighth
        height: heightUnit
        anchors.top: parent.top
        anchors.left: deleteNumberLocationRect.right
        border.width: borderwidth
        border.color: bordercolor
        ComboBox {
            model: ListModel {
                ListElement { text: "0 Z." }
                ListElement { text: "1 Z." }
                ListElement { text: "2 Z." }
                ListElement { text: "3 Z." }
                ListElement { text: "4 Z." }
                ListElement { text: "5 Z." }
                ListElement { text: "6 Z." }
                ListElement { text: "7 Z." }
            }
            popup.font.pointSize: font.pointSize
            currentIndex: controller ? controller.deleteNumberCountIndex : 0
            anchors.fill: parent
            padding: 0
            anchors.topMargin: -1
            anchors.bottomMargin: -1
            leftInset: 0
            topInset: 0
            bottomInset: 0
            rightInset: 0
            font.pointSize: delimiterInput.font.pointSize
            onCurrentIndexChanged: if (controller) {
                                       controller.deleteNumberCountIndex = currentIndex
                                       controller.runNameDerivation()
                                   }
        }
    }
    Rectangle {
        id: deleteAndTitleRect
        color: "white";
        width: 0.6 * widthEighth
        height: heightUnit
        anchors.top: parent.top
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
        color: "lightgray";
        width: 1.2 * widthEighth
        height: heightUnit
        anchors.top: parent.top
        anchors.right: deleteCharsTextRect.left
        border.width: borderwidth
        border.color: bordercolor
        ComboBox {
            model: ListModel {
                ListElement { text: "links" }
                ListElement { text: "rechts" }
                ListElement { text: "außen" }
                ListElement { text: "nicht" }
                ListElement { text: "ganz" }
            }
            popup.font.pointSize: font.pointSize
            currentIndex: controller ? controller.deleteCharsLocationIndex : 0
            anchors.fill: parent
            padding: 0
            anchors.topMargin: -1
            anchors.bottomMargin: -1
            leftInset: 0
            topInset: 0
            bottomInset: 0
            rightInset: 0
            font.pointSize: delimiterInput.font.pointSize
            onCurrentIndexChanged: if (controller) {
                                       controller.deleteCharsLocationIndex = currentIndex
                                       controller.runNameDerivation()
                                   }
        }
    }
    Rectangle {
        id: deleteCharsTextRect
        color: "wheat"
        width: 3 * widthEighth
        height: heightUnit
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: widthMargin
        border.width: borderwidth
        border.color: bordercolor
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
        color: "white";
        width: 1 * widthEighth
        height: heightUnit
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
        color: "wheat"
        width: 2.8 * widthEighth - heightUnit
        height: heightUnit
        anchors.top: deleteNumberTitleRect.bottom
        anchors.left: replaceFromTitleRect.right
        border.width: borderwidth
        border.color: bordercolor
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
        color: "blue"
        height: heightUnit
        width: height
        anchors.top: deleteNumberTitleRect.bottom
        anchors.left: replaceFromTextRect.right
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "white"
        }
        Text {
            anchors.fill: parent
            text: "i"
            color: "blue"
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
                border.color: "darkgray"
                color: "lightblue"
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
        color: "white";
        width: 0.8 * widthEighth
        height: heightUnit
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
        color: "wheat"
        width: 2.8 * widthEighth-heightUnit
        height: heightUnit
        anchors.top: deleteNumberTitleRect.bottom
        anchors.right: infoReplaceToRect.left
        border.width: borderwidth
        border.color: bordercolor
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
        color: "blue"
        height: heightUnit
        width: height
        anchors.top: deleteNumberTitleRect.bottom
        anchors.right: caseSensitivityRect.left
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "white"
        }
        Text {
            anchors.fill: parent
            text: "i"
            color: "blue"
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
                border.color: "darkgray"
                color: "lightblue"
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
        color: caseSensitivityMouseArea.pressed ? "red":"lightgray";
        width: 0.6 * widthEighth
        height: heightUnit
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
        color: "white";
        width: 1.4 * widthEighth
        height: heightUnit
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
        color: "wheat"
        width: 2.6 * widthEighth
        height: heightUnit
        anchors.top: replaceFromTitleRect.bottom
        anchors.left: delimiterTitleRect.right
        border.width: borderwidth
        border.color: bordercolor
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
        color: "lightgray";
        width: 2 * widthEighth
        height: heightUnit
        anchors.top: replaceFromTitleRect.bottom
        anchors.right: nameOrderRect.left
        border.width: borderwidth
        border.color: bordercolor
        ComboBox {
            model: ListModel {
                ListElement { text: "1. v. Links" }
                ListElement { text: "1. v. Rechts" }
                ListElement { text: "2. v. Links" }
                ListElement { text: "2. v. Rechts" }
                ListElement { text: "Mitte/links" }
                ListElement { text: "Mitte/rechts" }
            }
            popup.font.pointSize: font.pointSize
            currentIndex: controller ? controller.delimiterCounterIndex : 0
            anchors.fill: parent
            padding: 0
            anchors.topMargin: -1
            anchors.bottomMargin: -1
            leftInset: 0
            topInset: 0
            bottomInset: 0
            rightInset: 0
            font.pointSize: delimiterInput.font.pointSize
            onCurrentIndexChanged: if (controller) {
                                       controller.delimiterCounterIndex = currentIndex
                                       controller.runNameDerivation()
                                   }
        }
    }
    Rectangle {
        id: nameOrderRect
        color: "lightgray"
        width: 2 * widthEighth
        height: heightUnit
        anchors.top: replaceFromTitleRect.bottom
        anchors.right: parent.right
        anchors.rightMargin: widthMargin
        border.width: borderwidth
        border.color: bordercolor
        ComboBox {
            model: ListModel {
                id: nameOrderModel
                ListElement { text: "Vor-/Nachname." }
                ListElement { text: "Nach-/Vorname" }
            }
            popup.font.pointSize: font.pointSize
            currentIndex: controller ? (controller.firstNameFirst ? 0 : 1) : 0
            anchors.fill: parent
            padding: 0
            anchors.topMargin: -1
            anchors.bottomMargin: -1
            leftInset: 0
            topInset: 0
            bottomInset: 0
            rightInset: 0
            font.pointSize: delimiterInput.font.pointSize
            onCurrentIndexChanged: {
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
        columnWidthProvider: function c(column) {
            switch (column) {
            case 0: return (width * 30/100) - nameTable.borderwidth
            case 1: return (width * 30/100) - nameTable.borderwidth
            case 2: return (width * 40/100) - nameTable.borderwidth
            default: return 0
            }
        }
        width: parent.width * 22/24
        height: parent.height - delimiterTitleRect.height - replaceFromTitleRect.height - verticalSpaceToTable.height - 3 *borderwidth
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
            implicitWidth: 100
            implicitHeight: 20
            border.color: "black"
            border.width: borderwidth
            color: heading ? 'teal': (exclude && column === 2 ? "tomato" : (overrideAutomatic && !exclude && column !== 2 ? "wheat" : "white"))
            clip: true
            TextInput {
                width: parent.width
                text: (exclude && column !== 2) ? "" : tabledata
                font.pointSize: 10
                anchors.centerIn: parent
                enabled: overrideAutomatic && (column!== 2)
                onTextChanged: {
                    if (nameDerivationTable) nameDerivationTable.editData(row, column, text)
                }
                padding: 1
                leftPadding: height/4
            }
            MouseArea {
                anchors.fill: parent
                enabled: !overrideAutomatic || (column === 2)
                onClicked: {
                    nameDerivationTable.clicked(row, column)
                }
            }
        }
    }
}
