<div align="center">

# 🚀 Act-AIO

![Python](https://img.shields.io/badge/Python-3.13+-3776AB?logo=python&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-0078D6)
![Qt](https://img.shields.io/badge/Qt-6-41CD52?logo=qt&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**A modern, extensible plugin management system built with Python and Qt6** 🚀

</div>

---

## ✨ Features

- 🔌 **Plugin System** - Automatic plugin discovery from the `plugins/` directory using `pyproject.toml` metadata
- 📦 **Isolated Environments** - Each plugin runs in its own UV-managed virtual environment with independent dependencies
- 🎨 **Modern UI** - Clean, responsive interface built with Qt Quick/QML featuring Catppuccin color scheme
- 🔍 **Search & Filter** - Real-time plugin search by name, description, tags, or version
- ⚙️ **Environment Management** - Support for `.env` files with variable substitution and proxy configuration
- 🎯 **Font Size Customization** - Adjustable font size (1.0x - 2.0x) for plugin descriptions and tags in the UI
- 🔒 **Privacy-Focused Analytics** - Optional PostHog integration with hardware-based UUID (no personal data)
- 📦 **Distribution Tools** - Built-in script for creating distributable packages with optional 7z compression and encryption

## 📋 Requirements

- 🐍 **Python 3.13 or higher**
- 💻 **Windows** (primary support), Linux/macOS (experimental)
- ⚡ **UV package manager (required)** - [Download](https://docs.astral.sh/uv/getting-started/installation/)

## 📥 Installation

### Option 1: Automated Installation (Windows) 🪟

For Windows users, Act-AIO includes pre-packaged binaries for offline installation:

```bash
# Clone the repository
git clone https://github.com/player-alex/act-aio.git
cd act-aio

# Run the automated installer
install.bat
```

This will automatically install:
- UV package manager (from `installation/binaries/`)
- Python 3.13.7 (from `mirror/`)

### Option 2: Manual Installation ⚡

If you don't have UV installed, install it first:

**Windows (PowerShell):**
```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**Linux/macOS:**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Then install Act-AIO:

```bash
# Clone the repository
git clone https://github.com/player-alex/act-aio.git
cd act-aio

# Install dependencies
uv sync

# Run the application
uv run python -m act_aio.main
```

## 🎯 Usage

### Launching the Application 🚀

```bash
uv run python -m act_aio.main
```

### Managing Plugins 🔌

1. **Installing Plugins**: Place plugin directories in the `plugins/` folder
2. **Plugin Requirements**: Each plugin must have a `pyproject.toml` file with metadata
3. **Import/Export Plugins**: Use the top-left button to import or export plugins 📥📤
4. **Running Plugins**: Click on a plugin in the list and press the "Run" button ▶️
5. **Environment Variables**: Click the settings button on the right, then select "Environment Variables" to specify custom environment variables for plugin execution ⚙️
6. **Font Size Adjustment**: In the settings dialog, use the "Font Size" slider to adjust the font size for plugin descriptions and tags (1.0x - 2.0x) 🎯
7. **Viewing Documentation**: Click the "?" button to view plugin manuals (if available) 📖
8. **Opening Plugin Directory**: Click the folder icon to open the plugin's directory 📁

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
  import os
  os.environ["HTTP_PROXY"] = ""
  os.environ["HTTPS_PROXY"] = ""
  ```
- Remember to restore the original values if needed after disabling

## ⚙️ Configuration

The main application can be configured via the `pyproject.toml` file in the root directory and `settings.json` for user preferences.

### Application Title

You can customize the application's main window title by setting the `title` property in the `[project]` section of `pyproject.toml`.

**Example:**
```toml
[project]
name = "act-aio"
version = "0.1.0"
description = "Actions All-In-One - Python Plugin Launcher"
title = "My Custom App Title" # This will be the window title
```

If the `title` property is not set, the application will use a default title.

### User Settings 🎯

User preferences are automatically saved to `settings.json` in the root directory:

- **Font Size**: Adjustable font size multiplier for plugin descriptions and tags (1.0x - 2.0x)
- **Environment Settings**: Enabled/disabled state of environment variables from `.env`
- **Proxy Configuration**: HTTP/HTTPS proxy settings

**Example `settings.json`:**
```json
{
  "proxy": "http://proxy.example.com:8080",
  "environment_settings": {
    "API_KEY": true,
    "DEBUG_MODE": false
  },
  "font_size": 1.25
}
```

**Note:** The `font_size` value is validated on load. Invalid values (non-numeric, out of range, NaN) will automatically default to 1.0.

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

Follow these steps to create a new plugin:

### Step 1: Create Plugin Directory 📁

```bash
cd plugins
mkdir your-plugin-name
cd your-plugin-name
```

### Step 2: Initialize with UV ⚡

```bash
uv init
```

This creates a basic `pyproject.toml` and project structure.

### Step 3: Configure Required Metadata 📝

Edit `pyproject.toml` and set the required fields:

```toml
[project]
name = "your-plugin-name"           # Required: Plugin name
version = "1.0.0"                   # Required: Version
description = "Your plugin description"  # Required: Description
```

### Step 4: Set a User-Friendly Alias (Optional) 💬

The `name` in `pyproject.toml` must follow strict packaging rules (e.g., using hyphens, no special characters). To display a more readable or creative name in the UI, you can add an `alias`.

If an `alias` is provided, it will be used throughout the application's UI. If not, the `name` will be used as a fallback.

```toml
[project]
name = "my-super-cool-plugin"
version = "1.0.0"
description = "A plugin with a simple name."
alias = "My Super Cool Plugin ✨" # Optional: A user-friendly display name
```

### Step 5: Add Optional Metadata (Tags) 🏷️

Add optional tags to categorize your plugin in the `[project]` section:

```toml
[project]
name = "your-plugin-name"
version = "1.0.0"
description = "Your plugin description"
tags = ["utility", "automation", "example"]  # Optional: Category tags
```

**Available Options:**
- **tags**: Array of strings to categorize your plugin (e.g., "utility", "data-processing", "automation")

### Step 6: Create Plugin Manuals (Optional) 📖

To add documentation accessible via the "?" button:

1. Create a `manuals/` directory inside your plugin folder:
   ```bash
   mkdir manuals
   ```

2. Add documentation files of any format:
   ```bash
   # Example files:
   # manuals/user-guide.md
   # manuals/api-reference.txt
   # manuals/tutorial.pdf
   # manuals/config-example.json
   ```

**Note:** Act-AIO automatically detects **all files** in the `manuals/` directory, regardless of format (`.md`, `.txt`, `.pdf`, `.json`, etc.). You don't need to list them in `pyproject.toml`. The manual files will be accessible via the "?" button in the plugin list.

### Step 7: Custom Execution Command (Optional) ⚙️

By default, Act-AIO launches plugins using `uv run main.py`. However, you can define a custom execution command in `pyproject.toml` using the `exec` field under the `[project]` section.

**Simple Cross-Platform Command:**
```toml
[project]
name = "my-plugin"
version = "1.0.0"
exec = "python custom_launcher.py"
```

**Platform-Specific Commands:**
```toml
[project]
name = "my-plugin"
version = "1.0.0"
exec = { win32 = "cmd /c custom.bat", posix = "./custom.sh" }
```

**Features:**
- ✨ **Macro Substitution**: Use macros like `${PLUGIN_DIR}`, `${ENV:VAR_NAME}` in your commands
- 🔄 **Automatic Fallback**: If `exec` is not defined or no platform-specific command is found, defaults to `uv run main.py`
- 🌐 **Environment Variables**: All configured environment variables are passed to custom commands
- ⚠️ **Error Handling**: On Windows, the console pauses on errors automatically

**Example with Macros:**
```toml
[project]
name = "my-plugin"
exec = "python ${PLUGIN_DIR}/scripts/launcher.py --env ${ENV:MY_VAR}"
```

### Complete Example 📄

```toml
[project]
name = "my-awesome-plugin"
alias = "My Awesome Plugin"
version = "1.0.0"
description = "An awesome plugin for Act-AIO"
requires-python = ">=3.13"
tags = ["utility", "web", "automation"]
dependencies = [
    "requests>=2.31.0",
]
# Optional: Custom execution command
exec = "python custom_launcher.py"
```

### Plugin Entry Point ▶️

Create `main.py` with your plugin's main logic:

```python
def main():
    print("Hello from your plugin!")

if __name__ == "__main__":
    main()
```

### Final Plugin Structure 📦

```
your-plugin/
├── pyproject.toml          # Required: Plugin metadata
├── main.py                 # Required: Plugin entry point
├── manuals/                # Optional: Documentation files
│   ├── user-guide.md
│   └── api-reference.md
└── .venv/                  # Auto-created by Act-AIO
```

### Command Snippets (Optional) ⚡

Plugins can include command snippets, which are simple scripts that can be executed from the UI. They are defined in `.yaml` files located in a `snippets/commands` directory within your plugin.

**Directory Structure:**
```
your-plugin/
└── snippets/
    └── commands/
        └── my-command.yaml
```

**Snippet Format:**

Each `.yaml` file must contain `name`, `description`, and `command`.

```yaml
# my-command.yaml
name: Open Downloads Folder
description: Opens the user's Downloads folder in the explorer.
command: start explorer "${ENV:USERPROFILE}\Downloads"
```

**Macros:**

You can use macros to make commands more flexible:
- `${PLUGIN_DIR}`: The root directory of the plugin.
- `${CURRENT_DIR}`: The directory containing the snippet file (`.../snippets/commands`).
- `${ENV:VAR_NAME}`: The value of an environment variable.

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

## 🔧 Technologies Used

| Technology | Purpose | Version |
|------------|---------|---------|
| [Python](https://www.python.org/) | Core language | 3.13+ |
| [Qt6/PySide6](https://doc.qt.io/qtforpython-6/) | GUI framework | - |
| [UV](https://docs.astral.sh/uv/) | Package manager | - |
| [py7zr](https://py7zr.readthedocs.io/) | Archive creation | - |
| [PostHog](https://posthog.com/) | Analytics | - |

## 📚 Dependencies

- **PySide6**: Qt6 Python bindings for GUI
- **py7zr**: 7z archive creation with encryption support
- **posthog**: Analytics library
- **tomli**: TOML parsing (Python < 3.11)
- **UV**: Fast Python package installer

## ⚠️ Troubleshooting

<details>
<summary><b>🚫 Application won't start</b></summary>

- ✅ Ensure Python 3.13+ is installed
- ✅ Check that all dependencies are installed: `uv sync`
- ✅ Verify `.env` file exists (or create an empty one if needed)
- ✅ Try running with debug mode: `POSTHOG_DEBUG=1 uv run python -m act_aio.main`

</details>

<details>
<summary><b>❌ Plugin won't launch</b></summary>

- ✅ Verify plugin has `main.py` file
- ✅ Check plugin's `pyproject.toml` is valid
- ✅ Look for error messages in the console

</details>

<details>
<summary><b>🌐 Proxy issues</b></summary>

- ✅ Verify `HTTP_PROXY` and `HTTPS_PROXY` in `.env` are correct
- ✅ Check proxy allows HTTPS connections
- ✅ Try running without proxy temporarily (set to empty string "")

</details>

## 🐛 Known Issues

- **PySide6 `6.10.0`**: There is a known bug in this version that may cause unexpected behavior on Windows 11 (x64). If you encounter UI-related problems, consider using a different version. (Reported: 2025-10-16)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
