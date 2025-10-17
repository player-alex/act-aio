#!/usr/bin/env python3

import sys
import os
import json
import logging
import platform
import uuid
import hashlib
from datetime import datetime
from pathlib import Path
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import qmlRegisterType, QQmlApplicationEngine
from PySide6.QtCore import QUrl
from PySide6.QtGui import QFontDatabase
from PySide6.QtQuickControls2 import QQuickStyle
import posthog

from . import qml_qrc
from .plugin_manager import PluginManager
from .models import PluginListModel
from .tracking import tracking_context

def resource_path(relative_path):
    """ Get absolute path to resource, works for dev and for Nuitka """
    if getattr(sys, 'frozen', False):
        # Nuitka one-file mode
        base_path = Path(sys.executable).parent
    else:
        # Development mode
        base_path = Path(__file__).parent.parent
    return base_path / relative_path

def load_posthog_config():
    """Load PostHog configuration from credentials file."""
    try:
        credentials_path = Path(__file__).parent.parent / "credentials" / "posthog.json"
        with open(credentials_path, 'r') as f:
            config = json.load(f)
        return config.get('key')
    except Exception as e:
        logging.error(f"Failed to load PostHog config: {e}")
        return None


def setup_posthog():
    """Initialize PostHog client."""
    api_key = load_posthog_config()
    if api_key:
        posthog.api_key = api_key
        posthog.host = 'https://app.posthog.com'

        # Disable geo IP and IP address tracking for privacy
        posthog.disable_geoip = True

        logging.info("PostHog initialized successfully (geo IP disabled)")
        return True
    else:
        logging.warning("PostHog initialization failed - no API key found")
        return False


def get_system_info():
    """Get system information for tracking."""
    return {
        'os': platform.system(),
        'os_version': platform.version(),
        'python_version': platform.python_version(),
        'machine': platform.machine(),
        'processor': platform.processor()
    }


def get_hardware_uuid():
    """Generate a hardware-based UUID for analytics separation."""
    try:
        # Get hardware identifiers
        machine_id = platform.machine()
        processor_info = platform.processor()
        system_info = platform.system()

        # Try to get more specific hardware info
        try:
            import subprocess
            if platform.system() == "Windows":
                # Get Windows machine GUID/UUID
                result = subprocess.run(
                    ["wmic", "csproduct", "get", "UUID"],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                if result.returncode == 0:
                    lines = result.stdout.strip().split('\n')
                    for line in lines:
                        line = line.strip()
                        if line and line != "UUID" and len(line) > 10:
                            machine_id = line
                            break
            elif platform.system() == "Linux":
                # Try to get machine-id
                try:
                    with open('/etc/machine-id', 'r') as f:
                        machine_id = f.read().strip()
                except:
                    try:
                        with open('/var/lib/dbus/machine-id', 'r') as f:
                            machine_id = f.read().strip()
                    except:
                        pass
        except Exception:
            # Fallback to basic platform info
            pass

        # Create a stable hash from hardware info
        hardware_string = f"{machine_id}-{processor_info}-{system_info}"
        hardware_hash = hashlib.sha256(hardware_string.encode()).hexdigest()

        # Generate UUID from hardware hash (deterministic)
        hardware_uuid = str(uuid.uuid5(uuid.NAMESPACE_DNS, hardware_hash))

        logging.info(f"Generated hardware UUID: {hardware_uuid[:8]}...")
        return hardware_uuid

    except Exception as e:
        logging.warning(f"Failed to generate hardware UUID, using fallback: {e}")
        # Fallback to a pseudo-random but somewhat stable UUID
        fallback_string = f"{platform.node()}-{platform.machine()}-{platform.processor()}"
        fallback_hash = hashlib.md5(fallback_string.encode()).hexdigest()
        return str(uuid.uuid5(uuid.NAMESPACE_DNS, fallback_hash))


def get_session_id():
    """Generate a unique session ID."""
    return str(uuid.uuid4())


def track_plugin_event(event_name, plugin_name, session_id=None, hardware_uuid=None):
    """Track plugin-related events with PostHog."""
    try:
        properties = {
            'script_name': 'act_aio',
            'session_id': session_id or 'unknown',
            'plugin_name': plugin_name,
            'event_time': datetime.now().strftime('%H:%M:%S')
        }

        # Add system information
        properties.update(get_system_info())

        posthog.capture(
            distinct_id=hardware_uuid or 'anonymous',
            event=event_name,
            properties=properties,
            send_feature_flags=False
        )
        logging.info(f"Tracked event: {event_name} for plugin: {plugin_name}")

        # Debug mode: print properties for easy verification
        if os.getenv('POSTHOG_DEBUG'):
            logging.info(f"Plugin event properties: {json.dumps(properties, indent=2)}")

    except Exception as e:
        logging.error(f"Failed to track plugin event {event_name}: {e}")


def track_script_event(event_name, session_id=None, hardware_uuid=None, start_time=None, end_time=None):
    """Track script events with PostHog."""
    try:
        properties = {
            'script_name': 'act_aio',
            'session_id': session_id or 'unknown'
        }

        # Add system information
        properties.update(get_system_info())

        # Add timing information
        if start_time:
            properties['start_datetime'] = start_time.isoformat()
            properties['start_time'] = start_time.strftime('%H:%M:%S')
        if end_time:
            properties['end_datetime'] = end_time.isoformat()
            properties['end_time'] = end_time.strftime('%H:%M:%S')
            if start_time:
                duration = (end_time - start_time).total_seconds()
                properties['session_duration_seconds'] = duration
                logging.info(f"Session duration: {duration:.2f} seconds")

        posthog.capture(
            distinct_id=hardware_uuid or 'anonymous',
            event=event_name,
            properties=properties,
            send_feature_flags=False
        )
        logging.info(f"Tracked event: {event_name} (session: {session_id})")

        # Debug mode: print properties for easy verification
        if os.getenv('POSTHOG_DEBUG'):
            logging.info(f"Event properties: {json.dumps(properties, indent=2)}")

    except Exception as e:
        logging.error(f"Failed to track event {event_name}: {e}")


def load_fonts():
    """Load Roboto fonts from the fonts directory."""
    fonts_dir = resource_path("fonts")

    if fonts_dir.exists():
        for font_file in fonts_dir.rglob("*.ttf"):
            font_id = QFontDatabase.addApplicationFont(str(font_file))
            if font_id != -1:
                font_families = QFontDatabase.applicationFontFamilies(font_id)
                print(f"Loaded font: {font_families}")


def main():
    """Main application entry point."""
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

    # Generate unique identifiers
    session_id = get_session_id()
    hardware_uuid = get_hardware_uuid()
    start_time = datetime.now()
    logging.info(f"Act-AIO started at {start_time} (session: {session_id})")

    # Set global tracking context
    tracking_context.set_context(session_id, hardware_uuid)

    posthog_enabled = setup_posthog()

    if posthog_enabled:
        track_script_event('started_act_aio', session_id=session_id, hardware_uuid=hardware_uuid, start_time=start_time)

    app = QApplication(sys.argv)

    # Set Qt Quick Controls style to Basic for customization support
    QQuickStyle.setStyle("Basic")

    # Load fonts
    load_fonts()

    # Register QML types
    qmlRegisterType(PluginListModel, "ActAio", 1, 0, "PluginListModel")
    qmlRegisterType(PluginManager, "ActAio", 1, 0, "PluginManager")

    # Create a PluginManager instance and set the tracking IDs
    plugin_manager = PluginManager()
    plugin_manager.set_session_id(session_id)
    plugin_manager.set_hardware_uuid(hardware_uuid)

    # Create QML engine
    engine = QQmlApplicationEngine()

    # Set up the QML source
    # qml_file = Path(__file__).parent / "qml" / "main.qml"
    # engine.load(QUrl.fromLocalFile(str(qml_file)))
    engine.load("qrc:/qml/main.qml")

    if not engine.rootObjects():
        end_time = datetime.now()
        logging.error(f"Failed to load QML at {end_time}")
        if posthog_enabled:
            track_script_event('ended_act_aio', session_id=session_id, hardware_uuid=hardware_uuid, start_time=start_time, end_time=end_time)
        sys.exit(1)

    try:
        exit_code = app.exec()
    finally:
        end_time = datetime.now()
        logging.info(f"Act-AIO ended at {end_time}")
        if posthog_enabled:
            track_script_event('ended_act_aio', session_id=session_id, hardware_uuid=hardware_uuid, start_time=start_time, end_time=end_time)

    sys.exit(exit_code)


if __name__ == "__main__":
    main()