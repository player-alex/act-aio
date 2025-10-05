"""Global tracking context for PostHog analytics."""


class TrackingContext:
    """Singleton class to store global tracking context."""

    _instance = None
    _session_id = None
    _hardware_uuid = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def set_context(self, session_id: str, hardware_uuid: str):
        """Set the tracking context."""
        self._session_id = session_id
        self._hardware_uuid = hardware_uuid

    def get_session_id(self) -> str:
        """Get the current session ID."""
        return self._session_id

    def get_hardware_uuid(self) -> str:
        """Get the current hardware UUID."""
        return self._hardware_uuid

    def get_context(self) -> dict:
        """Get the full tracking context."""
        return {
            'session_id': self._session_id,
            'hardware_uuid': self._hardware_uuid
        }


# Global instance
tracking_context = TrackingContext()