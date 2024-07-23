#!/bin/bash

############################################################################################
############################################################################################
###Setup instructions###
###Place bash file in /home/$USER/bin with update.sh name. You will need to create the bin subdirectory.

###Run commands:

###sudo chmod +x update.sh                     to make executable

###########################################################################################
###########################################################################################

now=$(date)
USER="David"
DEVICE="Desktop"
DISTRO="Pop OS Linux"
MODEL="Thelio"
RAM=$(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024)))"M"
TODAY=$(date +"Today's date is %A, %B %d %Y.")
TIMENOW=$(date +"The local time is %r")
SLEEP=.05s
SLEEPL=3s
ANIMATE=true
WHO="Our rock never dies ever, forever!"
###########################################################################################

echo -e "\e[1;37m Let's go, it showtime! \e[0m"
sleep $SLEEPL

echo -e "\e[1;37m                   .:+#%@@@@@@@@@@%#+:.                                \e[0m" 
sleep $SLEEP          
echo -e "\e[1;37m              .:+%@@@@@@@@@@@@@@@@@@@@@@%+:.                           \e[0m"
sleep $SLEEP
echo -e "\e[1;37m           .:#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:.                        \e[0m"
sleep $SLEEP
echo -e "\e[1;37m         .=@@@@@+..:%@@@@@@@@@@@@@@@@@: .+@@@@@=.                      \e[0m"
sleep $SLEEP
echo -e "\e[1;37m       .+@@@@+.     .#@@@@@@@@@@@@@@#.    ..+%@@@+.                    \e[0m"
sleep $SLEEP
echo -e "\e[1;37m     .-@@@#..        .*@@@@@@@@@@@@*.       ...#@@@-.                  \e[0m"
sleep $SLEEP
echo -e "\e[1;37m     *@@@@@.%#:       .-@@@@@@@@@@-.       :#%.@@@@@*                  \e[0m"
sleep $SLEEP
echo -e "\e[1;37m   :%@@@@@@*-@@@*:.    .:@@@@@@@@:.     :*@@@=+@@@@@@@:                \e[0m"
sleep $SLEEP
echo -e "\e[1;37m  .%@@@@@@@@.+%@@@@*:.   .#@@@@#.   .:*@@@@%*.@@@@@@@@%.               \e[0m"
sleep $SLEEP
echo -e "\e[1;37m .%@@@@@@@@@@@%+:.=%@@+.  .#::#:  .+@@%=.:+%@@@@@@@@@@@%.              \e[0m"
sleep $SLEEP
echo -e "\e[1;37m.+@@@@@@@@@@@@@@@@@@%*+++=.+=-+.=+++*%@@@@@@@@@@@@@@@@@@*.             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m:%@@@@@@@@@@@@@@@@@@@@@@@%--%%--%@@@@@@@@@@@@@@@@@@@@@@@@:             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m+@@@@@@@@@@@@@@@@@@@@@@%:.=@@@@+ :%@@@@@@@@@@@@@@@@@@@@@@+             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m%@@@@@@@@@@@@@@@@@@@@*. .#%#@@###. .+@@@@@@@@@@@@@@@@@@@@%             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m@@@@@@@@@@@@@@@@@@@=.     .%@@%.     .=@@@@@@@@@@@@@@@@@@@             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m@@@@@@@@@@@@@@@@@::*#.    *@@@@*    .#*::@@@@@@@@@@@@@@@@@             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m@@@@@@@@@@@@@@@@@@*:.   .+@@@@@@+.   .:*@@@@@@@@@@@@@@@@@@             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m%@@@@@@@@@@@@@@@#.     .=@@@@@@@@=.     .*@@@@@@@@@@@@@@@%             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m+@@@@@@@@@@@@@*.       :@@@@@@@@@@:       .*@@@@@@@@@@@@@+             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m:@@@@@@@@@@@+.        :@@@@@@@@@@@@:        .+@@@@@@@@@@@:             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m.+@@@@@@@@+.         .%@@@@@@@@@@@@%.          =@@@@@@@@*.             \e[0m"
sleep $SLEEP
echo -e "\e[1;37m .%@@@@@=           .*@@@@@@@@@@@@@@#.           -@@@@@%.              \e[0m"
sleep $SLEEP
echo -e "\e[1;37m  .%@@=.           .*@@@@@@@@@@@@@@@@*.           .-@@%.               \e[0m"
sleep $SLEEP
echo -e "\e[1;37m   :%@@@@@@@@@.    =@@@@@@@@@@@@@@@@@@=    .@@@@@@@@@@:                \e[0m"
sleep $SLEEP
echo -e "\e[1;37m     *@@@@@@@@+   :@@@@@@@@@@@@@@@@@@@@:. .=@@@@@@@@*                  \e[0m"
sleep $SLEEP
echo -e "\e[1;37m     .-@@@@@@@%. :@@@@@@@@@@@@@@@@@@@@@@: .#@@@@@@@-.                  \e[0m"
sleep $SLEEP
echo -e "\e[1;37m       .+@@@@@@-.#@@@@@@@@@@@@@@@@@@@@@@%.:%@@@@@+.                    \e[0m"
sleep $SLEEP
echo -e "\e[1;37m         .=@@@@=#@@@@@@@@@@@@@@@@@@@@@@@@#=@@@@+.                      \e[0m"
sleep $SLEEP
echo -e "\e[1;37m           .:#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:.                        \e[0m"
sleep $SLEEP
echo -e "\e[1;37m              .:+%@@@@@@@@@@@@@@@@@@@@@@%+:.                           \e[0m"
sleep $SLEEP
echo -e "\e[1;37m                   .:+%@@@@@@@@@@@@%+:.                                \e[0m"
sleep $SLEEP


sleep $SLEEPL

clear
if [ "$ANIMATE" = true ] ; then
    echo -e "\e[47m                    \e[0m"
    sleep $SLEEP
    clear
    echo -e "\e[47m                    \e[0m"
    echo -e "\e[40m                     \e[0m"
    sleep $SLEEP
    clear
    echo -e "\e[47m                    \e[0m"
    echo -e "\e[40m                     \e[0m"
    echo -e "\e[47m                    \e[0m"
    sleep $SLEEP
    clear
    echo -e "\e[47m                    \e[0m"
    echo -e "\e[40m                     \e[0m"
    echo -e "\e[47m                    \e[0m"
    echo -e "\e[40m                     \e[0m"
    sleep $SLEEP
    clear
    echo -e "\e[47m                    \e[0m"
    echo -e "\e[40m                     \e[0m"
    echo -e "\e[47m                    \e[0m"
    echo -e "\e[40m                     \e[0m"
    echo -e "\e[47m                    \e[0m"
    sleep $SLEEP
    clear
    echo -e "\e[47m                    \e[0m   $USER's $DEVICE"
    echo -e "\e[40m                     \e[0m   "
    echo -e "\e[47m                    \e[0m   "
    echo -e "\e[40m                     \e[0m   "
    echo -e "\e[47m                    \e[0m   "
    sleep $SLEEP
    clear
    echo -e "\e[47m                    \e[0m   $USER's $DEVICE"
    echo -e "\e[40m                     \e[0m  $DISTRO"
    echo -e "\e[47m                    \e[0m   "
    echo -e "\e[40m                     \e[0m   "
    echo -e "\e[47m                    \e[0m   "
    sleep $SLEEP
    clear
    echo -e "\e[47m                    \e[0m   $USER's $DEVICE"
    echo -e "\e[40m                     \e[0m  $DISTRO"
    echo -e "\e[47m                    \e[0m   $WHO"
    echo -e "\e[40m                     \e[0m   "
    echo -e "\e[47m                    \e[0m   "
    sleep $SLEEP
    clear
    echo -e "\e[47m                    \e[0m   $USER's $DEVICE"
    echo -e "\e[40m                     \e[0m  $DISTRO"
    echo -e "\e[47m                    \e[0m   $WHO"
    echo -e "\e[40m                     \e[0m  $MODEL"
    echo -e "\e[47m                    \e[0m   "
    sleep $SLEEP
    clear
    echo -e "\e[47m                    \e[0m   $USER's $DEVICE"
    echo -e "\e[40m                     \e[0m  $DISTRO"
    echo -e "\e[47m                    \e[0m   $WHO"
    echo -e "\e[40m                     \e[0m  $MODEL"
    echo -e "\e[47m                    \e[0m   $RAM Ram ok"
    sleep $SLEEP

else
    clear
    echo -e "\e[47m          \e[0m   $USER's $DEVICE \e[0m"
    echo -e "\e[40m           \e[0m   $DISTRO"
    echo -e "\e[47m          \e[0m   $WHO"
    echo -e "\e[40m           \e[0m   $MODEL"
    echo -e "\e[47m          \e[0m   $RAM OK"
fi

echo -e "\e[1;37m Hello $USER \e[0m"
sleep 1s

echo -e "\e[1;37m $TODAY \e[0m"
sleep 1s

echo -e "\e[1;37m $TIMENOW \e[0m"
sleep $SLEEPL

echo -e "\e[1;37m Breaking new Gate! \e[0m"
sleep $SLEEPL

echo -e "\e[1;37m ============================================================================= \e[0m"

sleep 1s

echo -e "\e[1;37m Here is your the weather forecast, po. \e[0m"

sleep $SLEEPL

curl wttr.in/Tucson

sleep $SLEEPL

echo -e "\e[1;37m ============================================================================= \e[0m"

sleep $SLEEPL

clear

echo -e "\e[1;37m Don't mix danger, handle with care! \e[0m"

sleep $SLEEPL

exit
