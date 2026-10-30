pragma Singleton
import QtQuick 2.15

// Colors and sizes of the whole app (light only). The brand colors come from the icon:
// green and red stand for the answer (known / not known) and are kept for that,
// teal is the accent for everything else.
QtObject {
    // surfaces
    readonly property color background: "#f6f4ef"   // warm off-white behind everything
    readonly property color surface: "#ffffff"      // cards, footer, table cells
    readonly property color border: "#d6d2c8"
    readonly property color divider: "#e4e0d6"

    // text
    readonly property color text: "#1f2a2a"
    readonly property color textMuted: "#5f5e5a"
    readonly property color textOnAccent: "#ffffff"

    // accent
    readonly property color accent: "#008080"
    readonly property color accentDark: "#005c5c"
    readonly property color accentLight: "#e1f2f2"
    readonly property color accentMid: "#9fd3d3"

    // answers (LearningSession.Outcome)
    readonly property color known: "#008f39"
    readonly property color almost: "#f9c825"
    readonly property color unknown: "#e2001a"
    // light tints of them for table rows: excluded / names edited by hand
    readonly property color unknownLight: "#fbe1e4"
    readonly property color almostLight: "#fdf3cf"

    // sizes
    readonly property int radius: 8
    readonly property int smallRadius: 5
}
