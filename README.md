# workshed

ImprovedAppInstaller.sh is a bash script I created as an educational exercise to learn more scripting. 

It will install all the deb and flatpak apps I typically use on my computer. I wrote and tested it with Pop OS, but it should work with any Ubuntu based script. 

The deb and flatpak applications are listed in array at the top of the script. This should make for easy customization of what applications can be installed.

It installs nala and then uses nala to install deb packages.

The script will add a repo for Fastfetch, and Fastfetch with modified ascii art work as well.

The script will first check if an application is already installed and skip it if it is.

The script will modify your bashrc file with aliases I commonly use. It will also create a script to update deb and flatpak applications.

This was made for my use and I may be an idiot.

The script can be run via a curl command.

Curl command to run App download script:


` curl -s https://raw.githubusercontent.com/mdleslie/workshed/workshed/ImprovedAppInstaller.sh | bash `


###Groovy.


-mdleslie@gmail.com
