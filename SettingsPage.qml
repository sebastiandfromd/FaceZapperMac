import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material
import QtQuick.Layouts 1.15
import "."

// Settings: what to type, flash duration and the card box values, each with an explanation (ⓘ).
// Every change is stored right away (controller.setSetting -> QSettings).
Rectangle {
    id: settingsPage
    color: Theme.background
    signal done()

    // Esc on the desktop, the back button on Android
    focus: visible
    Keys.onEscapePressed: done()
    Keys.onBackPressed: done()

    // key, label, range, step and explanation of every number setting (defaults: Controller::defaultSettings)
    property var numberSettings: [
        { key: "learning/flashDuration", label: qsTr("Name einblenden (ms)"), from: 100, to: 3000, step: 100,
          info: qsTr("Wie lange der Name nach dem Wischen groß eingeblendet wird, in Millisekunden (1000 ms = 1 Sekunde).") },
        { key: "cardBox/easySeconds", label: qsTr("Sehr schnell: unter … Sekunden"), from: 1, to: 10, step: 1,
          info: qsTr("Wer ein Gesicht schneller als in dieser Zeit ohne Tippen nach links wischt, kannte die Person offensichtlich sicher. Die Karte rutscht dann besonders weit nach hinten (siehe „Sehr schnell: Faktor“).\n\nZeit, in der die App im Hintergrund war, zählt nicht mit.") },
        { key: "cardBox/unsureSeconds", label: qsTr("Lange angesehen: über … Sekunden"), from: 2, to: 60, step: 1,
          info: qsTr("Wer länger als diese Zeit überlegt, bevor er den ersten Buchstaben tippt (oder ohne Tippen wischt), war sich wohl nicht ganz sicher. Die Karte zählt als gewusst, kommt aber bald wieder (siehe „Unsicher“).\n\nDie Zeit fürs Tippen selbst zählt nicht mit, ebenso wenig Zeit, in der die App im Hintergrund war.") },
        { key: "cardBox/easyFactor", label: qsTr("Sehr schnell: Faktor"), from: 1, to: 10, step: 1,
          info: qsTr("Wie weit eine sehr schnell gewusste Karte nach hinten rutscht: Faktor × 2^Stufe Karten.\n\nDie Stufe steigt jedes Mal um 1, wenn die Person gewusst wird, und fällt auf 0, wenn nicht.\n\nBeispiel mit Faktor 4: Die Karte kommt nach 8, dann 16, dann 32 … anderen Karten wieder.") },
        { key: "cardBox/goodFactor", label: qsTr("Gewusst: Faktor"), from: 1, to: 10, step: 1,
          info: qsTr("Wie oben, aber für normal gewusste Karten: mit richtig getippten Buchstaben oder nach normaler Bedenkzeit.\n\nBeispiel mit Faktor 2: Die Karte kommt nach 4, dann 8, dann 16 … anderen Karten wieder.\n\nSollte kleiner sein als der Faktor für „Sehr schnell“.") },
        { key: "cardBox/unsureOffset", label: qsTr("Unsicher: kommt nach … Karten wieder"), from: 1, to: 50, step: 1,
          info: qsTr("Nach so vielen anderen Karten kommt eine Person wieder, die zwar gewusst wurde, aber erst nach langem Überlegen (siehe „Lange angesehen“).\n\nDie Stufe bleibt dabei unverändert. Ein mit ← korrigierter Vertipper zählt nicht negativ.") },
        { key: "cardBox/againOffset", label: qsTr("Nicht gewusst: kommt nach … Karten wieder"), from: 1, to: 50, step: 1,
          info: qsTr("Nach so vielen anderen Karten kommt eine Person wieder, die nicht gewusst wurde: „Unbekannt“ gedrückt oder einen falschen Buchstaben stehen gelassen.\n\nDie Stufe fällt dabei auf 0 zurück.") },
        { key: "cardBox/learnedStreak", label: qsTr("„Sicher“ nach … mal in Folge gewusst"), from: 1, to: 10, step: 1,
          info: qsTr("Ab wie vielen Malen hintereinander gewusst eine Person im Zähler unten links als „sicher“ zählt.") },
        { key: "cardBox/newCardInterval", label: qsTr("Neues Gesicht spätestens jede … Karte"), from: 2, to: 20, step: 1,
          info: qsTr("Solange es noch nie gezeigte Gesichter gibt, ist spätestens jede so vielte Karte ein neues Gesicht.\n\nSo halten schwierige Karten, die immer wieder vorne landen, die neuen nicht ewig auf.") }
    ]
    // bumped to re-read all values (after "Standardwerte")
    property int revision: 0
    // re-translated combo box texts reset their selection: re-read it after a language change
    Connections {
        target: controller
        function onLanguageChanged() { Qt.callLater(() => settingsPage.revision++) }
    }

    // header with the way back - always visible, not part of the scrolling list
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 48
        color: Theme.accent
        Button {
            id: backButton
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            flat: true
            Material.foreground: Theme.textOnAccent
            text: qsTr("‹ Zurück")
            onClicked: settingsPage.done()
        }
        Label {
            anchors.left: backButton.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Einstellungen")
            color: Theme.textOnAccent
            font.bold: true
            font.pixelSize: 20
        }
    }

    Popup {
        id: infoPopup
        property alias text: infoText.text
        anchors.centerIn: parent
        width: Math.min(settingsPage.width * 0.9, 420)
        modal: true
        padding: 16
        Label {
            id: infoText
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }

    component InfoButton: RoundButton {
        property string info
        text: "i"
        font.italic: true
        font.bold: true
        implicitWidth: 32
        implicitHeight: 32
        flat: true
        Material.foreground: Theme.accentDark
        background: Rectangle {
            implicitWidth: 26
            implicitHeight: 26
            anchors.centerIn: parent
            width: 26
            height: 26
            radius: 13
            color: parent.pressed ? Theme.accentMid : Theme.accentLight
        }
        onClicked: {
            infoPopup.text = info
            infoPopup.open()
        }
    }

    ScrollView {
        id: scroll
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        contentWidth: availableWidth
        clip: true

        // the settings on a white card
        Rectangle {
            width: settingsColumn.width + 24
            height: settingsColumn.implicitHeight + 24
            color: Theme.surface
            radius: Theme.radius
            border.color: Theme.divider

        ColumnLayout {
            id: settingsColumn
            x: 12
            y: 12
            // leave room for the scroll bar, so it doesn't cover the controls on the right
            width: scroll.availableWidth - (scroll.ScrollBar.vertical ? scroll.ScrollBar.vertical.width : 0) - 4 - 24
            spacing: 8

            // label with its ⓘ right behind the text, control on the right
            RowLayout {
                Layout.fillWidth: true
                Label { text: qsTr("Sprache") }
                InfoButton {
                    info: qsTr("Die Sprache der App. „Systemsprache“ nimmt die Sprache des Geräts – oder Englisch, wenn es die App in dieser Sprache nicht gibt.\n\nNamen und Gruppen bleiben, wie sie sind.")
                }
                Item { Layout.fillWidth: true }
                ComboBox {
                    id: languageBox
                    property var languages: controller ? controller.availableLanguages() : []
                    // "" = the system's language, stored in "ui/language" (kept by "Standardwerte")
                    model: [qsTr("Systemsprache")].concat(languages.map(l => l.name))
                    currentIndex: {
                        settingsPage.revision
                        if (!controller) return 0
                        controller.language // re-read after a change (the model is re-translated too)
                        const code = controller.setting("ui/language")
                        return 1 + languages.findIndex(l => l.code === code) // not found: 0
                    }
                    onActivated: (index) => controller.setLanguage(index > 0 ? languages[index - 1].code : "")
                    Layout.preferredWidth: 200
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label { text: qsTr("Eintippen") }
                InfoButton {
                    info: qsTr("Was beim Lernen eingetippt wird: nur der Vorname, nur der Nachname oder beides, in der gewählten Reihenfolge.\n\nBei „Nachname, Vorname“ ist das Komma eine eigene Taste, danach kommt das Leerzeichen.\n\nBei „Vorname Nachname“ dürfen weitere Vornamen weggelassen werden, wenn sie mit Leerzeichen getrennt sind („Anna Groß“ statt „Anna Lena Groß“), nicht aber mit Bindestrich („Anna-Lena“).\n\nBeim Wischen wird genau das geprüft und auch so eingeblendet, und die Buchstabenknöpfe bieten dafür den richtigen nächsten Buchstaben an.")
                }
                Item { Layout.fillWidth: true }
                ComboBox {
                    model: [qsTr("Vorname"), qsTr("Nachname"), qsTr("Vorname Nachname"), qsTr("Nachname, Vorname")]
                    currentIndex: { settingsPage.revision; return controller ? controller.setting("learning/targetMode") : 2 }
                    onActivated: (index) => controller.setSetting("learning/targetMode", index)
                    Layout.preferredWidth: 200
                }
            }

            Repeater {
                model: settingsPage.numberSettings
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: modelData.label
                        wrapMode: Text.WordWrap
                        // fixed room for ⓘ (32), spin box (160), spacing and the card's padding - not
                        // taken from the row itself, which would make the layout recalculate itself in a loop
                        Layout.maximumWidth: Math.max(80, scroll.availableWidth - 264)
                    }
                    InfoButton { info: modelData.info }
                    Item { Layout.fillWidth: true }
                    SpinBox {
                        from: modelData.from
                        to: modelData.to
                        stepSize: modelData.step
                        editable: true
                        value: { settingsPage.revision; return controller ? controller.setting(modelData.key) : from }
                        onValueModified: controller.setSetting(modelData.key, value)
                        Layout.preferredWidth: 160
                    }
                }
            }

            Button {
                text: qsTr("Standardwerte")
                flat: true
                Material.foreground: Theme.accent
                onClicked: {
                    controller.resetSettings()
                    settingsPage.revision++
                }
            }
        }
        }
    }
}
