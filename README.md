# backup-sys-files
A scripted solution to backing up important configuration files. The script is deployed with systemd and since it will need read access to your important files, you will need to run it as root.

# IMPORTANT:
Restore script is not yet finished. It is currently in debug mode and will only output what it will do, instead of actually performing any changes.

# Installing
Included is a script to install the necessary files. Inspect the script in order to get an understanding of what it will do, then run it as root to install. 
> ./INSTALL.sh

# Configuration
The install script will put a configuration file in /etc/backup-sys-files with the name filelist. Put in absolute paths to specific important files you wish to backup. Don't put in relative paths or folders. Comments and empty lines will be ignored.

# Running
Start the service by issuing as root:
> systemctl start backup-sys-files

If you wish to have it autostart at boot, do:
> systemctl enable backup-sys-files

You can monitor output through:
> systemctl status backup-sys-files

# Uninstalling
At this time there is no uninstall-script. Read the install-script and reverse it manually.
