# Create desktop file


```
Usage: create-desktop-file.sh [OPTIONS]
Options:
 --help        Display this help message
 --debug       Enable debug mode
 --name NAME   Name of the application
 --executable EXECUTABLE
               Executable with possible path followed by possible arguments
 --icon ICON   Icon with possible path
 --start       Start application from desktop file after creation
 --overwrite   Overwrite existing desktop or icon file
 --dont-check-exec
               Don't perform any checks on executable, use executable as is.
               E.g. this is useful when instead of invoking an executable a
               script is being executed.

create-desktop-file.sh will create a simple .desktop file for your application
such that you can start your application via the GUI of your desktop environment.

Examples:
  create-desktop-file.sh # fully interactive, it will ask for necessary info
  create-desktop-file.sh -d -s # with debug info and testing it by starting app
  create-desktop-file.sh -d -o -s -n "MyApp" -e "~/bin/MyApp.AppImage" -i "/home/a/Downloads/MyAppIcon.png" # fully batch
```

# Install
Download this bash script, change permissions and execute it.
