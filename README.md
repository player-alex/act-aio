# 🚀 Act-AIO

A modern, extensible plugin management system built with Python and Qt6. Act-AIO provides a sleek GUI for discovering, managing, and launching Python-based plugins with isolated virtual environments.

## ✨ Features

- 🔌 **Plugin System**: Automatic plugin discovery from the `plugins/` directory using `pyproject.toml` metadata
- 📦 **Isolated Environments**: Each plugin runs in its own UV-managed virtual environment with independent dependencies
- 🎨 **Modern UI**: Clean, responsive interface built with Qt Quick/QML featuring Catppuccin color scheme
- 🔍 **Search & Filter**: Real-time plugin search by name, description, tags, or version
- ⚙️ **Environment Management**: Support for `.env` files with variable substitution and proxy configuration
- 🔒 **Privacy-Focused Analytics**: Optional PostHog integration with hardware-based UUID (no personal data)
- 📦 **Distribution Tools**: Built-in script for creating distributable packages with optional 7z compression and encryption

## 📋 Requirements

- 🐍 Python 3.13 or higher
- 💻 Windows (primary support), Linux/macOS (experimental)
- ⚡ UV package manager (recommended) or pip

## 📥 Installation

### Using UV (Recommended) ⚡

```bash
# Clone the repository
git clone https://github.com/yourusername/act-aio.git
cd act-aio

# Install dependencies
uv sync

# Run the application
uv run python -m act_aio.main
```

### Using pip 🐍

```bash
# Clone the repository
git clone https://github.com/yourusername/act-aio.git
cd act-aio

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -e .

# Run the application
python -m act_aio.main
```

## 🎯 Usage

### Launching the Application 🚀

```bash
# With UV
uv run python -m act_aio.main

# With activated virtual environment
python -m act_aio.main
```

### Managing Plugins 🔌

1. **Installing Plugins**: Place plugin directories in the `plugins/` folder
2. **Plugin Requirements**: Each plugin must have a `pyproject.toml` file with metadata
3. **Import/Export Plugins**: Use the top-left button to import or export plugins 📥📤
4. **Running Plugins**: Click on a plugin in the list and press the "Run" button ▶️
5. **Environment Variables**: Click the settings button on the right, then select "Environment Variables" to specify custom environment variables for plugin execution ⚙️
6. **Viewing Documentation**: Click the "?" button to view plugin manuals (if available) 📖
7. **Opening Plugin Directory**: Click the folder icon to open the plugin's directory 📁

### Environment Variables ⚙️

Create a `.env` file in the root directory to set environment variables:

```env
HTTP_PROXY=http://proxy.example.com:8080
HTTPS_PROXY=http://proxy.example.com:8080
SOME_API_KEY=your_api_key_here
```

Variables support substitution using `${VARIABLE_NAME}` syntax.

### Proxy Configuration 🌐

For network-restricted environments, configure proxy settings in `.env`:

```env
HTTP_PROXY=http://your-proxy:port
HTTPS_PROXY=http://your-proxy:port
```

The application will use these proxy settings for UV package installations.

**Important Notes for Plugin Developers:**
- UV respects the standard `HTTP_PROXY` and `HTTPS_PROXY` environment variables during dependency installation
- To disable proxy for specific operations in your plugin, set:
  ```python
  os.environ["HTTP_PROXY"] = ""
  os.environ["HTTPS_PROXY"] = ""
  ```
- Remember to restore the original values if needed after disabling

## 📁 Project Structure

```
act-aio/
├── act_aio/
│   ├── main.py              # Application entry point
│   ├── plugin_manager.py    # Core plugin management logic
│   ├── models.py            # QML data models
│   └── qml/
│       ├── main.qml         # Main application UI
│       └── PluginListItem.qml  # Plugin list item component
├── plugins/                 # Plugin directory
├── fonts/                   # Application fonts (Roboto)
├── credentials/             # Credential storage (gitignored)
├── create-distribution.py   # Distribution package creator
├── pyproject.toml          # Project dependencies and metadata
└── README.md               # This file
```

## 🛠️ Plugin Development

### Plugin Structure 📦

Each plugin should follow this structure:

```
your-plugin/
├── pyproject.toml          # Required: Plugin metadata
├── main.py                 # Required: Plugin entry point
├── manuals/                # Optional: Manual/documentation files
│   ├── user-guide.md
│   └── api-reference.md
├── README.md               # Optional: Plugin documentation
└── requirements.txt        # Optional: Dependencies (or use pyproject.toml)
```

### Creating Plugin Manuals 📖

To add documentation to your plugin:

1. Create a `manuals/` directory inside your plugin folder
2. Add markdown files (`.md`) with your documentation
3. Reference these files in your `pyproject.toml`:

```toml
[project.optional-metadata]
manuals = ["manuals/user-guide.md", "manuals/api-reference.md"]
```

The manual files will be accessible via the "?" button in the plugin list.

### Example pyproject.toml 📄

```toml
[project]
name = "your-plugin"
version = "1.0.0"
description = "A sample plugin for Act-AIO"

[project.optional-metadata]
tags = ["utility", "example"]
manuals = ["manuals/user-guide.md", "manuals/api-reference.md"]
```

### Plugin Entry Point ▶️

The `main.py` file should contain your plugin's main logic:

```python
def main():
    print("Hello from your plugin!")

if __name__ == "__main__":
    main()
```

## 📦 Creating Distribution Packages

Use the included `create-distribution.py` script to create distributable packages:

```bash
python create-distribution.py
```

The script will:
1. ✅ Create a `dist/` directory with files based on `.dist.rules`
2. 🗜️ Optionally compress to a 7z archive
3. 🔐 Optionally encrypt with AES-256 and filename encryption

### Distribution Rules 📋

Edit `.dist.rules` to customize what gets included in distributions:

```
INCLUDE:
act_aio/
plugins/
fonts/
README.md

EXCLUDE_NAMES:
__pycache__
.git

EXCLUDE_PREFIXES:
.

EXCLUDE_SUFFIXES:
.pyc
.log
```

## 🔒 Analytics & Privacy

Act-AIO uses PostHog for optional usage analytics:

- 🆔 **Hardware UUID**: Generated from CPU/motherboard information (no personal data)
- 🚫 **Opt-out**: Set `POSTHOG_DEBUG=1` environment variable to disable
- 📊 **Data Collected**: Plugin launches, application starts (anonymous)

## 💻 Development

### Running in Debug Mode 🐛

```bash
# Enable PostHog debug mode
POSTHOG_DEBUG=1 uv run python -m act_aio.main
```

### Code Style 📝

- 🐍 **Python**: Follow PEP 8
- 🎨 **QML**: Use Qt Quick best practices
- 🔤 **Type hints**: Encouraged for Python code

## 📚 Dependencies

- **PySide6**: Qt6 Python bindings for GUI
- **py7zr**: 7z archive creation with encryption support
- **posthog**: Analytics library
- **tomli**: TOML parsing (Python < 3.11)
- **UV**: Fast Python package installer

## ⚠️ Troubleshooting

### Application won't start 🚫
- ✅ Ensure Python 3.13+ is installed
- ✅ Check that all dependencies are installed: `uv sync`
- ✅ Try running with debug mode: `POSTHOG_DEBUG=1 uv run python -m act_aio.main`

### Plugin won't launch ❌
- ✅ Verify plugin has `main.py` file
- ✅ Check plugin's `pyproject.toml` is valid
- ✅ Look for error messages in the console

### Proxy issues 🌐
- ✅ Verify `HTTP_PROXY` and `HTTPS_PROXY` in `.env` are correct
- ✅ Check proxy allows HTTPS connections
- ✅ Try running without proxy temporarily (set to empty string "")

## 📄 License

[Your License Here]

## 🙏 Acknowledgments

- **Catppuccin** 🎨: Color scheme for the UI
- **Roboto** ✍️: Font family by Google
- **Qt Project** 🖥️: Qt framework
- **Astral** ⚡: UV package manager
