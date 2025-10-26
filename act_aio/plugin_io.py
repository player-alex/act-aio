"""
Plugin I/O operations.

This module handles plugin import/export functionality including:
- Importing plugins from disk (zip files)
- Importing plugins from URLs
- Exporting plugins to zip files
- Managing import confirmation dialogs
"""

import asyncio
import sys
import logging
import zipfile
import shutil
import tempfile
from pathlib import Path

import httpx
from PySide6.QtCore import QThread, Signal
from PySide6.QtWidgets import QFileDialog

from .plugin_utils import safe_rmtree


class PluginImportWorker(QThread):
    """Worker thread for importing plugin from URL."""

    finished = Signal(bool, str, object)  # success, error_message, import_data (source_dir, target_dir, plugin_name)
    progress = Signal(int, str)  # percentage (0-100), status_message

    def __init__(self, url, plugins_dir, parent=None):
        super().__init__(parent)
        self.url = url
        self.plugins_dir = plugins_dir
        self.temp_zip_path = None
        self._is_cancelled = False
        self._asyncio_task = None

    def cancel(self):
        """Request cancellation of the import process."""
        logging.info("Cancellation requested for plugin import.")
        self._is_cancelled = True
        if self._asyncio_task:
            # Cancel executing asyncio task directly
            self._asyncio_task.cancel()

    def run(self):
        """Sets up and runs the asyncio event loop."""
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        try:
            # Create async task in current thread.
            self._asyncio_task = loop.create_task(self._run_async())
            # Execute task.
            loop.run_until_complete(self._asyncio_task)
        except asyncio.CancelledError:
            # If task cancelled by externally
            logging.info("Asyncio task was cancelled.")
            error_message = "Download cancelled by user."
            self.finished.emit(False, error_message, None)
        finally:
            loop.close()

    async def _run_async(self):
        """Run the plugin import in a separate thread."""
        success = False
        error_message = ""
        import_data = None
        # 1. Create a single top-level temporary directory for all operations.
        main_temp_dir = tempfile.mkdtemp(prefix="plugin_import_")
        logging.info(f"Created main temporary directory: {main_temp_dir}")

        try:
            self.progress.emit(-1, "Starting download...")

            # 2. Download the zip file into the main temporary directory.
            temp_zip_path = Path(main_temp_dir) / 'plugin.zip'

            # Download the file with httpx using streaming
            try:
                self.progress.emit(-1, "Connecting to server...")
                async with httpx.AsyncClient(timeout=60.0, follow_redirects=True) as client:
                    async with client.stream('GET', self.url) as response:
                        response.raise_for_status()
                        total_size = int(response.headers.get('content-length', 0))
                        downloaded_size = 0
                        chunk_size = 8192

                        with open(temp_zip_path, 'wb') as f:
                            async for chunk in response.aiter_bytes(chunk_size=chunk_size):
                                if self._is_cancelled:
                                    raise asyncio.CancelledError()

                                if chunk:
                                    f.write(chunk)
                                    downloaded_size += len(chunk)
                                    if total_size > 0:
                                        percentage = int((downloaded_size / total_size) * 100)
                                        self.progress.emit(percentage, f"Downloading... {downloaded_size // 1024} KB / {total_size // 1024} KB")
                                    else:
                                        self.progress.emit(-1, f"Downloading... {downloaded_size // 1024} KB")
                        logging.info(f"Downloaded {downloaded_size} bytes to {temp_zip_path}")

            except httpx.ConnectError as e:
                error_message = f"Could not connect to the server.\n\nPlease check:\n- Your internet connection\n- The URL is correct and accessible\n- SSL certificate issues\n\nError: {str(e)}"
                logging.error(error_message)
                self.finished.emit(False, error_message, None)
            except httpx.HTTPStatusError as e:
                error_message = f"HTTP error {e.response.status_code}: {e.response.reason_phrase}\n\nURL: {self.url}"
                logging.error(error_message)
                self.finished.emit(False, error_message, None)
            except httpx.TimeoutException as e:
                error_message = f"The request took too long (>60 seconds).\n\nPlease check your internet connection and try again later."
                logging.error(error_message)
                self.finished.emit(False, error_message, None)
            except Exception as e:
                # 그 외 모든 예외 처리
                error_message = f"An unexpected error occurred: {e}"
                logging.error(error_message)
                self.finished.emit(False, error_message, None)

            # 3. Verify it's a valid zip file
            self.progress.emit(-1, "Verifying...")
            if not zipfile.is_zipfile(temp_zip_path):
                error_message = f"The downloaded file is not a valid zip file.\n\nPlease check the URL and try again."
                raise Exception(error_message)
            logging.info(f"Successfully downloaded and verified zip file")

            # 4. Extract the zip into a sub-directory within the main temp directory
            extraction_path = Path(main_temp_dir) / "extracted"
            extraction_path.mkdir()
            try:
                with zipfile.ZipFile(temp_zip_path, 'r') as zip_ref:
                    file_list = zip_ref.namelist()
                    total_files = len(file_list)
                    self.progress.emit(0, f"Extracting... 0/{total_files} files")
                    for i, file in enumerate(file_list):
                        if self._is_cancelled:
                            raise asyncio.CancelledError()

                        zip_ref.extract(file, extraction_path)

                        # Restore Windows file attributes on Windows
                        if sys.platform == "win32":
                            try:
                                zip_info = zip_ref.getinfo(file)
                                # Windows attributes are stored in LOWER 16 bits (MS-DOS format)
                                win_attrs = zip_info.external_attr & 0xFFFF

                                if win_attrs != 0:
                                    extracted_file = extraction_path / file
                                    if extracted_file.exists() and extracted_file.is_file():
                                        # Set Windows attributes
                                        import ctypes
                                        ctypes.windll.kernel32.SetFileAttributesW(str(extracted_file), win_attrs)
                                        logging.debug(f"Restored Windows attributes for {file}: 0x{win_attrs:x}")
                            except Exception as e:
                                logging.warning(f"Failed to restore attributes for {file}: {e}")

                        percentage = int((i + 1) / total_files * 100)
                        self.progress.emit(percentage, f"Extracting... {i + 1}/{total_files} files")
            except Exception as e:
                error_message = f"Failed to extract zip file: {e}"
                raise

            # 5. Find the plugin directory
            plugin_dirs = [item for item in extraction_path.iterdir() if item.is_dir() and ((item / "pyproject.toml").exists() or (item / "main.py").exists())]

            if not plugin_dirs:
                error_message = "No valid plugin found in zip file. Plugin should contain pyproject.toml or main.py."
                raise Exception(error_message)
            if len(plugin_dirs) > 1:
                error_message = "Zip file contains multiple plugins. Please import one plugin at a time."
                raise Exception(error_message)

            source_dir = plugin_dirs[0]
            plugin_name = source_dir.name
            target_dir = self.plugins_dir / plugin_name

            # 6. Prepare import data without moving any files yet.
            # The source_dir is still in the temporary location.
            import_data = {
                'source_dir': source_dir,
                'target_dir': target_dir,
                'plugin_name': plugin_name,
                'needs_confirmation': target_dir.exists(),
                'temp_cleanup_dir': main_temp_dir  # Pass the main temp dir for later cleanup
            }

            if import_data['needs_confirmation']:
                self.progress.emit(100, "Plugin already exists")
            else:
                self.progress.emit(100, "Import ready")

            success = True

            # 8. Emit the finished signal.
            # If successful, the responsibility to clean up main_temp_dir is passed to the main thread.
            self.finished.emit(success, error_message, import_data)
            return

        except asyncio.CancelledError:
            if main_temp_dir and Path(main_temp_dir).exists():
                safe_rmtree(main_temp_dir)
            raise

        except Exception as e:
            if main_temp_dir and Path(main_temp_dir).exists():
                safe_rmtree(main_temp_dir)

            if not error_message:
                error_message = f"Failed to import plugin from URL: {e}"
            logging.error(f"Error importing plugin from URL: {e}")
            success = False
            self.finished.emit(False, error_message, None)

        self.finished.emit(False, error_message, None)


class PluginIOManager:
    """Manages plugin import/export operations."""

    def __init__(self, manager):
        """
        Initialize the PluginIOManager.

        Args:
            manager: Reference to the parent PluginManager instance
        """
        self.manager = manager
        self._import_worker = None
        self._pending_import_data = None
        self._temp_import_dir = None

    def cleanup_old_temp_dirs(self):
        """Clean up any leftover .temp_import_ directories from previous crashes."""
        try:
            if not self.manager._plugins_dir.exists():
                return

            # Find and remove all .temp_import_* directories
            temp_dirs = list(self.manager._plugins_dir.glob(".temp_import_*"))
            if temp_dirs:
                logging.info(f"Found {len(temp_dirs)} leftover temporary import directories")
                for temp_dir in temp_dirs:
                    try:
                        safe_rmtree(temp_dir)
                        logging.info(f"Cleaned up leftover temp directory: {temp_dir}")
                    except Exception as e:
                        logging.error(f"Failed to clean up temp directory {temp_dir}: {e}")
        except Exception as e:
            logging.error(f"Error during temp directory cleanup: {e}")

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
                self.manager._show_error("Invalid file", "Please select a valid zip file.")
                return

            # Clean up any previous temp import directory
            if self._temp_import_dir and Path(self._temp_import_dir).exists():
                safe_rmtree(self._temp_import_dir)
                self._temp_import_dir = None

            # Create persistent temporary directory for extraction
            self._temp_import_dir = tempfile.mkdtemp(prefix="plugin_import_")
            temp_path = Path(self._temp_import_dir)

            # Extract zip file
            try:
                with zipfile.ZipFile(file_path, 'r') as zip_ref:
                    zip_ref.extractall(temp_path)

                    # Restore Windows file attributes on Windows
                    if sys.platform == "win32":
                        for file in zip_ref.namelist():
                            try:
                                zip_info = zip_ref.getinfo(file)
                                # Windows attributes are stored in LOWER 16 bits (MS-DOS format)
                                win_attrs = zip_info.external_attr & 0xFFFF

                                if win_attrs != 0:
                                    extracted_file = temp_path / file
                                    if extracted_file.exists() and extracted_file.is_file():
                                        # Set Windows attributes
                                        import ctypes
                                        ctypes.windll.kernel32.SetFileAttributesW(str(extracted_file), win_attrs)
                                        logging.debug(f"Restored Windows attributes for {file}: 0x{win_attrs:x}")
                            except Exception as e:
                                logging.warning(f"Failed to restore attributes for {file}: {e}")

            except Exception as e:
                self.manager._show_error("Extraction failed", f"Failed to extract zip file: {e}")
                # Clean up temp directory on error
                if self._temp_import_dir and Path(self._temp_import_dir).exists():
                    safe_rmtree(self._temp_import_dir)
                    self._temp_import_dir = None
                return

            # Find the plugin directory (should contain pyproject.toml or main.py)
            plugin_dirs = []
            for item in temp_path.iterdir():
                if item.is_dir():
                    if (item / "pyproject.toml").exists() or (item / "main.py").exists():
                        plugin_dirs.append(item)

            if len(plugin_dirs) == 0:
                self.manager._show_error("Invalid plugin", "No valid plugin found in zip file. Plugin should contain pyproject.toml or main.py.")
                # Clean up temp directory
                if self._temp_import_dir and Path(self._temp_import_dir).exists():
                    safe_rmtree(self._temp_import_dir)
                    self._temp_import_dir = None
                return
            elif len(plugin_dirs) > 1:
                self.manager._show_error("Multiple plugins", "Zip file contains multiple plugins. Please import one plugin at a time.")
                # Clean up temp directory
                if self._temp_import_dir and Path(self._temp_import_dir).exists():
                    safe_rmtree(self._temp_import_dir)
                    self._temp_import_dir = None
                return

            source_dir = plugin_dirs[0]
            plugin_name = source_dir.name

            # Check if plugin already exists
            target_dir = self.manager._plugins_dir / plugin_name
            if target_dir.exists():
                # Store import data and request confirmation
                # Files stay in system temp directory until user confirms
                self._pending_import_data = {
                    'source_dir': source_dir,
                    'target_dir': target_dir,
                    'plugin_name': plugin_name,
                    'temp_cleanup_dir': self._temp_import_dir
                }
                self.manager.confirmationRequested.emit(
                    "Plugin exists",
                    f"Plugin '{plugin_name}' already exists. Do you want to overwrite it?",
                    "import_overwrite"
                )
                return

            # Copy plugin to plugins directory
            self._complete_import(source_dir, target_dir, plugin_name)

        except Exception as e:
            logging.error(f"Error importing plugin: {e}")
            self.manager._show_error("Import failed", f"Failed to import plugin: {e}")
            # Clean up temp directory on error
            if self._temp_import_dir and Path(self._temp_import_dir).exists():
                safe_rmtree(self._temp_import_dir)
                self._temp_import_dir = None

    def importPluginFromUrl(self, url: str):
        """Import a plugin from a URL pointing to a zip file."""
        # Validate URL
        if not url or not url.strip():
            self.manager._show_error("Invalid URL", "Please enter a valid URL.")
            return

        url = url.strip()

        # Basic URL validation
        if not url.startswith(('http://', 'https://')):
            self.manager._show_error("Invalid URL", "URL must start with http:// or https://")
            return

        logging.info(f"Importing plugin from URL: {url}")

        # Emit import started signal
        self.manager.importStarted.emit()

        # Create worker thread for background download
        self._import_worker = PluginImportWorker(url, self.manager._plugins_dir)

        # Connect worker signals
        self._import_worker.progress.connect(self.manager.importProgress.emit)
        self._import_worker.finished.connect(self._on_import_finished)

        # Connect to deleteLater
        self._import_worker.finished.connect(self._import_worker.deleteLater)

        # Start the worker
        self._import_worker.start()

    def _on_import_finished(self, success: bool, error_message: str, import_data: dict):
        """Handle import worker completion."""
        self.manager.importFinished.emit(success)

        if not success:
            self.manager._show_error("Import Failed", error_message)
            return

        if not import_data:
            return

        # If confirmation is needed, store data and ask user.
        if import_data.get('needs_confirmation'):
            self._pending_import_data = import_data
            self.manager.confirmationRequested.emit(
                "Plugin exists",
                f"Plugin '{import_data['plugin_name']}' already exists. Do you want to overwrite it?",
                "import_overwrite"
            )
        else:
            # No confirmation needed, complete the import by moving files.
            try:
                shutil.move(str(import_data['source_dir']), str(import_data['target_dir']))
                logging.info(f"Plugin '{import_data['plugin_name']}' imported successfully.")
                self.manager.scan_plugins()
                self.manager._show_info("Import successful", f"Plugin '{import_data['plugin_name']}' has been imported successfully.")
                self.manager.importSucceeded.emit()
            except Exception as e:
                logging.error(f"Error completing import: {e}")
                self.manager._show_error("Import failed", f"Failed to import plugin: {e}")
            finally:
                # Clean up the main temporary directory.
                temp_cleanup_dir = import_data.get('temp_cleanup_dir')
                if temp_cleanup_dir and Path(temp_cleanup_dir).exists():
                    safe_rmtree(temp_cleanup_dir)
                    logging.info(f"Cleaned up temporary import directory: {temp_cleanup_dir}")

        # self._import_worker = None

    def cancel_import(self):
        """Cancel the ongoing plugin import process."""
        if self._import_worker and self._import_worker.isRunning():
            self._import_worker.cancel()

    def exportPlugin(self, plugin_display_name: str, plugin_path: str):
        """Export a plugin to a zip file."""
        try:
            if not plugin_path:
                self.manager._show_error("No selection", "Please select a plugin to export.")
                return

            plugin_dir = Path(plugin_path)
            if not plugin_dir.exists() or not plugin_dir.is_dir():
                self.manager._show_error("Plugin not found", f"Plugin directory '{plugin_path}' not found.")
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

                            # Create ZipInfo with proper attributes
                            zip_info = zipfile.ZipInfo.from_file(file, str(rel_path))

                            # Preserve Windows file attributes on Windows
                            if sys.platform == "win32":
                                try:
                                    import os
                                    # Get Windows file attributes
                                    win_attrs = os.stat(file).st_file_attributes

                                    # For Windows files, store attributes in LOWER 16 bits (MS-DOS format)
                                    # and set the host OS to MS-DOS (0) to indicate Windows attributes
                                    # Upper 16 bits are Unix permissions (kept for compatibility)
                                    zip_info.external_attr = (zip_info.external_attr & 0xFFFF0000) | win_attrs

                                    logging.debug(f"Preserved Windows attributes for {file.name}: 0x{win_attrs:x}")
                                except Exception as e:
                                    logging.warning(f"Failed to preserve attributes for {file}: {e}")

                            # Write file to zip with the prepared ZipInfo
                            with open(file, 'rb') as f:
                                zip_ref.writestr(zip_info, f.read(), compress_type=zipfile.ZIP_DEFLATED)

                logging.info(f"Plugin '{plugin_display_name}' exported to {file_path}")
                self.manager._show_info("Export successful", f"Plugin '{plugin_display_name}' has been exported to {file_path}")

            except Exception as e:
                self.manager._show_error("Export failed", f"Failed to create zip file: {e}")

        except Exception as e:
            logging.error(f"Error exporting plugin: {e}")
            self.manager._show_error("Export failed", f"Failed to export plugin: {e}")

    def _complete_import(self, source_dir: Path, target_dir: Path, plugin_name: str):
        """Complete the import process by copying files and refreshing."""
        try:
            # Copy plugin to plugins directory
            shutil.copytree(source_dir, target_dir)
            logging.info(f"Plugin '{plugin_name}' imported successfully")

            # Refresh plugin list
            self.manager.scan_plugins()

            self.manager._show_info("Import successful", f"Plugin '{plugin_name}' has been imported successfully.")

            # Emit success signal to close UrlInputDialog
            self.manager.importSucceeded.emit()
        except Exception as e:
            logging.error(f"Error completing import: {e}")
            self.manager._show_error("Import failed", f"Failed to import plugin: {e}")
        finally:
            # Always clean up system temp directory after import (success or failure)
            if self._temp_import_dir and Path(self._temp_import_dir).exists():
                try:
                    safe_rmtree(self._temp_import_dir)
                    logging.info(f"Cleaned up temporary import directory: {self._temp_import_dir}")
                    self._temp_import_dir = None
                except Exception as cleanup_error:
                    logging.error(f"Failed to clean up temp directory: {cleanup_error}")

    def handleConfirmationResponse(self, callback_id: str, accepted: bool):
        """Handle confirmation dialog response from QML."""
        if callback_id == "import_overwrite":
            pending_data = self._pending_import_data
            self._pending_import_data = None  # Clear pending data immediately

            if not pending_data:
                logging.warning("handleConfirmationResponse called with no pending import data.")
                return

            temp_cleanup_dir = pending_data.get('temp_cleanup_dir')

            try:
                if accepted:
                    logging.info(f"User accepted overwrite for plugin '{pending_data['plugin_name']}'.")
                    # Remove existing plugin
                    if Path(pending_data['target_dir']).exists():
                        safe_rmtree(pending_data['target_dir'])

                    # Copy the new version from temp to plugins directory
                    shutil.copytree(str(pending_data['source_dir']), str(pending_data['target_dir']))

                    logging.info(f"Plugin '{pending_data['plugin_name']}' overwritten and imported successfully.")
                    self.manager.scan_plugins()
                    self.manager._show_info("Import successful", f"Plugin '{pending_data['plugin_name']}' has been overwritten successfully.")
                    self.manager.importSucceeded.emit()
                else:
                    # User cancelled
                    logging.info("User cancelled plugin overwrite.")
            except Exception as e:
                logging.error(f"Error overwriting plugin: {e}")
                self.manager._show_error("Import failed", f"Failed to overwrite plugin: {e}")
            finally:
                # Always clean up the system temporary directory
                if temp_cleanup_dir and Path(temp_cleanup_dir).exists():
                    try:
                        safe_rmtree(temp_cleanup_dir)
                        logging.info(f"Cleaned up temporary import directory: {temp_cleanup_dir}")
                    except Exception as cleanup_error:
                        logging.error(f"Failed to clean up temp directory: {cleanup_error}")

                # Also clean up the instance variable if it matches
                if self._temp_import_dir == temp_cleanup_dir:
                    self._temp_import_dir = None
