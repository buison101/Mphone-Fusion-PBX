import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols" as SoftphonePro
import "../utils"

Item {
    id: root

    implicitHeight: body.height
    implicitWidth: body.width
    property bool focusToLastItem: false
    property var forceFocusOnFirstItem: function(focusFromCrmAndControlsLayer) {
        if (!focusFromCrmAndControlsLayer) {
           nextItemInFocusChain();
        }
        if (focusToLastItem) {
            if (callButton.enabled) {
                callButton.forceActiveFocus();
            } else if (hangupButton.enabled) {
                hangupButton.forceActiveFocus();
            }
        } else {
            if (rollUpButton.enabled) {
                rollUpButton.forceActiveFocus();
            } else if (hangupButton.enabled) {
                hangupButton.forceActiveFocus();
            }
        }
        if (AppState.activeCall) {
            if (currentCallDirection == SipCall.Conference) {
                if (focusToLastItem) {
                    hangupButton.forceActiveFocus();
                } else {
                    if (holdButton.enabled) {
                        holdButton.forceActiveFocus();
                    } else if (unholdButton.enabled) {
                        unholdButton.forceActiveFocus();
                    }
                }
            }
        }
    }


    property alias number: number.text
    property alias name: displayName.text

    property alias numberElement: number
    property alias nameElement: displayName
    property alias uneditedName: displayNameToolTipContent.text

    property alias holdButtonEnabled: holdButton.enabled
    property alias unholdButtonEnabled: unholdButton.enabled

    property int currentCallStatus
    property int currentCallId
    property int currentCallDirection
    property bool showCallsInConference: false
    property bool rollUpInfo: false

    property int toolTipDelay: 1000

    Component {
        id: numberMenuComponent

        // Menu element should be placed into Component
        // to crete every time new Menu element
        Menu {
            id: numberMenu

            background: Rectangle {
                implicitWidth: 215 * SettingsState.scale
                implicitHeight: 30 * SettingsState.scale

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
                enabled: true
                scale: SettingsState.scale
                colorDefault: ColorStorage.surfaceSecondary
                colorOnHover: ColorStorage.mainWindowBackground

                topMargin: 1
                bottomMargin: 1

                roundCorners: true

                actionLabel: qsTrId("clipboard_copy") + Translator.translate
                shortcutLabel: "Ctrl+C"

                onTriggered: {
                    if(!number.hasTextSelected()){
                        number.selectAll();
                    }

                    number.copy();
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus) {
                    numberMenu.close();
                }
            }

            Component.onCompleted: {
                numberMenu.open();
            }
        }
    }

    Loader {
        id: numberLoader
    }

    Component {
        id: nameMenuComponent

        // Menu element should be placed into Component
        // to crete every time new Menu element
        Menu {
            id: nameMenu

            background: Rectangle {
                implicitWidth: 215 * SettingsState.scale
                implicitHeight: 30 * SettingsState.scale

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
                enabled: displayName.hasTextSelected()
                scale: SettingsState.scale
                roundBottomCorners: true
                roundTopCorners: true
                actionLabel: qsTrId("clipboard_copy") + Translator.translate
                shortcutLabel: "Ctrl+C"

                colorDefault: ColorStorage.surfaceSecondary
                colorOnHover: ColorStorage.mainWindowBackground

                topMargin: 1
                bottomMargin: 1

                roundCorners: true

                onTriggered: {
                    displayName.copy();
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus) {
                    nameMenu.close();
                }
            }

            Component.onCompleted: {
                nameMenu.open();
            }
        }
    }

    Loader {
        id: nameLoader
    }

    Rectangle {
        id: body
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: {
            if (showCallsInConference) {
                return callsInConference.implicitHeight + hangupButton.height + 48 * SettingsState.scale
            }

            var displayNameShift = 0;

            if (displayName.contentHeight > 50 * SettingsState.scale) {
                displayNameShift = 25 * SettingsState.scale;
            } else if (displayName.contentHeight > 30 * SettingsState.scale) {
                displayNameShift = 11 * SettingsState.scale;
            }

            return hangupButton.height + hangupButton.anchors.topMargin * 2 + displayNameShift
        }

        radius: 8 * SettingsState.scale

        color: "transparent"

        TextEdit {
            id: number

            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.top: hangupButton.top
            anchors.topMargin: 5 * SettingsState.scale

            selectByMouse: true
            selectionColor: ColorStorage.selectionInputColor
            selectedTextColor: ColorStorage.iconsAndTextPrimary
            readOnly: true

            font.pixelSize: 14 * SettingsState.scale
            font.family: "Segoe UI"


            color: ColorStorage.iconsAndTextSecondary // white: #707070 black: #ACACAC

            wrapMode: TextEdit.WrapAnywhere

            property int lastSelectionBegin: 0
            property int lastSelectionEnd: 0

            function hasTextSelected() {
                return lastSelectionEnd > lastSelectionBegin;
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton

                onPressed: {
                    // destroy old Menu element if it exists
                    numberLoader.sourceComponent = null;
                }

                onReleased: {
                    // need to save selected text because it would
                    // lost after mouse click
                    number.lastSelectionBegin = number.selectionStart
                    number.lastSelectionEnd = number.selectionEnd

                    numberLoader.sourceComponent = numberMenuComponent;
                    numberLoader.item.x = parent.x + mouseX;
                    numberLoader.item.y = parent.y + mouseY;

                    // restore selection
                    number.select(number.lastSelectionBegin, number.lastSelectionEnd);
                }
            }
        }

        TextEdit {
            id: displayName

            anchors.top: number.bottom
            anchors.topMargin: 1 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: answerButton.left
            anchors.rightMargin: 10 * SettingsState.scale

            selectByMouse: true
            selectionColor: ColorStorage.selectionInputColor
            selectedTextColor: ColorStorage.iconsAndTextPrimary
            readOnly: true

            font.pixelSize: 13 * SettingsState.scale
            font.family: "Segoe UI"
            font.bold: true

            color: ColorStorage.iconsAndTextPrimary //white: "#000000" // black: #FFFFFF

            wrapMode: TextEdit.Wrap

            property int lastSelectionBegin: 0
            property int lastSelectionEnd: 0

            function hasTextSelected() {
                return lastSelectionEnd > lastSelectionBegin;
            }


            MouseArea {
                id: displayNameMouseArea

                function elided(){return name !== uneditedName}

                anchors.fill: parent
                acceptedButtons: Qt.RightButton

                hoverEnabled: true

                ToolTip {
                    id: displayNameToolTip

                    visible: displayNameMouseArea.containsMouse && displayNameToolTipContent.text && displayNameMouseArea.elided()
                    delay: 1000
                    timeout: 5000
                    contentItem: Text {
                        id: displayNameToolTipContent
                        color: ColorStorage.mainWindowBackground
                        wrapMode: Text.WordWrap
                    }

                    background: Rectangle {
                        color: ColorStorage.iconsAndTextPrimary
                    }
                }

                onPressed: {
                    // destroy old Menu element if it exists
                    nameLoader.sourceComponent = null;
                }

                onReleased: {
                    // need to save selected text because it would
                    // lost after mouse click
                    displayName.lastSelectionBegin = displayName.selectionStart
                    displayName.lastSelectionEnd = displayName.selectionEnd

                    nameLoader.sourceComponent = nameMenuComponent;
                    nameLoader.item.x = parent.x + mouseX;
                    nameLoader.item.y = parent.y + mouseY;

                    // restore selection
                    displayName.select(displayName.lastSelectionBegin, displayName.lastSelectionEnd);
                }
            }
        }

        TextEdit {
            id: conferenceCount

            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.top: number.bottom
            anchors.topMargin: 8 * SettingsState.scale

            width: 15 * SettingsState.scale

            visible: currentCallDirection == SipCall.Conference
            text: {
                if (showCallsInConference) {
                    return listview.count;
                }

                return AppState.activeCallsInConferenceModel.count;
            }

            selectByMouse: true
            selectionColor: ColorStorage.selectionInputColor
            selectedTextColor: ColorStorage.iconsAndTextPrimary
            readOnly: true

            font.pixelSize: 13 * SettingsState.scale
            font.family: "Segoe UI"
            font.bold: true

            color: ColorStorage.iconsAndTextPrimary //white: "#000000" // black: #FFFFFF

            wrapMode: TextEdit.WordWrap
        }

        Image {
            id: image

            anchors.left: conferenceCount.right
            anchors.verticalCenter: conferenceCount.verticalCenter

            visible: false

            width: 17 * SettingsState.scale
            height: 17 * SettingsState.scale

            sourceSize.width: width
            sourceSize.height: height

            source: "qrc:/images/conference-default.svg"
        }

        IconShader {
            anchors.left: conferenceCount.right
            anchors.verticalCenter: conferenceCount.verticalCenter
            visible: currentCallDirection == SipCall.Conference

            imageSrcComponent: image
            imgColor: ColorStorage.iconsAndTextPrimary //white: "#000000" // black: #FFFFFF
            imageWidth: image.width
            imageHeight: image.height
        }



        Rectangle {
            id: callsInConference

            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16 * SettingsState.scale

            implicitHeight: 0 * SettingsState.scale

            radius: 8 * SettingsState.scale

            visible: showCallsInConference

            color: ColorStorage.surfaceSecondary //black: #242424

            Item {
                id: callsInConferenceList

                anchors.fill: parent

                Component {
                    id: rowDelegate

                    Rectangle {
                        width: parent.width
                        height: 30 * SettingsState.scale

                        color: "transparent"

                        Text {
                            id: contactName

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 15 * SettingsState.scale
                            anchors.right: parent.right
                            anchors.rightMargin: 15 * SettingsState.scale

                            font.pixelSize: 13 * SettingsState.scale
                            font.family: "Segoe UI"
                            font.bold: true

                            color: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF

                            text: {
                                if (!AppState.lastFinishedCall) {
                                    return "";
                                }

                                if (callName.length > 0) {
                                    return callName;
                                }

                                return "";
                            }

                            elide: Text.ElideRight

                            MouseArea {
                                anchors.fill: parent

                                hoverEnabled: true

                                ToolTip {
                                    visible: text && parent.containsMouse && contactName.implicitWidth > contactName.width

                                    delay: 1000
                                    timeout: 5000
                                    contentItem: Text {
                                        id: content
                                        text: contactName.text
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
                }

                ListView {
                    id: listview

                    anchors.fill: parent

                    focus: true
                    clip: true

                    boundsBehavior: Flickable.StopAtBounds

                    model: AppState.callsInConferenceModel

                    delegate: rowDelegate

                    interactive: false

                    onCountChanged: {
                        callsInConference.implicitHeight = (30 * count) * SettingsState.scale;
                    }
                }
            }
        }

        onActiveFocusChanged: {
            if (activeFocus) {
                nextItemInFocusChain();
            }
        }

        SoftphonePro.SquareButton {
            id: rollUpButton

            Accessible.role: Accessible.Button
            Accessible.name: "CallInfoRollUpButton"

            KeyNavigation.tab: {
                if (callButton.enabled) {
                    return callButton;
                } else if (holdButton.enabled) {
                    return holdButton;
                }  else if (unholdButton.enabled){
                    return unholdButton;
                } else {
                    return answerButton;
                }
            }
            KeyNavigation.backtab: {
                if (!rollUpInfo) {
                    return null;
                } else {
                    if (hangupButton.enabled) {
                        return hangupButton;
                    } else {
                        return callButton;
                    }
                }
            }

            anchors.left: number.right
            anchors.leftMargin: 10 * SettingsState.scale
            anchors.verticalCenter: number.verticalCenter

            enabled: !rollUpInfo && currentCallDirection != SipCall.Conference && currentCallStatus != SipCall.Connecting
            visible: enabled

            width: 24 * SettingsState.scale
            height: 24 * SettingsState.scale

            borderWidth: 0
            borderWidthOnHover: 0

            color: "transparent"
            colorOnPress: ColorStorage.sSizeButtonOnPress
            colorOnHover: ColorStorage.sSizeButtonOnHover

            radius: 8 * SettingsState.scale

            imageWidth: 24 * SettingsState.scale
            imageHeight: 24 * SettingsState.scale

            imageColorDefault: ColorStorage.iconsAndTextSecondary //white: "#707070" // black: #ACACAC
            imageColorOnHover: ColorStorage.iconsAndTextSecondary //white: "#707070" // black: #ACACAC
            imageColorOnPress: ColorStorage.iconsAndTextSecondary //white: "#707070" // black: #ACACAC

            imageDefault: "qrc:/images/chevron_down.svg"

            doWorkOnButtonClick: function() {
                rollUpInfo = true;
                    expandButton.forceActiveFocus();
            }
        }

        SoftphonePro.SquareButton {
            id: expandButton

            Accessible.role: Accessible.Button
            Accessible.name: "CallInfoExpandButton"

            KeyNavigation.tab: {
                    if (callButton.enabled) {
                        return callButton;
                    } else if (holdButton.enabled) {
                        return holdButton;
                    }  else if (unholdButton.enabled){
                        return unholdButton;
                    } else {
                        return answerButton;
                    }
                }
                KeyNavigation.backtab: {
                    if (!rollUpInfo) {
                        return null;
                    } else {
                        if (hangupButton.enabled) {
                            return hangupButton;
                        } else {
                            return callButton;
                        }
                    }
                }

            anchors.left: number.right
            anchors.leftMargin: 10 * SettingsState.scale
            anchors.verticalCenter: number.verticalCenter

            enabled: rollUpInfo && currentCallDirection != SipCall.Conference && currentCallStatus != SipCall.Connecting
            visible: enabled

            borderWidth: 0
            borderWidthOnHover: 0

            width: 24 * SettingsState.scale
            height: 24 * SettingsState.scale

            color: "transparent"
            colorOnPress: ColorStorage.sSizeButtonOnPress
            colorOnHover: ColorStorage.sSizeButtonOnHover

            radius: 8 * SettingsState.scale

            imageWidth: 24 * SettingsState.scale
            imageHeight: 24 * SettingsState.scale

            imageColorDefault: ColorStorage.iconsAndTextSecondary //white: "#707070" // black: #ACACAC
            imageColorOnHover: ColorStorage.iconsAndTextSecondary //white: "#707070" // black: #ACACAC
            imageColorOnPress: ColorStorage.iconsAndTextSecondary //white: "#707070" // black: #ACACAC

            imageDefault: "qrc:/images/chevron_up.svg"

            doWorkOnButtonClick: function() {
                rollUpInfo = false;
                rollUpButton.forceActiveFocus();
            }
        }

        Item {
            id: focusReceiver
            onActiveFocusChanged: {
                if (activeFocus) {
                    hangupButton.forceActiveFocus();
                }
            }
        }

        SoftphonePro.SquareButton {
            id: answerButton

            Accessible.role: Accessible.Button
            Accessible.name: "CallInfoAnswerButton"

            KeyNavigation.tab: hangupButton
            KeyNavigation.backtab: focusReceiver
            anchors.top: hangupButton.top
            anchors.right: hangupButton.left
            anchors.rightMargin: 8 * SettingsState.scale

            enabled: !unholdButton.enabled && !holdButton.enabled
            visible: AppState.activeCall &&  (currentCallDirection == SipCall.Incoming ||
                                              (AppState.activeCall.isClickToCall && currentCallDirection == SipCall.Outgoing)) && enabled

            width: 48 * SettingsState.scale
            height: 48 * SettingsState.scale

            radius: 8 * SettingsState.scale

            colorDefault: ColorStorage.green //white: "#05B86D" //black: #05B86D
            colorOnHover: ColorStorage.greenOnHover //white: "#049F5F" //black: #049F5F
            colorOnPress: ColorStorage.greenOnPress //white: "#026E41" //black: #026E41
            colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

            imageWidth: 24 * SettingsState.scale
            imageHeight: 24 * SettingsState.scale

            imageColorDefault: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnHover: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

            imageDefault: "qrc:/images/call_default.svg"

            doWorkOnButtonClick: function() {
                ActionProvider.answerCall(currentCallId);
                AppLogger.debug("Active calls; Call info layer: User clicked Answer button");
            }

            tooltipText: qsTrId("answer_button_tooltip") + Translator.translate
            toolTipDelay: root.toolTipDelay
        }

        SoftphonePro.SquareButton {
            id: holdButton

            Accessible.role: Accessible.Button
            Accessible.name: "CallInfoHoldButton"

            KeyNavigation.tab: hangupButton
            anchors.top: hangupButton.top
            KeyNavigation.backtab: {
                if (currentCallDirection == SipCall.Conference) {
                    if (currentCallStatus == SipCall.OnHold) {
                        return hangupButton;
                    } else {
                        return null;
                    }
                } else {
                    return !rollUpInfo ? rollUpButton : expandButton;
                }
            }

            anchors.right: hangupButton.left
            anchors.rightMargin: 8 * SettingsState.scale

            width: 48 * SettingsState.scale
            height: 48 * SettingsState.scale

            radius: 8 * SettingsState.scale

            visible: AppState.activeCall && enabled

            colorDefault: ColorStorage.grayNeutral //white: "#D9D9D9" //black: #3B3B3B
            colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
            colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
            colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

            imageWidth: 24 * SettingsState.scale
            imageHeight: 24 * SettingsState.scale

            imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
            imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
            imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

            imageDefault: "qrc:/images/phone_hold_default.svg"

            doWorkOnButtonClick: function() {
                if (holdButton.activeFocus) {
                    unholdButton.forceActiveFocus();
                }

                if (currentCallDirection == SipCall.Conference) {
                    ActionProvider.holdConference(true);
                    return;
                }

                ActionProvider.holdCall(currentCallId);
            }

            tooltipText: qsTrId("hold_button_tooltip") + Translator.translate
            toolTipDelay: root.toolTipDelay
        }

        SoftphonePro.SquareButton {
            id: unholdButton

            Accessible.role: Accessible.Button
            Accessible.name: "CallInfoUnholdButton"

            KeyNavigation.tab: hangupButton
            anchors.top: hangupButton.top
            KeyNavigation.backtab: {
                if (currentCallDirection == SipCall.Conference) {
                    if (currentCallStatus == SipCall.OnHold) {
                        return hangupButton;
                    } else {
                        return null;
                    }
                } else {
                    return !rollUpInfo ? rollUpButton : expandButton;
                }
            }
            anchors.right: hangupButton.left
            anchors.rightMargin: 8 * SettingsState.scale

            width: 48 * SettingsState.scale
            height: 48 * SettingsState.scale

            radius: 8 * SettingsState.scale

            visible: AppState.activeCall && enabled

            colorDefault: ColorStorage.grayNeutral //white: "#D9D9D9" //black: #3B3B3B
            colorOnHover: ColorStorage.grayNeutralOnHover //white: "#C4C4C4" //black: #545454
            colorOnPress: ColorStorage.grayNeutralOnPress //white: "#ACACAC" //black: #707070
            colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

            imageWidth: 24 * SettingsState.scale
            imageHeight: 24 * SettingsState.scale

            imageColorDefault: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
            imageColorOnHover: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: #FFFFFF
            imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

            imageDefault: "qrc:/images/phone_unhold.svg"

            doWorkOnButtonClick: function() {
                if (unholdButton.activeFocus) {
                    holdButton.forceActiveFocus();
                }

                rollUpInfo = false;

                if (currentCallDirection == SipCall.Conference) {
                    ActionProvider.holdConference(false);
                    return;
                }

                ActionProvider.holdCall(currentCallId);
            }

            tooltipText: qsTrId("unhold_button_tooltip") + Translator.translate
            toolTipDelay: root.toolTipDelay
        }

        SoftphonePro.SquareButton {
            id: hangupButton

            Accessible.role: Accessible.Button
            Accessible.name: "CallInfoHangupButton"
                KeyNavigation.tab: {
                    if (AppState.activeCall) {
                        if (currentCallStatus == SipCall.Answered
                                || currentCallStatus == SipCall.Calling) {
                            if (currentCallDirection == SipCall.Conference) {
                                return null;
                            } else {
                                if (rollUpButton.enabled) {
                                    return null;
                                } else {
                                    return expandButton;
                                }
                            }
                        } else if (currentCallStatus == SipCall.Connecting){
                            return answerButton;
                        } else if (currentCallStatus == SipCall.OnHold) {
                            if (currentCallDirection == SipCall.Conference) {
                                return unholdButton;
                            } else {
                                return rollUpButton.enabled ? null : expandButton;
                            }
                        }
                    }
                }

                KeyNavigation.backtab: {
                    if (holdButton.enabled) {
                        return holdButton;
                    } else if (unholdButton.visible) {
                        return unholdButton;
                    } else if (answerButton.visible) {
                        return answerButton;
                    } else if (rollUpButton.visible) {
                        return rollUpButton;
                    } else if (expandButton.visible) {
                        return expandButton;
                    }
                }

            anchors.top: parent.top
            anchors.topMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            enabled: AppState.activeCall
            visible: enabled

            width: 48 * SettingsState.scale
            height: 48 * SettingsState.scale

            radius: 8 * SettingsState.scale

            colorDefault: ColorStorage.red //white: "#F01D00" //black: #F01D00
            colorOnHover: ColorStorage.redOnHover //white: "#C71700" //black: #C71700
            colorOnPress: ColorStorage.redOnPress //white: "#781002" //black: #781002
            colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

            imageWidth: 24 * SettingsState.scale
            imageHeight: 24 * SettingsState.scale

            imageColorDefault: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnHover: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

            imageDefault: "qrc:/images/phone_hangup.svg"

            doWorkOnButtonClick: function() {
                AppLogger.debug("Active calls; Call info layer: User clicked Hangup button");
                if (currentCallDirection != SipCall.Conference) {
                    ActionProvider.hangupCall(currentCallId);
                    return;
                }
                ActionProvider.hangupConference();
            }

            tooltipText: qsTrId("decline_button_tooltip") + Translator.translate
            toolTipDelay: root.toolTipDelay
        }

        SoftphonePro.SquareButton {
            id: callButton

            Accessible.role: Accessible.Button
            Accessible.name: "CallInfoCallButton"

                KeyNavigation.tab: {
                    if (rollUpButton.enabled) {
                        return null;
                    } else {
                        expandButton;
                    }
                }

                KeyNavigation.backtab: {
                    if (rollUpButton.enabled) {
                        return rollUpButton;
                    } else {
                        expandButton;
                    }
                }

            anchors.top: hangupButton.top
            anchors.right: hangupButton.right

            anchors.verticalCenter: answerButton.verticalCenter

            width: 48 * SettingsState.scale
            height: 48 * SettingsState.scale

            radius: 8 * SettingsState.scale

            enabled: !AppState.activeCall && currentCallDirection != SipCall.Conference
            visible: enabled

            colorDefault: ColorStorage.green //white: "#05B86D" //black: #05B86D
            colorOnHover: ColorStorage.greenOnHover //white: "#049F5F" //black: #049F5F
            colorOnPress: ColorStorage.greenOnPress //white: "#026E41" //black: #026E41
            colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

            imageWidth: 24 * SettingsState.scale
            imageHeight: 24 * SettingsState.scale

            imageColorDefault: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnHover: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
            imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

            imageDefault: "qrc:/images/call_default.svg"

            doWorkOnButtonClick: function() {
                if (!disableWorkFunction) {
                    var number = AppState.lastFinishedCall.remoteOrNumberWithExtension;

                    if((AppState.lastFinishedCall.direction == AppCall.Incoming)
                            && SettingsState.hideCallerIDForInboundCalls) {
                        number =  SettingsState.hiddenCallerIDTemplate;
                    }

                    ActionProvider.makeCallViaAccount(number,
                                                      AppState.lastFinishedCall.accountId,
                                                      false, false, {}, AppState.lastFinishedCall.didId);
                    secondsDisabledLeft = 0;
                    disableWorkFunction = true;
                }
            }

            property var timeNow: AppState.timeNow
            property int secondsDisabledMax: 2
            property int secondsDisabledLeft: 0
            property bool disableWorkFunction: false

            onTimeNowChanged: {
                if (secondsDisabledLeft == secondsDisabledMax) {
                    return;
                }

                secondsDisabledLeft += 1;

                if (secondsDisabledLeft == secondsDisabledMax) {
                    disableWorkFunction = false;
                }
            }

            onEnabledChanged: {
                if (!enabled) {
                    return;
                }
                secondsDisabledLeft = 0;
                disableWorkFunction = true;
            }

            tooltipText: qsTrId("dial_button_tooltip") + Translator.translate
            toolTipDelay: root.toolTipDelay
        }
    }
}
