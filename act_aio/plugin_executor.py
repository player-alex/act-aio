"""Plugin execution and environment management.

This module handles:
- Plugin environment setup (virtual environments)
- Plugin process launching
- Command execution and macro substitution
- Environment variable management
"""

import os
import sys
import subprocess
import logging
import re
from pathlib import Path
from typing import Dict, Optional

from PySide6.QtCore import QThread, Signal

from .plugin_models import Plugin


# Environment variable filter constants
# These prefixes/patterns will be filtered out from system environment when launching plugins
ENV_FILTER_STARTSWITH = ['QT_', 'PYSIDE_']  # Filter keys starting with these prefixes
ENV_FILTER_ENDSWITH = []  # Filter keys ending with these suffixes (for future use)
ENV_FILTER_CONTAINS = []  # Filter keys containing these strings (for future use)


class PluginSetupWorker(QThread):
    """Worker thread for setting up plugin environment."""

    finished = Signal(bool, str)  # success, error_message
    progress = Signal(str)  # progress message

    def __init__(self, plugin, executor, parent=None):
        super().__init__(parent)
        self.plugin = plugin
        self.executor = executor

    def run(self):
        """Run the plugin setup in a separate thread."""
        try:
            success = self.executor._setup_plugin_environment_impl(self.plugin, self.progress)
            if success:
                self.finished.emit(True, "")
            else:
                self.finished.emit(False, "Failed to setup environment")
        except Exception as e:
            self.finished.emit(False, str(e))


class PluginExecutor:
    """Handles plugin execution, environment setup, and command execution."""

    def __init__(self, manager):
        """Initialize the executor with a reference to the PluginManager.

        Args:
            manager: The PluginManager instance that owns this executor.
        """
        self.manager = manager
        self._setup_worker = None
        self._pending_plugin = None

    def launch_plugin(self, plugin_name: str) -> bool:
        """Launch a plugin by name with uv environment management."""
        plugin = self.manager._find_plugin_by_name(plugin_name)
        if not plugin:
            error_msg = f"Plugin '{plugin_name}' not found.\n\nPlease check if the plugin exists in the plugins directory and refresh the plugin list."
            self.manager.errorOccurred.emit("Plugin Not Found", error_msg)
            print(f"Plugin '{plugin_name}' not found")
            return False

        if not plugin.is_executable:
            error_msg = f"Plugin '{plugin_name}' cannot be executed.\n\nThe plugin is missing a main.py file. Please check the plugin structure."
            self.manager.errorOccurred.emit("Plugin Not Executable", error_msg)
            print(f"Plugin '{plugin_name}' has no main.py file")
            return False

        try:
            # Check if environment already exists
            venv_base_dir = self.manager._plugins_dir / ".venv"
            plugin_venv_dir = venv_base_dir / plugin.name

            if not plugin_venv_dir.exists():
                # Setup environment in background thread
                self._pending_plugin = plugin
                self.manager.setupStarted.emit(plugin.alias or plugin.name)
                self._setup_worker = PluginSetupWorker(plugin, self)
                self._setup_worker.finished.connect(self._on_setup_finished)
                self._setup_worker.start()
                return True
            else:
                # Environment exists, launch directly
                return self._launch_plugin_process(plugin)

        except Exception as e:
            error_msg = f"Unexpected error while launching plugin '{plugin_name}'.\n\nError details:\n{str(e)}"
            self.manager.errorOccurred.emit("Plugin Launch Error", error_msg)
            print(f"Error launching plugin '{plugin_name}': {e}")
            return False

    def _on_setup_finished(self, success: bool, error_message: str):
        """Handle setup worker completion."""
        self.manager.setupFinished.emit()

        if success and self._pending_plugin:
            # Launch the plugin
            self._launch_plugin_process(self._pending_plugin)
        elif not success:
            error_msg = f"Failed to setup environment for plugin '{self._pending_plugin.name}'.\n\nError: {error_message}"
            self.manager.errorOccurred.emit("Environment Setup Failed", error_msg)

        self._pending_plugin = None
        self._setup_worker = None

    def _launch_plugin_process(self, plugin: Plugin) -> bool:
        """Launch the plugin process."""
        try:
            venv_base_dir = self.manager._plugins_dir / ".venv"
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
                    error_msg = f"Virtual environment for plugin '{plugin.name}' was not created properly.\n\nPlease try:\n1. Delete the plugin\n2. Re-import the plugin\n3. Check UV installation"
                    self.manager.errorOccurred.emit("Virtual Environment Missing", error_msg)
                    print(f"Virtual environment directory does not exist: {plugin_venv_dir}")
                    return False

                # If still no python executable found
                if not python_exe.exists():
                    error_msg = f"Python executable not found for plugin '{plugin.name}'.\n\nThe virtual environment appears corrupted. Please try:\n1. Delete the plugin\n2. Re-import the plugin\n3. Check UV installation"
                    self.manager.errorOccurred.emit("Python Executable Missing", error_msg)
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
            enabled_env_vars = [k for k, v in self.manager._environment_settings.items() if v]
            disabled_env_vars = [k for k, v in self.manager._environment_settings.items() if not v]

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

            # Check if plugin has custom exec command
            if plugin.exec_command:
                # Determine the command based on exec_command type
                if isinstance(plugin.exec_command, dict):
                    # Platform-specific commands
                    custom_cmd = plugin.exec_command.get(sys.platform)
                    if not custom_cmd:
                        print(f"Warning: No exec command defined for platform '{sys.platform}', falling back to default")
                else:
                    # Simple string command (cross-platform)
                    custom_cmd = plugin.exec_command

                if custom_cmd:
                    # Apply macro substitution to custom command
                    custom_cmd = self._substitute_command_macros(custom_cmd, plugin)
                    print(f"Using custom exec command: {custom_cmd}")

                    if sys.platform == "win32":
                        # On Windows, wrap in cmd /c with error handling
                        cmd_string = f'cmd /c "{custom_cmd} & if %ERRORLEVEL% neq 0 (echo Exit code: %ERRORLEVEL% & pause)"'
                        print(f"Executing command: {cmd_string}")
                        print(f"Working directory: {plugin.path}")
                        subprocess.Popen(
                            cmd_string,
                            cwd=str(plugin.path),
                            env=env,
                            creationflags=subprocess.CREATE_NEW_CONSOLE
                        )
                    else:
                        # On Unix-like systems
                        subprocess.Popen(
                            custom_cmd,
                            cwd=str(plugin.path),
                            env=env,
                            shell=True
                        )
                    print(f"Launched plugin: {plugin.name}")
                else:
                    # Fall back to default if custom_cmd is None
                    print("No valid custom exec command, using default uv run")
                    self._launch_with_default_command(plugin, env)
            else:
                # Use default uv run command
                print("Using default uv run command")
                self._launch_with_default_command(plugin, env)


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
            self.manager.errorOccurred.emit("Plugin Launch Error", error_msg)
            print(f"Error launching plugin '{plugin.name}': {e}")
            return False

    def _launch_with_default_command(self, plugin: Plugin, env: dict):
        """Launch plugin with default uv run command."""
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

    def _setup_plugin_environment_impl(self, plugin: Plugin, progress: Signal = None) -> bool:
        """Setup uv environment for a plugin in centralized venv directory (implementation)."""
        try:
            plugin_path = plugin.path
            pyproject_file = plugin_path / "pyproject.toml"
            requirements_file = plugin_path / "requirements.txt"

            # Create centralized venv directory structure
            venv_base_dir = self.manager._plugins_dir / ".venv"
            plugin_venv_dir = venv_base_dir / plugin.name

            print(f"Setting up environment for plugin: {plugin.name}")
            print(f"Virtual environment location: {plugin_venv_dir}")

            # Check if uv is available
            if not self._check_uv_command():
                error_msg = "UV command not found. Please install UV package manager to use plugins.\n\nVisit: https://docs.astral.sh/uv/getting-started/installation/"
                self.manager.errorOccurred.emit("UV Not Found", error_msg)
                print("uv command not found. Please install uv.")
                return False

            # Create the venv base directory if it doesn't exist
            venv_base_dir.mkdir(exist_ok=True)

            # Create virtual environment in centralized location
            if not plugin_venv_dir.exists():
                print(f"Creating virtual environment for {plugin.name}")
                print(f"Command: uv venv {plugin_venv_dir}")
                print(f"Working directory: {self.manager._plugins_dir.parent}")
                result = subprocess.run(
                    ["uv", "venv", str(plugin_venv_dir)],
                    cwd=str(self.manager._plugins_dir.parent),  # Run from the main project directory
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
                    self.manager.errorOccurred.emit("Environment Setup Failed", error_msg)
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

            print(f"Environment setup completed for {plugin.name}")
            return True

        except subprocess.TimeoutExpired:
            error_msg = f"Timeout while setting up environment for plugin '{plugin.name}'.\n\nThe installation took too long (>5 minutes). This could be due to:\n- Slow network connection\n- Large package dependencies\n- Proxy issues"
            self.manager.errorOccurred.emit("Installation Timeout", error_msg)
            print(f"Timeout while setting up environment for {plugin.name}")
            return False
        except Exception as e:
            error_msg = f"Unexpected error while setting up environment for plugin '{plugin.name}'.\n\nError details:\n{str(e)}"
            self.manager.errorOccurred.emit("Environment Setup Error", error_msg)
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

    def executeCommand(self, plugin_name: str, command: str):
        """Execute a command snippet for a plugin."""
        try:
            plugin = self.manager._find_plugin_by_name(plugin_name)
            if not plugin:
                self.manager.errorOccurred.emit("Plugin Not Found", f"Plugin '{plugin_name}' not found.")
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
            self.manager.errorOccurred.emit("Command Execution Failed", f"Could not execute command: {e}")

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
        if self.manager._proxy_url:
            env['HTTP_PROXY'] = self.manager._proxy_url
            env['HTTPS_PROXY'] = self.manager._proxy_url
            env['http_proxy'] = self.manager._proxy_url
            env['https_proxy'] = self.manager._proxy_url
            logging.info(f"Using proxy environment variables: {self.manager._proxy_url}")

        # Add enabled environment variables from .env file and remove unchecked ones
        try:
            env_vars = self.manager.getEnvironmentVariables()
            enabled_count = 0
            removed_count = 0
            logging.info(f"Available environment variables: {list(env_vars.keys())}")
            logging.info(f"Environment settings: {self.manager._environment_settings}")

            for key, value in env_vars.items():
                # Only apply environment variables that are enabled in settings
                if self.manager._environment_settings.get(key, False):
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
            env_vars = self.manager.getEnvironmentVariables()
            for key, value in env_vars.items():
                if self.manager._environment_settings.get(key, False):
                    # Escape any special characters in the value for batch file
                    safe_value = value.replace('"', '""').replace('%', '%%')
                    echo_commands.append(f'echo   {key} = {safe_value}')
        except Exception as e:
            logging.error(f"Failed to generate env echo commands: {e}")

        return '\n'.join(echo_commands) if echo_commands else 'echo   No environment variables enabled'
