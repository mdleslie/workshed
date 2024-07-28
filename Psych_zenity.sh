#!/bin/bash

# Array of phrases
phrases=("IS THAT MAURIZIO IN THERE, GUS?! IS THAT MAURIZIO IN THERE?!"
"Are you a fan of delicious flavor?"
"I've heard it both ways."
"Gus, don't be the only game at Chuck E Cheese that isn't broken."
"You must be outa your damn mind!"
"Embrace the deception, learn how to bend"
"Your worst inhibitions tend to PSYCH you out in the end."
"I can't help it, Shawn, my body craves buttery goodness."
"Suck it."
"Agree To Agree.")

# Function to show a random phrase
show_phrase() {
    random_index=$((RANDOM % ${#phrases[@]}))
    zenity --info --text="${phrases[$random_index]}"
}

# Main dialog box
zenity --info --text="Press the button to get a phrase!" --ok-label="Show Phrase" --no-wrap

# Check the exit status of the dialog box
if [ $? -eq 0 ]; then
    show_phrase
fi
