# Example block for when Alacritty is used, with terminal type == alacritty,
# because then, the .bash_profile isn't read. Systemd will be properly
# initialized by .bash_profile when you start up the linux container however
if [ $TERM = alacritty ] ; then 
	export XDG_DATA_HOME=$HOME/.local/share
	export XDG_BIN_HOME=$HOME/.local/bin
	# De facto standard, but isn't preset. 
	PATH=.:/usr/local/bin:$XDG_BIN_HOME:$XDG_BIN_HOME/fb:$PATH
	# TODO: You will  want to update your path to your likings.
	# just be sure to incorporate $XDG_BIN_HOME/fb
	export LC_ALL=C.UTF-8
	export FB=/mnt/chromeos/GoogleDrive/MyDrive/FB
	# TODO: you may want to update the path to your folder backup root as well
	# if it is named differently.

	. "$HOME/.cargo/env"
	# Cargo env, for Alacritty. Pretty mandatory for Alacritty.
fi
