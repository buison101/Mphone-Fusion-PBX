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

    property alias messageTextInputField: messageTextInput
    property alias numberTextInputField: numberTextInput

    function sendMessage() {
        ActionProvider.makeMessage(numberTextInput.text, messageTextInput.text);
        numberTextInput.text = "";
        messageTextInput.text = "";
    }

    Connections{
        target: AppState
        onMessagingWindowFocusChanged: {
            messageTextInput.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ColorStorage.secondaryWindowBackground

        Item {
            id: focusReceiver

            focus: true

            KeyNavigation.tab: numberTextInput
            KeyNavigation.backtab: messageTextInput
        }

        FocusSender {
            anchors.fill: parent
            receiver: focusReceiver
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

                text: qsTrId("main_menu_messaging_window") + Translator.translate

                color: ColorStorage.secondaryWindowTitleAndIcons
            }
        }

        Rectangle {
            anchors {
                fill: parent
                topMargin: 43 * SettingsState.scale
                leftMargin: 12 * SettingsState.scale
                rightMargin: 12 * SettingsState.scale
            }

            Component {
                id: contextMenuComponent

                Menu {
                    id: contextMenu

                    property int messageId
                    property string message
                    property string remoteNumber
                    property int accountId
                    property string currentMessageUuid

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
                        id: resendMenuButton
                        scale: SettingsState.scale
                        clip: true
                        visible: listview.messageDirection != StandartMessage.Incoming
                        enabled: !listview.sentStatus
                        topMargin: 1 * SettingsState.scale

                        height: visible ? elementHeight : 0

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        roundTopCorners: true

                        actionLabel: qsTrId("resend") + Translator.translate

                        onTriggered: {
                            ActionProvider.makeMessageViaAccount(contextMenu.remoteNumber, contextMenu.message, contextMenu.accountId, true, contextMenu.currentMessageUuid);
                        }
                    }

                    SoftphonePro.MainMenuSeparator {
                        color: ColorStorage.menuBorderColor
                        height: resendMenuButton.visible ? 1 * SettingsState.scale : 0
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale
                        clip: true
                        visible: listview.messageDirection == StandartMessage.Incoming
                        topMargin: 1 * SettingsState.scale

                        height: visible ? elementHeight : 0

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        roundTopCorners: true

                        actionLabel: qsTrId("answer_button_tooltip") + Translator.translate

                        onTriggered: {
                            ActionProvider.sendMessageNumberFromUi(contextMenu.remoteNumber);
                            messageTextInput.forceActiveFocus();
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        visible: listview.messageDirection == StandartMessage.Outgoing

                        height: visible ? elementHeight : 0

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("write_again") + Translator.translate

                        onTriggered: {
                            ActionProvider.sendMessageNumberFromUi(contextMenu.remoteNumber);
                            messageTextInput.forceActiveFocus();
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_copy_phone_number") + Translator.translate

                        onTriggered: {
                            SystemClipboard.setText(contextMenu.remoteNumber);
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_copy_text_message") + Translator.translate

                        onTriggered: {
                            SystemClipboard.setText(contextMenu.message);
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
                            ActionProvider.tryDeleteMessageHistory(contextMenu.messageId);
                        }
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_delete_all") + Translator.translate

                        onTriggered: {
                            ActionProvider.tryDeleteAllDataMessageHistory();
                        }
                    }

                    SoftphonePro.MainMenuSeparator {
                        color: ColorStorage.menuBorderColor
                    }

                    SoftphonePro.PhoneInputMenuItem {
                        scale: SettingsState.scale

                        enabled: true

                        roundBottomCorners: true
                        bottomMargin: 1 * scale

                        colorDefault: contextMenu.defaultElementColor
                        colorOnHover: contextMenu.onHoverElementColor

                        actionLabel: qsTrId("clipboard_mark_as_read_all") + Translator.translate

                        onTriggered: {
                            ActionProvider.markAllMessageHistoryAsRead();
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

                Rectangle {
                    id: body

                    width: listview.width
                    height: messageText.height + 55 * SettingsState.scale
                    clip: true

                    radius: 8 * SettingsState.scale

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
                        visible: index != listview.count - 1
                    }

                    property color colorDefault: ColorStorage.surfaceSecondary
                    property color colorHovered: ColorStorage.mainWindowBackground
                    property alias contextMenuLoader: contextMenuLoader
                    color: ListView.isCurrentItem && (listview.activeFocus || (contextMenuLoader.item && contextMenuLoader.item.visible))
                           ? colorHovered : colorDefault
                    onColorChanged: { messageText.color = (body.color == colorDefault) ? ColorStorage.iconsAndTextSecondary : ColorStorage.iconsAndTextPrimary }

                    MouseArea {
                        id: mouseArea

                        anchors.fill: parent
                        hoverEnabled: true

                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onPressed: {
                            contextMenuLoader.sourceComponent = null;
                            listview.forceActiveFocus();
                            listview.currentIndex = index;
                            listview.selectedMessageId = messageId;
                            listview.currentAccountId = messageAccountId;
                            listview.currentMessageBody = messageBody;
                            listview.currentMessageUuid = messageUuid;
                            listview.currentRemoteNumber = messageRemoteNumber;
                            listview.sentStatus = messageState == StandartMessage.SuccessfulSend;
                            listview.messageDirection = messageDirection;

                            if (mouseArea.pressedButtons & Qt.RightButton) {
                                contextMenuLoader.sourceComponent = contextMenuComponent;
                                contextMenuLoader.item.x = mouseArea.x + mouseX;
                                contextMenuLoader.item.y = mouseArea.y + mouseY;
                                contextMenuLoader.item.messageId = messageId;
                                contextMenuLoader.item.message = messageBody;
                                contextMenuLoader.item.currentMessageUuid = messageUuid;
                                contextMenuLoader.item.accountId = messageAccountId;
                                contextMenuLoader.item.remoteNumber = messageRemoteNumber;
                            }

                            if (!messageHasRead) {
                                ActionProvider.markMessageHistoryAsRead(messageId);
                            }
                        }
                    }

                    Loader {
                        id: contextMenuLoader
                    }

                    Item {
                        Image {
                            id: messageArrowImage

                            anchors.left: parent.left
                            anchors.leftMargin: 16 * SettingsState.scale
                            anchors.top: parent.top
                            anchors.topMargin: 12 * SettingsState.scale



                            source: {
                                if (messageDirection == StandartMessage.Incoming) {
                                    if (messageHasRead) {
                                        return "qrc:/images/message-arrow-left-outline-white.svg";
                                    } else {
                                        return "qrc:/images/message-arrow-left-white.svg";
                                    }
                                } else {
                                    return "qrc:/images/message-arrow-right-outline-white.svg";
                                }
                            }

                            visible: true

                            sourceSize.width: width
                            sourceSize.height: height

                            width: 16 * SettingsState.scale
                            height: 16 * SettingsState.scale
                        }

                        IconShader {
                            anchors.horizontalCenter: messageArrowImage.horizontalCenter
                            anchors.verticalCenter: messageArrowImage.verticalCenter

                            imageSrcComponent: messageArrowImage
                            imgColor: ColorStorage.iconsAndTextSecondary
                            imageWidth: messageArrowImage.width
                            imageHeight: messageArrowImage.height
                        }
                    }

                    Item {
                        anchors.fill: parent
                        clip: true

                        Text {
                            id: phoneNumberText

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: 12 * SettingsState.scale
                            anchors.leftMargin: 44 * SettingsState.scale

                            text: messageRemoteNumber
                            font.pixelSize: 10 * SettingsState.scale
                            font.family: "Segoe UI"
                            font.weight: messageHasRead ? Font.Normal : Font.Bold
                            color: ColorStorage.iconsAndTextPrimary
                        }

                        Rectangle {
                            id: nameTextRectangle
                            anchors.top: phoneNumberText.bottom
                            anchors.left: phoneNumberText.left
                            width: parent.width * 0.5
                            height: 16 * SettingsState.scale

                            color: "transparent"

                            Text {
                                id: nameText

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right

                                elide: Text.ElideRight

                                text: messageContactName
                                font.family: "Segoe UI"
                                font.pixelSize: 12 * SettingsState.scale
                                font.weight: Font.Medium
                                color: ColorStorage.iconsAndTextPrimary

                                MouseArea {
                                    id: nameTextMouseArea

                                    hoverEnabled: true

                                    anchors.fill: parent

                                    acceptedButtons: Qt.NoButton

                                    onPressed: mouseArea.pressed()

                                    ToolTip {
                                        visible: nameTextMouseArea.containsMouse && content.text && nameText.implicitWidth > nameText.width

                                        delay: 1000
                                        timeout: 5000

                                        contentItem: Text {
                                            id: content
                                            text: nameText.text ? nameText.text : ""
                                            color: ColorStorage.mainWindowBackground
                                            wrapMode: Text.WordWrap
                                        }

                                        background: Rectangle {
                                            color: ColorStorage.iconsAndTextPrimary
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: accountTextRectangle
                            anchors.top: nameTextRectangle.top
                            anchors.right: dateTextRect.right

                            width: parent.width * 0.25
                            height: 16 * SettingsState.scale

                            color: "transparent"

                            Text {
                                id: accountText

                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.left: parent.left

                                visible: true

                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight

                                text:  messageAccountName
                                color: ColorStorage.additionalText
                                font.family: "Segoe UI"
                                font.pixelSize: 10 * SettingsState.scale
                                font.weight: messageHasRead ? Font.Normal : Font.Bold

                                MouseArea {
                                    id: accountTextMouseArea

                                    hoverEnabled: true

                                    anchors.fill: parent

                                    acceptedButtons: Qt.NoButton

                                    onPressed: mouseArea.pressed()

                                    ToolTip {
                                        visible: accountTextMouseArea.containsMouse && contentItem.text && accountText.implicitWidth > accountText.width

                                        delay: 1000
                                        timeout: 5000

                                        contentItem: Text {
                                            text: accountText.text ? accountText.text : ""
                                            color: ColorStorage.mainWindowBackground
                                            wrapMode: Text.WordWrap
                                        }

                                        background: Rectangle {
                                            color: ColorStorage.iconsAndTextPrimary
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: dateTextRect
                            clip: true
                            color:  "transparent"

                            anchors.right: parent.right
                            anchors.rightMargin: 30 * SettingsState.scale
                            anchors.verticalCenter: phoneNumberText.verticalCenter
                            width:  dateText.contentWidth
                            height: dateText.contentHeight

                            Text {
                                id: dateText

                                text: messageDatetime
                                color: ColorStorage.additionalText
                                font.family: "Segoe UI"
                                font.pixelSize: 10 * SettingsState.scale
                                font.weight: messageHasRead ? Font.Normal : Font.Bold
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Image {
                            id: statusImage

                            source: {
                                if (messageState == StandartMessage.SuccessfulSend) {
                                    return "qrc:/images/message_send_ok.svg";
                                }
                                return "qrc:/images/message_send_error.svg";
                            }

                            visible: messageDirection != StandartMessage.Incoming

                            sourceSize.width: width * Screen.devicePixelRatio
                            sourceSize.height: height * Screen.devicePixelRatio

                            width: {
                                if(SettingsState.scale == 1.2) {
                                    return 14
                                }
                                return 11 * SettingsState.scale
                            }

                            height: {
                                if(SettingsState.scale == 1.2) {
                                    return 14
                                }
                                return 11 * SettingsState.scale
                            }

                            anchors.left: dateTextRect.right
                            anchors.leftMargin: 6
                            anchors.top: dateTextRect.top
                            anchors.topMargin: {
                                if(SettingsState.scale <= 1.2) {
                                    return 0
                                }

                                if(SettingsState.scale < 1.4) {
                                    return 1
                                }

                                if(SettingsState.scale >= 1.8){
                                    return 3
                                }
                                return 2
                            }
                        }

                        Text {
                            id: messageText
                            text: messageBody

                            anchors.left: phoneNumberText.left
                            anchors.right: dateTextRect.right
                            anchors.top: (nameText.text !== "" || accountText.text !== "") ? nameTextRectangle.bottom : phoneNumberText.bottom
                            anchors.topMargin: 4 * SettingsState.scale

                            wrapMode:TextEdit.Wrap
                            font.family: "Segoe UI"
                            font.pixelSize: 12 * SettingsState.scale
                            font.weight: messageHasRead ? Font.Normal : Font.Bold
                        }
                    }

                    Loader {
                        id: contactDescriptionLoader

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.right: parent.left
                        anchors.rightMargin: 15 * SettingsState.scale
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        visible: index != listview.count - 1
                        height: 1 * SettingsState.scale
                        color: ColorStorage.secondaryWindowBackground
                    }
                }
            }

            Rectangle {
                id: listviewRectangle
                anchors.fill: parent
                color: ColorStorage.secondaryWindowBackground
                clip: true

                FocusSender {
                    anchors.fill: parent
                    receiver: focusReceiver
                }

                ListView {
                    id: listview
                    anchors.right: parent.right
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 4 * SettingsState.scale

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

                    clip: true

                    height: 430 * SettingsState.scale - underRectangle.messageOffset

                    model: AppState.messageHistoryModel

                    highlightFollowsCurrentItem: false
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: rowDelegate

                    property int selectedMessageId: 0
                    property string currentMessageBody: ""
                    property int currentAccountId: -1
                    property string currentRemoteNumber: ""
                    property string currentMessageUuid: ""
                    property bool sentStatus: false
                    property int messageDirection: -1

                    ScrollBar.vertical: ScrollBar {
                        id: scrollBar
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

                    FocusSender {
                        property int preferredHeight: listview.height - listview.contentHeight
                        receiver: focusReceiver
                        width: listview.width
                        height: preferredHeight > 0 ? preferredHeight : 0
                        anchors.bottom: parent.bottom
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
                }

                Rectangle {
                    id: underRectangle
                    color: ColorStorage.secondaryWindowBackground

                    anchors.right: parent.right
                    anchors.left: parent.left
                    anchors.leftMargin: 4 * SettingsState.scale
                    anchors.rightMargin: 4 * SettingsState.scale
                    anchors.top: listview.bottom
                    anchors.topMargin: 16 * SettingsState.scale
                    anchors.bottom: parent.bottom

                    property int messageOffset: {
                        if(messageTextInput.text.length > 90)
                            return 48 * SettingsState.scale
                        if(messageTextInput.text.length > 60)
                            return 35 * SettingsState.scale
                        if(messageTextInput.text.length > 30)
                            return 22 * SettingsState.scale
                        return 10 * SettingsState.scale
                    }

                    Rectangle {
                        id: messagingSendingRectangle

                        anchors.right: parent.right
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 1 * SettingsState.scale

                        color: ColorStorage.secondaryWindowBackground

                        Rectangle {
                            id: inputsContainer

                            anchors.fill: parent

                            color: ColorStorage.secondaryWindowBackground

                            FocusSender {
                                anchors.fill: parent
                                receiver: focusReceiver
                            }

                            Rectangle {
                                id: numberInputRectangle

                                anchors.right: parent.right
                                anchors.left: parent.left
                                anchors.top: parent.top

                                height: 40 * SettingsState.scale
                                radius: 8 * SettingsState.scale
                                color: ColorStorage.mainWindowBackground
                                border.color: "transparent"
                                border.width: 1 * SettingsState.scale

                                Component {
                                    id: numberInputContextMenuComponent

                                    // Menu element should be placed into Component
                                    // to crete every time new Menu element
                                    Menu {
                                        id: numberInputContextMenu
                                        background: Rectangle {
                                            implicitWidth: 200 * SettingsState.scale
                                            implicitHeight: 40 * SettingsState.scale
                                            radius: 8 * SettingsState.scale

                                            MenuShadow {
                                                scale: SettingsState.scale
                                                anchors.fill: parent
                                                bodyColor: ColorStorage.surfaceSecondary
                                                shadowColor: ColorStorage.menuShadowColor
                                            }
                                        }

                                        SoftphonePro.PhoneInputMenuItem {
                                            enabled: numberTextInput.hasTextSelected()
                                            topMargin: 1 * SettingsState.scale

                                            actionLabel: qsTrId("clipboard_cut") + Translator.translate
                                            shortcutLabel: "Ctrl+X"

                                            roundTopCorners: true

                                            onTriggered: {
                                                numberTextInput.cut();
                                                numberTextInput.forceActiveFocus();
                                            }
                                        }

                                        SoftphonePro.PhoneInputMenuItem {
                                            enabled: numberTextInput.hasTextSelected()

                                            actionLabel: qsTrId("clipboard_copy") + Translator.translate
                                            shortcutLabel: "Ctrl+C"

                                            onTriggered: {
                                                numberTextInput.copy();
                                                numberTextInput.forceActiveFocus();
                                            }
                                        }

                                        SoftphonePro.PhoneInputMenuItem {
                                            enabled: {
                                                var text = SystemClipboard.getText();

                                                if (text) {
                                                    return true;
                                                }

                                                return false;
                                            }

                                            roundBottomCorners: true

                                            bottomMargin: 1 * SettingsState.scale

                                            actionLabel: qsTrId("clipboard_paste") + Translator.translate
                                            shortcutLabel: "Ctrl+V"

                                            onTriggered: {
                                                numberTextInput.paste();
                                                numberTextInput.forceActiveFocus();
                                            }
                                        }

                                        onActiveFocusChanged: {
                                            if (!activeFocus) {
                                                numberInputContextMenu.close();
                                            }
                                        }

                                        Component.onCompleted: {
                                            numberInputContextMenu.open();
                                        }
                                    }
                                }

                                Loader {
                                    id: numberInputLoader
                                }

                                Rectangle {
                                    id: numberInputArea

                                    anchors {
                                        fill: parent
                                        topMargin: 12 * SettingsState.scale
                                        bottomMargin: 12 * SettingsState.scale
                                        leftMargin: 1 * SettingsState.scale
                                        rightMargin: 1 * SettingsState.scale
                                    }

                                    border.color: "transparent"
                                    border.width: 1 * SettingsState.scale

                                    color: ColorStorage.mainWindowBackground

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12 * SettingsState.scale

                                        text: qsTrId("message_number_placeholder") + Translator.translate
                                        color: ColorStorage.additionalText
                                        font.family: "Segoe UI"
                                        visible: !numberTextInput.text
                                        font.pixelSize: 12 * SettingsState.scale
                                    }

                                    MouseArea {
                                        id: numberInputMouseArea
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton
                                        hoverEnabled: true

                                        cursorShape: Qt.IBeamCursor

                                        onPressed: {
                                            // destroy old Menu element if it exists
                                            numberInputLoader.sourceComponent = null;
                                        }

                                        onReleased: {
                                            // need to save selected text because it would
                                            // lost after mouse click
                                            numberTextInput.lastSelectionBegin = numberTextInput.selectionStart
                                            numberTextInput.lastSelectionEnd = numberTextInput.selectionEnd

                                            numberInputLoader.sourceComponent = numberInputContextMenuComponent;

                                            // restore selection
                                            numberTextInput.select(numberTextInput.lastSelectionBegin, numberTextInput.lastSelectionEnd);
                                        }
                                    }

                                    TextInput {
                                        id: numberTextInput

                                        anchors.fill: parent
                                        anchors.leftMargin: 12 * SettingsState.scale

                                        font.family: "Segoe UI"
                                        font.pixelSize: 12 * SettingsState.scale
                                        color: ColorStorage.iconsAndTextPrimary
                                        maximumLength: 30
                                        selectByMouse: true
                                        selectionColor: ColorStorage.selectionInputColor
                                        selectedTextColor: ColorStorage.iconsAndTextPrimary

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: false
                                            cursorShape: Qt.IBeamCursor
                                        }

                                        property int lastSelectionBegin: 0
                                        property int lastSelectionEnd: 0

                                        function hasTextSelected() {
                                            return lastSelectionEnd > lastSelectionBegin;
                                        }

                                        onActiveFocusChanged: {
                                            if (activeFocus) {
                                                numberInputRectangle.border.color = ColorStorage.grayNeutralOnPress;
                                                return;
                                            }

                                            numberInputRectangle.border.color = "transparent";
                                        }

                                        property string messageNumberFromUi: AppState.messageNumberFromUi

                                        text: messageNumberFromUi

                                        KeyNavigation.tab: messageTextInput

                                        onMessageNumberFromUiChanged: {
                                            text = messageNumberFromUi;
                                        }

                                        Keys.onReturnPressed: {
                                            if (numberTextInput.text != "" && messageTextInput.text != "") {
                                                sendMessage();
                                            }
                                        }

                                        Keys.onEnterPressed: {
                                            if (numberTextInput.text != "" && messageTextInput.text != "") {
                                                sendMessage();
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: messageInputRectangle

                                clip: true
                                anchors.right: parent.right
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                anchors.top: numberInputRectangle.bottom
                                anchors.bottomMargin: 16 * SettingsState.scale
                                anchors.topMargin: 8 * SettingsState.scale

                                radius: 8 * SettingsState.scale
                                color: ColorStorage.mainWindowBackground
                                border.color: "transparent"
                                border.width: 1 * SettingsState.scale

                                Component {
                                    id: messageInputContextMenuComponent

                                    // Menu element should be placed into Component
                                    // to crete every time new Menu element
                                    Menu {
                                        id: messageInputContextMenu
                                        background: Rectangle {
                                            implicitWidth: 200 * SettingsState.scale
                                            implicitHeight: 40 * SettingsState.scale
                                            radius: 8 * SettingsState.scale

                                            MenuShadow {
                                                scale: SettingsState.scale
                                                anchors.fill: parent
                                                bodyColor: ColorStorage.surfaceSecondary
                                                shadowColor: ColorStorage.menuShadowColor
                                            }
                                        }

                                        SoftphonePro.PhoneInputMenuItem {
                                            enabled: messageTextInput.hasTextSelected()
                                            topMargin: 1 * SettingsState.scale

                                            actionLabel: qsTrId("clipboard_cut") + Translator.translate
                                            shortcutLabel: "Ctrl+X"

                                            roundTopCorners: true

                                            onTriggered: {
                                                messageTextInput.cut();
                                                messageTextInput.forceActiveFocus();
                                            }
                                        }

                                        SoftphonePro.PhoneInputMenuItem {
                                            enabled: messageTextInput.hasTextSelected()

                                            actionLabel: qsTrId("clipboard_copy") + Translator.translate
                                            shortcutLabel: "Ctrl+C"

                                            onTriggered: {
                                                messageTextInput.copy();
                                                messageTextInput.forceActiveFocus();
                                            }
                                        }

                                        SoftphonePro.PhoneInputMenuItem {
                                            enabled: {
                                                var text = SystemClipboard.getText();

                                                if (text) {
                                                    return true;
                                                }

                                                return false;
                                            }

                                            roundBottomCorners: true

                                            bottomMargin: 1 * SettingsState.scale

                                            actionLabel: qsTrId("clipboard_paste") + Translator.translate
                                            shortcutLabel: "Ctrl+V"

                                            onTriggered: {
                                                messageTextInput.paste();
                                                messageTextInput.forceActiveFocus();
                                            }
                                        }

                                        onActiveFocusChanged: {
                                            if (!activeFocus) {
                                                messageInputContextMenu.close();
                                            }
                                        }

                                        Component.onCompleted: {
                                            messageInputContextMenu.open();
                                        }
                                    }
                                }

                                Loader {
                                    id: messageInputLoader
                                }

                                Rectangle {
                                    id: messageInputArea

                                    anchors.fill: parent
                                    anchors.topMargin: 4 * SettingsState.scale
                                    anchors.leftMargin: 2 * SettingsState.scale
                                    anchors.rightMargin: 40 * SettingsState.scale
                                    anchors.bottomMargin: 20 * SettingsState.scale

                                    color: ColorStorage.mainWindowBackground

                                    ScrollView {
                                        anchors.fill: parent
                                        focus: true

                                        TextArea {
                                            id: messageTextInput

                                            width: parent.width
                                            height: parent.height

                                            property int lastSelectionBegin: 0
                                            property int lastSelectionEnd: 0

                                            function hasTextSelected() {
                                                return lastSelectionEnd > lastSelectionBegin;
                                            }

                                            background: Text {
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.topMargin: 5 * SettingsState.scale
                                                anchors.leftMargin: 10 * SettingsState.scale

                                                text: qsTrId("message_placeholder") + Translator.translate
                                                color: ColorStorage.additionalText
                                                font.family: "Segoe UI"
                                                font.pixelSize: 12 * SettingsState.scale

                                                visible: !messageTextInput.text
                                            }

                                            onActiveFocusChanged: {
                                                if (activeFocus) {
                                                    if (remainingCharactersCounter.text == "0") {
                                                        messageInputRectangle.border.color = ColorStorage.red;
                                                        return;
                                                    }
                                                    messageInputRectangle.border.color = ColorStorage.grayNeutralOnPress;
                                                    return;
                                                }

                                                messageInputRectangle.border.color = "transparent";
                                            }

                                            color: ColorStorage.iconsAndTextPrimary
                                            font.pixelSize: 13 * SettingsState.scale
                                            font.family: "Segoe UI"
                                            wrapMode: TextEdit.Wrap

                                            focus: true

                                            selectByKeyboard: true
                                            selectByMouse: true
                                            selectionColor: ColorStorage.selectionInputColor
                                            selectedTextColor: ColorStorage.iconsAndTextPrimary

                                            clip: true

                                            property string messageMaximumLength: SettingsState.messageMaximumLength

                                            KeyNavigation.tab: numberTextInput

                                            KeyNavigation.priority: KeyNavigation.BeforeItem

                                            onPressed: {
                                                // destroy old Menu element if it exists
                                                if (event.button == Qt.RightButton) {
                                                    messageInputLoader.sourceComponent = null;
                                                }
                                            }

                                            onReleased: {
                                                if (event.button == Qt.RightButton) {
                                                    // need to save selected text because it would
                                                    // lost after mouse click
                                                    messageTextInput.lastSelectionBegin = messageTextInput.selectionStart
                                                    messageTextInput.lastSelectionEnd = messageTextInput.selectionEnd

                                                    messageInputLoader.sourceComponent = messageInputContextMenuComponent;

                                                    // restore selection
                                                    messageTextInput.select(messageTextInput.lastSelectionBegin, messageTextInput.lastSelectionEnd);
                                                }
                                            }

                                            Keys.onReturnPressed: {
                                                if (event.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) {
                                                    insert(cursorPosition, "\n");
                                                    return;
                                                }

                                                if (numberTextInput.text != "" && messageTextInput.text != "") {
                                                    sendMessage();
                                                }
                                            }

                                            Keys.onEnterPressed: {
                                                if (event.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) {
                                                    insert(cursorPosition, "\n");
                                                    return;
                                                }

                                                if (numberTextInput.text != "" && messageTextInput.text != "") {
                                                    sendMessage();
                                                }
                                            }

                                            onTextChanged: {
                                                if(messageTextInput.text.length >  messageMaximumLength) {
                                                    messageTextInput.remove(messageMaximumLength,
                                                                            messageTextInput.text.length)
                                                }
                                            }
                                            onMessageMaximumLengthChanged: {
                                                if(messageTextInput.text.length >  messageMaximumLength) {
                                                    messageTextInput.remove(messageMaximumLength,
                                                                            messageTextInput.text.length)
                                                }
                                            }
                                        }
                                    }
                                }

                                Button {
                                    id: sendMessageButton

                                    enabled: numberTextInput.text != "" && messageTextInput.text != ""

                                    anchors.right: messageInputRectangle.right
                                    anchors.bottom: messageInputRectangle.bottom
                                    anchors.rightMargin: 12 * SettingsState.scale
                                    anchors.bottomMargin: 8 * SettingsState.scale

                                    height: 28 * SettingsState.scale
                                    width: 28 * SettingsState.scale

                                    background: Rectangle {
                                        color: "transparent"
                                    }

                                    MouseArea {
                                        id: sendMessageButtonMouseArea
                                        anchors.fill: parent
                                        onClicked: {
                                            ActionProvider.makeMessage(numberTextInput.text, messageTextInput.text);
                                            numberTextInput.text = "";
                                            messageTextInput.text = "";
                                        }
                                    }

                                    contentItem: Item{
                                        Image {
                                            id: image
                                            height: 20 * SettingsState.scale
                                            width: 20 * SettingsState.scale
                                            source: "qrc:/images/send_message_button.svg"
                                            anchors.centerIn: parent
                                            visible: false
                                            sourceSize.width: width
                                            sourceSize.height: height
                                        }

                                        IconShader {
                                            anchors.centerIn: parent
                                            imageSrcComponent: image
                                            imgColor: sendMessageButton.enabled ?
                                                          (sendMessageButtonMouseArea.pressedButtons ?
                                                               ColorStorage.iconsAndTextPrimary :
                                                               ColorStorage.iconsAndTextSecondary) :
                                                               ColorStorage.additionalText
                                            imageWidth: image.width
                                            imageHeight: image.height
                                        }
                                    }
                                }

                                Text {
                                    id: remainingCharactersCounter

                                    anchors.right: messageInputRectangle.right
                                    anchors.top: messageInputArea.top
                                    anchors.rightMargin: 8 * SettingsState.scale

                                    color: {
                                        if(remainingCharactersCounter.text == "0") {
                                            messageInputRectangle.border.color = ColorStorage.red
                                            return ColorStorage.red
                                        }
                                        messageInputRectangle.border.color = messageTextInput.activeFocus ? ColorStorage.grayNeutralOnPress : "transparent"
                                        return ColorStorage.additionalText
                                    }

                                    text: {
                                        if(!messageTextInput.text) {
                                            return SettingsState.messageMaximumLength
                                        }
                                        return (SettingsState.messageMaximumLength - messageTextInput.text.length).toString()
                                    }
                                    font.family: "Segoe UI"
                                    font.pixelSize: 10 * SettingsState.scale
                                }
                            }
                        }
                    }
                }
            }

        }
    }
}
