import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0
import QtGraphicalEffects 1.15
import "../utils"

FocusScope {
    id: root

    property alias hoverWide: body.width
    property alias hoverHeigth: body.height

    property alias title: title.text
    property alias titleSize: title.font.pixelSize

    property alias selection: selection.text
    property alias selectionAlignment: selection.horizontalAlignment
    property alias selectionSize: selection.font.pixelSize
    property alias listViewCount: view.count

    property variant viewModel

    property var modelType

    property int popupX: 0
    property int popupY: 0

    property bool alignRight: false

    property bool focusedWhenOpenDropdown: false

    property bool itemSelectedByMouse: false

    property var doWorkOnListItemClick: function() {}
    property var doWorkOnActionItemClick: function() {}

    implicitWidth: hoverWide
    implicitHeight: hoverHeigth

    focus: true

    property var openDropdown: function() {
        dropdown.open();
        view.currentIndex = 0;
        view.forceActiveFocus();
    }

    property var closeDropdown: function() {
        dropdown.close();
        window.close();
    }

    Keys.onSpacePressed: {
        openDropdown();
    }

    onVisibleChanged: {
        if (!root.visible) {
            closeDropdown();
        }
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            root.focusedWhenOpenDropdown = true;
        }
        if (itemSelectedByMouse) {
            itemSelectedByMouse = false;
            return;
        } else {
            body.color = activeFocus ? body.colorOnHover : body.colorDefault;
            title.color = activeFocus ? ColorStorage.iconsAndTextPrimary : enabled ? ColorStorage.iconsAndTextSecondary : ColorStorage.textAndDisabledIconsGrey;
            selection.color = activeFocus ? ColorStorage.iconsAndTextPrimary : enabled ? ColorStorage.iconsAndTextSecondary : ColorStorage.textAndDisabledIconsGrey;
        }
    }

    Rectangle {
        id: body

        implicitWidth: {
            if (title.width  > 102 * SettingsState.scale ) {
                return (title.width + 15);
            }
            else {
                return 110 * SettingsState.scale;
            }
        }

        implicitHeight: selection.height + 18 * SettingsState.scale

        readonly property string colorDefault: ColorStorage.mainWindowBackground
        readonly property string colorOnHover: ColorStorage.mSizeButtonOnHover
        readonly property string colorOnPress: ColorStorage.mainWindowBackground

        radius: 8 * SettingsState.scale

        color: colorDefault

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                body.color = body.colorOnHover;
                title.color = ColorStorage.iconsAndTextPrimary;
                selection.color = ColorStorage.iconsAndTextPrimary;
            }

            onExited: {
                body.color = body.colorDefault;
                title.color = ColorStorage.iconsAndTextSecondary;
                selection.color = ColorStorage.iconsAndTextSecondary;
            }

            onPressed: {
                dropdown.open();
                view.forceActiveFocus();
            }

            onReleased: {
                body.color = body.colorDefault;
            }
        }

        Column {
            id: selectionColumn
            anchors.fill: parent
            anchors.margins: 6 * SettingsState.scale

            Text {
                id: title
                anchors.left: parent.left
                anchors.leftMargin: 5 * SettingsState.scale
                anchors.verticalCenter: parent.verticalCenter

                font.family: "Segoe UI"
                font.pixelSize: 14 * SettingsState.scale

                color: root.activeFocus || mouseArea.containsMouse ? ColorStorage.iconsAndTextPrimary : (!root.enabled ? ColorStorage.textAndDisabledIconsGrey :
                                                                                                                         ColorStorage.iconsAndTextSecondary)
                visible: AppState.callTagsSelectedName == ""
            }

            Item {
                width: body.width - selection. anchors.rightMargin - 12 * SettingsState.scale
                height: selection.height
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: selection

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: chevronImage.left
                    anchors.rightMargin: 5 * SettingsState.scale

                    elide: Text.ElideRight

                    font.family: "Segoe UI"
                    font.pixelSize: 16 * SettingsState.scale

                    color: root.activeFocus || mouseArea.containsMouse ? ColorStorage.iconsAndTextPrimary : (!root.enabled ? ColorStorage.textAndDisabledIconsGrey :
                                                                                                                             ColorStorage.iconsAndTextSecondary)
                }

                Image {
                    id: chevronImage

                    property string chevronImageColorDefault: ColorStorage.additionalText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: false

                    width: 18 * SettingsState.scale
                    height: 18 * SettingsState.scale

                    source: "qrc:/images/chevron_down.svg" 
                }

                IconShader {
                    anchors.centerIn: chevronImage
                    imageSrcComponent: chevronImage
                    imgColor: chevronImage.chevronImageColorDefault
                    imageWidth: chevronImage.width
                    imageHeight: chevronImage.height
                }
            }
        }
        ApplicationWindow {
            id: window

            property alias dropdown: dropdown
            property alias view: view

            flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint |
                   Qt.WindowStaysOnTopHint

            color: "transparent"


            x: root.popupX + (root.width - width) / 2
            y: root.popupY - 6 * SettingsState.scale

            width: scope.width + 12 * SettingsState.scale
            height: scope.height + 12 * SettingsState.scale

            visible: dropdown.visible

            FocusScope {
                id: scope

                implicitWidth: dropdown.implicitWidth
                implicitHeight: dropdown.implicitHeight

                focus: true

                Popup {
                    id: dropdown

                    property int viewElementWidth: 0 * SettingsState.scale
                    property int viewElementHeight: 40 * SettingsState.scale
                    property int viewElementMaxWidth: 220 * SettingsState.scale
                    property int viewFooterHeight: 0

                    property int viewMaxElementCount: 8 * SettingsState.scale

                    property bool alreadyClosed: false

                    // add border in 1 px
                    implicitWidth: view.count ? viewElementWidth + 2 * SettingsState.scale : 0
                    implicitHeight: {
                        var rowCount = viewMaxElementCount > view.count ?
                                    view.count : viewMaxElementCount;

                        return view.count ? viewElementHeight * rowCount + 2 * SettingsState.scale : 0;
                    }

                    closePolicy: Popup.CloseOnPressOutside

                    margins: 6 * SettingsState.scale

                    onVisibleChanged: {
                        if (!visible) {
                            // to recalculate listview element's width
                            viewElementWidth = 0;
                        }
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

                        layer.enabled: true
                        layer.textureSize: Qt.size(1920 * SettingsState.scale, 1080 * SettingsState.scale)
                        layer.effect: OpacityMask {
                            source: delegateBody
                            maskSource: Rectangle {
                                width: window.width
                                height: window.height - 2 * SettingsState.scale
                                anchors.top: window.top
                                radius: 8 * SettingsState.scale
                            }
                        }

                        anchors.fill: parent
                        anchors.margins: 1 * SettingsState.scale

                        interactive: true
                        keyNavigationWraps: true
                        focus: true

                        model: viewModel

                        ScrollBar.vertical: ScrollBar {
                            id: scrollBar
                            active: view.count > dropdown.viewMaxElementCount
                        }

                        Keys.onUpPressed: {
                            if (view.currentIndex == 0) {
                                return;
                            }

                            view.decrementCurrentIndex();
                        }

                        Keys.onDownPressed: {
                            if (view.currentIndex == view.count - 1) {
                                return;
                            }

                            view.incrementCurrentIndex();
                        }

                        Keys.onTabPressed: {
                            dropdown.alreadyClosed = true;
                            dropdown.close();
                            window.close();
                            root.forceAtciveFocus();
                        }

                        Keys.onEscapePressed: {
                            dropdown.alreadyClosed = true;
                            dropdown.close();
                            window.close();
                            root.forceActiveFocus();
                        }

                        Keys.onReturnPressed: {
                            root.doWorkOnListItemClick(view.currentIndex);
                            dropdown.alreadyClosed = true;
                            dropdown.close();
                            window.close();
                            root.forceActiveFocus();
                        }

                        Keys.onEnterPressed: {
                            root.doWorkOnListItemClick(view.currentIndex);
                            dropdown.alreadyClosed = true;
                            dropdown.close();
                            window.close();
                            root.forceActiveFocus();
                        }

                        delegate: Rectangle {
                            id: delegateBody

                            implicitWidth: dropdown.viewElementWidth
                            implicitHeight: dropdown.viewElementHeight

                            readonly property string colorDefault: ColorStorage.mainWindowBackground
                            readonly property string colorOnHover: ColorStorage.surfaceSecondary

                            color: colorDefault

                            Component.onCompleted: {
                                root.modelType = model.type;
                            }

                            onActiveFocusChanged: {
                                color = activeFocus ? colorOnHover : colorDefault;
                            }

                            Shortcut {
                                enabled: true
                                sequence: index + 1

                                onActivated: {
                                    root.doWorkOnListItemClick(index);
                                    dropdown.alreadyClosed = true;
                                    dropdown.close();
                                    root.forceActiveFocus();
                                }
                            }

                            MouseArea {
                                anchors.fill: delegateBody
                                hoverEnabled: true

                                onEntered: {
                                    view.currentIndex = index;
                                    delegateBody.forceActiveFocus();
                                }

                                onExited: {
                                    if (!parent.activeFocus) {
                                        parent.color = parent.colorDefault;
                                    }
                                }

                                onReleased: {
                                    if (!containsMouse) {
                                        return;
                                    }

                                    root.doWorkOnListItemClick(view.currentIndex);
                                    dropdown.alreadyClosed = true;
                                    dropdown.close();
                                    window.close();
                                    if (root.focusedWhenOpenDropdown) {
                                        root.itemSelectedByMouse = true;
                                        root.focusedWhenOpenDropdown = false;
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"

                                layer.enabled: false

                                Text {
                                    id: description

                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left:  parent.left
                                    anchors.leftMargin: 15 * SettingsState.scale

                                    font.family: "Segoe UI"
                                    font.pixelSize: 13 * SettingsState.scale

                                    elide: Text.ElideRight
                                    color: ColorStorage.iconsAndTextPrimary

                                    text: name
                                    visible: dropdown.visible

                                    onVisibleChanged: {
                                        // to recalculate listview element's width
                                        if(visible) {
                                            updateWidth();
                                        }
                                    }

                                    function updateWidth() {
                                        var margin = 60 * SettingsState.scale;
                                        dropdown.viewElementWidth = dropdown.viewElementMaxWidth;
                                        description.width = dropdown.viewElementMaxWidth - margin;
                                    }

                                    onTextChanged: {
                                        updateWidth();
                                    }

                                    Component.onCompleted: {
                                        updateWidth();
                                    }
                                }

                                Image {
                                    id: check
                                    anchors.left: description.right
                                    anchors.leftMargin: 10 * SettingsState.scale
                                    anchors.verticalCenter: description.verticalCenter

                                    width: 24 * SettingsState.scale
                                    height: 24 * SettingsState.scale

                                    visible: selected
                                    source: selected ? "qrc:/images/check.svg" : ""
                                }

                                IconShader {
                                    anchors.centerIn: check
                                    visible: selected
                                    imageSrcComponent: check
                                    imgColor: chevronImage.chevronImageColorDefault
                                    imageWidth: check.width
                                    imageHeight: check.height
                                }
                            }
                        }


                        Component {
                            id: actionDelegate

                            FocusScope {
                                focus: true

                                implicitWidth: footerOuterRect.width
                                implicitHeight: footerOuterRect.height

                                Rectangle {
                                    id: footerOuterRect

                                    implicitWidth: dropdown.viewElementWidth
                                    implicitHeight: dropdown.viewFooterHeight

                                    color: "transparent"

                                    Rectangle {
                                        id: footerInnerRect

                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom

                                        implicitWidth: dropdown.viewElementWidth
                                        implicitHeight: dropdown.viewElementHeight

                                        readonly property string colorDefault: ColorStorage.mainWindowBackground
                                        readonly property string colorOnHover: ColorStorage.surfaceSecondary

                                        color: colorDefault

                                        focus: true

                                        Shortcut {
                                            enabled: true
                                            sequence: view.count

                                            onActivated: {
                                                root.doWorkOnActionItemClick();
                                                dropdown.alreadyClosed = true;
                                                dropdown.close();
                                                root.forceActiveFocus();
                                            }
                                        }

                                        onActiveFocusChanged: {
                                            footerInnerRect.color = activeFocus ? colorOnHover : colorDefault;
                                        }

                                        Keys.onUpPressed: {
                                            // to move focus from footer
                                            // to the last item in listview
                                            view.currentIndex = view.count - 1;
                                            view.currentItem.forceActiveFocus();
                                        }

                                        Keys.onDownPressed: {
                                            view.currentIndex = 0;
                                            view.currentItem.forceActiveFocus();
                                        }

                                        Keys.onReturnPressed: {
                                            root.doWorkOnActionItemClick();
                                            dropdown.alreadyClosed = true;
                                            dropdown.close();
                                            window.close();
                                            root.forceActiveFocus();
                                        }

                                        MouseArea {
                                            anchors.fill: footerInnerRect
                                            hoverEnabled: true

                                            onEntered: {
                                                parent.color = parent.colorOnHover;
                                                footerInnerRect.forceActiveFocus();
                                            }

                                            onExited: {
                                                if (!parent.activeFocus) {
                                                    parent.color = parent.colorDefault;
                                                }
                                            }

                                            onReleased: {
                                                if (!containsMouse) {
                                                    return;
                                                }

                                                root.doWorkOnActionItemClick();
                                                dropdown.alreadyClosed = true;
                                                dropdown.close();
                                                window.close();

                                                root.forceActiveFocus();
                                            }
                                        }

                                        Image {
                                            id: image

                                            width: 20 * SettingsState.scale
                                            height: 20 * SettingsState.scale

                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: 15 * SettingsState.scale

                                            source: "qrc:/images/plus.svg"
                                        }

                                        Text {
                                            anchors.verticalCenter: image.verticalCenter
                                            anchors.left: image.right
                                            anchors.leftMargin: 10 * SettingsState.scale

                                            font.family: "Segoe UI"
                                            font.pixelSize: 13 * SettingsState.scale

                                            color: ColorStorage.secondaryWindowBackground

                                            text: root.actionText
                                            visible: dropdown.visible

                                            onVisibleChanged: {
                                                // to recalculate listview element's width
                                                if(visible) {
                                                    updateWidth();
                                                }
                                            }

                                            function updateWidth() {
                                                var margin = 100 * SettingsState.scale;
                                                dropdown.viewElementWidth = dropdown.viewElementMaxWidth;
                                                width = dropdown.viewElementMaxWidth - margin;
                                            }

                                            Component.onCompleted: {
                                                updateWidth();
                                            }

                                            onTextChanged: {
                                                updateWidth();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        footer: null
                    }

                    background: Rectangle {
                        color: ColorStorage.mainWindowBackground
                        radius: 8 * SettingsState.scale
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
}
