import QtQuick 2.15
import QtQuick.Controls 2.15

RadioButton {
    id: control
    text: qsTr("RadioButton")
    checked: true

    indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 10
        border.color: control.down ? "#bdbdbd" : "#bdbdbd"

        Rectangle {
            width: 12
            height: 12
            x: 4
            y: 4
            radius: 6
            color: control.down ? "black" : "black"
            visible: control.checked
        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? "black" : "black"
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
