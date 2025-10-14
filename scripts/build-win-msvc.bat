@echo off
cd %~dp0../
uv run nuitka --standalone --onefile --msvc=latest --output-dir=./build/win-msvc/ --plugin-enable=pyside6 --include-qt-plugins=qml --windows-console-mode=disable --output-filename="ActAio" ./main.py
pause