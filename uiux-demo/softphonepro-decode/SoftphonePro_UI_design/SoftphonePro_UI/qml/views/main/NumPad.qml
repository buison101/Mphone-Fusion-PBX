import QtQuick 2.15
import Flux 1.0

import "../uicontrols"

FocusScope {
    id: root

    property string buttonColorOnHover: ""
    property string buttonColorOnPress: ""

    focus: true

    Grid {
        id: pad

        rows: 4
        columns: 3

        columnSpacing: 4 * SettingsState.scale
        rowSpacing: 4 * SettingsState.scale

        function sendDigit(digit) {
            root.forceActiveFocus();
            ActionProvider.sendDialedSymbol(digit);
        }

        NumPadButton {
            digit: "1"
            characters: "@"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad1"
        }

        NumPadButton {
            digit: "2"
            characters: "ABC"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad2"
        }

        NumPadButton {
            digit: "3"
            characters: "DEF"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad3"
        }

        NumPadButton {
            digit: "4"
            characters: "GHI"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad4"
        }

        NumPadButton {
            digit: "5"
            characters: "JKL"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad5"
        }

        NumPadButton {
            digit: "6"
            characters: "MNO"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad6"
        }

        NumPadButton {
            digit: "7"
            characters: "PQRS"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad7"
        }

        NumPadButton {
            digit: "8"
            characters: "TUV"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad8"
        }

        NumPadButton {
            digit: "9"
            characters: "WXYZ"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad9"
        }

        NumPadButton {
            digit: "*"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad*"
        }

        NumPadButton {
            digit: "0"
            characters: "+"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad0"
        }

        NumPadButton {
            digit: "#"

            widthNum: (root.width - 26 * SettingsState.scale) / 3

            doWorkOnButtonClick: function() {
                pad.sendDigit(digit);
            }

            buttonColorOnHover: root.buttonColorOnHover
            buttonColorOnPress: root.buttonColorOnPress

            Accessible.role: Accessible.Button
            Accessible.name: "NumPad#"
        }
    }
}
