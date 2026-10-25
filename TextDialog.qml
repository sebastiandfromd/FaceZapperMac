import QtQuick 2.15
import QtQuick.Controls 2.15

// Dialog with a bold heading and a wrapping text.
// The heading is part of the content on purpose: Dialog's own `title` together with a wrapping
// text makes Qt 6.12 report a binding loop for implicitHeight.
Dialog {
    id: textDialog
    property string heading
    property string message
    anchors.centerIn: parent
    width: Math.min(parent.width * 0.9, 560)
    modal: true

    Column {
        width: textDialog.availableWidth
        spacing: 12
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: textDialog.heading
            font.bold: true
            font.pixelSize: 20
        }
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: textDialog.message
        }
    }
}
