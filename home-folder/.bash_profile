# bash profile, for login shell
export XDG_DATA_HOME=$HOME/.local/share
# isn't preset. you need to ~/.mkdir $HOME/.local/share if you don't have it!  
# you need to make (mkdir -p ) ~/.local/bin/fb if it isn't there.
export PATH=.:$HOME/.local/bin/fb:/bin:$PATH
export LC_ALL=C.UTF-8
export FB=/mnt/chromeos/GoogleDrive/MyDrive/FB
# It's the varible for mounting the backup system.

# Below are stuff for making the DBUS, available, and hence the desktop
# Notifications possible, in addition, we exxport our FB variable over to
# the systemd services that will run in -user space. So, Should you 
# change this variable, then you'll need to "turn off the Linux Container
# and turn it back on again, because the Login shell only executes each time
# the Linux container is started.

xrdb ~/.Xresources -display :1
dbus-update-activation-environment --systemd \
		                        DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY FB
# If you customize your PATH and plan on launching applications that make use
# of it from systemd units, you should make sure the modified PATH is set on
# the systemd environment.

# This may not be entirely smart to do if we are going to do things with elevated rights
# and access to root stuff, then it might be better to ditch the command below and 
# write a .conf file for the service, specifying the paths we need.

systemctl --user import-environment


# We source ~/.bashrc, since the login shell becomes interactive the first time,
source ~/.bashrc
