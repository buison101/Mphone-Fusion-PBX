import QtQuick 2.15
import QtQuick.Controls 2.15
import AuthEngineModule 1.0
import Flux 1.0

import "../activecalls"
import "../uicontrols" as SoftphonePro
import "../utils"

FocusScope {
    id: root
    property int mainLoginWidth
    property int mainLoginHeight

    implicitWidth: mainLoginWidth
    implicitHeight: loginLayer.height

    focus: true

    property var doWorkOnWindowClose: function() {}

    Rectangle {
        id: loginLayer

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: mainLoginHeight

        color: ColorStorage.secondaryWindowBackground

        border.width: 1 * AuthEngine.scale
        border.color: ColorStorage.windowBorder

        Rectangle {
            id: titleLayer

            anchors.top: parent.top
            anchors.left: parent.left

            color: ColorStorage.secondaryWindowTitleBackgroundColor
            width: parent.width
            height: 39 * AuthEngine.scale

            Text {
                id: title

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16 * AuthEngine.scale

                font.pixelSize: 12 * AuthEngine.scale
                font.family: "Segoe UI"
                font.bold: true

                color: ColorStorage.secondaryWindowTitleAndIcons

                text: qsTrId("login_window_title") + Translator.translate
            }
        }

        Row {
            id: logo
            anchors.top: titleLayer.bottom
            anchors.topMargin: 90 * AuthEngine.scale

            anchors.left: companyInput.left
            width: (imageLogo.width + textLogo.implicitWidth)
            height: imageLogo.height

            visible: true

            spacing: 10 * AuthEngine.scale

            Image {
                id: imageLogo

                width: 40 * AuthEngine.scale
                height: 40 * AuthEngine.scale

                sourceSize.width: width
                sourceSize.height: height

                source: "qrc:/images/app_icon_white.svg"
            }

            Rectangle {
                width: textLogo.width
                height: textLogo.height
                color: "transparent"

                Text {
                    id: textLogo

                    anchors.top: parent.top
                    anchors.topMargin: 5 * AuthEngine.scale

                    font.pixelSize: 20 * AuthEngine.scale
                    font.family: "Segoe UI"
                    font.bold: true

                    color: ColorStorage.iconsAndTextPrimary

                    text: StringStorage.appTitle
                }
            }
        }

        Text {
            id: companyTitle

            anchors.top: logo.bottom
            anchors.topMargin: 30 * AuthEngine.scale
            anchors.left: companyInput.left

            visible: companyInput.visible

            font.pixelSize: 10 * AuthEngine.scale
            font.family:  "Segoe UI"

            color: ColorStorage.additionalText
            text: qsTrId("settings_crm_account") + Translator.translate
        }

        SoftphonePro.LoginInput {
            id: companyInput

            anchors.top: companyTitle.bottom
            anchors.topMargin: 5 * AuthEngine.scale
            anchors.horizontalCenter: parent.horizontalCenter

            visible: AuthEngine.isCompanyVisible

            implicitWidth: 2 / 3 * mainLoginWidth
            implicitHeight: 40 * AuthEngine.scale

            focus: true

            textColor: ColorStorage.iconsAndTextPrimary

            placeholder.text: qsTrId("login_window_login_placeholder") + Translator.translate
            placeholder.color: ColorStorage.additionalText
            placeholder.font.pixelSize: 14 * AuthEngine.scale
            placeholder.font.family: "Segoe UI"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
                enabled: false
            }
        }

        Text {
            id: loginTitle

            anchors.top: companyInput.visible ? companyInput.bottom : logo.bottom
            anchors.topMargin: companyInput.visible ? 20 * AuthEngine.scale : 30 * AuthEngine.scale
            anchors.left: companyInput.left

            font.pixelSize: 10 * AuthEngine.scale
            font.family:  "Segoe UI"

            color: ColorStorage.additionalText
            text: qsTrId("settings_sip_account_login") + Translator.translate
        }

        SoftphonePro.AccountsComboBox {
            id: loginInput

            edit.font.pixelSize: 12 * AuthEngine.scale

            delegateColorDefault: ColorStorage.mainWindowBackground
            delegateColorOnHover: ColorStorage.surfaceSecondary

            anchors.top: loginTitle.bottom
            anchors.topMargin: 5 * AuthEngine.scale
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.left: loginTitle.left

            hoverWidth: 2 / 3 * mainLoginWidth
            hoverHeight: 40 * AuthEngine.scale

            edit.editText: AuthEngine.lastLogin

            focus: true

            model: AuthEngine.loginListModel

            placeholder.text: qsTrId("login_window_login_placeholder") + Translator.translate
            placeholder.color: ColorStorage.additionalText
            placeholder.font.pixelSize: 14 * AuthEngine.scale
            placeholder.font.family: "Segoe UI"

            gotoTab: passwordInput

            onEnterPressed: loginButton.doWorkOnButtonClick

            Component.onCompleted: {
                setFocus();
            }
        }

        Text {
            id: passwordTitle

            anchors.top: loginInput.bottom
            anchors.topMargin: 60 * AuthEngine.scale
            anchors.left: companyInput.left

            font.pixelSize: 10 * AuthEngine.scale
            font.family:  "Segoe UI"

            color: ColorStorage.additionalText
            text: qsTrId("settings_sip_account_password") + Translator.translate
        }

        SoftphonePro.LoginInput {
            id: passwordInput

            edit.font.pixelSize: 12 * AuthEngine.scale

            anchors.top: passwordTitle.bottom
            anchors.topMargin: 5 * AuthEngine.scale
            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: 2 / 3 * mainLoginWidth
            implicitHeight: 40 * AuthEngine.scale

            edit.echoMode: TextInput.Password

            focus: true

            textColor: ColorStorage.iconsAndTextPrimary

            placeholder.text: qsTrId("login_window_password_placeholder") + Translator.translate
            placeholder.color: ColorStorage.additionalText
            placeholder.font.pixelSize: 14 * AuthEngine.scale
            placeholder.font.family: "Segoe UI"

            KeyNavigation.tab: rememberCheckbox

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
                enabled: false
            }

            Keys.onReturnPressed: {
                loginButton.doWorkOnButtonClick();
            }

            Keys.onEnterPressed: {
                loginButton.doWorkOnButtonClick();
            }
        }

        Rectangle {
            anchors.top: passwordInput.bottom
            anchors.topMargin: 20 * AuthEngine.scale
            anchors.left: companyInput.left
            CheckBox {
                property int halo: 0

                id: rememberCheckbox

                checked: AuthEngine.remember

                onCheckedChanged: {
                    AuthEngine.remember = !AuthEngine.remember;
                }

                onFocusChanged: {
                    halo = focus == true ? 2 : 0
                }

                KeyNavigation.tab: loginButton

                indicator: Rectangle {
                    id: rect
                    property int widthValue: 20 * AuthEngine.scale
                    width: widthValue
                    height: width
                    color: ColorStorage.mainWindowBackground
                    radius: 4 * AuthEngine.scale
                    border.width: rememberCheckbox.activeFocus || mouseArea.containsMouse ? 1 * AuthEngine.scale : 0
                    border.color: ColorStorage.grayNeutralOnPress

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        onReleased: {
                            rememberCheckbox.checked = !rememberCheckbox.checked;
                        }
                    }

                    Image {
                        id: check

                        property string imageColorDefault: ColorStorage.iconsAndTextSecondary

                        source: "qrc:/images/check.svg"
                        width: rect.width
                        height: width
                        visible: false
                    }

                    IconShader {
                        visible: rememberCheckbox.checked
                        imageSrcComponent: check
                        imgColor: check.imageColorDefault
                        imageWidth: check.width
                        imageHeight: check.height
                    }
                }
            }

            Label {
                text: qsTrId("login_window_remember_me") + Translator.translate
                anchors.top: rememberCheckbox.top
                anchors.topMargin: 1 * AuthEngine.scale
                anchors.left: rememberCheckbox.right
                font.pixelSize: 13 * AuthEngine.scale
                font.family: "Segoe UI"
                color: ColorStorage.iconsAndTextSecondary
            }
        }

        SoftphonePro.SquareButton {
            id: loginButton

            scale: AuthEngine.scale
            anchors.top: passwordInput.bottom
            anchors.topMargin: 60 * AuthEngine.scale
            anchors.horizontalCenter: parent.horizontalCenter

            enabled: loginInput.edit.editText.length > 0 &&
                     (AuthEngine.status == AuthStatus.AuthorizationWaiting || AuthEngine.status == AuthStatus.Error)

            width: 2 / 3 * mainLoginWidth
            height: 45 * scale

            radius: 8 * scale

            colorDefault: ColorStorage.loginButtonLoginWindowDefaultColor
            colorOnPress: ColorStorage.loginButtonLoginWindowOnPressColor
            colorOnHover: ColorStorage.loginButtonLoginWindowOnHoverColor
            colorOnDisabled: ColorStorage.sSizeButtonDisabled

            imageDefault: ""

            KeyNavigation.tab: loginInput

            Text {
                id: name

                anchors.centerIn: parent

                visible: AuthEngine.status == AuthStatus.AuthorizationWaiting || AuthEngine.status == AuthStatus.Error

                font.pixelSize: 16 * AuthEngine.scale;

                font.family: "Segoe UI"

                color: loginButton.enabled ? ColorStorage.white : ColorStorage.textAndDisabledIconsGrey

                text: qsTrId("login_window_login_button_title") + Translator.translate
            }

            BusyIndicator {
                id: busyIndicator

                anchors.centerIn: parent

                width: 24 * AuthEngine.scale
                height: 24 * AuthEngine.scale

                visible: !name.visible
                running: visible

                contentItem: Image {
                    visible: busyIndicator.running
                    source: "qrc:/images/spinner.svg"
                    RotationAnimator on rotation {
                        running: busyIndicator.running
                        loops: Animation.Infinite
                        duration: 2000
                        from: 0 ; to: 360
                    }
                }
            }

            doWorkOnButtonClick: function() {
                if (loginButton.enabled) {
                    AuthEngine.checkData(companyInput.edit.text, loginInput.edit.editText, passwordInput.edit.text);
                }
            }
        }

        Rectangle {
            id: errorBody
            anchors.top: loginButton.bottom
            anchors.topMargin: 10 * AuthEngine.scale
            anchors.horizontalCenter: parent.horizontalCenter

            color: "transparent"
            width: loginButton.width
            height: errorTitle.height + errorTitle.anchors.topMargin + errorDescription.height +
                    errorDescription.anchors.topMargin + 20 * AuthEngine.scale;

            visible: AuthEngine.status == AuthStatus.Error

            FocusScope {
                id: errorScopre

                focus: true

                anchors.fill: parent

                Text {
                    id: errorTitle

                    anchors.top: parent.top
                    anchors.topMargin: 10 * AuthEngine.scale
                    anchors.left: parent.left
                    anchors.right: parent.right

                    text: AuthEngine.errorString + " (" + AuthEngine.errorCode + ")"

                    font.pixelSize: 14 * AuthEngine.scale
                    font.family: "Segoe UI"
                    font.weight: Font.Bold

                    wrapMode: Text.WordWrap

                    color: errorDescription.color

                    onLinkActivated: Qt.openUrlExternally(link)

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }

                Text {
                    id: errorDescription

                    anchors.top: errorTitle.bottom
                    anchors.topMargin: 10 * AuthEngine.scale
                    anchors.left: errorTitle.left
                    anchors.right: parent.right

                    text:""

                    font.pixelSize: 12 * AuthEngine.scale
                    font.family: "Segoe UI"

                    color: ColorStorage.errorWindowTextColor

                    wrapMode: Text.WordWrap
                }
            }
        }

        SoftphonePro.TitleButton {
            id: windowClose
            scale: AuthEngine.scale

            anchors.topMargin: 1 * AuthEngine.scale
            anchors.right: parent.right
            anchors.rightMargin: 1 * AuthEngine.scale
            anchors.top: parent.top

            bodyWidth: 39 * AuthEngine.scale
            bodyHeight: bodyWidth

            enabled: true
            visible: enabled

            colorDefault: "transparent"
            colorOnHover: ColorStorage.redOnHover
            colorOnPress: ColorStorage.redOnPress

            imageSource:  "qrc:/images/close_default.svg"
            imageColorDefault: ColorStorage.iconsAndTextPrimary
            imageWidth: 24 * AuthEngine.scale
            imageHeight: 24 * AuthEngine.scale

            doWorkOnButtonClick: function() {
                root.doWorkOnWindowClose();
            }
        }
    }
}
