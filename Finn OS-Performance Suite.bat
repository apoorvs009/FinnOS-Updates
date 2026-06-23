@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
powershell -Command "Start-Process '%~f0' -Verb RunAs"
exit
)

title FINN OS - Performance Suite
chcp 65001 >nul
color 0B
mode con: cols=140 lines=45

:: FINN OS VERSION
set CURRENT_VERSION=1.0.5

:: CHECK FOR UPDATES
call :CheckForUpdates

:home
cls
set POWERPLAN=Unknown

for /f "tokens=*" %%a in ('powercfg /getactivescheme') do set POWERLINE=%%a

echo %POWERLINE% | find /i "Atlas" >nul && set POWERPLAN=Atlas
echo %POWERLINE% | find /i "Ultimate" >nul && set POWERPLAN=Ultimate
echo %POWERLINE% | find /i "High performance" >nul && set POWERPLAN=High Performance
echo %POWERLINE% | find /i "Balanced" >nul && set POWERPLAN=Balanced
set GAMEMODE=Unknown

reg query "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled >nul 2>&1

if %errorlevel%==0 (
for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled ^| find "AutoGameModeEnabled"') do (
if "%%a"=="0x1" set GAMEMODE=Enabled
if "%%a"=="0x0" set GAMEMODE=Disabled
)
)
set HAGS=Unknown

for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode 2^>nul ^| find "HwSchMode"') do (
if "%%a"=="0x2" set HAGS=Enabled
if "%%a"=="0x1" set HAGS=Disabled
)
set MEMORYINTEGRITY=Unknown

for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2^>nul ^| find "Enabled"') do (
if "%%a"=="0x1" set MEMORYINTEGRITY=Enabled
if "%%a"=="0x0" set MEMORYINTEGRITY=Disabled
)
set SCORE=0

if /i "%GAMEMODE%"=="Enabled" set /a SCORE+=25
if /i "%HAGS%"=="Enabled" set /a SCORE+=25
if /i "%MEMORYINTEGRITY%"=="Disabled" set /a SCORE+=25
if not "%POWERPLAN%"=="Unknown" set /a SCORE+=25

set RECOMMENDATIONS=0

if not "%GAMEMODE%"=="Enabled" set /a RECOMMENDATIONS+=1
if not "%HAGS%"=="Enabled" set /a RECOMMENDATIONS+=1
if not "%MEMORYINTEGRITY%"=="Disabled" set /a RECOMMENDATIONS+=1
if "%POWERPLAN%"=="Balanced" set /a RECOMMENDATIONS+=1
if "%POWERPLAN%"=="Unknown" echo [!] Configure Power Plan
if "%POWERPLAN%"=="Balanced" echo [!] Activate High Performance Power Profile


echo.
echo               ╔════════════════════════════════════════════════════════════════════════════════════════════╗
echo               ║                                                                                            ║
echo               ║                                         FINN OS                                            ║
echo               ║                                                                                            ║
echo               ╚════════════════════════════════════════════════════════════════════════════════════════════╝
echo.

echo ────────────────────────────────────────────────────────────────────────────────────────────
echo  SYSTEM INFORMATION
echo ────────────────────────────────────────────────────────────────────────────────────────────
echo.

for /f "tokens=2 delims==" %%a in (
'wmic cpu get name /value ^| find "="'
) do set CPU=%%a

for /f "tokens=2 delims==" %%a in (
'wmic path win32_videocontroller get name /value ^| find "="'
) do set GPU=%%a

chcp 437 > nul
for /f %%a in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)"') do set RAMGB=%%a


for /f %%a in ('powershell -NoProfile -Command "[math]::Round((Get-PSDrive C).Free/1GB)"') do set FREEGB=%%a

for /f %%a in ('powershell -NoProfile -Command "[math]::Round(((Get-PSDrive C).Used + (Get-PSDrive C).Free)/1GB)"') do set TOTALGB=%%a


for /f %%a in ('powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController).CurrentRefreshRate"') do (
    set REFRESHRATE=%%a
    goto :gotrefresh
)

:gotrefresh
chcp 65001 > nul

for /f "tokens=2 delims==" %%a in (
'wmic os get caption /value ^| find "="'
) do set OSNAME=%%a

echo  CPU      : %CPU%
echo  GPU      : %GPU%
echo  RAM      : %RAMGB% GB
echo  Storage  : %FREEGB% GB Free / %TOTALGB% GB
echo  Display  : %REFRESHRATE% Hz
echo  OS       : %OSNAME%

echo.
echo ────────────────────────────────────────────────────────────────────────────────────────────
echo. BASIC OPTIMIZATION STATUS
echo ────────────────────────────────────────────────────────────────────────────────────────────
echo.
echo  Power Plan       : %POWERPLAN%
echo  Game Mode        : %GAMEMODE%
echo  HAGS             : %HAGS%
echo  Memory Integrity : %MEMORYINTEGRITY%
echo  Score            : %SCORE%/100
echo.
echo ───────────────────────────────────────────────────────────
echo  RECOMMENDATIONS
echo ───────────────────────────────────────────────────────────
if not "%GAMEMODE%"=="Enabled" echo [!] Enable Game Mode
if not "%HAGS%"=="Enabled" echo [!] Enable HAGS
if not "%MEMORYINTEGRITY%"=="Disabled" echo [!] Disable Memory Integrity
if "%POWERPLAN%"=="Unknown" echo [!] Configure Power Plan
echo.
if %RECOMMENDATIONS%==0 echo [✓] No recommendations, System is already optimized at a basic level.
echo.
echo ───────────────────────────────────────────────────────────────────────────────────
echo.
echo [1] Apply Recommended Fixes
echo [2] Quick Optimize
echo [3] Ultimate Gaming Optimization
echo [4] Cleanup Tools
echo [5] Network And Latency Optimization
echo [6] Backup ^& Restore
echo [0] Exit
echo.
choice /c 1234560 /n /m "Select Option: "

if errorlevel 7 exit
if errorlevel 6 goto backup
if errorlevel 5 goto network
if errorlevel 4 goto cleanup
if errorlevel 3 goto gaming
if errorlevel 2 goto quick
if errorlevel 1 goto applyfixes


goto home

:createrestore

echo.
echo Creating Restore Point...
echo.

powershell -Command "Checkpoint-Computer -Description 'Finn Optimizer Backup' -RestorePointType MODIFY_SETTINGS"

if %errorlevel%==0 (
echo [SUCCESS] Restore Point Created
) else (
echo [FAILED] Restore Point Creation Failed
)

echo.
exit /b

:applyfixes
cls

set CHANGES=0

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo              RECOMMENDED FIXES
echo.
echo ═══════════════════════════════════════════════════════════════
echo.

if "%POWERPLAN%"=="Balanced" (
    echo [INFO] Balanced Power Plan Detected

    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1

    for /f "tokens=3" %%a in ('powercfg -list ^| findstr /i "Ultimate"') do (
        powercfg -setactive %%a
    )

    echo [✓] Ultimate Performance Plan Activated
    set /a CHANGES+=1
)

if "%POWERPLAN%"=="Atlas" (
    echo [✓] Atlas Power Plan Already In Use
)

if "%POWERPLAN%"=="Ultimate" (
    echo [✓] Ultimate Performance Plan Already Active
)

if "%GAMEMODE%"=="Enabled" (
echo [✓] Game Mode Already Enabled
) else (
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul
echo [✓] Game Mode Activated
set /a CHANGES+=1
)

if "%HAGS%"=="Enabled" (
echo [✓] HAGS Already Enabled
) else (
echo [INFO] HAGS Requires Manual Review
)

if "%MEMORYINTEGRITY%"=="Disabled" (
echo [✓] Memory Integrity Already Optimized
) else (
echo [INFO] Memory Integrity Requires Manual Review
)

echo.
echo ──────────────────────────────────────────────────────────────
if "%CHANGES%"=="0" echo  No recommended fixes were required.
if not "%CHANGES%"=="0" echo %CHANGES% optimizations applied successfully.

echo.
echo ──────────────────────────────────────────────────────────────
echo [X] Return to Dashboard
echo.

choice /c X /n /m "Select Option: "
goto home


:quick
cls
set ACTIONS=0
set FILESREMOVED=0

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo                 QUICK OPTIMIZE
echo.
echo ═══════════════════════════════════════════════════════════════
echo.

echo Cleaning User Temporary Files...
del /f /s /q "%temp%*" >nul 2>&1
for /d %%x in ("%temp%*") do rd /s /q "%%x" >nul 2>&1
echo [✓] User Temporary Files Cleaned

set /a ACTIONS+=1

echo.
echo Cleaning Windows Temporary Files...
del /f /s /q "C:\Windows\Temp*" >nul 2>&1
for /d %%x in ("C:\Windows\Temp*") do rd /s /q "%%x" >nul 2>&1
echo [✓] Windows Temporary Files Cleaned

set /a ACTIONS+=1

echo.
echo Removing DirectX Shader Cache...

del /f /s /q "%LocalAppData%\D3DSCache*" >nul 2>&1
for /d %%D in ("%LocalAppData%\D3DSCache*") do rd /s /q "%%D" >nul 2>&1

echo [✓] DirectX Shader Cache Cleared
echo [INFO] Some games may rebuild shaders so slight lag and unstability on first launch is normal.

set /a ACTIONS+=1

echo.
echo Emptying Recycle Bin...
chcp 437 > nul
powershell -NoProfile -Command "Clear-RecycleBin -Force" >nul 2>&1
chcp 65001 > nul
echo [✓] Recycle Bin Emptied

set /a ACTIONS+=1

echo.

if "%GAMEMODE%"=="Enabled" (
echo [✓] Game Mode Already Optimized
) else (
echo [FIX] Game Mode Disabled

```
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul

echo [✓] Game Mode Activated
```
set /a ACTIONS+=1

)

echo.

if "%POWERPLAN%"=="Atlas" (
echo [✓] Atlas Power Profile Already Active and Optimized
)
set /a ACTIONS+=1

if "%POWERPLAN%"=="Ultimate" (
echo [✓] Ultimate Performance Already Active And In Use
)
set /a ACTIONS+=1

if "%POWERPLAN%"=="Balanced" (
echo [FIX] Balanced Power Plan Detected

```
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1

for /f "tokens=3" %%a in ('powercfg -list ^| findstr /i "Ultimate"') do (
    powercfg -setactive %%a
)

echo [✓] Ultimate Performance Plan Activated
```
set /a ACTIONS+=1
)

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo                    OPTIMIZATION SUMMARY
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo Actions Completed : %ACTIONS%
echo.
echo System Status     : Optimized
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [X] Return to Dashboard
echo.

choice /c X /n /m "Select Option: "
goto home

:gaming
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo           ULTIMATE GAMING OPTIMIZATION BY FINN
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [1] Registry Gaming Tweaks
echo [2] Notifications ^& Background Activity
echo [3] Visual Optimization
echo [4] Virtualization ^& VBS
echo [5] Driver Update Check
echo.
echo [0] Return To Dashboard
echo.

choice /c 123450 /n /m "Select Option: "

if errorlevel 6 goto home
if errorlevel 5 goto drivers
if errorlevel 4 goto virtualization
if errorlevel 3 goto visual
if errorlevel 2 goto notifications
if errorlevel 1 goto registry

goto gaming

:notifications
cls
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo         NOTIFICATIONS ^& BACKGROUND ACTIVITY
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [1] Apply Optimizations
echo [2] Restore Defaults
echo.
echo ──────────────────────────────────────────────────────────────
echo.
echo  Available Optimizations
echo.
echo [✓] Notifications OFF
echo [✓] Focus Assist ON
echo [✓] Delivery Optimization OFF
echo [✓] Background Apps Restricted
echo [✓] Suggestions ^& Tips OFF
echo.
echo ──────────────────────────────────────────────────────────────
echo [0] Return
echo.

choice /c 120 /n /m "Select Option: "

if errorlevel 3 goto gaming
if errorlevel 2 goto notifications_restore
if errorlevel 1 goto notifications_apply

goto notifications

:visual
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo                VISUAL OPTIMIZATION
echo.
echo ═══════════════════════════════════════════════════════════════
echo [1] Apply Optimizations
echo [2] Restore Defaults
echo ──────────────────────────────────────────────────────────────
echo.
echo Available Optimizations
echo.
echo [✓] Transparency Effects OFF
echo [✓] Animation Effects OFF
echo [✓] Adjust For Best Performance
echo [✓] Smooth Screen Fonts ON
echo [✓] Show Thumbnails ON
echo.
echo ──────────────────────────────────────────────────────────────
echo [0] Return
echo.
choice /c 120 /n /m "Select Option: "

if errorlevel 3 goto gaming
if errorlevel 2 goto visual_restore
if errorlevel 1 goto visual_apply

goto visual


:virtualization
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo              VIRTUALIZATION ^& VBS
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo Available Optimizations
echo.
echo [✓] Hyper-V OFF
echo [✓] Virtual Machine Platform OFF
echo [✓] Windows Hypervisor Platform OFF
echo [✓] Windows Sandbox OFF
echo [✓] VBS Disabled
echo.
echo ──────────────────────────────────────────────────────────────
echo.
echo [1] Apply Optimizations
echo [2] Restore Defaults
echo.
echo [0] Return
echo.

choice /c 120 /n /m "Select Option: "

if errorlevel 3 goto gaming
if errorlevel 2 goto virtualization_restore
if errorlevel 1 goto virtualization_apply

goto virtualization


:drivers
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo                DRIVER UPDATE CHECK
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [1] Open Windows Update
echo [2] Open Device Manager
echo [3] Check Installed GPU Driver
echo [4] Open Latest Driver Download Page
echo.
echo [0] Return
echo.

choice /c 12340 /n /m "Select Option: "

if errorlevel 5 goto gaming
if errorlevel 4 goto gpu_software
if errorlevel 3 goto gpu_driver
if errorlevel 2 goto device_manager
if errorlevel 1 goto windows_update


goto drivers

:windows_update
start ms-settings:windowsupdate
goto drivers

:device_manager
start devmgmt.msc
goto drivers

:gpu_driver
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo              INSTALLED GPU DRIVER
echo.
echo ═══════════════════════════════════════════════════════════════
echo.

wmic path win32_VideoController get Name,DriverVersion

echo.
echo [X] Return

choice /c X /n >nul
goto drivers

:gpu_software

wmic path win32_VideoController get Name | find /i "NVIDIA" >nul
if not errorlevel 1 (
start https://www.nvidia.com/en-us/drivers/
goto drivers
)

wmic path win32_VideoController get Name | find /i "AMD" >nul
if not errorlevel 1 (
start https://www.amd.com/en/support
goto drivers
)

wmic path win32_VideoController get Name | find /i "Intel" >nul
if not errorlevel 1 (
start https://www.intel.com/content/www/us/en/download-center/home.html
goto drivers
)

cls
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo No Supported GPU Vendor Detected
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [X] Return

choice /c X /n >nul
goto drivers



:registry
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo                 REGISTRY GAMING TWEAKS
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [1] Apply Registry Tweaks
echo [2] Restore Registry Defaults
echo.
echo ──────────────────────────────────────────────────────────────
echo.
echo  Available Tweaks
echo.
echo [✓] Win32PrioritySeparation
echo [✓] Network Throttling
echo [✓] GPU Priority
echo [✓] MMCSS Priority
echo [✓] Scheduling Category
echo.
echo ──────────────────────────────────────────────────────────────
echo [0] Return
echo.

choice /c 120 /n /m "Select Option: "

if errorlevel 3 goto gaming
if errorlevel 2 goto registry_restore
if errorlevel 1 goto registry_apply

goto registry


:registry_apply
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo           APPLYING REGISTRY GAMING TWEAKS
echo.
echo ═══════════════════════════════════════════════════════════════
echo.

reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f >nul

echo [✓] Win32PrioritySeparation Applied

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul

echo [✓] Network Throttling Disabled

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
echo [✓] GPU Priority Set To 8

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Priority /t REG_DWORD /d 6 /f >nul
echo [✓] Priority Set To 6

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d High /f >nul
echo [✓] Scheduling Category Set To High


echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo Registry Tweaks Applied Successfully.
echo.
echo [INFO] Restart Recommended For Best Results.
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [X] Return

choice /c X /n >nul
goto registry

:registry_restore
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo           RESTORING REGISTRY DEFAULTS
echo.
echo ═══════════════════════════════════════════════════════════════
echo.

reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 2 /f >nul

echo [✓] Win32PrioritySeparation Restored

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul

echo [✓] Network Throttling Restored

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 2 /f >nul
echo [✓] GPU Priority Restored

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Priority /t REG_DWORD /d 2 /f >nul
echo [✓] Priority Restored

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d Medium /f >nul
echo [✓] Scheduling Category Restored


echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo Registry Defaults Restored Successfully.
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [X] Return

choice /c X /n >nul
goto registry

:notifications_apply
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo      APPLYING NOTIFICATIONS ^& BACKGROUND OPTIMIZATIONS
echo.
echo ═══════════════════════════════════════════════════════════════
echo.

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /t REG_DWORD /d 0 /f >nul

echo [OK] Delivery Optimization Disabled

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /t REG_DWORD /d 0 /f >nul

echo [OK] Windows Suggestions ^& Tips Disabled

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f >nul

echo [OK] Notifications Disabled
echo.
echo ──────────────────────────────────────────────────────────────
echo [INFO] Restart Required For Changes To Take Effect

echo.
echo [X] Return

choice /c X /n >nul
goto notifications


:notifications_restore
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo       RESTORING NOTIFICATION DEFAULTS
echo.
echo ═══════════════════════════════════════════════════════════════
echo.

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 1 /f >nul
echo [OK] Notifications Restored

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /f >nul 2>&1
echo [OK] Delivery Optimization Restored

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /t REG_DWORD /d 1 /f >nul
echo [OK] Windows Suggestions ^& Tips Restored

echo.
echo ──────────────────────────────────────────────────────────────
echo [INFO] Changes made may need a restart to fully take affect.

echo.
echo [X] Return

choice /c X /n >nul
goto notifications

...

:visual_apply
cls

echo.
echo Applying Visual Optimizations...
echo.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul

echo [OK] Transparency Effects Disabled

reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul

echo [OK] Animation Effects Disabled

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul

echo [OK] Adjusted For Best Performance

reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul
echo [OK] Smooth Screen Fonts Enabled

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul
echo [OK] Thumbnail Previews Enabled


echo.
echo [X] Return

choice /c X /n >nul
goto visual

:visual_restore
cls

echo.
echo Restoring Visual Defaults...
echo.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul

echo [OK] Transparency Effects Restored

reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 1 /f >nul

echo [OK] Animation Effects Restored

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul

echo [OK] Visual Effects Restored

reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul
echo [OK] Smooth Screen Fonts Restored

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul
echo [OK] Thumbnail Previews Restored


echo.
echo [X] Return

choice /c X /n >nul
goto visual
...

:virtualization_apply
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo      APPLYING VIRTUALIZATION OPTIMIZATIONS
echo.
echo ═══════════════════════════════════════════════════════════════
echo.

bcdedit /set hypervisorlaunchtype off >nul 2>&1
echo [OK] Hypervisor Launch Disabled

dism /online /disable-feature /featurename:Microsoft-Hyper-V-All /norestart >nul 2>&1
echo [OK] Hyper-V Disabled

dism /online /disable-feature /featurename:VirtualMachinePlatform /norestart >nul 2>&1
echo [OK] Virtual Machine Platform Disabled

dism /online /disable-feature /featurename:HypervisorPlatform /norestart >nul 2>&1
echo [OK] Windows Hypervisor Platform Disabled

dism /online /disable-feature /featurename:Containers-DisposableClientVM /norestart >nul 2>&1
echo [OK] Windows Sandbox Disabled

echo.
echo [INFO] Restart Required For Changes To Take Effect
echo.
echo [X] Return

choice /c X /n >nul
goto virtualization


:virtualization_restore
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo      RESTORING VIRTUALIZATION DEFAULTS
echo.
echo ═══════════════════════════════════════════════════════════════
echo.

bcdedit /set hypervisorlaunchtype auto >nul 2>&1
echo [OK] Hypervisor Launch Restored

echo.
echo [INFO] Restart Required For Changes To Take Effect
echo.
echo [X] Return

choice /c X /n >nul
goto virtualization

:cleanup
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo                    CLEANUP TOOLS
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [1] Windows Disk Cleanup
echo [2] Review Installed Apps
echo [3] Review Startup Applications
echo.
echo [0] Return
echo.

choice /c 1230 /n /m "Select Option: "

if errorlevel 4 goto home
if errorlevel 3 goto startup_apps
if errorlevel 2 goto installed_apps
if errorlevel 1 goto disk_cleanup

goto cleanup
:disk_cleanup
start cleanmgr.exe
goto cleanup

:installed_apps
start ms-settings:appsfeatures
goto cleanup

:startup_apps
start ms-settings:startupapps
goto cleanup


:network
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo          NETWORK ^& LATENCY OPTIMIZATION
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo Available Optimizations
echo.
echo [✓] DNS Cache Refresh
echo [✓] Winsock Reset
echo [✓] TCP/IP Stack Reset
echo [✓] System Responsiveness Optimized
echo.
echo ──────────────────────────────────────────────────────────────
echo.
echo [1] Apply Optimizations
echo.
echo [0] Return
echo.

choice /c 10 /n /m "Select Option: "

if errorlevel 2 goto home
if errorlevel 1 goto network_apply

:network_apply
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo      APPLYING NETWORK ^& LATENCY OPTIMIZATIONS
echo.
echo ═══════════════════════════════════════════════════════════════
echo.

ipconfig /flushdns >nul
echo [OK] DNS Cache Flushed

netsh winsock reset >nul
echo [OK] Winsock Reset Applied

netsh int ip reset >nul
echo [OK] TCP/IP Stack Reset Applied

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f >nul
echo [OK] System Responsiveness Optimized

echo.
echo [INFO] Restart Recommended
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [X] Return
echo.

choice /c X /n >nul
goto network

:backup
cls

echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo                 BACKUP ^& RESTORE
echo.
echo ═══════════════════════════════════════════════════════════════
echo.
echo [1] Open Windows Backup
echo [2] Create Restore Point
echo.
echo [0] Return
echo.

choice /c 120 /n /m "Select Option: "

if errorlevel 3 goto home
if errorlevel 2 goto restore_point
if errorlevel 1 goto windows_backup

goto backup

:windows_backup
start ms-settings:windowsbackup
goto backup

:restore_point
SystemPropertiesProtection.exe
goto backup

:CheckForUpdates

echo.
echo Checking for updates...
chcp 437 > nul
powershell -Command "(Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/apoorvs009/FinnOS-Updates/main/version.txt' -UseBasicParsing).Content.Trim()" > "%temp%\finn_version.txt"
chcp 65001 > nul
set /p LATEST_VERSION=<"%temp%\finn_version.txt"

if "%LATEST_VERSION%"=="%CURRENT_VERSION%" (
    echo Finn OS is up to date.
    timeout /t 2 >nul
    goto :eof
)

echo.
echo ==========================================
echo UPDATE AVAILABLE!
echo Current Version: %CURRENT_VERSION%
echo Latest Version : %LATEST_VERSION%
echo ==========================================
echo.

pause

goto :eof



                                                                                                                             
