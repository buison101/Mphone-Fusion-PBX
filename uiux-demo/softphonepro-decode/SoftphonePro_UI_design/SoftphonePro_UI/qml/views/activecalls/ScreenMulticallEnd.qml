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

    implicitWidth: parent.width

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Item {
            id: activeCallsList
            focus: true
            anchors.fill: parent

            SoftphonePro.SeparatorWithAccount {
                id: separatorWithAccount

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 16 * SettingsState.scale
                anchors.right: parent.right
                anchors.rightMargin: 16 * SettingsState.scale

                account: AppState.lastFinishedCall ? AppState.lastFinishedCall.account + " " + AppState.lastFinishedCall.didName : ""
                currentCallDirection: AppState.lastFinishedCall ? AppState.lastFinishedCall.direction : 0
            }

            onActiveFocusChanged: {
                callSection.forceActiveFocus();
            }

            Rectangle {
                id: callSection

                anchors.top: separatorWithAccount.bottom
                anchors.topMargin: 12 * SettingsState.scale
                anchors.left: parent.left
                anchors.leftMargin: 16 * SettingsState.scale
                anchors.right: parent.right
                anchors.rightMargin: 16 * SettingsState.scale

                height: callInfo.height + crmInfo.height

                color: ColorStorage.mainWindowBackground //black: #000000

                radius: 8 * SettingsState.scale

                property bool rollUpCrmInfo: callInfo.rollUpInfo

            KeyNavigation.tab: callInfo

                MulticallInfoLayer {
                    id: callInfo

                    Keys.onTabPressed: {
                        crmInfo.focusToLastItem = false;
                        crmInfo.forceActiveFocus();
                    }
                    Keys.onBacktabPressed: {
                        crmInfo.focusToLastItem = true;
                        crmInfo.forceActiveFocus();
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            forceFocusOnFirstItem(focusFromCrmAndControlsLayer);
                        }
                    }

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: implicitHeight

                    number: {
                        if (!AppState.lastFinishedCall) {
                            return "";
                        }

                        if((AppState.lastFinishedCall.direction == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                            return SettingsState.hiddenCallerIDTemplate
                        }

                        if (AppState.lastFinishedCall.direction == SipCall.Conference) {
                            return qsTrId("conference_call_name") + Translator.translate;
                        }

                        return AppState.lastFinishedCall.remoteNumber;
                    }

                    name: tmDisplayName.elidedText
                    uneditedName: tmDisplayName.text

                    currentCallStatus: AppState.lastFinishedCall ? AppState.lastFinishedCall.status : 0
                    currentCallDirection: AppState.lastFinishedCall ? AppState.lastFinishedCall.direction : 0
                    showCallsInConference: AppState.lastFinishedCall ? AppState.lastFinishedCall.direction == SipCall.Conference : false

                }

                TextMetrics {
                    id: tmDisplayName

                    elide: Text.ElideRight
                    elideWidth: text.length > 0 ? callInfo.implicitWidth : 0
                    font.family: "Segoe UI"
                    text: {
                        if (!AppState.lastFinishedCall) {
                            return "";
                        }

                        if((AppState.lastFinishedCall.direction == AppCall.Incoming) && SettingsState.hideCallerIDForInboundCalls) {
                            return "";
                        }

                        if (AppState.lastFinishedCall.contactName.length > 0) {
                            return AppState.lastFinishedCall.contactName;
                        }

                        return AppState.lastFinishedCall.remoteDisplayName;
                    }
                }

                CrmAndControlsLayer {
                	id: crmInfo
                	onActiveFocusChanged: {
                    		if (activeFocus) {
                        		forceFocusOnFirstItem();
                        		focusFromCrmAndControlsLayer = true;
                    		}
                	}
                
                	Keys.onTabPressed: {
                            callInfo.focusToLastItem = false;
                    		callInfo.forceActiveFocus();
                    }
                	Keys.onBacktabPressed: {
                        callInfo.focusToLastItem = true;
                    		callInfo.forceActiveFocus();
                	}
			anchors.left: parent.left
                	anchors.right: parent.right
                	anchors.bottom: parent.bottom

                    	height: implicitHeight

                    	crmBorderVisible: {
                        	if (!AppState.lastFinishedCall || !AppState.lastFinishedCall.crmInfo) {
                            	return false;
                        }

                        crmInfo.height = crmInfo.implicitHeight;
                        return true;
             	}

                    visible: {
                        if (!parent.rollUpCrmInfo) {
                            crmInfo.height = crmInfo.implicitHeight;
                            return true;
                        }
                        crmInfo.height = 0;
                        return false;
                    }

                    name: {
                        if (!crmBorderVisible) {
                            return "";
                        }

                        if (AppState.lastFinishedCall.crmInfo.name.length == 0) {
                            return AppState.lastFinishedCall.crmInfo.company;
                        }

                        return AppState.lastFinishedCall.crmInfo.name;
                    }

                    company: {
                        if (!crmBorderVisible) {
                            return "";
                        }

                        if (AppState.lastFinishedCall.crmInfo.name.length == 0) {
                            return "";
                        }

                        return AppState.lastFinishedCall.crmInfo.company;
                    }

                    crm: {
                        if (!crmBorderVisible) {
                            return "";
                        }

                        if (AppState.lastFinishedCall.crmInfo.name.length == 0 ||
                                AppState.lastFinishedCall.crmInfo.company.length == 0) {
                            return AppState.lastFinishedCall.crmInfo.crm;
                        }

                        return "(" + AppState.lastFinishedCall.crmInfo.crm + ")";
                    }

                    number: {
                        if (!AppState.lastFinishedCall) {
                            return "";
                        }

                        if (AppState.lastFinishedCall.direction == SipCall.Conference) {
                            return "";
                        }

                        return AppState.lastFinishedCall.remoteNumber;
                    }


                    status: AppState.lastFinishedCall ? fmt.formatStatus(AppState.lastFinishedCall.status) : ""
                    duration: AppState.lastFinishedCall ? fmt.formatDuration(AppState.lastFinishedCall.duration) : ""
                    currentCallStatus: AppState.lastFinishedCall ? AppState.lastFinishedCall.status : SipCall.Unknown

                    link: crmBorderVisible ? AppState.lastFinishedCall.crmInfo.link : ""
                }
            }
        }
    }
}
