from typing import List, Dict, Any
from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, Signal, Slot, Property
from PySide6.QtQml import QmlElement

from .plugin_manager import PluginManager


QML_IMPORT_NAME = "ActAio"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class PluginListModel(QAbstractListModel):
    """QML-compatible model for displaying plugins in a ListView."""

    # Define roles for QML access
    NameRole = Qt.UserRole + 1
    DisplayNameRole = Qt.UserRole + 2
    DescriptionRole = Qt.UserRole + 3
    VersionRole = Qt.UserRole + 4
    PathRole = Qt.UserRole + 5
    ExecutableRole = Qt.UserRole + 6
    ManualsRole = Qt.UserRole + 7
    TagsRole = Qt.UserRole + 8
    CommandsRole = Qt.UserRole + 9

    # Signals
    pluginManagerChanged = Signal()
    selectedIndexChanged = Signal()
    searchTextChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._plugin_manager: PluginManager = None
        self._selected_index = -1
        self._search_text = ""
        self._filtered_plugins = []

    @Property(PluginManager, notify=pluginManagerChanged)
    def pluginManager(self) -> PluginManager:
        """Get the plugin manager."""
        return self._plugin_manager

    @pluginManager.setter
    def pluginManager(self, manager: PluginManager):
        """Set the plugin manager and connect to its signals."""
        if self._plugin_manager != manager:
            if self._plugin_manager:
                self._plugin_manager.pluginsChanged.disconnect(self._on_plugins_changed)

            self._plugin_manager = manager

            if self._plugin_manager:
                self._plugin_manager.pluginsChanged.connect(self._on_plugins_changed)
                self._on_plugins_changed()

            self.pluginManagerChanged.emit()

    @Property(str, notify=searchTextChanged)
    def searchText(self) -> str:
        """Get the search text."""
        return self._search_text

    @searchText.setter
    def searchText(self, text: str):
        """Set the search text and filter plugins."""
        if self._search_text != text:
            self._search_text = text
            self.searchTextChanged.emit()
            self._update_filtered_plugins()

    @Property(int, notify=selectedIndexChanged)
    def selectedIndex(self) -> int:
        """Get the currently selected index."""
        return self._selected_index

    @selectedIndex.setter
    def selectedIndex(self, index: int):
        """Set the currently selected index."""
        if self._selected_index != index:
            self._selected_index = index
            self.selectedIndexChanged.emit()

    @Property(bool, notify=selectedIndexChanged)
    def hasSelection(self) -> bool:
        """Check if there's a valid selection."""
        return 0 <= self._selected_index < self.rowCount()

    @Property(bool, notify=selectedIndexChanged)
    def canLaunch(self) -> bool:
        """Check if the selected plugin can be launched."""
        if not self.hasSelection:
            return False

        if 0 <= self._selected_index < len(self._filtered_plugins):
            return self._filtered_plugins[self._selected_index].get("executable", False)
        return False

    @Property(str, notify=selectedIndexChanged)
    def selectedPluginName(self) -> str:
        """Get the name of the currently selected plugin."""
        if not self.hasSelection:
            return ""

        if 0 <= self._selected_index < len(self._filtered_plugins):
            return self._filtered_plugins[self._selected_index].get("name", "")
        return ""
    
    @Property(str, notify=selectedIndexChanged)
    def selectedPluginPath(self) -> str:
        """Get the path of the currently selected plugin."""
        if not self.hasSelection:
            return ""
        
        if 0 <= self._selected_index < len(self._filtered_plugins):
            return self._filtered_plugins[self._selected_index].get("path", "")
        return ""

    def roleNames(self) -> Dict[int, bytes]:
        """Define role names for QML access."""
        return {
            self.NameRole: b"name",
            self.DisplayNameRole: b"displayName",
            self.DescriptionRole: b"description",
            self.VersionRole: b"version",
            self.PathRole: b"path",
            self.ExecutableRole: b"executable",
            self.ManualsRole: b"manuals",
            self.TagsRole: b"tags",
            self.CommandsRole: b"commands"
        }

    def rowCount(self, parent=QModelIndex()) -> int:
        """Return the number of plugins."""
        return len(self._filtered_plugins)

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole) -> Any:
        """Return data for the given index and role."""
        if not index.isValid():
            return None

        if index.row() >= len(self._filtered_plugins):
            return None

        plugin = self._filtered_plugins[index.row()]

        if role == self.DisplayNameRole:
            return plugin.get("alias") or plugin.get("name", "")
        elif role == self.NameRole:
            return plugin.get("name", "")
        elif role == self.DescriptionRole:
            return plugin.get("description", "")
        elif role == self.VersionRole:
            return plugin.get("version", "")
        elif role == self.PathRole:
            return plugin.get("path", "")
        elif role == self.ExecutableRole:
            return plugin.get("executable", False)
        elif role == self.ManualsRole:
            return plugin.get("manuals", [])
        elif role == self.TagsRole:
            return plugin.get("tags", [])
        elif role == self.CommandsRole:
            return plugin.get("commands", [])

        return None

    @Slot()
    def refresh(self):
        """Refresh the plugin list."""
        if self._plugin_manager:
            self._plugin_manager.scan_plugins()

    @Slot(result=bool)
    def launchSelected(self) -> bool:
        """Launch the currently selected plugin."""
        if not self.canLaunch:
            return False

        return self._plugin_manager.launch_plugin(self.selectedPluginName)

    def _update_filtered_plugins(self):
        """Update the filtered plugins list based on search text."""
        self.beginResetModel()

        if not self._plugin_manager:
            self._filtered_plugins = []
        elif not self._search_text:
            # No search text, show all plugins
            self._filtered_plugins = self._plugin_manager.plugins
        else:
            # Filter plugins by name, description, or tags (case-insensitive)
            search_lower = self._search_text.lower()
            self._filtered_plugins = [
                plugin for plugin in self._plugin_manager.plugins
                if search_lower in plugin.get("name", "").lower()
                or search_lower in plugin.get("description", "").lower()
                or any(search_lower in tag.lower() for tag in plugin.get("tags", []))
            ]

        self.selectedIndex = -1  # Reset selection
        self.endResetModel()

    def _on_plugins_changed(self):
        """Handle plugins changed signal from PluginManager."""
        self._update_filtered_plugins()