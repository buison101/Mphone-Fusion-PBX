import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

MenuSeparator {
    id: root

    padding: 0
    topPadding: 0
    bottomPadding: 0
    z: 1

    property string color: "grey"

    contentItem: Rectangle {
        id: rect
        implicitWidth: 200
        implicitHeight: 1 * SettingsState.scale

        color: root.color
    }
}
