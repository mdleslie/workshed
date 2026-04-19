# workshed
This project is called workshed, because it is for me to workshed projects I work on for my personal use and education.

WorkshedAppInstaller.sh is a bash script I created as an educational exercise to learn more scripting. 

It will install all the deb and flatpak apps I typically use on my computer. I wrote and tested it with Pop OS, but it should work with any Ubuntu based script but you might need to install curl first.

The deb and flatpak applications are listed in array at the top of the script. This should make for easy customization of what applications can be installed.

It installs nala and then uses nala to install deb packages.

The script will add a repo for Fastfetch, and Fastfetch with modified ascii art work as well.

The script will first check if an application is already installed and skip it if it is.

The script will modify your bashrc file with aliases I commonly use. It will also create a script to update deb and flatpak applications.

Testing changes to PUID of logged in user to make NFS mounting of NAS better. (avoid file permission issues).  This should be handled by adding a variable near the top of the script. Edit variable and arrays as needed.

This was made for my use and I may be an idiot but others are free to try it.

The script can be run via a curl command.


### Curl command to run Ubuntu Based App download script:


`curl -s https://raw.githubusercontent.com/mdleslie/workshed/workshed/WorkshedAppInstaller.sh | bash`


-------------------------------------------------------------------------------------------------------


### Curl command to run Fedora Based App download script:


`curl -s https://raw.githubusercontent.com/mdleslie/workshed/workshed/Fedora_Install.sh | bash`




DAW Install script
I am working on this secondary install script for audio recording and production. Of which I am still learning and have a long way to go.
Run after app install script or stand alone. 

`curl -s https://raw.githubusercontent.com/mdleslie/workshed/workshed/DAW_Install.sh | bash`

There is also a uninstall_DAW.sh to remove all apps installed with the install DAW script.

### Groovy.

###Groovy.


-mdleslie@gmail.com
