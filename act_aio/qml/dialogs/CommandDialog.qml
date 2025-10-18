import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

// Command Dialog
Rectangle {
    id: commandDialog
    anchors.fill: parent
    color: "#80000000"
    visible: false
    z: 2000

    property string displayName: ""
    property string pluginName: ""
    property var commands: []
    property int selectedIndex: -1
    property var applicationWindow
    property var pluginManager

    function open() {
        selectedIndex = -1
        visible = true
    }

    function close() {
        visible = false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPressed: mouse.accepted = true
        onReleased: mouse.accepted = true
        onPositionChanged: (mouse) => {
            mouse.accepted = true;
        }
        onWheel: (wheel) =>  {
            wheel.accepted = true
        }
    }

    Rectangle {
        id: commandDialogContent
        width: 600
        height: 450
        color: applicationWindow.base
        radius: 12
        border.color: applicationWindow.surface1
        border.width: 2
        anchors.centerIn: parent

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 30
            anchors.rightMargin: 30
            anchors.topMargin: 20
            anchors.bottomMargin: 20
            spacing: 15

            RowLayout {
                Layout.fillWidth: true

                MultiLangText {
                    rawText: "Command Snippets - " + commandDialog.displayName
                    wrapMode: Text.NoWrap
                    maxLines: 1
                    elide: Text.ElideRight
                    font.pointSize: 16
                    font.weight: Font.Bold
                    color: applicationWindow.text
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 30
                    height: 30
                    color: commandCloseMouseArea.containsMouse ? applicationWindow.red : "transparent"
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
                        id: commandCloseMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: commandDialog.close()
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
                color: applicationWindow.surface0
                radius: 8
                border.color: applicationWindow.surface1
                border.width: 1

                ListView {
                    id: commandListView
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.rightMargin: 2
                    model: commandDialog.commands
                    spacing: 4
                    clip: true

                    ScrollBar.vertical: CustomScrollBar {
                        orientation: Qt.Vertical
                        bottomPadding: 8
                    }

                    delegate: Rectangle {
                        width: commandListView.width - 10
                        height: commandItemColumn.height + 20
                        color: commandDialog.selectedIndex === index ? applicationWindow.surface2 : (commandItemMouseArea.containsMouse ? applicationWindow.surface1 : "transparent")
                        radius: 4
                        border.color: commandDialog.selectedIndex === index ? applicationWindow.blue : "transparent"
                        border.width: commandDialog.selectedIndex === index ? 2 : 0

                        property var commandData: modelData

                        ColumnLayout {
                            id: commandItemColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.topMargin: 10
                            spacing: 5

                            MultiLangText {
                                rawText: commandData.name
                                font.pointSize: 12
                                font.weight: Font.Bold
                                color: commandDialog.selectedIndex === index ? applicationWindow.blue : applicationWindow.text
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                            }

                            MultiLangText {
                                rawText: "- " + (commandData.description || "")
                                font.pointSize: 10
                                color: applicationWindow.subtext0
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                visible: commandData.description && commandData.description.length > 0
                                renderType: Text.NativeRendering
                            }

                            MultiLangText {
                                rawText: commandData.command
                                font.pointSize: 9
                                color: applicationWindow.overlay2
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                visible: false
                            }
                        }

                        MouseArea {
                            id: commandItemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                commandDialog.selectedIndex = index
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: applicationWindow.surface2
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 100
                    height: 35
                    color: commandCancelMouseArea.containsMouse ? applicationWindow.surface1 : applicationWindow.surface0
                    radius: 4
                    border.color: applicationWindow.overlay0
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        font.family: "Roboto"
                        font.pointSize: 10
                        color: applicationWindow.text
                    }

                    MouseArea {
                        id: commandCancelMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: commandDialog.close()
                    }
                }

                Rectangle {
                    width: 100
                    height: 35
                    color: commandDialog.selectedIndex >= 0 ? (commandExecuteMouseArea.containsMouse ? applicationWindow.blue : applicationWindow.surface1) : applicationWindow.overlay0
                    radius: 4
                    border.color: commandDialog.selectedIndex >= 0 ? applicationWindow.blue : applicationWindow.overlay1
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "Execute"
                        font.family: "Roboto"
                        font.pointSize: 10
                        font.weight: Font.Bold
                        color: commandExecuteMouseArea.containsMouse ? applicationWindow.base : (commandDialog.selectedIndex >= 0 ? applicationWindow.text : applicationWindow.subtext0)
                    }

                    MouseArea {
                        id: commandExecuteMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: commandDialog.selectedIndex >= 0
                        onClicked: {
                            if (commandDialog.selectedIndex >= 0) {
                                var selectedCommand = commandDialog.commands[commandDialog.selectedIndex]
                                pluginManager.executeCommand(
                                    commandDialog.pluginName,
                                    selectedCommand.command
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
