import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: errorDialog
    width: 500
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

    property string errorTitle: "Error"
    property string errorMessage: ""
    property var applicationWindow

    function show(title, message) {
        errorTitle = title
        errorMessage = message
        visible = true
    }

    background: Rectangle {
        color: applicationWindow.base
        radius: 12
        border.color: applicationWindow.red
        border.width: 2
    }

    contentItem: ColumnLayout {
        spacing: 15
        Layout.fillWidth: true
        height: Math.max(250, parent.height)

        // Title bar
        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                width: 24
                height: 24
                color: applicationWindow.red
                radius: 12

                Text {
                    anchors.centerIn: parent
                    text: "!"
                    font.family: "Roboto"
                    font.pointSize: 14
                    font.weight: Font.Bold
                    color: applicationWindow.base
                }
            }

            Text {
                text: errorDialog.errorTitle
                font.family: "Roboto"
                font.pointSize: 16
                font.weight: Font.Bold
                color: applicationWindow.red
                Layout.fillWidth: true
            }

            Rectangle {
                width: 30
                height: 30
                color: errorCloseMouseArea.containsMouse ? applicationWindow.red : "transparent"
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.family: "Roboto"
                    font.pointSize: 16
                    font.weight: Font.Bold
                    color: applicationWindow.text
                }

                MouseArea {
                    id: errorCloseMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: errorDialog.close()
                }
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
                id: errorDialogMessageFlickable
                anchors.fill: parent
                contentWidth: parent.width
                contentHeight: errorDialogMessageText.height
                clip: true
                flickableDirection: Flickable.HorizontalAndVerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: CustomScrollBar {
                    orientation: Qt.Vertical
                }

                MultiLangText {
                    id: errorDialogMessageText
                    width: parent.width
                    height: implicitHeight
                    rawText: errorDialog.errorMessage
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
            Layout.rightMargin: 30
            Layout.bottomMargin: 20

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                width: 80
                height: 35
                color: errorOkMouseArea.containsMouse ? applicationWindow.blue : applicationWindow.surface1
                radius: 4
                border.color: applicationWindow.blue
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "OK"
                    font.family: "Roboto"
                    font.pointSize: 10
                    font.weight: Font.Bold
                    color: errorOkMouseArea.containsMouse ? applicationWindow.base : applicationWindow.text
                }

                MouseArea {
                    id: errorOkMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: errorDialog.close()
                }
            }
        }
    }
}
