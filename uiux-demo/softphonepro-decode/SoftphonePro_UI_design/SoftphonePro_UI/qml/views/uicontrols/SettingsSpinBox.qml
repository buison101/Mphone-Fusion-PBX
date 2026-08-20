import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T

T.SpinBox {
    id: control

    height: 30
    width: 140
    property int buttonsWidth: 25
    property int buttonsHeight: 40
    padding: 6

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentItem.implicitWidth + 2 * padding +
                            up.implicitIndicatorWidth +
                            down.implicitIndicatorWidth)
    implicitHeight: Math.max(implicitContentHeight + topPadding + bottomPadding,
                             implicitBackgroundHeight,
                             up.implicitIndicatorHeight,
                             down.implicitIndicatorHeight)

    rightPadding: padding + (control.mirrored ? (down.indicator ? down.indicator.width : 0) : (up.indicator ? up.indicator.width : 0))

    validator: IntValidator {
        locale: control.locale.name
        bottom: Math.min(control.from, control.to)
        top: Math.max(control.from, control.to)
    }

    editable: true

    contentItem: TextInput {
        z: 2
        text: control.displayText

        font: control.font
        color: control.palette.text
        selectionColor: control.palette.highlight
        selectedTextColor: control.palette.highlightedText
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter

        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: control.inputMethodHints

        Rectangle {
            x: -padding
            y: -padding
            width: control.width - down.indicator.width
            height: control.height
            visible: control.activeFocus
            color: "transparent"
            border.color: control.palette.highlight
            border.width: 2
        }

        onTextChanged: {
           control.value =  parseInt(text);
        }
    }

    up.indicator: Rectangle {
        height: parent.height / 2
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: buttonsHeight
        implicitWidth: buttonsWidth
        color: control.up.pressed ? "#bdbdbd" : "#e0e0e0"
        border.color: "#bdbebf"
        Text {
            text: '+'
            anchors.centerIn: parent
        }
    }

    down.indicator: Rectangle {
        height: parent.height / 2
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: buttonsHeight
        implicitWidth: buttonsWidth
        color: control.down.pressed ? "#bdbdbd" : "#e0e0e0"
        border.color: "#bdbebf"
        Text {
            text: '-'
            anchors.centerIn: parent
        }
    }

    background: Rectangle {
        implicitWidth: control.width - down.indicator.width
        color: enabled ? control.palette.base : control.palette.button
        border.color: control.palette.button
    }
}
