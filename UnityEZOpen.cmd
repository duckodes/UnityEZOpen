@echo off
setlocal enabledelayedexpansion

REM ======== Unity Editor ���| ========
set "unityExe=C:\Program Files\Unity\Hub\Editor\2022.3.44f1\Editor\Unity.exe"

REM ======== Ū���M�ײM�� ========
set project_count=0
set "projects_file=%~dp0Setup.txt"

if not exist "%projects_file%" (
    echo ���~�G�䤣��M�ײM���ɮ� "%projects_file%"
    pause
    exit /b
)

echo.
echo [37;40m===== Unity �M�ײM�� =====[0m
echo.

for /f "tokens=1,2 delims=|" %%A in (%projects_file%) do (
    set /a project_count+=1
    set "project!project_count!_name=%%A"
    set "project!project_count!_path=%%B"

    rem ���o git ����
    set "branch=��������"
    for /f %%B in ('cmd /v:on /c "git -C %%B rev-parse --abbrev-ref HEAD"') do (
        set "branch=%%B"
    )
    if "!branch!"=="��������" (
        set "branch=�L�k���o����]�T�{���|�P Git �M�ס^"
    )
    set "branch!project_count!=!branch!"

    rem ���o Unity ����
    set "unity_version=��������"
    set "version_file=%%B\ProjectSettings\ProjectVersion.txt"
    if exist "!version_file!" (
        for /f "tokens=2 delims=: " %%D in ('findstr "m_EditorVersion" "!version_file!"') do (
            set "unity_version=%%D"
        )
    )
    set "version!project_count!=!unity_version!"

    rem ���o bundleVersion
    set "bundle_version=��������"
    set "player_file=%%B\ProjectSettings\ProjectSettings.asset"
    if exist "!player_file!" (
        for /f "tokens=2 delims=: " %%E in ('findstr "bundleVersion:" "!player_file!"') do (
            set "bundle_version=%%E"
        )
    )
    set "bundleVersion!project_count!=!bundle_version!"

    echo !project_count!. %%A
    echo    unity�����G !unity_version!
    echo    bundleVersion�G !bundle_version!
    echo    [38;2;0;255;255mgit����G !branch![0m
    echo.
)

set /p choice=�п�J�s���ë� Enter�G

REM ======== ���� Unity �M�� ========
for /L %%i in (1,1,%project_count%) do (
    if "!choice!"=="%%i" (
        start "" "%unityExe%" -projectPath "!project%%i_path!"
	if exist "!project%%i_path!\Unity.sln" (
	    start "" "!project%%i_path!\Unity.sln"
	)
        exit /b
    )
)

echo �L�Ī���ܡI
pause
exit /b