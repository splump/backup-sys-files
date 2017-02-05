# backup-sys-files
A scripted solution to backing up important configuration files. The script is deployed with systemd and since it will need read access to your important files, you will need to run it as root.

# IMPORTANT:
Restore script is not yet finished. Feel free to tinker with it, but don't blame me if it does not work as expected or does anything weird to your files..

# Installing
Included is a script to install the necessary files. Inspect the script in order to get an understanding of what it will do, then run it as root to install. 
> ./INSTALL.sh

# Configuration
The install script will put a configuration file in /etc/backup-sys-files with the name filelist. Put in absolute paths to specific important files you wish to backup. Don't put in relative paths or folders.

# Running
Start the service by issuing as root:
> systemctl start backup-sys-files

If you wish to have it autostart at boot, do:
> systemctl enable backup-sys-files

You can monitor output through:
> systemctl status backup-sys-files

# Uninstalling
At this time there is no uninstall-script. Read the install-script and reverse it manually.