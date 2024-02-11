#!/usr/bin/env bash

# Initialize variables with default values
debug_mode=false
overwrite=false
name=""
executable=""
icon=""
start=false
icon_set=false
dont_check_exec=false

# Function to display usage information
usage() {
	echo "Usage: $(basename "$0") [OPTIONS]"
	echo "Options:"
	echo " --help        Display this help message"
	echo " --debug       Enable debug mode"
	echo " --name NAME   Name of the application"
	echo " --executable EXECUTABLE"
	echo "               Executable with possible path followed by possible arguments"
	echo " --icon ICON   Icon with possible path"
	echo " --start       Start application from desktop file after creation"
	echo " --overwrite   Overwrite existing desktop or icon file"
	echo " --dont-check-exec"
	echo "               Don't perform any checks on executable, use executable as is."
	echo "               E.g. this is useful when instead of invoking an executable a"
	echo "               script is being executed."
	echo ""
	echo "$(basename "$0") will create a simple .desktop file for your application"
	echo "such that you can start your application via the GUI of your desktop environment."
	echo ""
	echo "Examples:"
	echo "  $(basename "$0") # fully interactive, it will ask for necessary info"
	echo "  $(basename "$0") -d -s # with debug info and testing it by starting app"
	echo "  $(basename "$0") -d -o -s -n \"MyApp\" -e \"~/bin/MyApp.AppImage\" -i \"$HOME/Downloads/MyAppIcon.png\" # fully batch"
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
	case $1 in
	-h | --help | "-?" | "/?")
		usage
		exit 0
		;;
	-d | --debug)
		debug_mode=true
		;;
	-o | --overwrite)
		overwrite=true
		;;
	-n | --name)
		shift
		name="$1"
		;;
	-e | --executable)
		shift
		executable="$1"
		;;
	-i | --icon)
		shift
		icon="$1"
		icon_set=true
		;;
	-s | --start)
		start=true
		;;
	-dce | ----dont-check-exec)
		dont_check_exec=true
		;;
	*)
		echo "Invalid option: $1"
		usage
		exit 1
		;;
	esac
	shift
done

# Main script logic

# Debug
if $debug_mode; then
	DEBUG=true
elif [[ "$DEBUG" == "" ]]; then
	DEBUG=false
elif [[ "$DEBUG" == "1" ]] || [[ "${DEBUG,,}" == "true" ]] || [[ "${DEBUG,,}" == "on" ]]; then
	DEBUG=true
else
	DEBUG=false
fi
$DEBUG && echo "Debug mode is enabled."

# XDG
if [[ "$XDG_DATA_HOME" != "" ]]; then
	$DEBUG && echo "XDG_DATA_HOME set to \"$XDG_DATA_HOME\"."
else
	XDG_DATA_HOME="$(realpath "$HOME/.local/share")"
	$DEBUG && echo "XDG_DATA_HOME initialized to \"$XDG_DATA_HOME\"."
fi
LOCAL_ICONS="${XDG_DATA_HOME}/icons"
mkdir -p "$LOCAL_ICONS"
if [[ ! -d "$LOCAL_ICONS" ]]; then
	echo "ERROR: Directory \"$LOCAL_ICONS\" does not exist. Aborting."
	exit 12
else
	$DEBUG && echo "Directory \"$LOCAL_ICONS\" exists."
fi
LOCAL_APPS="${XDG_DATA_HOME}/applications"
mkdir -p "$LOCAL_APPS"
if [[ ! -d "$LOCAL_APPS" ]]; then
	echo "ERROR: Directory \"$LOCAL_APPS\" does not exist. Aborting."
	exit 12
else
	$DEBUG && echo "Directory \"$LOCAL_APPS\" exists."
fi
# LOCAL_BIN="$(realpath "$HOME/.local/bin")"
# $DEBUG && echo "LOCAL_BIN initialized to \"$LOCAL_BIN\"."
# mkdir -p "$LOCAL_BIN"
# if [[ ! -d "$LOCAL_BIN" ]]; then
# 	echo "ERROR: Directory \"$LOCAL_BIN\" does not exist. Aborting."
# 	exit 11
# else
# 	$DEBUG && echo "Directory \"$LOCAL_BIN\" exists."
# fi
# if [[ ":$PATH:" == *":$LOCAL_BIN:"* ]] || [[ ":$PATH:" == *":~/.local/bin:"* ]]; then
# 	$DEBUG && echo "Your PATH is: $PATH"
# 	$DEBUG && echo "Your path is correctly set and already contains \"$LOCAL_BIN\"."
# else
# 	echo "WARNING: Your PATH is: $PATH"
# 	echo "WARNING: Your path is missing \"$LOCAL_BIN\", you need to add it."
# fi

# Name
if [[ "$name" == "" ]]; then
	read -r -p "Simple name of app (e.g. MyApp): " appname
else
	appname="$name"
fi
# remove leading whitespace from a string:
shopt -s extglob
appname=$(printf '%s\n' "${appname##+([[:space:]])}")
# remove trailing whitespace from a string:
appname=$(printf '%s\n' "${appname%%+([[:space:]])}")
if [[ "$appname" == "" ]]; then
	echo "ERROR: Name of app must not be empty. Aborting."
	exit 2
fi
$DEBUG && echo "Application name is: \"$appname\""
appname2=${appname// /-} # replace spaces

# Executable
if [[ "$executable" == "" ]]; then
	read -r -p "Executable with possible path (and possible arguments): " executable
fi
# remove leading whitespace from a string:
shopt -s extglob
executable=$(printf '%s\n' "${executable##+([[:space:]])}")
# remove trailing whitespace from a string:
executable=$(printf '%s\n' "${executable%%+([[:space:]])}")
if [[ "$executable" == "" ]]; then
	echo "ERROR: Executable must not be empty. Aborting."
	exit 3
fi
if ! $dont_check_exec; then
	executable="${executable/#\~/$HOME}" # replace ~ as that can cause problems for cp
	$DEBUG && echo "Executable is: \"$executable\""
	first_word="${executable%% *}"
	executableonly=$(realpath "$first_word")
	if [[ -f "$executableonly" ]]; then
		$DEBUG && echo "Executable \"$executableonly\" exists."
	else
		echo "ERROR: Executable file \"$executableonly\" does not exists. Aborting."
		exit 4
	fi
else
	$DEBUG && echo "Not checking the executable."
	$DEBUG && echo "Executable is: \"$executable\""
fi

# icon
if ! $icon_set; then
	read -r -p "Icon with possible path (e.g. ~/Downloads/MyAppIcon.png) or empty: " icon
fi
# remove leading whitespace from a string:
shopt -s extglob
icon=$(printf '%s\n' "${icon##+([[:space:]])}")
# remove trailing whitespace from a string:
icon=$(printf '%s\n' "${icon%%+([[:space:]])}")
if [[ "$icon" != "" ]]; then
	iconname2=$(basename "$icon") # get just the filename without path
	iconname2=${iconname2// /-}   # replace spaces
	icon="${icon/#\~/$HOME}"      # replace ~ as that can cause problems for cp
	iconfile="${LOCAL_ICONS}/$iconname2"
else
	iconfile=""
fi
icon="$(realpath "$icon")"
$DEBUG && echo "Source icon file is: $icon"
if [[ "$(dirname "$icon")" == "$LOCAL_ICONS" ]]; then
	$DEBUG && echo "Icon \"$icon\" is located in \"$LOCAL_ICONS\". Hence no need to copy it."
	iconfile="$icon"
fi
$DEBUG && [[ "$icon" != "" ]] && echo "Icon file name will be: $iconfile"
if [[ "$icon" != "" ]]; then
	if [[ -f "$icon" ]]; then
		$DEBUG && echo "Icon \"$icon\" exists."
	else
		echo "ERROR: Icon file \"$icon\" does not exists. Aborting."
		exit 5
	fi
	if [[ "$icon" != "$iconfile" ]]; then
		if [[ -f "$iconfile" ]]; then
			if ! $overwrite; then
				echo "ERROR: Icon file \"$iconfile\" already exists."
				echo "       Rename or remove it first. Aborting."
				exit 6
			else
				echo "WARNING: Icon file \"$iconfile\" already exists and will be overwritten."
			fi
		fi
		if ! cp "$icon" "$iconfile"; then
			echo "ERROR: File \"$icon\" could not be copied. Fix it. Aborting."
			exit 7
		fi
		$DEBUG && echo "Copied icon file from \"$icon\" to \"$iconfile\"."
	fi
else
	$DEBUG && echo "WARNING: No icon assigned."
fi

# desktop file
desktopfile="${LOCAL_APPS}/${appname2}.desktop"
$DEBUG && echo "Desktop file name will be: $desktopfile"
if [[ -f "$desktopfile" ]]; then
	if ! $overwrite; then
		echo "ERROR: Desktop file \"$desktopfile\" already exists."
		echo "       Rename or remove it first. Aborting."
		exit 8
	else
		echo "WARNING: Desktop file \"$desktopfile\" already exists and will be overwritten."
	fi
fi

cat <<EOF >"$desktopfile"
[Desktop Entry]
Encoding=UTF-8
Type=Application
Terminal=false
Exec=$executable
Name=$appname
Icon=$iconfile
# end
EOF
$DEBUG && echo "Created desktop file \"$desktopfile\"."
chmod 644 "$desktopfile"

$DEBUG && echo "Successfully created desktop file \"$desktopfile\"."

# start
if command -v gtk-launch >/dev/null 2>&1; then
	if $start; then
		$DEBUG && echo "Command gtk-launch exists."
		$DEBUG && echo "Launching application with gtk-launch."
		# gtk-launch "app name"  or  tk-launch "app.desktop" :: okay, correct
		# gtk-launch /full/path/app.desktop :: false, incorrect
		if ! gtk-launch "$(basename "$desktopfile")"; then
			echo "ERROR: Launching application via desktop file failed. Aborting."
			exit 9
		else
			$DEBUG && echo "Successfully launched application via desktop file."
		fi
	fi
else
	$DEBUG && echo "Command gtk-launch does not exist."
	if $start; then
		echo "ERROR: Cannot launch application via gtk-launch because gtk-launch is not found. Install gtk-launch first."
		exit 10
	fi
fi

$DEBUG && echo "Done. Success!"
exit 0

# end of script
