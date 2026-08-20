import QtQuick 2.15
import Flux 1.0
import "../uicontrols"

Item {
    id: root

    focus: true

    function calculateWidth() {
        return root.width / (5 -(!AppFeatures.hideStatisticsWindow ? 0 : 1) - (!AppFeatures.hideMessagingWindow && SettingsState.messagingEnable? 0 : 1))
    }

    SwitchButton {
        id: activeCallsButton

        Accessible.role: Accessible.Button
        Accessible.name: "ActiveCallsButton"

        height: parent.height
        width: calculateWidth()

        imageWidth: 24 * SettingsState.scale
        imageHeight: 24 * SettingsState.scale

        anchors.top: parent.top
        anchors.left: parent.left
        isChecked: SettingsState.showActiveCallsWindow

        doWorkOnButtonClick: function () {
            ActionProvider.showActiveCallsWindow(!isChecked);
        }

        source: "qrc:/images/active_calls_window_panel_button_enabled.svg"
    }

    SwitchButton {
        id: contactButton

        Accessible.role: Accessible.Button
        Accessible.name: "ContactButton"

        height: parent.height
        width: calculateWidth()

        imageWidth: 24 * SettingsState.scale
        imageHeight: 24 * SettingsState.scale

        anchors.top: parent.top
        anchors.left: activeCallsButton.right

        isChecked: SettingsState.showContactsWindow


        doWorkOnButtonClick: function () {
            ActionProvider.showContactsWindow(!isChecked);
        }

        // sourceOnDisable: "qrc:/images/contact_window_panel_button_default.svg"
        // sourceOnEnable: "qrc:/images/contact_window_panel_button_enabled.svg"
        source: "qrc:/images/contact_window_panel_button_enabled.svg"
    }


    SwitchButton {
        id: historyCallsButton

        Accessible.role: Accessible.Button
        Accessible.name: "HistoryCallsButton"

        height: parent.height
        width: calculateWidth()

        imageWidth: 24 * SettingsState.scale
        imageHeight: 24 * SettingsState.scale

        anchors.top: parent.top
        anchors.left: contactButton.right

        isChecked: SettingsState.showHistoryWindow


        doWorkOnButtonClick: function () {
            ActionProvider.showHistoryWindow(!isChecked);
        }

        // sourceOnDisable: "qrc:/images/history_calls_window_panel_button_default.svg"
        // sourceOnEnable: "qrc:/images/history_calls_window_panel_button_enabled.svg"
        source: "qrc:/images/history_calls_window_panel_button_enabled.svg"
    }

    SwitchButton {
        id: sendMessageButton

        Accessible.role: Accessible.Button
        Accessible.name: "SendMessageButton"

        height: parent.height
        width: calculateWidth()

        visible: !AppFeatures.hideMessagingWindow && SettingsState.messagingEnable

        imageWidth: 24 * SettingsState.scale
        imageHeight: 24 * SettingsState.scale

        anchors.top: parent.top
        anchors.left: historyCallsButton.right

        isChecked: SettingsState.showMessagingWindow

        doWorkOnButtonClick: function () {
            ActionProvider.showMessagingWindow(!isChecked);
        }

        // sourceOnDisable: "qrc:/images/message_button_on_press.svg"
        // sourceOnEnable: "qrc:/images/message_button_default.svg"
        source: "qrc:/images/message_button_default.svg"
    }

    SwitchButton {
        id: personalStatisticsButton

        Accessible.role: Accessible.Button
        Accessible.name: "PersonalStatisticsButton"

        height: parent.height
        width: calculateWidth()

        visible: !AppFeatures.hideStatisticsWindow

        imageWidth: 24 * SettingsState.scale
        imageHeight: 24 * SettingsState.scale

        anchors.top: parent.top
        anchors.left: sendMessageButton.visible ?  sendMessageButton.right : historyCallsButton.right

        isChecked: SettingsState.showPersonalStatisticsWindow


        doWorkOnButtonClick: function () {
            ActionProvider.showPersonalStatisticsWindow(!isChecked);            
        }

        // sourceOnDisable: "qrc:/images/personal_statistics_window_panel_button_default.svg"
        // sourceOnEnable: "qrc:/images/personal_statistics_window_panel_button_enabled.svg"
        source: "qrc:/images/personal_statistics_window_panel_button_enabled.svg"
    }
}
