"""
Utility functions for plugin management.

This module contains common utility functions used across the plugin management system,
including file system operations and error handling helpers.
"""

import os
import stat
import shutil
import logging
from pathlib import Path


def remove_readonly(func, path, excinfo):
    """
    Error handler for shutil.rmtree to remove read-only attributes.

    This is called when rmtree encounters permission errors, particularly
    on Windows systems where files may have read-only attributes set.

    Args:
        func: The function that raised the error (typically os.unlink or os.rmdir)
        path: The path to the file/directory that caused the error
        excinfo: Exception information from sys.exc_info()

    Raises:
        Exception: If removing read-only attribute fails
    """
    try:
        # Remove read-only attribute and retry
        os.chmod(path, stat.S_IWRITE | stat.S_IREAD)
        func(path)
        logging.debug(f"Removed read-only attribute and deleted: {path}")
    except Exception as e:
        logging.error(f"Failed to remove read-only file {path}: {e}")
        raise


def safe_rmtree(path):
    """
    Safely remove a directory tree, handling read-only files on Windows.

    This function wraps shutil.rmtree with proper error handling for read-only
    files, which is a common issue on Windows systems.

    Args:
        path: Path object or string path to the directory to remove

    Raises:
        Exception: If directory removal fails even after removing read-only attributes
    """
    path = Path(path)
    if path.exists():
        try:
            shutil.rmtree(path, onerror=remove_readonly)
            logging.info(f"Successfully removed directory: {path}")
        except Exception as e:
            logging.error(f"Failed to remove directory {path}: {e}")
            raise
