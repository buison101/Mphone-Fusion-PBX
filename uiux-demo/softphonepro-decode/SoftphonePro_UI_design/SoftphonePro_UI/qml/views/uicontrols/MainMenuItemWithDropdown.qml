import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../utils"

MenuItem {
    id: root

    property alias actionLabel: action.text
    property alias shortcutLabel: shortcut.text

    property bool isDropdownOpen: dropdown.open
    property bool dropdownVisible: dropdown.visible
    property int elementWidth: 215 * SettingsState.scale
    property int elementHeight: 30 * SettingsState.scale
    property bool roundBottomCorners: false
    property bool roundTopCorners: false
    property int topMargin: 0 * SettingsState.scale
    property int bottomMargin: 0 * SettingsState.scale
    property alias model: view.model
    property alias viewVisible: view.visible

    property bool openedByShortcut: false
    property bool ignoreHover: false

    property var doWorkOnListItemClick: function() {}

    property var openDropdown: function() {
        root.ignoreHover = true;
        dropdown.open();
        view.currentIndex = 0;
        view.itemAtIndex(view.currentIndex).forceActiveFocus();
    }

    property var closeDropdown: function() {
        dropdown.close();
    } 

    padding: 0

    onHighlightedChanged: {
        if (highlighted) {
            root.forceActiveFocus();
            body.color = body.colorOnHover;
            root.openDropdown();
        } else {
            body.color = body.colorDefault;
            dropdown.close();

        }
    }

    Keys.onReturnPressed: {
        root.openDropdown();
    }

    Keys.onRightPressed: {
        root.openDropdown();
    }

    Popup {
        id: dropdown
        x: parent.width
        property int viewElementWidth: 0 * SettingsState.scale
        property double viewElementHeight: 29.75 * SettingsState.scale
        property int viewElementMaxWidth: 220 * SettingsState.scale

        property int viewFooterHeight: root.showAction ? viewElementHeight + 20 * SettingsState.scale : 0

        // add border in 1 px
        implicitWidth: viewElementWidth + 2 * SettingsState.scale
        implicitHeight: view.count ? viewElementHeight * view.count + viewFooterHeight + 2 * SettingsState.scale : viewFooterHeight + 2 * SettingsState.scale

        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

        onActiveFocusChanged: {
            if (!activeFocus) {
                dropdown.close();
            }
        }

        onAboutToHide: {
            root.forceActiveFocus();
        }

        onClosed: {
            root.ignoreHover = false;
            root.forceActiveFocus();
        }

        onOpened: {
            root.highlighted = true;
        }

        onVisibleChanged: {
            if (!visible) {
                viewElementWidth = 0;
            }
        }

        contentItem: ListView {
            id: view

            anchors.fill: parent
            anchors.margins: 1 * SettingsState.scale
            interactive: false
            focus: true

            Keys.onUpPressed: {
                if (view.currentIndex == 0) {
                    view.currentIndex = view.count - 1;
                    return;
                }

                view.decrementCurrentIndex();
            }

            Keys.onDownPressed: {
                if (view.currentIndex == view.count - 1) {
                    view.currentIndex = 0;
                    return;
                }

                view.incrementCurrentIndex();
            }

            Keys.onLeftPressed: {
                root.openedByShortcut = false;
                root.forceActiveFocus();
                dropdown.close();
                root.highlighted = true;
            }

            Keys.onReturnPressed: {
                root.doWorkOnListItemClick(view.currentIndex);
                dropdown.close();
            }
            delegate: Rectangle {
                id: delegateBody
                implicitWidth: dropdown.viewElementWidth
                implicitHeight: dropdown.viewElementHeight
                radius: (index == 0 || index == view.count - 1) ? 8 * SettingsState.scale : 0
                anchors.topMargin: 1 * SettingsState.scale
                anchors.bottomMargin: 1 * SettingsState.scale
                readonly property string colorDefault: ColorStorage.surfaceSecondary
                readonly property string colorOnHover: ColorStorage.mainWindowBackground
                property variant currentModel: model
                color: colorDefault

                onActiveFocusChanged: {
                    color = activeFocus ? colorOnHover : colorDefault;
                }

                Shortcut {
                    enabled: true
                    sequence: index + 1

                    onActivated: {
                        root.doWorkOnListItemClick(index);
                        dropdown.close();
                        root.forceActiveFocus();
                    }
                }

                MouseArea {
                    id: delegateMouseArea
                    anchors.fill: delegateBody
                    hoverEnabled: true

                    onEntered: {
                        if (root.ignoreHover && mouseX > 5 * SettingsState.scale && mouseX < parent.width - 5 * SettingsState.scale) {
                            if (index == 0 && mouseY > 5 * SettingsState.scale) {
                                return;
                            } else if (index == view.count - 1 && mouseY < parent.height - 5 * SettingsState.scale) {
                                return;
                            } else if (index != view.count - 1 && index != 0) {
                                return;
                            }
                        }
                        view.currentIndex = index;
                        delegateBody.forceActiveFocus();
                        root.openedByShortcut = false;
                    }

                    onExited: {
                        if (!parent.activeFocus) {
                            parent.color = parent.colorDefault;
                        }

                        if (mouseX > 120 * SettingsState.scale) {
                            dropdown.close();
                        }

                        if (index == view.count - 1 && mouseY > 20 * SettingsState.scale) {
                            dropdown.close();
                        }

                        if (index == 0 && mouseY < 20 * SettingsState.scale) {
                           dropdown.close();
                        }

                        root.ignoreHover = false;
                    }

                    onPressed: {
                        delegateBody.forceActiveFocus();
                        view.currentIndex = index;
                    }

                    onReleased: {
                        if (!containsMouse) {
                            return;
                        }

                        root.doWorkOnListItemClick(view.currentIndex);
                        dropdown.close();
                    }
                }

                Rectangle {
                    id: bottomCornersListView

                    anchors.bottom: parent.bottom

                    height: parent.height / 3
                    width: parent.width
                    color: parent.color
                    enabled: false
                    visible: view.count > 1 && index == 0
                }

                Rectangle {
                    id: topCornersListView

                    anchors.top: parent.top

                    height: parent.height / 3
                    width: parent.width
                    color: parent.color
                    enabled: false
                    visible: view.count > 1 && index == view.count - 1
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    Text {
                        id: description

                        anchors.left: checkImage.right
                        anchors.leftMargin: 5 * SettingsState.scale
                        anchors.verticalCenter: checkImage.verticalCenter
                        width: 80 * SettingsState.scale
                        font.family: "Segoe UI"
                        font.pixelSize: 12 * SettingsState.scale

                        color: ColorStorage.iconsAndTextPrimary

                        elide: Text.ElideRight
                        text: name
                        visible: dropdown.visible

                        onVisibleChanged: {
                            // to recalculate listview element's width
                            if(visible) {
                                updateWidth();
                            }
                        }

                        function updateWidth() {
                            var margin = 45 * SettingsState.scale;

                            if (description.width + margin > dropdown.viewElementMaxWidth) {
                                dropdown.viewElementWidth = dropdown.viewElementMaxWidth;
                                description.width = dropdown.viewElementMaxWidth - margin;
                                return;
                            }

                            var itemWidth = description.width + margin;
                            if (dropdown.viewElementWidth < itemWidth) {
                                dropdown.viewElementWidth = itemWidth;
                                return;
                            }
                        }

                        onTextChanged: {
                            updateWidth();
                        }

                        Component.onCompleted: {
                            updateWidth();
                        }
                    }

                    Image {
                        id: checkImage
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 5 * SettingsState.scale

                        width: 18 * SettingsState.scale
                        height: 18 * SettingsState.scale
                        visible: false

                        sourceSize.width: width
                        sourceSize.height: height

                        source: selected ? "qrc:/images/check.svg" : ""
                    }

                    IconShader {
                        visible: selected
                        anchors.centerIn: checkImage
                        imageSrcComponent: checkImage
                        imgColor: ColorStorage.iconsAndTextSecondary

                        imageWidth: checkImage.width
                        imageHeight: checkImage.height
                    }
                }
            }
        }

        background: Rectangle {
            radius: 8 * SettingsState.scale
            color: ColorStorage.surfaceSecondary

            MenuShadow {
                scale: SettingsState.scale
                anchors.fill: parent
                bodyColor: ColorStorage.surfaceSecondary
                shadowColor: ColorStorage.menuShadowColor
            }
        }
    }

    Shortcut {
        enabled: true
        sequence: root.shortcut

        onActivated: {
            root.triggered();
        }
    }

    background: Rectangle {
        id: border

        color: "transparent"

        implicitWidth: root.elementWidth
        implicitHeight: root.elementHeight

        Rectangle {
            id: body

            anchors.top: parent.top
            anchors.topMargin: root.topMargin
            anchors.left: parent.left
            anchors.leftMargin: 1 * SettingsState.scale

            implicitWidth: border.width - 2 * SettingsState.scale
            implicitHeight: border.height - root.topMargin - root.bottomMargin
            radius: roundBottomCorners || roundTopCorners ? 8 * SettingsState.scale : 0
            opacity: enabled ? 1 : 0.3

            readonly property string colorDefault: ColorStorage.surfaceSecondary
            readonly property string colorOnHover: ColorStorage.mainWindowBackground

            color: dropdown.visible ? colorOnHover : colorDefault

            MouseArea {
                enabled: root.enabled

                anchors.left: parent.left
                width: root.elementWidth
                height: root.elementHeight
                hoverEnabled: true

                onClicked: {
                    dropdown.open();
                    view.itemAtIndex(view.currentIndex).forceActiveFocus();
                    root.highlighted = true;
                }

                onEntered: {
                    if (root.ignoreHover) {
                        return;
                    }

                    dropdown.open();
                    view.itemAtIndex(view.currentIndex).forceActiveFocus();
                    root.highlighted = true;
                }

                onExited: {
                    root.ignoreHover = false;
                    if (mouseX < dropdown.viewElementWidth) {
                        dropdown.close();
                    }
                    if (!dropdown.visible) {
                        root.highlighted = false;
                    }
                }
            }
            Rectangle {
                id: bottomCorners

                anchors.bottom: parent.bottom

                height: parent.height / 3
                width: parent.width
                color: parent.color
                enabled: false
                visible: roundTopCorners
            }

            Rectangle {
                id: topCorners

                anchors.top: parent.top

                height: parent.height / 3
                width: parent.width
                color: parent.color
                enabled: false
                visible: roundBottomCorners
            }
        }
    }
    contentItem: Rectangle {
        width: body.width
        height: body.height
        color: "transparent"

        Text {
            id: action

            anchors.left: parent.left
            anchors.leftMargin: 20 * SettingsState.scale
            anchors.verticalCenter: parent.verticalCenter

            font.family: "Segoe UI"
            font.pixelSize: 12 * SettingsState.scale

            color: root.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.iconsAndTextSecondary
        }

        Text {
            id: shortcut

            anchors.right: parent.right
            anchors.rightMargin: 10 * SettingsState.scale
            anchors.verticalCenter: parent.verticalCenter

            font.family: "Segoe UI"
            font.pixelSize: 12 * SettingsState.scale

            color: root.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.iconsAndTextSecondary
        }

        Item {
            id: canvas
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10 * SettingsState.scale
            width: 9 * SettingsState.scale
            height: 9 * SettingsState.scale
            Canvas {
                anchors.fill: parent
                onPaint: {
                    const context = getContext("2d");
                    context.fillStyle = ColorStorage.iconsAndTextSecondary;
                    context.strokeStyle = ColorStorage.iconsAndTextSecondary;

                    context.beginPath();
                    context.moveTo(parent.width/2, parent.height);
                    context.lineTo(parent.width, parent.height/2);
                    context.lineTo(parent.width/2,0);
                    context.closePath();
                    context.fill();
                    context.stroke();
                }
            }
        }

    }
}
