import QtQuick 2.15
import QtQuick.Controls 2.15

// "Über FaceZapper": version, privacy in short, the example class and the open source notices
// (Qt under LGPLv3 with its source, the bundled third-party libraries with their licences).
// Links "license:<file>" show a licence text from licenses.qrc in the app, others open the browser.
Rectangle {
    id: aboutPage
    color: "white"
    signal done()
    property string shownLicense: "" // file name of the licence text on display, "" = the page itself

    function goBack() {
        if (shownLicense !== "") shownLicense = ""
        else done()
    }
    function openLink(link) {
        if (link.startsWith("license:")) shownLicense = link.substring(8)
        else Qt.openUrlExternally(link)
    }

    // Esc on the desktop, the back button on Android
    focus: visible
    Keys.onEscapePressed: goBack()
    Keys.onBackPressed: goBack()
    onVisibleChanged: shownLicense = ""

    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 48
        color: "teal"
        Button {
            id: backButton
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("‹ Zurück")
            onClicked: aboutPage.goBack()
        }
        Label {
            anchors.left: backButton.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: aboutPage.shownLicense !== "" ? aboutPage.shownLicense : qsTr("Über FaceZapper")
            color: "white"
            font.bold: true
            font.pixelSize: 20
        }
    }

    // the page itself
    ScrollView {
        id: scroll
        visible: aboutPage.shownLicense === ""
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        Text {
            width: scroll.availableWidth - 8
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
            linkColor: "teal"
            font.pixelSize: 15
            onLinkActivated: (link) => aboutPage.openLink(link)
            text: "<h2>FaceZapper</h2>"
                  + qsTr("Version %1").arg(Qt.application.version) + "<br>"
                  + qsTr("Namen und Gesichter lernen.") + "<br>"
                  + "© 2026 Sebastian Diel"
                  + "<h3>" + qsTr("Datenschutz") + "</h3>"
                  + qsTr("FaceZapper sammelt und sendet keine Daten – die App hat keinen Internetzugang. "
                         + "Fotos, Namen und Lernstand bleiben auf dem Gerät und im gewählten Ordner.")
                  + "<h3>" + qsTr("Beispielgruppe") + "</h3>"
                  + qsTr("Die Beispielfotos und Namen wurden mit %1 KI-generiert und stellen keine realen Personen dar.")
                    .arg("<a href=\"https://perchance.org/ai-character-generator\">https://perchance.org/ai-character-generator</a>")
                  + "<h3>" + qsTr("Open-Source-Software") + "</h3>"
                  + qsTr("Diese App verwendet Qt 6.12 (© The Qt Company Ltd. und andere), lizenziert unter der "
                         + "GNU Lesser General Public License v3 (%1), die auf die GNU General Public License v3 (%2) verweist.")
                    .arg("<a href=\"license:LGPL-3.0.txt\">" + qsTr("Lizenztext") + "</a>")
                    .arg("<a href=\"license:GPL-3.0.txt\">" + qsTr("Lizenztext") + "</a>")
                  + " " + qsTr("Der Quellcode von Qt 6.12 ist unter %1 erhältlich. "
                               + "Die Qt-Bibliotheken sind als eigene Dateien in der App enthalten und können ausgetauscht werden.")
                    .arg("<a href=\"https://download.qt.io/official_releases/qt/6.12/\">download.qt.io</a>")
                  + "<br><br>"
                  + qsTr("Qt enthält Bibliotheken anderer Autoren: FreeType, HarfBuzz, libpng, libjpeg-turbo, PCRE2, "
                         + "double-conversion, SHA-3 (Keccak), TinyCBOR, MD4C, libwebp, libtiff, den JavaScriptCore "
                         + "Macro Assembler und unter Windows zlib; dazu kommen die C++-Laufzeitbibliotheken "
                         + "(LLVM libc++ unter Android, GCC/MinGW-w64 unter Windows). %1")
                    .arg("<a href=\"license:THIRD-PARTY-NOTICES.txt\">" + qsTr("Lizenzen und Copyright-Hinweise") + "</a>")
                  + "<br><br>"
                  + "Portions of this software are copyright © 2026 The FreeType Project (www.freetype.org). All rights reserved."
        }
    }

    // a licence text
    ScrollView {
        id: licenseScroll
        visible: aboutPage.shownLicense !== ""
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        contentWidth: availableWidth
        clip: true

        Text {
            width: licenseScroll.availableWidth - 8
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            font.family: "monospace"
            font.pixelSize: 12
            text: aboutPage.shownLicense !== "" && controller ? controller.licenseText(aboutPage.shownLicense) : ""
        }
    }
}
