@echo off
echo Launching 3 instances for multiplayer testing...

REM Update this path to your Godot executable
set GODOT_PATH=C:\Users\benja\Desktop\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe

REM Launch 3 instances with 1 second delay between each
start "Game Instance 1" "%GODOT_PATH%" --path "%CD%"
timeout /t 1 /nobreak >nul

start "Game Instance 2" "%GODOT_PATH%" --path "%CD%"
timeout /t 1 /nobreak >nul

start "Game Instance 3" "%GODOT_PATH%" --path "%CD%"

echo All instances launched!
echo.
echo Instructions:
echo 1. Instance 1: Click Multiplayer -^> Host Game
echo 2. Instance 2-3: Click Multiplayer -^> Join Game (127.0.0.1)
echo 3. Instance 1: Click Start Game when 3/3 players
echo.
pause
