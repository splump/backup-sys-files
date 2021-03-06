echo "Creating folder and copying config-file to /etc/backup-sys-files/filelist"
mkdir -p /etc/backup-sys-files && cp ./filelist /etc/backup-sys-files/
echo "Installing script to /usr/sbin/backup-sys-files.d"
cp ./backup-sys-files.d /usr/sbin/
echo "Installing restore script to /usr/sbin/restore.sh"
cp ./restore.sh /usr/sbin/
echo "Installing systemd service file to /usr/lib/systemd/system/backup-sys-files.service"
cp ./backup-sys-files.service /usr/lib/systemd/system/
echo "Running systemctl daemon-reload"
systemctl daemon-reload
echo "FIRST, edit the /usr/sbin/backup-sys-files and /usr/sbin/restore.sh BACKUPREPO variables to where you want to store your backups."
echo "Then start the daemon by running: systemctl start backup-sys-files"
