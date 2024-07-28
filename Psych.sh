#!/bin/bash

# Define the script content
SCRIPT_CONTENT='#!/bin/bash

# Array of phrases
phrases=("IS THAT MAURIZIO IN THERE, GUS?! IS THAT MAURIZIO IN THERE?!"
         "Are you a fan of delicious flavor?"
         "I\'ve heard it both ways."
         "Gus, don\'t be the only game at Chuck E Cheese that isn\'t broken."
         "You must be outa your damn mind!"
         "Embrace the deception, learn how to bend"
         "Your worst inhibitions tend to PSYCH you out in the end."
         "I can\'t help it, Shawn, my body craves buttery goodness."
         "Suck it."
         "Agree To Agree.")

# Function to show a random phrase
show_phrase() {
    random_index=$((RANDOM % ${#phrases[@]}))
    zenity --info --text="${phrases[$random_index]}"
}

# Main dialog box
zenity --info --text="Press it!" --ok-label="It" --no-wrap

# Show a random phrase when the button is pressed
show_phrase
'

# Define the desktop entry content
DESKTOP_ENTRY='[Desktop Entry]
Version=1.0
Name=Psych Quote
Comment=Show a random inspirational phrase
Exec=/opt/psych/psych.sh
Icon=dialog-information
Terminal=false
Type=Application
Categories=Utility;
'

# Cleanup function
cleanup() {
    echo "An error occurred. Cleaning up..."
    sudo rm -rf /opt/psych
    sudo rm -f /usr/share/applications/psych.desktop
    sudo rm -f /usr/local/bin/psych
    exit 1
}

# Create the application directory
sudo mkdir -p /opt/psych || cleanup

# Create the script file
echo "$SCRIPT_CONTENT" | sudo tee /opt/psych/psych.sh > /dev/null || cleanup

# Make the script executable
sudo chmod +x /opt/psych/psych.sh || cleanup

# Create the desktop entry file
echo "$DESKTOP_ENTRY" | sudo tee /usr/share/applications/psych.desktop > /dev/null || cleanup

# Create a symbolic link for easy access
sudo ln -sf /opt/psych/psych.sh /usr/local/bin/psych || cleanup

# Refresh the desktop database
sudo update-desktop-database || cleanup

echo "Installation complete. You can find 'Psych Quote' in your application menu or run 'psych' from the terminal."
exit 0
