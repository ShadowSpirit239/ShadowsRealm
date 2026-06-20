import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import SddmComponents 2.0
import "." as Theme

/**
 * ShadowsRealm SDDM greeter.
 *
 * Mirrors the Caelestia lock screen: blurred wallpaper, large centered clock
 * and date, and a rounded Material You password field with session/user
 * selectors. Colors come from the auto-generated Colors.qml singleton, so the
 * login screen tracks the active desktop scheme.
 */
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: Theme.Colors.background

    property int sessionIndex: sessionModel.lastIndex

    TextConstants { id: textConstants }

    // ---- Background (blurred wallpaper) ----
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
        cache: true
    }
    GaussianBlur {
        anchors.fill: wallpaper
        source: wallpaper
        radius: Number(config.blurRadius) || 48
        samples: 32
        visible: wallpaper.status === Image.Ready
    }
    // Scrim so text stays readable over any wallpaper.
    Rectangle {
        anchors.fill: parent
        color: Theme.Colors.background
        opacity: wallpaper.status === Image.Ready ? 0.45 : 1.0
    }

    // ---- Clock + date ----
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.16
        spacing: 4

        Text {
            id: clock
            Layout.alignment: Qt.AlignHCenter
            color: Theme.Colors.onBackground
            font.family: config.font || "sans-serif"
            font.pixelSize: 96
            font.weight: Font.DemiBold
            text: Qt.formatTime(timeSource.now, config.clockFormat || "hh:mm")
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            color: Theme.Colors.onSurfaceVariant
            font.family: config.font || "sans-serif"
            font.pixelSize: 26
            text: Qt.formatDate(timeSource.now, config.dateFormat || "dddd, MMMM d")
        }
    }

    QtObject {
        id: timeSource
        property var now: new Date()
    }
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: timeSource.now = new Date()
    }

    // ---- Login card ----
    Rectangle {
        id: card
        width: 420
        radius: 28
        color: Theme.Colors.surfaceContainer
        border.width: 1
        border.color: Theme.Colors.outlineVariant
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: parent.height * 0.12
        implicitHeight: cardCol.implicitHeight + 48

        ColumnLayout {
            id: cardCol
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 16

            // User selector
            ComboBox {
                id: userCombo
                Layout.fillWidth: true
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex
                font.family: config.font || "sans-serif"
            }

            // Password field
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 16
                color: Theme.Colors.surfaceContainerHigh
                border.width: passwordField.activeFocus ? 2 : 1
                border.color: passwordField.activeFocus ? Theme.Colors.primary : Theme.Colors.outline

                TextField {
                    id: passwordField
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    placeholderText: textConstants.password
                    color: Theme.Colors.onSurface
                    placeholderTextColor: Theme.Colors.onSurfaceVariant
                    font.family: config.font || "sans-serif"
                    font.pixelSize: 18
                    background: Item {}
                    focus: true
                    onAccepted: root.attemptLogin()
                    Keys.onEscapePressed: passwordField.text = ""
                }
            }

            // Login button
            Button {
                id: loginButton
                Layout.fillWidth: true
                height: 50
                font.family: config.font || "sans-serif"
                contentItem: Text {
                    text: textConstants.login
                    color: Theme.Colors.onPrimary
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 16
                    color: loginButton.down ? Theme.Colors.primaryContainer : Theme.Colors.primary
                }
                onClicked: root.attemptLogin()
            }

            // Error / status message
            Text {
                id: message
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: Theme.Colors.error
                font.family: config.font || "sans-serif"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                text: ""
            }

            // Session selector
            ComboBox {
                id: sessionCombo
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                font.family: config.font || "sans-serif"
                onCurrentIndexChanged: root.sessionIndex = currentIndex
            }
        }
    }

    // ---- Power buttons ----
    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 12

        Button {
            text: "\u23FB" // power
            onClicked: sddm.powerOff()
            background: Rectangle { radius: 12; color: Theme.Colors.surfaceContainerHigh }
            contentItem: Text { text: parent.text; color: Theme.Colors.onSurface; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
        Button {
            text: "\u21BB" // reboot
            onClicked: sddm.reboot()
            background: Rectangle { radius: 12; color: Theme.Colors.surfaceContainerHigh }
            contentItem: Text { text: parent.text; color: Theme.Colors.onSurface; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        }
    }

    function attemptLogin() {
        message.text = ""
        sddm.login(userCombo.currentText, passwordField.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            message.color = Theme.Colors.onSurfaceVariant
            message.text = textConstants.loginSucceeded
        }
        function onLoginFailed() {
            message.color = Theme.Colors.error
            message.text = textConstants.loginFailed
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }

    Component.onCompleted: passwordField.forceActiveFocus()
}
