@echo off
cd %~dp0../
rmdir .\act_aio\__pycache__ /s /q
uv run pyside6-rcc ./act_aio/resources.qrc -o ./act_aio/qml_qrc.py