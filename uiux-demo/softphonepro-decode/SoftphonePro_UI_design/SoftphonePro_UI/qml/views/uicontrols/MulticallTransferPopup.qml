import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import Flux 1.0
import QtGraphicalEffects 1.15

FocusScope {
    id: root

    focus: true
    implicitWidth: phonesDropdownLoader.width
    implicitHeight: phonesDropdownLoader.height

    property bool showTransferMethodBlock: true

    property bool alwaysOnTop: false
    property int currentActiveCallId: AppState.activeCall ? AppState.activeCall.id : 0
    property bool activeCallsAreVisible: true
    property int currentAccountId: 0

    onImplicitWidthChanged: {
        if (Screen.desktopAvailableWidth < root.x + root.width) {
            root.x -= root.width;
            phonesDropdownLoader.item.x = root.x;
        }
    }

    onImplicitHeightChanged: {
        if (Screen.desktopAvailableHeight < root.y + root.height) {
            root.y -= root.height;
            phonesDropdownLoader.item.y = root.y;
        }
    }

    function open() {
        // start updating model to get actual presence info
        ActionProvider.updateCallTransferModel(true);

        phonesDropdownLoader.item.dropdown.open();
        phonesDropdownLoader.item.requestActivate();

        if (Screen.desktopAvailableWidth < root.x + root.width) {
            root.x -= root.width;
        }

        phonesDropdownLoader.item.x = root.x;
        phonesDropdownLoader.item.y = root.y;

        root.implicitWidth = Qt.binding(function() { return phonesDropdownLoader.item.width; });
        root.implicitHeight = Qt.binding(function() { return phonesDropdownLoader.item.height; });
    }

    Component {
        id: phonesDropdownComponent

        ApplicationWindow {
            id: window

            property alias dropdown: dropdown

            flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint

            width: scope.width + 20 * SettingsState.scale
            height: scope.height + 20 * SettingsState.scale
            color: "transparent"
            visible: dropdown.visible

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

                focus: true
                anchors.centerIn: parent

                property var doWorkOnListItemClick: function(phone) {
                    if (!AppState.activeCall) {
                        return;
                    }

                    switch (transferMethodBlock.index()) {
                    case 0:
                        if (AppState.activeCall.status == SipCall.Connecting) {
                            ActionProvider.redirectCall(AppState.activeCall.id, phone);
                        } else {
                            ActionProvider.transferCall(AppState.activeCall.id, phone);
                        }
                        break;

                    case 1:
                        ActionProvider.makeCallViaAccount(phone, AppState.activeCall.accountId, true, true)
                        break;
                    }
                }

                property var doWorkOnActiveCallClick: function(destCallId) {
                    if (!AppState.activeCall) {
                        return;
                    }
                    ActionProvider.transferActiveCall(currentActiveCallId, destCallId)
                }

                Popup {
                    id: dropdown
                    property int viewElementMaxWidth: 1000 * SettingsState.scale
                    property int viewElementWidth: 0 * SettingsState.scale
                    property int viewElementMinWidth: 200 * SettingsState.scale
                    property int viewElementHeight: 34 * SettingsState.scale
                    property int viewMaxElementCount: 9
                    property int activeCallViewMaxCount: 3

                    // add border in 1 px
                    width: view.count || activeCallsView.visible ? viewElementWidth + 2 * SettingsState.scale : 315 * SettingsState.scale
                    height: {
                        var rowCount = viewMaxElementCount > view.count ?
                                    view.count : viewMaxElementCount;

                        var searchInputHeight = searchInput.visible ? searchInput.height + 16 * SettingsState.scale : 0;
                        var titleHeight = title.visible ? title.height + 12 * SettingsState.scale : 0;
                        var activeCallsTitleHeight = activeCallsTitle.visible ? activeCallsTitle.height + 12 * SettingsState.scale : 0;
                        var contactListTitleHeight = contactListTitle.visible ? contactListTitle.height + 12 * SettingsState.scale : 0;
                        var activeCallsViewHeight = activeCallsView.visible ? viewElementHeight * (activeCallsView.count - 1) + 12 * SettingsState.scale : 0;
                        var emptyContactsTitleHeight = emptyContactsTitle.visible ? emptyContactsTitle.height + 8 * SettingsState.scale : 0;
                        var transferRadioBtnHeight = transferMethodBlock.height + 10 * SettingsState.scale;
                        var contactListBottomMargin = rowCount !== 0 ? 12 * SettingsState.scale : 0;

                        return viewElementHeight * rowCount + contactListBottomMargin + searchInputHeight + titleHeight + activeCallsTitleHeight + contactListTitleHeight + activeCallsViewHeight + emptyContactsTitleHeight + transferRadioBtnHeight;
                    }

                    closePolicy: Popup.CloseOnPressOutside

                    onVisibleChanged: {
                        if (!visible) {
                            // stop updating model. We do not need actual presence info
                            ActionProvider.updateCallTransferModel(false);
                        }
                    }

                    contentItem: Rectangle {

                        anchors.fill: parent
                        color: ColorStorage.mainWindowBackground
                        radius: 8 * SettingsState.scale

                        Rectangle {
                            id : body
                            anchors.fill: parent
                            color: ColorStorage.mainWindowBackground
                            radius: 8 * SettingsState.scale

                            SearchInput {
                                id: searchInput

                                anchors.top: parent.top
                                anchors.topMargin: 8 * SettingsState.scale
                                anchors.leftMargin: 12 * SettingsState.scale
                                anchors.rightMargin: 12 * SettingsState.scale
                                anchors.bottomMargin: 8 * SettingsState.scale
                                anchors.left: parent.left
                                anchors.right: parent.right

                                visible: true
                                focus: !view.focus && !activeCallsView.focus && !transferMethodBlock.focus

                                height: 32 * SettingsState.scale

                                property string text: edit.text

                                edit.font.pixelSize: 15 * SettingsState.scale
                                edit.color: ColorStorage.iconsAndTextPrimary
                                body.border.color: ColorStorage.grayNeutral
                                deleteButton.borderColorOnHover: ColorStorage.mainWindowBackground
                                deleteButton.colorOnPress: ColorStorage.mainWindowBackground

                                placeholder.font.pixelSize: 11 * SettingsState.scale
                                placeholder.anchors.rightMargin: 8 * SettingsState.scale
                                placeholder.color: ColorStorage.menuBorderColor
                                placeholder.text: qsTrId("call_transfer_popup_search_and_enter_placeholder") + Translator.translate

                                onTextChanged: {
                                    ActionProvider.filterTransferredPhones(edit.text);
                                    if (edit.text != "") {
                                        activeCallsAreVisible = false;
                                    }
                                    else {
                                        activeCallsAreVisible = true;
                                    }
                                }

                                onVisibleChanged: {
                                    if (visible) {
                                        edit.text = "";
                                        forceActiveFocus();
                                        ActionProvider.filterTransferredPhones(edit.text);
                                    }
                                }

                                Keys.onTabPressed: {
                                    if (activeCallsView.visible) {
                                        activeCallsView.forceActiveFocus();
                                        activeCallsView.currentIndex = 0;
                                    }
                                    else {
                                        view.forceActiveFocus();
                                        view.currentIndex = 0;
                                    }
                                }

                                Keys.onDownPressed: {
                                    if (activeCallsView.visible) {
                                        activeCallsView.forceActiveFocus();
                                        activeCallsView.currentIndex = 0;
                                    }
                                    else {
                                        view.forceActiveFocus();
                                        view.currentIndex = 0;
                                    }
                                }

                                Keys.onUpPressed: {
                                    view.forceActiveFocus();
                                    view.currentIndex = view.count;
                                }

                                Keys.onEnterPressed: {
                                    switch (transferMethodBlock.index()) {
                                    case 0:
                                        ActionProvider.transferCall(AppState.activeCall.id, edit.text)
                                        break;

                                    case 1:
                                        ActionProvider.makeCallViaAccount(edit.text, AppState.activeCall.accountId, true, true)
                                        break;
                                    }

                                    activeCallsAreVisible = true;
                                    dropdown.visible = false;
                                }

                                Keys.onReturnPressed: {
                                    switch (transferMethodBlock.index()) {
                                    case 0:
                                        ActionProvider.transferCall(AppState.activeCall.id, edit.text)
                                        break;

                                    case 1:
                                        ActionProvider.makeCallViaAccount(edit.text, AppState.activeCall.accountId, true, true)
                                        break;
                                    }

                                    activeCallsAreVisible = true;
                                    dropdown.visible = false;
                                }

                                onContextMenuIsOpenChanged: {
                                    if (!contextMenuIsOpen) {
                                        window.requestActivate();
                                        if (!activeFocus && !view.activeFocus && !activeCallsView.activeFocus && !transferMethodBlock.activeFocus) {
                                            dropdown.close();
                                        }
                                    }
                                }

                                onActiveFocusChanged: {
                                    if (!activeFocus && !view.activeFocus && !activeCallsView.activeFocus && !transferMethodBlock.activeFocus && !contextMenuIsOpen) {
                                        dropdown.visible = false;
                                    }
                                }
                            }

                            TextArea {
                                id: title
                                anchors.top: searchInput.bottom
                                anchors.topMargin: 20 * SettingsState.scale
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 12 * SettingsState.scale
                                anchors.rightMargin: 12 * SettingsState.scale

                                visible: !view.count && !activeCallsView.visible
                                implicitHeight: 40 * SettingsState.scale

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top

                                    wrapMode: Text.WordWrap
                                    font.pixelSize: 10 * SettingsState.scale
                                    color: ColorStorage.additionalText
                                    text: qsTrId("call_transfer_dropdown_empty_message") + Translator.translate
                                }
                            }

                            TextArea {
                                id: activeCallsTitle
                                anchors.top: searchInput.bottom
                                anchors.topMargin: 20 * SettingsState.scale
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 12 * SettingsState.scale
                                anchors.rightMargin: 12 * SettingsState.scale

                                implicitHeight: visible ? 18 * SettingsState.scale : 0
                                visible: activeCallsView.visible

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter

                                    wrapMode: Text.WordWrap
                                    font.pixelSize: 12 * SettingsState.scale
                                    color: ColorStorage.iconsAndTextSecondary
                                    text: qsTrId("call_transfer_popup_active_calls") + Translator.translate
                                }
                            }

                            ListView {
                                id: activeCallsView
                                anchors.top: activeCallsTitle.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: 12 * SettingsState.scale

                                implicitHeight: {
                                    if (activeCallsAreVisible) {
                                        var rowCount = dropdown.activeCallViewMaxCount > activeCallsView.count - 1 ?
                                                    activeCallsView.count - 1 : dropdown.activeCallViewMaxCount;

                                        return dropdown.viewElementHeight * rowCount;
                                    }
                                    return 0;
                                }

                                model: AppState.onlyActiveCallsModel

                                highlightFollowsCurrentItem: false
                                boundsBehavior: Flickable.StopAtBounds

                                interactive: true
                                focus: !searchInput.focus && !view.focus && !transferMethodBlock.focus

                                clip: true

                                visible: count - 1 > 0 && activeCallsAreVisible

                                enabled: visible

                                ScrollBar.vertical: ScrollBar {
                                    id: activeCallsScrollBar
                                    active: activeCallsView.activeFocus && activeCallsView.count - 1 > dropdown.viewMaxElementCount
                                    visible: false
                                }

                                Keys.onUpPressed: {
                                    if (view.currentIndex == 0) {
                                        searchInput.forceActiveFocus();
                                        return;
                                    }

                                    activeCallsScrollBar.decrease();
                                    activeCallsView.decrementCurrentIndex();
                                }

                                Keys.onDownPressed: {
                                    if (currentIndex == count) {
                                        view.forceActiveFocus();
                                        view.currentIndex = 0;
                                    }
                                    activeCallsScrollBar.increase();
                                    activeCallsView.incrementCurrentIndex();
                                }

                                Keys.onTabPressed: {
                                    view.forceActiveFocus();
                                    view.currentIndex = 0;
                                }

                                Keys.onEscapePressed: {
                                    dropdown.visible = false;
                                }

                                onActiveFocusChanged: {
                                    if (!activeFocus && !searchInput.activeFocus && !view.activeFocus && !transferMethodBlock.activeFocus) {
                                        dropdown.visible = false;
                                    }
                                }

                                property int lastVisualType: 0
                                delegate: Rectangle {
                                    id: activeCallDelegateBody
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    implicitWidth: dropdown.viewElementWidth
                                    implicitHeight: visible ? dropdown.viewElementHeight : 0

                                    readonly property string colorDefault: "transparent"
                                    readonly property string colorOnHover: ColorStorage.secondaryWindowBackground

                                    color: colorDefault

                                    onActiveFocusChanged: {
                                        color = activeFocus ? colorOnHover : colorDefault;
                                    }

                                    visible: currentActiveCallId == callId ? false : true

                                    MouseArea {
                                        anchors.fill: activeCallDelegateBody
                                        hoverEnabled: true

                                        ToolTip {
                                            visible: currentAccountId != callAccountId && parent.containsMouse
                                            delay: 1000
                                            timeout: 5000
                                            width: root.implicitWidth
                                            height: elementToolTipText.height
                                            bottomPadding: 20 * SettingsState.scale
                                            Text {
                                                id: elementToolTipText
                                                width: parent.width
                                                text: qsTrId("multicall_transfer_popup_disable_active_call") + Translator.translate
                                                elide: Text.ElideRight
                                                wrapMode: Text.WordWrap
                                                font.pixelSize: 12 * SettingsState.scale
                                                height: implicitHeight * 1.5 * SettingsState.scale
                                                color: ColorStorage.mainWindowBackground
                                            }

                                            background: Rectangle {
                                                color: ColorStorage.iconsAndTextPrimary
                                            }
                                        }

                                        onEntered: {
                                            activeCallsView.currentIndex = index;
                                            activeCallDelegateBody.forceActiveFocus();
                                        }

                                        onExited: {
                                            if (!parent.activeFocus) {
                                                parent.color = parent.colorDefault;
                                            }
                                        }

                                        onReleased: {
                                            if (containsMouse && currentAccountId == callAccountId) {
                                                scope.doWorkOnActiveCallClick(callId);
                                                dropdown.visible = false;
                                            }
                                        }
                                    }

                                    Keys.onReturnPressed: {
                                        if (currentAccountId == callAccountId) {
                                            scope.doWorkOnActiveCallClick(callId);
                                            dropdown.visible = false;
                                        }
                                    }

                                    Keys.onEnterPressed: {
                                        if (currentAccountId == callAccountId) {
                                            scope.doWorkOnActiveCallClick(callId);
                                            dropdown.visible = false;
                                        }
                                    }

                                    Component {
                                        id: activeCallComponent

                                        Rectangle {
                                            id: description

                                            anchors.fill: parent
                                            anchors.leftMargin: 12 * SettingsState.scale
                                            anchors.rightMargin: 12 * SettingsState.scale

                                            implicitWidth: nameDescription.implicitWidth + phoneDescription.implicitWidth + 10

                                            color: "transparent"

                                            Text {
                                                id: nameDescription

                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.right: phoneDescription.left
                                                anchors.rightMargin: 10 * SettingsState.scale
                                                color: {
                                                    if (currentAccountId == callAccountId) {
                                                        return ColorStorage.iconsAndTextPrimary;
                                                    }
                                                    return ColorStorage.iconsAndTextPrimary;
                                                }

                                                font.family: "Segoe UI"
                                                font.pixelSize: 12 * SettingsState.scale
                                                font.weight: Font.Medium
                                                text: {
                                                    if (callContactName != "") {
                                                        return callContactName;
                                                    }
                                                    return qsTrId("call_transfer_popup_unknown_active_call") + Translator.translate;
                                                }
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                id: phoneDescription

                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.right: parent.right

                                                font.family: "Segoe UI"
                                                font.pixelSize: 12 * SettingsState.scale

                                                color: {
                                                    if (currentAccountId == callAccountId) {
                                                        return ColorStorage.additionalText;
                                                    }
                                                    return ColorStorage.additionalText;
                                                }

                                                text: callRemoteNumber
                                                elide: Text.ElideRight
                                            }

                                            Component.onCompleted: {
                                                var margin = 30 * SettingsState.scale;

                                                if (view.count == 0) {
                                                    if (description.implicitWidth + margin > dropdown.viewElementMaxWidth) {
                                                        dropdown.viewElementWidth = dropdown.viewElementMaxWidth;
                                                        description.width = dropdown.viewElementMaxWidth - margin;
                                                        return;
                                                    }

                                                    if (dropdown.viewElementWidth < dropdown.viewElementMinWidth) {
                                                        dropdown.viewElementWidth = dropdown.viewElementMinWidth;
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

                                    Loader {
                                        id: activeCallLoader
                                        anchors.fill: parent
                                    }

                                    Component.onCompleted: {
                                        activeCallLoader.sourceComponent = activeCallComponent;
                                    }
                                }
                            }

                            TextArea {
                                id: contactListTitle
                                anchors.top: activeCallsView.visible ? activeCallsView.bottom : searchInput.bottom
                                anchors.topMargin: activeCallsView.visible ? 12 * SettingsState.scale : 20 * SettingsState.scale
                                anchors.left: parent.left
                                anchors.right: parent.right

                                height: visible ? 18 * SettingsState.scale : 0
                                visible: !title.visible

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12 * SettingsState.scale
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right

                                    wrapMode: Text.WordWrap
                                    font.pixelSize: 12 * SettingsState.scale
                                    color: ColorStorage.iconsAndTextSecondary
                                    text: qsTrId("call_transfer_popup_contact_list") + Translator.translate
                                }
                            }

                            TextArea {
                                id: emptyContactsTitle
                                anchors.top: contactListTitle.bottom
                                anchors.topMargin: 8 * SettingsState.scale
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 12 * SettingsState.scale
                                anchors.rightMargin: 12 * SettingsState.scale

                                implicitHeight: {
                                    if (dropdown.viewElementWidth > 250 * SettingsState.scale) {
                                        return 30 * SettingsState.scale;
                                    }
                                    return 50 * SettingsState.scale;
                                }

                                height: visible ? implicitHeight : 0
                                visible: !view.count && !title.visible

                                Text {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.right: parent.right

                                    wrapMode:  Text.WordWrap
                                    font.pixelSize: 10 * SettingsState.scale
                                    color: ColorStorage.additionalText

                                    text: qsTrId("call_transfer_dropdown_empty_message") + Translator.translate
                                }
                            }

                            ListView {
                                id: view

                                anchors.top: contactListTitle.bottom
                                anchors.topMargin: 10 * SettingsState.scale
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: transferMethodBlock.top

                                model: AppState.filteredTransferModel

                                highlightFollowsCurrentItem: false
                                boundsBehavior: Flickable.StopAtBounds

                                interactive: true
                                focus: !searchInput.focus && !activeCallsView.focus && !transferMethodBlock.focus

                                clip: true

                                visible: count > 0

                                enabled: visible

                                ScrollBar.vertical: ScrollBar {
                                    id: scrollBar
                                    active: view.activeFocus && view.count > dropdown.viewMaxElementCount
                                    visible: false
                                }

                                Keys.onUpPressed: {
                                    if (view.currentIndex == 0) {
                                        if (activeCallsView.visible){
                                            activeCallsView.forceActiveFocus();
                                            activeCallsView.currentIndex = activeCallsView.count - 1
                                        }
                                        else {
                                            searchInput.forceActiveFocus();
                                        }
                                        return;
                                    }

                                    scrollBar.decrease();
                                    view.decrementCurrentIndex();
                                }

                                Keys.onDownPressed: {
                                    if (currentIndex == count - 1) {
                                        searchInput.forceActiveFocus();
                                        return;
                                    }
                                    scrollBar.increase();
                                    view.incrementCurrentIndex();
                                }

                                Keys.onTabPressed: {
                                    searchInput.forceActiveFocus();
                                }

                                Keys.onEscapePressed: {
                                    dropdown.visible = false;
                                }

                                onActiveFocusChanged: {
                                    if (!activeFocus && !searchInput.activeFocus && !activeCallsView.activeFocus && !transferMethodBlock.activeFocus) {
                                        dropdown.visible = false;
                                    }
                                }

                                property int lastVisualType: 0
                                delegate: Rectangle {
                                    id: delegateBody
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    implicitWidth: dropdown.viewElementWidth
                                    implicitHeight: dropdown.viewElementHeight

                                    readonly property string colorDefault: "transparent"
                                    readonly property string colorOnHover: ColorStorage.secondaryWindowBackground

                                    color: colorDefault

                                    onActiveFocusChanged: {
                                        color = activeFocus ? colorOnHover : colorDefault;
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
                                                scope.doWorkOnListItemClick(phoneNumber);
                                                dropdown.visible = false;
                                            }
                                        }
                                    }

                                    Keys.onReturnPressed: {
                                        scope.doWorkOnListItemClick(phoneNumber);
                                        dropdown.visible = false;
                                    }

                                    Keys.onEnterPressed: {
                                        scope.doWorkOnListItemClick(phoneNumber);
                                        dropdown.visible = false;
                                    }

                                    Component {
                                        id: contactPhoneComplexComponent

                                        Rectangle {
                                            id: description

                                            anchors.fill: parent
                                            anchors.leftMargin: 12 * SettingsState.scale
                                            anchors.rightMargin: 12 * SettingsState.scale

                                            implicitWidth: nameDescription.implicitWidth + phoneDescription.implicitWidth
                                                                                            + statusImage.width + 10 * SettingsState.scale

                                            color: "transparent"

                                            Image {
                                                id: statusImage

                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left

                                                width: 18 * SettingsState.scale
                                                height: width

                                                sourceSize.width: width
                                                sourceSize.height: height
                                                source: image
                                            }

                                            Text {
                                                id: nameDescription

                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: statusImage.right
                                                anchors.leftMargin: 8 * SettingsState.scale
                                                anchors.right: phoneDescription.left

                                                font.family: "Segoe UI"
                                                font.pixelSize: 12 * SettingsState.scale
                                                font.weight: Font.Medium
                                                color: ColorStorage.iconsAndTextPrimary
                                                text: name
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                id: phoneDescription

                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.right: parent.right

                                                font.family: "Segoe UI"
                                                font.pixelSize: 12 * SettingsState.scale
                                                color: ColorStorage.additionalText

                                                text: phoneType + " " + phoneNumber
                                                elide: Text.ElideRight
                                            }
                                            Component.onCompleted: {
                                                var margin = 30 * SettingsState.scale + 15 * SettingsState.scale;

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

                                    Component {
                                        id: contactPhoneSimpleComponent

                                        Rectangle {
                                            id: description
                                            anchors.fill: parent
                                            anchors.leftMargin: 12 * SettingsState.scale
                                            anchors.rightMargin: 12 * SettingsState.scale

                                            implicitWidth: nameDescription.implicitWidth + phoneDescription.implicitWidth + 10 * SettingsState.scale

                                            color: "transparent"

                                            Text {
                                                id: nameDescription

                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.right: phoneDescription.left

                                                font.family: "Segoe UI"
                                                font.pixelSize: 12 * SettingsState.scale
                                                font.weight: Font.Medium
                                                color: ColorStorage.iconsAndTextPrimary
                                                text: name
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                id: phoneDescription

                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.right: parent.right

                                                font.family: "Segoe UI"
                                                font.pixelSize: 12 * SettingsState.scale
                                                color: ColorStorage.additionalText

                                                text: phoneType + " " + phoneNumber
                                                elide: Text.ElideRight
                                            }

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

                                    Loader {
                                        id: contactPhoneLoader
                                        anchors.fill: parent
                                    }

                                    Component.onCompleted: {
                                        contactPhoneLoader.sourceComponent = visualType ? contactPhoneComplexComponent : contactPhoneSimpleComponent;

                                        // reset element width on visual item type
                                        if (view.lastVisualType != visualType) {
                                            dropdown.viewElementWidth = 0;
                                            view.lastVisualType = visualType;
                                        }
                                    }
                                }
                            }

                            Item {
                                id: transferMethodBlock

                                function index() {
                                    for(var i = 0; i < transferRadioBtnRepeater.count; ++i) {
                                        if(transferRadioBtnRepeater.itemAt(i).checked === true) {
                                            return i;
                                        }
                                    }
                                    return 0;
                                }

                                readonly property int defMargin: 10
                                anchors {
                                    left: parent.left
                                    leftMargin: defMargin * SettingsState.scale
                                    right: parent.right
                                    bottom: parent.bottom
                                }

                                height: visible ? SettingsState.scale * 68 : 0
                                visible: root.showTransferMethodBlock && AppState.sipAccountCallTransferMode == CallTransferMode.Sip
                                focus: !searchInput.focus && !view.focus && !activeCallsView.activeFocus
                                onActiveFocusChanged: {
                                    if (!activeFocus && !searchInput.activeFocus && !activeCallsView.activeFocus && !view.activeFocus) {
                                        dropdown.visible = false;
                                    }
                                }

                                Rectangle {
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        leftMargin: -transferMethodBlock.defMargin * SettingsState.scale
                                        right: parent.right
                                    }
                                    height: 1 * SettingsState.scale
                                    color: ColorStorage.grayNeutral
                                }

                                Column {
                                    id: transferRadioBtnColumn
                                    anchors {
                                        top: parent.top
                                        topMargin: 8 * SettingsState.scale
                                        left: parent.left
                                        leftMargin: -4 * SettingsState.scale
                                        right: parent.right
                                        bottom: parent.bottom
                                        bottomMargin: 12 * SettingsState.scale
                                    }
                                    spacing: 8

                                    Repeater {
                                        id: transferRadioBtnRepeater
                                        model: [qsTrId("settings_sip_account_call_transfer_sip_transfer_method_transfer_now") + Translator.translate,
                                            qsTrId("settings_sip_account_call_transfer_sip_transfer_method_call_first") + Translator.translate]
                                        Component.onCompleted: idxMethodUpdate()

                                        RadioButton {
                                            id: transferRadioBtnItem
                                            text: modelData
                                            height: 20 * SettingsState.scale
                                            width: parent.width
                                            onFocusChanged: transferMethodBlock.forceActiveFocus()

                                            indicator: Rectangle {
                                                readonly property int diameter: 20 * SettingsState.scale

                                                implicitWidth: diameter
                                                implicitHeight: diameter
                                                x: transferRadioBtnItem.leftPadding
                                                y: parent.height / 2 - height / 2
                                                radius: diameter / 2
                                                border.color: ColorStorage.menuBorderColor

                                                Rectangle {
                                                    readonly property int diameter: parent.diameter * 0.5

                                                    width: diameter
                                                    height: diameter
                                                    x: parent.width / 2 - diameter / 2
                                                    y: x
                                                    radius: diameter / 2
                                                    color: transferRadioBtnItem.down ? "#2D5D96" : ColorStorage.additionalText
                                                    visible: transferRadioBtnItem.checked
                                                }
                                            }

                                            contentItem: Text {
                                                text: transferRadioBtnItem.text
                                                font.family: "Segoe UI"
                                                font.pixelSize: 12 * SettingsState.scale
                                                color: ColorStorage.iconsAndTextPrimary
                                                verticalAlignment: Text.AlignVCenter
                                                leftPadding: transferRadioBtnItem.indicator.width + 12 * SettingsState.scale
                                            }
                                        }

                                        function idxMethodUpdate() {
                                            transferRadioBtnRepeater.itemAt(AppState.sipAccountSipTransferMethod).checked = true
                                        }
                                    }

                                    Connections {
                                        target: transferMethodBlock
                                        onVisibleChanged: transferRadioBtnRepeater.idxMethodUpdate()
                                    }
                                }
                            }
                        }

                        DropShadow {
                            anchors.fill: body
                            horizontalOffset: 0
                            verticalOffset: 0
                            radius: 14
                            samples: 28
                            transparentBorder: true
                            color: ColorStorage.menuShadowColor
                            smooth: true
                            source: body
                        }
                    }



                    background: Rectangle {
                        color: "transparent"
                        radius: 8 * SettingsState.scale
                    }
                }
            }
        }
    }

    Loader {
        id: phonesDropdownLoader
        sourceComponent: phonesDropdownComponent
    }
}
