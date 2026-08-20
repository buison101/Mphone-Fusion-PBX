import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0
import "../utils"

FocusScope {
    id: root

    property int changedWide: 0

    property alias hoverWide: body.width
    property alias hoverHeigth: body.height

    property alias viewElementWidth: dropdown.viewElementWidth
    property alias viewElementHeight: dropdown.viewElementHeight

    property alias title: title.text
    property alias selection: selection.text
    property alias selectionAlignment: selection.horizontalAlignment

    property alias titleSize: title.font.pixelSize
    property alias selectionSize: selection.font.pixelSize

    property string delegateColorDefault: ColorStorage.surfaceSecondary
    property string delegateColorOnHover: ColorStorage.mainWindowBackground

    property alias model: view.model
    property alias delegate: view.delegate

    property bool underline: true

    property bool alignRight: false

    property bool dropdownVisible: dropdown.visible

    property string chevronImageColorDefault: ColorStorage.additionalText

    property bool showAction: true
    property string actionText: qsTrId("combobox_action_add") + Translator.translate

    property var doWorkOnListItemClick: function() {}
    property var doWorkOnActionItemClick: function() {}

    implicitWidth: hoverWide
    implicitHeight: hoverHeigth

    focus: true

    property var openDropdown: function() {
        dropdown.ignoreHover = true;
        dropdown.open();
        view.currentIndex = view.currentItem.currentModel.selectedIdx;
        view.forceActiveFocus();
    }

    property var closeDropdown: function() {
        dropdown.close();
    }

    onActiveFocusChanged: {
        body.color = activeFocus && !body.skipHover ? body.colorOnHover : body.colorDefault;
        if (!activeFocus) {
            body.skipHover = false;
        }
    }

    Keys.onSpacePressed: {
        openDropdown();
    }

    Keys.onReturnPressed: {
        openDropdown();
    }

    Keys.onEnterPressed: {
        openDropdown();
    }

    Rectangle {
        id: body

        radius: 8 * SettingsState.scale

        property bool skipHover: false

        implicitWidth: {
            if (changedWide != 0) {
                return changedWide;
            }

            if (title.width  > 102 * SettingsState.scale ) {
                return (title.width + 15);
            }
            else {
                return 110 * SettingsState.scale;
            }
        }

        implicitHeight: title.height + selection.height + 14 * SettingsState.scale

        readonly property string colorDefault: ColorStorage.mainWindowBackground
        readonly property string colorOnHover: ColorStorage.mSizeButtonOnHover
        readonly property string colorOnPress: ColorStorage.mainWindowBackground

        color: root.enabled ? colorDefault : ColorStorage.buttonSecondaryOnHover

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                body.skipHover = true;
                body.color = body.colorOnHover;
            }

            onExited: {
                if (!root.activeFocus || body.skipHover) {
                    body.color = body.colorDefault;
                }
            }

            onPressed: {
                body.color = body.colorOnPress;
                dropdown.ignoreHover = true;
                dropdown.open();
                view.forceActiveFocus();
            }

            onReleased: {
                body.color = body.colorDefault;
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 6 * SettingsState.scale

            Text {
                id: title

                font.family: "Segoe UI"
                font.pixelSize: 12 * SettingsState.scale

                color: root.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.disabledButtonsGrey
            }

            Item {
                width: parent.width
                height: selection.height
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: selection

                    anchors.left: parent.left
                    anchors.leftMargin: 5 * SettingsState.scale
                    anchors.right: chevronImage.left
                    anchors.rightMargin: 5 * SettingsState.scale

                    elide: Text.ElideRight

                    font.family: "Segoe UI"
                    font.pixelSize: 16 * SettingsState.scale

                    color: !(!root.activeFocus || body.skipHover) || mouseArea.containsMouse ? ColorStorage.iconsAndTextPrimary : (!root.enabled ? ColorStorage.textAndDisabledIconsGrey :
                                                                                                             ColorStorage.iconsAndTextSecondary)
                }

                Image {
                    id: chevronImage

                    anchors.right: parent.right
                    anchors.verticalCenter: selection.verticalCenter
                    visible: false

                    width: 18 * SettingsState.scale
                    height: 18 * SettingsState.scale

                    source: "qrc:/images/chevron_down.svg"
                }

                IconShader {
                    anchors.centerIn: chevronImage
                    imageSrcComponent: chevronImage
                    imgColor: root.chevronImageColorDefault
                    imageWidth: chevronImage.width
                    imageHeight: chevronImage.height
                }
            }
        }

        FocusScope {
            implicitWidth: dropdown.width
            implicitHeight: dropdown.height

            anchors.top: body.top
            anchors.right: root.alignRight ? body.right : undefined
            anchors.left: root.alignRight ? undefined : body.left

            focus: true

            Popup {
                id: dropdown

                property int viewElementWidth: 0 * SettingsState.scale
                property int viewElementHeight: 40 * SettingsState.scale
                property int viewElementMaxWidth: 220 * SettingsState.scale

                property int viewFooterHeight: root.showAction ? viewElementHeight + 20 * SettingsState.scale : 0

                property bool ignoreHover: false

                // add border in 1 px
                implicitWidth: viewElementWidth + 2 * SettingsState.scale
                implicitHeight: view.count ? viewElementHeight * view.count + viewFooterHeight + 2 * SettingsState.scale : viewFooterHeight + 2 * SettingsState.scale

                closePolicy: Popup.CloseOnPressOutside

                onVisibleChanged: {
                    if (!visible) {
                        // to recalculate listview element's width
                        viewElementWidth = 0;
                    }
                }

                onClosed: {
                    ignoreHover = false;
                }

                onActiveFocusChanged: {
                    if (!activeFocus) {
                        dropdown.close();
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
                            view.footerItem.forceActiveFocus();
                            return;
                        }

                        view.decrementCurrentIndex();
                    }

                    Keys.onDownPressed: {
                        if (view.currentIndex == view.count - 1) {
                            view.footerItem.forceActiveFocus();
                            return;
                        }

                        view.incrementCurrentIndex();
                    }

                    Keys.onTabPressed: {
                        dropdown.close();
                        root.forceActiveFocus();
                    }

                    Keys.onEscapePressed: {
                        dropdown.close();
                        //root.forceActiveFocus();
                    }

                    Keys.onReturnPressed: {
                        root.doWorkOnListItemClick(view.currentIndex);
                        dropdown.close();
                        //root.forceActiveFocus();
                    }

                    Keys.onEnterPressed: {
                        root.doWorkOnListItemClick(view.currentIndex);
                        dropdown.close();
                        //root.forceActiveFocus();
                    }

                    delegate: Rectangle {
                        id: delegateBody

                        implicitWidth: dropdown.viewElementWidth
                        implicitHeight: dropdown.viewElementHeight

                        radius: (index == 0 || index == view.count - 1) ? 8 * SettingsState.scale : 0

                        readonly property string colorDefault: root.delegateColorDefault
                        readonly property string colorOnHover: root.delegateColorOnHover

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
                            anchors.fill: delegateBody

                            hoverEnabled: true

                            onEntered: {
                                if (dropdown.ignoreHover && mouseX > 10 && mouseX < delegateBody.implicitWidth - 10) {
                                    if (index == 0 && mouseY > 5) {
                                        return;
                                    } else if (index == view.count - 1 && mouseY < parent.height - 5) {
                                        return;
                                    } else if (index != 0 && index != view.count - 1) {
                                        return;
                                    }
                                }
                                view.currentIndex = index;
                                delegateBody.forceActiveFocus();
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

                                body.skipHover = true;
                                root.doWorkOnListItemClick(view.currentIndex);
                                dropdown.close();

                                root.forceActiveFocus();
                            }
                        }

                        Rectangle {
                            id: bottomCornersListView

                            anchors.bottom: parent.bottom

                            height: parent.height / 3
                            width: parent.width

                            enabled: false

                            visible: view.count > 1 && index == 0

                            color: parent.color
                        }

                        Rectangle {
                            id: topCornersListView

                            anchors.top: parent.top

                            height: parent.height / 3
                            width: parent.width

                            enabled: false

                            visible: view.count > 1 && index == view.count - 1

                            color: parent.color
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"

                            Text {
                                id: description

                                anchors.left: checkImage.right
                                anchors.leftMargin: 10 * SettingsState.scale
                                anchors.verticalCenter: checkImage.verticalCenter

                                font.family: "Segoe UI"
                                font.pixelSize: 13 * SettingsState.scale

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
                                    var margin = 60 * SettingsState.scale;

                                    if (description.implicitWidth + margin > dropdown.viewElementMaxWidth) {
                                        dropdown.viewElementWidth = dropdown.viewElementMaxWidth;
                                        description.width = dropdown.viewElementMaxWidth - margin;
                                        return;
                                    }

                                    var itemWidth = description.implicitWidth + margin;
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
                                anchors.left:  parent.left
                                anchors.leftMargin: 15 * SettingsState.scale

                                width: 24 * SettingsState.scale
                                height: 24 * SettingsState.scale

                                source: selected ? "qrc:/images/check.svg" : ""

                                visible: false
                            }

                            IconShader {
                                anchors.centerIn: checkImage
                                visible: selected
                                imageSrcComponent: checkImage
                                imgColor: ColorStorage.iconsAndTextSecondary
                                imageWidth: checkImage.width
                                imageHeight: checkImage.height
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

                                    readonly property string colorDefault: ColorStorage.surfaceSecondary
                                    readonly property string colorOnHover: ColorStorage.mainWindowBackground

                                    color: colorDefault

                                    focus: true

                                    Shortcut {
                                        enabled: true
                                        sequence: view.count

                                        onActivated: {
                                            root.doWorkOnActionItemClick();
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
                                        dropdown.close();
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

                                            body.skipHover = true;
                                            root.doWorkOnActionItemClick();
                                            dropdown.close();

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

                                            if (implicitWidth + margin > dropdown.viewElementMaxWidth) {
                                                dropdown.viewElementWidth = dropdown.viewElementMaxWidth;
                                                width = dropdown.viewElementMaxWidth - margin;
                                                return;
                                            }

                                            var itemWidth = implicitWidth + margin;
                                            if (dropdown.viewElementWidth < itemWidth) {
                                                dropdown.viewElementWidth = itemWidth;
                                                return;
                                            }
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

                    footer: root.showAction ? actionDelegate : null
                }

                background: Rectangle {
                    radius: 8 * SettingsState.scale
                    color: ColorStorage.mainWindowBackground

                    MenuShadow {
                        scale: SettingsState.scale
                        anchors.fill: parent
                        bodyColor: ColorStorage.surfaceSecondary
                        shadowColor: ColorStorage.menuShadowColor
                    }
                }
            }
        }
    }
}
