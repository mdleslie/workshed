# Need to test removal of Libreoffice, this may need more work. #

clear

echo -e "\e[1;34m Made for and on Pop OS. Updated July 20 2024. Make sure to click ok or yes at various points in install process. Don't Mix Danger, Handle with Care! \e[0m"
sleep 5s

echo -e "\e[1;34m ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

echo -e "\e[1;34m ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

echo -e "\e[1;34m Preparing system before beging installation script. \e[0m" 

sudo apt update
sudo apt upgrade -y

echo -e "\e[1;34m Removing the old packaged version of Libre Office. We will install a newer version later in this script. \e[0m"
sleep 2s

sudo apt-get remove --purge "libreoffice*"
sudo apt-get clean
sudo apt-get autoremove

echo -e "\e[1;34m Installing Nala \e[0m"

sudo apt install nala

echo -e "\e[1;34m Installing File Manager customizations and terminal tools \e[0m" 
sleep 2s

sudo nala install gnome-sushi imagemagick nautilus-image-converter nautilus-admin ffmpegthumbnailer fortune-mod cowsay folder-color nautilus-dropbox -y

echo -e "\e[1;34m Installing Cosmic App Store. Unleash your Potential. \e[0m" 
sleep 2s

sudo nala install cosmic-icons cosmic-store -y

echo -e "\e[1;34m Installing Fastfetch. \e[0m" 
sleep 2s

sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update
sudo apt install fastfetch

echo -e "\e[1;34m Installing MakeMKV. \e[0m" 
sleep 2s

sudo add-apt-repository ppa:heyarje/makemkv-beta
sudo apt update
sudo nala install makemkv-bin makemkv-oss -y

echo -e "\e[1;34m Installing codecs and media tools. \e[0m" 
sleep 2s

sudo nala install ubuntu-restricted-extras ffmpeg mpv mediainfo vlc youtube-dl libdvdcss2 chromium-codecs-ffmpeg-extra libdvd-pkg libssl-dev libexpat1-dev libgl1-mesa-dev -y

sudo dpkg-reconfigure libdvd-pkg

echo -e "\e[1;34m Installing gstreeamer tools. \e[0m"

sudo nala install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio -y

echo -e "\e[1;34m Installing network file sharing tools. \e[0m" 
sleep 2s

sudo nala install nfs-common cifs-utils -y

echo -e "\e[1;34m Installing other essential applications for productivety and gaming. \e[0m" 
sleep 2s

sudo nala install gamemode gnome-tweaks lutris steam cpu-x digikam stacer curl python3 -y

echo -e "\e[1;34m ++++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

echo -e "\e[1;34m ++++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

echo -e "\e[1;34m Now entering the Flatpak zone. \e[0m" 

echo -e "\e[1;34m Installing Libre Office Flatpak. Newer and much better version. \e[0m"

flatpak install flathub org.libreoffice.LibreOffice  -y

echo -e "\e[1;34m Installing Joplin Flatpak. \e[0m"

flatpak install flathub net.cozic.joplin_desktop -y

echo -e "\e[1;34m Installing Synology Drive Station. \e[0m"

flatpak install flathub com.synology.SynologyDrive -y

echo -e "\e[1;34m Installing Brave. \e[0m"

flatpak install flathub com.brave.Browser -y

echo -e "\e[1;34m Installing Floorp. \e[0m"

flatpak install flathub one.ablaze.floorp -y

echo -e "\e[1;34m Installing Kdenlive Flatpak. \e[0m"

flatpak install flathub org.kde.kdenlive -y

echo -e "\e[1;34m Installing Spotube Spotify client Flatpak. \e[0m"

flatpak install flathub com.github.KRTirtho.Spotube -y

echo -e "\e[1;34m Installing Handbrake Flatpak. \e[0m"

flatpak install flathub fr.handbrake.ghb -y

echo -e "\e[1;34m Installing OBS Studio Flatpak. \e[0m"

flatpak install flathub com.obsproject.Studio -y

echo -e "\e[1;34m Installing Mission Center Flatpak. \e[0m"

flatpak install flathub io.missioncenter.MissionCenter -y

echo -e "\e[1;34m Installing Telegram Flatpak. \e[0m"

flatpak install flathub org.telegram.desktop -y

echo -e "\e[1;34m Installing Bitwarden Flatpak. \e[0m"

flatpak install flathub com.bitwarden.desktop -y

echo -e "\e[1;34m Installing Skype Flatpak. \e[0m"

flatpak install flathub com.skype.Client -y

echo -e "\e[1;34m Installing Youtube Downloader Flatpak. \e[0m"

flatpak install flathub io.github.aandrew_me.ytdn -y

echo -e "\e[1;34m Installing LocalSend Flatpak. \e[0m"

flatpak install flathub org.localsend.localsend_app -y

echo -e "\e[1;34m +++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

echo -e "\e[1;34m +++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

echo -e "\e[1;34m Finished scripted installations. Shop Smart, shop S-Mart. \e[0m"

echo -e "\e[1;34m +++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

echo -e "\e[1;34m +++++++++++++++++++++++++++++++++++++++++++++++ \e[0m"

sleep 10s

exit