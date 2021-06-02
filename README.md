# [Kali-xRDP • GUI add-on for Kali Linux in WSL (Version 1 or 2) • v1.1/20210602](https://github.com/DesktopECHO/Kali-xRDP)
Other distributions are available - See **KDE Neon** [**(kWSL)**](https://github.com/DesktopECHO/kWSL) and **Ubuntu 20.04** [**(xWSL)**](https://github.com/DesktopECHO/xWSL) for details.

Kali-xRDP is a fully-automated script that installs xRDP on-top of Kali Linux from the Windows Store.  It works under WSL1 or WSL2 and includes optimizations and visual tweaks for a smooth and responsive desktop experience.  Display scaling is configured automatically and works on everything from standard unscaled displays all the way to xHiDPI (250%+) displays like the Microsoft Surface.

Other Kali GUI installers are designed to work with WSL2 only, and therefore target newer versions of Windows.  Kali-xRDP works with Windows 10 version 1809, Windows Server 2019, Server Core, or Hyper-V Server 2019.  Running Kali in WSL1 can also be helpful for newer versions of Windows running on older hardware without VT-d, or in a virtual machine without nested virtualization support.  Note that WSL1 has limitations in its networking stack that prevent some of Kali's included tools from working as they should, so you should run Kali in WSL2 unless you're prevented from doing so for the reasons listed above.       

The install script is meant to be run on a new Kali Linux installation from the Microsoft Store.  If Kali is not installed on your system it will download the .AppX image directly from Microsoft and install it for you. 

**INSTRUCTIONS:  Open a NEW elevated command prompt window (admin rights are required to open firewall ports for RDP and SSH) then type/paste the following command:**

    PowerShell -executionpolicy bypass -command "wget https://github.com/DesktopECHO/Kali-xRDP/raw/main/Kali-xRDP.cmd -UseBasicParsing -OutFile Kali-xRDP.cmd ; .\Kali-xRDP.cmd"
    
You will be asked a few questions.  The installer script determines the current Windows DPI scaling of your system but you may set your own if preferred:

     [Kali xRDP Installer 20210602]

     Hit Enter to use your current display scaling in Windows
     or set the desired value (1.0 to 3.0 in .25 increments) [1.5]: 1.25
     Port number for xRDP traffic or hit Enter for default [3399]:
     Port number for SSHd traffic or hit Enter for default [3322]:
     [Not recommended!] Type X to eXclude from Windows Defender:

The script will download the [LxRunOffline](https://github.com/DDoSolitary/LxRunOffline) distro manager to bootstrap the installation.  Install times will vary depending on system performance and presence of antivirus software.  A fast system with broadband Internet can complete the install in under 10 minutes and most machines will complete within 20 minutes. 

     [22:18:12] Prepare Distro (~1m00s)
     [22:19:08] Install xRDP and Kali-Linux-Core packages (~3m00s)
     [22:22:53] Kali-Desktop-XFCE (~5m00s)
     [22:30:39] Additional Components (~1m00s)
   
At the end of the script you will be prompted to create a non-root user which will automatically be added to sudo'ers.

     Create a NEW user in Kali for xRDP GUI login. Enter username: kaliuser
     Enter password for kaliuser: **********

    Open Windows Firewall Ports for xRDP, SSH, mDNS...
    Building RDP Connection file, Init system...
    Building Scheduled Task...
    SUCCESS: The scheduled task "kali-linux" has successfully been created.

           Start: Thu 02/25/2021 @ 22:17
             End: Thu 02/25/2021 @ 22:31
        Packages: 1154

       - xRDP Server listening on port 3399 and SSHd on port 3322.

       - Link for GUI session has been placed on your desktop.

       - (Re)launch init from the Task Scheduler or by running the following command:
         schtasks.exe /run /tn kali-linux

      Installaion of xRDP GUI on "kali-linux" complete, graphical login will start in a few seconds...

A fullscreen remote desktop session will launch Kali using your stored credentials.   

**Configure Kali-xRDP to start at boot (like a service, no console window)**

* Open the Windows Task Scheduler 
* Right-click the task in Task Scheduler (kali-linux) and click properties
* Click the checkbox for **Run whether user is logged on or not** and click **OK**
* Enter your Windows credentials when prompted
 
Reboot your PC when complete and the xRDP service in Kali will startup automatically with your system.

**Start/Stop Operation**

* Start (or restart) the instance: ````schtasks /run /tn kali-linux```` 
* Terminate the instance: ````wslconfig /t kali-linux````

**Convert to WSL2 instance**

If your computer has virtualization support you can convert the instance to WSL2 (and back to WSL1 if needed.) 

 - Terminate the instance:
    ````wslconfig /t kali-linux````
 - Convert the instance to WSL2:
    ````wsl --set-version kali-linux 2````
 - Restart the Instance:
    ````schtasks /run /tn kali-linux````

**Make it your own:**

From a security perspective, you should fork this project so you control the packages and files in the repository.  This also allows you to customize the installer in any way you prefer: 

- Sign into GitHub and fork this project
- Edit ```Kali-xRDP.cmd```.  On line 2 you will see ```SET GITORG=DesktopECHO``` - Change ```DesktopECHO``` to the name of your own repository.
- Customize the script any way you like.
- Launch the script using your repository name:
 ```PowerShell -executionpolicy bypass -command "wget https://github.com/YOUR-ORG/Kali-xRDP/raw/main/Kali-xRDP.cmd -UseBasicParsing -OutFile Kali-xRDP.cmd ; .\Kali-xRDP.cmd"```

**Additional Info:**

* Rebuilt [WebKitGTK](https://webkit.org/) 2.32 for WSL
* When you log out out of a desktop session the entire WSL instance is restarted, equivalent to a clean-boot at every login. 
* Disconnected sessions continue to run in the background and resuming the session works reliably.
* Enabled gksu for apps needing elevated rights (Synaptic, root console) to work around limitations in WSL1.
* [apt-fast](https://github.com/ilikenwf/apt-fast) added to improve download speed and reliability.
* Mozilla Seamonkey included as a stable browser that's kept up to date via apt.  Current versions of Chrome/Firefox do not work in WSL1.
* Installed base image consumes approximately 3GB of storage
* Minor visual tweaks were made and fonts in XFCE4 are supplied by the host OS (Segoe UI / Cascadia Code)

![image](https://user-images.githubusercontent.com/33142753/109518093-55463880-7a80-11eb-9276-e27ffd08fcc9.png)

![image](https://user-images.githubusercontent.com/33142753/109516375-7c036f80-7a7e-11eb-99de-54ae788ebb90.png)

