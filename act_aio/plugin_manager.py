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
from pathlib import Path
from typing import List, Dict, Any, Optional
try:
    import tomllib
except ImportError:
    import tomli as tomllib

from PySide6.QtCore import QObject, Signal, Slot, Property, QThread
from PySide6.QtWidgets import QFileDialog, QMessageBox


# Environment variable filter constants
# These prefixes/patterns will be filtered out from system environment when launching plugins
ENV_FILTER_STARTSWITH = ['QT_', 'PYSIDE_']  # Filter keys starting with these prefixes
ENV_FILTER_ENDSWITH = []  # Filter keys ending with these suffixes (for future use)
ENV_FILTER_CONTAINS = []  # Filter keys containing these strings (for future use)


class Plugin:
    """Represents a single plugin with its metadata."""

    def __init__(self, path: Path, metadata: Dict[str, Any]):
        self.path = path
        self.name = metadata.get("name", "Unknown")
        self.alias = metadata.get("alias", "")
        self.description = metadata.get("description", "No description")
        self.version = metadata.get("version", "0.0.0")

        # Robustly parse tags
        raw_tags = metadata.get("tags", [])
        if isinstance(raw_tags, list):
            self.tags = [str(tag) for tag in raw_tags]
        else:
            self.tags = []

        self.main_file = path / "main.py"

    @property
    def is_executable(self) -> bool:
        """Check if the plugin has a main.py file."""
        return self.main_file.exists()


class PluginSetupWorker(QThread):
    """Worker thread for setting up plugin environment."""

    finished = Signal(bool, str)  # success, error_message
    progress = Signal(str)  # progress message

    def __init__(self, plugin, plugin_manager, parent=None):
        super().__init__(parent)
        self.plugin = plugin
        self.plugin_manager = plugin_manager

    def run(self):
        """Run the plugin setup in a separate thread."""
        try:
            success = self.plugin_manager._setup_plugin_environment_impl(self.plugin, self.progress)
            if success:
                self.finished.emit(True, "")
            else:
                self.finished.emit(False, "Failed to setup environment")
        except Exception as e:
            self.finished.emit(False, str(e))


class PluginManager(QObject):
    """Manages plugin discovery and execution."""

    pluginsChanged = Signal()
    errorOccurred = Signal(str, str)  # title, message
    setupStarted = Signal(str)  # plugin name
    setupFinished = Signal()
    confirmationRequested = Signal(str, str, str)  # title, message, callback_id
    infoMessageRequested = Signal(str, str)  # title, message

    def __init__(self, parent=None):
        super().__init__(parent)
        self._plugins: List[Plugin] = []
        self._plugins_dir = Path("./plugins")
        self._session_id = None  # Will be set by main.py
        self._hardware_uuid = None  # Will be set by main.py
        self._proxy_url = ""  # Proxy URL for pip commands
        self._settings_file = Path("./settings.json")
        self._setup_worker = None
        self._pending_plugin = None
        self._env_file = Path(".env")
        self._environment_settings = {}  # Dictionary to track enabled/disabled environment variables
        self._pending_import_data = None  # Store import data while waiting for confirmation
        self._load_settings()
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

    def _load_settings(self):
        """Load settings from settings.json file."""
        try:
            if self._settings_file.exists():
                with open(self._settings_file, 'r', encoding='utf-8') as f:
                    settings = json.load(f)
                self._proxy_url = settings.get('proxy', '')
                self._environment_settings = settings.get('environment_settings', {})
                if self._proxy_url:
                    logging.info(f"Loaded proxy setting: {self._proxy_url}")
                else:
                    logging.info("No proxy setting found in settings.json")
                logging.info(f"Loaded environment settings: {self._environment_settings}")
            else:
                logging.info("No settings.json file found, using default settings")
        except Exception as e:
            logging.error(f"Failed to load settings: {e}")
            self._proxy_url = ""
            self._environment_settings = {}

    def _save_settings(self):
        """Save settings to settings.json file."""
        try:
            settings = {
                'proxy': self._proxy_url,
                'environment_settings': self._environment_settings
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
        plugin = self._find_plugin_by_name(plugin_name)
        if not plugin:
            error_msg = f"Plugin '{plugin_name}' not found.\n\nPlease check if the plugin exists in the plugins directory and refresh the plugin list."
            self.errorOccurred.emit("Plugin Not Found", error_msg)
            print(f"Plugin '{plugin_name}' not found")
            return False

        if not plugin.is_executable:
            error_msg = f"Plugin '{plugin_name}' cannot be executed.\n\nThe plugin is missing a main.py file. Please check the plugin structure."
            self.errorOccurred.emit("Plugin Not Executable", error_msg)
            print(f"Plugin '{plugin_name}' has no main.py file")
            return False

        try:
            # Check if environment already exists
            venv_base_dir = self._plugins_dir / ".venv"
            plugin_venv_dir = venv_base_dir / plugin.name

            if not plugin_venv_dir.exists():
                # Setup environment in background thread
                self._pending_plugin = plugin
                self.setupStarted.emit(plugin.alias or plugin.name)
                self._setup_worker = PluginSetupWorker(plugin, self)
                self._setup_worker.finished.connect(self._on_setup_finished)
                self._setup_worker.start()
                return True
            else:
                # Environment exists, launch directly
                return self._launch_plugin_process(plugin)

        except Exception as e:
            error_msg = f"Unexpected error while launching plugin '{plugin_name}'.\n\nError details:\n{str(e)}"
            self.errorOccurred.emit("Plugin Launch Error", error_msg)
            print(f"Error launching plugin '{plugin_name}': {e}")
            return False

    def _on_setup_finished(self, success: bool, error_message: str):
        """Handle setup worker completion."""
        self.setupFinished.emit()

        if success and self._pending_plugin:
            # Launch the plugin
            self._launch_plugin_process(self._pending_plugin)
        elif not success:
            error_msg = f"Failed to setup environment for plugin '{self._pending_plugin.name}'.\n\nError: {error_message}"
            self.errorOccurred.emit("Environment Setup Failed", error_msg)

        self._pending_plugin = None
        self._setup_worker = None

    def _launch_plugin_process(self, plugin: Plugin) -> bool:
        """Launch the plugin process."""
        try:
            venv_base_dir = self._plugins_dir / ".venv"
            plugin_venv_dir = venv_base_dir / plugin.name

            if sys.platform == "win32":
                python_exe = plugin_venv_dir / "Scripts" / "python.exe"
            else:
                python_exe = plugin_venv_dir / "bin" / "python"

            # Convert to absolute path
            python_exe = python_exe.resolve()

            # Check if the Python executable exists
            print(f"Checking for Python executable at: {python_exe}")
            print(f"File exists: {python_exe.exists()}")

            if not python_exe.exists():
                print(f"Python executable not found at: {python_exe}")
                print(f"Virtual environment directory: {plugin_venv_dir}")
                print(f"Virtual environment exists: {plugin_venv_dir.exists()}")

                if plugin_venv_dir.exists():
                    print("Virtual environment directory contents:")
                    for item in plugin_venv_dir.iterdir():
                        print(f"  {item}")

                    # Check Scripts directory specifically
                    scripts_dir = plugin_venv_dir / "Scripts"
                    if scripts_dir.exists():
                        print(f"Scripts directory contents:")
                        for item in scripts_dir.iterdir():
                            print(f"  {item}")
                    else:
                        print(f"Scripts directory does not exist: {scripts_dir}")

                    # Check if python.exe exists with different name
                    possible_names = ["python.exe", "python3.exe", "python3.13.exe"]
                    for name in possible_names:
                        alt_path = scripts_dir / name
                        if alt_path.exists():
                            print(f"Found alternative Python executable: {alt_path}")
                            python_exe = alt_path
                            break
                else:
                    error_msg = f"Virtual environment for plugin '{plugin_name}' was not created properly.\n\nPlease try:\n1. Delete the plugin\n2. Re-import the plugin\n3. Check UV installation"
                    self.errorOccurred.emit("Virtual Environment Missing", error_msg)
                    print(f"Virtual environment directory does not exist: {plugin_venv_dir}")
                    return False

                # If still no python executable found
                if not python_exe.exists():
                    error_msg = f"Python executable not found for plugin '{plugin_name}'.\n\nThe virtual environment appears corrupted. Please try:\n1. Delete the plugin\n2. Re-import the plugin\n3. Check UV installation"
                    self.errorOccurred.emit("Python Executable Missing", error_msg)
                    return False

            print(f"Using Python executable: {python_exe}")

            # Get environment with enabled variables and set VIRTUAL_ENV for plugin
            env = self._get_environment_with_proxy()
            # Set VIRTUAL_ENV to the plugin's virtual environment (resolve to absolute path)
            plugin_venv_absolute = plugin_venv_dir.resolve()
            env['VIRTUAL_ENV'] = str(plugin_venv_absolute)

            print(f"VIRTUAL_ENV set to: {env['VIRTUAL_ENV']}")
            print(f"Resolved venv path: {plugin_venv_absolute}")
            print(f"Total environment variables: {len(env)}")

            # Show enabled and disabled .env variables
            enabled_env_vars = [k for k, v in self._environment_settings.items() if v]
            disabled_env_vars = [k for k, v in self._environment_settings.items() if not v]

            if enabled_env_vars:
                print(f"Enabled .env variables: {enabled_env_vars}")
                for var in enabled_env_vars:
                    if var in env:
                        print(f"  {var} = {env[var]}")
            else:
                print("No .env variables enabled")

            if disabled_env_vars:
                print(f"Disabled .env variables (removed from env): {disabled_env_vars}")
            else:
                print("No .env variables disabled")

            if sys.platform == "win32":
                # On Windows, use uv run --active with the plugin's virtual environment
                # Pause only if error occurred (ERRORLEVEL != 0)
                cmd_string = f'cmd /c "uv run --active main.py & if %ERRORLEVEL% neq 0 (echo Exit code: %ERRORLEVEL% & pause)"'
                print(f"Executing command: {cmd_string}")
                print(f"Working directory: {plugin.path}")
                subprocess.Popen(
                    cmd_string,
                    cwd=str(plugin.path),
                    env=env,
                    creationflags=subprocess.CREATE_NEW_CONSOLE
                )
            else:
                # On Unix-like systems, use uv run --active
                subprocess.Popen(
                    ['uv', 'run', '--active', 'main.py'],
                    cwd=str(plugin.path),
                    env=env
                )
            print(f"Launched plugin: {plugin.name}")

            # Track plugin launch event
            try:
                from .main import track_plugin_event
                from .tracking import tracking_context

                session_id = tracking_context.get_session_id()
                hardware_uuid = tracking_context.get_hardware_uuid()

                logging.info(f"Tracking context: session_id={session_id}, hardware_uuid={hardware_uuid[:8] if hardware_uuid else None}...")
                track_plugin_event(
                    'launched_plugin',
                    plugin.name,
                    session_id,
                    hardware_uuid
                )
            except Exception as e:
                logging.error(f"Failed to track plugin launch: {e}")

            return True
        except Exception as e:
            error_msg = f"Unexpected error while launching plugin '{plugin.name}'.\n\nError details:\n{str(e)}"
            self.errorOccurred.emit("Plugin Launch Error", error_msg)
            print(f"Error launching plugin '{plugin.name}': {e}")
            return False

    def _setup_plugin_environment_impl(self, plugin: Plugin, progress: Signal = None) -> bool:
        """Setup uv environment for a plugin in centralized venv directory (implementation)."""
        try:
            plugin_path = plugin.path
            pyproject_file = plugin_path / "pyproject.toml"
            requirements_file = plugin_path / "requirements.txt"

            # Create centralized venv directory structure
            venv_base_dir = self._plugins_dir / ".venv"
            plugin_venv_dir = venv_base_dir / plugin.name

            print(f"Setting up environment for plugin: {plugin.name}")
            print(f"Virtual environment location: {plugin_venv_dir}")

            # Check if uv is available
            if not self._check_uv_command():
                error_msg = "UV command not found. Please install UV package manager to use plugins.\n\nVisit: https://docs.astral.sh/uv/getting-started/installation/"
                self.errorOccurred.emit("UV Not Found", error_msg)
                print("uv command not found. Please install uv.")
                return False

            # Create the venv base directory if it doesn't exist
            venv_base_dir.mkdir(exist_ok=True)

            # Create virtual environment in centralized location
            if not plugin_venv_dir.exists():
                print(f"Creating virtual environment for {plugin.name}")
                print(f"Command: uv venv {plugin_venv_dir}")
                print(f"Working directory: {self._plugins_dir.parent}")
                result = subprocess.run(
                    ["uv", "venv", str(plugin_venv_dir)],
                    cwd=str(self._plugins_dir.parent),  # Run from the main project directory
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                print(f"uv venv return code: {result.returncode}")
                if result.stdout:
                    print(f"uv venv stdout: {result.stdout}")
                if result.stderr:
                    print(f"uv venv stderr: {result.stderr}")

                if result.returncode != 0:
                    error_msg = f"Failed to create virtual environment for plugin '{plugin.name}'.\n\nError details:\n{result.stderr}"
                    self.errorOccurred.emit("Environment Setup Failed", error_msg)
                    print(f"Failed to create virtual environment: {result.stderr}")
                    return False

                # Verify the venv was created
                if plugin_venv_dir.exists():
                    print(f"✅ Virtual environment created successfully at {plugin_venv_dir}")
                    print("Contents:")
                    for item in plugin_venv_dir.iterdir():
                        print(f"  {item.name}")
                else:
                    print(f"❌ Virtual environment directory not found after creation: {plugin_venv_dir}")
                    return False
            else:
                print(f"Virtual environment already exists for {plugin.name}")
                print("Contents:")
                for item in plugin_venv_dir.iterdir():
                    print(f"  {item.name}")

            # Install dependencies from requirements.txt if it exists
            # NOTE: Commented out because UV automatically resolves dependencies
            # if requirements_file.exists():
            #     print(f"Installing requirements for {plugin.name}")
            #     pip_cmd = ["uv", "pip", "install", "-r", str(requirements_file), "--python", str(plugin_venv_dir)]
            #     env = self._get_environment_with_proxy()
            #     result = subprocess.run(
            #         pip_cmd,
            #         cwd=str(self._plugins_dir.parent),  # Run from main project directory
            #         capture_output=True,
            #         text=True,
            #         timeout=300,  # 5 minutes for package installation
            #         env=env
            #     )
            #     if result.returncode != 0:
            #         error_msg = f"Failed to install requirements for plugin '{plugin.name}'.\n\nThis could be due to:\n- Invalid proxy settings\n- Network connectivity issues\n- Missing packages\n\nError details:\n{result.stderr}"
            #         self.errorOccurred.emit("Package Installation Failed", error_msg)
            #         print(f"Failed to install requirements: {result.stderr}")
            #         return False

            # Install dependencies from pyproject.toml if it exists and has dependencies
            # NOTE: Commented out because UV automatically resolves dependencies
            # if pyproject_file.exists():
            #     try:
            #         with open(pyproject_file, "rb") as f:
            #             data = tomllib.load(f)

            #         dependencies = data.get("project", {}).get("dependencies", [])
            #         if dependencies:
            #             print(f"Installing pyproject.toml dependencies for {plugin.name}")

            #             # Install all dependencies in one command
            #             deps_args = []
            #             for dep in dependencies:
            #                 deps_args.append(dep)

            #             pip_cmd = ["uv", "pip", "install"] + deps_args + ["--python", str(plugin_venv_dir)]
            #             env = self._get_environment_with_proxy()
            #             result = subprocess.run(
            #                 pip_cmd,
            #                 cwd=str(self._plugins_dir.parent),  # Run from main project directory
            #                 capture_output=True,
            #                 text=True,
            #                 timeout=300,
            #                 env=env
            #             )
            #             if result.returncode != 0:
            #                 error_msg = f"Failed to install dependencies from pyproject.toml for plugin '{plugin.name}'.\n\nThis could be due to:\n- Invalid proxy settings\n- Network connectivity issues\n- Missing packages\n\nError details:\n{result.stderr}"
            #                 self.errorOccurred.emit("Package Installation Failed", error_msg)
            #                 print(f"Failed to install pyproject.toml dependencies: {result.stderr}")
            #                 return False
            #     except Exception as e:
            #         print(f"Warning: Could not process pyproject.toml dependencies: {e}")

            print(f"Environment setup completed for {plugin.name}")
            return True

        except subprocess.TimeoutExpired:
            error_msg = f"Timeout while setting up environment for plugin '{plugin.name}'.\n\nThe installation took too long (>5 minutes). This could be due to:\n- Slow network connection\n- Large package dependencies\n- Proxy issues"
            self.errorOccurred.emit("Installation Timeout", error_msg)
            print(f"Timeout while setting up environment for {plugin.name}")
            return False
        except Exception as e:
            error_msg = f"Unexpected error while setting up environment for plugin '{plugin.name}'.\n\nError details:\n{str(e)}"
            self.errorOccurred.emit("Environment Setup Error", error_msg)
            print(f"Error setting up environment for {plugin.name}: {e}")
            return False

    def _check_uv_command(self) -> bool:
        """Check if uv command is available in PATH."""
        try:
            if sys.platform == "win32":
                # Use 'where' command on Windows
                result = subprocess.run(["where", "uv"],
                                      capture_output=True,
                                      text=True)
                return result.returncode == 0 and result.stdout.strip()
            else:
                # Use 'which' command on Unix-like systems
                result = subprocess.run(["which", "uv"],
                                      capture_output=True,
                                      text=True)
                return result.returncode == 0 and result.stdout.strip()
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False

    def _find_plugin_by_name(self, name: str) -> Optional[Plugin]:
        """Find a plugin by its name."""
        for plugin in self._plugins:
            if plugin.name == name:
                return plugin
        return None

    def _check_python_command(self, cmd: str) -> bool:
        """Check if a Python command is available."""
        try:
            subprocess.run([cmd, "--version"],
                         capture_output=True,
                         check=True,
                         timeout=5)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            return False

    @Slot()
    def importPlugin(self):
        """Import a plugin from a zip file."""
        try:
            # Open file dialog to select zip file
            file_path, _ = QFileDialog.getOpenFileName(
                None,
                "Import Plugin",
                "",
                "Zip Files (*.zip)"
            )

            if not file_path:
                return

            file_path = Path(file_path)
            if not file_path.exists() or file_path.suffix.lower() != '.zip':
                self._show_error("Invalid file", "Please select a valid zip file.")
                return

            # Create temporary directory for extraction
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_path = Path(temp_dir)

                # Extract zip file
                try:
                    with zipfile.ZipFile(file_path, 'r') as zip_ref:
                        zip_ref.extractall(temp_path)
                except Exception as e:
                    self._show_error("Extraction failed", f"Failed to extract zip file: {e}")
                    return

                # Find the plugin directory (should contain pyproject.toml or main.py)
                plugin_dirs = []
                for item in temp_path.iterdir():
                    if item.is_dir():
                        if (item / "pyproject.toml").exists() or (item / "main.py").exists():
                            plugin_dirs.append(item)

                if len(plugin_dirs) == 0:
                    self._show_error("Invalid plugin", "No valid plugin found in zip file. Plugin should contain pyproject.toml or main.py.")
                    return
                elif len(plugin_dirs) > 1:
                    self._show_error("Multiple plugins", "Zip file contains multiple plugins. Please import one plugin at a time.")
                    return

                source_dir = plugin_dirs[0]
                plugin_name = source_dir.name

                # Check if plugin already exists
                target_dir = self._plugins_dir / plugin_name
                if target_dir.exists():
                    # Copy to temporary location in plugins directory before asking for confirmation
                    temp_import_dir = self._plugins_dir / f".temp_import_{plugin_name}"

                    # Remove temp import dir if it exists
                    if temp_import_dir.exists():
                        shutil.rmtree(temp_import_dir)

                    # Copy to temp location
                    shutil.copytree(source_dir, temp_import_dir)

                    # Store import data and request confirmation
                    self._pending_import_data = {
                        'source_dir': temp_import_dir,
                        'target_dir': target_dir,
                        'plugin_name': plugin_name
                    }
                    self.confirmationRequested.emit(
                        "Plugin exists",
                        f"Plugin '{plugin_name}' already exists. Do you want to overwrite it?",
                        "import_overwrite"
                    )
                    return

                # Copy plugin to plugins directory
                self._complete_import(source_dir, target_dir, plugin_name)

        except Exception as e:
            logging.error(f"Error importing plugin: {e}")
            self._show_error("Import failed", f"Failed to import plugin: {e}")

    @Slot(str, str)
    def exportPlugin(self, plugin_display_name: str, plugin_path: str):
        """Export a plugin to a zip file."""
        try:
            if not plugin_path:
                self._show_error("No selection", "Please select a plugin to export.")
                return
    
            plugin_dir = Path(plugin_path)
            if not plugin_dir.exists() or not plugin_dir.is_dir():
                self._show_error("Plugin not found", f"Plugin directory '{plugin_path}' not found.")
                return
    

            # Use the directory name for the zip file name
            plugin_name = plugin_dir.name
    
            # Open save dialog
            file_path, _ = QFileDialog.getSaveFileName(
                None,
                "Export Plugin",
                f"{plugin_name}.zip",
                "Zip Files (*.zip)"
            )
    
            if not file_path:
                return
    
            file_path = Path(file_path)
    
            # Create zip file
            try:
                with zipfile.ZipFile(file_path, 'w', zipfile.ZIP_DEFLATED) as zip_ref:
                    # Add all files in the plugin directory
                    for file in plugin_dir.rglob('*'):
                        if file.is_file():
                            # Skip certain files/directories
                            if any(skip in file.parts for skip in ['.venv', '__pycache__', '.git', '.lock']):
                                continue
    
                            # Calculate relative path from plugin directory
                            rel_path = file.relative_to(plugin_dir.parent)
                            zip_ref.write(file, rel_path)
    
                logging.info(f"Plugin '{plugin_display_name}' exported to {file_path}")
                self._show_info("Export successful", f"Plugin '{plugin_display_name}' has been exported to {file_path}")
    
            except Exception as e:
                self._show_error("Export failed", f"Failed to create zip file: {e}")
    
        except Exception as e:
            logging.error(f"Error exporting plugin: {e}")
            self._show_error("Export failed", f"Failed to export plugin: {e}")

    def _show_error(self, title: str, message: str):
        """Show error dialog using QML signal."""
        self.errorOccurred.emit(title, message)

    def _show_info(self, title: str, message: str):
        """Show info message using QML signal."""
        self.infoMessageRequested.emit(title, message)

    def _complete_import(self, source_dir: Path, target_dir: Path, plugin_name: str):
        """Complete the import process by copying files and refreshing."""
        try:
            # Copy plugin to plugins directory
            shutil.copytree(source_dir, target_dir)
            logging.info(f"Plugin '{plugin_name}' imported successfully")

            # Clean up temporary import directory if it exists
            temp_import_dir = self._plugins_dir / f".temp_import_{plugin_name}"
            if temp_import_dir.exists() and source_dir == temp_import_dir:
                shutil.rmtree(temp_import_dir)
                logging.info(f"Cleaned up temporary import directory: {temp_import_dir}")

            # Refresh plugin list
            self.scan_plugins()

            self._show_info("Import successful", f"Plugin '{plugin_name}' has been imported successfully.")
        except Exception as e:
            logging.error(f"Error completing import: {e}")
            self._show_error("Import failed", f"Failed to import plugin: {e}")

            # Still try to clean up temp directory on error
            try:
                temp_import_dir = self._plugins_dir / f".temp_import_{plugin_name}"
                if temp_import_dir.exists():
                    shutil.rmtree(temp_import_dir)
                    logging.info(f"Cleaned up temporary import directory after error: {temp_import_dir}")
            except Exception as cleanup_error:
                logging.error(f"Failed to clean up temp directory: {cleanup_error}")

    @Slot(str, bool)
    def handleConfirmationResponse(self, callback_id: str, accepted: bool):
        """Handle confirmation dialog response from QML."""
        if callback_id == "import_overwrite":
            if accepted and self._pending_import_data:
                try:
                    # Remove existing plugin
                    shutil.rmtree(self._pending_import_data['target_dir'])
                    # Complete import
                    self._complete_import(
                        self._pending_import_data['source_dir'],
                        self._pending_import_data['target_dir'],
                        self._pending_import_data['plugin_name']
                    )
                except Exception as e:
                    logging.error(f"Error overwriting plugin: {e}")
                    self._show_error("Import failed", f"Failed to overwrite plugin: {e}")

                    # Clean up temp directory on error
                    try:
                        temp_import_dir = self._plugins_dir / f".temp_import_{self._pending_import_data['plugin_name']}"
                        if temp_import_dir.exists():
                            shutil.rmtree(temp_import_dir)
                            logging.info(f"Cleaned up temporary import directory after error: {temp_import_dir}")
                    except Exception as cleanup_error:
                        logging.error(f"Failed to clean up temp directory: {cleanup_error}")
                finally:
                    self._pending_import_data = None
            else:
                # User cancelled - clean up temp directory
                if self._pending_import_data:
                    try:
                        temp_import_dir = self._plugins_dir / f".temp_import_{self._pending_import_data['plugin_name']}"
                        if temp_import_dir.exists():
                            shutil.rmtree(temp_import_dir)
                            logging.info(f"Cleaned up temporary import directory after cancellation: {temp_import_dir}")
                    except Exception as cleanup_error:
                        logging.error(f"Failed to clean up temp directory: {cleanup_error}")
                self._pending_import_data = None

    def _get_environment_with_proxy(self) -> Dict[str, str]:
        """Get environment variables with proxy settings and enabled .env variables."""
        env = os.environ.copy()

        # Filter out environment variables based on defined patterns
        filtered_keys = []
        for key in list(env.keys()):
            should_filter = False

            # Check startswith filters
            for prefix in ENV_FILTER_STARTSWITH:
                if key.startswith(prefix):
                    should_filter = True
                    break

            # Check endswith filters (for future use)
            if not should_filter:
                for suffix in ENV_FILTER_ENDSWITH:
                    if key.endswith(suffix):
                        should_filter = True
                        break

            # Check contains filters (for future use)
            if not should_filter:
                for pattern in ENV_FILTER_CONTAINS:
                    if pattern in key:
                        should_filter = True
                        break

            if should_filter:
                filtered_keys.append(key)
                del env[key]

        if filtered_keys:
            logging.info(f"Filtered out {len(filtered_keys)} system environment variables: {filtered_keys}")

        # Add proxy settings if configured
        if self._proxy_url:
            env['HTTP_PROXY'] = self._proxy_url
            env['HTTPS_PROXY'] = self._proxy_url
            env['http_proxy'] = self._proxy_url
            env['https_proxy'] = self._proxy_url
            logging.info(f"Using proxy environment variables: {self._proxy_url}")

        # Add enabled environment variables from .env file and remove unchecked ones
        try:
            env_vars = self.getEnvironmentVariables()
            enabled_count = 0
            removed_count = 0
            logging.info(f"Available environment variables: {list(env_vars.keys())}")
            logging.info(f"Environment settings: {self._environment_settings}")

            for key, value in env_vars.items():
                # Only apply environment variables that are enabled in settings
                if self._environment_settings.get(key, False):
                    env[key] = value
                    enabled_count += 1
                    logging.info(f"Applied environment variable: {key} = {value}")
                else:
                    # Remove unchecked environment variable even if it exists in host environment
                    if key in env:
                        del env[key]
                        removed_count += 1
                        logging.info(f"Removed unchecked environment variable: {key}")
                    else:
                        logging.info(f"Skipped disabled environment variable: {key}")

            logging.info(f"Applied {enabled_count} enabled and removed {removed_count} unchecked environment variables from .env file")
        except Exception as e:
            logging.error(f"Failed to apply .env environment variables: {e}")
            import traceback
            logging.error(f"Traceback: {traceback.format_exc()}")

        return env

    def _generate_env_echo_commands(self) -> str:
        """Generate batch file echo commands for enabled environment variables."""
        echo_commands = []
        try:
            env_vars = self.getEnvironmentVariables()
            for key, value in env_vars.items():
                if self._environment_settings.get(key, False):
                    # Escape any special characters in the value for batch file
                    safe_value = value.replace('"', '""').replace('%', '%%')
                    echo_commands.append(f'echo   {key} = {safe_value}')

            if not echo_commands:
                echo_commands.append('echo   (No environment variables enabled)')

        except Exception as e:
            echo_commands.append(f'echo   Error reading environment variables: {e}')

        return '\n'.join(echo_commands)

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
        try:
            plugin = self._find_plugin_by_name(plugin_name)
            if not plugin:
                self.errorOccurred.emit("Plugin Not Found", f"Plugin '{plugin_name}' not found.")
                logging.error(f"Plugin not found: {plugin_name}")
                return

            # Substitute macros in the command
            substituted_command = self._substitute_command_macros(command, plugin)

            logging.info(f"Executing command: {substituted_command}")

            # Execute the command in a new independent session
            if sys.platform == "win32":
                # On Windows, use cmd /c to execute in a new session
                subprocess.Popen(
                    f'cmd /c "{substituted_command}"',
                    cwd=str(plugin.path),
                    creationflags=subprocess.CREATE_NEW_CONSOLE
                )
            else:
                # On Unix-like systems
                subprocess.Popen(
                    substituted_command,
                    cwd=str(plugin.path),
                    shell=True
                )

            logging.info(f"Command executed successfully for plugin: {plugin_name}")

        except Exception as e:
            logging.error(f"Failed to execute command: {e}")
            self.errorOccurred.emit("Command Execution Failed", f"Could not execute command: {e}")

    # def _substitute_command_macros(self, command: str, plugin: Plugin) -> str:
    #     """Substitute macros in command string with actual paths."""
    #     plugin_dir = plugin.path.resolve()
    #     snippet_dir = plugin_dir / "snippets"
    #     command_dir = snippet_dir / "commands"

    #     # Macro converter functions
    #     macro_converters = {
    #         "{$PLUGIN_DIR}": lambda: str(plugin_dir),
    #         "{$SNIPPET_DIR}": lambda: str(snippet_dir),
    #         "{$COMMAND_DIR}": lambda: str(command_dir),
    #         "{$CURR_DIR}": lambda: str(command_dir),  # Alias for compatibility
    #         "{$CURRENT_DIR}": lambda: str(command_dir),  # Alias for compatibility
    #     }

    #     # Substitute all macros
    #     result = command
    #     for macro, converter in macro_converters.items():
    #         if macro in result:
    #             result = result.replace(macro, converter())

    #     return result

    def _substitute_command_macros(self, command: str, plugin: Plugin) -> str:
        """Substitute macros in command string with actual paths and environment variables."""
        # Handle path macros
        plugin_dir = plugin.path.resolve()
        snippet_dir = plugin_dir / "snippets"
        command_dir = snippet_dir / "commands"
    
        # Use standard ${MACRO_NAME} format
        macro_converters = {
            "${PLUGIN_DIR}": str(plugin_dir),
            "${SNIPPET_DIR}": str(snippet_dir),
            "${COMMAND_DIR}": str(command_dir),
            "${CURR_DIR}": str(command_dir),  # Alias for compatibility
            "${CURRENT_DIR}": str(command_dir),  # Alias for compatibility
        }
    
        result = command
        for macro, value in macro_converters.items():
            result = result.replace(macro, value)
    
        # Handle environment variable macros ${ENV:VAR_NAME}
        env_macro_pattern = r'\$\{ENV:([^\}]+)\}'
        for match in re.finditer(env_macro_pattern, result):
            variable_name = match.group(1)
            env_value = os.environ.get(variable_name, '')
            result = result.replace(match.group(0), env_value)
    
        return result