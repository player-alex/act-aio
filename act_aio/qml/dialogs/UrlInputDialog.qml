import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: urlInputDialog
    width: 500
    height: Math.max(260, implicitHeight)
    anchors.centerIn: parent
    modal: true
    focus: true
    visible: false
    closePolicy: Popup.CloseOnEscape

    topPadding: 20
    bottomPadding: 20
    leftPadding: 30
    rightPadding: 30

    property var applicationWindow
    property var pluginManager
    property bool isLoading: false
    property int progressPercent: 0
    property string progressStatus: ""

    function show() {
        urlTextField.text = ""
        isLoading = false
        progressPercent = 0
        progressStatus = ""
        visible = true
        urlTextField.forceActiveFocus()
    }

    Connections {
        target: pluginManager
        function onImportSucceeded() {
            urlInputDialog.close()
        }
        function onImportStarted() {
            isLoading = true
            progressPercent = 0
            progressStatus = "Starting download..."
        }
        function onImportProgress(percent, status) {
            progressPercent = percent
            progressStatus = status
        }
        function onImportFinished(success) {
            isLoading = false
            // if (success) {
            //     urlInputDialog.close()
            // }
        }
    }

    background: Rectangle {
        color: applicationWindow.base
        radius: 12
        border.color: applicationWindow.blue
        border.width: 2
    }

    contentItem: ColumnLayout {
        spacing: 15
        Layout.fillWidth: true
        height: Math.max(200, parent.height)

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                width: 24
                height: 24
                color: applicationWindow.blue
                radius: 12

                Text {
                    anchors.centerIn: parent
                    text: "↓"
                    font.family: "Roboto"
                    font.pointSize: 14
                    font.weight: Font.Bold
                    color: applicationWindow.base
                }
            }

            Text {
                text: "Import Plugin from URL"
                font.family: "Roboto"
                font.pointSize: 16
                font.weight: Font.Bold
                color: applicationWindow.blue
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

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Text {
                    text: "Enter the URL of the plugin zip file:"
                    font.family: "Roboto"
                    font.pointSize: 11
                    color: applicationWindow.text
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: applicationWindow.surface0
                    radius: 6
                    border.color: urlTextField.activeFocus ? applicationWindow.blue : applicationWindow.surface1
                    border.width: urlTextField.activeFocus ? 2 : 1

                    TextField {
                        id: urlTextField
                        anchors.fill: parent
                        anchors.margins: 8
                        placeholderText: "https://example.com/plugin.zip"
                        font.family: "Roboto"
                        font.pointSize: 10
                        color: applicationWindow.text
                        placeholderTextColor: applicationWindow.subtext0
                        verticalAlignment: TextInput.AlignVCenter
                        topPadding: 0
                        bottomPadding: 0
                        leftPadding: 4
                        rightPadding: 4
                        enabled: !isLoading
                        background: Rectangle {
                            color: "transparent"
                        }
                        onAccepted: {
                            if (urlTextField.text.trim() !== "" && !isLoading) {
                                pluginManager.importPluginFromUrl(urlTextField.text.trim())
                            }
                        }
                    }
                }

                // Progress section - only visible when loading
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    visible: isLoading
                    Layout.topMargin: 5

                    // Status text
                    Text {
                        text: progressStatus
                        font.family: "Roboto"
                        font.pointSize: 9
                        color: applicationWindow.subtext0
                        Layout.fillWidth: true
                    }

                    // Progress bar container
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        color: applicationWindow.surface0
                        radius: 4
                        border.color: applicationWindow.surface1
                        border.width: 1

                        // Progress bar fill
                        Rectangle {
                            width: parent.width * (progressPercent / 100.0)
                            height: parent.height
                            color: applicationWindow.blue
                            radius: 4

                            Behavior on width {
                                NumberAnimation {
                                    duration: 100
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                    }

                    // Progress percentage text
                    Text {
                        text: progressPercent + "%"
                        font.family: "Roboto"
                        font.pointSize: 9
                        font.weight: Font.Bold
                        color: applicationWindow.blue
                        Layout.alignment: Qt.AlignRight
                    }
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
                color: cancelMouseArea.containsMouse ? applicationWindow.surface1 : applicationWindow.surface0
                radius: 4
                border.color: applicationWindow.overlay0
                border.width: 1
                opacity: isLoading ? 0.5 : 1.0

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.family: "Roboto"
                    font.pointSize: 10
                    color: applicationWindow.text
                }

                MouseArea {
                    id: cancelMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !isLoading
                    onClicked: {
                        urlInputDialog.close()
                    }
                }
            }

            Rectangle {
                width: 80
                height: 35
                color: okMouseArea.containsMouse ? applicationWindow.blue : applicationWindow.surface1
                radius: 4
                border.color: applicationWindow.blue
                border.width: 1
                opacity: (urlTextField.text.trim() === "" || isLoading) ? 0.5 : 1.0

                Text {
                    anchors.centerIn: parent
                    text: isLoading ? "Loading..." : "OK"
                    font.family: "Roboto"
                    font.pointSize: 10
                    font.weight: Font.Bold
                    color: okMouseArea.containsMouse ? applicationWindow.base : applicationWindow.text
                }

                MouseArea {
                    id: okMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: urlTextField.text.trim() !== "" && !isLoading
                    onClicked: {
                        pluginManager.importPluginFromUrl(urlTextField.text.trim())
                    }
                }
            }
        }
    }
}
