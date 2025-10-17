import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import ActAio 1.0
import "components"

ApplicationWindow {
    id: window
    width: Math.max(600, Screen.width * 0.4)
    height: Math.max(700, Screen.height * 0.75)
    visible: true
    title: "Actions All-In-One"

    Component.onCompleted: {
        // Center the window on screen
        x = (Screen.width - width) / 2
        y = (Screen.height - height) / 2
    }

    // Catppuccin Mocha color scheme
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"
    property color base: "#1e1e2e"
    property color mantle: "#181825"
    property color crust: "#11111b"
    property color text: "#cdd6f4"
    property color subtext1: "#bac2de"
    property color subtext0: "#a6adc8"
    property color overlay2: "#9399b2"
    property color overlay1: "#7f849c"
    property color overlay0: "#6c7086"
    property color lavender: "#b4befe"
    property color blue: "#89b4fa"
    property color sapphire: "#74c7ec"
    property color sky: "#89dceb"
    property color teal: "#94e2d5"
    property color green: "#a6e3a1"
    property color yellow: "#f9e2af"
    property color peach: "#fab387"
    property color maroon: "#eba0ac"
    property color red: "#f38ba8"
    property color mauve: "#cba6f7"
    property color pink: "#f5c2e7"
    property color flamingo: "#f2cdcd"
    property color rosewater: "#f5e0dc"

    color: base

    // Plugin Manager
    PluginManager {
        id: pluginManager

        onErrorOccurred: function(title, message) {
            errorDialog.show(title, message)
        }

        onSetupStarted: function(pluginName) {
            setupDialog.show(pluginName)
        }

        onSetupFinished: {
            setupDialog.close()
        }

        onConfirmationRequested: function(title, message, callbackId) {
            confirmationDialog.show(title, message, callbackId)
        }

        onInfoMessageRequested: function(title, message) {
            infoDialog.show(title, message)
        }
    }

    // Plugin List Model
    PluginListModel {
        id: pluginListModel
        pluginManager: pluginManager
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Top Bar with Menu and Settings
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            // Menu Button (left)
            Rectangle {
                id: menuButton
                width: 40
                height: 40
                color: menuMouseArea.containsMouse ? window.surface1 : window.surface0
                radius: 8
                border.color: window.overlay0
                border.width: 1

                // Menu icon (three horizontal lines)
                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: 3
                        Rectangle {
                            width: 18
                            height: 2
                            color: window.text
                            radius: 1
                        }
                    }
                }

                MouseArea {
                    id: menuMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: menuDropdown.visible = !menuDropdown.visible
                }
            }

            // Title (center)
            Text {
                Layout.fillWidth: true
                text: "Actions All-In-One"
                font.family: "Roboto"
                font.pointSize: 18
                font.weight: Font.Bold
                color: window.text
                horizontalAlignment: Text.AlignHCenter
            }

            // Settings Button (right)
            Rectangle {
                id: settingsButton
                width: 40
                height: 40
                color: settingsMouseArea.containsMouse ? window.surface1 : window.surface0
                radius: 8
                border.color: window.overlay0
                border.width: 1

                // Settings icon (gear)
                Canvas {
                    id: settingsIcon
                    width: 20
                    height: 20
                    anchors.centerIn: parent

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.fillStyle = window.text
                        ctx.strokeStyle = window.text
                        ctx.lineWidth = 1.5

                        // Draw gear icon
                        ctx.beginPath()
                        ctx.arc(10, 10, 6, 0, 2 * Math.PI)
                        ctx.stroke()

                        // Draw gear teeth
                        for (var i = 0; i < 8; i++) {
                            var angle = (i * Math.PI) / 4
                            var x1 = 10 + Math.cos(angle) * 8
                            var y1 = 10 + Math.sin(angle) * 8
                            var x2 = 10 + Math.cos(angle) * 10
                            var y2 = 10 + Math.sin(angle) * 10
                            ctx.moveTo(x1, y1)
                            ctx.lineTo(x2, y2)
                        }
                        ctx.stroke()

                        // Center hole
                        ctx.beginPath()
                        ctx.arc(10, 10, 3, 0, 2 * Math.PI)
                        ctx.stroke()
                    }
                }

                MouseArea {
                    id: settingsMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: settingsDialog.open()
                }
            }
        }

        // Search Box
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            color: window.surface0
            radius: 8
            border.color: searchField.activeFocus ? window.blue : window.surface1
            border.width: searchField.activeFocus ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Search Icon
                Canvas {
                    id: searchIcon
                    width: 20
                    height: 20
                    Layout.alignment: Qt.AlignVCenter

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = window.subtext0
                        ctx.lineWidth = 2

                        // Draw magnifying glass circle
                        ctx.beginPath()
                        ctx.arc(8, 8, 6, 0, 2 * Math.PI)
                        ctx.stroke()

                        // Draw handle
                        ctx.beginPath()
                        ctx.moveTo(13, 13)
                        ctx.lineTo(18, 18)
                        ctx.stroke()
                    }
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "Search plugins..."
                    font.family: "Roboto"
                    font.pointSize: 11
                    color: window.text
                    placeholderTextColor: window.subtext0
                    verticalAlignment: TextInput.AlignVCenter
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    background: Rectangle {
                        color: "transparent"
                    }
                    onTextChanged: {
                        pluginListModel.searchText = text
                    }
                }

                // Clear button (visible when text is entered)
                Rectangle {
                    width: 20
                    height: 20
                    color: clearMouseArea.containsMouse ? window.surface2 : "transparent"
                    radius: 10
                    visible: searchField.text.length > 0
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.family: "Roboto"
                        font.pointSize: 14
                        font.weight: Font.Bold
                        color: window.subtext0
                    }

                    MouseArea {
                        id: clearMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: searchField.text = ""
                    }
                }
            }
        }

        // Plugin List
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: window.surface0
            radius: 12
            border.color: window.surface1
            border.width: 1
                            
		ListView {                                
		id: pluginListView                
		anchors.fill: parent
                anchors.margins: 0
                anchors.rightMargin: 0
                model: pluginListModel
                spacing: 8
                clip: true

                ScrollBar.vertical: ScrollBar {
                    id: vbar
                    policy: ScrollBar.AsNeeded
                    padding: 0
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    hoverEnabled: true
                    active: true
                    orientation: Qt.Vertical

                    background: Rectangle {
                        implicitWidth: 10
                        color: window.surface0
                        radius: 5
                    }

                    contentItem: Rectangle {
                        implicitWidth: 10
                        color: window.overlay0
                        radius: 5
                        visible: vbar.size < 1.0
                    }
                }

                delegate: PluginListItem {
                    width: pluginListView.width - vbar.width
                    pluginName: model.displayName
                    pluginDescription: model.description
                    pluginVersion: model.version
                    isExecutable: model.executable
                    isSelected: index === pluginListModel.selectedIndex
                    manuals: model.manuals
                    tags: model.tags
                    commands: model.commands

                    onClicked: {
                        pluginListModel.selectedIndex = index
                    }

                    onOpenDirectoryButtonClicked: {
                        pluginManager.openPluginDirectory(model.name)
                    }

                    onCommandButtonClicked: {
                        console.log("Command button clicked for:", model.name)
                        console.log("model.commands:", JSON.stringify(model.commands))
                        commandDialog.pluginName = model.name
                        commandDialog.commands = model.commands || []
                        console.log("commandDialog.commands after assignment:", JSON.stringify(commandDialog.commands))
                        commandDialog.open()
                    }

                    onManualButtonClicked: {
                        manualDialog.pluginName = model.name
                        manualDialog.manuals = model.manuals
                        manualDialog.open()
                    }
                }

                // Show message when no plugins are found
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: noPluginsText.height + 40
                    color: "transparent"
                    visible: pluginListView.count === 0

                    Text {
                        id: noPluginsText
                        anchors.centerIn: parent
                        text: "No plugins found in ./plugins directory"
                        font.family: "Roboto"
                        font.pointSize: 14
                        color: window.subtext0
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
        }

        // Bottom Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 120
                height: 40
                color: window.surface1
                radius: 4
                border.color: window.overlay0
                border.width: 1
                scale: mouseArea.containsMouse ? 1.05 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Refresh"
                    font.family: "Roboto"
                    font.pointSize: 10
                    font.weight: Font.Bold
                    color: window.text
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        pluginListModel.refresh()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                id: launchButton
                width: 120
                height: 40
                color: pluginListModel.canLaunch ? window.blue : window.overlay0
                radius: 4
                border.color: pluginListModel.canLaunch ? window.blue : window.overlay1
                border.width: 1
                scale: (launchMouseArea.containsMouse && pluginListModel.canLaunch) ? 1.05 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Launch"
                    font.family: "Roboto"
                    font.pointSize: 10
                    font.weight: Font.Bold
                    color: pluginListModel.canLaunch ? window.base : window.subtext0
                }

                MouseArea {
                    id: launchMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: pluginListModel.canLaunch
                    onClicked: {
                        if (pluginListModel.launchSelected()) {
                            console.log("Plugin launched successfully")
                        } else {
                            console.log("Failed to launch plugin")
                        }
                    }
                }
            }
        }
    }

    // Dropdown Menu (outside the layout hierarchy for proper z-ordering)
    Rectangle {
        id: menuDropdown
        width: 120
        height: importExportColumn.height + 20
        color: window.surface1
        radius: 8
        border.color: window.overlay0
        border.width: 1
        visible: false
        x: 20  // Same as left margin
        y: 80  // Below the top bar
        z: 1000  // Very high z-index

        // Consume clicks inside the menu to prevent closing
        MouseArea {
            anchors.fill: parent
            onClicked: {} // Do nothing, just consume the click
            hoverEnabled: false
        }

        Column {
            id: importExportColumn
            anchors.centerIn: parent
            spacing: 8

            // Import Button
            Rectangle {
                width: 100
                height: 30
                color: importMouseArea.containsMouse ? window.blue : "transparent"
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "Import"
                    font.family: "Roboto"
                    font.pointSize: 10
                    color: importMouseArea.containsMouse ? window.base : window.text
                }

                MouseArea {
                    id: importMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        menuDropdown.visible = false
                        pluginManager.importPlugin()
                    }
                }
            }

            // Export Button
            Rectangle {
                width: 100
                height: 30
                color: exportMouseArea.containsMouse && pluginListModel.canLaunch ? window.green : "transparent"
                radius: 4
                opacity: pluginListModel.canLaunch ? 1.0 : 0.5

                Text {
                    anchors.centerIn: parent
                    text: "Export"
                    font.family: "Roboto"
                    font.pointSize: 10
                    color: exportMouseArea.containsMouse && pluginListModel.canLaunch ? window.base : window.text
                }

                MouseArea {
                    id: exportMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (pluginListModel.canLaunch) {
                            menuDropdown.visible = false
                            pluginManager.exportPlugin(pluginListModel.selectedPluginPath)
                        }
                    }
                }
            }

            Rectangle {
                width: 100
                height: 30
                color: aboutMouseArea.containsMouse ? window.blue : "transparent"
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "About"
                    font.family: "Roboto"
                    font.pointSize: 10
                    color: aboutMouseArea.containsMouse ? window.base : window.text
                }

                MouseArea {
                    id: aboutMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        menuDropdown.visible = false
                        aboutDialog.open()
                    }
                }
            }
        }
    }

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

        function open() {
            var info = pluginManager.getSystemInfo()
            repositoryUrl = info.repository
            dependencies = info.dependencies
            licenseText = info.license_text
            visible = true
        }

        background: Rectangle {
            color: window.base
            radius: 12
            border.color: window.surface1
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
                    color: window.text
                    Layout.fillWidth: true
                }
                Text {
                    text: "player-alex"
                    font.family: "Roboto"
                    font.pointSize: 10
                    color: window.subtext0
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: window.surface2 }

            // Repository
            RowLayout {
                Text {
                    text: "Repository:"
                    font.family: "Roboto"
                    font.pointSize: 11
                    font.weight: Font.Bold
                    color: window.text
                }
                Text {
                    text: '<a href="' + aboutDialog.repositoryUrl + '"><font color="' + window.text + '">' + aboutDialog.repositoryUrl + '</font></a>'
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
                color: window.text
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: window.surface0
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
                                text: '<a href="' + modelData.url + '"><font color="' + window.text + '">' + modelData.name + '</font></a>'
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
                color: window.text
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 200
                color: window.surface0
                radius: 8
                border.color: window.surface1
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
                        color: window.subtext0
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
                        color: aboutCloseMouseArea.containsMouse ? window.surface1 : window.surface0
                        radius: 4
                        border.color: window.overlay0
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "Close"
                            font.family: "Roboto"
                            font.pointSize: 10
                            color: window.text
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
            color: window.base
            radius: 12
            border.color: window.surface1
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
                    color: window.text
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 30
                    height: 30
                    color: closeMouseArea.containsMouse ? window.red : "transparent"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.family: "Roboto"
                        font.pointSize: 16
                        font.weight: Font.Bold
                        color: window.text
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
                color: window.surface2
            }

            Text {
                text: "Environment Variables"
                font.family: "Roboto"
                font.pointSize: 14
                font.weight: Font.Bold
                color: window.text
                Layout.bottomMargin: 5
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 200
                color: window.surface0
                radius: 8
                border.color: window.surface1
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
                            color: envItemMouseArea.containsMouse ? window.surface1 : "transparent"
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
                                    border.color: model.enabled ? window.blue : window.overlay1
                                    border.width: 2
                                    radius: 3

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 10
                                        color: window.blue
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
                                    color: window.text
                                    Layout.minimumWidth: contentWidth
                                }

                                Rectangle {
                                    width: 1
                                    height: 20
                                    color: window.overlay0
                                }

                                Text {
                                    id: valueText
                                    text: model.value
                                    font.family: "Roboto"
                                    font.pointSize: 10
                                    color: window.subtext0
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
        }

        footer: ColumnLayout {
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: window.surface2
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.topMargin: 10
                Layout.bottomMargin: 20
                Layout.rightMargin: 25

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 100
                    height: 35
                    color: cancelMouseArea.containsMouse ? window.surface1 : window.surface0
                    radius: 4
                    border.color: window.overlay0
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        font.family: "Roboto"
                        font.pointSize: 10
                        color: window.text
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
                    color: saveMouseArea.containsMouse ? window.blue : window.surface1
                    radius: 4
                    border.color: window.blue
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        font.family: "Roboto"
                        font.pointSize: 10
                        color: saveMouseArea.containsMouse ? window.base : window.text
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

    // Setup Dialog (Loading)
    Rectangle {
        id: setupDialog
        anchors.fill: parent
        color: "#80000000"
        visible: false
        z: 2500

        property string pluginName: ""

        function show(name) {
            pluginName = name
            visible = true
        }

        function close() {
            visible = false
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {}
            onPressed: {}
            onReleased: {}
            onPositionChanged: {}
            onWheel: { wheel.accepted = true }
        }

        Rectangle {
            width: 400
            height: 200
            color: window.base
            radius: 12
            border.color: window.surface1
            border.width: 2
            anchors.centerIn: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 20

                Text {
                    text: "Setting up " + setupDialog.pluginName
                    font.family: "Roboto"
                    font.pointSize: 16
                    font.weight: Font.Bold
                    color: window.text
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Text {
                    text: "Installing requirements...\nThis may take a few minutes."
                    font.family: "Roboto"
                    font.pointSize: 12
                    color: window.subtext0
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    id: progressBarContainer
                    Layout.fillWidth: true
                    height: 4
                    color: window.surface1
                    radius: 2

                    Rectangle {
                        id: progressBar
                        width: 0
                        height: parent.height
                        color: window.blue
                        radius: 2

                        SequentialAnimation on width {
                            loops: Animation.Infinite
                            running: setupDialog.visible

                            NumberAnimation {
                                from: 0
                                to: progressBarContainer.width
                                duration: 1500
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: progressBarContainer.width
                                to: 0
                                duration: 1500
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }
        }
    }

    // Manual Dialog
    Rectangle {
        id: manualDialog
        anchors.fill: parent
        color: "#80000000"
        visible: false
        z: 2000

        property string pluginName: ""
        property var manuals: []
        property int selectedIndex: -1

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
            onPositionChanged: mouse.accepted = true
            onWheel: { wheel.accepted = true }
        }

        Rectangle {
            id: manualDialogContent
            width: 500
            height: 400
            color: window.base
            radius: 12
            border.color: window.surface1
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

                    Text {
                        text: "Manuals - " + manualDialog.pluginName
                        font.family: "Roboto"
                        font.pointSize: 16
                        font.weight: Font.Bold
                        color: window.text
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 30
                        height: 30
                        color: manualCloseMouseArea.containsMouse ? window.red : "transparent"
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            font.family: "Roboto"
                            font.pointSize: 16
                            font.weight: Font.Bold
                            color: window.text
                        }

                        MouseArea {
                            id: manualCloseMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: manualDialog.close()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: window.surface2
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: window.surface0
                    radius: 8
                    border.color: window.surface1
                    border.width: 1

                    ListView {
                        id: manualListView
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.rightMargin: 2
                        model: manualDialog.manuals
                        spacing: 4
                        clip: true

                        ScrollBar.vertical: CustomScrollBar {
                            orientation: Qt.Vertical
                            bottomPadding: 8
                        }

                        delegate: Rectangle {
                            width: manualListView.width - 10
                            height: 40
                            color: manualDialog.selectedIndex === index ? window.surface2 : (manualItemMouseArea.containsMouse ? window.surface1 : "transparent")
                            radius: 4
                            border.color: manualDialog.selectedIndex === index ? window.blue : "transparent"
                            border.width: manualDialog.selectedIndex === index ? 2 : 0

                            property string manualPath: modelData

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    var parts = manualPath.split(/[\\\/]/)
                                    return parts[parts.length - 1]
                                }
                                font.family: "Roboto"
                                font.pointSize: 11
                                color: manualDialog.selectedIndex === index ? window.blue : window.text
                                font.weight: manualDialog.selectedIndex === index ? Font.Bold : Font.Normal
                                elide: Text.ElideMiddle
                                width: parent.width - 20
                            }

                            MouseArea {
                                id: manualItemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    manualDialog.selectedIndex = index
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: window.surface2
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 80
                        height: 35
                        color: manualCancelMouseArea.containsMouse ? window.surface1 : window.surface0
                        radius: 4
                        border.color: window.overlay0
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Close"
                            font.family: "Roboto"
                            font.pointSize: 10
                            color: window.text
                        }

                        MouseArea {
                            id: manualCancelMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: manualDialog.close()
                        }
                    }

                    Rectangle {
                        width: 80
                        height: 35
                        color: manualDialog.selectedIndex >= 0 ? (manualOpenMouseArea.containsMouse ? window.blue : window.surface1) : window.overlay0
                        radius: 4
                        border.color: manualDialog.selectedIndex >= 0 ? window.blue : window.overlay1
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "Open"
                            font.family: "Roboto"
                            font.pointSize: 10
                            font.weight: Font.Bold
                            color: manualOpenMouseArea.containsMouse ? window.base : (manualDialog.selectedIndex >= 0 ? window.text : window.subtext0)
                        }

                        MouseArea {
                            id: manualOpenMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: manualDialog.selectedIndex >= 0
                            onClicked: {
                                if (manualDialog.selectedIndex >= 0) {
                                    var selectedManual = manualDialog.manuals[manualDialog.selectedIndex]
                                    pluginManager.openManual(selectedManual)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Close dropdown when clicking outside
    MouseArea {
        anchors.fill: parent
        visible: menuDropdown.visible
        onClicked: menuDropdown.visible = false
        z: 50
    }

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

        function show(title, message) {
            errorTitle = title
            errorMessage = message
            visible = true
        }

        background: Rectangle {
            color: window.base
            radius: 12
            border.color: window.red
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
                    color: window.red
                    radius: 12

                    Text {
                        anchors.centerIn: parent
                        text: "!"
                        font.family: "Roboto"
                        font.pointSize: 14
                        font.weight: Font.Bold
                        color: window.base
                    }
                }

                Text {
                    text: errorDialog.errorTitle
                    font.family: "Roboto"
                    font.pointSize: 16
                    font.weight: Font.Bold
                    color: window.red
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 30
                    height: 30
                    color: errorCloseMouseArea.containsMouse ? window.red : "transparent"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.family: "Roboto"
                        font.pointSize: 16
                        font.weight: Font.Bold
                        color: window.text
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
                color: window.surface2
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

                    Text {
                        id: errorDialogMessageText
                        width: parent.width
                        height: implicitHeight
                        text: errorDialog.errorMessage
                        font.family: "Roboto"
                        font.pointSize: 11
                        color: window.text
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
                color: window.surface2
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
                    color: errorOkMouseArea.containsMouse ? window.blue : window.surface1
                    radius: 4
                    border.color: window.blue
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "OK"
                        font.family: "Roboto"
                        font.pointSize: 10
                        font.weight: Font.Bold
                        color: errorOkMouseArea.containsMouse ? window.base : window.text
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

        function show(title, message, cbId) {
            dialogTitle = title
            dialogMessage = message
            callbackId = cbId
            visible = true
        }

        background: Rectangle {
            color: window.base
            radius: 12
            border.color: window.yellow
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
                    color: window.yellow
                    radius: 12

                    Text {
                        anchors.centerIn: parent
                        text: "?"
                        font.family: "Roboto"
                        font.pointSize: 14
                        font.weight: Font.Bold
                        color: window.base
                    }
                }

                Text {
                    text: confirmationDialog.dialogTitle
                    font.family: "Roboto"
                    font.pointSize: 16
                    font.weight: Font.Bold
                    color: window.yellow
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: window.surface2
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

                    Text {
                        id: confirmationDialogMessageText
                        width: parent.width
                        height: implicitHeight
                        text: confirmationDialog.dialogMessage
                        font.family: "Roboto"
                        font.pointSize: 11
                        color: window.text
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
                color: window.surface2
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
                    color: confirmNoMouseArea.containsMouse ? window.surface1 : window.surface0
                    radius: 4
                    border.color: window.overlay0
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "No"
                        font.family: "Roboto"
                        font.pointSize: 10
                        color: window.text
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
                    color: confirmYesMouseArea.containsMouse ? window.blue : window.surface1
                    radius: 4
                    border.color: window.blue
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Yes"
                        font.family: "Roboto"
                        font.pointSize: 10
                        font.weight: Font.Bold
                        color: confirmYesMouseArea.containsMouse ? window.base : window.text
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

        function show(title, message) {
            dialogTitle = title
            dialogMessage = message
            visible = true
        }

        background: Rectangle {
            color: window.base
            radius: 12
            border.color: window.green
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
                    color: window.green
                    radius: 12

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        font.family: "Roboto"
                        font.pointSize: 14
                        font.weight: Font.Bold
                        color: window.base
                    }
                }

                Text {
                    text: infoDialog.dialogTitle
                    font.family: "Roboto"
                    font.pointSize: 16
                    font.weight: Font.Bold
                    color: window.green
                    Layout.fillWidth: true
                }
            }
                
                
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: window.surface2
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

                    Text {
                        id: infoDialogMessageText
                        width: parent.width
                        height: implicitHeight
                        text: infoDialog.dialogMessage
                        font.family: "Roboto"
                        font.pointSize: 11
                        color: window.text
                        wrapMode: Text.Wrap
                        textFormat: Text.StyledText
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: window.surface2
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
                    color: infoOkMouseArea.containsMouse ? window.blue : window.surface1
                    radius: 4
                    border.color: window.blue
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "OK"
                        font.family: "Roboto"
                        font.pointSize: 10
                        font.weight: Font.Bold
                        color: infoOkMouseArea.containsMouse ? window.base : window.text
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

    // Command Dialog
    Rectangle {
        id: commandDialog
        anchors.fill: parent
        color: "#80000000"
        visible: false
        z: 2000

        property string pluginName: ""
        property var commands: []
        property int selectedIndex: -1

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
            onPositionChanged: mouse.accepted = true
            onWheel: { wheel.accepted = true }
        }

        Rectangle {
            id: commandDialogContent
            width: 600
            height: 450
            color: window.base
            radius: 12
            border.color: window.surface1
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

                    Text {
                        text: "Command Snippets - " + commandDialog.pluginName
                        font.family: "Roboto"
                        font.pointSize: 16
                        font.weight: Font.Bold
                        color: window.text
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 30
                        height: 30
                        color: commandCloseMouseArea.containsMouse ? window.red : "transparent"
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            font.family: "Roboto"
                            font.pointSize: 16
                            font.weight: Font.Bold
                            color: window.text
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
                    color: window.surface2
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: window.surface0
                    radius: 8
                    border.color: window.surface1
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
                            color: commandDialog.selectedIndex === index ? window.surface2 : (commandItemMouseArea.containsMouse ? window.surface1 : "transparent")
                            radius: 4
                            border.color: commandDialog.selectedIndex === index ? window.blue : "transparent"
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

                                Text {
                                    text: commandData.name
                                    font.family: "Roboto"
                                    font.pointSize: 12
                                    font.weight: Font.Bold
                                    color: commandDialog.selectedIndex === index ? window.blue : window.text
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "- " + (commandData.description || "")
                                    font.family: "Roboto"
                                    font.pointSize: 10
                                    color: window.subtext0
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    visible: commandData.description && commandData.description.length > 0
                                }

                                Text {
                                    text: commandData.command
                                    font.family: "Roboto Mono"
                                    font.pointSize: 9
                                    color: window.overlay2
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
                    color: window.surface2
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
                        color: commandCancelMouseArea.containsMouse ? window.surface1 : window.surface0
                        radius: 4
                        border.color: window.overlay0
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Close"
                            font.family: "Roboto"
                            font.pointSize: 10
                            color: window.text
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
                        color: commandDialog.selectedIndex >= 0 ? (commandExecuteMouseArea.containsMouse ? window.blue : window.surface1) : window.overlay0
                        radius: 4
                        border.color: commandDialog.selectedIndex >= 0 ? window.blue : window.overlay1
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "Execute"
                            font.family: "Roboto"
                            font.pointSize: 10
                            font.weight: Font.Bold
                            color: commandExecuteMouseArea.containsMouse ? window.base : (commandDialog.selectedIndex >= 0 ? window.text : window.subtext0)
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
}
