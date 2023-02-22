# bash profile, for login shell
export XDG_DATA_HOME=$HOME/.local/share
export XDG_BIN_HOMR=$HOME/.local/fb
# isn't preset. you need to ~/.mkdir $HOME/.local/share if you don't have it!  
# you need to make (mkdir -p ) ~/.local/bin/fb if it isn't there.

# Enter your original path from your .bashrc here,
# be sure to let it end in $PATH to include  the path set in /etc/bash_profile.

#  export PATH=your:path:$PATH


export PATH=.:$HOME/.local/bin/fb:/bin:$PATH
export LC_ALL=C.UTF-8
# It's the varible for mounting the backup system.
export FB=/mnt/chromeos/GoogleDrive/MyDrive/FB


# the lines below are for importing the environment into the
# systemd --user processes, as they are started up in parallell.
xrdb ~/.Xresources -display :1
dbus-update-activation-environment --systemd \
        DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY FB

systemctl --user import-environment

# We source ~/.bashrc, since the login shell becomes interactive the first time,
source ~/.bashrc
