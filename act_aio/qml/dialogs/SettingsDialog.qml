import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: settingsDialog
    width: 500
    height: 450
    anchors.centerIn: parent
    modal: true
    focus: true
    visible: false
    closePolicy: Popup.CloseOnEscape

    topPadding: 20
    bottomPadding: 20
    leftPadding: 25
    rightPadding: 25

    property var envSettings: ({})
    property var applicationWindow
    property var pluginManager

    ListModel {
        id: envListModel
    }

    function open() {
        envSettings = pluginManager.getEnvironmentSettings()
        envListModel.clear()

        // Load environment variables from .env file
        var envVars = pluginManager.getEnvironmentVariables()
        for (var key in envVars) {
            envListModel.append({
                "key": key,
                "value": envVars[key],
                "enabled": envSettings[key] === true
            })
        }
        visible = true
    }

    background: Rectangle {
        color: applicationWindow.base
        radius: 12
        border.color: applicationWindow.surface1
        border.width: 2
    }

    contentItem: ColumnLayout {
        spacing: 10

        // Title bar
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Settings"
                font.family: "Roboto"
                font.pointSize: 16
                font.weight: Font.Bold
                color: applicationWindow.text
                Layout.fillWidth: true
            }

            Rectangle {
                width: 30
                height: 30
                color: closeMouseArea.containsMouse ? applicationWindow.red : "transparent"
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
                    id: closeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: settingsDialog.close()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: applicationWindow.surface2
        }

        Text {
            text: "Environment Variables"
            font.family: "Roboto"
            font.pointSize: 14
            font.weight: Font.Bold
            color: applicationWindow.text
            Layout.bottomMargin: 5
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 200
            color: applicationWindow.surface0
            radius: 8
            border.color: applicationWindow.surface1
            border.width: 1

            Flickable {
                id: envFlickable
                anchors.fill: parent
                anchors.margins: 8
                anchors.rightMargin: 2
                contentWidth: Math.max(width, envListView.contentItem ? envListView.contentItem.childrenRect.width : 0)
                contentHeight: envListView.contentHeight
                clip: true
                flickableDirection: Flickable.HorizontalAndVerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: CustomScrollBar {
                    orientation: Qt.Vertical
                    bottomPadding: 8
                }

                ScrollBar.horizontal: CustomScrollBar {
                    orientation: Qt.Horizontal
                    rightPadding: 8
                }

                ListView {
                    id: envListView
                    width: Math.max(envFlickable.width, implicitWidth)
                    height: contentHeight
                    model: envListModel
                    spacing: 2
                    clip: false
                    interactive: false

                    footer: Item {
                        width: 1
                        height: 10
                    }

                    property real implicitWidth: {
                        var maxWidth = 0
                        for (var i = 0; i < count; i++) {
                            var item = itemAtIndex(i)
                            if (item) {
                                maxWidth = Math.max(maxWidth, item.implicitWidth)
                            }
                        }
                        return maxWidth
                    }

                    delegate: Rectangle {
                        width: Math.max(envListView.width, implicitWidth)
                        height: 35
                        color: envItemMouseArea.containsMouse ? applicationWindow.surface1 : "transparent"
                        radius: 4

                        property real implicitWidth: envRowLayout.implicitWidth

                        RowLayout {
                            id: envRowLayout
                            height: parent.height
                            spacing: 10

                            Item { width: 10; height: 1 }

                            Rectangle {
                                width: 20
                                height: 20
                                color: "transparent"
                                border.color: model.enabled ? applicationWindow.blue : applicationWindow.overlay1
                                border.width: 2
                                radius: 3

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    color: applicationWindow.blue
                                    radius: 2
                                    visible: model.enabled
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        var newEnabled = !model.enabled
                                        envListModel.setProperty(index, "enabled", newEnabled)
                                        settingsDialog.envSettings[model.key] = newEnabled
                                        console.log("Updated", model.key, "to", newEnabled)
                                        console.log("Current envSettings:", JSON.stringify(settingsDialog.envSettings))
                                    }
                                }
                            }

                            Text {
                                id: keyText
                                text: model.key
                                font.family: "Roboto"
                                font.pointSize: 10
                                font.weight: Font.Bold
                                color: applicationWindow.text
                                Layout.minimumWidth: contentWidth
                            }

                            Rectangle {
                                width: 1
                                height: 20
                                color: applicationWindow.overlay0
                            }

                            Text {
                                id: valueText
                                text: model.value
                                font.family: "Roboto"
                                font.pointSize: 10
                                color: applicationWindow.subtext0
                                Layout.minimumWidth: contentWidth
                            }

                            Item { width: 10; height: 1 }
                        }

                        MouseArea {
                            id: envItemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
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
            Layout.topMargin: 5
            Layout.bottomMargin: 5

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                width: 100
                height: 35
                color: cancelMouseArea.containsMouse ? applicationWindow.surface1 : applicationWindow.surface0
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
                    id: cancelMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: settingsDialog.close()
                }
            }

            Rectangle {
                width: 100
                height: 35
                color: saveMouseArea.containsMouse ? applicationWindow.blue : applicationWindow.surface1
                radius: 4
                border.color: applicationWindow.blue
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Save"
                    font.family: "Roboto"
                    font.pointSize: 10
                    color: saveMouseArea.containsMouse ? applicationWindow.base : applicationWindow.text
                }

                MouseArea {
                    id: saveMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        console.log("Saving environment settings:", JSON.stringify(settingsDialog.envSettings))
                        pluginManager.setEnvironmentSettings(settingsDialog.envSettings)
                        settingsDialog.close()
                    }
                }
            }
        }
    }
}
