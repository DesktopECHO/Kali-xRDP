@ECHO OFF & NET SESSION >NUL 2>&1
IF %ERRORLEVEL% == 0 (ECHO Administrator check passed...) ELSE (ECHO You need to run this command with administrative rights.  Is User Account Control enabled? && pause && goto ENDSCRIPT)
COLOR 1F
SET GITORG=DesktopECHO
SET GITPRJ=Kali-xRDP
SET BRANCH=main
SET BASE=https://github.com/%GITORG%/%GITPRJ%/raw/%BRANCH%
SET RUNSTART=%date% @ %time:~0,5%
SET DISTRO=kali-linux
START /MIN "Kali" "CMD.EXE" "/C WSLconfig.exe /t %DISTRO% & Taskkill.exe /IM kali.exe /F"

REM ## Enable WSL if needed
PowerShell.exe -Command "$WSL = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' ; if ($WSL.State -eq 'Disabled') {Enable-WindowsOptionalFeature -FeatureName $WSL.FeatureName -Online}"

REM ## Install Kali from AppStore if needed
PowerShell.exe -Command "wsl -d kali-linux -e 'uname' > $env:TEMP\DistroTestAlive.TMP ; $alive = Get-Content $env:TEMP\DistroTestAlive.TMP ; IF ($Alive -ne 'Linux') { Start-BitsTransfer https://aka.ms/wsl-kali-linux-new -Destination $env:TEMP\Kali.AppX ; WSL.EXE --set-default-version 1 > $null ; Add-AppxPackage $env:TEMP\Kali.AppX ; Write-Host ; START ((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\kali.exe' -Name '(Default)') | findstr default).substring(15) ; Write-Host 'When the KALI.EXE window prompts you to create a user, close the window and' ; PAUSE ; Write-Host }"

REM ## Acquire LxRunOffline
MKDIR %TEMP%\Kali-xRDP >NUL 2>&1
IF NOT EXIST "%TEMP%\LxRunOffline.exe" POWERSHELL.EXE -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; wget https://github.com/DesktopECHO/Pi-Hole-for-WSL1/blob/master/LxRunOffline-v3.5.0-33-gbdc6d7d-msvc.zip?raw=true -UseBasicParsing -OutFile '%TEMP%\LxRunOffline.zip' ; Expand-Archive -Path '%TEMP%\LxRunOffline.zip' -DestinationPath '%TEMP%' -Force ; copy '%TEMP%\LxRunOffline-v3.5.0-33-gbdc6d7d-msvc\*.exe' '%TEMP%'" > NUL

REM ## Find system DPI setting and get installation parameters
IF NOT EXIST "%TEMP%\windpi.ps1" POWERSHELL.EXE -ExecutionPolicy Bypass -Command "wget '%BASE%/windpi.ps1' -UseBasicParsing -OutFile '%TEMP%\windpi.ps1'"
FOR /f "delims=" %%a in ('powershell -ExecutionPolicy bypass -command "%TEMP%\windpi.ps1" ') do set "WINDPI=%%a"

CLS
ECHO [Kali-xRDP Installer 20240807]
ECHO:
ECHO Hit Enter to use your current display scaling in Windows
SET /p WINDPI=or set your desired value (1.0 to 3.0 in .25 increments) [%WINDPI%]: 
SET RDPPRT=3399& SET /p RDPPRT=Port number for xRDP traffic or hit Enter for default [3399]: 
SET SSHPRT=3322& SET /p SSHPRT=Port number for SSHd traffic or hit Enter for default [3322]: 
FOR /f "delims=" %%a in ('PowerShell -Command 96 * "%WINDPI%" ') do set "LINDPI=%%a"
FOR /f "delims=" %%a in ('PowerShell -Command 32 * "%WINDPI%" ') do set "PANEL=%%a"
FOR /f "delims=" %%a in ('PowerShell -Command 48 * "%WINDPI%" ') do set "ICONS=%%a"
SET DEFEXL=NONO& SET /p DEFEXL=[Not recommended!] Type [X] to eXclude from Windows Defender: 
SET DISTROFULL=%temp%
SET /A SESMAN = %RDPPRT% - 50
CD %DISTROFULL%
%TEMP%\LxRunOffline.exe su -n %DISTRO% -v 0
SET GO="%DISTROFULL%\LxRunOffline.exe" r -n "%DISTRO%" -c

IF %DEFEXL%==X (POWERSHELL.EXE -Command "wget %BASE%/excludeWSL.ps1 -UseBasicParsing -OutFile '%DISTROFULL%\excludeWSL.ps1'" & START /WAIT /MIN "Add exclusions in Windows Defender" "POWERSHELL.EXE" "-ExecutionPolicy" "Bypass" "-Command" ".\excludeWSL.ps1" "%DISTROFULL%" &  DEL ".\excludeWSL.ps1")

REM ## Workaround potential DNS issue in WSL and update Keyring
%GO% "rm -rf /etc/resolv.conf ; echo 'nameserver 9.9.9.9' > /etc/resolv.conf ; echo 'nameserver 8.8.8.8' >> /etc/resolv.conf ; chattr +i /etc/resolv.conf" >NUL 2>&1

REM ## Loop until we get a successful repo update
:APTRELY
IF EXIST apterr DEL apterr
START /MIN /WAIT "apt-get update" %GO% "apt-get update 2> apterr"
FOR /F %%A in ("apterr") do If %%~zA NEQ 0 GOTO APTRELY

ECHO:
ECHO [%TIME:~0,8%] Prepare Distro                          (ETA: 1m30s)
%GO% "cd /tmp ; export RUNLEVEL=0 DEBIAN_FRONTEND=noninteractive ; apt-get -y install systemd ; rm -rf /var/lib/dpkg/info/systemd.postinst ; apt-get -fy install ; apt-get -y install udev polkitd ; rm -rf /var/lib/dpkg/info/udev.postinst ; rm -rf /var/lib/dpkg/info/polkitd.postinst ; DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends libcares2 libssh2-1t64 libaria2-0 aria2 git acl pciutils gnupg2 ; echo 'exit 0' > /usr/bin/lspci ; echo 'exit 0' > /usr/bin/setfacl ; rm -rf %GITPRJ% ; echo 'Clone Git repo...' ; git clone --quiet -b %BRANCH% --depth=1 https://github.com/%GITORG%/%GITPRJ%.git ; chmod +x /tmp/Kali-xRDP/dist/usr/local/bin/*" > "%TEMP%\Kali-xRDP\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Prepare Distro.log" 2>&1 

%GO% "find /tmp/Kali-xRDP -type d -exec chmod 755 {} \;"
%GO% "find /tmp/Kali-xRDP -type f -exec chmod 644 {} \;"
%GO% "cp -p /tmp/Kali-xRDP/dist/usr/local/bin/systemd-sysusers /usr/local/bin ; rm -rf /tmp/apt-fast.lock ; chmod +x /tmp/Kali-xRDP/dist/usr/local/bin/* ; cp -p /tmp/Kali-xRDP/dist/usr/local/bin/apt-fast /usr/local/bin ; chmod 755 /tmp/Kali-xRDP/dist/etc/profile.d/xWSL.sh /tmp/Kali-xRDP/dist/etc/xrdp/startwm.sh /tmp/Kali-xRDP/dist/usr/bin/pm-is-supported /tmp/Kali-xRDP/dist/usr/local/bin/restartwsl /tmp/Kali-xRDP/dist/usr/local/bin/initwsl ; chmod -R 7700 /tmp/Kali-xRDP/dist/etc/skel/.local"

ECHO [%TIME:~0,8%] 'kali-linux-core' metapackage and xRDP  (ETA: 3m30s)
%GO% "RUNLEVEL=0 DEBIAN_FRONTEND=noninteractive apt-fast -y install --allow-downgrades /tmp/Kali-xRDP/deb/x*.deb /tmp/Kali-xRDP/deb/synaptic_0.90.2_amd64.deb /tmp/Kali-xRDP/deb/g*.deb /tmp/Kali-xRDP/deb/lib*.deb /tmp/Kali-xRDP/deb/multiarch-support_2.27-3ubuntu1_amd64.deb /tmp/Kali-xRDP/deb/fonts-cascadia-code_2102.03-1_all.deb /tmp/Kali-xRDP/deb/pulseaudio-module-xrdp*.deb libpulsedsp libspeexdsp1 pulseaudio pulseaudio-utils libxcb-damage0 x11-apps x11-session-utils x11-xserver-utils xserver-common xserver-xorg xserver-xorg-core xserver-xorg-legacy dialog distro-info-data dumb-init inetutils-syslogd xdg-utils avahi-daemon libnss-mdns binutils putty unzip zip unzip dbus-x11 samba-common-bin lhasa arj unace liblhasa0 apt-config-icons apt-config-icons-hidpi apt-config-icons-large apt-config-icons-large-hidpi libvte-2.91-0 libvte-2.91-common libdbus-glib-1-2 xbase-clients python3-psutil kali-linux-core moreutils libpython3.12-minimal libpython3.12-stdlib python3.12 python3.12-minimal --no-install-recommends" > "%TEMP%\Kali-xRDP\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% xRDP and 'kali-linux-core' metapackage.log" 2>&1

ECHO [%TIME:~0,8%] Kali Xfce desktop environment           (ETA: 3m00s)
%GO% "DEBIAN_FRONTEND=noninteractive apt-fast -y install xfce4-settings xfdesktop4 xfce4-session xfdesktop4-data xfce4 xfwm4 qt5ct lsb-release xfce4-datetime-plugin ristretto parole mousepad mate-calc-common xfce4-taskmanager mate-calc xfce4-screenshooter xfce4-clipman xfce4-clipman-plugin xfce4-cpugraph-plugin xfce4-whiskermenu-plugin xdg-user-dirs xdg-user-dirs-gtk kazam kali-menu kali-themes kali-wallpapers-2023 gstreamer1.0-gl gstreamer1.0-plugins-bad gstreamer1.0-plugins-bad-apps gstreamer1.0-plugins-base-apps gstreamer1.0-plugins-good gstreamer1.0-tools mesa-utils qterminal libqt5x11extras5 libqtermwidget5-1 qterminal qtermwidget5-data epiphany-browser pcscd gstreamer1.0-fdkaac libaribb24-0 libavcodec-extra libopencore-amrnb0 libopencore-amrwb0 libvo-amrwbenc0 --no-install-recommends ; update-rc.d pcscd remove" > "%TEMP%\Kali-xRDP\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Kali Xfce desktop environment.log" 2>&1

REM ## Additional items to install can go here...
ECHO [%TIME:~0,8%] Extras [Seamonkey, Zenmap, CRD]         (ETA: 1m30s)
%GO% "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A8AA1FAA3F055C03 B7B9C16F2667CA5C CCC158AFC1289A29 ; echo 'deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main' > /etc/apt/sources.list.d/mozilla.list ; cp /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/ubuntu.gpg ; apt-get update" >NUL 2>&1
%GO% "wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb -O /tmp/chrome-remote-desktop_current_amd64.deb ; DEBIAN_FRONTEND=noninteractive apt-fast -y install tilix atril engrampa seamonkey-mozilla-build nmap ncat ndiff /tmp/chrome-remote-desktop_current_amd64.deb /tmp/Kali-xRDP/deb/zenmap_*.deb" > "%TEMP%\Kali-xRDP\%TIME:~0,2%%TIME:~3,2%%TIME:~6,2% Extras [Seamonkey, Zenmap, CRD].log" 2>&1
%GO% "update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/bin/seamonkey 100 ; update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/seamonkey 100" >NUL 2>&1
%GO% "mv /usr/bin/pkexec /usr/bin/pkexec.orig ; echo gksudo -k -S -g \$1 > /usr/bin/pkexec ; chmod 755 /usr/bin/pkexec"
%GO% "which schtasks.exe" > "%TEMP%\SCHT.tmp" & set /p SCHT=<"%TEMP%\SCHT.tmp"
%GO% "sed -i 's#SCHT#%SCHT%#g' /tmp/Kali-xRDP/dist/usr/local/bin/restartwsl ; sed -i 's#DISTRO#%DISTRO%#g' /tmp/Kali-xRDP/dist/usr/local/bin/restartwsl"

IF %LINDPI% GEQ 288 ( %GO% "sed -i 's/HISCALE/3/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; sed -i 's/HISCALE/3/g' /tmp/Kali-xRDP/dist/etc/profile.d/xWSL.sh" )
IF %LINDPI% GEQ 240 ( %GO% "sed -i 's/QQQ/120/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; sed -i 's/III/60/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml ; sed -i 's/PPP/40/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" )
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/HISCALE/2/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; sed -i 's/HISCALE/2/g' /tmp/Kali-xRDP/dist/etc/profile.d/xWSL.sh" )
IF %LINDPI% GEQ 192 ( %GO% "sed -i 's/Kali-Dark-HiDPI/Kali-Dark-xHiDPI/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml ; sed -i 's/QQQ/96/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; sed -i 's/III/48/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml ; sed -i 's/PPP/32/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" )
IF %LINDPI% LSS 192 ( %GO% "sed -i 's/HISCALE/1/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; sed -i 's/HISCALE/1/g' /tmp/Kali-xRDP/dist/etc/profile.d/xWSL.sh ; sed -i 's/QQQ/%LINDPI%/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ; sed -i 's/III/%ICONS%/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml ; sed -i 's/PPP/%PANEL%/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" )
IF %LINDPI% LSS 120 ( %GO% "sed -i 's/Kali-Dark-HiDPI/Kali-Dark/g' /tmp/Kali-xRDP/dist/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" )

%GO% "sed -i 's/\\h/%DISTRO%/g' /tmp/Kali-xRDP/dist/etc/skel/.bashrc"
%GO% "sed -i 's/#Port 22/Port %SSHPRT%/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config"
%GO% "sed -i 's/WSLINSTANCENAME/%DISTRO%/g' /tmp/Kali-xRDP/dist/usr/local/bin/initwsl"
%GO% "sed -i 's/#enable-dbus=yes/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/#host-name=foo/host-name=%COMPUTERNAME%-%DISTRO%/g' /etc/avahi/avahi-daemon.conf ; sed -i 's/use-ipv4=yes/use-ipv4=no/g' /etc/avahi/avahi-daemon.conf"
%GO% "cp /mnt/c/Windows/Fonts/*.ttf /usr/share/fonts/truetype ; ssh-keygen -A ; adduser xrdp ssl-cert &> /dev/null" > NUL
%GO% "rm /usr/lib/systemd/system/dbus-org.freedesktop.login1.service /usr/share/dbus-1/system-services/org.freedesktop.login1.service /usr/share/polkit-1/actions/org.freedesktop.login1.policy ; rm /usr/share/dbus-1/services/org.freedesktop.systemd1.service /usr/share/dbus-1/system-services/org.freedesktop.systemd1.service /usr/share/dbus-1/system.d/org.freedesktop.systemd1.conf /usr/share/polkit-1/actions/org.freedesktop.systemd1.policy /usr/share/applications/gksu.desktop" > NUL 2>&1
%GO% "cp -Rp /tmp/Kali-xRDP/dist/* / ; cp -Rp /tmp/Kali-xRDP/dist/etc/skel/.* /root ; chmod +x /etc/init.d/xrdp ; update-rc.d -f xrdp defaults ; update-rc.d -f inetutils-syslogd enable S 2 3 4 5 ; update-rc.d -f ssh enable S 2 3 4 5 ; update-rc.d -f avahi-daemon enable S 2 3 4 5 ; apt-get clean ; cd /tmp" >NUL 2>&1
%GO% "setcap cap_net_raw+p /bin/ping"
%GO% "sed -i 's/port=3389/port=%RDPPRT%/g' /etc/xrdp/xrdp.ini"
%GO% "sed -i 's/thinclient_drives/.xWSL/g' /etc/xrdp/sesman.ini"
%GO% "service dbus stop" > NUL

SET RUNEND=%date% @ %time:~0,5%
CD %DISTROFULL%
ECHO:
SET /p XU=Create a NEW user in Kali for xRDP GUI login. Enter username: 
POWERSHELL -Command $prd = read-host "Enter password for %XU%" -AsSecureString ; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($prd) ; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) > .tmp & set /p PWO=<.tmp
%GO% "useradd -m -p nulltemp -s /bin/bash %XU%"
%GO% "(echo '%XU%:%PWO%') | chpasswd"
%GO% "echo '%XU% ALL=(ALL:ALL) ALL' >> /etc/sudoers"
%GO% "sed -i 's/PLACEHOLDER/%XU%/g' /tmp/Kali-xRDP/xWSL.rdp"
%GO% "sed -i 's/COMPY/LocalHost/g' /tmp/Kali-xRDP/xWSL.rdp"
%GO% "sed -i 's/RDPPRT/%RDPPRT%/g' /tmp/Kali-xRDP/xWSL.rdp"
%GO% "cp /tmp/Kali-xRDP/xWSL.rdp ./xWSL._"
ECHO $prd = Get-Content .tmp > .tmp.ps1
ECHO ($prd ^| ConvertTo-SecureString -AsPlainText -Force) ^| ConvertFrom-SecureString ^| Out-File .tmp  >> .tmp.ps1
POWERSHELL -ExecutionPolicy Bypass -Command ./.tmp.ps1
TYPE .tmp>.tmpsec.txt
COPY /y /b xWSL._+.tmpsec.txt "%DISTROFULL%\Kali-xRDP (%XU%).rdp" > NUL
DEL /Q  xWSL._ .tmp*.* > NUL
ECHO:
ECHO Open Windows Firewall Ports for xRDP, SSH, mDNS...
NETSH AdvFirewall Firewall add rule name="%DISTRO% xRDP" dir=in action=allow protocol=TCP localport=%RDPPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Secure Shell" dir=in action=allow protocol=TCP localport=%SSHPRT% > NUL
NETSH AdvFirewall Firewall add rule name="%DISTRO% Avahi Daemon" dir=in action=allow protocol=UDP localport=5353,53791 > NUL
START /MIN "%DISTRO% Init" WSL ~ -u root -d %DISTRO% -e initwsl 2
ECHO Building RDP Connection file, Init system...
ECHO Set OW = GetObject(^"winmgmts:^" ^& ^"^{impersonationLevel^=impersonate^}!\\.\root\cimv2^") > "%LOCALAPPDATA%\Kali-xRDP.vbs"
ECHO Set ST = OW.Get(^"Win32_ProcessStartup^") >> "%LOCALAPPDATA%\Kali-xRDP.vbs"
ECHO Set OC = ST.SpawnInstance_ >> "%LOCALAPPDATA%\Kali-xRDP.vbs"
ECHO OC.ShowWindow ^= 0 >> "%LOCALAPPDATA%\Kali-xRDP.vbs"
ECHO Set OP = GetObject(^"winmgmts:root\cimv2:Win32_Process^") >> "%LOCALAPPDATA%\Kali-xRDP.vbs"
ECHO WScript.Sleep 2000 >> "%LOCALAPPDATA%\Kali-xRDP.vbs"
ECHO RT = OP.Create( ^"WSLCONFIG.EXE /t kali-linux^", null, OC, intProcessID) >> "%LOCALAPPDATA%\Kali-xRDP.vbs"
ECHO WScript.Sleep 5000 >> "%LOCALAPPDATA%\Kali-xRDP.vbs"
ECHO RT = OP.Create( ^"WSL.EXE ~ -u root -d kali-linux -e initwsl 2^", null, OC, intProcessID) >> "%LOCALAPPDATA%\Kali-xRDP.vbs"
POWERSHELL -Command "Copy-Item '%DISTROFULL%\Kali-xRDP (%XU%).rdp' ([Environment]::GetFolderPath('Desktop'))"
ECHO Building Scheduled Task...
%GO% "cp /tmp/Kali-xRDP/xWSL.xml ."
%TEMP%\LxRunOffline.exe su -n %DISTRO% -v 1000
POWERSHELL -C "$WAI = (whoami)                       ; (Get-Content .\xWSL.xml).replace('AAAA', $WAI) | Set-Content .\xWSL.xml"
POWERSHELL -C "$WAC = '%LOCALAPPDATA%\Kali-xRDP.vbs' ; (Get-Content .\xWSL.xml).replace('QQQQ', $WAC) | Set-Content .\xWSL.xml"
SCHTASKS /Create /TN:%DISTRO% /XML ./xWSL.xml /F
PING -n 6 LOCALHOST > NUL
ECHO:
ECHO:      Start: %RUNSTART%
ECHO:        End: %RUNEND%
%GO%  "echo -ne '   Packages:'\   ; dpkg-query -l | grep "^ii" | wc -l "
ECHO:
ECHO:     * xRDP Server listening on port %RDPPRT% and SSHd on port %SSHPRT%.
ECHO:
ECHO:     * Connection file for xRDP session has been placed on your desktop.
ECHO:
ECHO:     * Launch or Relaunch xRDP from Task Scheduler with the following command:
ECHO:       schtasks.exe /run /tn %DISTRO%
ECHO:
ECHO:     * Kill xRDP with the following command:
ECHO        wslconfig.exe /t %DISTRO%
ECHO:
ECHO:     * This is a minimal installation of Kali. To install default packages:
ECHO:       sudo apt install kali-linux-default
ECHO:
ECHO:Installation of Kali-xRDP (%DISTRO%) complete.
ECHO:Remote Desktop session will start shortly...
PING -n 6 LOCALHOST > NUL
START "Remote Desktop Connection" "MSTSC.EXE" "/V" "Kali-xRDP (%XU%).rdp"
CD ..
ECHO:
:ENDSCRIPT
