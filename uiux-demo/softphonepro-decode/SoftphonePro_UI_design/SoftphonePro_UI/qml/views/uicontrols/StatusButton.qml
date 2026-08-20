import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import Flux 1.0

import "../utils"

FocusScope {
    id: root

    property alias hoverWide: body.width
    property alias hoverHeigth: body.height

    property alias selection: selectionText.text
    property alias selectionSize: selectionText.font.pixelSize
    property alias selectionImage: selectionImage.source

    property bool alignRight: false

    property int popupX: 0
    property int popupY: 0

    implicitWidth: hoverWide
    implicitHeight: hoverHeigth

    property var openDropdown: function() {
        statusesDropdownLoader.item.dropdown.ignoreHover = true;
        statusesDropdownLoader.item.dropdown.open();
        statusesDropdownLoader.item.view.currentIndex = statusesDropdownLoader.item.view.currentItem.currentModel.selectedIdx;
        statusesDropdownLoader.item.view.forceActiveFocus();
    }

    property var closeDropdown: function() {
        statusesDropdownLoader.item.dropdown.close();
    }

    property var doWorkOnListItemClick: function() {}

    focus: true

    Keys.onSpacePressed: {
        openDropdown();
    }

    Keys.onReturnPressed: {
        openDropdown();
    }

    Keys.onEnterPressed: {
        openDropdown();
    }

    onActiveFocusChanged: {
        body.color = activeFocus && !body.skipHover ? body.colorOnHover : body.colorDefault;
        if (!activeFocus) {
            body.skipHover = false;
        }
    }

    Rectangle {
        id: body

        radius: 8 * SettingsState.scale

        implicitWidth: hoverWide/*162 * SettingsState.scale*/
        implicitHeight: hoverHeigth//42 * SettingsState.scale

        readonly property string colorDefault: ColorStorage.secondaryWindowBackground
        readonly property string colorOnHover: ColorStorage.windowBorder
        readonly property string colorOnPress: ColorStorage.windowBorder

        property bool skipHover: false

        color: colorDefault

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                body.color = body.colorOnHover;
            }

            onExited: {
                if (!root.activeFocus || body.skipHover) {
                    body.color = body.colorDefault;
                }
            }

            onPressed: {
                body.color = body.colorOnPress;
                statusesDropdownLoader.item.dropdown.ignoreHover = true;
                statusesDropdownLoader.item.dropdown.open();
                statusesDropdownLoader.item.view.currentIndex = statusesDropdownLoader.item.view.currentItem.currentModel.selectedIdx;
                statusesDropdownLoader.item.view.forceActiveFocus();
            }

            onReleased: {
                body.color = body.colorDefault;
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: 16 * SettingsState.scale

            Image {
                id: selectionImage
                anchors.verticalCenter: parent.verticalCenter

                anchors.left: parent.left

                width: 12 * SettingsState.scale
                height: 12 * SettingsState.scale

                sourceSize.width: width
                sourceSize.height: height

                source: "qrc:/images/blank_circle_green.svg"
            }

            Text {
                id: selectionText

                anchors.verticalCenter: selectionImage.verticalCenter

                anchors.left: selectionImage.right
                anchors.leftMargin: 6 * SettingsState.scale
                horizontalAlignment: Text.AlignLeft

                width: hoverWide - selectionImage.width - chevronImage.width - 35 * SettingsState.scale

                font.family: "Segoe UI"
                font.bold: true
                font.pixelSize: 16 * SettingsState.scale

                elide: Text.ElideRight

                color: ColorStorage.iconsAndTextPrimary
            }

            Image {
                id: chevronImage

                anchors.right: parent.right
                anchors.verticalCenter: selectionText.verticalCenter
                visible: false

                width: 18 * SettingsState.scale
                height: 18 * SettingsState.scale

                sourceSize.width: width
                sourceSize.height: height

                source: "qrc:/images/chevron_down_white.svg" 
            }

            IconShader {
                anchors.centerIn: chevronImage
                imageSrcComponent: chevronImage
                imgColor: ColorStorage.iconsAndTextSecondary
                imageWidth: chevronImage.width
                imageHeight: chevronImage.height
            }
        }

        FocusScope {
            anchors.top: body.top
            anchors.right: root.alignRight ? body.right : undefined
            anchors.left: root.alignRight ? undefined : body.left

            focus: true

            implicitWidth: statusesDropdownLoader.width
            implicitHeight: statusesDropdownLoader.height

            Component {
                id: statusesDropdownComponent
                ApplicationWindow {
                    id: window

                    property alias dropdown: dropdown
                    property alias view: view
                    property int windowRescale: AppFeatures.osType == OSType.MacOS ? 0 : 12 * SettingsState.scale

                    flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint | Qt.WindowStaysOnTopHint

                    x: root.popupX - 6 * SettingsState.scale
                    y: root.popupY - 6 * SettingsState.scale

                    width: scope.width + windowRescale
                    height: scope.height + windowRescale
                    color: "transparent"

                    visible: dropdown.visible

                    FocusScope {
                        id: scope

                        implicitWidth: dropdown.implicitWidth
                        implicitHeight: dropdown.implicitHeight

                        property alias dropdown: dropdown
                        property alias view: view

                        focus: true

                        Popup {
                            id: dropdown
                            property int viewElementWidth: 165 * SettingsState.scale
                            property int viewElementHeight: 45 * SettingsState.scale
                            property int viewElementMaxWidth: 250 * SettingsState.scale
                            property int viewElementMinWidth: 165 * SettingsState.scale
                            property int viewMaxElementCount: 11 * SettingsState.scale

                            property bool alreadyClosed: false

                            property bool ignoreHover: false

                            // add border in 1 px
                            implicitWidth: view.count ? viewElementWidth + 2 * SettingsState.scale : 0
                            implicitHeight: {
                                var rowCount = viewMaxElementCount > view.count ?
                                            view.count : viewMaxElementCount;

                                return view.count ? viewElementHeight * rowCount + 2 * SettingsState.scale : 0;
                            }

                            closePolicy: Popup.CloseOnPressOutside

                            margins: AppFeatures.osType == OSType.MacOS ? 0 : 6 * SettingsState.scale

                            onClosed: {
                                ignoreHover = false;
                            }

                            onActiveFocusChanged: {
                                if (alreadyClosed) {
                                    alreadyClosed = false;
                                    return;
                                }
                                if (!activeFocus) {
                                    closeDropdown();
                                }
                            }

                            contentItem: ListView {
                                id: view

                                anchors.fill: parent
                                anchors.margins: 1 * SettingsState.scale

                                boundsBehavior: Flickable.StopAtBounds

                                interactive: true
                                keyNavigationWraps: true

                                model: AppState.phoneStatusModel

                                layer.enabled: true
                                layer.textureSize: Qt.size(1920 * SettingsState.scale, 1080 * SettingsState.scale)
                                layer.effect: OpacityMask {
                                    source: view
                                    maskSource: Rectangle {
                                        width: view.width
                                        height: view.height
                                        anchors.top: parent.top

                                        radius: 8 * SettingsState.scale
                                    }
                                }

                                focus: true

                                ScrollBar.vertical: ScrollBar {
                                    id: scrollBar
                                    active: view.count > dropdown.viewMaxElementCount
                                }

                                Keys.onUpPressed: {
                                    view.decrementCurrentIndex();
                                }

                                Keys.onDownPressed: {
                                    view.incrementCurrentIndex();
                                }

                                Keys.onTabPressed: {
                                    dropdown.alreadyClosed = true;
                                    dropdown.focus = false;
                                    dropdown.close();
                                    mainWindow.requestActivate();
                                }

                                Keys.onEscapePressed: {
                                    dropdown.alreadyClosed = true;
                                    dropdown.focus = false;
                                    dropdown.close();
                                    mainWindow.requestActivate();
                                }

                                Keys.onReturnPressed: {
                                    if (view.enabled) {
                                        root.doWorkOnListItemClick(view.currentIndex);
                                        dropdown.alreadyClosed = true;
                                        dropdown.focus = false;
                                        dropdown.close();
                                        mainWindow.requestActivate();
                                    }
                                }

                                Keys.onEnterPressed: {
                                    if (view.enabled) {
                                        root.doWorkOnListItemClick(view.currentIndex);
                                        dropdown.alreadyClosed = true;
                                        dropdown.focus = false;
                                        dropdown.close();
                                        mainWindow.requestActivate();
                                    }
                                }

                                delegate: Rectangle {
                                    id: delegateBody
                                    radius: (index == 0 || index == view.count - 1) ? 8 * SettingsState.scale : 0
                                    implicitWidth: dropdown.viewElementWidth
                                    implicitHeight: dropdown.viewElementHeight
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
                                            if (statusEnabled) {
                                                root.doWorkOnListItemClick(index);
                                                dropdown.alreadyClosed = true;
                                                dropdown.close();
                                                root.forceActiveFocus();
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: delegateBody
                                        hoverEnabled: true

                                        onEntered: {
                                            if (dropdown.ignoreHover && mouseX > 5 && mouseX < delegateBody.implicitWidth - 15) {
                                                if (index == 0 && mouseY > 5) {
                                                    return;
                                                } else if (index == view.count - 1 && mouseY < parent.height - 5) {
                                                    return;
                                                } else if (index != 0 && index != view.count - 1) {
                                                    return;
                                                }
                                            }
                                            view.currentIndex = index;
                                            parent.color = parent.colorOnHover;
                                        }

                                        onExited: {
                                            if (!parent.activeFocus) {
                                                parent.color = parent.colorDefault;
                                            }
                                            dropdown.ignoreHover = false;
                                        }

                                        onPressed: {
                                            parent.forceActiveFocus();
                                            view.currentIndex = index;
                                        }

                                        onReleased: {
                                            if (!containsMouse) {
                                                return;
                                            }

                                            if (statusEnabled) {
                                                root.doWorkOnListItemClick(view.currentIndex);
                                                dropdown.alreadyClosed = true;
                                                dropdown.close();

                                                window.close();
                                                body.skipHover = true;
                                                root.forceActiveFocus();
                                                view.currentIndex =view.currentItem.currentModel.selectedIdx;
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
                                        visible: view.count > 1 && index == 0
                                    }

                                    Rectangle {
                                        id: topCorners

                                        anchors.top: parent.top

                                        height: parent.height / 3
                                        width: parent.width
                                        color: parent.color
                                        enabled: false
                                        visible: view.count > 1 && index == view.count - 1
                                    }

                                    Loader {
                                        id: loader
                                        anchors.fill: parent
                                        sourceComponent: normalDelegate
                                    }

                                    Component {
                                        id: normalDelegate

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.topMargin: 10 * SettingsState.scale
                                            anchors.bottomMargin: 10 * SettingsState.scale
                                            anchors.leftMargin: 20 * SettingsState.scale

                                            Accessible.name: name
                                            Accessible.role: Accessible.Button

                                            color: "transparent"

                                            Image {
                                                id: image

                                                anchors.top: parent.top
                                                anchors.left: parent.left

                                                width: 18 * SettingsState.scale
                                                height: 18 * SettingsState.scale

                                                sourceSize.width: width
                                                sourceSize.height: height

                                                source: icon
                                            }

                                            Text {
                                                id: status

                                                anchors.verticalCenter: image.verticalCenter
                                                anchors.left:  image.right
                                                anchors.leftMargin: 10 * SettingsState.scale
                                                anchors.right: selectedImage.left
                                                anchors.rightMargin: 5 * SettingsState.scale

                                                font.family: "Segoe UI"
                                                font.pixelSize: 13 * SettingsState.scale

                                                elide: Text.ElideRight

                                                color: statusEnabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.iconsAndTextSecondary

                                                text: name

                                                Component.onCompleted: {
                                                    var margin = 55 * SettingsState.scale;

                                                    var itemWidth = status.implicitWidth + margin + selectedImage.width + image.width;
                                                    if (itemWidth < dropdown.viewElementWidth) {
                                                        return;
                                                    }

                                                    if (itemWidth > dropdown.viewElementMaxWidth) {
                                                        dropdown.viewElementWidth = dropdown.viewElementMaxWidth;
                                                        return;
                                                    }

                                                    if (itemWidth > dropdown.viewElementMinWidth) {
                                                        dropdown.viewElementWidth = itemWidth;
                                                        return;
                                                    }
                                                }
                                            }

                                            Image {
                                                id: selectedImage

                                                anchors.right: parent.right
                                                anchors.rightMargin: 20 * SettingsState.scale
                                                anchors.verticalCenter: status.verticalCenter

                                                width: 24 * SettingsState.scale
                                                height: 24 * SettingsState.scale

                                                sourceSize.width: width
                                                sourceSize.height: height

                                                source: "qrc:/images/check.svg"
                                                visible: false
                                            }

                                            IconShader {
                                                anchors.centerIn: selectedImage
                                                visible: selected
                                                imageSrcComponent: selectedImage
                                                imgColor: ColorStorage.iconsAndTextSecondary
                                                imageWidth: selectedImage.width
                                                imageHeight: selectedImage.height
                                            }
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
                                    visible: dropdown.visible
                                    bodyColor: ColorStorage.surfaceSecondary
                                    shadowColor: ColorStorage.menuShadowColor
                                }
                            }
                        }
                    }
                }
            }
            Loader {
                id: statusesDropdownLoader
                sourceComponent: statusesDropdownComponent
            }
        }
    }
}

