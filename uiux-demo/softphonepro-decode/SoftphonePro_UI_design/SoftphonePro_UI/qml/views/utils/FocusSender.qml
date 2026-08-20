import QtQuick 2.15

MouseArea {
    property var receiver

    acceptedButtons: Qt.LeftButton

    onPressed: {
        receiver.forceActiveFocus();
    }
}
