@echo off
setlocal
chcp 65001 >nul

set version=1.1

echo EZCab [version %version%]
echo.

set "switch=%~1"
if /i "%switch%"=="/c" goto :mkcab
if /i "%switch%"=="/s" goto :mkscript
if /i "%switch%"=="/x" goto :excab
if /i "%switch%"=="/l" goto :listcab
if /i "%switch%"=="/?" goto :help
if /i "%switch%"=="" goto :help

echo ERROR. Invalid switch: "%switch%" >&2
endlocal
exit /b 2

:help
echo Usage:
echo.
echo EZCAB /C [/T:{MSZIP^|LZX^|NONE}] source [output]
echo EZCAB /S [/T:{MSZIP^|LZX^|NONE}] [/L:launcher] [/G] [/H:title] source [output]
echo EZCAB /X file [extract]
echo EZCAB /L file
echo.
echo   /C        Compress a file or folder into a CAB archive.
echo   /S        Compress a file or folder into a Self-Extracting CMD script.
echo   /X        Extract the contents of a CAB archive or a self-extracting CMD.
echo   /L        List the contents of a CAB archive without extracting.
echo.
echo   /T:type   Compression types: "MSZIP" (default), "LZX" (better compression)
echo             or "NONE".
echo   /L:file   Entry-point script inside the bundle (default: "start.cmd").
echo   /G        Hide the console window (GUI mode).
echo   /H:text   Title of the console window.
echo.
echo   source    File or directory you want to compress.
echo   output    Path or name of the resulting CAB file.
echo   file      Path to the CAB archive you want to read or extract.
echo   extract   Destination folder for extracted files (defaults to current
echo             directory).
echo.
echo EZCAB /C /T:LZX "My File.txt" "My CAB"
echo EZCAB /C /T:LZX "My Folder\*" "My CAB"
echo EZCAB /S /T:LZX /L:"App Launcher.exe" /G /H:"My App" "App Src" "My Script"
echo EZCAB /X "My CAB.cab" "My Folder\New Files"
echo EZCAB /X "My Script.cmd" "Scripts Folder"
echo EZCAB /L "My CAB.cab"
echo EZCAB /L "My Script.cmd"

endlocal
exit /b 0

:mkcab
set type=MSZIP
set compress=ON
set "source=%~2"
set "output=%~3"

if /i "%~2"=="/t:mszip" (
    set type=MSZIP
    set "source=%~3"
    set "output=%~4"
    set valid=1
)
if /i "%~2"=="/t:lzx" (
    set type=LZX
    set "source=%~3"
    set "output=%~4"
    set valid=1
)
if /i "%~2"=="/t:none" (
    set compress=OFF
    set "source=%~3"
    set "output=%~4"
    set valid=1
)

set wildcard=
if "%source:~-2%"=="\*" set wildcard=1 & set "source=%source:~0,-2%"

if not exist "%source%" (
    echo ERROR. Not exist: "%source%" >&2
    endlocal
    exit /b 2
)

if exist "%source%\setup.inf" del /q "%source%\setup.inf"
if exist "%source%\setup.rpt" del /q "%source%\setup.rpt"

set "dest=%source%"
if "%dest:~-1%"=="\" set "dest=%dest:~0,-1%"

for %%a in ("%dest%") do set "filename=%%~nxa"

set "dest=%cd%\%filename%.cab"
if "%output%" neq "" (
    if exist "%output%\" (
        set "dest=%output%\%filename%.cab"
    ) else (
        for %%b in ("%output%") do (
            if /i "%%~xb"==".cab" (
                set "dest=%output%"
            ) else (
                set "dest=%cd%\%output%.cab"
            )
        )
    )
)
set "dest=%dest:\\=\%"

if not exist "%temp%\ezcab" mkdir "%temp%\ezcab"

for /f "delims=" %%i in ("%dest%") do set "drive=%%~di"
if %drive%==%systemdrive% set "drive=%temp%\ezcab"

set "tstamp=%time::=%"
set "tstamp=%tstamp:,=%"
set "tstamp=%tstamp: =%"
set tempcab=%tstamp%%random%%random%.cab
set ddf=%tstamp%%random%%random%.ddf

if exist "%source%\" (
    set ispath=true
    if defined wildcard (
        pushd "%source%"
    ) else (
        for %%a in ("%source%") do pushd "%%~dpa"
    )
) else (
    set ispath=false
    for %%a in ("%source%") do pushd "%%~dpa"
)

(
    echo .OPTION EXPLICIT
    echo .Set CabinetNameTemplate=%tempcab%
    echo .Set DiskDirectoryTemplate=%drive%\
    echo .Set CompressionType=%type%
    echo .Set Cabinet=ON
    echo .Set Compress=%compress%
    echo .Set MaxDiskSize=0

    if %ispath%==true (
        for /r %%f in (*) do (
            set "f=%%f"
            setlocal enabledelayedexpansion
            set "rel=!f:%cd%\=!"
            if defined wildcard (
                echo "!rel!" "!rel!"
            ) else (
                if not "!rel!"=="!rel:%filename%\=!" echo "!rel!" "!rel!"
            )
            endlocal
        )
    ) else (
        for %%a in ("%source%") do echo "%%~nxa" "%%~nxa"
    )
) > "%temp%\ezcab\%ddf%"

makecab /f "%temp%\ezcab\%ddf%"
if errorlevel 1 (
    del /q "setup.inf" "setup.rpt" 2>nul
    endlocal
    exit /b %errorlevel%
)

del /q "setup.inf" "setup.rpt" "%temp%\ezcab\%ddf%" 2>nul
popd

move /y "%drive%\%tempcab%" "%dest%" >nul

endlocal
exit /b 0

:mkscript
set type=MSZIP
set compress=ON
set "launcher=start.cmd"
set gui=false
set "title="

:parsemk
set "a=%~2"
set "a=%a:"=%"
if "%a%"=="" goto :parsemkd
if /i "%a%"=="/t:mszip" set type=MSZIP& shift& goto :parsemk
if /i "%a%"=="/t:lzx" set type=LZX& shift& goto :parsemk
if /i "%a%"=="/t:none" set compress=OFF& shift& goto :parsemk
if /i "%a:~0,3%"=="/l:" set "launcher=%a:~3%"& shift& goto :parsemk
if /i "%a%"=="/g" set gui=true& shift& goto :parsemk
if /i "%a:~0,3%"=="/h:" set "title=%a:~3%"& shift& goto :parsemk

:parsemkd
set "source=%~2"
set "output=%~3"

if not exist "%source%" (
    echo ERROR. Not exist: "%source%" >&2
    endlocal
    exit /b 2
)
if not exist "%source%\" (
    echo ERROR. Source must be a directory for /S. >&2
    endlocal
    exit /b 2
)

if exist "%source%\setup.inf" del /q "%source%\setup.inf"
if exist "%source%\setup.rpt" del /q "%source%\setup.rpt"

set "workdir=%temp%\ezcab-s"

if exist "%workdir%" rd /s /q "%workdir%"
md "%workdir%"

pushd "%source%"
(
    echo .OPTION EXPLICIT
    echo .Set CabinetNameTemplate=bundle.cab
    echo .Set DiskDirectoryTemplate="%workdir%"
    echo .Set CompressionType=%type%
    echo .Set Cabinet=ON
    echo .Set Compress=%compress%
    echo .Set MaxDiskSize=0

    for /r %%f in (*) do (
        set "f=%%f"
        setlocal enabledelayedexpansion
        echo "!f:%cd%\=!" "!f:%cd%\=!"
        endlocal
    )
) > "%workdir%\bundle.ddf"

makecab /f "%workdir%\bundle.ddf"
if errorlevel 1 (
    rd /s /q "%workdir%"
    endlocal
    exit /b %errorlevel%
)
popd

certutil -f -encode "%workdir%\bundle.cab" "%workdir%\bundle.b64" || (
    rd /s /q "%workdir%"
    endlocal
    exit /b
)

if "%output%"=="" (
    for %%s in ("%source%") do set "output=%%~nxs.cmd"
) else (
    for %%s in ("%output%") do (
        if /i not "%%~xs"==".cmd" set "output=%output%.cmd"
    )
)

(
    echo ::ezcab-%version%
    echo @echo off
    echo chcp 65001 ^>nul
    if not "%title%"=="" echo title %title%

    if %gui%==true (
        echo echo Starting %title%...
        echo :rh
        echo set "h=%%temp%%\%%random%%.vbs"
        echo if exist "%%h%%" goto :rh
        echo if "%%1" neq "__hide__" echo CreateObject^("Shell.Application"^).ShellExecute "%%~s0", "__hide__ %%*",,, 0 ^> %%h%% ^&^& call %%h%% ^& del /q %%h%% ^& exit /b
    )

    echo :rp
    echo set "p=%%temp%%\%%random%%"
    echo if exist "%%p%%" goto :rp

    echo md "%%p%%"
    echo pushd "%%p%%"

    echo certutil -decode "%%~f0" bundle.cab ^>nul

    echo expand bundle.cab -r -f:* . ^>nul

    echo del /q bundle.cab

    if %gui%==true (
        echo shift
        echo call "%%p%%\%launcher%" %%1 %%2 %%3 %%4 %%5 %%6 %%7 %%8 %%9
    ) else (
        echo call "%%p%%\%launcher%" %%*
    )
    echo set "el=%%errorlevel%%"

    echo :ce
    echo popd
    echo rd /s /q "%%p%%"
    echo exit /b %%el%%

    type "%workdir%\bundle.b64"
) > "%output%"

rd /s /q "%workdir%"
del /q "%source%\setup.inf" "%source%\setup.rpt" 2>nul

endlocal
exit /b 0

:excab
set "file=%~2"
set "extract=%~3"

if not exist "%file%" (
    echo ERROR. Not exist: "%file%" >&2
    endlocal
    exit /b 2
)

if "%extract%"=="" (set "dest=%cd%") else (set "dest=%extract%")
if not exist "%dest%" mkdir "%dest%"

findstr /b /c:"-----BEGIN CERTIFICATE-----" "%file%" >nul 2>&1
if errorlevel 1 goto :excab_direct

set "workdir=%temp%\ezcab-ex"
if exist "%workdir%" rd /s /q "%workdir%"
md "%workdir%"

certutil -decode "%file%" "%workdir%\bundle.cab"
if errorlevel 1 (
    rd /s /q "%workdir%"
    echo ERROR. Failed to decode embedded CAB. >&2
    endlocal
    exit /b 2
)

expand "%workdir%\bundle.cab" /r /f:* "%dest%"
if errorlevel 1 (
    rd /s /q "%workdir%"
    endlocal
    exit /b 2
)

rd /s /q "%workdir%"
endlocal
exit /b 0

:excab_direct
expand "%file%" /r /f:* "%dest%"
if errorlevel 1 (
    endlocal
    exit /b %errorlevel%
)

endlocal
exit /b 0

:listcab
set "file=%~2"

if not exist "%file%" (
    echo ERROR. Not exist: "%file%" >&2
    endlocal
    exit /b 2
)

findstr /b /c:"::ezcab-" "%file%" >nul 2>&1
if errorlevel 1 goto :listcab_direct

set "workdir=%temp%\ezcab-ls"

if exist "%workdir%" rd /s /q "%workdir%"
md "%workdir%"

call set "cabpath=%%file:%~nx2=%%"
set "cabpath=%cabpath::=%"

if exist "%workdir%\%cabpath%" rd /s /q "%workdir%\%cabpath%"
md "%workdir%\%cabpath%"

for %%a in ("%file%") do set "cabfile=%%~nxa"

certutil -decode "%file%" "%workdir%\%cabpath%\%cabfile%" 2>&1
if errorlevel 1 (
    rd /s /q "%workdir%"
    echo ERROR. Failed to decode embedded CAB. >&2
    endlocal
    exit /b 2
)

pushd "%workdir%"
expand "%cabpath%%cabfile%" /d
popd
rd /s /q "%workdir%"
endlocal
exit /b 0

:listcab_direct
expand "%file%" /d
if errorlevel 1 (
    endlocal
    exit /b %errorlevel%
)

endlocal
exit /b 0