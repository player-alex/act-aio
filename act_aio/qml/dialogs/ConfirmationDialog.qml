import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: confirmationDialog
    width: 450
    height: 250
    anchors.centerIn: parent
    modal: true
    focus: true
    visible: false
    closePolicy: Popup.CloseOnEscape

    topPadding: 20
    bottomPadding: 20
    leftPadding: 30
    rightPadding: 30

    property string dialogTitle: ""
    property string dialogMessage: ""
    property string callbackId: ""
    property var applicationWindow
    property var pluginManager

    function show(title, message, cbId) {
        dialogTitle = title
        dialogMessage = message
        callbackId = cbId
        visible = true
    }

    background: Rectangle {
        color: applicationWindow.base
        radius: 12
        border.color: applicationWindow.yellow
        border.width: 2
    }

    contentItem: ColumnLayout {
        spacing: 15
        Layout.fillWidth: true
        height: Math.max(250, parent.height)

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                width: 24
                height: 24
                color: applicationWindow.yellow
                radius: 12

                Text {
                    anchors.centerIn: parent
                    text: "?"
                    font.family: "Roboto"
                    font.pointSize: 14
                    font.weight: Font.Bold
                    color: applicationWindow.base
                }
            }

            Text {
                text: confirmationDialog.dialogTitle
                font.family: "Roboto"
                font.pointSize: 16
                font.weight: Font.Bold
                color: applicationWindow.yellow
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: applicationWindow.surface2
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            Flickable {
                id: confirmationDialogMessageFlickable
                anchors.fill: parent
                contentWidth: parent.width
                contentHeight: confirmationDialogMessageText.height
                clip: true
                flickableDirection: Flickable.HorizontalAndVerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: CustomScrollBar {
                    orientation: Qt.Vertical
                }

                MultiLangText {
                    id: confirmationDialogMessageText
                    width: parent.width
                    height: implicitHeight
                    rawText: confirmationDialog.dialogMessage
                    font.pointSize: 11
                    color: applicationWindow.text
                    wrapMode: Text.Wrap
                    textFormat: Text.StyledText
                }
            }
        }
    }

    footer: ColumnLayout {
        spacing: 0
        Layout.fillWidth: true

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: applicationWindow.surface2
            Layout.topMargin: 15
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 15
            spacing: 10
            Layout.rightMargin: 30
            Layout.bottomMargin: 20

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                width: 80
                height: 35
                color: confirmNoMouseArea.containsMouse ? applicationWindow.surface1 : applicationWindow.surface0
                radius: 4
                border.color: applicationWindow.overlay0
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "No"
                    font.family: "Roboto"
                    font.pointSize: 10
                    color: applicationWindow.text
                }

                MouseArea {
                    id: confirmNoMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        pluginManager.handleConfirmationResponse(confirmationDialog.callbackId, false)
                        confirmationDialog.close()
                    }
                }
            }

            Rectangle {
                width: 80
                height: 35
                color: confirmYesMouseArea.containsMouse ? applicationWindow.blue : applicationWindow.surface1
                radius: 4
                border.color: applicationWindow.blue
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Yes"
                    font.family: "Roboto"
                    font.pointSize: 10
                    font.weight: Font.Bold
                    color: confirmYesMouseArea.containsMouse ? applicationWindow.base : applicationWindow.text
                }

                MouseArea {
                    id: confirmYesMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        pluginManager.handleConfirmationResponse(confirmationDialog.callbackId, true)
                        confirmationDialog.close()
                    }
                }
            }
        }
    }
}
