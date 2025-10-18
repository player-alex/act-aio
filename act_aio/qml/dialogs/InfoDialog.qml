import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: infoDialog
    width: 450
    height: 250
    anchors.centerIn: parent
    modal: true
    focus: true
    visible: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnClickedOutside

    topPadding: 20
    bottomPadding: 20
    leftPadding: 30
    rightPadding: 30

    property string dialogTitle: ""
    property string dialogMessage: ""
    property var applicationWindow

    function show(title, message) {
        dialogTitle = title
        dialogMessage = message
        visible = true
    }

    background: Rectangle {
        color: applicationWindow.base
        radius: 12
        border.color: applicationWindow.green
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
                color: applicationWindow.green
                radius: 12

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    font.family: "Roboto"
                    font.pointSize: 14
                    font.weight: Font.Bold
                    color: applicationWindow.base
                }
            }

            Text {
                text: infoDialog.dialogTitle
                font.family: "Roboto"
                font.pointSize: 16
                font.weight: Font.Bold
                color: applicationWindow.green
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
                id: infoDialogMessageFlickable
                anchors.fill: parent
                contentWidth: parent.width
                contentHeight: infoDialogMessageText.height
                clip: true
                flickableDirection: Flickable.HorizontalAndVerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: CustomScrollBar {
                    orientation: Qt.Vertical
                }

                MultiLangText {
                    id: infoDialogMessageText
                    width: parent.width
                    height: implicitHeight
                    rawText: infoDialog.dialogMessage
                    font.pointSize: 11
                    color: applicationWindow.text
                    wrapMode: Text.Wrap
                    textFormat: Text.StyledText
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: applicationWindow.surface2
            Layout.topMargin: 15
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 15

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                width: 80
                height: 35
                color: infoOkMouseArea.containsMouse ? applicationWindow.blue : applicationWindow.surface1
                radius: 4
                border.color: applicationWindow.blue
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "OK"
                    font.family: "Roboto"
                    font.pointSize: 10
                    font.weight: Font.Bold
                    color: infoOkMouseArea.containsMouse ? applicationWindow.base : applicationWindow.text
                }

                MouseArea {
                    id: infoOkMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: infoDialog.close()
                }
            }
        }
    }
}
