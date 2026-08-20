import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

Slider {
    id:control
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 20
        implicitHeight: 20
        radius: 13
        color: control.pressed ? "#f0f0f0" : "#f6f6f6"
        border.color: "gray"
        border.width: 1
    }


    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 6
        width: control.availableWidth
        height: implicitHeight
        radius: 3
        opacity: enabled ? 1 : 0.3
        color: ColorStorage.white

        Rectangle {
            opacity: enabled ? 1 : 0.3
            width: control.visualPosition * parent.width
            height: parent.height
            color: "black"
            radius: 3
        }
    }
}
