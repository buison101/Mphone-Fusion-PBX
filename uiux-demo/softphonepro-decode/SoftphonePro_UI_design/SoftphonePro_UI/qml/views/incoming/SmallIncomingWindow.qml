import QtQuick 2.15
import Flux 1.0
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15

import "../activecalls"
import "../uicontrols" as SoftphonePro
import "../utils"

FocusScope {
    id: root

    property int maxVisibleElementsCount: 4

    property int crmAddHeight: 68 * SettingsState.scale
    property int autoanswerAddHeight: 27 * SettingsState.scale
    property int elementBaseHeight: 114 * SettingsState.scale

    property int callsWithCrmRoot: 0
    property variant crmCallsArray: []
    property int answeredCallId: -1

    property int lastFinishedCallIdRoot: AppState.lastFinishedCallId

    function updateCallsWithCrm() {
        var sum = 0;
        for(var i = 0; i < crmCallsArray.length; i++) {
            if (!crmCallsArray[i]) {
                continue;
            }
            sum++;
        }
        callsWithCrmRoot = sum;
    }

    width: 364 * SettingsState.scale

    Formatter {
        id: fmt

        property int smallWindowsCount: AppState.incomingCallsModel.count
        property int callsWithCrm: callsWithCrmRoot
        property int lastFinishedCallId: lastFinishedCallIdRoot

        onSmallWindowsCountChanged: {
            if (smallWindowsCount == 0) {
                answeredCallId = -1;
                callsWithCrmRoot = 0;
            }
            updateHeight();
        }

        onLastFinishedCallIdChanged: {
            if (lastFinishedCallId == -1) {
                return;
            }
            if (lastFinishedCallId == answeredCallId)
                answeredCallId = -1;
            if (crmCallsArray[lastFinishedCallId]) {
                crmCallsArray[lastFinishedCallId] = 0;
                updateCallsWithCrm();
            }
        }

        onCallsWithCrmChanged: {
            if (callsWithCrmRoot < 0)
                callsWithCrmRoot = 0;
            updateHeight();
        }

        function updateHeight() {
            var viewHeight = 0;
            var count = listview.count;
            for (var i = 0; i < count && i < root.maxVisibleElementsCount; ++i) {
                viewHeight += root.elementBaseHeight;

                if (AppState.incomingCallsModel.getData(i, ActiveCallItem.AutoAnsweredRole) == true) {
                    viewHeight += root.autoanswerAddHeight;
                }
            }
            viewHeight += callsWithCrm * crmAddHeight;
            root.height = viewHeight;
        }
    }

    Component {
        id: rowDelegate

        FocusScope {
            id: row

            width: 364 * SettingsState.scale
            height: 114 * SettingsState.scale

            focus: true

            Rectangle {
                anchors.fill: parent

                color: ColorStorage.secondaryWindowBackground

                Rectangle {
                    id: titleLayer

                    anchors.top: parent.top
                    anchors.left: parent.left

                    color: ColorStorage.secondaryWindowTitleBackgroundColor
                    width: parent.width
                    height: 31 * SettingsState.scale

                    Text {
                        id: title

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16 * SettingsState.scale

                        font.pixelSize: 12 * SettingsState.scale
                        font.family: "Segoe UI"
                        font.bold: true

                        color: ColorStorage.secondaryWindowTitleAndIcons

                        text: qsTrId("incoming_call_window_title") + Translator.translate
                    }
                }

                Rectangle {
                    id: account
                    width: parent.width - 40 * SettingsState.scale
                    height: 18 * SettingsState.scale
                    anchors.top: titleLayer.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 10 * SettingsState.scale
                    color: "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: accountLayout.left
                        anchors.rightMargin: 20 * SettingsState.scale
                        anchors.verticalCenter: accountLayout.verticalCenter
                        anchors.horizontalCenterOffset: 2

                        height: 1 * SettingsState.scale

                        color: ColorStorage.textAndDisabledIconsGrey
                    }

                    RowLayout {
                        id: accountLayout
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter:  parent.horizontalCenter

                        Text {
                            id: accountName
                            Layout.maximumWidth: 150 * SettingsState.scale
                            Layout.minimumWidth: 10 * SettingsState.scale

                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            elide: Text.ElideRight

                            font.pixelSize: 12 * SettingsState.scale
                            font.family: "Segoe UI"
                            font.weight: Font.DemiBold
                            color: ColorStorage.textAndDisabledIconsGrey
                            text: AppState.activeCall ? AppState.activeCall.account + " " + AppState.activeCall.didName : ""
                            MouseArea {
                                hoverEnabled: true
                                anchors.fill: parent
                                ToolTip {
                                    id: toolTip
                                    visible: parent.containsMouse && content.text && accountName.implicitWidth > accountName.width
                                    delay: 1000
                                    timeout: 5000
                                    clip: true
                                    background: Rectangle {
                                        id: background
                                        color: ColorStorage.iconsAndTextPrimary
                                    }
                                    contentItem: Text {
                                        id: content
                                        text: accountName.text ? accountName.text : ""
                                        color: ColorStorage.mainWindowBackground
                                        wrapMode: Text.WordWrap
                                    }

                                    property int margin: (root.width - background.width) * 0.5
                                    property int minMargin: 6 * SettingsState.scale

                                    leftMargin: margin < minMargin ? minMargin : margin
                                    rightMargin: leftMargin
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.left: accountLayout.right
                        anchors.leftMargin: 20 * SettingsState.scale
                        anchors.verticalCenter: accountLayout.verticalCenter
                        anchors.horizontalCenterOffset: 2

                        height: 1 * SettingsState.scale

                        color: ColorStorage.textAndDisabledIconsGrey
                    }
                }

                CallInfoLayerSmall {
                    id: callInfo

                    anchors.top: account.bottom
                    anchors.topMargin: 10 * SettingsState.scale
                    anchors.left: parent.left
                    anchors.leftMargin: 20 * SettingsState.scale

                    height: 32 * SettingsState.scale

                    numberElement.anchors.topMargin: 0 * SettingsState.scale
                    nameElement.anchors.topMargin: -10 * SettingsState.scale

                    statusElement.anchors.verticalCenterOffset: 0
                    statusElement.visible: index == listview.count - 1 && AppState.activeCallsModel.count == listview.count ? false : true

                    durationElement.anchors.bottomMargin: -3
                    durationElement.visible: statusElement.visible ? true : false

                    width: {
                        if (statusElement.visible) {
                            return 240 * SettingsState.scale;
                        }
                        else {
                            return 170 * SettingsState.scale;
                        }
                    }

                    numberElement.font.pixelSize: 12 * SettingsState.scale
                    nameElement.font.pixelSize: 16 * SettingsState.scale
                    statusElement.font.pixelSize: 11 * SettingsState.scale
                    durationElement.font.pixelSize: 12 * SettingsState.scale

                    number: tmDisplayName.elidedText
                    name: {
                        if((callDirection == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                            return SettingsState.hiddenCallerIDTemplate
                        }
                        return callRemoteNumber
                    }
                    uneditedName: tmDisplayName.text

                    status: fmt.formatStatus(callStatus)
                    duration: fmt.formatDuration(AppState.timeNow - callStartTime)
                }

                TextMetrics {
                    id: tmDisplayName
                    elide: Text.ElideRight
                    elideWidth: text.length > 0 ? 315 : 0
                    font.family: "Segoe UI"
                    text: {
                        if((callDirection == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                            return ""
                        }
                        if(callContactName != "") {
                            return callContactName
                        }
                        if(callRemoteDisplayName != "")
                            return callRemoteDisplayName
                        return callRemoteNumber
                    }
                }

                Column {
                    anchors.top: callInfo.top
                    anchors.topMargin: -7 * SettingsState.scale
                    anchors.right: parent.right
                    anchors.rightMargin: 56 * SettingsState.scale
                    spacing: 15 * SettingsState.scale

                    Component {
                        id: controlsComponent

                        Item {
                            id: controls

                            height: answerButton.height

                            Item {
                                id: initialFocusReceiver

                                anchors.bottom: parent.top
                                anchors.right: parent.right
                                anchors.left: parent.left

                                focus: true

                                KeyNavigation.tab: answerButton
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenterOffset: autoanswerLoader.item ? 3 : 0

                                spacing: 10 * SettingsState.scale

                                SoftphonePro.SquareButton {
                                    id: answerButton

                                    Accessible.role: Accessible.Button
                                    Accessible.name: "SmallIncomingAnswerButton"

                                    KeyNavigation.tab: hangupButton

                                    width: 32 * SettingsState.scale
                                    height: 32 * SettingsState.scale

                                    radius: 8 * SettingsState.scale

                                    colorDefault: ColorStorage.green
                                    colorOnHover: ColorStorage.greenOnHover
                                    colorOnPress: ColorStorage.greenOnPress
                                    colorOnDisabled: ColorStorage.sSizeButtonDisabled

                                    imageWidth: 16 * SettingsState.scale
                                    imageHeight: 16 * SettingsState.scale

                                    imageColorDefault: ColorStorage.white
                                    imageColorOnHover: ColorStorage.white
                                    imageColorOnPress: ColorStorage.white
                                    imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                                    imageDefault: "qrc:/images/call_default.svg"

                                    doWorkOnButtonClick: function() {
                                        if (crmCallsArray[callId]) {
                                            crmCallsArray[callId] = 0;
                                            updateCallsWithCrm();
                                        }
                                        answeredCallId = callId;
                                        ActionProvider.answerCall(callId);
                                        AppLogger.debug("Small incoming window: User clicked Answer button");
                                    }

                                    tooltipText: qsTrId("answer_button_tooltip") + Translator.translate
                                }

                                SoftphonePro.SquareButton {
                                    id: hangupButton

                                    Accessible.role: Accessible.Button
                                    Accessible.name: "SmallHangupAnswerButton"

                                    visible: SettingsState.displayDeclineButtonOnRingingPopup
                                    enabled: SettingsState.displayDeclineButtonOnRingingPopup

                                    KeyNavigation.tab: answerButton

                                    width: 32 * SettingsState.scale
                                    height: 32 * SettingsState.scale

                                    radius: 8 * SettingsState.scale

                                    colorDefault: ColorStorage.red
                                    colorOnHover: ColorStorage.redOnHover
                                    colorOnPress: ColorStorage.redOnPress
                                    colorOnDisabled: ColorStorage.textAndDisabledIconsGrey

                                    imageWidth: 16 * SettingsState.scale
                                    imageHeight: 16 * SettingsState.scale

                                    imageColorDefault:  ColorStorage.white
                                    imageColorOnHover: ColorStorage.white
                                    imageColorOnPress: ColorStorage.white
                                    imageColorOnDisabled: ColorStorage.sSizeButtonImageDisabled

                                    imageDefault: "qrc:/images/phone_hangup_default.svg"

                                    doWorkOnButtonClick: function() {
                                        ActionProvider.hangupCall(callId);
                                        AppLogger.debug("Small incoming window: User clicked Hangup button");
                                    }

                                    tooltipText: qsTrId("decline_button_tooltip") + Translator.translate
                                }
                            }
                        }
                    }

                    Loader {
                        id: controlsLoader

                        width: parent.width
                        sourceComponent: controlsComponent
                    }

                    Component {
                        id: autoanswerComponent

                        Item {
                            id: autoanswer

                            height: 20 * SettingsState.scale

                            Row {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 7
                                anchors.rightMargin: 20


                                spacing: 3 * SettingsState.scale

                                Text {
                                    id: autoanswerLabel

                                    font.pixelSize: 10 * SettingsState.scale
                                    font.family: "Segoe UI"

                                    color: ColorStorage.iconsAndTextPrimary

                                    text: qsTrId("incoming_call_autoanswer") + Translator.translate
                                }

                                Text {
                                    id: autoanswerSeconds

                                    font.pixelSize: 10 * SettingsState.scale
                                    font.family: "Segoe UI"

                                    color: ColorStorage.iconsAndTextPrimary

                                    text: fmt.formatDuration(autoanswerLoader.milliseconds)
                                }
                            }

                            Component.onCompleted: {
                                row.height += root.autoanswerAddHeight;
                            }
                        }
                    }

                    Loader {
                        id: autoanswerLoader

                        property int milliseconds: callAutoAnsweredTime ? callAutoAnsweredTime - AppState.timeNow : 0

                        width: parent.width
                        sourceComponent: controlsLoader.item && callAutoAnswered && milliseconds > 0 ? autoanswerComponent :
                                                                                                       null
                    }
                }

                CrmDynamicInfoLayer {
                    id: crmInfo
                    anchors.top: callInfo.bottom
                    anchors.topMargin: 8 * SettingsState.scale
                    anchors.horizontalCenter: parent.horizontalCenter
                    property string crmName: callCrmName
                    property string crmCompany: callCrmCompany
                    property string crmSystem: callCrmSystemName
                    property string crmLink: callCrmLink
                    property int callIdWithCrmInfo: AppState.callIdWithCrmInfo
                    imageColorDefault: ColorStorage.additionalText
                    width: 336 * SettingsState.scale
                    height: implicitHeight * SettingsState.scale

                    visible: {
                        if (crmName && crmSystem && answeredCallId != currentCallId &&
                                lastFinishedCallIdRoot != currentCallId) {
                            crmCallsArray[currentCallId] = 1;
                            updateCallsWithCrm();
                            crmInfo.height = crmInfo.implicitHeight;
                            row.height = root.elementBaseHeight + root.crmAddHeight;
                            return true;
                        }
                        crmInfo.height = 0;
                        row.height = root.elementBaseHeight;
                        crmCallsArray[currentCallId] = 0;
                        updateCallsWithCrm();
                        return false;
                    }

                    onCallIdWithCrmInfoChanged: {
                        if (callIdWithCrmInfo == -1 || callIdWithCrmInfo != currentCallId) {
                            return;
                        }
                        crmCallsArray[callIdWithCrmInfo] = 1;
                        visible = true;
                        crmInfo.height = crmInfo.implicitHeight;
                        row.height = root.elementBaseHeight + root.crmAddHeight;
                        updateCallsWithCrm();
                    }

                    crmBorderVisible: true

                    name: {
                        if (!crmBorderVisible) {
                            return "";
                        }

                        if (crmName.length == 0) {
                            return crmCompany;
                        }

                        return crmName;
                    }

                    company: {
                        if (!crmBorderVisible) {
                            return "";
                        }

                        if (crmName.length == 0) {
                            return "";
                        }

                        return crmCompany;
                    }

                    crm: {
                        if (!crmBorderVisible) {
                            return "";
                        }

                        if (crmName.length == 0 ||
                                crmCompany.length == 0) {
                            return crmSystem;
                        }

                        return "(" + crmSystem + ")";
                    }
                    currentCallId: callId
                    currentCallAccountId: callAccountId

                    link: crmLink
                }

                SoftphonePro.TitleButton {
                    id: windowClose

                    anchors.top: parent.top
                    anchors.topMargin: 1 * scale
                    anchors.right: parent.right
                    anchors.rightMargin: 1 * scale

                    bodyWidth: 31 * SettingsState.scale
                    bodyHeight: bodyWidth

                    visible: SettingsState.closeRingingPopupButton != IncomingWindowCloseButton.Disabled
                    enabled: SettingsState.closeRingingPopupButton != IncomingWindowCloseButton.Disabled

                    Accessible.role: Accessible.Button
                    Accessible.name: "SmallIncomingCloseButton"

                    scale: SettingsState.scale                    

                    imageWidth: 24 * SettingsState.scale
                    imageHeight: 24 * SettingsState.scale

                    colorDefault: "transparent"
                    colorOnHover: ColorStorage.redOnHover
                    colorOnPress: ColorStorage.redOnPress

                    imageColorDefault: ColorStorage.iconsAndTextPrimary
                    imageSource:  "qrc:/images/close_default.svg"

                    doWorkOnButtonClick: function() {
                        if (crmCallsArray[callId]) {
                            crmCallsArray[callId] = 0;
                            updateCallsWithCrm();
                        }
                        if (AppState.activeCall && SettingsState.closeRingingPopupButton == IncomingWindowCloseButton.Decline) {
                            ActionProvider.hangupCall(AppState.activeCall.id);
                            AppLogger.debug("Small incoming window; Close button: User clicked Hangup button");
                        } else if(AppState.activeCall) {
                            ActionProvider.ignoreCall(AppState.activeCall.id);
                            AppLogger.debug("Small incoming window; Close button: User clicked Ignore button");
                        }
                    }
                }

                Rectangle {
                    id: outline

                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right

                    visible: index != listview.count - 1

                    height: 1 * SettingsState.scale

                    color: ColorStorage.windowBorder
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
        interactive: count > maxVisibleElementsCount

        model: AppState.incomingCallsModel

        delegate: rowDelegate
    }
}
