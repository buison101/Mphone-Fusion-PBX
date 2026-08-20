import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import Flux 1.0

import "../uicontrols" as SoftphonePro
import "../utils"

FocusScope {
    id: root

    focus: true

    MouseArea {
        anchors.fill: parent

        onPressed: {
            focusReceiver.focus = true;
            root.forceActiveFocus();
            listview.currentIndex = 0;
            mouse.accepted = false
        }
    }

    Shortcut {
        enabled: true
        sequence: "Ctrl+F"

        onActivated: {
            searchInput.focus = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ColorStorage.secondaryWindowBackground

        focus: parent.focus

        Item {
            id: focusReceiver
            focus: true

            KeyNavigation.tab: searchInput
            KeyNavigation.backtab: listview
        }

        Rectangle {
            id: titleLayer

            anchors.top: parent.top
            anchors.left: parent.left

            color: ColorStorage.secondaryWindowTitleBackgroundColor
            width: parent.width
            height: 39 * SettingsState.scale

            FocusSender {
                anchors.fill: parent
                receiver: focusReceiver
            }

            Text {
                id: title

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16 * SettingsState.scale

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"
                font.bold: true

                color: ColorStorage.secondaryWindowTitleAndIcons

                text: qsTrId("contacts_window_title") + Translator.translate
            }
        }

        SoftphonePro.SearchInput {
            id: searchInput

            anchors.top: titleLayer.bottom
            anchors.topMargin: 8 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: addButton.left
            anchors.rightMargin: 8 * SettingsState.scale

            height: 40 * SettingsState.scale

            focus: parent.focus

            KeyNavigation.tab: addButton
            Shortcut {
                enabled: searchInput.activeFocus
                sequence: "Shift+Tab"

                onActivated: {
                    listview.forceActiveFocus();
                }
            }

            property string text: edit.text

            onTextChanged: {
                ActionProvider.filterContacts(edit.text);
            }
        }

        SoftphonePro.SquareButton {
            id: addButton

            anchors.bottom: searchInput.bottom
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            width: 40 * SettingsState.scale
            height: 40 * SettingsState.scale

            radius: 8 * SettingsState.scale

            colorDefault: ColorStorage.mainWindowBackground
            colorOnHover: ColorStorage.mSizeButtonOnHover
            colorOnPress: ColorStorage.mSizeButtonOnPress

            imageColorDefault: ColorStorage.mSizeButtonImageDefault
            imageColorOnHover: ColorStorage.mSizeButtonImageOnHover
            imageColorOnPress: ColorStorage.mSizeButtonImageOnHover

            imageDefault: "qrc:/images/account_add.svg"
            imageWidth: width / 2
            imageHeight: imageWidth / 1.3

            enabled: true
            visible: enabled

            doWorkOnButtonClick: function() {
                ActionProvider.tryAddNewContact();
            }

            onActiveFocusChanged: {
                state = activeFocus ? "hovered" : "default";
            }

            KeyNavigation.tab: listview
            KeyNavigation.backtab: searchInput
        }

        Rectangle {
            anchors.top: searchInput.bottom
            anchors.topMargin: 11 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16 * SettingsState.scale

            clip: true

            Component {
                id: sectionDelegate

                Rectangle {
                    width: parent.width
                    height: 30 * SettingsState.scale

                    color: "transparent"

                    FocusSender {
                        anchors.fill: parent
                        receiver: focusReceiver
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left

                        font.pixelSize: 13 * SettingsState.scale
                        font.family: "Segoe UI"
                        color: ColorStorage.additionalText

                        text: section
                    }
                }
            }

            Component {
                id: contextMenuComponent

                Menu {
                    id: contextMenu

                    property string defaultElementColor: ColorStorage.surfaceSecondary
                    property string onHoverElementColor: ColorStorage.secondaryWindowBackground

                    background: Rectangle {
                        implicitWidth: 200 * SettingsState.scale
                        implicitHeight: 40 * SettingsState.scale
                        color: "transparent"
                        radius: 8 * SettingsState.scale

                        MenuShadow {
                            scale: SettingsState.scale
                            anchors.fill: parent
                            bodyColor: ColorStorage.surfaceSecondary
                            shadowColor: ColorStorage.menuShadowColor
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true
                        topMargin: 1

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        roundTopCorners: true

                        actionLabel: qsTrId("clipboard_edit") + Translator.translate

                        onTriggered: {
                            ActionProvider.editContact(listview.selectedContactId);
                        }
                    }

                    SoftphonePro.MainMenuSeparator {
                        color: ColorStorage.menuBorderColor
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: listview.selectedContactType == ContactType.Local
                        bottomMargin: 1

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_delete") + Translator.translate

                        onTriggered: {
                            ActionProvider.tryDeleteContact(listview.selectedContactId);
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true
                        bottomMargin: 1

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        roundBottomCorners: true

                        actionLabel: qsTrId("clipboard_delete_all") + Translator.translate

                        onTriggered: {
                            ActionProvider.tryDeleteAllDataContacts();
                        }
                    }

                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            contextMenu.close();
                        }
                    }

                    Component.onCompleted: {
                        contextMenu.open();
                    }
                }
            }

            Component {
                id: phonesDropdownComponent

                ApplicationWindow {
                    id: window

                    property alias model: view.model
                    property alias dropdown: dropdown
                    property bool alwaysOnTop: SettingsState.alwaysOnTop

                    flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint

                    onAlwaysOnTopChanged: {
                        var flags = window.flags;
                        flags = alwaysOnTop ? (flags | Qt.WindowStaysOnTopHint)
                                            : (flags & ~Qt.WindowStaysOnTopHint);
                        window.flags = flags;
                    }

                    visible: dropdown.visible

                    color: "transparent"

                    property int xOnOpen: 0
                    property int yOnOpen: 0

                    width: dropdown.width + 12 * SettingsState.scale
                    height: dropdown.height + 12 * SettingsState.scale

                    function open() {
                        dropdown.open();
                        window.requestActivate();

                        xOnOpen = x;
                        yOnOpen = y;

                        view.currentIndex = 0;

                        if (Screen.desktopAvailableWidth < xOnOpen + window.width) {
                            window.x = xOnOpen - window.width - 6 * SettingsState.scale;
                        }

                        if (Screen.desktopAvailableHeight < yOnOpen + window.height) {
                            window.y = yOnOpen - window.height - 6 * SettingsState.scale;
                        }
                    }

                    onWidthChanged: {
                        if (Screen.desktopAvailableWidth < xOnOpen + window.width) {
                            window.x = xOnOpen - window.width - 6 * SettingsState.scale;
                        }
                    }

                    onHeightChanged: {
                        if (Screen.desktopAvailableHeight < yOnOpen + window.height) {
                            window.y = yOnOpen - window.height - 6 * SettingsState.scale;
                        }
                    }

                    Popup {
                        id: dropdown

                        property int viewElementMaxWidth: 300 * SettingsState.scale
                        property int viewElementWidth: 0 * SettingsState.scale
                        property int viewElementHeight: 40 * SettingsState.scale

                        // add border in 1 px
                        width: view.count ? viewElementWidth + 2 * SettingsState.scale : 0
                        height: view.count ? viewElementHeight * view.count + 2 * SettingsState.scale : 0

                        margins: 6 * SettingsState.scale

                        focus: true

                        closePolicy: Popup.CloseOnPressOutside

                        onViewElementWidthChanged: {
                            width = view.count ? viewElementWidth + 2 * SettingsState.scale : 0;
                        }

                        contentItem: Rectangle {
                            anchors.fill: parent
                            color: "transparent"

                            ListView {
                                id: view

                                anchors.fill: parent
                                anchors.margins: 1 * SettingsState.scale

                                model: AppState.contactPhonesModel

                                interactive: false
                                focus: true

                                function doWorkOnListItemClick(number, isCallPickup) {
                                    ActionProvider.sendDialedString(number);
                                    ActionProvider.makeCall(number, isCallPickup);
                                }

                                Keys.onUpPressed: {
                                    view.decrementCurrentIndex();
                                }

                                Keys.onDownPressed: {
                                    view.incrementCurrentIndex();
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

                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        dropdown.visible = false;
                                    }
                                }

                                delegate: Rectangle {
                                    id: delegateBody

                                    implicitWidth: dropdown.viewElementWidth
                                    implicitHeight: dropdown.viewElementHeight

                                    readonly property string colorDefault: ColorStorage.surfaceSecondary
                                    readonly property string colorOnHover: ColorStorage.mainWindowBackground

                                    color: colorDefault

                                    radius: index == 0 || index == view.count - 1 ? 8 * SettingsState.scale : 0

                                    focus: true

                                    onActiveFocusChanged: {
                                        color = activeFocus ? colorOnHover : colorDefault;
                                    }

                                    Shortcut {
                                        enabled: true
                                        sequence: index + 1

                                        onActivated: {
                                            view.doWorkOnListItemClick(phoneNumber);
                                            dropdown.visible = false;
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
                                        id: topCorners

                                        anchors.top: parent.top

                                        height: parent.height / 3
                                        width: parent.width
                                        color: parent.color
                                        enabled: false
                                        visible: index == view.count - 1
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
                                            if (containsMouse) {
                                                view.doWorkOnListItemClick(phoneNumber);
                                                dropdown.visible = false;
                                            }
                                        }
                                    }

                                    Keys.onReturnPressed: {
                                        view.doWorkOnListItemClick(phoneNumber);
                                        dropdown.visible = false;
                                    }

                                    Keys.onEnterPressed: {
                                        view.doWorkOnListItemClick(phoneNumber);
                                        dropdown.visible = false;
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"

                                        Text {
                                            id: description

                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left:  parent.left
                                            anchors.leftMargin: 15 * SettingsState.scale
                                            anchors.right: parent.right
                                            anchors.rightMargin: 15 * SettingsState.scale

                                            font.family: "Segoe UI"
                                            font.pixelSize: 13 * SettingsState.scale

                                            color: ColorStorage.iconsAndTextPrimary

                                            text: (phoneTypeId != Contact.CallPickup ? qsTrId("contacts_phone_dropdown_dial_to") + " " : "" )+
                                                  phoneType + " " +  phoneNumber
                                            elide: Text.ElideRight

                                            Component.onCompleted: {
                                                var margin = 30 * SettingsState.scale;

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
                                        }
                                    }
                                }
                            }
                        }

                        background: Rectangle {
                            color: ColorStorage.surfaceSecondary
                            radius: 8 * SettingsState.scale

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

            Loader {
                id: phonesDropdownLoader
                sourceComponent: phonesDropdownComponent
            }


            Component {
                id: messagePhonesDropdownComponent

                ApplicationWindow {
                    id: window

                    property alias model: view.model
                    property alias dropdown: dropdown
                    property bool alwaysOnTop: SettingsState.alwaysOnTop

                    flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint

                    onAlwaysOnTopChanged: {
                        var flags = window.flags;
                        flags = alwaysOnTop ? (flags | Qt.WindowStaysOnTopHint)
                                            : (flags & ~Qt.WindowStaysOnTopHint);
                        window.flags = flags;
                    }

                    visible: dropdown.visible

                    property int xOnOpen: 0
                    property int yOnOpen: 0

                    width: dropdown.width + 12 * SettingsState.scale
                    height: dropdown.height + 12 * SettingsState.scale

                    color: "transparent"

                    function open() {
                        dropdown.open();
                        window.requestActivate();

                        xOnOpen = x;
                        yOnOpen = y;

                        view.currentIndex = 0;

                        if (Screen.desktopAvailableWidth < xOnOpen + window.width) {
                            window.x = xOnOpen - window.width - 6 * SettingsState.scale;
                        }

                        if (Screen.desktopAvailableHeight < yOnOpen + window.height) {
                            window.y = yOnOpen - window.height - 6 * SettingsState.scale;
                        }
                    }

                    onWidthChanged: {
                        if (Screen.desktopAvailableWidth < xOnOpen + window.width) {
                            window.x = xOnOpen - window.width - 6 * SettingsState.scale;
                        }
                    }

                    onHeightChanged: {
                        if (Screen.desktopAvailableHeight < yOnOpen + window.height) {
                            window.y = yOnOpen - window.height - 6 * SettingsState.scale;
                        }
                    }

                    Popup {
                        id: dropdown

                        property int viewElementMaxWidth: 300 * SettingsState.scale
                        property int viewElementWidth: 0 * SettingsState.scale
                        property int viewElementHeight: 40 * SettingsState.scale

                        // add border in 1 px
                        width: view.count ? viewElementWidth + 2 * SettingsState.scale : 0
                        height: view.count ? viewElementHeight * view.count + 2 * SettingsState.scale : 0

                        margins: 6 * SettingsState.scale

                        focus: true

                        closePolicy: Popup.CloseOnPressOutside

                        onViewElementWidthChanged: {
                            width = view.count ? viewElementWidth + 2 * SettingsState.scale : 0;
                        }

                        contentItem: Rectangle {
                            anchors.fill: parent
                            color: "transparent"

                            ListView {
                                id: view

                                anchors.fill: parent
                                anchors.margins: 1 * SettingsState.scale

                                model: AppState.messageNumbersModel

                                interactive: false
                                focus: true

                                function doWorkOnListItemClick(number) {
                                    if (SettingsState.compactWindowMode) {
                                        ActionProvider.showCompactWindowMode(false);
                                    }
                                    ActionProvider.showMessagingWindow(true);
                                    ActionProvider.changeMessagingWindowFocusToInput();
                                    ActionProvider.sendMessageNumberFromUi(number);
                                }

                                Keys.onUpPressed: {
                                    view.decrementCurrentIndex();
                                }

                                Keys.onDownPressed: {
                                    view.incrementCurrentIndex();
                                }

                                Keys.onTabPressed: {
                                    dropdown.visible = false;
                                }

                                Keys.onEscapePressed: {
                                    dropdown.visible = false;
                                }

                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        dropdown.visible = false;
                                    }
                                }

                                delegate: Rectangle {
                                    id: delegateBody

                                    implicitWidth: dropdown.viewElementWidth
                                    implicitHeight: dropdown.viewElementHeight

                                    readonly property string colorDefault: ColorStorage.surfaceSecondary
                                    readonly property string colorOnHover: ColorStorage.mainWindowBackground

                                    color: colorDefault

                                    radius: index == 0 || index == view.count - 1 ? 8 * SettingsState.scale : 0

                                    onActiveFocusChanged: {
                                        color = activeFocus ? colorOnHover : colorDefault;
                                    }

                                    Shortcut {
                                        enabled: true
                                        sequence: index + 1

                                        onActivated: {
                                            view.doWorkOnListItemClick(phoneNumber);
                                            dropdown.visible = false;
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
                                        id: topCorners

                                        anchors.top: parent.top

                                        height: parent.height / 3
                                        width: parent.width
                                        color: parent.color
                                        enabled: false
                                        visible: index == view.count - 1
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
                                            if (containsMouse) {
                                                view.doWorkOnListItemClick(phoneNumber);
                                                dropdown.visible = false;
                                            }
                                        }
                                    }

                                    Keys.onReturnPressed: {
                                        view.doWorkOnListItemClick(phoneNumber);
                                        dropdown.visible = false;
                                    }

                                    Keys.onEnterPressed: {
                                        view.doWorkOnListItemClick(phoneNumber);
                                        dropdown.visible = false;
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"

                                        Text {
                                            id: description

                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left:  parent.left
                                            anchors.leftMargin: 15 * SettingsState.scale
                                            anchors.right: parent.right
                                            anchors.rightMargin: 15 * SettingsState.scale

                                            font.family: "Segoe UI"
                                            font.pixelSize: 13 * SettingsState.scale

                                            color: ColorStorage.iconsAndTextPrimary

                                            text: qsTrId("contact_window_send_message") + " " +  phoneNumber

                                            elide: Text.ElideRight

                                            Component.onCompleted: {
                                                var margin = 30 * SettingsState.scale;

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
                                        }
                                    }
                                }
                            }
                        }

                        background: Rectangle {
                            color: ColorStorage.surfaceSecondary
                            radius: 8 * SettingsState.scale

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

            Loader {
                id: messagePhonesDropdownLoader
                sourceComponent: messagePhonesDropdownComponent
            }

            Component {
                id: rowDelegate

                FocusScope {
                    id: delegateFocusScope

                    property bool isCurrentItem: ListView.isCurrentItem

                    height: 60 * SettingsState.scale
                    width: parent ? parent.width : 0

                    focus: true

                    Rectangle {
                        id: body

                        radius: 8 * SettingsState.scale

                         property var doWorkOnCompleted: function() {
                            topRectangle.visible = index != 0 && listview.itemAtIndex(index).focus
                         }

                        Rectangle{
                            id: topRectangle
                            anchors.top: parent.top
                            width: body.width
                            color: parent.color
                            height: 8 * SettingsState.scale

                            visible: index != 0

                        }

                        Rectangle{
                            id: bottomRectangle
                            anchors.bottom: parent.bottom
                            width: body.width
                            color: parent.color
                            height: 8 * SettingsState.scale
                            visible: index != listview.count - 1
                        }

                        width: parent.width
                        height: 60 * SettingsState.scale

                        property string colorDefault: ColorStorage.surfaceSecondary
                        property string colorHovered: ColorStorage.mainWindowBackground
                        property alias contextMenuLoader: contextMenuLoader

                        color: delegateFocusScope.isCurrentItem && (listview.activeFocus || (contextMenuLoader.item && contextMenuLoader.item.visible))
                               ? colorHovered : colorDefault

                        MouseArea {
                            id: mouseArea

                            property bool nameAreaContainsMouse: false

                            anchors.fill: parent
                            hoverEnabled: true

                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onPressed: {
                                contextMenuLoader.sourceComponent = null;
                                listview.forceActiveFocus();
                                sendMessageButton.focus = false;
                                callButton.focus = false;
                                listview.currentIndex = index;
                                listview.selectedContactId = contactUUID;
                                listview.selectedContactType = contactType;

                                if (mouseArea.pressedButtons & Qt.RightButton) {
                                    contextMenuLoader.sourceComponent = contextMenuComponent;
                                    contextMenuLoader.item.x = mouseArea.x + mouseX;
                                    contextMenuLoader.item.y = mouseArea.y + mouseY;
                                }
                            }
                        }

                        Loader {
                            id: contextMenuLoader
                        }

                        Component {
                            id: contactComplexDescriptionComponent

                            Item {
                                anchors.fill: parent

                                Image {
                                    id: statusImage

                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12 * SettingsState.scale

                                    width: 25 * SettingsState.scale
                                    height: 25 * SettingsState.scale

                                    sourceSize.width: width
                                    sourceSize.height: height

                                    source: image
                                }

                                RowLayout {
                                    id: nameLabelLayout

                                    anchors.top: parent.top
                                    anchors.topMargin: 15 * SettingsState.scale
                                    anchors.left: statusImage.right
                                    anchors.leftMargin: 12 * SettingsState.scale
                                    anchors.right: parent.right

                                    Text {
                                        id: nameLabel

                                        Layout.maximumWidth: parent.width - typeImage.width - 20 * SettingsState.scale
                                        Layout.preferredWidth: implicitWidth

                                        font.pixelSize: 13 * SettingsState.scale
                                        font.family: "Segoe UI"

                                        elide: Text.ElideRight

                                        text: name

                                        color: ColorStorage.iconsAndTextPrimary

                                        MouseArea {
                                            id: displayNameMouseArea

                                            anchors.fill: parent

                                            hoverEnabled: true

                                            acceptedButtons: Qt.NoButton
                                            onPressed: mouseArea.pressed()

                                            ToolTip {
                                                visible: displayNameMouseArea.containsMouse && content.text && nameLabel.implicitWidth > nameLabel.width
                                                delay: 1000
                                                timeout: 5000
                                                contentItem: Text {
                                                    id: content
                                                    text: nameLabel.text ? nameLabel.text : ""
                                                    color: ColorStorage.mainWindowBackground
                                                    wrapMode: Text.WordWrap
                                                }

                                                background: Rectangle {
                                                    color: ColorStorage.iconsAndTextPrimary
                                                }
                                            }

                                            onContainsMouseChanged: mouseArea.nameAreaContainsMouse = containsMouse
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true

                                        height: typeImage.height

                                        MouseArea {
                                            id: imageArea
                                            anchors.fill: typeImage

                                            hoverEnabled: true
                                        }

                                        Image {
                                            id: typeImage

                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter

                                            width: 14 * SettingsState.scale
                                            height: 14 * SettingsState.scale

                                            sourceSize.width: width
                                            sourceSize.height: height

                                            ToolTip {
                                                visible: typeImage.visible && imageArea.containsMouse && bookName && bookName.length > 0
                                                delay: 1000
                                                timeout: 5000
                                                contentItem: Text {
                                                    text: bookName ? bookName : ""
                                                    color: ColorStorage.mainWindowBackground
                                                    wrapMode: Text.WordWrap
                                                }

                                                background: Rectangle {
                                                    color: ColorStorage.iconsAndTextPrimary
                                                }
                                            }
                                            source: {
                                                switch(contactType) {
                                                case ContactType.CiscoXml:
                                                case ContactType.GoogleContacts:
                                                    return "qrc:/images/external_contact_grey.svg";
                                                }

                                                return "";
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.top: nameLabelLayout.bottom
                                    anchors.topMargin: 3 * SettingsState.scale
                                    anchors.left: nameLabelLayout.left
                                    anchors.right: nameLabelLayout.right

                                    font.pixelSize: 12 * SettingsState.scale
                                    font.family: "Segoe UI"
                                    color: ColorStorage.menuBorderColor

                                    elide: Text.ElideRight

                                    text: statusText
                                }
                            }
                        }

                        Component {
                            id: contactSimpleDescriptionComponent

                            Item {
                                id: itemContactSimpleDescriptionComponent
                                anchors.fill: parent

                                RowLayout {
                                    id: nameLabelLayout

                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20 * SettingsState.scale
                                    anchors.right: parent.right

                                    Text {
                                        id: nameLabel

                                        Layout.maximumWidth: parent.width - typeImage.width - 20 * SettingsState.scale
                                        Layout.preferredWidth: implicitWidth

                                        font.pixelSize: 13 * SettingsState.scale
                                        font.family: "Segoe UI"

                                        elide: Text.ElideRight

                                        text: name
                                        color: ColorStorage.iconsAndTextPrimary

                                        MouseArea {
                                            id: displayNameMouseArea

                                            anchors.fill: parent

                                            hoverEnabled: true

                                            acceptedButtons: Qt.NoButton
                                            onPressed: mouseArea.pressed()

                                            ToolTip {
                                                visible: displayNameMouseArea.containsMouse && content.text && nameLabel.implicitWidth > nameLabel.width
                                                delay: 1000
                                                timeout: 5000
                                                contentItem: Text {
                                                    id: content
                                                    text: nameLabel.text ? nameLabel.text : ""
                                                    color: ColorStorage.mainWindowBackground
                                                    wrapMode: Text.WordWrap
                                                }

                                                background: Rectangle {
                                                    color: ColorStorage.iconsAndTextPrimary
                                                }
                                            }

                                            onContainsMouseChanged: mouseArea.nameAreaContainsMouse = containsMouse
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true

                                        height: typeImage.height

                                        MouseArea {
                                            id: imageArea
                                            anchors.fill: typeImage

                                            hoverEnabled: true
                                        }

                                        Image {
                                            id: typeImage

                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter

                                            width: 14 * SettingsState.scale
                                            height: 14 * SettingsState.scale

                                            sourceSize.width: width
                                            sourceSize.height: height

                                            ToolTip {
                                                visible: typeImage.visible && imageArea.containsMouse && bookName && bookName.length > 0
                                                delay: 1000
                                                timeout: 5000
                                                contentItem: Text {
                                                    text: bookName ? bookName : ""
                                                    color: ColorStorage.mainWindowBackground
                                                    wrapMode: Text.WordWrap
                                                }

                                                background: Rectangle {
                                                    color: ColorStorage.iconsAndTextPrimary
                                                }
                                            }

                                            source: {
                                                switch(contactType) {
                                                case ContactType.CiscoXml:
                                                case ContactType.GoogleContacts:
                                                    return "qrc:/images/external_contact_grey.svg";
                                                }

                                                return "";
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Loader {
                            id: contactDescriptionLoader

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.right: callButton.left
                            anchors.rightMargin: 15 * SettingsState.scale
                        }

                        SoftphonePro.SquareButton {
                            id: sendMessageButton

                            anchors.right: callButton.left
                            anchors.rightMargin: 8 * SettingsState.scale
                            anchors.verticalCenter: parent.verticalCenter

                            scale: SettingsState.scale

                            width: 32 * SettingsState.scale
                            height: 32 * SettingsState.scale


                            imageWidth: 18 * SettingsState.scale
                            imageHeight: 18 * SettingsState.scale

                            colorDefault: ColorStorage.sSizeButtonDefault
                            colorOnHover: ColorStorage.sSizeButtonOnHover
                            colorOnPress: ColorStorage.sSizeButtonOnPress
                            colorOnDisabled: ColorStorage.sSizeButtonDisabled

                            focus: false

                            radius: 8 * SettingsState.scale


                            borderColorDefault: ColorStorage.sSizeButtonBorderDefault
                            borderWidthDefault: 1 * SettingsState.scale

                            imageColorDefault: ColorStorage.sSizeButtonImageDefault
                            imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                            imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                            imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                            imageDefault: "qrc:/images/message_button_default.svg"

                            tooltipText: qsTrId("message_button_tooltip") + Translator.translate

                            enabled: !AppFeatures.hideMessagingWindow && SettingsState.messagingEnable

                            visible: enabled && phonesCount > 0 && (mouseArea.containsMouse || sendMessageButton.hovered || callButton.hovered || mouseArea.nameAreaContainsMouse)
                            property var timeNow: AppState.timeNow
                            property int secondsDisabledMax: 2
                            property int secondsDisabledLeft: 0
                            property bool disableWorkFunction: false

                            doWorkOnButtonClick: function() {
                                forceActiveFocus();

                                if (!disableWorkFunction) {

                                    if (phonesCount > 1) {
                                        ActionProvider.filterContactMessagePhones(contactUUID);

                                        // set dropdown position
                                        var point = sendMessageButton.mapToItem(root, width / 2, height / 2);
                                        messagePhonesDropdownLoader.item.x = contactsWindow.x + point.x;
                                        messagePhonesDropdownLoader.item.y = contactsWindow.y + point.y;

                                        messagePhonesDropdownLoader.item.open();
                                        return;
                                    }
                                }

                                if (SettingsState.compactWindowMode) {
                                    ActionProvider.showCompactWindowMode(false);
                                }
                                ActionProvider.showMessagingWindow(true);
                                ActionProvider.changeMessagingWindowFocusToInput();
                                ActionProvider.sendMessageNumberFromUi(phoneNumbers[0]);

                                secondsDisabledLeft = 0;
                                disableWorkFunction = true;
                            }


                            onTimeNowChanged: {
                                if (secondsDisabledLeft == secondsDisabledMax) {
                                    return;
                                }

                                secondsDisabledLeft += 1;

                                if (secondsDisabledLeft >= secondsDisabledMax) {
                                    disableWorkFunction = false;
                                }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: -2 * SettingsState.scale
                                anchors.right: parent.right
                                anchors.rightMargin: -2 * SettingsState.scale

                                width: 12 * SettingsState.scale
                                height: width
                                radius: width / 2

                                color: ColorStorage.surfaceSecondary

                                visible: phonesCount > 1

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width - 2 * SettingsState.scale
                                    height: parent.height - 2 * SettingsState.scale
                                    radius: width / 2

                                    border.color: sendMessageButton.pressed ? sendMessageButton.borderColorOnPress : (sendMessageButton.hovered ? sendMessageButton.borderColorOnHover : sendMessageButton.borderColorDefault)

                                    color: sendMessageButton.pressed ? sendMessageButton.colorOnPress : (sendMessageButton.hovered ? sendMessageButton.colorOnHover : sendMessageButton.colorDefault)

                                    Image {
                                        id: chevronImageSendMessageButton

                                        anchors.centerIn: parent
                                        visible: false

                                        width: 10 * SettingsState.scale
                                        height: 10 * SettingsState.scale

                                        sourceSize.width: width
                                        sourceSize.height: height

                                        source: "qrc:/images/chevron_down.svg"
                                    }

                                    IconShader {
                                        anchors.centerIn: parent

                                        imageSrcComponent: chevronImageSendMessageButton
                                        imgColor: sendMessageButton.pressed ? sendMessageButton.imageColorOnPress : sendMessageButton.imageColorDefault
                                        imageWidth: chevronImageSendMessageButton.width
                                        imageHeight: chevronImageSendMessageButton.height
                                    }
                                }
                            }

                        }

                        SoftphonePro.SquareButton {
                            id: callButton

                            anchors.right: parent.right
                            anchors.rightMargin: 12 * SettingsState.scale
                            anchors.verticalCenter: parent.verticalCenter

                            scale: SettingsState.scale

                            width: 32 * SettingsState.scale
                            height: 32 * SettingsState.scale

                            borderWidthDefault: 1 * SettingsState.scale
                            borderColorDefault: ColorStorage.sSizeButtonBorderDefault

                            imageWidth: 16 * SettingsState.scale
                            imageHeight: 16 * SettingsState.scale

                            tooltipText: phonesCount > 1 ? "" : phoneTypes[0] ? (qsTrId("contacts_phone_dropdown_dial_to") + Translator.translate + " " + phoneTypes[0] + " " + phoneNumbers[0]) :
                                                                                (qsTrId("contacts_phone_dropdown_dial_to") + Translator.translate + " " + phoneNumbers[0])

                            colorDefault: ColorStorage.sSizeButtonDefault
                            colorOnHover: ColorStorage.sSizeButtonOnHover
                            colorOnPress: ColorStorage.sSizeButtonOnPress
                            colorOnDisabled: ColorStorage.sSizeButtonDisabled

                            focus: true

                            radius: 8 * SettingsState.scale

                            imageColorDefault: ColorStorage.sSizeButtonImageDefault
                            imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                            imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                            imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                            imageDefault: "qrc:/images/call_default.svg"

                            visible: phonesCount > 0 && (mouseArea.containsMouse || sendMessageButton.hovered || callButton.hovered || mouseArea.nameAreaContainsMouse)

                            property var timeNow: AppState.timeNow
                            property int secondsDisabledMax: 2
                            property int secondsDisabledLeft: 0
                            property bool disableWorkFunction: false

                            doWorkOnButtonClick: function() {
                                forceActiveFocus();

                                if (!disableWorkFunction) {

                                    if (phonesCount > 1 || (AppState.sipAccountDtfm != "" && phonesCount > 0)) {
                                        if (phonesCount == 1) {
                                            if (contactContainsExt) {
                                                ActionProvider.filterContactPhones(contactUUID);

                                                // set dropdown position
                                                var point = callButton.mapToItem(root, width / 2, height / 2);
                                                phonesDropdownLoader.item.x = contactsWindow.x + point.x;
                                                phonesDropdownLoader.item.y = contactsWindow.y + point.y;

                                                phonesDropdownLoader.item.open();
                                                return;
                                            }
                                        } else {
                                            ActionProvider.filterContactPhones(contactUUID);

                                            // set dropdown position
                                            var point = callButton.mapToItem(root, width / 2, height / 2);
                                            phonesDropdownLoader.item.x = contactsWindow.x + point.x;
                                            phonesDropdownLoader.item.y = contactsWindow.y + point.y;

                                            phonesDropdownLoader.item.open();
                                            return;
                                        }
                                    }

                                    ActionProvider.sendDialedString(phoneNumbers[0]);
                                    ActionProvider.makeCall(phoneNumbers[0]);

                                    secondsDisabledLeft = 0;
                                    disableWorkFunction = true;
                                }
                            }

                            onTimeNowChanged: {
                                if (secondsDisabledLeft == secondsDisabledMax) {
                                    return;
                                }

                                secondsDisabledLeft += 1;

                                if (secondsDisabledLeft >= secondsDisabledMax) {
                                    disableWorkFunction = false;
                                }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: -2 * SettingsState.scale
                                anchors.right: parent.right
                                anchors.rightMargin: -2 * SettingsState.scale

                                width: 12 * SettingsState.scale
                                height: width
                                radius: width / 2

                                color: ColorStorage.surfaceSecondary

                                visible: phonesCount > 1 || (AppState.sipAccountDtfm != "" && phonesCount > 0 && contactContainsExt)

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width - 2 * SettingsState.scale
                                    height: parent.height - 2 * SettingsState.scale
                                    radius: width / 2

                                    border.color: callButton.pressed ? callButton.borderColorOnPress : (callButton.hovered ? callButton.borderColorOnHover : callButton.borderColorDefault)

                                    color: callButton.pressed ? callButton.colorOnPress : (callButton.hovered ? callButton.colorOnHover : callButton.colorDefault)

                                    Image {
                                        id: chevronImageCallButton

                                        anchors.centerIn: parent
                                        visible: false

                                        width: 10 * SettingsState.scale
                                        height: 10 * SettingsState.scale

                                        sourceSize.width: width
                                        sourceSize.height: height

                                        source: "qrc:/images/chevron_down.svg" 
                                    }

                                    IconShader {
                                        anchors.centerIn: parent

                                        imageSrcComponent: chevronImageCallButton
                                        imgColor: callButton.pressed ? callButton.imageColorOnPress : callButton.imageColorDefault
                                        imageWidth: chevronImageCallButton.width
                                        imageHeight: chevronImageCallButton.height
                                    }


                                }
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: 1 * SettingsState.scale
                            color: ColorStorage.secondaryWindowBackground
                        }

                        property int visualTypeIdx: visualType
                        onVisualTypeIdxChanged:  {
                            contactDescriptionLoader.sourceComponent = visualType ?
                                        contactComplexDescriptionComponent : contactSimpleDescriptionComponent;
                        }

                        Component.onCompleted: {
                            contactDescriptionLoader.sourceComponent = visualType ?
                                        contactComplexDescriptionComponent : contactSimpleDescriptionComponent;
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                id: listviewRectangle
                color: ColorStorage.secondaryWindowBackground

                Text {
                    id: callEndLabel

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -15 * SettingsState.scale

                    font.pixelSize: 13 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.iconsAndTextPrimary
                    visible: listview.count == 0

                    text: qsTrId("contacts_window_no_contacts") + Translator.translate
                }

                ListView {
                    id: listview

                    anchors.fill: parent
                    model: AppState.contactModel

                    layer.enabled: true
                    layer.textureSize: Qt.size(1920 * SettingsState.scale, 1080 * SettingsState.scale)
                    layer.effect: OpacityMask {
                        source: listview
                        maskSource: Rectangle {
                            width: listviewRectangle.width
                            height: listviewRectangle.height
                            anchors.top: parent.top

                            radius: 8 * SettingsState.scale
                        }
                    }

                    focus: true

                    highlightFollowsCurrentItem: false
                    boundsBehavior: Flickable.StopAtBounds

                    section.property: listview.count > 10 ?
                                          (SettingsState.displayBlfContactsFirst ? "sectionPropertyRole" : "name") : ""
                    section.criteria: ViewSection.FirstCharacter
                    section.delegate: sectionDelegate

                    delegate: rowDelegate

                    property string selectedContactId: ""
                    property int selectedContactType: 0

                    ScrollBar.vertical: ScrollBar {
                        id: scrollBar
                        visible: true
                        stepSize: 0.0245
                    }

                    Keys.onUpPressed: {
                        listview.decrementCurrentIndex();
                        scrollBar.decrease();
                    }

                    Keys.onDownPressed: {
                        listview.incrementCurrentIndex();
                        scrollBar.increase();
                    }

                    Shortcut {
                        sequence: "PgUp"

                        onActivated: {
                            listview.decrementCurrentIndex();
                            scrollBar.decrease();
                        }
                    }

                    Shortcut {
                        sequence: "PgDown"

                        onActivated: {
                            listview.incrementCurrentIndex();
                            scrollBar.increase();
                        }
                    }

                    FocusSender {
                        property int preferredHeight: listview.height - listview.contentHeight
                        receiver: focusReceiver
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: preferredHeight > 0 ? preferredHeight : 0
                    }

                    KeyNavigation.tab: searchInput
                    KeyNavigation.backtab: addButton
                }
            }
        }
    }
}
