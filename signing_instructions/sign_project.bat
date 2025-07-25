@echo off
setlocal enabledelayedexpansion
pushd "%~dp0\..\"

:: --- Find signtool.exe ---
echo Searching for signtool.exe...
set "SIGNTOOL_PATH="
for /f "delims=" %%i in ('where /r "C:\Program Files (x86)\Windows Kits" signtool.exe') do (
    if not defined SIGNTOOL_PATH (
        set "SIGNTOOL_PATH=%%i"
    )
)

if not defined SIGNTOOL_PATH (
    echo.
    echo ERROR: Could not find signtool.exe automatically.
    echo Please ensure the Windows SDK is installed.
    echo.
    pause
    goto :eof
)

echo Found signtool.exe at: %SIGNTOOL_PATH%
echo.
pause
cls

:main_menu
cls
echo =========================================
echo      Project Signing Utility
echo =========================================
echo.
echo 1. Create a new signing certificate
echo 2. Sign an executable
echo Q. Quit
echo.
set /p "menu_choice=Enter your choice: "

if /i "%menu_choice%"=="1" goto :create_certificate
if /i "%menu_choice%"=="2" goto :sign_executable
if /i "%menu_choice%"=="q" goto :eof

echo Invalid choice.
pause
goto :main_menu


:create_certificate
cls
echo =========================================
echo      Create New Signing Certificate
echo =========================================
echo.
set /p "CN=Enter Common Name (CN) - the name of the signer: "
set /p "O=Enter Organization (O) - the name of your organization: "
set /p "OU=Enter Organizational Unit (OU) - e.g., Development, Production: "
echo.
cls
echo You have entered the following details:
echo.
echo   Common Name (CN): %CN%
echo   Organization (O): %O%
echo   Organizational Unit (OU): %OU%
echo.
set /p "confirm=Is this correct? (Y/n): "
if /i not "%confirm%"=="y" goto :create_certificate

set "subject=CN=%CN%,O=%O%,OU=%OU%"
set "friendly_name=%CN% Signing Certificate"

echo.
echo Creating certificate...
powershell -command "New-SelfSignedCertificate -Type Custom -Subject \"%subject%\" -KeyUsage DigitalSignature -FriendlyName \"%friendly_name%\" -CertStoreLocation \"Cert:\CurrentUser\My\" -NotAfter (Get-Date).AddYears(5)"

if %errorlevel% equ 0 (
    echo.
    echo Certificate created successfully.
) else (
    echo.
    echo ERROR: Certificate creation failed.
)
echo.
pause
goto :main_menu


:sign_executable
cls
echo =========================================
echo      Sign an Executable
echo =========================================
echo.
echo Searching for executables in Output...
echo.

set "exe_count=0"
for %%f in (Output\*.exe) do (
    set /a exe_count+=1
    echo !exe_count!. %%~nxf
    set "exe_!exe_count!=%%f"
)

if %exe_count% equ 0 (
    echo No executables found in the ../Output directory.
    pause
    goto :main_menu
)

echo.
set /p "exe_choice=Select an executable to sign: "
if %exe_choice% gtr %exe_count% (
    echo Invalid selection.
    pause
    goto :sign_executable
)
if %exe_choice% lss 1 (
    echo Invalid selection.
    pause
    goto :sign_executable
)

call set "selected_exe=%%exe_%exe_choice%%%"

cls
echo =========================================
echo      Verifying Existing Signature
echo =========================================
echo.
echo Verifying %selected_exe%...
echo.
set "signed_by=Not Found"
set "sha1_hash=Not Found"
set "signed_on=No timestamp found."
set "signature_found=false"

"%SIGNTOOL_PATH%" verify /v /pa "%selected_exe%" > "%temp%\signtool.log" 2>&1

for /f "usebackq delims=" %%i in ("%temp%\signtool.log") do (
    set "line=%%i"
    if not "!signature_found!"=="true" (
        echo !line! | findstr /b /c:"    Issued to:" > nul
        if not errorlevel 1 (
            for /f "tokens=3,*" %%a in ("!line!") do set "signed_by=%%a %%b"
        )
        echo !line! | findstr /b /c:"    SHA1 hash:" > nul
        if not errorlevel 1 (
            for /f "tokens=3" %%a in ("!line!") do set "sha1_hash=%%a"
            set "signature_found=true"
        )
    )
    echo !line! | findstr /b /c:"The signature is timestamped:" > nul
    if not errorlevel 1 (
        for /f "tokens=1,* delims=:" %%a in ("!line!") do (
            set "ts=%%b"
            set "signed_on=!ts:~1!"
        )
    )
)

if exist "%temp%\signtool.log" del "%temp%\signtool.log"

if not "%signed_by%"=="Not Found" (
    echo    Signed By: %signed_by%
    echo    SHA1 Hash: %sha1_hash%
    echo    Signed On: %signed_on%
) else (
    echo    No signature found.
)
echo.
echo --- End of Verification ---
echo.
pause
cls
echo =========================================
echo      Select a Certificate
echo =========================================
echo.
echo Searching for available certificates...
echo.

set "cert_count=0"
for /f "tokens=1,* delims=" %%a in ('powershell -command "Get-ChildItem Cert:\CurrentUser\My | ForEach-Object { $_.Subject + ' | ' + $_.Thumbprint }"') do (
    set /a cert_count+=1
    echo !cert_count!. %%a
    set "cert_!cert_count!=%%b"
)

if %cert_count% equ 0 (
    echo No certificates found in your personal store.
    echo Please create a certificate first.
    pause
    goto :main_menu
)

echo.
set /p "cert_choice=Select a certificate to use for signing: "
if %cert_choice% gtr %cert_count% (
    echo Invalid selection.
    pause
    goto :sign_executable
)
if %cert_choice% lss 1 (
    echo Invalid selection.
    pause
    goto :sign_executable
)

for /f "delims=" %%i in ('powershell -command "(Get-ChildItem Cert:\CurrentUser\My)[%cert_choice% - 1].Thumbprint"') do set "selected_cert_thumbprint=%%i"


cls
echo =========================================
echo      Confirm Signing Operation
echo =========================================
echo.
echo   Executable: %selected_exe%
echo   Certificate Thumbprint: %selected_cert_thumbprint%
echo.
set /p "confirm_sign=Proceed with signing? (Y/n): "
if /i not "%confirm_sign%"=="y" goto :main_menu

echo.
echo Signing executable...
"%SIGNTOOL_PATH%" sign /as /v /fd SHA256 /td SHA256 /tr http://timestamp.sectigo.com /sha1 %selected_cert_thumbprint% "%selected_exe%"

if %errorlevel% equ 0 (
    echo.
    echo Executable signed successfully.
) else (
    echo.
    echo ERROR: Signing failed.
)
echo.
pause
goto :main_menu

:eof
popd
