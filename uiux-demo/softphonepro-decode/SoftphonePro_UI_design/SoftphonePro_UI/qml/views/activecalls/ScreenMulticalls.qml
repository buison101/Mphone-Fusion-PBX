import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols" as SoftphonePro
import "../utils"

FocusScope {
    id: root

    focus: true

    property bool focusFromCrmAndControlsLayer: false
    Formatter {
        id: fmt
    }

    Rectangle {
        color: "transparent"
        anchors.fill: parent

        Item {
            id: activeCallsList
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Component {
                id: rowDelegate
                Rectangle {
                    width: parent.width
                    height:  {
                        if (conferenceInfo.visible) {
                            return callInfo.height + conferenceInfo.height + separatorWithAccount.height
                        }
                        return callInfo.height + crmInfo.height + separatorWithAccount.height
                    }

                    onActiveFocusChanged: {
                        callSection.forceActiveFocus();
                    }

                    color: ColorStorage.secondaryWindowBackground //black: #171717

                    SoftphonePro.SeparatorWithAccount {
                        id: separatorWithAccount

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: 16 * SettingsState.scale
                        anchors.right: parent.right
                        anchors.rightMargin: 16 * SettingsState.scale

                        account: AppState.activeCall ? callAccount + " " + AppState.activeCall.didName : ""
                        currentCallDirection: callDirection
                    }

                    Rectangle {
                        id: callSection

                        anchors.top: separatorWithAccount.bottom
                        anchors.topMargin: 12 * SettingsState.scale
                        anchors.left: parent.left
                        anchors.leftMargin: 16 * SettingsState.scale
                        anchors.right: parent.right
                        anchors.rightMargin: 16 * SettingsState.scale

                        radius: 8 * SettingsState.scale

                        height:  {
                            if (conferenceInfo.visible) {
                                return callInfo.height + conferenceInfo.height
                            }

                            return callInfo.height + crmInfo.height
                        }

                        color: ColorStorage.mainWindowBackground //black: #000000
                        property bool rollUpCrmInfo: callInfo.rollUpInfo

                        onActiveFocusChanged: {
                            focusFromCrmAndControlsLayer = false;
                            callInfo.forceActiveFocus();
                        }

                        KeyNavigation.tab: callInfo
                        KeyNavigation.backtab: callInfo
                        MulticallInfoLayer {
                            id: callInfo
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: implicitHeight

                            visible: AppState.activeCall

                            onActiveFocusChanged: {
                                if (activeFocus) {
                                    forceFocusOnFirstItem(focusFromCrmAndControlsLayer);
                                }
                            }
                            Keys.onTabPressed: {
                                crmInfo.focusToLastItem = false;
                                AppState.activeCall.direction
                                    == SipCall.Conference ? conferenceInfo.forceActiveFocus()
                                    : crmInfo.forceActiveFocus();
                            }
                            Keys.onBacktabPressed: {
                                crmInfo.focusToLastItem = true;
                                if (AppState.activeCall) {
                                    if (AppState.activeCall.direction == SipCall.Conference) {
                                        conferenceInfo.forceActiveFocus();
                                    } else if (AppState.activeCall.status == SipCall.Connecting) {
                                        callInfo.focusToLastItem = true;
                                        callInfo.forceActiveFocus();
                                    } else {
                                        crmInfo.forceActiveFocus();
                                    }
                                } else {
                                    crmInfo.forceActiveFocus();
                                }
                            }
                            number: {
                                if (!AppState.activeCall) {
                                    return ""
                                }

                                if ((callDirection == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                                    return SettingsState.hiddenCallerIDTemplate
                                }

                                return callRemoteNumber
                            }
                            name: tmDisplayName.elidedText
                            uneditedName: tmDisplayName.text

                            nameElement.visible: callDirection != SipCall.Conference

                            currentCallId: callId
                            currentCallDirection: callDirection
                            currentCallStatus: callStatus

                            unholdButtonEnabled: AppState.activeCall && callStatus == SipCall.OnHold
                            holdButtonEnabled: AppState.activeCall && callStatus == SipCall.Answered
                        }

                        TextMetrics {
                            id: tmDisplayName

                            elide: Text.ElideRight
                            elideWidth: text.length > 0 ? callInfo.implicitWidth : 0
                            font.family: "Segoe UI"
                            text: {
                                if (!AppState.activeCall) {
                                    return ""
                                }

                                if ((AppState.activeCall.direction == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                                    return ""
                                }

                                if (callContactName) {
                                    return callContactName
                                }

                                return callRemoteDisplayName
                            }
                        }

                        CrmAndControlsLayer {
                            id: crmInfo

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom

                            property string crmName: callCrmName
                            property string crmCompany: callCrmCompany
                            property string crmSystem: callCrmSystemName
                            property string crmLink: callCrmLink

                            Keys.onTabPressed: {
                            callInfo.focusToLastItem = false;
                            callInfo.forceActiveFocus();
                            }
                            Keys.onBacktabPressed: {
                            callInfo.focusToLastItem = true;
                            callInfo.forceActiveFocus();
                            }

                            onActiveFocusChanged: {
                                if (activeFocus) {
                                    forceFocusOnFirstItem();
                                    focusFromCrmAndControlsLayer = true;
                                }
                            }
                            height: implicitHeight
                            visible: {
                                if (!parent.rollUpCrmInfo && callDirection != SipCall.Conference &&
                                        (callStatus == SipCall.Answered || callStatus == SipCall.OnHold ||
                                         callDirection == SipCall.Outgoing ||
                                         (callDirection == SipCall.Incoming && AppState.activeCall.isClickToCall))) {
                                    crmInfo.height = crmInfo.implicitHeight;
                                    return true;
                                }

                                crmInfo.height = 0;
                                return false;
                            }

                            crmBorderVisible: {
                                if (crmSystem.length == 0) {
                                    return false;
                                }

                                return true;
                            }

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

                            number: AppState.activeCall ? callRemoteNumber : ""

                            status: AppState.activeCall ? fmt.formatStatus(callStatus) : ""
                            duration: AppState.activeCall ? fmt.formatDuration(AppState.timeNow - callStartTime) : ""
                            currentCallId: callId
                            currentCallStatus: callStatus
                            currentCallAccountId: callAccountId

                            link: crmLink

                            onVisibleChanged: {
                                if (!parent.rollUpCrmInfo && callStatus != SipCall.Connecting) {
                                    crmInfo.height = crmInfo.implicitHeight;
                                }
                                else {
                                    crmInfo.height = 0;
                                }
                            }
                        }

                        ConferenceControlsLayer {
                            id: conferenceInfo

                            onActiveFocusChanged: {
                                if (activeFocus) {
                                    forceFocusOnFirstItem();
                                    focusFromCrmAndControlsLayer = false;
                                }
                            }
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom

                            Keys.onTabPressed: {
                                callInfo.focusToLastItem = false;
                                callInfo.forceActiveFocus();
                            }
                            Keys.onBacktabPressed: {
                                callInfo.focusToLastItem = true;
                                callInfo.forceActiveFocus();
                            }
                            height: implicitHeight
                            visible: AppState.activeCall && callDirection == SipCall.Conference
                            currentCallId: callId
                            currentCallStatus: callStatus
                            status: AppState.activeCall ? fmt.formatStatus(callStatus) : ""
                            duration: AppState.activeCall ? fmt.formatDuration(AppState.timeNow - callStartTime) : ""
                        }
                    }
                }
            }

            ListView {
                id: listview
                focus: true
                anchors.fill: parent
                clip: true
                property var activeCallsWithConferenceModel: AppState.activeCallsWithConferenceModel
                boundsBehavior: Flickable.StopAtBounds
                spacing: 25 * SettingsState.scale
                model: AppState.activeCallsWithConferenceModel

                ScrollBar.vertical: ScrollBar {
                    id: scrollBar
                    active: listview.activeFocus && listview.count > 2
                }

                delegate: rowDelegate
            }
        }

        Rectangle {
            anchors.fill: parent

            color: "transparent"

            visible: !AppState.activeCall && !AppState.lastFinishedCall

            Text {
                id: callEndLabel

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                font.pixelSize: 13 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextPrimary //white: "#000000" //black: "#FFFFFF"

                text: qsTrId("active_calls_window_no_active_calls") + Translator.translate
            }
        }
    }
}


