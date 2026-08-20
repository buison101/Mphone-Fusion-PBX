import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "activecalls"
import "clipboard"
import "contacts"
import "dialogs"
import "floating"
import "history"
import "incoming"
import "license"
import "main"
import "postprocessing"
import "settings"
import "uicontrols"
import "update"
import "errors"
import "personalstatistics"
import "info"
import "messaging"

Item {
    id: root

    FontLoader {

        source: AppFeatures.osType == OSType.Unix ?  "qrc:/fonts/OpenSans-VariableFont_wdth,wght.ttf" : ""
    }

    Component.onCompleted: {
        mainWindow.showNormal();
        mainWindow.requestActivate();
    }

    MenuBar {
        Menu {
            title: StringStorage.appTitle
            MenuItem {
                text: qsTr("&Quit")
                onTriggered: ActionProvider.tryQuitApplication()
            }
        }
    }

    property bool newInstanceDetected: AppState.newInstanceDetected

    onNewInstanceDetectedChanged: {
        if (newInstanceDetected) {
            mainWindow.showNormal();
            mainWindow.requestActivate();
        }
    }

    //Global shortcuts
    Shortcut {
        enabled: (incomingWindow.visible || smallIncomingWindow.visible) && AppState.activeCall
        sequence: SettingsState.answerShortcutKey
        context: Qt.ApplicationShortcut

        onActivated:{
            ActionProvider.answerCall(AppState.activeCall.id);
            AppLogger.debug("Shortcut: User clicked Answer button");
        }
    }

    Shortcut {
        enabled: AppState.activeCall
        sequence: SettingsState.hangupShortcutKey
        context: Qt.ApplicationShortcut

        onActivated:{
            ActionProvider.hangupCall(AppState.activeCall.id);
            AppLogger.debug("Shortcut: User clicked Hangup button");
        }
    }

    Shortcut {
        enabled: (incomingWindow.visible || smallIncomingWindow.visible) && AppState.activeCall
        sequence: SettingsState.ignoreShortcutKey
        context: Qt.ApplicationShortcut

        onActivated:{
            ActionProvider.ignoreCall(AppState.activeCall.id);
            AppLogger.debug("Shortcut: User clicked Ignore button");
        }
    }


    Shortcut {
        enabled: true
        sequence: "Ctrl+Q"
        context: Qt.ApplicationShortcut

        onActivated:{
            if (!AppState.activeCall) {
                enabled = false;
            }
            ActionProvider.tryQuitApplication();
        }
    }


    Shortcut {
        enabled: !mainWindow.compactWindowMode
        sequence: "Ctrl+1"
        context: Qt.ApplicationShortcut

        onActivated: {
            mainWindow.requestActivate();
        }
    }

    Shortcut {
        enabled: !mainWindow.compactWindowMode
        sequence: "Ctrl+2"
        context: Qt.ApplicationShortcut

        onActivated:{
            activeCallWindow.requestActivate();
            if (SettingsState.twoWindowMode) {
                ActionProvider.showActiveCallsWindow(true);
            }
        }
    }

    Shortcut {
        enabled: !mainWindow.compactWindowMode
        sequence: "Ctrl+3"
        context: Qt.ApplicationShortcut

        onActivated:{
            contactsWindow.requestActivate();
            if (SettingsState.twoWindowMode) {
                ActionProvider.showContactsWindow(true);
            }
        }
    }

    Shortcut {
        enabled: !mainWindow.compactWindowMode
        sequence: "Ctrl+4"
        context: Qt.ApplicationShortcut

        onActivated:{
            historyWindow.requestActivate();
            if (SettingsState.twoWindowMode) {
                ActionProvider.showHistoryWindow(true);
            }
        }
    }

    Shortcut {
        enabled: SettingsState.messagingEnable && !mainWindow.compactWindowMode
        sequence: "Ctrl+5"
        context: Qt.ApplicationShortcut

        onActivated:{
            messagingWindow.requestActivate();
            if (SettingsState.twoWindowMode) {
                ActionProvider.showMessagingWindow(true);
            }
        }
    }

    Shortcut {
        enabled: SettingsState.twoWindowMode
        sequence: SettingsState.messagingEnable ? "Ctrl+6" : "Ctrl+5"
        context: Qt.ApplicationShortcut

        onActivated: {
            personalStatisticsWindow.requestActivate();
            ActionProvider.showPersonalStatisticsWindow(true);
        }
    }

    BorderlessWindow {
        id: mainWindow

        x: AppState.mainWindowX
        y: AppState.mainWindowY

        titleButtonImageColor: ColorStorage.mainWindowTitleAndIcons
        titleButtonColorOnHover: ColorStorage.mainWindowTitleButtonOnHover
        titleButtonColorOnPress: ColorStorage.mainWindowTitleButtonOnPress
        titleButtonSize: 39 * SettingsState.scale

        height: AppFeatures.osType === OSType.MacOS ? (mainWindow.compactWindowMode ? 269 * SettingsState.scale : 644 * SettingsState.scale) : null
        width: AppFeatures.osType === OSType.MacOS ? 362 * SettingsState.scale : null

        mouseAreaLeftMargin: 40 * SettingsState.scale
        alwaysOnTop: SettingsState.alwaysOnTop
        disableMinimizeButton: AppFeatures.osType == OSType.Unix

        function mainWindowVisibility() {
            return mainWindow.visibility !== Window.Minimized && mainWindow.visibility !== Window.Hidden;
        }

        property bool mainWindowVisible: {
            if (AppState.instanceWillDestroy)
            {
                return false;
            }

            if (AppState.activeCall && AppState.showMainWindowOnIncoming &&
                    (AppState.activeCall.direction == SipCall.Incoming ||
                    (AppState.activeCall.direction == SipCall.Outgoing && AppState.activeCall.isClickToCall)) &&
                    AppState.activeCall.status == SipCall.Answered) {
                mainWindow.showNormal();
                mainWindow.requestActivate();
                return true;
            }

            if (AppState.activeCall && AppState.showMainWindowOnOutgoing &&
                    (AppState.activeCall.direction == SipCall.Outgoing ||
                     AppState.activeCall.direction == SipCall.Incoming && AppState.activeCall.isClickToCall)) {
                mainWindow.showNormal();
                mainWindow.requestActivate();
                return true;
            }

            return AppState.showMainWindow;
        }

        property bool activeCallsWindowVisible: activeCallWindow ? activeCallWindow.visible : false
        property bool contactsWindowVisible: contactsWindow ? contactsWindow.visible : false
        property bool historyWindowVisible: historyWindow ? historyWindow.visible : false
        // on MacOS subwindows should be hidden before we can hide main window
        // that's why we can't just use visible property of mainWindow object
        visible: true

        property bool showMainWindow: {
            return mainWindowVisible || activeCallsWindowVisible || contactsWindowVisible || historyWindowVisible;

        }

        onShowMainWindowChanged: {
            if (AppFeatures.osType != OSType.MacOS && AppFeatures.osType != OSType.Unix) {
                return;
            }

            if (showMainWindow) {
                mainWindow.showNormal();
                ActionProvider.showMainWindowSubwindows(true);
            }
            else {
                mainWindow.hide();
            }
        }

        property bool compactWindowMode: SettingsState.compactWindowMode

        onCompactWindowModeChanged: {
            mainWindow.height = mainWindow.compactWindowMode ? 266 * SettingsState.scale + 2 : 644 * SettingsState.scale + 2
        }

        onWidthChanged: {
            mainWindow.width = 364 * SettingsState.scale
        }
        onHeightChanged: {
            mainWindow.height = mainWindow.compactWindowMode ? 266 * SettingsState.scale + 2 : 644 * SettingsState.scale + 2
        }

        content: MainWindow {
            width: 364 * SettingsState.scale
            height: mainWindow.compactWindowMode ? 266 * SettingsState.scale + 2 : 644 * SettingsState.scale + 2

            visible: true
            focus: true

            Shortcut {
                enabled: true
                sequence: "Ctrl+S"
                context: Qt.ApplicationShortcut

                onActivated:{
                    mainWindow.requestActivate();
                    closeMainMenu();
                    ActionProvider.showSettingsWindow(true);
                }
            }

            Shortcut {
                enabled: true
                sequence: "Ctrl+J"
                context: Qt.ApplicationShortcut

                onActivated: {
                    mainWindow.requestActivate();
                    forceFocusOnInput();
                }
            }

            Shortcut {
                enabled: true
                sequence: "Ctrl+K"
                context: Qt.ApplicationShortcut

                onActivated: {
                    mainWindow.requestActivate();
                    openAccountDropdown();
                }
            }

            Shortcut {
                enabled: true
                sequence: "Ctrl+L"
                context: Qt.ApplicationShortcut

                onActivated: {
                    mainWindow.requestActivate();
                    openStatusDropdown();
                }
            }

            Shortcut {
                enabled: !contactsWindow.activeFocus && !historyWindow.activeFocus
                sequence: "Ctrl+F"
                context: Qt.ApplicationShortcut

                onActivated: {
                    mainWindow.requestActivate();
                    openCallForwardDropdown();
                }
            }

            Shortcut {
                enabled: true
                sequence: "Ctrl+E"
                context: Qt.ApplicationShortcut

                onActivated: {
                    mainWindow.requestActivate();
                    openEmailNotificationDropdown();
                }
            }

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Tab"

                onActivated: {
                    if (contactsWindow.visible) {
                        contactsWindow.requestActivate();
                    } else if (historyWindow.visible) {
                        historyWindow.requestActivate();
                    } else if (messagingWindow.visible) {
                        messagingWindow.requestActivate();
                    }
                }
            }

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Shift+Tab"

                onActivated: {
                    if (messagingWindow.visible) {
                        messagingWindow.requestActivate();
                    } else if (historyWindow.visible) {
                        historyWindow.requestActivate();
                    } else if (contactsWindow.visible) {
                        contactsWindow.requestActivate();
                    }
                }
            }
        }

        onXChanged: {
            ActionProvider.sendMainWindowPosition(Qt.point(mainWindow.x, mainWindow.y));
            if (SettingsState.lastFullSizeWindowModeIsTwoWindowMode && SettingsState.compactWindowMode) {
                if (SettingsState.showActiveCallsWindow) {
                    activeCallWindow.x = mainWindow.x + mainWindow.width;
                    activeCallWindow.y = mainWindow.y;
                    ActionProvider.sendActiveCallsWindowPosition(Qt.point(activeCallWindow.x, activeCallWindow.y));
                }

                if (SettingsState.showContactsWindow) {
                    contactsWindow.x = mainWindow.x + mainWindow.width;
                    contactsWindow.y = mainWindow.y;
                    ActionProvider.sendContactsWindowPosition(Qt.point(contactsWindow.x,  contactsWindow.y));
                }

                if (SettingsState.showHistoryWindow) {
                    historyWindow.x = mainWindow.x + mainWindow.width;
                    historyWindow.y = mainWindow.y;
                    ActionProvider.sendHistoryWindowPosition(Qt.point(historyWindow.x,  historyWindow.y));
                }

                if (SettingsState.showPersonalStatisticsWindow) {
                    personalStatisticsWindow.x = mainWindow.x + mainWindow.width;
                    personalStatisticsWindow.y = mainWindow.y;
                    ActionProvider.sendPersonalStatisticsWindowPosition(Qt.point(personalStatisticsWindow.x,  personalStatisticsWindow.y));
                }

                if (SettingsState.showMessagingWindow) {
                    messagingWindow.x = mainWindow.x + mainWindow.width;
                    messagingWindow.y = mainWindow.y;
                    ActionProvider.sendMessagingWindowPosition(Qt.point(messagingWindow.x,  messagingWindow.y));
                }
            }
        }

        onYChanged: {
            ActionProvider.sendMainWindowPosition(Qt.point(mainWindow.x, mainWindow.y));
            if (SettingsState.lastFullSizeWindowModeIsTwoWindowMode && SettingsState.compactWindowMode) {
                if (SettingsState.showActiveCallsWindow) {
                    activeCallWindow.x = mainWindow.x + mainWindow.width;
                    activeCallWindow.y = mainWindow.y;
                    ActionProvider.sendActiveCallsWindowPosition(Qt.point(activeCallWindow.x, activeCallWindow.y));
                }

                if (SettingsState.showContactsWindow) {
                    contactsWindow.x = mainWindow.x + mainWindow.width;
                    contactsWindow.y = mainWindow.y;
                    ActionProvider.sendContactsWindowPosition(Qt.point(contactsWindow.x,  contactsWindow.y));
                }

                if (SettingsState.showHistoryWindow) {
                    historyWindow.x = mainWindow.x + mainWindow.width;
                    historyWindow.y = mainWindow.y;
                    ActionProvider.sendHistoryWindowPosition(Qt.point(historyWindow.x,  historyWindow.y));
                }

                if (SettingsState.showPersonalStatisticsWindow) {
                    personalStatisticsWindow.x = mainWindow.x + mainWindow.width;
                    personalStatisticsWindow.y = mainWindow.y;
                    ActionProvider.sendPersonalStatisticsWindowPosition(Qt.point(personalStatisticsWindow.x,  personalStatisticsWindow.y));
                }

                if (SettingsState.showMessagingWindow) {
                    messagingWindow.x = mainWindow.x + mainWindow.width;
                    messagingWindow.y = mainWindow.y;
                    ActionProvider.sendMessagingWindowPosition(Qt.point(messagingWindow.x,  messagingWindow.y));
                }
            }
        }

        property int mainWindowX: AppState.mainWindowX
        property int mainWindowY: AppState.mainWindowY

        onMainWindowXChanged: {
            if (mainWindow.x !== AppState.mainWindowX) {
                mainWindow.x = AppState.mainWindowX;
            }
        }

        onMainWindowYChanged: {
            if (mainWindow.y !== AppState.mainWindowY) {
                mainWindow.y = AppState.mainWindowY;
            }
        }

        destroyWindowManually: true

        function minimizeWindow() {
            ActionProvider.showMainWindowManually(false);

            if (AppFeatures.osType == OSType.MacOS) {
                ActionProvider.showMainWindowSubwindows(false);
                ActionProvider.showMainWindow(false);
            } else {
                mainWindow.showMinimized();
            }
        }

        function removeFromTaskbarWindow() {
            minimizeWindow();
            if (AppFeatures.osType == OSType.Windows) {
                mainWindow.hide();
            }
        }

        ControlGuiMenuPopup {
            id: controlGuiMenuPopup

            anchors.top: parent.top
            anchors.topMargin: 8 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 10 * SettingsState.scale
        }

        function openControlGuiMenu() {
            controlGuiMenuPopup.open()
        }

        doWorkOnWindowClose: removeFromTaskbarWindow
        doWorkOnWindowMinimized: minimizeWindow
        doWorkOnOpenControlGuiMenu: openControlGuiMenu

        property bool showMainWindowManually:  {
            if (AppState.showMainWindowManually) {
                mainWindow.showNormal();
                mainWindow.requestActivate();
                ActionProvider.showMainWindowManually(false);
                return true;
            }

            return false;
        }

        ConfirmDialog {
            id: quitAppDialog

            width: 363
            height: 115

            x: mainWindow.x + mainWindow.width / 2 - width / 2
            y: mainWindow.y + mainWindow.height / 2 - height / 2

            visible: AppState.showQuitAppDialog

            message: qsTrId("app_quit_dialog_message") + Translator.translate

            onOKAction: function() {
                ActionProvider.confirmQuitApplication(true);
            }

            onCancelAction: function() {
                ActionProvider.confirmQuitApplication(false);
            }
        }

        InfoDialog {
            id: infoDialog

            width: 363
            height: 115

            visible: !AppState.activeCall && !AppState.showPostProcessingWindow && AppState.showRestartOnConfigUpdateDialog
            message: qsTrId("dialog_restart_request").arg(StringStorage.appTitle) + Translator.translate
            buttonText: qsTrId("dialog_restart_button") + Translator.translate

            onVisibleChanged: {
                if (visible) {
                    ActionProvider.appDisableOnTeamConfigUpdate();
                }
            }

            onOKAction: function() {
                ActionProvider.tryRestartApplication(false);
            }
        }

        SystemTrayIcon {
            id: systemTray

            Component.onCompleted: {
                systemTray.show();
            }

            toolTip: AppState.appSystemTrayIconTooltip

            onActivated: {
                mainWindow.show()
                mainWindow.raise()
                mainWindow.requestActivate();

                if(messagingWindow.showMessagingWindow) {
                    messagingWindow.show()
                    messagingWindow.raise()
                }


                if(contactsWindow.showContactsWindow) {
                    contactsWindow.show()
                    contactsWindow.raise()
                }

                if(activeCallWindow.showActiveCallsWindow) {
                    activeCallWindow.show()
                    activeCallWindow.raise()
                }

                if(historyWindow.showHistoryWindow) {
                    historyWindow.show()
                    historyWindow.raise()
                }

                if(personalStatisticsWindow.showPersonalStatisticsWindow) {
                    personalStatisticsWindow.show()
                    personalStatisticsWindow.raise()
                }
            }

            onSettingsWindowActivatedFromTray: {
                mainWindow.show();
                settingsWindow.show();
                settingsWindow.requestActivate();
            }
            onResetWindowsActivatedFromTray: {
                mainWindow.show();
                mainWindow.requestActivate();
            }
        }

        BorderlessWindow {
            id: updateWindow

            x: mainWindow.x + 1 * SettingsState.scale
            y: mainWindow.y + 191 * SettingsState.scale

            visible: AppState.showMainWindowSubwindows && !AppState.instanceWillDestroy
                     && (AppState.updateInfo || AppState.showTeamUpdateDialog)
                     && mainWindow.mainWindowVisibility() && (!AppFeatures.infoWindowOn || AppState.showTeamUpdateDialog)

            beSubWindow: false
            enableMove: true

            disableMinimizeButton: true
            destroyWindowManually: true
            disableCloseButton: false

            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            function updatePosition() {
                x = mainWindow.x + 1 * SettingsState.scale;
                y = mainWindow.y + 191 * SettingsState.scale;
            }

            content: UpdateWindow {
                width: 360 * SettingsState.scale

                property int checkSum: AppState.appVersionStatus + SettingsState.languageModelSelectedIdx * 100

                onVersionChanged: {
                    description = AppState.updateInfo ? AppState.updateInfo.description : "";
                    return;
                }

                onCheckSumChanged: {
                    if (AppState.appVersionStatus == AppVersionStatus.OK) {
                        description = AppState.updateInfo ? AppState.updateInfo.description : "";
                        return;
                    } else {
                        updateLink = AppState.teamSfUpdateLink;
                        title = qsTrId("team_update_unsupported_version_title") + Translator.translate;
                        if (AppState.appVersionStatus == AppVersionStatus.Expired) {
                            description = qsTrId("team_update_critical_update_description") + Translator.translate;
                        } else {
                            description = qsTrId("team_update_warning_update_description").arg(AppState.teamSfUpdateExpirationDate) + Translator.translate;
                        }
                    }
                }
            }

            doWorkOnWindowClose: function() {
                ActionProvider.dismissUpdateDialog();
                x = mainWindow.x + 1 * SettingsState.scale
                y = mainWindow.y + 191 * SettingsState.scale
            }

            onVisibleChanged: {
                if (visible) {
                    updatePosition();
                }
            }
        }

        BorderlessWindow {
            id: infoWindow

            x: mainWindow.x + 1 * SettingsState.scale
            y: mainWindow.y + 191 * SettingsState.scale
            visible: AppState.showMainWindowSubwindows && !AppState.instanceWillDestroy
                     && AppFeatures.infoWindowOn && AppState.showInfoWindow
                     && mainWindow.mainWindowVisibility() && (AppState.updateInfo ? AppState.updateInfo.enableButton : false)

            beSubWindow: false
            enableMove: true

            disableMinimizeButton: true
            destroyWindowManually: true
            disableCloseButton: false

            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            function updatePosition() {
                x = mainWindow.x + 1 * SettingsState.scale;
                y = mainWindow.y + 191 * SettingsState.scale;
            }

            content: InfoWindow {
                width: 360 * SettingsState.scale
                height: 260 * SettingsState.scale
            }

            doWorkOnWindowClose: function() {
                ActionProvider.dismissInfoWindow();
                x = mainWindow.x + 1 * SettingsState.scale
                y = mainWindow.y + 191 * SettingsState.scale
            }

            onVisibleChanged: {
                if (visible) {
                    updatePosition();
                }
            }
        }


        BorderlessWindow {
            id: licenseWindow

            x: mainWindow.x + 1 * SettingsState.scale
            y: mainWindow.y + 191 * SettingsState.scale

            visible: AppState.showMainWindowSubwindows && AppState.showLicenseDialog
                     && !AppState.instanceWillDestroy
                     && mainWindow.mainWindowVisibility()
                    // && SettingsState.displayLicenseWillExpireSoonWarning

            beSubWindow: false
            enableMove: true

            disableMinimizeButton: true
            destroyWindowManually: true
            disableCloseButton: false

            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            titleButtonSize: 31 * SettingsState.scale

            function updatePosition() {
                x = mainWindow.x + 1 * SettingsState.scale;
                y = mainWindow.y + 191 * SettingsState.scale;
            }

            content: LicenseWindow {
                width: 360 * SettingsState.scale
            }

            doWorkOnWindowClose: function() {
                ActionProvider.dismissLicenseDialog();
                x = mainWindow.x + 1 * SettingsState.scale
                y = mainWindow.y + 191 * SettingsState.scale
            }

            onVisibleChanged: {
                if (visible) {
                    updatePosition();
                }
            }
        }

        BorderlessWindow {
            id: sipRegErrorWindow

            x: mainWindow.x + 1 * SettingsState.scale
            y: mainWindow.y + 191 * SettingsState.scale

            visible: AppState.showMainWindowSubwindows && AppState.showSipRegErrorDialog && !AppState.instanceWillDestroy
                     && mainWindow.mainWindowVisibility()

            beSubWindow: false
            enableMove: true

            disableMinimizeButton: true
            destroyWindowManually: true
            disableCloseButton: false

            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            titleButtonSize: 31 * SettingsState.scale

            property bool refocus: true

            function updatePosition() {
                x = mainWindow.x + 1 * SettingsState.scale;
                y = mainWindow.y + 191 * SettingsState.scale;
            }

            content: ErrorWindow {
                title: qsTrId("telefony_provider_error") + Translator.translate
                description: {
                    if (AppState.sipRegErrorDescription == "") {
                        return "";
                    } else {
                        return "SIP " + AppState.sipRegErrorCode + " - " + AppState.sipRegErrorDescription + " (" + AppState.sipRegErrorAccountName  + ")"
                    }
                }

                errLink: AppState.sipRegErrorLink
                errLinkText: qsTrId("license_info_error_link_desc") + Translator.translate
                errLinkEnable: true

                width: 360 * SettingsState.scale
            }

            onActiveFocusChanged: {
                if (!activeFocus) {
                    return;
                }
                if (refocus && activeFocus) {
                    mainWindow.requestActivate();
                    refocus = false;
                }
            }

            onVisibleChanged: {
                if (!visible) {
                    refocus = true;
                } else {
                    updatePosition();
                }
            }

            doWorkOnWindowClose: function() {
                ActionProvider.dismissSipRegErrorDialog()
                x = mainWindow.x + 1 * SettingsState.scale
                y = mainWindow.y + 191 * SettingsState.scale
            }
        }

        BorderlessWindow {
            id: callMakeErrorWindow

            x: mainWindow.x + 1 * SettingsState.scale
            y: mainWindow.y + 191 * SettingsState.scale

            visible: AppState.showMainWindowSubwindows && AppState.showCallMakeErrorDialog && !AppState.instanceWillDestroy
                     && mainWindow.mainWindowVisibility()

            beSubWindow: false
            enableMove: true

            disableMinimizeButton: true
            destroyWindowManually: true
            disableCloseButton: false

            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            titleButtonSize: 31 * SettingsState.scale

            property bool refocus: true

            function updatePosition() {
                x = mainWindow.x + 1 * SettingsState.scale;
                y = mainWindow.y + 191 * SettingsState.scale;
            }

            content: ErrorWindow {
                title: qsTrId("telefony_provider_error") + Translator.translate
                description: "SIP " + AppState.callMakeErrorCode + " - " + AppState.callMakeErrorText + " (" + AppState.callMakeErrorAccountName  + ")"

                errLink: AppState.callMakeErrorLink
                errLinkText: qsTrId("license_info_error_link_desc") + Translator.translate;
                errLinkEnable: true

                width: 360 * SettingsState.scale
            }

            onActiveFocusChanged: {
                if (!activeFocus) {
                    return;
                }
                if (refocus && activeFocus) {
                    mainWindow.requestActivate();
                    refocus = false;
                }
            }

            onVisibleChanged: {
                if (!visible) {
                    refocus = true;
                } else {
                    updatePosition();
                }
            }

            doWorkOnWindowClose: function() {
                ActionProvider.dismissCallMakeErrorDialog();
                x = mainWindow.x + 1 * SettingsState.scale
                y = mainWindow.y + 191 * SettingsState.scale
            }
        }

        BorderlessWindow {
            id: invalidAudioDeviceErrorWindow

            x: mainWindow.x + 1 * SettingsState.scale
            y: mainWindow.y + 191 * SettingsState.scale

            visible: AppState.showMainWindowSubwindows && AppState.showInvalidAudioDeviceErrorDialog && !AppState.instanceWillDestroy
                     && mainWindow.mainWindowVisibility()

            beSubWindow: false
            enableMove: true

            disableMinimizeButton: true
            destroyWindowManually: true
            disableCloseButton: false

            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            titleButtonSize: 31 * SettingsState.scale

            property bool refocus: true

            function updatePosition() {
                x = mainWindow.x + 1 * SettingsState.scale;
                y = mainWindow.y + 191 * SettingsState.scale;
            }

            content: ErrorWindow {
                property bool micDisabledOnSysLvl: AppState.callMakeAudioError == CallMakeAudioError.MicDisabledBySystem
                title: micDisabledOnSysLvl ? qsTrId("micro_disabled_by_system_title") + Translator.translate : qsTrId("audio_device_error_title") + Translator.translate

                description: micDisabledOnSysLvl ? qsTrId("micro_disabled_by_system_description")  + Translator.translate: qsTrId("audio_device_error_text").arg(AppState.callMakeAudioErrorCode) + Translator.translate
                errLink: StringStorage.getHelpAudioDeviceErrorLink(SettingsState.languageIsoCode) + Translator.translate
                errLinkText: qsTrId("audio_device_error_link_text") + Translator.translate
                errLinkEnable: !micDisabledOnSysLvl

                width: 360 * SettingsState.scale
            }

            onActiveFocusChanged: {
                if (!activeFocus) {
                    return;
                }
                if (refocus && activeFocus) {
                    mainWindow.requestActivate();
                    refocus = false;
                }
            }

            onVisibleChanged: {
                if (!visible) {
                    refocus = true;
                } else {
                    updatePosition();
                }
            }

            doWorkOnWindowClose: function() {
                ActionProvider.dismissInvalidAudioDeviceErrorDialog();
                x = mainWindow.x + 1 * SettingsState.scale
                y = mainWindow.y + 191 * SettingsState.scale
            }
        }

        ApplicationWindow {
            id: settingsWindow

            visible: AppState.showMainWindowSubwindows && SettingsState.showSettings
                     && !AppState.instanceWillDestroy

            flags: {
                return Qt.Dialog | Qt.CustomizeWindowHint | Qt.WindowTitleHint |
                        Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint | Qt.MSWindowsFixedSizeDialogHint
            }

            Component.onCompleted: {
                setX(Screen.width / 2 - width / 2)
                if (SettingsState.desktopYPosition > 0) {
                    setY(SettingsState.desktopYPosition + 30 + (Screen.height - SettingsState.desktopYPosition - 30) / 2 - height / 2)
                } else {
                    setY(SettingsState.desktopYPosition + 30 + (SettingsState.desktopHeight - 30) / 2 - height / 2)
                }
            }
            width: settingsWindowContent.width
            height: settingsWindowContent.height

            minimumWidth: width
            minimumHeight: height

            maximumWidth: minimumWidth
            maximumHeight: minimumHeight

            title: qsTrId("settings_window_title") + " " + AppState.appVersion + Translator.translate

            SettingsWindow {
                id: settingsWindowContent

                width: 1026
                height: {
                    if (745 > SettingsState.desktopHeight - 30) {
                        return SettingsState.desktopHeight - 30
                    } else {
                        return 745
                    }
                }

                focus: true
            }

            property bool instanceWillDestroy: AppState.instanceWillDestroy

            onInstanceWillDestroyChanged: {
                if (instanceWillDestroy) {
                    settingsWindow.destroy();
                }
            }

            onClosing: {
                ActionProvider.saveSettingsUpdates(false);
                close.accepted = false;
                if (!AppState.activeCall) {
                    ActionProvider.stopPlayRingtone();
                }
            }

            ConfirmDialog {
                id: discardSettingsChangesDialog

                width: 363
                height: 115

                x: settingsWindow.x + settingsWindow.width / 2 - width / 2
                y: settingsWindow.y + settingsWindow.height / 2 - height / 2

                visible: SettingsState.showDiscardSettingsChangesDialog

                message: qsTrId("settings_dialog_discard_changes_message") + Translator.translate

                onOKAction: function() {
                    ActionProvider.confirmDiscardSettingsChanges(true);
                }

                onCancelAction: function() {
                    ActionProvider.confirmDiscardSettingsChanges(false);
                }
            }

            ConfirmDialogExtended {
                id: discardSipAccountChangesDialog

                width: 363
                height: 115

                x: settingsWindow.x + settingsWindow.width / 2 - width / 2
                y: settingsWindow.y + settingsWindow.height / 2 - height / 2

                visible: SettingsState.showSaveSipAccountChangesDialog

                message: {
                    if (SettingsState.sipAccount) {
                        return qsTrId("settings_sip_dialog_save_changes_message") + " "
                                + SettingsState.sipAccount.name + " ?" + Translator.translate;
                    }
                    else {
                        return qsTrId("settings_sip_dialog_save_changes_message") + "?" + Translator.translate;
                    }
                }

                onYesAction: function func() {
                    ActionProvider.confirmSaveSipAccountChanges(true);
                }

                onNoAction: function func() {
                    ActionProvider.confirmSaveSipAccountChanges(false);
                }

                onCancelAction: function func() {
                    ActionProvider.cancelSaveSipAccountChanges();
                }
            }

            SetLicenseDialog {
                id: licenseDialog

                width: 363
                height: 115

                x: mainWindow.x + mainWindow.width / 2 - width / 2
                y: mainWindow.y + mainWindow.height / 2 - height / 2

                visible: SettingsState.showSetLicenseKeyDialog

                onOKAction: function() {
                    ActionProvider.checkLicenseKey(key.trim());
                    key = "";
                }

                onCancelAction: function() {
                    ActionProvider.discardLicenseKey();
                }
            }

            RegisterDialog {
                id: registerDialog

                width: 363
                height: 170

                visible: SettingsState.showRegisterSipAccountDialog

                x: settingsWindow.x + settingsWindow.width / 2 - width / 2
                y: settingsWindow.y + settingsWindow.height / 2 - height / 2

                property int registrationStatus: SettingsState.registrationStatus
                property string registrationCode: SettingsState.registrationCode
                property string registrationError: SettingsState.registrationError

                onRegistrationStatusChanged: {
                    switch (registrationStatus) {

                    case RegistrationStatus.Unregistered:
                        registerDialog.message = qsTrId("register_dialog_status_check_connection") + Translator.translate;
                        registerDialog.code = "";
                        registerDialog.description = "";
                        break;

                    case RegistrationStatus.RegisterError:
                        registerDialog.message = qsTrId("register_dialog_status_reg_error") + Translator.translate;
                        registerDialog.code = registrationCode == "0" ? "" : registrationCode;
                        registerDialog.description = registrationError;
                        break;

                    case RegistrationStatus.Registered:
                        registerDialog.message = qsTrId("register_dialog_status_registered") + Translator.translate;
                        registerDialog.code = "";
                        registerDialog.description = "";
                        break;
                    }
                }

                onCloseAction: function func() {
                    ActionProvider.endSipAccountRegistration();
                }
            }

            ConfirmDialog {
                id: removeAccountsDialog

                width: 363
                height: 122

                x: settingsWindow.x + settingsWindow.width / 2 - width / 2
                y: settingsWindow.y + settingsWindow.height / 2 - height / 2

                visible: SettingsState.showRemoveSipAccountsDialog

                message: {
                    if (SettingsState.allSipAccountsSelectedIndexes.length == 1) {
                        return qsTrId("remove_single_account_question") + "?" + Translator.translate;
                    }

                    return qsTrId("remove_multiple_accounts_question") + "?" + Translator.translate;
                }

                onOKAction: function func() {
                    ActionProvider.confirmRemoveSipAccounts(true);
                }

                onCancelAction: function func() {
                    ActionProvider.confirmRemoveSipAccounts(false);
                }
            }

            ConfirmDialog {
                id: removeExternalEventReceiversDialog

                width: 363
                height: 122

                x: settingsWindow.x + settingsWindow.width / 2 - width / 2
                y: settingsWindow.y + settingsWindow.height / 2 - height / 2

                visible: SettingsState.showRemoveExternalEventReceiverDialog

                message: {
                    if (SettingsState.allExternalEventReceiversSelectedIndexes.length == 1) {
                        return qsTrId("remove_single_external_event_receiver_question") + "?" + Translator.translate;
                    }

                    return qsTrId("remove_multiple_external_event_receivers_question") + "?" + Translator.translate;
                }

                onOKAction: function func() {
                    ActionProvider.confirmRemoveExternalEventReceivers(true);
                }

                onCancelAction: function func() {
                    ActionProvider.confirmRemoveExternalEventReceivers(false);
                }
            }

            AddNewExternalEventReceiverDialog {
                id: addNewExternalEventReceiverDialog

                width: 500
                height: 750

                x: settingsWindow.x + settingsWindow.width / 2 - width / 2
                y: settingsWindow.y + settingsWindow.height / 2 - height / 2

                visible: SettingsState.showAddNewExternalEventReceiverDialog

                onOKAction: function func() {
                    ActionProvider.confirmAddNewExternalEventReceiver(true);
                }

                onCancelAction: function func() {
                    ActionProvider.confirmAddNewExternalEventReceiver(false);
                }
            }
        }

        InfoDialog {
            id: rebootApplicationDialog

            width: 363
            height: 115

            x: settingsWindow.x + settingsWindow.width / 2 - width / 2
            y: settingsWindow.y + settingsWindow.height / 2 - height / 2

            visible: SettingsState.showRebootAppDialog

            message: qsTrId("settings_dialog_reboot_cuz_scale_changed_message").arg(StringStorage.appTitle) + Translator.translate

            onOKAction: function() {
                ActionProvider.tryQuitApplication();
            }
        }

        BorderlessWindow {
            id: activeCallWindow

            property bool showActiveCallsWindow: SettingsState.showActiveCallsWindow

            titleButtonImageColor: ColorStorage.secondaryWindowTitleAndIcons
            titleButtonColorOnHover: ColorStorage.secondaryWindowTitleButtonOnHover
            titleButtonColorOnPress: ColorStorage.secondaryWindowTitleButtonOnPress
            titleButtonSize: 39 * SettingsState.scale
            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Tab"

                onActivated: {
                    if (contactsWindow.visible) {
                        contactsWindow.requestActivate();
                    } else if (historyWindow.visible) {
                        historyWindow.requestActivate();
                    } else if (messagingWindow.visible) {
                        messagingWindow.requestActivate();
                    } else {
                        mainWindow.requestActivate();
                    }
                }
            }

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Shift+Tab"

                onActivated: {
                    mainWindow.requestActivate();
                }
            }

            alwaysOnTop: SettingsState.alwaysOnTop

            visible: AppState.showMainWindowSubwindows && showActiveCallsWindow
                     && !AppState.instanceWillDestroy && !mainWindow.compactWindowMode

            onVisibleChanged: {
                if (AppFeatures.osType == OSType.MacOS && !AppState.showMainWindowSubwindows) {
                    return;
                }

                if (!visible) {
                    unstick();
                } else {
                    if (SettingsState.twoWindowMode) {
                        mainWindow.stickyProps.buddyRight = activeCallWindow;
                        activeCallWindow.stickyProps.buddyLeft = mainWindow;
                        activeCallWindow.stickyProps.leftAsSlave = true;

                    }
                    tryToStick();
                }
            }

            enableMove: !SettingsState.twoWindowMode

            disableMinimizeButton: true
            beSubWindow: true

            stickyBuddies: [mainWindow, contactsWindow, historyWindow, messagingWindow, personalStatisticsWindow]

            onXChanged: {
                ActionProvider.sendActiveCallsWindowPosition(Qt.point(activeCallWindow.x, activeCallWindow.y));

                // if user is pressing mouse button and moving the window =>
                // check for stick conditions
                //second condition is checking after we change multi window mode to two window mode
                if (activeFocus || (SettingsState.twoWindowMode && (AppFeatures.osType != OSType.MacOS))) {
                    tryToStick();
                }
            }

            onYChanged: {
                ActionProvider.sendActiveCallsWindowPosition(Qt.point(activeCallWindow.x, activeCallWindow.y));

                // if user is pressing mouse button and moving the window =>

                //second condition is checking after we change multi window mode to two window mode
                if (activeFocus || (SettingsState.twoWindowMode && (AppFeatures.osType != OSType.MacOS))) {
                    tryToStick();
                }
            }

            property int activeCallsWindowX: AppState.activeCallsWindowX
            property int activeCallsWindowY: AppState.activeCallsWindowY

            onActiveCallsWindowXChanged: {
                if (activeCallWindow.x !== AppState.activeCallsWindowX) {
                    activeCallWindow.x = AppState.activeCallsWindowX;
                    tryToStick();
                }
            }

            onActiveCallsWindowYChanged: {
                if (activeCallWindow.y !== AppState.activeCallsWindowY) {
                    activeCallWindow.y = AppState.activeCallsWindowY;
                    tryToStick();
                }
            }

            Component.onCompleted: {
                activeCallWindow.x = AppState.activeCallsWindowX;
                activeCallWindow.y = AppState.activeCallsWindowY;

                if (showActiveCallsWindow) {
                    tryToStick();
                }
            }

            destroyWindowManually: true

            doWorkOnWindowClose: function() {
                ActionProvider.showActiveCallsWindow(false);
            }

            content: ActiveCallsWindow {
                id: screens

                width: 362 * SettingsState.scale
                height: 644 * SettingsState.scale

                visible: true

                property var activeCall: AppState.activeCall
                property var lastFinishedCall: AppState.lastFinishedCall
                property bool playRecord: AppState.playRecord

                function updateScreens() {
                    if (AppState.activeCall) {
                        screens.currentScreen = screens.multicalls;
                        return;
                    }

                    if (!AppState.activeCall && AppState.lastFinishedCall) {
                        screens.currentScreen = screens.multicallsEnd;
                        return;
                    }
                }

                onActiveCallChanged: {
                    updateScreens();
                }

                onLastFinishedCallChanged: {
                    updateScreens();
                }

                onPlayRecordChanged: {
                    if (playRecord) {
                        screens.currentScreen = screens.recordPlay;
                    }
                    else {
                        screens.currentScreen = screens.calls;
                        updateScreens();
                    }
                }
            }
        }

        BorderlessWindow {
            id: contactsWindow
            width: mainWindow.width
            height: mainWindow.height
            property bool showContactsWindow: SettingsState.showContactsWindow

            titleButtonImageColor: ColorStorage.secondaryWindowTitleAndIcons
            titleButtonColorOnHover: ColorStorage.secondaryWindowTitleButtonOnHover
            titleButtonColorOnPress: ColorStorage.secondaryWindowTitleButtonOnPress
            titleButtonSize: 39 * SettingsState.scale
            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Tab"

                onActivated: {
                    if (historyWindow.visible) {
                        historyWindow.requestActivate();
                    } else if (messagingWindow.visible) {
                        messagingWindow.requestActivate();
                    } else {
                        mainWindow.requestActivate();
                    }
                }
            }

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Shift+Tab"

                onActivated: {
                    mainWindow.requestActivate();
                }
            }

            visible: AppState.showMainWindowSubwindows && showContactsWindow
                     && !AppState.instanceWillDestroy && !mainWindow.compactWindowMode

            alwaysOnTop: SettingsState.alwaysOnTop

            enableMove: !SettingsState.twoWindowMode

            onVisibleChanged: {
                if (AppFeatures.osType == OSType.MacOS && !AppState.showMainWindowSubwindows) {
                    return;
                }

                if (!visible) {
                    unstick();
                } else {
                    if (SettingsState.twoWindowMode) {
                        mainWindow.stickyProps.buddyRight = contactsWindow;
                        contactsWindow.stickyProps.buddyLeft = mainWindow;
                        contactsWindow.stickyProps.leftAsSlave = true;
                    }
                    tryToStick();
                }
            }

            disableMinimizeButton: true
            beSubWindow: true

            destroyWindowManually: true

            doWorkOnWindowClose: function() {
                ActionProvider.showContactsWindow(false);
            }

            stickyBuddies: [mainWindow, activeCallWindow, historyWindow, messagingWindow, personalStatisticsWindow]

            onXChanged: {
                ActionProvider.sendContactsWindowPosition(Qt.point(contactsWindow.x, contactsWindow.y));

                // if user is pressing mouse button and moving the window =>
                // check for stick conditions
                //second condition is checking after we change multi window mode to two window mode
                if (activeFocus || (SettingsState.twoWindowMode && (AppFeatures.osType != OSType.MacOS))) {
                    tryToStick();
                }
            }

            onYChanged: {
                ActionProvider.sendContactsWindowPosition(Qt.point(contactsWindow.x, contactsWindow.y));

                // if user is pressing mouse button and moving the window =>
                // check for stick conditions
                //second condition is checking after we change multi window mode to two window mode
                if (activeFocus || (SettingsState.twoWindowMode && (AppFeatures.osType != OSType.MacOS))) {
                    tryToStick();
                }
            }

            property int contactsWindowX: AppState.contactsWindowX
            property int contactsWindowY: AppState.contactsWindowY

            onContactsWindowXChanged: {
                if (contactsWindow.x !== AppState.contactsWindowX) {
                    contactsWindow.x = AppState.contactsWindowX;
                    tryToStick();
                }
            }

            onContactsWindowYChanged: {
                if (contactsWindow.y !== AppState.contactsWindowY) {
                    contactsWindow.y = AppState.contactsWindowY;
                    tryToStick();
                }
            }

            Component.onCompleted: {
                contactsWindow.x = AppState.contactsWindowX;
                contactsWindow.y = AppState.contactsWindowY;

                if (showContactsWindow) {
                    tryToStick();
                }
            }

            content: ContactsWindow {
                width: AppState.contactsWindowWidth * SettingsState.scale
                height: 644 * SettingsState.scale

                visible: true
            }

            ConfirmDialog {
                id: deleteContactDialog

                width: 363
                height: 115

                x: contactsWindow.x + contactsWindow.width / 2 - width / 2
                y: contactsWindow.y + contactsWindow.height / 2 - height / 2

                visible: SettingsState.showDeleteContactDialog

                message: qsTrId("contacts_dialog_delete_contact_message") + "?" + Translator.translate

                onOKAction: function() {
                    ActionProvider.confirmDeleteContact(true);
                }

                onCancelAction: function() {
                    ActionProvider.confirmDeleteContact(false);
                }
            }

            ConfirmDialog {
                id: deleteAllContactsDialog

                width: 363
                height: 115

                x: contactsWindow.x + contactsWindow.width / 2 - width / 2
                y: contactsWindow.y + contactsWindow.height / 2 - height / 2

                visible: SettingsState.showDeleteAllContactsDialog

                message: qsTrId("contacts_dialog_delete_all_contacts_message") + "?" + Translator.translate

                textOKButton: qsTrId("dialog_button_yes") + Translator.translate
                textCancelButton: qsTrId("dialog_button_no") + Translator.translate

                onOKAction: function() {
                    ActionProvider.deleteAllDataContacts(true);
                }

                onCancelAction: function() {
                    ActionProvider.deleteAllDataContacts(false);
                }
            }
        }

        AddNewContactDialog {
            id: addNewContactDialog

            width: 363
            height: AppFeatures.osType == OSType.Unix ? 592 : 572

            x: contactsWindow.x + contactsWindow.width / 2 - width / 2
            y: contactsWindow.y + contactsWindow.height / 2 - height / 2

            visible: SettingsState.showAddNewContactDialog

            onOKAction: function func() {
                ActionProvider.confirmAddNewContact(true);
            }

            onCancelAction: function func() {
                ActionProvider.confirmAddNewContact(false);
            }
        }

        BorderlessWindow {
            id: historyWindow
            property bool showHistoryWindow: SettingsState.showHistoryWindow

            titleButtonImageColor: ColorStorage.secondaryWindowTitleAndIcons
            titleButtonColorOnHover: ColorStorage.secondaryWindowTitleButtonOnHover
            titleButtonColorOnPress: ColorStorage.secondaryWindowTitleButtonOnPress
            titleButtonSize: 39 * SettingsState.scale
            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            visible: AppState.showMainWindowSubwindows && showHistoryWindow
                     && !AppState.instanceWillDestroy && !mainWindow.compactWindowMode

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Tab"

                onActivated: {
                    if (messagingWindow.visible) {
                        messagingWindow.requestActivate();
                    } else {
                        mainWindow.requestActivate();
                    }
                }
            }

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Shift+Tab"

                onActivated: {
                    if (contactsWindow.visible) {
                        contactsWindow.requestActivate();
                    } else {
                        mainWindow.requestActivate();
                    }
                }
            }

            onVisibleChanged: {
                if (AppFeatures.osType == OSType.MacOS && !AppState.showSubwindows) {
                    return;
                }

                if (!visible) {
                    unstick();
                } else {
                    if (SettingsState.twoWindowMode) {
                        mainWindow.stickyProps.buddyRight = historyWindow;
                        historyWindow.stickyProps.buddyLeft = mainWindow;
                        historyWindow.stickyProps.leftAsSlave = true;

                    }
                    tryToStick();
                }
            }

            disableMinimizeButton: true
            beSubWindow: true
            alwaysOnTop: SettingsState.alwaysOnTop

            enableMove: !SettingsState.twoWindowMode

            destroyWindowManually: true

            doWorkOnWindowClose: function() {
                ActionProvider.showHistoryWindow(false);
            }

            stickyBuddies: [mainWindow, activeCallWindow, contactsWindow, messagingWindow, personalStatisticsWindow]

            onXChanged: {
                ActionProvider.sendHistoryWindowPosition(Qt.point(historyWindow.x, historyWindow.y));

                // if user is pressing mouse button and moving the window =>
                // check for stick conditions
                //second condition is checking after we change multi window mode to two window mode
                if (activeFocus || (SettingsState.twoWindowMode && (AppFeatures.osType != OSType.MacOS))) {
                    tryToStick();
                }
            }

            onYChanged: {
                ActionProvider.sendHistoryWindowPosition(Qt.point(historyWindow.x, historyWindow.y));

                // if user is pressing mouse button and moving the window =>
                // check for stick conditions
                //second condition is checking after we change multi window mode to two window mode
                if (activeFocus || (SettingsState.twoWindowMode && (AppFeatures.osType != OSType.MacOS))) {
                    tryToStick();
                }
            }

            property int historyWindowX: AppState.historyWindowX
            property int historyWindowY: AppState.historyWindowY

            onHistoryWindowXChanged: {
                if (historyWindow.x !== AppState.historyWindowX) {
                    historyWindow.x = AppState.historyWindowX;
                    tryToStick();
                }
            }

            onHistoryWindowYChanged: {
                if (historyWindow.y !== AppState.historyWindowY) {
                    historyWindow.y = AppState.historyWindowY;
                    tryToStick();
                }
            }

            Component.onCompleted: {
                historyWindow.x = AppState.historyWindowX;
                historyWindow.y = AppState.historyWindowY;

                if (showHistoryWindow) {
                    tryToStick();
                }
            }

            content: HistoryWindow {
                width: 362 * SettingsState.scale
                height: 644 * SettingsState.scale

                visible: true
            }

            ConfirmDialog {
                id: deleteHistoryDialog

                width: 363
                height: 115

                x: contactsWindow.x + contactsWindow.width / 2 - width / 2
                y: contactsWindow.y + contactsWindow.height / 2 - height / 2

                visible: SettingsState.showDeleteHistoryDialog

                message: qsTrId("contacts_dialog_delete_history_message") + "?" + Translator.translate

                textOKButton: qsTrId("dialog_button_yes") + Translator.translate
                textCancelButton: qsTrId("dialog_button_no") + Translator.translate

                onOKAction: function() {
                    ActionProvider.deleteAllDataHistory(true);
                }

                onCancelAction: function() {
                    ActionProvider.deleteAllDataHistory(false);
                }
            }
        }

        BorderlessWindow {
            id: messagingWindow
            stickyBuddies: [mainWindow, contactsWindow, activeCallWindow, historyWindow, personalStatisticsWindow]

            property bool showMessagingWindow: SettingsState.showMessagingWindow
            property bool messagingEnable: SettingsState.messagingEnable

            titleButtonImageColor: ColorStorage.secondaryWindowTitleAndIcons
            titleButtonColorOnHover: ColorStorage.secondaryWindowTitleButtonOnHover
            titleButtonColorOnPress: ColorStorage.secondaryWindowTitleButtonOnPress
            titleButtonSize: 39 * SettingsState.scale
            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            visible: AppState.showMainWindowSubwindows && showMessagingWindow && !AppState.instanceWillDestroy
                     && !AppFeatures.hideMessagingWindow && !mainWindow.compactWindowMode
                     && messagingEnable

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Tab"

                onActivated: {
                    mainWindow.requestActivate();
                }
            }

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Shift+Tab"

                onActivated: {
                    if (historyWindow.visible) {
                        historyWindow.requestActivate();
                    } else if (contactsWindow.visible) {
                        contactsWindow.requestActivate();
                    } else {
                        mainWindow.requestActivate();
                    }
                }
            }

            Connections{
                target: AppState
                onMessagingWindowFocusChanged: {
                    messagingWindow.requestActivate();
                }
            }

            onMessagingEnableChanged: {
                //Fixed the display of the message window on top of the settings window
                ActionProvider.showMessagingWindow(false);
            }

            onVisibleChanged: {
                if (AppFeatures.osType == OSType.MacOS && !AppState.showSubwindows) {
                    return;
                }

                if (!visible) {
                    unstick();
                } else {
                    if (SettingsState.twoWindowMode) {
                        mainWindow.stickyProps.buddyRight = messagingWindow;
                        messagingWindow.stickyProps.buddyLeft = mainWindow;
                        messagingWindow.stickyProps.leftAsSlave = true;
                    }
                    tryToStick();
                }
            }

            disableMinimizeButton: true
            beSubWindow: true
            alwaysOnTop: SettingsState.alwaysOnTop

            enableMove: !SettingsState.twoWindowMode

            Component.onCompleted: {
                messagingWindow.x = AppState.messagingWindowX;
                messagingWindow.y = AppState.messagingWindowY;
                tryToStick();
            }

            content: MessagingWindow {
                width: 362 * SettingsState.scale
                height: 644 * SettingsState.scale
            }

            property int messagingWindowX: AppState.messagingWindowX
            property int messagingWindowY: AppState.messagingWindowY

            onXChanged: {
                ActionProvider.sendMessagingWindowPosition(Qt.point(messagingWindow.x, messagingWindow.y));
                // if user is pressing mouse button and moving the window =>
                // check for stick conditions
                //second condition is checking after we change multi window mode to two window mode
                if (activeFocus || (SettingsState.twoWindowMode && (AppFeatures.osType != OSType.MacOS))) {
                    tryToStick();
                }
            }

            onYChanged: {
                ActionProvider.sendMessagingWindowPosition(Qt.point(messagingWindow.x, messagingWindow.y));
                // if user is pressing mouse button and moving the window =>
                // check for stick conditions
                //second condition is checking after we change multi window mode to two window mode
                if (activeFocus || (SettingsState.twoWindowMode && (AppFeatures.osType != OSType.MacOS))) {
                    tryToStick();
                }
            }

            onMessagingWindowXChanged: {
                if (messagingWindow.x !== AppState.messagingWindowX) {
                    messagingWindow.x = AppState.messagingWindowX;
                    tryToStick();
                }
            }

            onMessagingWindowYChanged: {
                if (messagingWindow.y !== AppState.messagingWindowY) {
                    messagingWindow.y = AppState.messagingWindowY;
                    tryToStick();
                }
            }

            doWorkOnWindowClose: function() {
                ActionProvider.showMessagingWindow(false);
            }

            ConfirmDialog {
                id: deleteMessageHistoryDialog

                width: 363
                height: 115

                x: contactsWindow.x + contactsWindow.width / 2 - width / 2
                y: contactsWindow.y + contactsWindow.height / 2 - height / 2

                visible: SettingsState.showDeleteMessageHistoryDialog

                message: qsTrId("contacts_dialog_delete_message_history_message") + Translator.translate

                textOKButton: qsTrId("dialog_button_yes") + Translator.translate
                textCancelButton: qsTrId("dialog_button_no") + Translator.translate

                onOKAction: function() {
                    ActionProvider.deleteAllDataMessageHistory(true);
                }

                onCancelAction: function() {
                    ActionProvider.deleteAllDataMessageHistory(false);
                }
            }
        }

        BorderlessWindow {
            id: personalStatisticsWindow

            property bool showPersonalStatisticsWindow: SettingsState.showPersonalStatisticsWindow

            titleButtonImageColor: ColorStorage.secondaryWindowTitleAndIcons
            titleButtonColorOnHover: ColorStorage.secondaryWindowTitleButtonOnHover
            titleButtonColorOnPress: ColorStorage.secondaryWindowTitleButtonOnPress
            titleButtonSize: 39 * SettingsState.scale
            borderOpacity: ColorStorage.secondaryWindowBorderOpacity

            visible: AppState.showMainWindowSubwindows && showPersonalStatisticsWindow && !AppState.instanceWillDestroy
                     && !AppFeatures.hideStatisticsWindow && !mainWindow.compactWindowMode
            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Tab"

                onActivated: {
                    mainWindow.requestActivate();
                }
            }

            Shortcut {
                enabled: !mainWindow.compactWindowMode
                sequence: "Ctrl+Shift+Tab"

                onActivated: {
                    if (messagingWindow.visible) {
                        messagingWindow.requestActivate();
                    } else if (historyWindow.visible) {
                        historyWindow.requestActivate();
                    } else if (contactsWindow.visible) {
                        contactsWindow.requestActivate();
                    } else {
                        mainWindow.requestActivate();
                    }
                }
            }


            onVisibleChanged: {
                if (AppFeatures.osType == OSType.MacOS && !AppState.showMainWindowSubwindows) {
                    return;
                }

                if (!visible) {
                    unstick();
                } else {
                    if (SettingsState.twoWindowMode) {
                        mainWindow.stickyProps.buddyRight = personalStatisticsWindow;
                        personalStatisticsWindow.stickyProps.buddyLeft = mainWindow;
                        personalStatisticsWindow.stickyProps.leftAsSlave = true;

                    }
                    tryToStick();
                }
            }

            disableMinimizeButton: true
            beSubWindow: true
            alwaysOnTop: SettingsState.alwaysOnTop

            destroyWindowManually: true

            enableMove: !SettingsState.twoWindowMode

            doWorkOnWindowClose: function() {
                ActionProvider.showPersonalStatisticsWindow(false);
            }

            stickyBuddies: [mainWindow, activeCallWindow, contactsWindow, historyWindow, messagingWindow]

            onXChanged: {
                ActionProvider.sendPersonalStatisticsWindowPosition(Qt.point(personalStatisticsWindow.x, personalStatisticsWindow.y));

                // if user is pressing mouse button and moving the window =>
                // check for stick conditions
                //second condition is checking after we change multi window mode to two window mode
                if (activeFocus || (SettingsState.twoWindowMode && (AppFeatures.osType != OSType.MacOS))) {
                    tryToStick();
                }
            }

            onYChanged: {
                ActionProvider.sendPersonalStatisticsWindowPosition(Qt.point(personalStatisticsWindow.x, personalStatisticsWindow.y));

                // if user is pressing mouse button and moving the window =>
                // check for stick conditions
                //second condition is checking after we change multi window mode to two window mode
                if (activeFocus || (SettingsState.twoWindowMode && (AppFeatures.osType != OSType.MacOS))) {
                    tryToStick();
                }
            }

            property int personalStatisticsWindowX: AppState.personalStatisticsWindowX
            property int personalStatisticsWindowY: AppState.personalStatisticsWindowY

            onPersonalStatisticsWindowXChanged: {
                if (personalStatisticsWindow.x !== AppState.personalStatisticsWindowX) {
                    personalStatisticsWindow.x = AppState.personalStatisticsWindowX;
                    tryToStick();
                }
            }

            onPersonalStatisticsWindowYChanged: {
                if (personalStatisticsWindow.y !== AppState.personalStatisticsWindowY) {
                    personalStatisticsWindow.y = AppState.personalStatisticsWindowY;
                    tryToStick();
                }
            }

            Component.onCompleted: {
                personalStatisticsWindow.x = AppState.personalStatisticsWindowX;
                personalStatisticsWindow.y = AppState.personalStatisticsWindowY;

                if (showPersonalStatisticsWindow) {
                    tryToStick();
                }
            }

            content: PersonalStatistics {
                width: 362 * SettingsState.scale
                height: 644 * SettingsState.scale

                visible: true
            }

        }

    }

    BorderlessWindow {
        id: incomingWindow

        disableMinimizeButton: true
        alwaysOnTop: true
        beSubWindow: true
        titleButtonSize: 39 * SettingsState.scale

        borderOpacity: ColorStorage.secondaryWindowBorderOpacity

        onVisibleChanged: {
            if (visible) {
                x = AppState.incomingCallWindowX;
                y = AppState.incomingCallWindowY;
                forceActiveFocus();
                AppLogger.debug("Incoming call notification window appeared");
                return;
            }
            AppLogger.debug("Incoming call notification window disappeared");
        }

        visible: {
            if (!AppState.useSmallIncomingCallWindow &&
                    AppState.activeCall &&
                    (AppState.activeCall.direction == SipCall.Incoming || (AppState.activeCall.direction == SipCall.Outgoing && AppState.activeCall.isClickToCall)) &&
                    AppState.activeCall.status == SipCall.Connecting &&
                    !AppState.showPostProcessingWindow) {
                incomingWindow.raise();
                incomingWindow.requestActivate();
                return true;
            }

            return false;
        }
        content: IncomingWindow {
            width: 364 * SettingsState.scale
        }

        destroyWindowManually: true
        disableCloseButton: SettingsState.closeRingingPopupButton == IncomingWindowCloseButton.Disabled
        hideCloseButton: SettingsState.closeRingingPopupButton == IncomingWindowCloseButton.Disabled

        doWorkOnWindowClose: function() {
            if (AppState.activeCall && SettingsState.closeRingingPopupButton == IncomingWindowCloseButton.Decline) {
                ActionProvider.hangupCall(AppState.activeCall.id);
                AppLogger.debug("Incoming window; Close button: User clicked Hangup button");
            } else if(AppState.activeCall) {
                ActionProvider.ignoreCall(AppState.activeCall.id);
                AppLogger.debug("Incoming window; Close button: User clicked Ignore button");
            }
        }
    }

    BorderlessWindow {
        id: smallIncomingWindow

        disableMinimizeButton: true
        disableCloseButton: true
        hideCloseButton: true

        enableMove: false
        alwaysOnTop: true
        beSubWindow: true

        borderOpacity: ColorStorage.secondaryWindowBorderOpacity

        x: AppState.mainScreenWidth - width
        y: AppState.mainScreenHeight - height

        width: content.width
        height: content.height

        titleButtonSize: 31 * SettingsState.scale

        visible: AppState.incomingCallsModel.count && !incomingWindow.visible
        onVisibleChanged: {
            if (visible) {
                AppLogger.debug("Small incoming call notification window appeared");
                return;
            }
            AppLogger.debug("Small incoming call notification window disappeared");
        }

        onHeightChanged: {
            if (y + height != AppState.mainScreenHeight) {
                y = AppState.mainScreenHeight - height;
            }
        }

        Behavior on height {
            enabled: AppState.incomingCallsModel.count

            NumberAnimation {
                duration: 10
                easing.type: Easing.Linear
            }
        }

        content: SmallIncomingWindow {
            id: content
            anchors.centerIn: parent
        }

        destroyWindowManually: true
    }

    BorderlessWindow {
        id: floatingWindow

        x: AppState.floatingWindowX
        y: AppState.floatingWindowY

        disableMinimizeButton: true
        alwaysOnTop: true
        beSubWindow: true

        mouseAreaHeight: 31 * SettingsState.scale

        borderOpacity: ColorStorage.secondaryWindowBorderOpacity

        onXChanged: {
            ActionProvider.sendFloatingWindowPosition(Qt.point(floatingWindow.x, floatingWindow.y));
        }

        onYChanged: {
            ActionProvider.sendFloatingWindowPosition(Qt.point(floatingWindow.x, floatingWindow.y));
        }

        property int floatingWindowX: AppState.floatingWindowX
        property int floatingWindowY: AppState.floatingWindowY

        onFloatingWindowXChanged: {
            if (floatingWindow.x !== AppState.floatingWindowX) {
                floatingWindow.x = AppState.floatingWindowX;
            }
        }

        onFloatingWindowYChanged: {
            if (floatingWindow.y !== AppState.floatingWindowY) {
                floatingWindow.y = AppState.floatingWindowY;
            }
        }

        property bool showFloatingWindowOnActiveCall: AppState.showFloatingWindowOnActiveCall

        onShowFloatingWindowOnActiveCallChanged: {
            if (!activeCall) {
                return;
            }

            floatingWindow.visible = (showFloatingWindowOnActiveCall && ((activeCall.direction == SipCall.Outgoing && !activeCall.isClickToCall) ||
                                                                         activeCall.status == SipCall.Answered));
        }

        property var activeCall: AppState.activeCall
        property var lastFinishedCall: AppState.lastFinishedCall

        property bool callAvailable: false

        onActiveCallChanged: {
            if (!showFloatingWindowOnActiveCall) {
                return;
            }

            if (!activeCall) {
                return;
            }

            floatingWindow.visible = (activeCall.direction == SipCall.Outgoing && !activeCall.isClickToCall) ||
                    activeCall.status == SipCall.Answered ||
                    activeCall.status == SipCall.OnHold;
        }

        onLastFinishedCallChanged: {
            if (!lastFinishedCall) {
                return;
            }

            floatingWindow.visible = false;
        }

        onVisibleChanged: {
            if (!visible || !AppState.activeCall) {
                return;
            }

            if (AppState.showMainWindowOnIncoming &&
                    (AppState.activeCall.direction == SipCall.Incoming || (AppState.activeCall.direction == SipCall.Outgoing && AppState.activeCall.isClickToCall)) &&
                    AppState.activeCall.status == SipCall.Answered) {
                mainWindow.showNormal();
                return;
            }
        }

        content: FloatingWindow {
        }

        destroyWindowManually: true
        doWorkOnWindowClose: function() {
            visible = false;
        }
    }

    BorderlessWindow {
        id: clipboardWindow

        disableMinimizeButton: true
        alwaysOnTop: true
        beSubWindow: true
        enableMove: false

        titleButtonSize: 31 * SettingsState.scale

        visible: false

        borderOpacity: ColorStorage.secondaryWindowBorderOpacity

        x: AppState.clipboardWindowX
        y: AppState.clipboardWindowY

        property int clipboardWindowX: AppState.clipboardWindowX
        property int clipboardWindowY: AppState.clipboardWindowY

        onClipboardWindowXChanged: {
            if (clipboardWindow.x !== AppState.clipboardWindowX) {
                clipboardWindow.x = AppState.clipboardWindowX;
            }
        }

        onClipboardWindowYChanged: {
            if (clipboardWindow.y !== AppState.clipboardWindowY) {
                clipboardWindow.y = AppState.clipboardWindowY;
            }
        }

        content: ClipboardWindow {
            id: clipboardWindowContent

            width: 363 * SettingsState.scale
            height: 180 * SettingsState.scale

            property var activeCall: AppState.activeCall
            property string inputText: input.edit.text
            property string inputFocus: input.edit.activeFocus

            enabled: clipboardWindow.visible

            onInputFocusChanged: {
                if (inputFocus) {
                    clipboardWindow.secondsLeft = 0;
                }
            }

            onInputTextChanged: {
                if (inputText.length == 0) {
                    return;
                }

                clipboardWindow.visible = true;
                clipboardWindow.secondsLeft = 0;
            }

            onActiveCallChanged: {
                clipboardWindow.secondsLeft = 0;
            }
        }

        property var timeNow: AppState.timeNow
        readonly property int maxSecondsVisible: 10
        property int secondsLeft: 0

        onXChanged: {
            secondsLeft = 0;
        }

        onYChanged: {
            secondsLeft = 0;
        }

        onTimeNowChanged: {
            if (!visible || AppState.activeCall) {
                return;
            }

            secondsLeft += 1;

            if (secondsLeft == maxSecondsVisible) {
                visible = false;
                secondsLeft = 0;
                x = AppState.clipboardWindowX;
                y = AppState.clipboardWindowY;
            }
        }

        destroyWindowManually: true
        doWorkOnWindowClose: function() {
            visible = false;
        }

        property bool closeClipboardWindow: AppState.closeClipboardWindow
        onCloseClipboardWindowChanged: {
            secondsLeft = 0;
            visible = false;
        }
    }

    BorderlessWindow {
        id: postProcessingWindow

        x: AppState.postProcessingWindowX
        y: AppState.postProcessingWindowY

        disableMinimizeButton: true
        alwaysOnTop: true
        beSubWindow: true

        borderOpacity: ColorStorage.secondaryWindowBorderOpacity

        onXChanged: {
            ActionProvider.sendPostProcessingWindowPosition(Qt.point(postProcessingWindow.x, postProcessingWindow.y));
        }

        onYChanged: {
            ActionProvider.sendPostProcessingWindowPosition(Qt.point(postProcessingWindow.x, postProcessingWindow.y));
        }

        property int postProcessingWindowX: AppState.postProcessingWindowX
        property int postProcessingWindowY: AppState.postProcessingWindowY

        onPostProcessingWindowXChanged: {
            if (postProcessingWindow.x !== AppState.postProcessingWindowX) {
                postProcessingWindow.x = AppState.postProcessingWindowX;
            }
        }

        onPostProcessingWindowYChanged: {
            if (postProcessingWindow.y !== AppState.postProcessingWindowY) {
                postProcessingWindow.y = AppState.postProcessingWindowY;
            }
        }

        visible: !AppFeatures.hidePostProcessing && AppState.showPostProcessingWindow

        content: PostProcessingWindow {
            width: 250 * SettingsState.scale

            postProcessingWindowVisible: postProcessingWindow.visible
        }

        destroyWindowManually: true

        doWorkOnWindowClose: function() {
            ActionProvider.tryToFinishPostProcessing("", null, "");
        }
    }
}

