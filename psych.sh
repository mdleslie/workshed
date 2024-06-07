#!/bin/bash


now=$(date)
USER="David"
DEVICE="Desktop"
DISTRO="In between the lines there’s a lot of obscurity."
MODEL="I’m not inclined to resign to maturity."
RAM="If it’s alright, then you’re all wrong. But why bounce around to the same damn song?"
TODAY=$(date +"Today's date is %A, %B %d %Y.")
TIMENOW=$(date +"The time is %r")
SLEEP=.2s
SLEEPL=3s
ANIMATE=true
WHO="I know, you know"

#################################################################################################################################################################
# Array with expressions
expressions=("IS THAT MAURICIO IN THERE, GUS?! IS THAT MAURICIO IN THERE?!"
"Are you a fan of delicious flavor?"
"I've heard it both ways."
"Gus, don't be the only game at Chuck E Cheese that isn't broken."
"You must be outa your damn mind!"
"Embrace the deception, learn how to bend"
"Your worst inhibitions tend to psych you out in the end.")

#################################################################################################################################################################
#################################################################################################################################################################
clear
    echo -e "\e[102m                         \e[0m"
    sleep $SLEEP
    clear
    echo -e "\e[102m                         \e[0m"
    echo -e "\e[104m                         \e[0m"
    sleep $SLEEP
    clear
    echo -e "\e[102m                         \e[0m"
    echo -e "\e[104m                         \e[0m"
    echo -e "\e[101m                         \e[0m"
    sleep $SLEEP
    clear
    echo -e "\e[102m                         \e[0m"
    echo -e "\e[104m                         \e[0m"
    echo -e "\e[101m                         \e[0m"
    echo -e "\e[41m                         \e[0m"
    sleep $SLEEP
    clear
    echo -e "\e[102m                         \e[0m"
    echo -e "\e[104m                         \e[0m"
    echo -e "\e[101m                         \e[0m"
    echo -e "\e[41m                         \e[0m"
    echo -e "\e[44m                         \e[0m"
    sleep $SLEEP
    clear
    echo -e "\e[102m                         \e[0m   $USER's $DEVICE"
    echo -e "\e[104m                         \e[0m   "
    echo -e "\e[101m                         \e[0m   "
    echo -e "\e[41m                         \e[0m    "
    echo -e "\e[44m                         \e[0m    "
    sleep $SLEEP
    clear
    echo -e "\e[102m                         \e[0m   $USER's $DEVICE"
    echo -e "\e[104m                         \e[0m   $DISTRO"
    echo -e "\e[101m                         \e[0m   "
    echo -e "\e[41m                         \e[0m    "
    echo -e "\e[44m                         \e[0m    "
    sleep $SLEEP
    clear
    echo -e "\e[102m                         \e[0m   $USER's $DEVICE"
    echo -e "\e[104m                         \e[0m   $DISTRO"
    echo -e "\e[101m                         \e[0m   $WHO"
    echo -e "\e[41m                         \e[0m    "
    echo -e "\e[44m                         \e[0m    "
    sleep $SLEEP
    clear
    echo -e "\e[102m                         \e[0m   $USER's $DEVICE"
    echo -e "\e[104m                         \e[0m   $DISTRO"
    echo -e "\e[101m                         \e[0m   $WHO"
    echo -e "\e[41m                         \e[0m   $MODEL"
    echo -e "\e[44m                         \e[0m   "
    sleep $SLEEP
    clear
    echo -e "\e[102m                         \e[0m   $USER's $DEVICE"
    echo -e "\e[104m                         \e[0m   $DISTRO"
    echo -e "\e[101m                         \e[0m   $WHO"
    echo -e "\e[41m                         \e[0m   $MODEL"
    echo -e "\e[44m                         \e[0m   $RAM Ram ok"
    sleep $SLEEP

sleep $SLEEPL
clear

echo -e "\e[1;34m Hello $USER \e[0m"

sleep $SLEEP

echo -e "\e[1;34m $TODAY \e[0m"

sleep $SLEEP

echo -e "\e[1;34m $TIMENOW \e[0m"

sleep $SLEEP

fastfetch

sleep $SLEEPL
sleep $SLEEPL
sleep $SLEEPL

clear

echo -e "\e[1;34m ============================================================================ \e[0m"
sleep $SLEEP
echo -e "\e[1;34m ============================================================================ \e[0m"
sleep $SLEEP
echo -e "\e[1;34m ============================================================================ \e[0m"
sleep $SLEEP
echo -e "\e[1;34m ============================================================================ \e[0m"
sleep $SLEEP
echo -e "\e[1;34m ============================================================================ \e[0m"
sleep $SLEEP


# Seed random expression generator
RANDOM=$$$(date +%s)

# Get random expression.
selectedexpression=${expressions[ $RANDOM % ${#expressions[@]} ]}

#Print expression.

echo -e "\e[1;34m $selectedexpression \e[0m"

echo -e "\e[1;34m ============================================================================ \e[0m"
sleep $SLEEP
echo -e "\e[1;34m ============================================================================ \e[0m"
sleep $SLEEP
echo -e "\e[1;34m ============================================================================ \e[0m"
sleep $SLEEP
echo -e "\e[1;34m ============================================================================ \e[0m"
sleep $SLEEP
echo -e "\e[1;34m ============================================================================ \e[0m"
sleep $SLEEP

exit
