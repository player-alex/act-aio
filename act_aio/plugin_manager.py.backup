import asyncio
import os
import re
import sys
import subprocess
import logging
import zipfile
import shutil
import tempfile
import json
import yaml
import stat
from pathlib import Path
from typing import List, Dict, Any, Optional
try:
    import tomllib
except ImportError:
    import tomli as tomllib

import httpx

from PySide6.QtCore import QObject, Signal, Slot, Property, QThread
from PySide6.QtWidgets import QFileDialog, QMessageBox

from .plugin_utils import remove_readonly, safe_rmtree
from .plugin_models import Plugin
from .plugin_io import PluginImportWorker, PluginIOManager
from .plugin_executor import PluginExecutor


class PluginManager(QObject):
    """Manages plugin discovery and execution."""

    pluginsChanged = Signal()
    errorOccurred = Signal(str, str)  # title, message
    setupStarted = Signal(str)  # plugin name
    setupFinished = Signal()
    confirmationRequested = Signal(str, str, str)  # title, message, callback_id
    infoMessageRequested = Signal(str, str)  # title, message
    importSucceeded = Signal()  # import completed successfully
    importStarted = Signal()  # import from URL started
    importProgress = Signal(int, str)  # percentage (0-100), status message
    importFinished = Signal(bool)  # success
    fontSizeChanged = Signal()  # font size changed

    def __init__(self, parent=None):
        super().__init__(parent)
        self._plugins: List[Plugin] = []
        self._plugins_dir = Path("./plugins")
        self._session_id = None  # Will be set by main.py
        self._hardware_uuid = None  # Will be set by main.py
        self._proxy_url = ""  # Proxy URL for pip commands
        self._settings_file = Path("./settings.json")
        self._env_file = Path(".env")
        self._environment_settings = {}  # Dictionary to track enabled/disabled environment variables
        self._font_size = 1.0  # Font size multiplier for ListView items
        self._load_settings()

        # Initialize I/O manager
        self.io_manager = PluginIOManager(self)
        self.io_manager.cleanup_old_temp_dirs()  # Clean up any leftover temp directories from previous crashes

        # Initialize execution manager
        self.executor = PluginExecutor(self)

        self.scan_plugins()

    @Slot(result="QVariant")
    def getSystemInfo(self):
        """Get system information like repository, dependencies, and license."""
        info = {
            "repository": "https://github.com/player-alex/act-aio",
            "dependencies": [],
            "license_text": "LICENSE file not found."
        }

        # Read dependencies from pyproject.toml
        try:
            pyproject_file = Path("./pyproject.toml")
            if pyproject_file.exists():
                with open(pyproject_file, "rb") as f:
                    data = tomllib.load(f)

                deps = data.get("project", {}).get("dependencies", [])
                for dep in deps:
                    # Extract package name from version specifier (e.g., "PySide6>=6.0")
                    match = re.match(r"^[a-zA-Z0-9_-]+", dep)
                    if match:
                        name = match.group(0)
                        info["dependencies"].append({
                            "name": name,
                            "url": f"https://pypi.org/project/{name}/"
                        })
        except Exception as e:
            logging.error(f"Failed to read dependencies from pyproject.toml: {e}")

        # Read license file
        try:
            license_file = Path("./LICENSE")
            if license_file.exists():
                info["license_text"] = license_file.read_text(encoding="utf-8")
        except Exception as e:
            logging.error(f"Failed to read LICENSE file: {e}")

        return info

    def set_session_id(self, session_id: str):
        """Set the current session ID for tracking."""
        self._session_id = session_id

    def set_hardware_uuid(self, hardware_uuid: str):
        """Set the current hardware UUID for tracking."""
        self._hardware_uuid = hardware_uuid

    @Property(str)
    def proxyUrl(self) -> str:
        """Get the proxy URL."""
        return self._proxy_url

    @Slot(str)
    def setProxyUrl(self, url: str):
        """Set the proxy URL for pip commands."""
        self._proxy_url = url.strip()
        logging.info(f"Proxy URL set to: {self._proxy_url}")
        self._save_settings()

    @Property(float, notify=fontSizeChanged)
    def fontSize(self) -> float:
        """Get the font size multiplier."""
        return self._font_size

    @fontSize.setter
    def fontSize(self, size: float):
        """Set the font size multiplier."""
        if self._font_size != size:
            self._font_size = max(1.0, min(2.0, size))  # Clamp between 1.0 and 2.0
            logging.info(f"Font size set to: {self._font_size}")
            self._save_settings()
            self.fontSizeChanged.emit()

    def _load_settings(self):
        """Load settings from settings.json file."""
        try:
            if self._settings_file.exists():
                with open(self._settings_file, 'r', encoding='utf-8') as f:
                    settings = json.load(f)
                self._proxy_url = settings.get('proxy', '')
                self._environment_settings = settings.get('environment_settings', {})

                # Load and validate font_size
                font_size = settings.get('font_size', 1.0)
                try:
                    font_size = float(font_size)
                    # Clamp to valid range [1.0, 2.0]
                    if font_size < 1.0 or font_size > 2.0 or not (0 < font_size < float('inf')):
                        logging.warning(f"Invalid font_size value: {font_size}, using default 1.0")
                        font_size = 1.0
                except (TypeError, ValueError) as e:
                    logging.warning(f"Invalid font_size type in settings.json: {font_size}, using default 1.0")
                    font_size = 1.0

                self._font_size = font_size

                if self._proxy_url:
                    logging.info(f"Loaded proxy setting: {self._proxy_url}")
                else:
                    logging.info("No proxy setting found in settings.json")
                logging.info(f"Loaded environment settings: {self._environment_settings}")
                logging.info(f"Loaded font size: {self._font_size}")
            else:
                logging.info("No settings.json file found, using default settings")
        except Exception as e:
            logging.error(f"Failed to load settings: {e}")
            self._proxy_url = ""
            self._environment_settings = {}
            self._font_size = 1.0

    def _save_settings(self):
        """Save settings to settings.json file."""
        try:
            settings = {
                'proxy': self._proxy_url,
                'environment_settings': self._environment_settings,
                'font_size': self._font_size
            }
            with open(self._settings_file, 'w', encoding='utf-8') as f:
                json.dump(settings, f, indent=2)
            logging.info("Settings saved successfully")
        except Exception as e:
            logging.error(f"Failed to save settings: {e}")

    @Slot(result='QVariant')
    def getEnvironmentVariables(self):
        """Get environment variables from .env file."""
        env_vars = {}
        try:
            if self._env_file.exists():
                with open(self._env_file, 'r', encoding='utf-8') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#') and '=' in line:
                            key, value = line.split('=', 1)
                            env_vars[key.strip()] = value.strip()
                logging.info(f"Loaded {len(env_vars)} environment variables from .env file")
            else:
                logging.info("No .env file found")
        except Exception as e:
            logging.error(f"Failed to read .env file: {e}")
        return env_vars

    @Slot(result='QVariant')
    def getEnvironmentSettings(self):
        """Get environment settings (which variables are enabled)."""
        return self._environment_settings

    @Slot('QVariant')
    def setEnvironmentSettings(self, settings):
        """Set environment settings (which variables are enabled)."""
        try:
            logging.info(f"Received settings type: {type(settings)}, value: {settings}")

            # Handle QML JavaScript object conversion
            if hasattr(settings, 'toVariant'):
                settings = settings.toVariant()

            # Convert to Python dict
            if isinstance(settings, dict):
                self._environment_settings = settings
            else:
                # Try to convert from QVariantMap or similar
                self._environment_settings = dict(settings) if settings else {}

            logging.info(f"Environment settings updated: {self._environment_settings}")
            self._save_settings()
        except Exception as e:
            logging.error(f"Failed to set environment settings: {e}")
            import traceback
            logging.error(f"Traceback: {traceback.format_exc()}")

    @Property('QVariant', notify=pluginsChanged)
    def plugins(self) -> List[Dict[str, Any]]:
        """Return plugins as a list of dictionaries for QML consumption."""
        result = []
        for plugin in self._plugins:
            commands = self._get_plugin_commands(plugin)
            logging.info(f"plugins() property - Plugin '{plugin.name}' commands: {commands}")
            plugin_dict = {
                "name": plugin.name,
                "alias": plugin.alias,
                "description": plugin.description,
                "version": plugin.version,
                "path": str(plugin.path),
                "executable": plugin.is_executable,
                "manuals": self._get_plugin_manuals(plugin),
                "tags": plugin.tags,
                "commands": commands
            }
            result.append(plugin_dict)
        return result

    @Slot()
    def scan_plugins(self):
        """Scan the plugins directory for available plugins."""
        self._plugins.clear()

        if not self._plugins_dir.exists():
            self._plugins_dir.mkdir(exist_ok=True)
            self.pluginsChanged.emit()
            return

        for item in self._plugins_dir.iterdir():
            if item.is_dir():
                pyproject_file = item / "pyproject.toml"
                if pyproject_file.exists():
                    plugin = self._load_plugin(item, pyproject_file)
                    if plugin:
                        self._plugins.append(plugin)

        self.pluginsChanged.emit()

    def _load_plugin(self, plugin_path: Path, pyproject_file: Path) -> Optional[Plugin]:
        """Load plugin metadata from pyproject.toml."""
        try:
            with open(pyproject_file, "rb") as f:
                data = tomllib.load(f)

            # Extract project metadata
            project_data = data.get("project", {})
            return Plugin(plugin_path, project_data)

        except Exception as e:
            print(f"Error loading plugin from {plugin_path}: {e}")
            return None

    @Slot(str, result=bool)
    def launch_plugin(self, plugin_name: str) -> bool:
        """Launch a plugin by name with uv environment management."""
        return self.executor.launch_plugin(plugin_name)

    def _find_plugin_by_name(self, name: str) -> Optional[Plugin]:
        """Find a plugin by its name."""
        for plugin in self._plugins:
            if plugin.name == name:
                return plugin
        return None

    @Slot()
    def importPlugin(self):
        """Import a plugin from a zip file."""
        self.io_manager.importPlugin()

    @Slot(str)
    def importPluginFromUrl(self, url: str):
        """Import a plugin from a URL pointing to a zip file."""
        self.io_manager.importPluginFromUrl(url)

    @Slot()
    def cancel_import(self):
        """Cancel the ongoing plugin import process."""
        self.io_manager.cancel_import()

    @Slot(str, str)
    def exportPlugin(self, plugin_display_name: str, plugin_path: str):
        """Export a plugin to a zip file."""
        self.io_manager.exportPlugin(plugin_display_name, plugin_path)

    def _show_error(self, title: str, message: str):
        """Show error dialog using QML signal."""
        self.errorOccurred.emit(title, message)

    def _show_info(self, title: str, message: str):
        """Show info message using QML signal."""
        self.infoMessageRequested.emit(title, message)

    @Slot(str, bool)
    def handleConfirmationResponse(self, callback_id: str, accepted: bool):
        """Handle confirmation dialog response from QML."""
        self.io_manager.handleConfirmationResponse(callback_id, accepted)


    def _get_plugin_manuals(self, plugin: Plugin) -> List[str]:
        """Get list of manual files for a plugin."""
        if not plugin:
            return []

        manual_dir = plugin.path / "manuals"
        if not manual_dir.exists():
            return []

        manual_files = []
        for file in manual_dir.iterdir():
            if file.is_file():
                manual_files.append(str(file))

        return sorted(manual_files)

    @Slot(str)
    def openManual(self, file_path: str):
        """Open a manual file using the system default application."""
        try:
            if sys.platform == "win32":
                os.startfile(file_path)
            elif sys.platform == "darwin":
                subprocess.run(["open", file_path])
            else:
                subprocess.run(["xdg-open", file_path])
            logging.info(f"Opened manual: {file_path}")
        except Exception as e:
            logging.error(f"Failed to open manual: {e}")
            self.errorOccurred.emit("Failed to Open Manual", f"Could not open manual file: {e}")

    @Slot(str)
    def openPluginDirectory(self, plugin_name: str):
        """Open the plugin directory in the system file explorer."""
        try:
            # Find the plugin by name to get its actual directory path
            plugin = self._find_plugin_by_name(plugin_name)
            if not plugin:
                self.errorOccurred.emit("Plugin Not Found", f"Plugin '{plugin_name}' not found.")
                logging.error(f"Plugin not found: {plugin_name}")
                return

            plugin_dir = plugin.path
            if not plugin_dir.exists():
                self.errorOccurred.emit("Directory Not Found", f"Plugin directory does not exist.")
                logging.error(f"Plugin directory not found: {plugin_dir}")
                return

            if sys.platform == "win32":
                os.startfile(str(plugin_dir))
            elif sys.platform == "darwin":
                subprocess.run(["open", str(plugin_dir)])
            else:
                subprocess.run(["xdg-open", str(plugin_dir)])
            logging.info(f"Opened plugin directory: {plugin_dir}")
        except Exception as e:
            logging.error(f"Failed to open plugin directory: {e}")
            self.errorOccurred.emit("Failed to Open Directory", f"Could not open plugin directory: {e}")

    def _get_plugin_commands(self, plugin: Plugin) -> List[Dict[str, str]]:
        """Get list of command snippets for a plugin."""
        if not plugin:
            logging.debug(f"Plugin object not found for commands")
            return []

        commands_dir = plugin.path / "snippets" / "commands"
        if not commands_dir.exists():
            logging.debug(f"Commands directory does not exist for plugin '{plugin.name}':{commands_dir}")
            return []

        logging.info(f"Scanning commands directory for plugin '{plugin.name}': {commands_dir}")
        command_snippets = []
        for file in commands_dir.iterdir():
            if file.is_file() and file.suffix.lower() in ['.yaml', '.yml']:
                try:
                    logging.info(f"Loading command snippet from {file}")
                    with open(file, 'r', encoding='utf-8') as f:
                        data = yaml.safe_load(f)

                        # Validate required fields
                        if not isinstance(data, dict):
                            logging.warning(f"Invalid data type in {file}: {type(data)}")
                            continue

                        name = data.get('name')
                        command = data.get('command')

                        # Skip if required fields are missing
                        if not name or not command:
                            logging.warning(f"Invalid command snippet {file}: missing name or command")
                            continue

                        description = data.get('description', '')

                        snippet = {
                            'name': name,
                            'description': description,
                            'command': command,
                            'file_path': str(file)
                        }
                        command_snippets.append(snippet)
                        logging.info(f"Loaded command snippet: {name}")
                except Exception as e:
                    logging.error(f"Failed to load command snippet from {file}: {e}")
                    continue

        logging.info(f"Found {len(command_snippets)} command snippets for plugin '{plugin.name}'")
        return sorted(command_snippets, key=lambda x: x['name'])

    @Slot(str, str)
    def executeCommand(self, plugin_name: str, command: str):
        """Execute a command snippet for a plugin."""
        self.executor.executeCommand(plugin_name, command)

