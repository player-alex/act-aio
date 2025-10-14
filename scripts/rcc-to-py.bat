@echo off
cd %~dp0../
uv run pyside6-rcc ./act_aio/resources.qrc -o ./act_aio/qml_qrc.py