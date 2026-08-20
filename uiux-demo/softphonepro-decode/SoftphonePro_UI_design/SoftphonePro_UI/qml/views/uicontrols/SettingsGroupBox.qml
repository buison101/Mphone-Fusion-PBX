import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

GroupBox {
    id:  groupBox

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    label: Label {
        width: groupBox.availableWidth
        text: groupBox.title
        font.pixelSize: 11
        elide: Text.ElideRight
        anchors.left: groupBox.left
        anchors.bottom: groupBox.top
        anchors.bottomMargin: -height / 2
        anchors.leftMargin: 10

        background: Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: - 3
            width: parent.paintedWidth + 6
            height: parent.paintedHeight
            color: ColorStorage.settingsWindowBaseColor
        }
    }

    background: Rectangle {
        width: parent.width
        height: parent.height
        color: "transparent"
        border.color: "#dcdcdc"
        radius: 1
    }
}
