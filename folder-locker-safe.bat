@echo off
:: folder-locker-safe.bat
:: Prevents deletion while locked by applying a delete-deny ACL.
:: NOTE: This is not encryption. Admins can bypass. Run as Administrator for best results.

setlocal
set "FOLDER=Private"
set "LOCKNAME=Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}"
set "PASSWORD=YourPasswordHere"

:: Resolve full absolute path for clarity
for %%I in ("%FOLDER%") do set "FULLPATH=%%~fI"
for %%I in ("%LOCKNAME%") do set "LOCKFULL=%%~fI"

if not exist "%FULLPATH%" (
    mkdir "%FULLPATH%"
    echo Created "%FULLPATH%". Put files inside then run script again.
    pause
    exit /b
)

:MENU
cls
echo ===========================
echo   Folder Locker (SAFE-ish)
echo ===========================
echo 1) Lock folder
echo 2) Unlock folder
echo 3) Exit
echo.
set /p choice=Choose 1-3: 

if "%choice%"=="1" goto LOCK
if "%choice%"=="2" goto UNLOCK
if "%choice%"=="3" goto END
goto MENU

:LOCK
cls
echo Locking "%FULLPATH%"...
rem -- make hidden & system
attrib +h +s "%FULLPATH%"

rem -- rename to lock name (use full path for safety)
ren "%FULLPATH%" "%LOCKNAME%"

rem -- Apply delete-deny ACL to the locked folder object
echo Applying deny-delete ACL (prevents deletion by normal users)...
icacls "%~dp0%LOCKNAME%" /deny Everyone:(DE) >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Delete denied for Everyone on locked folder.
) else (
    echo Warning: could not set ACL. Try running this script as Administrator.
)

echo Folder locked. To unlock you must provide the correct password.
pause
goto MENU

:UNLOCK
cls
set /p "USERPASS=Enter password to unlock: "
if "%USERPASS%"=="%PASSWORD%" (
    echo Correct password.
    rem -- remove deny ACL from the locked folder before renaming back
    echo Removing deny-delete ACL...
    icacls "%~dp0%LOCKNAME%" /remove:d Everyone >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo Delete-deny ACL removed.
    ) else (
        echo Warning: could not remove ACL. Try running this script as Administrator.
    )

    rem -- rename back and remove hidden/system attributes
    ren "%~dp0%LOCKNAME%" "%FOLDER%"
    attrib -h -s "%FULLPATH%" 2>nul
    echo Folder unlocked.
) else (
    echo Incorrect password. Folder remains locked and deletion will be prevented.
)
pause
goto MENU

:END
endlocal
exit /b
