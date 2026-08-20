import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import Flux 1.0

import "../dialogs"
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
        sequence: "Ctrl+F"

        onActivated: {
            searchInput.focus = true;
        }

    }

    function formatDuration(msec) {
        if (msec < 0) {
            msec = 0;
        }

        var durationSeconds = Math.round(msec / 1000);
        var minutes = Math.floor(durationSeconds / (60));

        durationSeconds = durationSeconds - minutes * 60;

        var seconds = durationSeconds;

        if (minutes < 10) {
            minutes = "0" + minutes;
        }

        if (seconds < 10) {
            seconds = "0" + seconds;
        }

        var duration = minutes + ":" + seconds;

        return duration;
    }

    Rectangle {
        anchors.fill: parent
        color: ColorStorage.secondaryWindowBackground

        focus: parent.focus

        Item {
            id: focusReceiver

            focus: true
            KeyNavigation.tab: callHistoryShowCombobox
            KeyNavigation.backtab: listview
        }

        Rectangle {
            id: titleLayer

            anchors.top: parent.top
            anchors.left: parent.left

            focus: parent.focus

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

                text: qsTrId("call_history_window_title") + Translator.translate
            }
        }

        SoftphonePro.ComboButton {
            id: callHistoryShowCombobox

            anchors.top: titleLayer.bottom
            anchors.topMargin: 8 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale

            enabled: true
            showAction: false

            delegateColorDefault: ColorStorage.mainWindowBackground
            delegateColorOnHover: ColorStorage.surfaceSecondary

            hoverWide: 155 * SettingsState.scale
            hoverHeigth: 40 * SettingsState.scale

            selection: AppState.callHistorySelection
            selectionSize: 13 * SettingsState.scale

            model: AppState.callHistorySelectionModel

            Shortcut {
                enabled: callHistoryShowCombobox.enabled
                sequence: "Ctrl+H"

                onActivated: {
                    if (callHistoryShowCombobox.dropdownVisible) {
                        callHistoryShowCombobox.closeDropdown();
                        callHistoryShowCombobox.forceActiveFocus();
                    }
                    else {
                        callHistoryShowCombobox.openDropdown();
                    }
                }
            }

            Shortcut {
                enabled: callHistoryShowCombobox.activeFocus
                sequence: "Shift+Tab"

                onActivated: {
                    listview.forceActiveFocus();
                }
            }

            doWorkOnListItemClick: function(idx) {
                ActionProvider.changeCallHistorySelection(idx);
            }

            doWorkOnActionItemClick: function() {
                ActionProvider.showSettingsWindow(true);
                ActionProvider.createCallForward();
            }

            KeyNavigation.tab: searchInput
        }

        SoftphonePro.SearchInput {
            id: searchInput

            anchors.bottom: callHistoryShowCombobox.bottom
            anchors.left: callHistoryShowCombobox.right
            anchors.leftMargin: 8 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale
            anchors.top: callHistoryShowCombobox.top

            focus: parent.focus

            KeyNavigation.tab: listview
            KeyNavigation.backtab: callHistoryShowCombobox

            property string text: edit.text
            onTextChanged: {
                ActionProvider.filterHistory(edit.text);
            }
        }

        Rectangle {
            anchors.top: callHistoryShowCombobox.bottom
            anchors.topMargin: 8 * SettingsState.scale
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

                    color: ColorStorage.secondaryWindowBackground

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

                        text: {
                            switch(Number(section)) {
                            case CallHistoryModelItem.TodayGroup:
                                return qsTrId("call_history_group_today") + Translator.translate;

                            case CallHistoryModelItem.YesterdayGroup:
                                return qsTrId("call_history_group_yesterday") + Translator.translate;
                            }

                            return qsTrId("call_history_group_earlier") + Translator.translate;
                        }
                    }
                }
            }

            Component {
                id: contextMenuComponent

                Menu {
                    id: contextMenu

                    property string recordName
                    property string callNumber
                    property int callId
                    property string callUuid
                    property string callCrmLink
                    property var direction
                    property string defaultElementColor: ColorStorage.surfaceSecondary
                    property string onHoverElementColor: ColorStorage.secondaryWindowBackground

                    background: Rectangle {
                        implicitWidth: 200 * SettingsState.scale
                        implicitHeight: 40 * SettingsState.scale
                        radius: 8 * SettingsState.scale
                        color: "transparent"

                        MenuShadow {
                            scale: SettingsState.scale
                            anchors.fill: parent
                            bodyColor: ColorStorage.surfaceSecondary
                            shadowColor: ColorStorage.menuShadowColor
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: contextMenu.recordName != "" && SettingsState.showPlayRecordButton
                        topMargin: 1 * SettingsState.scale

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        roundTopCorners: true

                        actionLabel: qsTrId("clipboard_listen_record") + Translator.translate

                        onTriggered: {
                            ActionProvider.startPlayRecord(contextMenu.recordName);
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_copy_phone_number") + Translator.translate

                        onTriggered: {
                            var text = contextMenu.callNumber;

                            if((contextMenu.direction == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                                text = SettingsState.hiddenCallerIDTemplate
                            }

                            SystemClipboard.setText(text);
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_new_contact") + Translator.translate

                        onTriggered: {
                            ActionProvider.tryAddNewContactFromCall(contextMenu.callId);
                        }
                    }
                    
                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: callCrmLink != ""

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_open_crm_info") + Translator.translate

                        onTriggered: {
                            Qt.openUrlExternally(callCrmLink);
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_search") + Translator.translate

                        onTriggered: {
                            searchInput.forceActiveFocus();
                            searchInput.edit.text = contextMenu.callNumber;
                        }
                    }

                    SoftphonePro.MainMenuSeparator {
                        color: ColorStorage.menuBorderColor
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_delete") + Translator.translate

                        onTriggered: {
                            ActionProvider.tryDeleteCallHistory(contextMenu.callId);
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_delete_all") + Translator.translate

                        onTriggered: {
                            ActionProvider.tryDeleteAllDataHistory();
                        }
                    }

                    SoftphonePro.MainMenuSeparator {
                        color: ColorStorage.menuBorderColor
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: !((contextMenu.direction == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls)

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_statistical_info") + Translator.translate

                        onTriggered: {
                            ActionProvider.showCallStatisticDialog(contextMenu.callId);
                        }
                    }

                    SoftphonePro.MainMenuSeparator {
                        color: ColorStorage.menuBorderColor
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        roundBottomCorners: !postprocessingItem.visible

                        actionLabel: qsTrId("clipboard_mark_as_read_all") + Translator.translate

                        onTriggered: {
                            ActionProvider.markAllCallHistoryAsRead();
                        }
                    }

                    SoftphonePro.MainMenuSeparator {
                        color: ColorStorage.menuBorderColor
                        visible: postprocessingItem.visible
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        id: postprocessingItem
                        scale: SettingsState.scale

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        property bool callTagEnabled: !AppFeatures.hidePostProcessing && SettingsState.postProcessingWindowEnabled && AppState.callTagsDropdownVisible

                        roundBottomCorners: true

                        enabled: !AppState.showPostProcessingWindow && !AppState.activeCall && contextMenu.callUuid
                        bottomMargin: 1 * scale
                        visible: callTagEnabled

                        actionLabel: qsTrId("postprocessing_settings") + Translator.translate

                        onTriggered: {
                            ActionProvider.startPostProcessingManually(contextMenu.callId);
                        }

                        onVisibleChanged: {
                            if (!callTagEnabled) {
                                height = 0;
                            }
                        }
                    }

                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            contextMenu.close();
                        }
                    }

                    Component.onCompleted: {
                        contextMenu.open();
                        contextMenu.currentIndex = -1;
                    }
                }
            }

            Component {
                id: rowDelegate

                FocusScope {
                    id: delegateScope

                    width: parent ? parent.width : 0

                    height: {
                        var tmpHeight = callCrmInfo == "" ? 60 * SettingsState.scale : 75 * SettingsState.scale;

                        if ((callState == AppCall.Missed ||
                                callState == AppCall.Redirected) &&
                                    !callIsShow) {
                            return 0;
                        }

                        if (callDirection == AppCall.Incoming) {

                            if ((callState == AppCall.Declined ||
                                    callState == AppCall.Busy) &&
                                        !callIsShow) {
                                return 0;
                            }

                            return tmpHeight;
                        }

                        return tmpHeight;
                    }

                    focus: true
                    property bool isCurrentItem: ListView.isCurrentItem
                    property bool hovered: mouseArea.containsMouse

                    onIsCurrentItemChanged: {
                        if (isCurrentItem && listview.activeFocus && !callHasRead) {
                            ActionProvider.markCallHistoryAsRead(callId);
                        }
                    }

                    Item {
                        ToolTip {
                            visible: delegateScope.visible && delegateScope.hovered && callDirection == SipCall.Conference && implicitWidth > root.width - 95
                            delay: 1000
                            timeout: 5000
                            clip:  true

                            background: Rectangle {
                                color: ColorStorage.iconsAndTextPrimary
                            }

                            contentItem: Text {
                                id: toolTipText
                                width: parent.width

                                font.pixelSize: 14 * SettingsState.scale
                                font.family: "Segoe UI"

                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap

                                color: ColorStorage.mainWindowBackground

                                text: callContactName != "" ? callContactName : callRemoteNumber;
                            }
                        }
                    }

                    Rectangle {
                        id: body
                        radius: 8 * SettingsState.scale
                        visible: delegateScope.height != 0
                        Rectangle{
                            anchors.top: parent.top
                            width: body.width
                            color: parent.color
                            height: 8 * SettingsState.scale
                            visible: index != 0
                        }

                        Rectangle{
                            anchors.bottom: parent.bottom
                            width: body.width
                            color: parent.color
                            height: 8 * SettingsState.scale
                            visible: (index != listview.count - 1 && callRepeatCount < 2) || (index + callRepeatCount != listview.count && callRepeatCount >= 2)
                        }

                        anchors.fill: parent

                        property string colorDefault: ColorStorage.surfaceSecondary
                        property string colorHovered: ColorStorage.mainWindowBackground
                        property alias contextMenuLoader: contextMenuLoader
                        property bool callLabelTruncated: false
                        property bool showAccountName: false

                        color: parent.isCurrentItem &&
                               (listview.activeFocus || (contextMenuLoader.item && contextMenuLoader.item.visible))
                               ? colorHovered : colorDefault

                        MouseArea {
                            id: mouseArea

                            property bool callAreaContainsMouse: false
                            anchors.fill: parent
                            hoverEnabled: true

                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onClicked: {
                                if (mouse.modifiers && Qt.ControlModifier) {
                                    searchInput.forceActiveFocus();
                                    searchInput.edit.text = callRemoteNumber;
                                }
                            }

                            onPressed: {
                                contextMenuLoader.sourceComponent = null;
                                listview.forceActiveFocus();
                                callButton.focus = false;
                                listview.currentIndex = index;
                                listview.selectedCallId = callId;

                                if (!callHasRead) {
                                    ActionProvider.markCallHistoryAsRead(callId);
                                }

                                if (mouseArea.pressedButtons & Qt.RightButton) {
                                    contextMenuLoader.sourceComponent = contextMenuComponent;

                                    contextMenuLoader.item.callNumber = callRemoteNumber;
                                    contextMenuLoader.item.callId = callId;
                                    contextMenuLoader.item.callUuid = callUuid;
                                    contextMenuLoader.item.direction = callDirection
                                    contextMenuLoader.item.callCrmLink = callCrmLink;
                                    // call durations in msec
                                    if (callRecordDuration > 1000) {
                                        contextMenuLoader.item.recordName = callRecordName;
                                    }

                                    contextMenuLoader.item.x = mouseArea.x + mouseX + 1 * SettingsState.scale;
                                    contextMenuLoader.item.y = mouseArea.y + mouseY + 1 * SettingsState.scale;
                                }
                            }
                        }

                        Loader {
                            id: contextMenuLoader
                        }

                        Component {
                            id: historyDescriptionComponent

                            Item {
                                anchors.fill: parent
                                visible: {
                                        if ((callState == AppCall.Missed ||
                                                callState == AppCall.Redirected) &&
                                                    !callIsShow) {
                                            return false;
                                        }

                                        if (callDirection == AppCall.Incoming) {

                                            if ((callState == AppCall.Declined ||
                                                    callState == AppCall.Busy) &&
                                                        !callIsShow) {
                                                return false;
                                            }

                                            return true;
                                        }

                                        return true;
                                }

                                Image {
                                    id: statusImage

                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12 * SettingsState.scale

                                    width: 22 * SettingsState.scale
                                    height: 22 * SettingsState.scale

                                    sourceSize.width: width
                                    sourceSize.height: height

                                    source: {
                                        if (callState == AppCall.Missed ||
                                                callState == AppCall.Redirected) {
                                            return "qrc:/images/phone_missed_red.svg";
                                        }

                                        if (callDirection == AppCall.Incoming) {

                                            if (callState == AppCall.Declined ||
                                                    callState == AppCall.Busy) {
                                                return "qrc:/images/phone_missed_red.svg";
                                            }

                                            return "qrc:/images/phone_incoming_green.svg";
                                        }

                                        if (callDirection == AppCall.Conference) {
                                            return "qrc:/images/conference_green.svg"
                                        }

                                        return "qrc:/images/phone_outgoing_green.svg";
                                    }
                                }

                                Text {
                                    id: datetimeLabel

                                    anchors.top: parent.top
                                    anchors.topMargin: 10 * SettingsState.scale
                                    anchors.left: statusImage.right
                                    anchors.leftMargin: 12 * SettingsState.scale

                                    font.pixelSize: 12 * SettingsState.scale
                                    font.family: "Segoe UI"
                                    font.weight: callHasRead ? Font.Normal : Font.Bold

                                    color: ColorStorage.additionalText

                                    elide: Text.ElideRight

                                    text: callDatetime
                                }

                                Image {
                                    id: callRecordIcon

                                    anchors.left: datetimeLabel.right
                                    anchors.leftMargin: 10 * SettingsState.scale
                                    anchors.verticalCenter: datetimeLabel.verticalCenter

                                    width: 14 * SettingsState.scale
                                    height: 14 * SettingsState.scale

                                    visible: false

                                    sourceSize.width: width
                                    sourceSize.height: height

                                    source: "qrc:/images/record_grey.svg"
                                }

                                IconShader {
                                    id: callRecordIconShader

                                    property string shaderColor: ColorStorage.additionalText

                                    anchors.centerIn: callRecordIcon
                                    visible: callRecordDuration > 1000 && SettingsState.showPlayRecordButton
                                    imageSrcComponent: callRecordIcon
                                    imgColor: shaderColor
                                    imageWidth: callRecordIcon.width
                                    imageHeight: callRecordIcon.height
                                }

                                MouseArea {
                                    anchors.fill: callRecordIconShader

                                    enabled: callRecordIconShader.visible
                                    hoverEnabled: enabled

                                    onEntered: {
                                        callRecordIconShader.shaderColor = ColorStorage.greenOnPress;
                                        callRecordIcon.source = "qrc:/images/play_green.svg";
                                    }

                                    onExited: {
                                        callRecordIconShader.shaderColor = ColorStorage.additionalText;
                                        callRecordIcon.source = "qrc:/images/record_grey.svg";
                                    }

                                    onReleased: {
                                        if (containsMouse) {
                                            ActionProvider.startPlayRecord(callRecordName);
                                        }
                                    }
                                }


                                Text {
                                    id: callRecordDurationLabel

                                    anchors.left: callRecordIconShader.right
                                    anchors.leftMargin: 2 * SettingsState.scale
                                    anchors.verticalCenter: callRecordIconShader.verticalCenter

                                    visible: callRecordIconShader.visible

                                    font.pixelSize: 12 * SettingsState.scale
                                    font.family: "Segoe UI"
                                    font.weight: callHasRead ? Font.Normal : Font.Bold

                                    color: ColorStorage.additionalText

                                    elide: Text.ElideRight

                                    text: root.formatDuration(callRecordDuration)
                                }

                                Text {
                                    id: callDurationLabel

                                    anchors.left: datetimeLabel.right
                                    anchors.leftMargin: 10 * SettingsState.scale
                                    anchors.verticalCenter: datetimeLabel.verticalCenter

                                    visible: !callRecordIconShader.visible

                                    font.pixelSize: 12 * SettingsState.scale
                                    font.family: "Segoe UI"
                                    font.weight: callHasRead ? Font.Normal : Font.Bold

                                    color: ColorStorage.additionalText

                                    elide: Text.ElideRight

                                    text: root.formatDuration(callDuration)
                                }

                                Image {
                                    id: accountIcon

                                    anchors.left: callRecordIconShader.visible ? callRecordDurationLabel.right : callDurationLabel.right
                                    anchors.leftMargin: 8 * SettingsState.scale
                                    anchors.verticalCenter: datetimeLabel.verticalCenter

                                    width: 12 * SettingsState.scale
                                    height: 12 * SettingsState.scale

                                    visible: false

                                    sourceSize.width: width
                                    sourceSize.height: height

                                    source: "qrc:/images/account_grey.svg"      
                                }

                                IconShader {
                                    anchors.centerIn: accountIcon
                                    visible: accountNameLabel.visible
                                    imageSrcComponent: accountIcon
                                    imgColor: ColorStorage.additionalText
                                    imageWidth: accountIcon.width
                                    imageHeight: accountIcon.height
                                }

                                Text {
                                    id: accountNameLabel

                                    anchors.verticalCenter:  datetimeLabel.verticalCenter
                                    anchors.left: accountIcon.right
                                    anchors.leftMargin: 0 * SettingsState.scale

                                    width: {
                                        if (callDatetime.length > 6) {
                                            return callRecordDurationLabel.visible ? 70 * SettingsState.scale : 120 * SettingsState.scale;
                                        } else {
                                            return callRecordDurationLabel.visible ? 130 * SettingsState.scale : 190 * SettingsState.scale;
                                        }

                                    }
                                    visible: callAccountName != "" && callDirection != AppCall.Conference

                                    font.pixelSize: 12 * SettingsState.scale
                                    font.family: "Segoe UI"

                                    color: ColorStorage.additionalText

                                    elide: Text.ElideRight

                                    text: callAccountName + " " + callDidName

                                    MouseArea {
                                        anchors.fill:parent
                                        hoverEnabled: true
                                        clip: true

                                        ToolTip {
                                            visible: parent.containsMouse && accNameContent.text && accountNameLabel.implicitWidth > accountNameLabel.width
                                            delay: 1000
                                            timeout: 5000
                                            background: Rectangle {
                                                id: accNameBackground
                                                color: ColorStorage.iconsAndTextPrimary
                                            }
                                            contentItem: Text {
                                                id: accNameContent
                                                text: accountNameLabel.text ? accountNameLabel.text : ""
                                                color: ColorStorage.mainWindowBackground
                                                wrapMode: Text.WordWrap
                                            }

                                            property int margin: (364 * SettingsState.scale - accNameBackground.width) * 0.5
                                            property int minMargin: 6 * SettingsState.scale

                                            leftMargin: margin < minMargin ? minMargin : margin
                                            rightMargin: leftMargin
                                        }
                                    }
                                }

                                Text {
                                    id: callLabel

                                    anchors.top: datetimeLabel.bottom
                                    anchors.topMargin: 3 * SettingsState.scale
                                    anchors.left: datetimeLabel.left
                                    anchors.right: parent.right

                                    font.pixelSize: 14 * SettingsState.scale
                                    font.family: "Segoe UI"
                                    font.weight: callHasRead ? Font.Normal : Font.DemiBold

                                    color: ColorStorage.iconsAndTextPrimary

                                    elide: Text.ElideRight

                                    onTruncatedChanged: {
                                        body.callLabelTruncated = callLabel.truncated
                                    }

                                    function getName() {
                                        if (callContactName != "") {
                                            body.showAccountName = true
                                            return callContactName;
                                        }
                                        else if (callRemoteDisplayName.length > 0 && SettingsState.showSipNameInCallHistory) {
                                            return callRemoteNumber + " " +  callRemoteDisplayName;
                                        }
                                        else
                                            return callRemoteNumber;
                                    }

                                    text: {
                                        if(callDirection == AppCall.Incoming && SettingsState.hideCallerIDForInboundCalls)
                                            return SettingsState.hiddenCallerIDTemplate;

                                        var name = getName();
                                        if (callState == AppCall.Missed ||
                                                callState == AppCall.Redirected) {

                                            if (callRepeatCount < 2) {
                                                return name;
                                            }
                                            else {
                                                return name + " (" + callRepeatCount + ")";
                                            }
                                        }

                                        if (callDirection == AppCall.Incoming) {

                                            if (callState == AppCall.Declined ||
                                                    callState == AppCall.Busy) {

                                                if (callRepeatCount < 2) {
                                                    return name;
                                                }
                                                else {
                                                    return name + " (" + callRepeatCount + ")";
                                                }
                                            }

                                            return name;
                                        }

                                        return name;
                                    }

                                    MouseArea {
                                        id: callLabelMouseArea

                                        hoverEnabled: true

                                        anchors.fill: parent

                                        acceptedButtons: Qt.NoButton

                                        onPressed: mouseArea.pressed()

                                        ToolTip {
                                            visible: callLabelMouseArea.containsMouse && content.text && callLabel.implicitWidth > callLabel.width

                                            delay: 1000
                                            timeout: 5000
                                            clip: true
                                            background: Rectangle {
                                                id: background
                                                color: ColorStorage.iconsAndTextPrimary
                                            }
                                            contentItem: Text {
                                                id: content
                                                text: callLabel.text ? callLabel.text : ""
                                                color: ColorStorage.mainWindowBackground
                                                wrapMode: Text.WordWrap
                                            }

                                            property int margin: (364 * SettingsState.scale - background.width) * 0.5
                                            property int minMargin: 6 * SettingsState.scale

                                            leftMargin: margin < minMargin ? minMargin : margin
                                            rightMargin: leftMargin
                                        }
                                        onContainsMouseChanged: mouseArea.callAreaContainsMouse = containsMouse
                                    }
                                }

                                Text {
                                    id: callCrmLabel
                                    anchors.top: callLabel.bottom
                                    anchors.topMargin: 3 * SettingsState.scale
                                    anchors.left: datetimeLabel.left
                                    anchors.right: parent.right

                                    visible: text.length != 0

                                    font.pixelSize: 12 * SettingsState.scale
                                    font.family: "Segoe UI"
                                    font.weight: callHasRead ? Font.Normal : Font.Bold

                                    color: ColorStorage.additionalText
                                    elide: Text.ElideRight

                                    text: callCrmInfo

                                    MouseArea {
                                        id: callCrmLabelMouseArea

                                        hoverEnabled: true

                                        anchors.fill: parent

                                        acceptedButtons: Qt.NoButton

                                        onPressed: mouseArea.pressed()

                                        ToolTip {
                                            visible: callCrmLabelMouseArea.containsMouse && crmContent.text && callCrmLabel.implicitWidth > callCrmLabel.width

                                            delay: 1000
                                            timeout: 5000
                                            clip: true
                                            background: Rectangle {
                                                id: crmBackground
                                                color: ColorStorage.iconsAndTextPrimary
                                            }
                                            contentItem: Text {
                                                id: crmContent
                                                text: callCrmLabel.text ? callCrmLabel.text : ""
                                                color: ColorStorage.mainWindowBackground
                                                wrapMode: Text.WordWrap
                                            }

                                            property int margin: (364 * SettingsState.scale - crmBackground.width) * 0.5
                                            property int minMargin: 6 * SettingsState.scale

                                            leftMargin: margin < minMargin ? minMargin : margin
                                            rightMargin: leftMargin
                                        }
                                        onContainsMouseChanged: mouseArea.callAreaContainsMouse = containsMouse
                                    }
                                }
                            }
                        }

                        Loader {
                            id: historyDescriptionLoader

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.right: callButton.left
                            anchors.rightMargin: 10 * SettingsState.scale
                        }

                        SoftphonePro.SquareButton {
                            id: callButton

                            anchors.right: parent.right
                            anchors.rightMargin: 15 * SettingsState.scale
                            anchors.verticalCenter: parent.verticalCenter

                            scale: SettingsState.scale

                            radius: 8 * SettingsState.scale

                            focus: true

                            width: 32 * SettingsState.scale
                            height: 32 * SettingsState.scale

                            imageWidth: 16 * SettingsState.scale
                            imageHeight: 16 * SettingsState.scale

                            colorDefault: ColorStorage.sSizeButtonDefault
                            colorOnHover: ColorStorage.sSizeButtonOnHover
                            colorOnPress: ColorStorage.sSizeButtonOnPress
                            colorOnDisabled: ColorStorage.sSizeButtonDisabled

                            borderWidthDefault: 1 * SettingsState.scale

                            borderColorDefault: ColorStorage.sSizeButtonBorderDefault

                            imageColorDefault: ColorStorage.sSizeButtonImageDefault
                            imageColorOnHover: ColorStorage.sSizeButtonImageOnHover
                            imageColorOnPress: ColorStorage.sSizeButtonImageOnPress
                            imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                            imageDefault: "qrc:/images/call_default.svg"

                            visible: (mouseArea.containsMouse || callButton.hovered || mouseArea.callAreaContainsMouse) && callDirection != SipCall.Conference

                            property var timeNow: AppState.timeNow
                            property int secondsDisabledMax: 2
                            property int secondsDisabledLeft: 0
                            property bool disableWorkFunction: false

                            doWorkOnButtonClick: function() {
                                forceActiveFocus();
                                if (!callHasRead) {
                                    ActionProvider.markCallHistoryAsRead(callId);
                                }

                                var number = callRemoteNumber;

                                if(callDirection == AppCall.Incoming && SettingsState.hideCallerIDForInboundCalls) {
                                    number = SettingsState.hiddenCallerIDTemplate;
                                }

                                if (!disableWorkFunction) {
                                    ActionProvider.sendDialedString(number);
                                    if (callAccountId >= 0) {
                                        ActionProvider.makeCallViaAccount(number, callAccountId, false, false, {}, callDidId);
                                    }
                                    else {
                                        ActionProvider.makeCall(number, false);
                                    }

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

                            Keys.onMenuPressed: {
                                contextMenuLoader.sourceComponent = null;
                                listview.selectedCallId = callId;

                                contextMenuLoader.sourceComponent = contextMenuComponent;
                                contextMenuLoader.item.x = mouseArea.x + mouseArea.width / 3;
                                contextMenuLoader.item.y = mouseArea.y + mouseArea.height / 3;
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right

                            visible: true

                            height: 1 * SettingsState.scale
                            color: ColorStorage.secondaryWindowBackground
                        }

                        Component.onCompleted: {
                            historyDescriptionLoader.sourceComponent = historyDescriptionComponent;
                        }
                    }
                }
            }

            Rectangle {
                id: listviewRectangle
                anchors.fill: parent

                color: ColorStorage.secondaryWindowBackground

                Text {

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -15

                    font.pixelSize: 13 * SettingsState.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.iconsAndTextPrimary
                    visible: listview.count == 0

                    text: qsTrId("callhistory_window_no_history") + Translator.translate
                }

                ListView {
                    id: listview

                    anchors.fill: parent
                    model: AppState.callHistoryModel

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

                    highlightFollowsCurrentItem: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: rowDelegate               

                    section.property: "callGroup"
                    section.delegate: sectionDelegate

                    property int selectedCallId: 0

                    ScrollBar.vertical: ScrollBar {
                        id: scrollBar
                        visible: true
                        stepSize: listview.count ? 1.0 / listview.count : 0.1
                    }

                    Keys.onUpPressed: {
                        listview.decrementCurrentIndex();
                        scrollBar.decrease();
                    }

                    Keys.onDownPressed: {
                        listview.incrementCurrentIndex();
                        scrollBar.increase();
                    }

                    FocusSender {
                        property int preferredHeight: listview.height - listview.contentHeight
                        receiver: focusReceiver
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: preferredHeight > 0 ? preferredHeight : 0
                    }

                    Shortcut {
                        sequence: "PgUp"

                        onActivated: {
                            for (var i=0; i<5; i++) {
                                listview.decrementCurrentIndex();
                                scrollBar.decrease();
                            }
                        }
                    }

                    Shortcut {
                        sequence: "PgDown"

                        onActivated: {
                            for (var i=0; i<5; i++) {
                                listview.incrementCurrentIndex();
                                scrollBar.increase();
                            }
                        }
                    }

                    KeyNavigation.tab: callHistoryShowCombobox
                    KeyNavigation.backtab: searchInput
                }
            }
        }
    }

    InfoDialog {
        id: infoDialog

        width: SettingsState.callStatistic ? 400 : 300
        height: SettingsState.callStatistic ? 670 : 100
        minimumHeight: 100
        minimumWidth: 300
        maximumHeight: 670
        maximumWidth: 400

        messageLabel.selectByMouse: true
        messageLabel.anchors.topMargin: 15
        messageLabel.font.pixelSize: 11

        visible: SettingsState.showCallStatisticDialog
        message: SettingsState.callStatistic ? SettingsState.callStatistic : qsTrId("callhistory_no_call_statistic") + Translator.translate

        onOKAction: function() {
            ActionProvider.closeCallStatisticDialog();
        }
    }
}
