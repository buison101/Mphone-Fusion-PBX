import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import Flux 1.0

import "../uicontrols"
import "../utils"

FocusScope {
    id: root

    property alias hoverWide: body.width
    property alias hoverHeigth: body.height

    property bool alwaysOnTop: false

    property alias viewElementWidth: dropdown.viewElementWidth
    property alias viewElementHeight: dropdown.viewElementHeight

    property alias selection: selectionText.text
    property alias selectionAlignment: selectionText.horizontalAlignment
    property alias selectionImage: statusImage.source

    property alias emptyDidsText: emptyDids.text

    property alias selectionSize: selectionText.font.pixelSize

    property alias sipModel: view.model
    property alias delegate: view.delegate

    property bool alignRight: false

    property bool dropdownVisible: dropdown.visible

    readonly property int accountsCount: view.count
    readonly property int didsCount: didView.count

    property bool showAction: true
    property string actionText: qsTrId("combobox_action_add") + Translator.translate

    property bool showChevron: true

    property var doWorkOnListItemClick: function() {}
    property var doWorkOnActionItemClick: function() {}
    property var doWorkOnDidListItemClick: function() {}


    implicitWidth: hoverWide
    implicitHeight: hoverHeigth

    focus: true

    property var openDropdown: function() {
        if (!enabled) {
            return;
        }
        var point = mArea.mapToGlobal(0, 0);
        if (Screen.desktopAvailableWidth < point.x + dropdown.width) {
            window.x = point.x - dropdown.width - 6 * SettingsState.scale
        } else {
            window.x = point.x - 6 * SettingsState.scale
        }

        if (Screen.desktopAvailableHeight < point.y + dropdown.height) {
            window.y = point.y - dropdown.height - 6 * SettingsState.scale
        } else {
            window.y = point.y - 6 * SettingsState.scale
        }

        dropdown.ignoreHover = true;

        dropdown.open();
        view.currentIndex = view.currentItem == null ? 0 : view.currentItem.currentSipModel.selectedIdx;
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

        implicitWidth: hoverWide
        radius: 8 * SettingsState.scale
        implicitHeight: hoverHeigth

        property bool skipHover: false

        readonly property string colorDefault: ColorStorage.secondaryWindowBackground
        readonly property string colorOnHover: ColorStorage.windowBorder
        readonly property string colorOnPress: ColorStorage.windowBorder

        function onBodyPressed() {
            body.color = body.colorOnPress;

            var point = mArea.mapToGlobal(0, 0);

            if (Screen.desktopAvailableWidth < point.x + dropdown.width) {
                window.x = point.x - dropdown.width - 6 * SettingsState.scale
            } else {
                window.x = point.x - 6 * SettingsState.scale
            }

            if (Screen.desktopAvailableHeight < point.y + dropdown.height) {
                window.y = point.y - dropdown.height - 6 * SettingsState.scale
            } else {
                window.y = point.y - 6 * SettingsState.scale
            }
            dropdown.ignoreHover = true;
            dropdown.open();
            if (view.count != 0) {
                view.currentIndex = view.currentItem == null ? 0 : view.currentItem.currentSipModel.selectedIdx;
            }
            view.forceActiveFocus();
        }

        color: colorDefault

        MouseArea {
            id: mArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                body.color = body.colorOnHover;
            }

            onExited: {
                if (!root.activeFocus || !body.skipHover) {
                    body.color = body.colorDefault;
                }
            }

            onPressed: body.onBodyPressed()

            onReleased: {
                body.color = body.colorDefault;
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: 16 * SettingsState.scale

            Image {
                id: statusImage
                anchors.verticalCenter: parent.verticalCenter

                anchors.left: parent.left

                width: 12 * SettingsState.scale
                height: 12 * SettingsState.scale

                visible: selectionText.text != ""

                sourceSize.width: width
                sourceSize.height: height
            }

            Text {
                id: selectionText

                anchors.verticalCenter: statusImage.verticalCenter

                anchors.left: statusImage.right
                anchors.leftMargin: 6 * SettingsState.scale
                horizontalAlignment: Text.AlignLeft

                width: hoverWide - statusImage.width - chevronImage.width - 35 * SettingsState.scale

                font.family: "Segoe UI"
                font.bold: true
                font.pixelSize: 16 * SettingsState.scale

                elide: Text.ElideRight

                color: ColorStorage.iconsAndTextPrimary

                MouseArea {
                    hoverEnabled: true
                    anchors.fill: parent

                    ToolTip {
                        id: toolTip
                        visible: parent.containsMouse && content.text && selectionText.implicitWidth > selectionText.width && !dropdown.visible
                        delay: 1000
                        timeout: 5000
                        background: Rectangle {
                            id: background
                            color: ColorStorage.iconsAndTextPrimary
                        }
                        contentItem: Text {
                            id: content
                            text: selectionText.text ? selectionText.text : ""
                            color: ColorStorage.mainWindowBackground
                            wrapMode: Text.WordWrap
                        }
                    }

                    onEntered: {
                        if (!dropdown.visible) {
                            body.color = body.colorOnHover;
                        }
                    }

                    onExited: {
                        if (dropdown.visible) {
                            body.color = body.colorDefault;
                        }
                    }

                    onPressed: body.onBodyPressed()

                    onReleased: {
                        body.color = body.colorDefault;
                        toolTip.hide();
                    }
                }
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
                visible: showChevron
            }


        }

        ApplicationWindow {
            id: window

            flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint

            property int windowRescale: AppFeatures.osType == OSType.MacOS ? 0 : 12 * SettingsState.scale

            width: scope.width + windowRescale
            height: scope.height + windowRescale


            visible: dropdown.visible
            color: "transparent"
            property bool alwaysOnTop: root.alwaysOnTop

            onAlwaysOnTopChanged: {
                var flags = window.flags;
                flags = root.alwaysOnTop ? (flags | Qt.WindowStaysOnTopHint)
                                         : (flags & ~Qt.WindowStaysOnTopHint);
                window.flags = flags;
            }

            FocusScope {
                id: scope
                implicitWidth: dropdown.width
                implicitHeight: dropdown.height
                anchors.top: body.top
                anchors.right: root.alignRight ? body.right : undefined
                anchors.left: root.alignRight ? undefined : body.left

                focus: true

                Popup {
                    id: dropdown
                    property int viewElementWidth: 0 * SettingsState.scale
                    property int viewElementHeight: 42 * SettingsState.scale
                    property int viewElementMaxWidth: 190 * SettingsState.scale
                    property bool needToResetCurrentIndex: false
                    property int dropdownDefaultWidth: viewElementWidth + 2 * SettingsState.scale
                    property int dropdownWithDidsWidth: 2 * viewElementWidth + 3 * SettingsState.scale

                    property int viewFooterHeight: root.showAction ? viewElementHeight + 20 * SettingsState.scale : 0

                    property bool ignoreHover: false

                    property var updateDropdownWidth: function() {
                        if (view.footerItem.activeFocus || AppState.noDidsAtAll) {
                            width = dropdownDefaultWidth;
                        } else {
                            width = dropdownWithDidsWidth;
                        }
                    }

                    onClosed: {
                        ignoreHover = false;
                    }

                    margins: AppFeatures.osType == OSType.MacOS ? 0 : 6 * SettingsState.scale
                    padding: 1

                    // add border in 1 px
                    width: AppState.noDidsAtAll ? dropdownDefaultWidth : dropdownWithDidsWidth
                    height: view.count ? (view.count > 8 ? viewElementHeight * 8 + viewFooterHeight : viewElementHeight * view.count + viewFooterHeight) : viewFooterHeight

                    property int sipAccountListHeight: view.count ? view.count > 8 ? viewElementHeight * 8 + viewFooterHeight : viewElementHeight * view.count + viewFooterHeight : viewFooterHeight

                    property int didListHeight: didView.count > 8 ? viewElementHeight * 8 + viewFooterHeight : viewElementHeight * didView.count

                    implicitHeight: view.count ? (sipAccountListHeight >= didListHeight ? sipAccountListHeight : didListHeight) : viewFooterHeight

                    function updateDropdownHeight() {
                        dropdown.implicitHeight = view.count ? (sipAccountListHeight >= didListHeight ? sipAccountListHeight : didListHeight) : viewFooterHeight
                        dropdown.height = dropdown.implicitHeight;
                    }

                    closePolicy: Popup.CloseOnPressOutside

                    onAboutToShow: {
                        needToResetCurrentIndex = true;
                    }

                    contentItem: Row {
                        id: row
                        padding: 0 * SettingsState.scale
                        layer.enabled: true
                        layer.textureSize: Qt.size(1920 * SettingsState.scale, 1080 * SettingsState.scale)
                        layer.effect: OpacityMask {
                            source: row
                            maskSource: Rectangle {
                                width: dropdown.width
                                height: dropdown.height
                                anchors.top: parent.top

                                radius: 8 * SettingsState.scale
                            }
                        }
                        ListView {
                            id: view

                            width: viewElementWidth
                            height: dropdown.height
                            anchors.margins: 0 * SettingsState.scale

                            interactive: true
                            focus: true
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            ScrollBar.vertical: ScrollBar {
                                id: scrollBar
                                active: view.activeFocus && view.count > 8
                            }

                            onCurrentIndexChanged: {
                                dropdown.updateDropdownHeight();
                            }

                            Keys.onUpPressed: {
                                if (view.currentIndex == 0) {
                                    if (view.footerItem) {
                                        view.footerItem.forceActiveFocus();
                                        return;
                                    }
                                    view.currentIndex = view.count-1;
                                    view.itemAtIndex(view.count-1).forceActiveFocus();
                                    return;
                                }

                                view.decrementCurrentIndex();
                            }

                            Keys.onDownPressed: {
                                if (view.currentIndex == view.count - 1) {
                                    if (view.footerItem) {
                                        view.footerItem.forceActiveFocus();
                                        return;
                                    }
                                    view.currentIndex = 0;
                                    view.itemAtIndex(0).forceActiveFocus();
                                    return;
                                }

                                view.incrementCurrentIndex();
                            }

                            Keys.onRightPressed: {
                                if (!emptyDidsRect.visible && !AppState.noDidsAtAll && didsCount > 0) {
                                    if (view.footerItem) {
                                        if (view.footerItem.activeFocus) {
                                            return;
                                        }
                                    }
                                    didView.forceActiveFocus();
                                }
                            }

                            Keys.onTabPressed: {
                                if (!emptyDidsRect.visible && !AppState.noDidsAtAll && didsCount > 0) {
                                    if (view.footerItem) {
                                        if (view.footerItem.activeFocus) {
                                            return;
                                        }
                                    }
                                    didView.forceActiveFocus();
                                }
                            }

                            Keys.onEscapePressed: {
                                view.currentIndex = view.currentItem == null ? -1 : view.currentItem.currentSipModel.selectedIdx;
                                dropdown.close();
                                window.close();
                                root.forceActiveFocus();
                            }

                            Keys.onReturnPressed: {
                                root.doWorkOnListItemClick(view.currentIndex);
                                dropdown.close();
                                window.close();
                                root.forceActiveFocus();
                            }

                            Keys.onEnterPressed: {
                                root.doWorkOnListItemClick(view.currentIndex);
                                dropdown.close();
                                window.close();
                                root.forceActiveFocus();
                            }

                            onActiveFocusChanged: {
                                if (view.count != 0) {
                                    didView.currentIndex = view.currentItem.currentSipModel.didDefaultIdx;
                                }
                                if (!activeFocus && !root.activeFocus && !body.activeFocus && !didView.activeFocus) {
                                    dropdown.close();
                                    window.close();
                                }
                                emptyDidsRect.visible = view.count != 0 && view.currentItem.currentSipModel.didSize === 0 && !AppState.noDidsAtAll
                            }

                            delegate: Rectangle {
                                id: delegateBody

                                property variant currentSipModel: model
                                radius: index == 0 ? 8 * SettingsState.scale : 0
                                implicitWidth: dropdown.viewElementWidth
                                implicitHeight: dropdown.viewElementHeight

                                readonly property string colorDefault: ColorStorage.surfaceSecondary
                                readonly property string colorOnHover: ColorStorage.mainWindowBackground

                                color: colorDefault

                                onActiveFocusChanged: {
                                    if (activeFocus) {
                                        dropdown.ignoreHover = true;
                                        dropdown.updateDropdownHeight();
                                    }
                                    color = activeFocus ? colorOnHover : colorDefault;
                                }

                                onFocusChanged: {
                                    if (activeFocus) {
                                        emptyDidsRect.visible = view.count != 0 && view.currentItem.currentSipModel.didSize === 0 && !AppState.noDidsAtAll
                                    }
                                }

                                Shortcut {
                                    enabled: true
                                    sequence: index + 1

                                    onActivated: {
                                        root.doWorkOnListItemClick(index);
                                        dropdown.close();
                                        window.close();
                                        root.forceActiveFocus();
                                    }
                                }

                                MouseArea {
                                    anchors.fill: delegateBody
                                    hoverEnabled: true

                                    onEntered: {
                                        if (dropdown.ignoreHover && mouseX > 5 && mouseX < delegateBody.width - 5 && (index == 0 && mouseY > 5)) {
                                            return;
                                        } else if (dropdown.ignoreHover && mouseX > 5 && mouseX < delegateBody.width - 5 && index != 0) {
                                            return;
                                        }
                                        view.currentIndex = index;
                                        delegateBody.forceActiveFocus();
                                    }

                                    onExited: {
                                        if (view.currentItem.currentSipModel.selected && dropdown.needToResetCurrentIndex) {
                                            view.currentIndex = view.currentItem.currentSipModel.selectedIdx;
                                        }
                                        if (!parent.activeFocus) {
                                            parent.color = parent.colorDefault;
                                        }
                                        dropdown.needToResetCurrentIndex = false;
                                        dropdown.ignoreHover= false;
                                    }

                                    onPressed: {
                                        parent.forceActiveFocus();
                                        view.currentIndex = index;
                                    }

                                    onReleased: {
                                        if (!containsMouse) {
                                            return;
                                        }

                                        root.doWorkOnListItemClick(view.currentIndex);
                                        dropdown.needToResetCurrentIndex = false;
                                        dropdown.close();
                                        window.close();
                                        body.skipHover = true;
                                        root.forceActiveFocus();
                                        view.currentIndex = view.currentItem.currentSipModel.selectedIdx;
                                    }
                                }

                                Rectangle {
                                    id: bottomCorners

                                    anchors.bottom: parent.bottom

                                    height: parent.height / 3
                                    width: parent.width
                                    color: parent.color
                                    enabled: false
                                    visible: index == 0
                                }

                                Rectangle {
                                    id: rightCorners
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    height: parent.height
                                    width: delegateBody.radius
                                    color: parent.color
                                    enabled: false
                                    visible: didView.visible || emptyDidsRect.visible
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"

                                    Image {
                                        id: image
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10 * SettingsState.scale
                                        anchors.verticalCenter: parent.verticalCenter

                                        width: 18 * SettingsState.scale
                                        height: 18 * SettingsState.scale

                                        sourceSize.width: width
                                        sourceSize.height: height
                                        source: {
                                            switch(regStatus) {
                                            case RegistrationStatus.Unregistered:
                                                return "qrc:/images/blank_circle_grey.svg";

                                            case RegistrationStatus.Registered:
                                                return "qrc:/images/blank_circle_green.svg";

                                            case RegistrationStatus.RegisterError:
                                                return "qrc:/images/blank_circle_red.svg";

                                            case RegistrationStatus.Connections:
                                                return "qrc:/images/blank_circle_yellow.svg";

                                            }

                                            return "";
                                        }
                                        visible: dropdown.visible
                                    }

                                    Text {
                                        id: description

                                        anchors.verticalCenter: image.verticalCenter
                                        anchors.left: image.right
                                        anchors.leftMargin: 10 * SettingsState.scale

                                        font.family: "Segoe UI"
                                        font.pixelSize: 13 * SettingsState.scale

                                        elide: Text.ElideRight

                                        text: name
                                        visible: dropdown.visible

                                        color: ColorStorage.iconsAndTextPrimary

                                        onVisibleChanged: {
                                            if(visible) {
                                                updateWidth();
                                            }
                                        }

                                        function updateWidth() {
                                            var margin = 90 * SettingsState.scale;

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

                                        MouseArea {
                                            hoverEnabled: true
                                            anchors.fill: parent

                                            ToolTip {
                                                id: dropdownAccToolTip
                                                visible: parent.containsMouse && contentAccTooltip.text && description.implicitWidth > description.width
                                                delay: 1000
                                                timeout: 5000
                                                background: Rectangle {
                                                    id: backgroundAccTooltip
                                                    color: ColorStorage.iconsAndTextPrimary
                                                }
                                                contentItem: Text {
                                                    id: contentAccTooltip
                                                    text: description.text ? description.text : ""
                                                    color: ColorStorage.mainWindowBackground
                                                    wrapMode: Text.WordWrap
                                                }
                                            }

                                            onEntered: {
                                                view.currentIndex = index;
                                                delegateBody.forceActiveFocus();
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
                                                dropdown.needToResetCurrentIndex = false;
                                                dropdown.close();
                                                window.close();
                                                body.skipHover = true;
                                                root.forceActiveFocus();
                                                view.currentIndex = view.currentItem.currentSipModel.selectedIdx;
                                                toolTip.hide();
                                            }
                                        }
                                    }

                                    Image {
                                        id: selectedImage
                                        anchors.left: description.right
                                        anchors.leftMargin: 10 * SettingsState.scale
                                        anchors.verticalCenter: description.verticalCenter

                                        width: 24 * SettingsState.scale
                                        height: 24 * SettingsState.scale
                                        visible: false
                                        source: "qrc:/images/check.svg"   
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
                                            radius: 8 * SettingsState.scale
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
                                                    window.close();
                                                    root.forceActiveFocus();
                                                }
                                            }

                                            onActiveFocusChanged: {
                                                if (activeFocus) {
                                                    footerInnerRect.color = colorOnHover;
                                                    emptyDidsRect.visible = false;
                                                    dropdown.implicitHeight = dropdown.sipAccountListHeight;
                                                    dropdown.height = dropdown.implicitHeight;
                                                } else {
                                                    footerInnerRect.color = colorDefault;
                                                }

                                                dropdown.updateDropdownWidth();
                                            }

                                            Keys.onUpPressed: {
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
                                                window.close();
                                                root.forceActiveFocus();
                                            }

                                            MouseArea {
                                                anchors.fill: footerInnerRect
                                                hoverEnabled: true
                                                property bool ignoreHover: dropdown.ignoreHover && mouseX > 5 && mouseX < parent.width - 5 && mouseY < parent.height - 5

                                                onEntered: {
                                                    if (ignoreHover) {
                                                        return;
                                                    }
                                                    parent.color = parent.colorOnHover;
                                                    footerInnerRect.forceActiveFocus();
                                                }

                                                onExited: {
                                                    if (!parent.activeFocus || view.count == 0) {
                                                        parent.color = parent.colorDefault;
                                                    }
                                                    if (view.count != 0) {
                                                        view.currentItem.forceActiveFocus();
                                                    }

                                                    dropdown.ignoreHover = false;
                                                }

                                                onPressed: {
                                                    parent.forceActiveFocus();
                                                }

                                                onReleased: {
                                                    if (!containsMouse) {
                                                        return;
                                                    }

                                                    root.doWorkOnActionItemClick();
                                                    dropdown.close();
                                                    window.close();
                                                    body.skipHover = true;
                                                    root.forceActiveFocus();
                                                }
                                            }

                                            Rectangle {
                                                id: topCorners

                                                anchors.top: parent.top

                                                height: parent.height / 3
                                                width: parent.width
                                                color: parent.color
                                                enabled: false
                                                visible: view.count > 0
                                            }

                                            Image {
                                                id: image

                                                width: 20 * SettingsState.scale
                                                height: 20 * SettingsState.scale

                                                sourceSize.width: width
                                                sourceSize.height: height

                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: 15 * SettingsState.scale
                                                visible: false

                                                source: "qrc:/images/plus.svg"   
                                            }

                                            IconShader {
                                                anchors.centerIn: image
                                                imageSrcComponent: image
                                                imgColor: ColorStorage.iconsAndTextSecondary //white: "#000000" // black: #FFFFFF
                                                imageWidth: image.width
                                                imageHeight: image.height
                                            }

                                            Text {
                                                anchors.verticalCenter: image.verticalCenter
                                                anchors.left: image.right
                                                anchors.leftMargin: 10 * SettingsState.scale

                                                font.family: "Segoe UI"
                                                font.pixelSize: 13 * SettingsState.scale

                                                color: ColorStorage.iconsAndTextSecondary

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

                        Rectangle {
                            id: separator
                            visible: view.count != 0 && (didView.visible || emptyDidsRect.visible)
                            width: SettingsState.scale
                            color: ColorStorage.menuBorderColor
                            height: view.height
                        }

                        Rectangle {
                            id: emptyDidsRect
                            width: view.width
                            color: ColorStorage.surfaceSecondary
                            height: view.height
                            radius: 8 * SettingsState.scale
                            anchors.margins: 1 * SettingsState.scale
                            visible: view.count != 0 && view.currentItem.currentSipModel.didSize === 0 && !AppState.noDidsAtAll
                            Text {
                                id: emptyDids
                                anchors.centerIn: parent
                                font.family: "Segoe UI"
                                width: parent.width - 20 * SettingsState.scale
                                horizontalAlignment: Text.AlignHCenter
                                color: ColorStorage.iconsAndTextSecondary
                                wrapMode: Text.WordWrap

                                font.pixelSize: 13 * SettingsState.scale
                            }

                            Rectangle {
                                id: leftCornerEmptyRect
                                height: view.height
                                width: emptyDidsRect.radius
                                color: emptyDidsRect.color
                            }
                        }

                        ListView {
                            id: didView

                            width: view.width
                            height: view.height
                            anchors.margins: 1 * SettingsState.scale

                            model: view.currentItem.currentSipModel.didModel



                            onModelChanged: {
                                dropdown.updateDropdownHeight();
                            }

                            interactive: true
                            focus: true

                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            visible: {
                                if (view.currentItem.currentSipModel.didSize > 0) {
                                    if (!view.footerItem) {
                                        return true;
                                    }
                                    if (!view.footerItem.activeFocus) {
                                        return true;
                                    }
                                }
                                return false;
                            }

                            ScrollBar.vertical: ScrollBar {
                                id: didScrollBar
                                active: didView.activeFocus && didView.count > 8
                            }

                            Keys.onUpPressed: {
                                if (didView.currentIndex == 0) {
                                    didView.currentIndex = didView.count - 1;
                                    return;
                                }

                                didView.decrementCurrentIndex();
                            }

                            Keys.onDownPressed: {
                                if (didView.currentIndex == didView.count - 1) {
                                    didView.currentIndex = 0;
                                    return;
                                }

                                didView.incrementCurrentIndex();
                            }

                            Keys.onLeftPressed: {
                                didView.currentIndex = view.currentItem.currentSipModel.didDefaultIdx;
                                view.forceActiveFocus();
                            }

                            Keys.onTabPressed: {
                                dropdown.close();
                                window.close();
                                root.forceActiveFocus();
                            }

                            Keys.onEscapePressed: {
                                dropdown.close();
                                window.close();
                                root.forceActiveFocus();
                            }

                            Keys.onReturnPressed: {
                                root.doWorkOnDidListItemClick(didView.currentIndex, view.currentIndex);
                                dropdown.close();
                                window.close();
                                root.forceActiveFocus();
                            }

                            Keys.onEnterPressed: {
                                root.doWorkOnDidListItemClick(didView.currentIndex, view.currentIndex);
                                dropdown.close();
                                window.close();
                                root.forceActiveFocus();
                            }

                            onActiveFocusChanged: {
                                if (!activeFocus && !root.activeFocus && !body.activeFocus && !view.activeFocus) {
                                    dropdown.close();
                                    window.close();
                                }
                            }
                            delegate: Rectangle {
                                id: didDelegateBody

                                implicitWidth: dropdown.viewElementWidth
                                implicitHeight: dropdown.viewElementHeight
                                radius: index == 0 || index == didView.count - 1 ? 8 * SettingsState.scale : 0

                                readonly property string colorDefault: ColorStorage.surfaceSecondary
                                readonly property string colorOnHover: ColorStorage.mainWindowBackground

                                color: colorDefault

                                onActiveFocusChanged: {
                                    color = activeFocus ? colorOnHover : colorDefault;
                                }

                                MouseArea {
                                    anchors.fill: didDelegateBody
                                    hoverEnabled: true

                                    onEntered: {
                                        if (dropdown.ignoreHover && mouseX > 5 && mouseX < didDelegateBody.width - 5) {
                                            if (index == 0 && mouseY > 5) {
                                                return;
                                            } else if (index == didView.count - 1 && mouseY < parent.height - 5) {
                                                return;
                                            } else if (index != 0 && index != didView.count - 1) {
                                                return;
                                            }
                                        }
                                        didDelegateBody.forceActiveFocus();
                                        didView.currentIndex = index;
                                    }

                                    onExited: {
                                        if (!parent.activeFocus) {
                                            parent.color = parent.colorDefault;
                                        }
                                        dropdown.ignoreHover = false;
                                    }

                                    onPressed: {
                                        parent.forceActiveFocus();
                                        didView.currentIndex = index;
                                    }

                                    onReleased: {
                                        if (!containsMouse) {
                                            return;
                                        }

                                        root.doWorkOnDidListItemClick(didView.currentIndex, view.currentIndex);
                                        dropdown.close();
                                        window.close();
                                        body.skipHover = true;
                                        root.forceActiveFocus();
                                    }
                                }

                                Rectangle {
                                    id: didBottomCorners
                                    anchors.bottom: parent.bottom
                                    height: parent.height / 3
                                    width: parent.width
                                    color: parent.color
                                    enabled: false
                                    visible: index == 0
                                }

                                Rectangle {
                                    id: didTopCorners
                                    anchors.top: parent.top
                                    height: parent.height / 3
                                    width: parent.width
                                    color: parent.color
                                    enabled: false
                                    visible: index == didView.count - 1
                                }

                                Rectangle {
                                    id: didLeftCorners
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    height: parent.height
                                    width: didDelegateBody.radius
                                    color: parent.color
                                    enabled: false
                                    visible: index == 0 || index == didView.count - 1
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"

                                    Text {
                                        id: didDescription

                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left:  parent.left
                                        anchors.leftMargin: 10 * SettingsState.scale

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
                                            var margin = 72 * SettingsState.scale;

                                            if (didDescription.implicitWidth + margin > dropdown.viewElementMaxWidth) {
                                                dropdown.viewElementWidth = dropdown.viewElementMaxWidth;
                                                didDescription.width = dropdown.viewElementMaxWidth - margin;
                                                return;
                                            }


                                            var itemWidth = didDescription.implicitWidth + margin;
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
                                        MouseArea {
                                            hoverEnabled: true
                                            anchors.fill: parent
                                            ToolTip {
                                                id: dropdownDidToolTip
                                                visible: parent.containsMouse && contentDidTooltip.text && didDescription.implicitWidth > didDescription.width
                                                delay: 1000
                                                timeout: 5000
                                                clip: true
                                                background: Rectangle {
                                                    id: backgroundDidTooltip
                                                    color: ColorStorage.iconsAndTextPrimary
                                                }
                                                contentItem: Text {
                                                    id: contentDidTooltip
                                                    text: didDescription.text ? didDescription.text : ""
                                                    color: ColorStorage.mainWindowBackground
                                                    wrapMode: Text.WordWrap
                                                }

                                                property int margin: (didDelegateBody.width - backgroundDidTooltip.width) * 0.5
                                                property int minMargin: 20 * SettingsState.scale

                                                leftMargin: margin < minMargin ? minMargin : margin
                                                rightMargin: leftMargin
                                            }

                                            onEntered: {
                                                didDelegateBody.forceActiveFocus();
                                                didView.currentIndex = index;
                                            }

                                            onPressed: {
                                                didDelegateBody.forceActiveFocus();
                                                didView.currentIndex = index;
                                            }

                                            onReleased: {
                                                if (!containsMouse) {
                                                    return;
                                                }

                                                root.doWorkOnDidListItemClick(didView.currentIndex, view.currentIndex);
                                                dropdown.close();
                                                window.close();
                                                body.skipHover = true;
                                                root.forceActiveFocus();
                                            }
                                        }
                                    }

                                    Image {
                                        id: check
                                        anchors.left: didDescription.right
                                        anchors.leftMargin: 10 * SettingsState.scale
                                        anchors.verticalCenter: didDescription.verticalCenter

                                        width: 24 * SettingsState.scale
                                        height: 24 * SettingsState.scale

                                        source: "qrc:/images/check.svg"

                                        visible: false
                                    }

                                    IconShader {
                                        anchors.centerIn: check
                                        visible: selected
                                        imageSrcComponent: check
                                        imgColor: ColorStorage.iconsAndTextSecondary
                                        imageWidth: check.width
                                        imageHeight: check.height
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
                            bodyColor: ColorStorage.surfaceSecondary
                            shadowColor: ColorStorage.menuShadowColor
                        }
                    }
                }
            }

        }
    }
}
