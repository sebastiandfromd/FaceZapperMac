import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: mainWin
    width: 640
    height: 480
    visible: true
    title: qsTr("FaceZapper")

    enum PageType {
        FACE_PAGE,
        SHOW_FOLDER_PAGE,
        SETTINGS_PAGE
    }
    property int test1: Main.PageType.FACE_PAGE
    property int test2: mainWin.PageType.FACE_PAGE
    property int test3: ApplicationWindow.PageType.FACE_PAGE
    SwipeView {
        id: swipeView
        property int lastIndex: -1;
        property int counter: 0
        anchors.fill: parent
        property bool creationInProgress: false;
        property var colors: ["orange", "lightgreen", "yellow"]
        background: Rectangle { color: "blue" }


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
            addItem(showFolderComponent.createObject(swipeView));
            for (var i = 0; i<4; i++) {
                // create a number of pre-load pages
                addItem(picPageComponent.createObject(swipeView, {color: swipeView.colors[counter%3], count: counter++, person: controller.nextPersonData()}));
            }
        }
        Component {
            id: showFolderComponent
            Rectangle {
                property bool isSettingsPage: false
                property int pageType: SHOW_FOLDER_PAGE
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
                            ListElement { text: "nicht" }
                            ListElement { text: "links" }
                            ListElement { text: "rechts" }
                            ListElement { text: "außen" }
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
                    width: 3 * widthEighth
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
                    id: replaceWithTitleRect
                    color: "white";
                    width: 1 * widthEighth
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
                    width: 3 * widthEighth
                    height: heightUnit
                    anchors.top: deleteNumberTitleRect.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: widthMargin
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
                    id: delimiterTitleRect
                    color: "white";
                    width: 2 * widthEighth
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
                    width: 2 * widthEighth
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

                        default: return loggedItemsTableView.column0Width;
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
        }

        Component {
            id: picPageComponent
            Rectangle {
                property int count: -1
                property var person: null
                property bool isSettingsPage: false
                property int pageType: Main.PageType.FACE_PAGE
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
                property bool isSettingsPage: true
                property int pageType: swipeView.PageType.SETTINGS_PAGE
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

    footer: Rectangle {
        id: footer
        height: 50
        implicitHeight: 50
        width: swipeView.width
        implicitWidth: 50
        color: "red"
        Button {
            visible: swipeView.currentItem.pageType === FACE_PAGE
//            visible: !swipeView.currentItem.isSettingsPage
            anchors.centerIn: parent
            text: "Settings"
            onClicked: {
                if (!swipeView.currentItem.isSettingsPage) swipeView.createSettingsPage()
            }
        }
        Button {
//            visible: !swipeView.currentItem.isSettingsPage
            visible: swipeView.currentItem.pageType === SHOW_FOLDER_PAGE
            anchors.centerIn: parent
            text: "Übernehmen"
            onClicked: {
                if (!swipeView.currentItem.isSettingsPage) swipeView.createSettingsPage()
            }
        }
    }
}
