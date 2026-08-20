import QtQuick 2.15
import Flux 1.0

import "../uicontrols"
import "../utils"

FocusScope {
    id: root

    KeyNavigation.tab: input
    KeyNavigation.backtab: input

    focus: true

    function resetFocus() {
        input.resetFocus();
        layersScope.focus = false;
        root.forceActiveFocus();
    }

    function activateInputWithSymbol(symbol) {
        input.requestInputFocus();
        ActionProvider.sendDialedSymbol(symbol);
    }

    function closeMainMenu() {
        title.closeMainMenu();
    }

    function forceFocusOnInput() {
        input.requestInputFocus();
        title.closeMainMenu();
    }

    function openAccountDropdown(){
        input.openAccountDropdown();
        title.closeMainMenu();
    }

    function openStatusDropdown(){
        input.openStatusDropdown();
        title.closeMainMenu();
    }

    function openCallForwardDropdown(){
        title.openCallForwardDropdown();
    }

    function openEmailNotificationDropdown(){
        title.openEmailNotificationDropdown();
    }


    Keys.onDigit0Pressed: {
        root.activateInputWithSymbol("0");
    }

    Keys.onDigit1Pressed: {
        root.activateInputWithSymbol("1");
    }

    Keys.onDigit2Pressed: {
        root.activateInputWithSymbol("2");
    }

    Keys.onDigit3Pressed: {
        root.activateInputWithSymbol("3");
    }

    Keys.onDigit4Pressed: {
        root.activateInputWithSymbol("4");
    }

    Keys.onDigit5Pressed: {
        root.activateInputWithSymbol("5");
    }

    Keys.onDigit6Pressed: {
        root.activateInputWithSymbol("6");
    }

    Keys.onDigit7Pressed: {
        root.activateInputWithSymbol("7");
    }

    Keys.onDigit8Pressed: {
        root.activateInputWithSymbol("8");
    }

    Keys.onDigit9Pressed: {
        root.activateInputWithSymbol("9");
    }

    Keys.onAsteriskPressed: {
        root.activateInputWithSymbol("*");
    }

    Keys.onNumberSignPressed: {
        root.activateInputWithSymbol("#");
    }

    MouseArea {
        anchors.fill: parent

        onPressed: {
            root.resetFocus();
            mouse.accepted = false;
        }
    }

    FocusScope {
        id: layersScope

            Rectangle {
                id: layers

                width: root.width
                height: 190  * SettingsState.scale //TODO add change width on hide status and account button

                color: ColorStorage.mainWindowBackground
                clip: true

                Column {
                    anchors.fill: parent

                    TitleLayer {
                        id: title

                        width: parent.width
                        height: 40 * SettingsState.scale
                    }

                    InputLayer {
                        id: input

                        width: parent.width
                        height: layers.height - title.height

                        focus: parent.focus

                        property bool focusFromInput

                        onFocusChanged: {
                            focusFromInput = activeFocus;
                            input.focusFromInput = input.activeFocus;
                        }
                    }
                }

                MainMenuSeparator {
                    id: convSeparator
                    width: parent.width - 2 * SettingsState.scale
                    height: 1 * SettingsState.scale
                    color: ColorStorage.mainWindowBorder
                    opacity: ColorStorage.mainWindowSeparatorOpacity
                    anchors.bottom: layers.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: 1 * SettingsState.scale
                }
            }

            SquareButton {
                id: conv
                anchors.top: layers.bottom
                Accessible.role: Accessible.Button
                Accessible.name: "CompactModeButton"

                width: root.width
                height: 22 * SettingsState.scale

                colorDefault: ColorStorage.mainWindowBackground
                colorOnHover: ColorStorage.buttonSecondaryOnHover
                colorOnPress: ColorStorage.buttonSecondaryOnPress

                imageWidth: 25 * SettingsState.scale
                imageHeight: 25 * SettingsState.scale

                imageColorDefault: ColorStorage.additionalText
                imageColorOnHover: ColorStorage.additionalText
                imageColorOnPress: ColorStorage.additionalText
                imageColorOnDisabled: ColorStorage.additionalText

                imageDefault: SettingsState.compactWindowMode ? "qrc:/images/chevron_down.svg" : "qrc:/images/chevron_up.svg"

                doWorkOnButtonClick: function() {
                    ActionProvider.showCompactWindowMode(!SettingsState.compactWindowMode);
                }
            }

            Rectangle {
                id: pad
                anchors.top: conv.bottom
                width: root.width
                height: 314 * SettingsState.scale

                color: ColorStorage.mainWindowBackground
                clip: true

                visible: !SettingsState.compactWindowMode

                NumPad {
                    id: numpad

                    buttonColorOnHover: ColorStorage.mainWindowNumButtonOnHover
                    buttonColorOnPress: ColorStorage.mainWindowNumButtonOnPress

                    anchors {
                        fill: parent
                        topMargin: 7 * SettingsState.scale
                        leftMargin: 20 * SettingsState.scale
                    }
                }
            }

            Rectangle {
                id: callButtonRect

                anchors.top: pad.visible ? pad.bottom : conv.bottom

                width: root.width
                height: 56 * SettingsState.scale

                SquareButton {
                    id: callButton

                    scale: SettingsState.scale

                    width: parent.width
                    height: parent.height

                    radius: 0

                    enabled: !input.isInputEmpty

                    Accessible.role: Accessible.Button
                    Accessible.name: "MainWindowButton"

                    colorDefault: ColorStorage.green //white: "#05B86D" //black: #05B86D
                    colorOnHover: ColorStorage.greenOnHover //white: "#049F5F" //black: #049F5F
                    colorOnPress: ColorStorage.greenOnPress //white: "#026E41" //black: #026E41
                    colorOnDisabled: ColorStorage.disabledButtonsGrey //white: "#D9D9D9" //black: #707070

                    imageWidth: 28 * SettingsState.scale
                    imageHeight: 28 * SettingsState.scale

                    imageColorDefault: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                    imageColorOnHover: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                    imageColorOnPress: ColorStorage.white //white: "#FFFFFF" //black: #FFFFFF
                    imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                    imageDefault: "qrc:/images/call_default.svg"
                    property int callMakeError: AppState.callMakeAccountError

                    onCallMakeErrorChanged: {
                        if (callMakeError == CallMakeAccountError.UnregisteredAccount) {
                            callMakePopup.open();

                            // if (callMakeError == CallMakeError.InvalidAudioDevice) {
                            //     // allow to make a next call immediately
                            //     // disableWorkFunction = false;
                            // }
                        }
                    }

                    CallMakePopup {
                        id: callMakePopup

                        anchors.centerIn: callButton
                    }

                    doWorkOnButtonClick: function() {
                       input.tryMakeCall();
                    }
                }

            }

            MainMenuSeparator {
                id: separator

                anchors.top: callButtonRect.bottom
                anchors.left: parent.left
                anchors.leftMargin: 1 * SettingsState.scale

                width: root.width - 2 * SettingsState.scale
                height: 1 * SettingsState.scale

                opacity: ColorStorage.mainWindowSeparatorOpacity

                visible: !SettingsState.compactWindowMode

                color: ColorStorage.mainWindowBorder
            }

            Rectangle {
                id: controlGuiButtons

                anchors.top: callButtonRect.bottom

                width: root.width
                height: 64 * SettingsState.scale

                visible: !SettingsState.compactWindowMode

                color: ColorStorage.mainWindowBackground

                SwitchWindowPanel {
                    id: switchWindowPanel

                    anchors.fill: parent
                }
            }
        }
}
