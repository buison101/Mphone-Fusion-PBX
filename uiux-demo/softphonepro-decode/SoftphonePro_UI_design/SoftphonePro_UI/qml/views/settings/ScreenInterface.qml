import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ScrollView {
    id: root

    property int marginValue: 20
    property int fontSize: 11

    Flickable {
        id: flickable

        ScrollBar.vertical: ScrollBar {}

        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds

        clip: true

        Rectangle {
            id: settingsInterface

            anchors.fill: parent

            height: groupBox.height + groupBoxPostprocessing.height +
                    groupBoxUserIdle.height + 80 - (AppFeatures.hidePostProcessing ? 0 : 28) + 130

            color: ColorStorage.settingsWindowBaseColor

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: marginValue
                anchors.leftMargin: marginValue
                anchors.rightMargin: marginValue

                color: ColorStorage.settingsWindowBaseColor

                SettingsGroupBox {
                    id: groupBox

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right

                    title: qsTrId("settings_interface") + Translator.translate

                    property int scaleHeight: scaleSetting.height + scaleSetting.anchors.topMargin

                    height: floatingWindowDuringCallSettings.height + floatingWindowDuringCallSettings.anchors.topMargin
                            + mainWindowOutgoingCallSettings.height + mainWindowOutgoingCallSettings.anchors.topMargin
                            + mainWindowIncomingCallSettings.height + mainWindowIncomingCallSettings.anchors.topMargin
                            + windowsRestorePositionsSettings.height + windowsRestorePositionsSettings.anchors.topMargin
                            + incomingCallWindowPositionSettings.height + incomingCallWindowPositionSettings.anchors.topMargin
                            + scaleHeight + marginValue + marginValue + marginValue

                    Row {
                        id: floatingWindowDuringCallSettings

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.topMargin: marginValue

                        height: floatingWindowDuringCallCheckbox.height
                        spacing: marginValue

                        SettingsCheckBox {
                            id: floatingWindowDuringCallCheckbox

                            property bool showFloatingWindow: SettingsState.showFloatingWindow

                            checked: showFloatingWindow

                            onCheckedChanged: {
                                if (checked != showFloatingWindow) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.ShowFloatingWindow, checked);
                                }
                            }

                            onShowFloatingWindowChanged: {
                                checked = showFloatingWindow;
                            }
                        }

                        Label {
                            anchors.verticalCenter: floatingWindowDuringCallCheckbox.verticalCenter
                            text: qsTrId("settings_interface_floating_window_during_call") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Row {
                        id: mainWindowOutgoingCallSettings

                        anchors.top: floatingWindowDuringCallSettings.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        height: mainWindowOutgoingCallCheckbox.height
                        spacing: marginValue

                        SettingsCheckBox {
                            id: mainWindowOutgoingCallCheckbox

                            property bool mainWindowOnOutgoing: SettingsState.mainWindowOnOutgoing

                            checked: mainWindowOnOutgoing

                            onCheckedChanged: {
                                if (checked != mainWindowOnOutgoing) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.MainWindowOnOutgoing, checked);
                                }
                            }

                            onMainWindowOnOutgoingChanged: {
                                checked = mainWindowOnOutgoing;
                            }
                        }

                        Label {
                            anchors.verticalCenter: mainWindowOutgoingCallCheckbox.verticalCenter
                            text: qsTrId("settings_interface_main_window_on_outgoing_call") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Row {
                        id: mainWindowIncomingCallSettings

                        anchors.top: mainWindowOutgoingCallSettings.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        height: mainWindowIncomingCallCheckbox.height
                        spacing: marginValue

                        SettingsCheckBox {
                            id: mainWindowIncomingCallCheckbox

                            property bool mainWindowOnIncomingAnswer: SettingsState.mainWindowOnIncomingAnswer

                            checked: mainWindowOnIncomingAnswer

                            onCheckedChanged: {
                                if (checked != mainWindowOnIncomingAnswer) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.MainWindowOnIncomingAnswer, checked);
                                }
                            }

                            onMainWindowOnIncomingAnswerChanged: {
                                checked = mainWindowOnIncomingAnswer;
                            }
                        }

                        Label {
                            enabled: mainWindowIncomingCallCheckbox.enabled

                            anchors.verticalCenter: mainWindowIncomingCallCheckbox.verticalCenter
                            text: qsTrId("settings_interface_main_window_on_incoming_call_answer") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Component {
                        id: showSipAcoountNameInCallHistoryComponent

                        Row {
                            id: showSipAcoountNameInCallHistory

                            height: showSipAcoountNameInCallHistoryCheckbox.height
                            spacing: marginValue

                            SettingsCheckBox {
                                id: showSipAcoountNameInCallHistoryCheckbox

                                property bool sipAccountInCallHistory: SettingsState.showSipAccountInCallHistory

                                checked: sipAccountInCallHistory

                                onCheckedChanged: {
                                    if (checked != sipAccountInCallHistory) {
                                        ActionProvider.markAppConfigUpdate(AppConfig.ShowSipAccountInCallHistoryWindow, checked);
                                    }
                                }

                                onSipAccountInCallHistoryChanged: {
                                    checked = sipAccountInCallHistory;
                                }
                            }

                            Label {
                                enabled: showSipAcoountNameInCallHistoryCheckbox.enabled

                                anchors.verticalCenter: showSipAcoountNameInCallHistoryCheckbox.verticalCenter
                                text: qsTrId("settings_interface_sip_account_in_call_history_window") + Translator.translate
                                font.pixelSize: fontSize
                            }
                        }
                    }

                    Loader {
                        id: showSipAcoountNameInCallHistoryLoader

                        anchors.top: mainWindowIncomingCallSettings.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        sourceComponent: showSipAcoountNameInCallHistoryComponent
                    }

                    Row {
                        id: windowsRestorePositionsSettings

                        anchors.top: showSipAcoountNameInCallHistoryLoader.item ? showSipAcoountNameInCallHistoryLoader.bottom : mainWindowIncomingCallSettings.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        height: windowsRestorePositionsCheckbox.height
                        spacing: marginValue

                        SettingsCheckBox {
                            id: windowsRestorePositionsCheckbox

                            property bool windowsRestorePositions: SettingsState.windowsRestorePositions

                            checked: windowsRestorePositions

                            onCheckedChanged: {
                                if (checked != windowsRestorePositions) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.WindowsRestorePositions, checked);
                                }
                            }

                            onWindowsRestorePositionsChanged: {
                                checked = windowsRestorePositions;
                            }
                        }

                        Label {
                            enabled: windowsRestorePositionsSettings.enabled

                            anchors.verticalCenter: windowsRestorePositionsSettings.verticalCenter
                            text: qsTrId("settings_interface_windows_reset_positions") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Row {
                        id: incomingCallWindowPositionSettings

                        anchors.top: windowsRestorePositionsSettings.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        height: incomingCallWindowPositionComboBox.height
                        spacing: marginValue

                        Label {
                            anchors.verticalCenter: incomingCallWindowPositionComboBox.verticalCenter
                            text: qsTrId("settings_interface_incoming_call_window_position") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        SettingsComboBox {
                            id: incomingCallWindowPositionComboBox

                            width: 150

                            model: SettingsState.incomingCallWindowPositionModel
                            textRole: "name"

                            property int incomingCallWindowPositionModelSelectedIdx: SettingsState.incomingCallWindowPositionModelSelectedIdx

                            currentIndex: incomingCallWindowPositionModelSelectedIdx

                            onCurrentIndexChanged: {
                                if (currentIndex != onCurrentIndexChanged) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.IncomingCallWindowPosition, currentIndex);
                                }
                            }

                            onIncomingCallWindowPositionModelSelectedIdxChanged: {
                                currentIndex = incomingCallWindowPositionModelSelectedIdx;
                            }
                        }
                    }

                    Row {
                        id: scaleSetting

                        anchors.top: incomingCallWindowPositionSettings.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.right: incomingCallWindowPositionSettings.right

                        visible: true

                        height: scaleSpinBox.height
                        spacing: marginValue

                        Label {
                            anchors.verticalCenter: scaleSpinBox.verticalCenter
                            text: qsTrId("settings_interface_scale_percents") + " (%)" + Translator.translate
                            font.pixelSize: fontSize
                        }

                        SettingsSpinBox {
                            id: scaleSpinBox

                            anchors.right: scaleSetting.right
                            anchors.rightMargin: 150 - width
                            width: 150

                            from: 50
                            to: 200
                            stepSize: 5
                            value: SettingsState.scale * 100

                            onValueChanged: {
                                ActionProvider.changeScale(value)
                            }
                        }
                    }
                }

                SettingsGroupBox {
                    id: groupBoxPostprocessing

                    anchors.top: groupBox.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: visible ? postProcessingWindowEnabledSettings.height + postProcessingWindowEnabledSettings.anchors.topMargin
                            + postProcessingStatusSettings.height + postProcessingStatusSettings.anchors.topMargin + marginValue : 0

                    title: qsTrId("postprocessing_settings") + Translator.translate
                    visible: !AppFeatures.hidePostProcessing

                    Row {
                        id: postProcessingWindowEnabledSettings

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.topMargin: marginValue

                        height: postProcessingWindowEnabledCheckbox.height
                        spacing: marginValue

                        SettingsCheckBox {
                            id: postProcessingWindowEnabledCheckbox

                            property bool postProcessingWindowEnabled: SettingsState.postProcessingWindowEnabled

                            checked: postProcessingWindowEnabled

                            onCheckedChanged: {
                                if (checked != postProcessingWindowEnabled) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.PostProcessingWindowEnabled, checked);
                                }
                            }

                            onPostProcessingWindowEnabledChanged: {
                                checked = postProcessingWindowEnabled;
                            }
                        }

                        Label {
                            enabled: postProcessingWindowEnabledCheckbox.enabled

                            anchors.verticalCenter: postProcessingWindowEnabledCheckbox.verticalCenter
                            text: qsTrId("settings_interface_show_post_processing_window") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Row {
                        id: postProcessingStatusSettings

                        anchors.top: postProcessingWindowEnabledSettings.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        height: postProcessingStatusComboBox.height
                        spacing: marginValue

                        Label {
                            anchors.verticalCenter: postProcessingStatusComboBox.verticalCenter
                            text: qsTrId("settings_interface_post_processing_status") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        SettingsComboBox {
                            id: postProcessingStatusComboBox

                            width: 150

                            model: AppState.phoneStatusModel
                            textRole: "name"

                            property int postProcessingStatusSelectedIdx: SettingsState.postProcessingStatusSelectedIdx

                            currentIndex: postProcessingStatusSelectedIdx

                            onCurrentIndexChanged: {
                                if (currentIndex != onCurrentIndexChanged) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.PostProcessingStatus, currentIndex);
                                }
                            }

                            onPostProcessingStatusSelectedIdxChanged: {
                                currentIndex = postProcessingStatusSelectedIdx;
                            }
                        }
                    }
                }

                SettingsGroupBox {
                    id: groupBoxUserIdle

                    anchors.top: groupBoxPostprocessing.bottom
                    anchors.topMargin: visible ? 20 : 0
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: visible ? userIdleSetAway.height + marginValue + userIdleSetOnline.height + marginValue + marginValue : 0

                    title: qsTrId("user_idle_settings") + Translator.translate

                    visible: !AppFeatures.hideStatusSettings

                    Row {
                        id: userIdleSetAway

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.topMargin: marginValue

                        height: userIdleSetAwayEnabledCheckbox.height

                        SettingsCheckBox {
                            id: userIdleSetAwayEnabledCheckbox

                            property bool userIdleSetAwayEnabled: SettingsState.userIdleSetAwayEnabled

                            checked: userIdleSetAwayEnabled

                            enabled: groupBoxUserIdle.visible

                            onCheckedChanged: {
                                if (checked != userIdleSetAwayEnabled) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.UserIdleSetAway, checked)
                                }
                            }

                            onUserIdleSetAwayEnabledChanged: {
                                checked = userIdleSetAwayEnabled;
                            }
                        }

                        Label {
                            id: userIdleSetAwayLabel

                            anchors.left: userIdleSetAwayEnabledCheckbox.right
                            anchors.leftMargin: marginValue
                            anchors.verticalCenter: userIdleSetAwayEnabledCheckbox.verticalCenter

                            text: qsTrId("enable_user_idle_set_away") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        SettingsSpinBox {
                            id: userIdleTimeSpinBox

                            enabled: userIdleSetAwayEnabledCheckbox.checked && groupBoxUserIdle.visible

                            anchors.verticalCenter: userIdleSetAwayEnabledCheckbox.verticalCenter
                            anchors.left: userIdleSetAwayLabel.right
                            anchors.leftMargin: marginValue / 4

                            from: 1
                            to: 48 * 60 //Two days in minutes
                            stepSize: 1
                            value: SettingsState.userIdleTime

                            height: 30
                            width: 60

                            onValueChanged: {
                                ActionProvider.markAppConfigUpdate(AppConfig.UserIdleTime, value)
                            }
                        }

                        Label {
                            anchors.verticalCenter: userIdleSetAwayEnabledCheckbox.verticalCenter
                            anchors.left: userIdleTimeSpinBox.right
                            anchors.leftMargin: 5

                            text: qsTrId("minutes") + Translator.translate
                            font.pixelSize: 11
                        }
                    }

                    Row {
                        id: userIdleSetOnline

                        anchors.top: userIdleSetAway.bottom
                        anchors.topMargin: 15
                        anchors.left: parent.left
                        anchors.leftMargin: 20

                        height: userIdleSetOnlineEnabledCheckbox.height
                        spacing: 20

                        SettingsCheckBox {
                            id: userIdleSetOnlineEnabledCheckbox

                            enabled: userIdleSetAwayEnabledCheckbox.checked && groupBoxUserIdle.visible

                            property bool userIdleSetOnlineEnabled: SettingsState.userIdleSetOnlineEnabled

                            checked: userIdleSetOnlineEnabled

                            onCheckedChanged: {
                                if (checked != userIdleSetOnlineEnabled) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.UserIdleSetOnline, checked)
                                }
                            }

                            onUserIdleSetOnlineEnabledChanged: {
                                checked = userIdleSetOnlineEnabled;
                            }
                        }

                        Label {
                            enabled: userIdleSetAwayEnabledCheckbox.checked

                            anchors.verticalCenter: userIdleSetOnlineEnabledCheckbox.verticalCenter
                            text: qsTrId("enable_user_idle_set_online") + Translator.translate
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}


