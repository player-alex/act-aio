import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Dialog {
    id: aboutDialog
    width: 550
    height: implicitHeight - 10
    anchors.centerIn: parent
    modal: true
    focus: true
    visible: false
    padding: 20
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnClickedOutside

    property string repositoryUrl: ""
    property var dependencies: []
    property string licenseText: ""
    property var applicationWindow
    property var pluginManager

    function open() {
        var info = pluginManager.getSystemInfo()
        repositoryUrl = info.repository
        dependencies = info.dependencies
        licenseText = info.license_text
        visible = true
    }

    background: Rectangle {
        color: applicationWindow.base
        radius: 12
        border.color: applicationWindow.surface1
        border.width: 2
    }

    contentItem: ColumnLayout {
        spacing: 15

        // Title
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "About Actions All-In-One"
                font.family: "Roboto"
                font.pointSize: 16
                color: applicationWindow.text
                Layout.fillWidth: true
            }
            Text {
                text: "player-alex"
                font.family: "Roboto"
                font.pointSize: 10
                color: applicationWindow.subtext0
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: applicationWindow.surface2 }

        // Repository
        RowLayout {
            Text {
                text: "Repository:"
                font.family: "Roboto"
                font.pointSize: 11
                font.weight: Font.Bold
                color: applicationWindow.text
            }
            Text {
                text: '<a href="' + aboutDialog.repositoryUrl + '"><font color="' + applicationWindow.text + '">' + aboutDialog.repositoryUrl + '</font></a>'
                font.family: "Roboto"
                font.pointSize: 11
                textFormat: Text.RichText

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        Qt.openUrlExternally(aboutDialog.repositoryUrl)
                    }
                }
            }
        }

        // Dependencies
        Text {
            text: "Dependencies"
            font.family: "Roboto"
            font.pointSize: 12
            font.weight: Font.Bold
            color: applicationWindow.text
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: applicationWindow.surface0
            radius: 4

            Flickable {
                anchors.fill: parent
                anchors.margins: 8
                contentHeight: depsColumn.height
                clip: true

                Column {
                    id: depsColumn
                    spacing: 5
                    Repeater {
                        model: aboutDialog.dependencies
                        delegate: Text {
                            text: '<a href="' + modelData.url + '"><font color="' + applicationWindow.text + '">' + modelData.name + '</font></a>'
                            font.family: "Roboto"
                            font.pointSize: 10
                            textFormat: Text.RichText
                            onLinkActivated: Qt.openUrlExternally(link)

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    Qt.openUrlExternally(modelData.url)
                                }
                            }
                        }
                    }
                }
            }
        }

        // License
        Text {
            text: "License"
            font.family: "Roboto"
            font.pointSize: 12
            font.weight: Font.Bold
            color: applicationWindow.text
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
                id: licenseFlickable
                anchors.fill: parent
                anchors.margins: 8
                anchors.rightMargin: 2
                contentWidth: Math.max(width, licenseTextx ? licenseTextx.width : 0)
                contentHeight: licenseTextx.height
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

                Text {
                    id: licenseTextx
                    width: Math.max(licenseFlickable.width, implicitWidth)
                    height: implicitHeight
                    text: aboutDialog.licenseText
                    wrapMode: Text.NoWrap
                    font.family: "Roboto"
                    font.pointSize: 9
                    color: applicationWindow.subtext0
                    padding: 10
                }
            }
        }

        // Close Button
        Rectangle {
            width: parent.width
            height: 55
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.bottomMargin: 10
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 100
                    height: 35
                    color: aboutCloseMouseArea.containsMouse ? applicationWindow.surface1 : applicationWindow.surface0
                    radius: 4
                    border.color: applicationWindow.overlay0
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        font.family: "Roboto"
                        font.pointSize: 10
                        color: applicationWindow.text
                    }

                    MouseArea {
                        id: aboutCloseMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: aboutDialog.close()
                    }
                }
            }
        }

    }
}
