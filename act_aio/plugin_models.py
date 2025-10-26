"""
Plugin data models.

This module contains data classes for representing plugin information.
"""

from pathlib import Path
from typing import Dict, Any


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

        # Parse custom execution command (supports string or dict for platform-specific)
        self.exec_command = metadata.get("exec", None)

        self.main_file = path / "main.py"

    @property
    def is_executable(self) -> bool:
        """Check if the plugin has a main.py file."""
        return self.main_file.exists()
