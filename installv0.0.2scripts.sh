#!/bin/bash
PNAME=${0##*/}
errfunc() {
	echo $PNAME : there were an error at $1
}
trap 'errfunc $LINENO' ERR

rmifexist() {
	[ -r "$1" ] && rm -f "$1"
}
rp=$(realpath $0)
SOURCE_PATH=${rp%/*}

if [ x"$XDG_BIN_HOME" = x ] ; then 
	echo -e "$PNAME : XDG_BIN_HOME not set,\n the steps in "$SOURCE_PATH/Docs/User/SystemInstallation.md" not followed.\nTerminating."
	exit 2
fi
echo -e $PNAME : Making folders for the delegates that actually backs up and restores.
mkdir -p $XDG_BIN_HOME/fb/OneShot/OneShot.d
echo  $PNAME : copies the delegates into $XDG_BIN_HOME/fb/OneShot
rmifexist "$XDG_BIN_HOME/fb/OneShot/OneShot.backup.sh"
cp -f $SOURCE_PATH/.local/bin/fb/OneShot/OneShot.backup.sh $XDG_BIN_HOME/fb/OneShot
echo cp -f $SOURCE_PATH/.local/bin/fb/OneShot/OneShot.backup.sh $XDG_BIN_HOME/fb/OneShot
rmifexist "$XDG_BIN_HOME/fb/OneShot/OneShot.restore.sh"
cp -f $SOURCE_PATH/.local/bin/fb/OneShot/OneShot.restore.sh $XDG_BIN_HOME/fb/OneShot
echo cp -f $SOURCE_PATH/.local/bin/fb/OneShot/OneShot.restore.sh $XDG_BIN_HOME/fb/OneShot
echo  $PNAME : copies the user commands  into $XDG_BIN_HOME/fb
rmifexist "$XDG_BIN_HOME/fb/fbsnapshot"
cp -f $SOURCE_PATH/.local/bin/fb/fbsnapshot $XDG_BIN_HOME/fb
echo cp -f $SOURCE_PATH/.local/bin/fb/fbsnapshot $XDG_BIN_HOME/fb
rmifexist "$XDG_BIN_HOME/fb/fbrestore"
cp -f $SOURCE_PATH/.local/bin/fb/fbrestore $XDG_BIN_HOME/fb
echo cp -f $SOURCE_PATH/.local/bin/fb/fbrestore $XDG_BIN_HOME/fb
echo  $PNAME : copies the shared functions into $XDG_BIN_HOME/fb
rmifexist "$XDG_BIN_HOME/fb/shared_functions.sh"
cp -f $SOURCE_PATH/.local/bin/fb/shared_functions.sh $XDG_BIN_HOME/fb
echo cp -f $SOURCE_PATH/.local/bin/fb/shared_functions.sh $XDG_BIN_HOME/fb
echo -e "\n\n$PNAME : Successfully installed Folder Backup v0.0.2\nEnjoy!"



