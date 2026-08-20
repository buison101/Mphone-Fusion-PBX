import QtQuick 2.15
import QtQuick.Controls 2.15
import AuthEngineModule 1.0
import Flux 1.0

import "../utils"

FocusScope {
    id: root

    property alias model: edit.model
    property alias hoverWidth: edit.width
    property alias hoverHeight: edit.height
    property alias edit: edit
    property alias placeholder: accPlaceholder
    property var gotoTab: 0
    property string delegateColorDefault: ColorStorage.surfaceSecondary
    property string delegateColorOnHover: ColorStorage.mainWindowBackground

    property var setFocus: function() {
       edit.forceActiveFocus();
    }

    property var onEnterPressed: function() {}

    ComboBox {
        id: edit

        editable: true
        font.family: "Segoe UI"
        font.pixelSize: 14

        Keys.onEnterPressed: {
            root.onEnterPressed()
        }

        Keys.onReturnPressed: {
            root.onEnterPressed()
        }

        Text {
            id: accPlaceholder

            anchors.verticalCenter: edit.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10 * AuthEngine.scale

            font.family: "Segoe UI"

            font.pixelSize: edit.font.pixelSize

            visible: edit.editText == "" && text != ""
        }

        delegate: Rectangle {
            width: edit.width - 2
            implicitHeight: 40 * AuthEngine.scale

            radius: index == 0 || index == listView.count - 1 ? 8 * AuthEngine.scale : 0

            color: root.delegateColorDefault

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10 * AuthEngine.scale
                anchors.top: parent.top
                anchors.verticalCenter: parent.verticalCenter
                text: modelData
                color: ColorStorage.iconsAndTextPrimary
                font: edit.font
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                id: topCorners

                anchors.top: parent.top

                width: parent.width
                height: parent.height / 4
                color: parent.color
                visible: index == listView.count - 1
            }

            Rectangle {
                id: bottomCorners

                anchors.bottom: parent.bottom

                width: parent.width
                height: parent.height / 4
                color: parent.color
                visible: index == 0
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    edit.currentIndex = index
                    listView.currentIndex = index
                    color = root.delegateColorOnHover
                }

                onExited: {
                    color = root.delegateColorDefault
                }

                onReleased: {
                    edit.popup.close()
                }
            }
        }

        indicator: Item{

            width: 25 * AuthEngine.scale
            height: width

            anchors.right: edit.right
            anchors.leftMargin: -edit.rightPadding
            anchors.top: edit.top
            anchors.topMargin: edit.topPadding + (edit.availableHeight - height) / 2

            Image {
                id: img
                width: 25 * AuthEngine.scale
                height: width
                source: "qrc:/images/chevron_down.svg"
                visible: false
            }

            IconShader {
                id: imageColor
                anchors.centerIn: parent
                visible: edit.count > 1 ? true : false
                imageSrcComponent: img
                imgColor: ColorStorage.iconsAndTextPrimary
                imageWidth: img.width
                imageHeight: img.height
            }

            Connections {
                target: edit
            }
        }


        contentItem: TextInput {
            id: textInput

            clip: contentWidth > width - rightPadding

            leftPadding: 10 * AuthEngine.scale
            rightPadding: edit.indicator.width + 10 + edit.spacing
            width: edit.width - img.width - 10

            text: edit.editText
            selectByMouse: true
            selectionColor: ColorStorage.selectionInputColor
            selectedTextColor: ColorStorage.iconsAndTextPrimary
            font: edit.font
            color: ColorStorage.iconsAndTextPrimary
            verticalAlignment: Text.AlignVCenter

            KeyNavigation.tab: root.gotoTab
        }

        background: Rectangle {
            implicitWidth: 120
            implicitHeight: 40

            color: ColorStorage.mainWindowBackground
            radius: 8 * AuthEngine.scale
        }

        popup: Popup {
            width: edit.width
            implicitHeight: contentItem.implicitHeight
            padding: 1

            contentItem: ListView {
                id: listView

                implicitHeight: edit.count <= 5 ? contentHeight + 2 : (contentHeight / edit.count) * 5
                model: edit.popup.visible ? edit.delegateModel : null

                boundsBehavior: Flickable.StopAtBounds
                clip: true

                ScrollBar.vertical: ScrollBar {
                    id: scrollBar
                    active: edit.count > 5
                }
            }

            background: Rectangle {
                radius: 8 * AuthEngine.scale
                color: ColorStorage.surfaceSecondary

                MenuShadow {
                    scale: AuthEngine.scale
                    anchors.fill: parent
                    bodyColor: ColorStorage.surfaceSecondary
                    shadowColor: ColorStorage.menuShadowColor
                }
            }
        }
    }
}
