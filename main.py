import json
import logging
from datetime import datetime
from pathlib import Path
import posthog

def load_posthog_config():
    """Load PostHog configuration from credentials file."""
    try:
        credentials_path = Path("credentials/posthog.json")
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
        logging.info("PostHog initialized successfully")
        return True
    else:
        logging.warning("PostHog initialization failed - no API key found")
        return False

def track_script_event(event_name, start_time=None, end_time=None):
    """Track script events with PostHog."""
    try:
        properties = {
            'script_name': 'act_aio'
        }

        if start_time:
            properties['start_datetime'] = start_time.isoformat()
        if end_time:
            properties['end_datetime'] = end_time.isoformat()

        posthog.capture(
            distinct_id='anonymous',
            event=event_name,
            properties=properties
        )
        logging.info(f"Tracked event: {event_name}")
    except Exception as e:
        logging.error(f"Failed to track event {event_name}: {e}")

def main():
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

    start_time = datetime.now()
    logging.info(f"Script started at {start_time}")

    posthog_enabled = setup_posthog()

    if posthog_enabled:
        track_script_event('script_started', start_time=start_time)

    print("Hello from act-aio!")

    end_time = datetime.now()
    logging.info(f"Script ended at {end_time}")

    if posthog_enabled:
        track_script_event('script_ended', start_time=start_time, end_time=end_time)

if __name__ == "__main__":
    main()
